package cc.coopersoft.keycloak.phone.authentication.authenticators.browser;

import cc.coopersoft.keycloak.phone.authentication.forms.SupportPhonePages;
import cc.coopersoft.keycloak.phone.providers.constants.TokenCodeType;
import cc.coopersoft.keycloak.phone.providers.exception.PhoneNumberInvalidException;
import cc.coopersoft.keycloak.phone.providers.spi.PhoneProvider;
import cc.coopersoft.keycloak.phone.providers.spi.PhoneVerificationCodeProvider;
import cc.coopersoft.keycloak.phone.Utils;
import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.events.Details;
import org.keycloak.events.Errors;
import org.keycloak.events.EventType;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.*;
import org.keycloak.protocol.oidc.OIDCLoginProtocol;
import org.keycloak.provider.ProviderConfigProperty;
import org.keycloak.provider.ProviderConfigurationBuilder;
import org.keycloak.services.validation.Validation;

import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import java.util.List;

import static cc.coopersoft.keycloak.phone.authentication.forms.SupportPhonePages.*;
import static org.keycloak.provider.ProviderConfigProperty.BOOLEAN_TYPE;

public class PhoneAutoRegistrationAuthenticator implements Authenticator, AuthenticatorFactory {

    private static final Logger logger = Logger.getLogger(PhoneAutoRegistrationAuthenticator.class);

    public static final String PROVIDER_ID = "phone-auto-register";
    
