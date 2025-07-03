<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password','code','phoneNumber') displayInfo=realm.password && realm.registrationAllowed && !registrationDisabled??; section>
    <#if section = "header">
        ${msg("loginAccountTitle")}
    <#elseif section = "form">

        <#if !usernameHidden?? && supportPhone??>

            <script src="https://fastly.jsdelivr.net/npm/vue/dist/vue.js"></script>
            <script src="https://fastly.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
            <style>
                [v-cloak] > * {
                    display: none;
                }

                [v-cloak]::before {
                    content: "loading...";
                }
                
                .phone-auto-register-info {
                    background-color: #f0f9ff;
                    border: 1px solid #0284c7;
                    border-radius: 4px;
                    padding: 12px;
                    margin-bottom: 15px;
                    color: #0c4a6e;
                }
                
                .phone-auto-register-info .info-icon {
                    color: #0284c7;
                    margin-right: 8px;
                }
            </style>
        </#if>


        <div id="vue-app">
            <div v-cloak>

                    <#if realm.password>
                    <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">

                        <#if !usernameHidden?? && supportPhone??>
                            <div class="${properties.kcFormClass!}">
                                <div class="alert-error ${properties.kcAlertClass!} pf-m-danger" v-show="errorMessage">
                                    <div class="pf-c-alert__icon">
                                        <span class="${properties.kcFeedbackErrorIcon!}"></span>
                                    </div>

                                    <span class="${properties.kcAlertTitleClass!}">{{ errorMessage }}</span>
                                </div>

                                <!-- 自动注册成功提示 -->
                                <div class="alert-success ${properties.kcAlertClass!} pf-m-success" v-show="successMessage">
                                    <div class="pf-c-alert__icon">
                                        <span class="${properties.kcFeedbackSuccessIcon!}"></span>
                                    </div>
                                    <span class="${properties.kcAlertTitleClass!}">{{ successMessage }}</span>
                                </div>

                                <!-- 手机号码未注册自动跳转 -->
                                <#if showRegistrationPrompt??>
                                <script>
                                    // 自动跳转到注册页面，不显示选择弹窗
                                    window.location.href = "${url.registrationUrl}?phoneNumber=${attemptedPhoneNumber!}&phoneVerified=true";
                                </script>
                                </#if>

                                <div class="${properties.kcFormGroupClass!}">
                                    <div class="${properties.kcLabelWrapperClass!}">
                                        <ul class="nav nav-pills nav-justified">
                                            <li role="presentation" v-bind:class="{ active: !phoneActivated }"
                                                v-on:click="phoneActivated = false">
                                                <a href="#">
                                                      ${msg("loginByPassword")}
                                                </a>
                                            </li>
                                            <li role="presentation" v-bind:class="{ active: phoneActivated }"
                                                v-on:click="phoneActivated = true"><a href="#">${msg("loginByPhone")}</a>
                                            </li>
                                        </ul>
                                    </div>
                                </div>
                            </div>

                            <input type="hidden" id="phoneActivated" name="phoneActivated" v-model="phoneActivated">
                            <!-- 添加自动注册相关的隐藏字段 -->
                            <input type="hidden" name="submitAction" :value="submitAction">
                       </#if>


                        <div  <#if !usernameHidden?? && supportPhone??> v-if="!phoneActivated" </#if> >
                            <#if !usernameHidden??>
                                <div class="${properties.kcFormGroupClass!}">
                                    <label for="username" class="${properties.kcLabelClass!}">
                                        <#if !realm.loginWithEmailAllowed>${msg("username")}
                                            <#if loginWithPhoneNumber??> ${msg("usernameOrPhoneNumber")} <#else>${msg("username")}</#if>
                                        <#elseif !realm.registrationEmailAsUsername>
                                            <#if loginWithPhoneNumber??> ${msg("usernameOrEmailOrPhoneNumber")} <#else>${msg("usernameOrEmail")}</#if>
                                        <#else>
                                            <#if loginWithPhoneNumber??> ${msg("emailOrPhoneNumber")} <#else>${msg("email")}</#if>
                                        </#if>
                                    </label>

                                    <input tabindex="0" id="username" class="${properties.kcInputClass!}" name="username" value="${(login.username!'')}"  type="text" autofocus autocomplete="off"
                                           aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                                    />

                                    <#if messagesPerField.existsError('username','password')>
                                        <span id="input-error" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                            </span>
                                    </#if>

                                </div>
                            </#if>

                            <div class="${properties.kcFormGroupClass!}">
                                <label for="password" class="${properties.kcLabelClass!}">${msg("password")}</label>

                                <input tabindex="0" id="password" class="${properties.kcInputClass!}" name="password" type="password" autocomplete="off"
                                       aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                                />

                                <#if usernameHidden?? && messagesPerField.existsError('username','password')>
                                    <span id="input-error" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                                </span>
                                </#if>

                            </div>


                            <div class="${properties.kcFormGroupClass!} ${properties.kcFormSettingClass!}">
                                <div id="kc-form-options">
                                    <#if realm.rememberMe && !usernameHidden??>
                                        <div class="checkbox">
                                            <label>
                                                <#if login.rememberMe??>
                                                    <input tabindex="0" id="rememberMe" name="rememberMe" type="checkbox" checked> ${msg("rememberMe")}
                                                <#else>
                                                    <input tabindex="0" id="rememberMe" name="rememberMe" type="checkbox"> ${msg("rememberMe")}
                                                </#if>
                                            </label>
                                        </div>
                                    </#if>
                                </div>
                                <div class="${properties.kcFormOptionsWrapperClass!}">
                                    <#if realm.resetPasswordAllowed>
                                        <span><a tabindex="0" href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a></span>
                                    </#if>
                                </div>
                            </div>


                        </div>

                        <#if !usernameHidden?? && supportPhone??>
                            <div v-if="phoneActivated">
                                <!-- 自动注册说明信息 -->
                                <div class="phone-auto-register-info">
                                    <i class="fa fa-info-circle info-icon" aria-hidden="true"></i>
                                    ${msg("phoneAutoLoginInstruction")}
                                </div>
                                
                                <div class="${properties.kcFormGroupClass!}">
                                    <label for="phoneNumber" class="${properties.kcLabelClass!}">${msg("phoneNumber")}</label>
                                    <input tabindex="0" type="tel" id="phoneNumber" name="phoneNumber" 
                                           v-model="phoneNumber"
                                           value="${(attemptedPhoneNumber!'')}"
                                           placeholder="${msg("phoneNumber")}"
                                           aria-invalid="<#if messagesPerField.existsError('code','phoneNumber')>true</#if>"
                                           class="${properties.kcInputClass!}" autofocus/>
                                    <#if messagesPerField.existsError('code','phoneNumber')>
                                        <span id="input-error" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.getFirstError('phoneNumber','code'))?no_esc}
                                        </span>
                                    </#if>
                                </div>

                                <div class="${properties.kcFormGroupClass!}">
                                    <label for="sendCode" class="${properties.kcLabelClass!}">${msg("sendVerificationCode")}</label>
                                    <button id="sendCode"
                                            class="${properties.kcButtonClass!} ${properties.kcButtonDefaultClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                            type="button" 
                                            :disabled="!phoneNumber || sendingCode || countdown > 0"
                                            @click="sendVerificationCode">
                                        <span v-if="countdown > 0">${msg("sendVerificationCode")} ({{ countdown }}s)</span>
                                        <span v-else-if="sendingCode">${msg("sendVerificationCode")}...</span>
                                        <span v-else>${msg("sendVerificationCode")}</span>
                                    </button>
                                </div>

                                <div class="${properties.kcFormGroupClass!}" v-show="showCodeInput">
                                    <label for="code" class="${properties.kcLabelClass!}">${msg("verificationCode")}</label>
                                    
                                    <input tabindex="0" type="text" id="code" name="code"
                                           v-model="verificationCode"
                                           placeholder="${msg("verificationCode")}"
                                           maxlength="6"
                                           aria-invalid="<#if messagesPerField.existsError('code','phoneNumber')>true</#if>"
                                           class="${properties.kcInputClass!}" autocomplete="one-time-code"/>
                                           
                                    <#if messagesPerField.existsError('code','phoneNumber')>
                                        <span id="input-error-code" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                            ${kcSanitize(messagesPerField.getFirstError('phoneNumber','code'))?no_esc}
                                        </span>
                                    </#if>
                                </div>
                            </div>
                        </#if>


                        <div id="kc-form-buttons" class="${properties.kcFormGroupClass!}">
                            <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>/>
                            <#if !usernameHidden?? && supportPhone??>
                                <!-- 手机登录提交按钮 -->
                                <input v-if="phoneActivated && showCodeInput" 
                                       tabindex="0" 
                                       class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                       type="submit" 
                                       :disabled="!verificationCode"
                                       @click="submitPhoneLogin"
                                       value="${msg("doLogIn")}"/>
                                <!-- 密码登录提交按钮 -->
                                <input v-if="!phoneActivated" 
                                       tabindex="0" 
                                       class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                       name="login" 
                                       id="kc-login" 
                                       type="submit" 
                                       value="${msg("doLogIn")}"/>
                            <#else>
                                <input tabindex="0" class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                            </#if>
                        </div>

                    </form>
                    </#if>
            </div>
        </div>

        <#if !usernameHidden?? && supportPhone??>
            <script type="text/javascript">

                function req(phoneNumber) {
                    const params = {params: {phoneNumber}}
                    axios.get(window.location.origin + '/realms/${realm.name}/sms/authentication-code', params)
                        .then(res => app.disableSend(res.data.expires_in))
                        .catch(e => app.errorMessage = e.response.data.error);
                }

                var app = new Vue({
                    el: '#vue-app',
                    data: {
                        errorMessage: '',
                        successMessage: '',
                        freezeSendCodeSeconds: 0,
                        phoneActivated: <#if attemptedPhoneActivated??>true<#else>false</#if>,
                        phoneNumber: '${attemptedPhoneNumber!}',
                        verificationCode: '',
                        showCodeInput: ${(attemptedPhoneNumber??)?string('true', 'false')},
                        sendingCode: false,
                        countdown: 0,
                        submitAction: 'login',
                        sendButtonText: '${msg("sendVerificationCode")}',
                        initSendButtonText: '${msg("sendVerificationCode")}'
                    },
                    mounted: function() {
                        <#if expires??>
                            this.disableSend(${expires});
                        </#if>
                        <#if message??>
                            <#if message.type = 'error'>
                                this.errorMessage = '${kcSanitize(message.summary)?no_esc}';
                            <#elseif message.type = 'success'>
                                this.successMessage = '${kcSanitize(message.summary)?no_esc}';
                            </#if>
                        </#if>
                    },
                    methods: {
                        disableSend: function(seconds) {
                            this.countdown = seconds;
                            this.showCodeInput = true;
                            this.sendingCode = false;
                            
                            var timer = setInterval(() => {
                                this.countdown--;
                                if (this.countdown <= 0) {
                                    clearInterval(timer);
                                }
                            }, 1000);
                        },
                        sendVerificationCode: function() {
                            const phoneNumber = this.phoneNumber.trim();
                            if (!phoneNumber) {
                                this.errorMessage = '${msg("requiredPhoneNumber")}';
                                return;
                            }
                            if (this.countdown > 0) {
                                return;
                            }
                            
                            this.sendingCode = true;
                            this.errorMessage = '';
                            this.successMessage = '';
                            this.submitAction = 'sendCode';
                            
                            // 确保隐藏字段值被更新
                            this.$nextTick(() => {
                                document.getElementById('kc-form-login').submit();
                            });
                        },
                        submitPhoneLogin: function() {
                            if (!this.verificationCode) {
                                this.errorMessage = '${msg("requiredVerificationCode")}';
                                return;
                            }
                            this.submitAction = 'login';
                            this.errorMessage = '';
                            this.successMessage = '';
                        }
                    },
                    watch: {
                        phoneActivated: function(newVal) {
                            if (newVal) {
                                this.errorMessage = '';
                                this.successMessage = '';
                                // 切换到手机登录时重置状态
                                if (!this.phoneNumber) {
                                    this.showCodeInput = false;
                                    this.countdown = 0;
                                    this.sendingCode = false;
                                }
                            }
                        }
                    }
                });
            </script>
        </#if>

    <#elseif section = "info" >
        <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
            <div id="kc-registration-container">
                <div id="kc-registration">
                    <span>${msg("noAccount")} <a tabindex="0"
                                                 href="${url.registrationUrl}">${msg("doRegister")}</a></span>
                </div>
            </div>
        </#if>
    <#elseif section = "socialProviders" >
        <#if realm.password && social.providers?? && (social.providers?size > 0)>
            <div id="kc-social-providers" class="${properties.kcFormSocialAccountSectionClass!}">
                <hr/>
                <h4>${msg("identity-provider-login-label")}</h4>
                <ul class="${properties.kcFormSocialAccountListClass!} <#if social.providers?size gt 3>${properties.kcFormSocialAccountListGridClass!}</#if>">
                    <#list social.providers as p>
                        <a id="social-${p.alias}" class="${properties.kcFormSocialAccountListButtonClass!} <#if social.providers?size gt 3>${properties.kcFormSocialAccountGridItem!}</#if>"
                           type="button" href="${p.loginUrl}">
                            <#if p.iconClasses?has_content>
                                <i class="${properties.kcCommonLogoIdP!} ${p.iconClasses!}" aria-hidden="true"></i>
                                <span class="${properties.kcFormSocialAccountNameClass!} kc-social-icon-text">${p.displayName!}</span>
                            <#else>
                                <span class="${properties.kcFormSocialAccountNameClass!}">${p.displayName!}</span>
                            </#if>
                        </a>
                    </#list>
                </ul>
            </div>
        </#if>
    </#if>

</@layout.registrationLayout>