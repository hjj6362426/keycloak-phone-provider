<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('firstName','lastName','email','username','password','password-confirm','phoneNumber','registerCode'); section>
    <#if section = "header">
        ${msg("registerTitle")}
    <#elseif section = "form">
        <script src="https://fastly.jsdelivr.net/npm/vue/dist/vue.js"></script>
        <script src="https://fastly.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
        <style>
            .phone-verified-readonly {
                background-color: #f5f5f5;
                color: #666;
                cursor: not-allowed;
            }
            .phone-verified-info {
                font-size: 0.9em;
                color: #28a745;
                margin-top: 5px;
            }
            .required-field {
                color: #d32f2f;
                font-weight: bold;
            }
        </style>
        <div id="vue-app">
        <form id="kc-register-form" class="${properties.kcFormClass!}" action="${url.registrationAction}" method="post" @submit="validateForm">
            <div class="alert-error ${properties.kcAlertClass!} pf-m-danger" v-show="errorMessage">
                <div class="pf-c-alert__icon">
                    <span class="${properties.kcFeedbackErrorIcon!}"></span>
                </div>

                <span class="${properties.kcAlertTitleClass!}">{{ errorMessage }}</span>
            </div>

            <#if !hideEmail??>
            <div class="${properties.kcFormGroupClass!}">
                <div class="${properties.kcLabelWrapperClass!}">
                    <label for="email" class="${properties.kcLabelClass!}">${msg("email")}</label>
                </div>
                <div class="${properties.kcInputWrapperClass!}">
                    <input type="text" id="email" class="${properties.kcInputClass!}" name="email"
                           value="${(register.formData.email!'')}" autocomplete="email"
                           aria-invalid="<#if messagesPerField.existsError('email')>true</#if>"
                    />

                    <#if messagesPerField.existsError('email')>
                        <span id="input-error-email" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                            ${kcSanitize(messagesPerField.get('email'))?no_esc}
                        </span>
                    </#if>
                </div>
            </div>
            </#if>

            <#if !(realm.registrationEmailAsUsername || registrationPhoneNumberAsUsername??)>
                <div class="${properties.kcFormGroupClass!}">
                    <div class="${properties.kcLabelWrapperClass!}">
                        <label for="username" class="${properties.kcLabelClass!}">${msg("username")} <span class="required-field">*</span></label>
                    </div>
                    <div class="${properties.kcInputWrapperClass!}">
                        <input type="text" id="username" class="${properties.kcInputClass!}" name="username"
                               value="${(register.formData.username!'')}" autocomplete="username"
                               aria-invalid="<#if messagesPerField.existsError('username')>true</#if>"
                               required
                        />

                        <#if messagesPerField.existsError('username')>
                            <span id="input-error-username" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                ${kcSanitize(messagesPerField.get('username'))?no_esc}
                            </span>
                        </#if>
                    </div>
                </div>
            </#if>

            <#if passwordRequired??>
                <div class="${properties.kcFormGroupClass!}">
                    <div class="${properties.kcLabelWrapperClass!}">
                        <label for="password" class="${properties.kcLabelClass!}">${msg("password")} <span class="required-field">*</span></label>
                    </div>
                    <div class="${properties.kcInputWrapperClass!}">
                        <input type="password" id="password" class="${properties.kcInputClass!}" name="password"
                               autocomplete="new-password"
                               aria-invalid="<#if messagesPerField.existsError('password','password-confirm')>true</#if>"
                               required
                        />

                        <#if messagesPerField.existsError('password')>
                            <span id="input-error-password" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                ${kcSanitize(messagesPerField.get('password'))?no_esc}
                            </span>
                        </#if>
                    </div>
                </div>

                <div class="${properties.kcFormGroupClass!}">
                    <div class="${properties.kcLabelWrapperClass!}">
                        <label for="password-confirm"
                               class="${properties.kcLabelClass!}">${msg("passwordConfirm")} <span class="required-field">*</span></label>
                    </div>
                    <div class="${properties.kcInputWrapperClass!}">
                        <input type="password" id="password-confirm" class="${properties.kcInputClass!}"
                               name="password-confirm"
                               aria-invalid="<#if messagesPerField.existsError('password-confirm')>true</#if>"
                               required
                        />

                        <#if messagesPerField.existsError('password-confirm')>
                            <span id="input-error-password-confirm" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}
                            </span>
                        </#if>
                    </div>
                </div>
            </#if>

            <!-- 手机号码字段 -->
            <div class="${properties.kcFormGroupClass!} ${messagesPerField.printIfExists('phoneNumber',properties.kcFormGroupErrorClass!)}">
                <div class="${properties.kcLabelWrapperClass!}">
                    <label for="phoneNumber" class="${properties.kcLabelClass!}">${msg("phoneNumber")} <span class="required-field">*</span></label>
                </div>
                <div class="${properties.kcInputWrapperClass!}">
                    <input tabindex="0" id="phoneNumber" 
                           :class="['${properties.kcInputClass!}', phoneVerified ? 'phone-verified-readonly' : '']"
                           name="phoneNumber" type="tel"
                           :value="phoneNumber"
                           :readonly="phoneVerified"
                           v-model="phoneNumber"
                           aria-invalid="<#if messagesPerField.existsError('phoneNumber')>true</#if>"
                           autocomplete="mobile tel"
                           :placeholder="phoneVerified ? '' : '${msg("phoneNumber")}'"
                           required />
                    
                    <!-- 已验证状态提示 -->
                    <div v-if="phoneVerified" class="phone-verified-info">
                        <i class="fa fa-check-circle" aria-hidden="true"></i>
                        ${msg("phoneVerifiedFromLogin")}
                    </div>
                    
                    <!-- 错误信息 -->
                    <#if messagesPerField.existsError('phoneNumber')>
                        <span id="input-error-phonenumber" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                            ${kcSanitize(messagesPerField.get('phoneNumber'))?no_esc}
                        </span>
                    </#if>
                </div>
            </div>

            <!-- 验证码字段 -->
            <div class="${properties.kcFormGroupClass!}">
                <!-- 普通注册：验证码输入和发送 -->
                <template v-if="!phoneVerified">
                    <div class="${properties.kcLabelWrapperClass!}">
                        <label for="registerCode" class="${properties.kcLabelClass!}">${msg("verificationCode")} <span class="required-field">*</span></label>
                    </div>
                    <div class="${properties.kcInputWrapperClass!}" style="display: flex; gap: 10px;">
                        <div style="flex: 2;">
                            <input tabindex="0" id="code" name="registerCode"
                                   aria-invalid="<#if messagesPerField.existsError('registerCode')>true</#if>"
                                   type="text" class="${properties.kcInputClass!}"
                                   v-model="verificationCode"
                                   placeholder="${msg("verificationCode")}"
                                   autocomplete="one-time-code"
                                   required/>
                            <#if messagesPerField.existsError('registerCode')>
                                <span id="input-error-registercode" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.get('registerCode'))?no_esc}
                                </span>
                            </#if>
                        </div>
                        <div style="flex: 1;">
                            <button tabindex="0"
                                    class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}"
                                    :disabled='sendButtonText !== initSendButtonText || !phoneNumber'
                                    v-on:click="sendVerificationCode()"
                                    type="button">
                                {{ sendButtonText }}
                            </button>
                        </div>
                    </div>
                </template>
                
                <!-- 已验证手机号：显示验证状态 -->
                <template v-else>
                    <div class="alert-success ${properties.kcAlertClass!} pf-m-success">
                        <div class="pf-c-alert__icon">
                            <span class="${properties.kcFeedbackSuccessIcon!}"></span>
                        </div>
                        <span class="${properties.kcAlertTitleClass!}">${msg("phoneAlreadyVerified")}</span>
                    </div>
                    <!-- 隐藏的验证码字段，用于跳过验证 -->
                    <input type="hidden" name="registerCode" value="SKIP_VERIFICATION" />
                </template>
            </div>

            <#if recaptchaRequired??>
                <div class="form-group">
                    <div class="${properties.kcInputWrapperClass!}">
                        <div class="g-recaptcha" data-size="compact" data-sitekey="${recaptchaSiteKey}"></div>
                    </div>
                </div>
            </#if>

            <div class="${properties.kcFormGroupClass!}">
                <div id="kc-form-options" class="${properties.kcFormOptionsClass!}">
                    <div class="${properties.kcFormOptionsWrapperClass!}">
                        <span><a href="${url.loginUrl}">${kcSanitize(msg("backToLogin"))?no_esc}</a></span>
                    </div>
                </div>

                <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                    <input class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" type="submit" value="${msg("doRegister")}"/>
                </div>
            </div>
        </form>
        </div>

        <script type="text/javascript">
                function getUrlParameter(name) {
                    const urlParams = new URLSearchParams(window.location.search);
                    return urlParams.get(name);
                }
                
                function req(phoneNumber) {
                    const params = {params: {phoneNumber}}
                    axios.get(window.location.origin + '/realms/${realm.name}/sms/registration-code', params)
                        .then(res => app.disableSend(res.data.expires_in))
                        .catch(e => app.errorMessage = e.response.data.error);
                }

                const app = new Vue({
                    el: '#vue-app',
                    data: {
                        errorMessage: '',
                        phoneNumber: '${(register.formData.phoneNumber!'')}' || getUrlParameter('phoneNumber') || '',
                        phoneVerified: getUrlParameter('phoneVerified') === 'true',
                        verificationCode: '',
                        sendButtonText: '${msg("sendVerificationCode")}',
                        initSendButtonText: '${msg("sendVerificationCode")}',
                        disableSend: function (seconds) {
                            if (seconds <= 0) {
                                app.sendButtonText = app.initSendButtonText;
                            } else {
                                const minutes = Math.floor(seconds / 60) + '';
                                const seconds_ = seconds % 60 + '';
                                app.sendButtonText = String(minutes.padStart(2, '0') + ":" + seconds_.padStart(2, '0'));
                                setTimeout(function () {
                                    app.disableSend(seconds - 1);
                                }, 1000);
                            }
                        },
                        sendVerificationCode: function () {
                            this.errorMessage = '';
                            const phoneNumber = this.phoneNumber.trim();
                            if (!phoneNumber) {
                                this.errorMessage = '${msg("requiredPhoneNumber")}';
                                document.getElementById('phoneNumber').focus();
                                return;
                            }
                            if (this.sendButtonText !== this.initSendButtonText) return;
                            
                            req(phoneNumber);
                        },
                        
                        validateForm: function(event) {
                            // 如果是预验证状态，直接通过
                            if (this.phoneVerified) {
                                return true;
                            }
                            
                            // 普通注册需要验证手机号和验证码
                            if (!this.phoneNumber || this.phoneNumber.trim() === '') {
                                this.errorMessage = '${msg("requiredPhoneNumber")}';
                                if (event) event.preventDefault();
                                return false;
                            }
                            
                            if (!this.verificationCode || this.verificationCode.trim() === '') {
                                this.errorMessage = '${msg("verificationCode")} ${msg("requiredMessage")}';
                                if (event) event.preventDefault();
                                return false;
                            }
                            
                            return true;
                        }
                    }
                });

            </script>
    </#if>
</@layout.registrationLayout>