    private static final String CONFIG_AUTO_REGISTER = "autoRegister";
    private static final String CONFIG_SET_PHONE_AS_USERNAME = "setPhoneAsUsername";

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        LoginFormsProvider form = context.form()
                .setAttribute("phoneAutoLogin", true)
                .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true);
        
        Response challenge = form.createForm("phone-auto-login.ftl");
        context.challenge(challenge);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        
        String phoneNumber = formData.getFirst(FIELD_PHONE_NUMBER);
        String code = formData.getFirst(FIELD_VERIFICATION_CODE);
        String action = formData.getFirst("submitAction");

        if (Validation.isBlank(phoneNumber)) {
            context.form()
                    .setError(SupportPhonePages.Errors.MISSING.message())
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, challenge);
            return;
        }

        // 标准化手机号码
        try {
            phoneNumber = Utils.canonicalizePhoneNumber(context.getSession(), phoneNumber);
            logger.info("Phone number canonicalized successfully: " + phoneNumber);
        } catch (PhoneNumberInvalidException e) {
            logger.warn("Phone number validation failed for: " + phoneNumber + ", error: " + e.getMessage());
            context.form()
                    .setError(e.getErrorType().message())
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, challenge);
            return;
        }

        if ("sendCode".equals(action)) {
            sendVerificationCode(context, phoneNumber);
            return;
        }

        if (Validation.isBlank(code)) {
            context.form()
                    .setError(SupportPhonePages.Errors.NOT_MATCH.message())
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, challenge);
            return;
        }

        validateCodeAndLogin(context, phoneNumber, code.trim());
    }

    private void sendVerificationCode(AuthenticationFlowContext context, String phoneNumber) {
        PhoneProvider phoneProvider = context.getSession().getProvider(PhoneProvider.class);
        
        try {
            int expires = phoneProvider.sendTokenCode(phoneNumber, 
                    context.getConnection().getRemoteAddr(), 
                    TokenCodeType.AUTH, null);
            
            context.form()
                    .setInfo("codeSent", phoneNumber)
                    .setAttribute("expires", expires)
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.challenge(challenge);
            
        } catch (ForbiddenException e) {
            logger.warn("Send verification code forbidden!", e);
            context.form()
                    .setError(SupportPhonePages.Errors.ABUSED.message())
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.GENERIC_AUTHENTICATION_ERROR, challenge);
        } catch (Exception e) {
            logger.warn("Send verification code failed!", e);
            context.form()
                    .setError(SupportPhonePages.Errors.FAIL.message())
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.GENERIC_AUTHENTICATION_ERROR, challenge);
        }
    }

    private void validateCodeAndLogin(AuthenticationFlowContext context, String phoneNumber, String code) {
        PhoneVerificationCodeProvider phoneVerificationCodeProvider = context.getSession()
                .getProvider(PhoneVerificationCodeProvider.class);

        try {
            // 查找现有用户
            UserModel user = Utils.findUserByPhone(context.getSession(), context.getRealm(), phoneNumber)
                    .orElse(null);

            if (user == null && isAutoRegisterEnabled(context)) {
                // 自动注册新用户
                user = createNewUser(context, phoneNumber);
                if (user == null) {
                    return; // 创建用户失败，已在方法内处理错误
                }
            }

            if (user == null) {
                context.getEvent().error(Errors.USER_NOT_FOUND);
                context.form()
                        .setError("phoneUserNotFound")
                        .setAttribute("phoneAutoLogin", true)
                        .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                        .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
                Response challenge = context.form().createForm("phone-auto-login.ftl");
                context.failureChallenge(AuthenticationFlowError.INVALID_USER, challenge);
                return;
            }

            // 验证验证码
            phoneVerificationCodeProvider.validateCode(user, phoneNumber, code, TokenCodeType.AUTH);

            // 登录成功
            context.setUser(user);
            context.getEvent().user(user);
            context.getEvent().detail(Details.USERNAME, user.getUsername());
            context.success();

            logger.info("Phone auto-login successful for user: " + user.getUsername() + " with phone: " + phoneNumber);

        } catch (Exception e) {
            logger.info("Phone verification failed for phone: " + phoneNumber, e);
            context.getEvent().error(Errors.INVALID_USER_CREDENTIALS);
            context.form()
                    .setError(SupportPhonePages.Errors.NOT_MATCH.message())
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, challenge);
        }
    }

    private UserModel createNewUser(AuthenticationFlowContext context, String phoneNumber) {
        try {
            String username = isSetPhoneAsUsername(context) ? phoneNumber : generateUsername(phoneNumber);
            
            // 检查用户名是否已存在
            if (context.getSession().users().getUserByUsername(context.getRealm(), username) != null) {
                // 如果用户名冲突，记为创建失败
                logger.warn("Username conflict when creating user for phone: " + phoneNumber + ", username: " + username);
                context.getEvent().error(Errors.USERNAME_IN_USE);
                context.form()
                        .setError("usernameConflict")
                        .setAttribute("phoneAutoLogin", true)
                        .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                        .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
                Response challenge = context.form().createForm("phone-auto-login.ftl");
                context.failureChallenge(AuthenticationFlowError.USER_CONFLICT, challenge);
                return null;
            }

            UserModel newUser = context.getSession().users().addUser(context.getRealm(), username);
            newUser.setEnabled(true);
            
            // 设置手机号码属性
            newUser.setSingleAttribute("phoneNumber", phoneNumber);
            
            context.getAuthenticationSession().setClientNote(OIDCLoginProtocol.LOGIN_HINT_PARAM, username);
            
            // 记录事件
            context.getEvent().event(EventType.REGISTER)
                    .detail(Details.USERNAME, username)
                    .detail(FIELD_PHONE_NUMBER, phoneNumber)
                    .detail(Details.REGISTER_METHOD, "phone-auto")
                    .success();

            logger.info("Auto-registered new user: " + username + " with phone: " + phoneNumber);
            return newUser;

        } catch (Exception e) {
            logger.error("Failed to create new user for phone: " + phoneNumber, e);
            context.getEvent().error(Errors.GENERIC_AUTHENTICATION_ERROR);
            context.form()
                    .setError("Failed to create user account")
                    .setAttribute("phoneAutoLogin", true)
                    .setAttribute(ATTRIBUTE_SUPPORT_PHONE, true)
                    .setAttribute(ATTEMPTED_PHONE_NUMBER, phoneNumber);
            Response challenge = context.form().createForm("phone-auto-login.ftl");
            context.failureChallenge(AuthenticationFlowError.GENERIC_AUTHENTICATION_ERROR, challenge);
            return null;
        }
    }

    private String generateUsername(String phoneNumber) {
        // 移除国家代码前缀，生成用户名
        String cleanPhone = phoneNumber.replaceFirst("^\\+\\d{1,3}", "");
        return "user" + cleanPhone;
    }



    private boolean isAutoRegisterEnabled(AuthenticationFlowContext context) {
        return context.getAuthenticatorConfig() == null ||
                "true".equals(context.getAuthenticatorConfig().getConfig()
                        .getOrDefault(CONFIG_AUTO_REGISTER, "true"));
    }

    private boolean isSetPhoneAsUsername(AuthenticationFlowContext context) {
        return context.getAuthenticatorConfig() != null &&
                "true".equals(context.getAuthenticatorConfig().getConfig()
                        .getOrDefault(CONFIG_SET_PHONE_AS_USERNAME, "false"));
    }

    @Override
    public boolean requiresUser() {
        return false;
    }

    @Override
    public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) {
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
        // No required actions needed
    }

    @Override
    public void close() {
        // Nothing to close
    }

    // AuthenticatorFactory methods

    @Override
    public String getDisplayType() {
        return "Phone Auto Registration Authenticator";
    }

    @Override
    public String getReferenceCategory() {
        return "phone";
    }

    @Override
    public boolean isConfigurable() {
        return true;
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public String getHelpText() {
        return "Allows users to login with phone verification code and automatically registers new users if enabled.";
    }

    private static final List<ProviderConfigProperty> CONFIG_PROPERTIES;

    static {
        CONFIG_PROPERTIES = ProviderConfigurationBuilder.create()
                .property().name(CONFIG_AUTO_REGISTER)
                .type(BOOLEAN_TYPE)
                .label("Auto Register")
                .helpText("Automatically register new users when they login with a valid phone verification code.")
                .defaultValue(true)
                .add()
                .property().name(CONFIG_SET_PHONE_AS_USERNAME)
                .type(BOOLEAN_TYPE)
                .label("Set Phone as Username")
                .helpText("Use phone number as username for new users. If disabled, generates username like 'user123456789'.")
                .defaultValue(false)
                .add()
                .build();
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return CONFIG_PROPERTIES;
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return new AuthenticationExecutionModel.Requirement[]{
                AuthenticationExecutionModel.Requirement.REQUIRED,
                AuthenticationExecutionModel.Requirement.ALTERNATIVE,
                AuthenticationExecutionModel.Requirement.DISABLED
        };
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return this;
    }

    @Override
    public void init(org.keycloak.Config.Scope config) {
        // Nothing to initialize
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
        // Nothing to post-initialize
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
} 