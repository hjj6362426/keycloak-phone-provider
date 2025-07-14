package cc.coopersoft.keycloak.phone.providers.sender;

import cc.coopersoft.keycloak.phone.providers.constants.TokenCodeType;
import cc.coopersoft.keycloak.phone.providers.exception.MessageSendException;
import cc.coopersoft.keycloak.phone.providers.spi.MessageSenderService;
import cc.coopersoft.common.OptionalUtils;
import com.aliyun.auth.credentials.Credential;
import com.aliyun.auth.credentials.provider.StaticCredentialProvider;

import com.aliyun.sdk.service.dysmsapi20170525.AsyncClient;
import com.aliyun.sdk.service.dysmsapi20170525.models.SendSmsRequest;
import com.aliyun.sdk.service.dysmsapi20170525.models.SendSmsResponse;
import darabonba.core.client.ClientOverrideConfiguration;
import org.jboss.logging.Logger;
import org.keycloak.Config;
import org.keycloak.models.RealmModel;

import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

public class AliyunDysmsSenderServiceProvider implements MessageSenderService {

  private static final Logger logger = Logger.getLogger(AliyunDysmsSenderServiceProvider.class);

  private final Config.Scope config;
  private final RealmModel realm;
  private final AsyncClient client;

  public AliyunDysmsSenderServiceProvider(Config.Scope config, RealmModel realm) {
    this.config = config;
    this.realm = realm;

    logger.info("Initializing Aliyun SMS provider (dysmsapi) for realm: " + realm.getName());
    
    // Configure Credentials authentication information, including ak, secret, token
    String accessKeyId = config.get("key");
    String accessKeySecret = config.get("secret");
    
    if (accessKeyId == null || accessKeySecret == null) {
      logger.error("Aliyun SMS credentials not configured properly. AccessKeyId: " + accessKeyId + ", AccessKeySecret: " + (accessKeySecret != null ? "***" : "null"));
      throw new IllegalArgumentException("Aliyun SMS credentials not configured");
    }
    
    logger.info("Using Aliyun AccessKeyId: " + accessKeyId.substring(0, Math.min(6, accessKeyId.length())) + "***");
    
    StaticCredentialProvider provider = StaticCredentialProvider.create(Credential.builder()
        .accessKeyId(accessKeyId)
        .accessKeySecret(accessKeySecret)
        .build());

    // Configure the Client - using dysmsapi endpoint for SMS messages
    client = AsyncClient.builder()
        .region("cn-shanghai") // Region ID
        .credentialsProvider(provider)
        .overrideConfiguration(
                ClientOverrideConfiguration.create()
                        .setEndpointOverride("dysmsapi.aliyuncs.com")
        )
        .build();
        
    logger.info("Aliyun SMS client initialized successfully with dysmsapi");
  }

  @Override
  public void sendSmsMessage(TokenCodeType type, String phoneNumber, String code, int expires, String kind) throws MessageSendException {
    logger.info("Sending SMS message via Aliyun dysmsapi to: " + phoneNumber + ", code: " + code + ", expires: " + expires);
    
    try {
      String kindName = OptionalUtils.ofBlank(kind).orElse(type.name().toLowerCase());
      
      // 获取模板ID配置，优先使用realm特定配置
      String templateCode = Optional.ofNullable(config.get(realm.getName().toLowerCase() + "-" + kindName + "-template"))
          .orElse(config.get(kindName + "-template"));
      
      // 如果没有配置模板ID，抛出异常  
      if (templateCode == null) {
        String error = "SMS template not configured for type: " + kindName + ". Please set --spi-message-sender-service-aliyun-" + kindName + "-template=YOUR_TEMPLATE_ID";
        logger.error(error);
        throw new MessageSendException(-1, "TEMPLATE_NOT_CONFIGURED", error);
      }
      
      // 获取签名配置，默认使用realm显示名称
      String signName = config.get("sign-name");
      if (signName == null) {
        signName = realm.getDisplayName();
        if (signName == null || signName.trim().isEmpty()) {
          signName = realm.getName();
        }
      }
      
      logger.info("Using template: " + templateCode + ", sign: " + signName);
      
      // Parameter settings for API request - using SendSmsRequest for dysmsapi
      SendSmsRequest sendSmsRequest = SendSmsRequest.builder()
          .phoneNumbers(phoneNumber)  // Note: phoneNumbers for dysmsapi
          .signName(signName)
          .templateCode(templateCode)
          .templateParam(String.format("{\"code\":\"%s\",\"min\":\"%s\"}", code, expires / 60))
          .build();

      // Asynchronously get the return value of the API request
      CompletableFuture<SendSmsResponse> response = client.sendSms(sendSmsRequest);

      SendSmsResponse resp;
      
      try {
        // Synchronously get the return value of the API request - wait up to 30 seconds
        resp = response.get(30, TimeUnit.SECONDS);
      } catch (Exception e) {
        String error = "SMS send timeout or failed: " + e.getMessage();
        logger.error(error, e);
        throw new MessageSendException(error, e);
      }
      
      // 检查发送结果
      if (resp != null && resp.getBody() != null) {
        String resultCode = resp.getBody().getCode();
        String message = resp.getBody().getMessage();
        String bizId = resp.getBody().getBizId();
        
        logger.info("Aliyun SMS response - Code: " + resultCode + ", Message: " + message + ", BizId: " + bizId);
        
        if (!"OK".equals(resultCode)) {
          String error = "SMS send failed with code: " + resultCode + ", message: " + message;
          logger.error(error);
          throw new MessageSendException(-1, resultCode, error);
        } else {
          logger.info("SMS message sent successfully to " + phoneNumber + " with BizId: " + bizId);
        }
      } else {
        String error = "SMS send failed: empty response";
        logger.error(error);
        throw new MessageSendException(-1, "EMPTY_RESPONSE", error);
      }
      
    } catch (MessageSendException e) {
      throw e;
    } catch (Exception e) {
      String error = "Unexpected error sending SMS: " + e.getMessage();
      logger.error(error, e);
      throw new MessageSendException(error, e);
    }
  }

  @Override
  public void close() {
    if (client != null) {
      client.close();
    }
  }
} 