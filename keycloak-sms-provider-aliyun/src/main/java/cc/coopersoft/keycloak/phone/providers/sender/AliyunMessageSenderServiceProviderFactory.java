package cc.coopersoft.keycloak.phone.providers.sender;

import cc.coopersoft.keycloak.phone.providers.spi.MessageSenderService;
import cc.coopersoft.keycloak.phone.providers.spi.MessageSenderServiceProviderFactory;
import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

public class AliyunMessageSenderServiceProviderFactory implements MessageSenderServiceProviderFactory {
  private Config.Scope config;

  @Override
  public MessageSenderService create(KeycloakSession keycloakSession) {
    // 根据配置选择使用哪个实现
    String apiType = config.get("api-type");
    if ("dysms".equalsIgnoreCase(apiType)) {
      return new AliyunDysmsSenderServiceProvider(config, keycloakSession.getContext().getRealm());
    } else {
      // 默认使用 dypns (短信验证码专用)
      return new AliyunSmsSenderServiceProvider(config, keycloakSession.getContext().getRealm());
    }
  }

  @Override
  public void init(Config.Scope config) {
    this.config = config;
  }

  @Override
  public void postInit(KeycloakSessionFactory keycloakSessionFactory) {
  }

  @Override
  public void close() {
  }

  @Override
  public String getId() {
    return "aliyun";
  }
}
