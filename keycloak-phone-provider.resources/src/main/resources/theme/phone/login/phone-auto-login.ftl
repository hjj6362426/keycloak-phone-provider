<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('phoneNumber','code'); section>
    <#if section = "header">
        ${msg("loginAccountTitle")}
    <#elseif section = "form">
        <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
        
        <div id="vue-app">
            <form id="kc-form-login" class="${properties.kcFormClass!}" action="${url.loginAction}" method="post">
                <!-- Hidden input to ensure phone number is submitted -->
                <input type="hidden" name="phoneNumber" :value="phoneNumber" />
                
                <div class="alert-error ${properties.kcAlertClass!} pf-m-danger" v-show="errorMessage">
                    <div class="pf-c-alert__icon">
                        <span class="${properties.kcFeedbackErrorIcon!}"></span>
                    </div>
                    <span class="${properties.kcAlertTitleClass!}">{{ errorMessage }}</span>
                </div>

                <div class="${properties.kcFormGroupClass!}">
                    <label for="phoneNumber" class="${properties.kcLabelClass!}">${msg("phoneNumber")}</label>
                    <div class="${properties.kcInputWrapperClass!}">
                        <input type="tel" id="phoneNumber" class="${properties.kcInputClass!}" 
                               name="phoneNumber" 
                               value="${(attemptedPhoneNumber!'')}"
                               placeholder="${msg("phoneNumber")}"
                               v-model="phoneNumber"
                               aria-invalid="<#if messagesPerField.existsError('phoneNumber')>true</#if>"
                               autofocus />

                        <#if messagesPerField.existsError('phoneNumber')>
                            <span id="input-error-phone" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                ${kcSanitize(messagesPerField.get('phoneNumber'))?no_esc}
                            </span>
                        </#if>
                    </div>
                </div>

                <div class="${properties.kcFormGroupClass!}">
                    <div class="${properties.kcInputWrapperClass!}">
                        <button class="${properties.kcButtonClass!} ${properties.kcButtonDefaultClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                type="button" 
                                :disabled="!phoneNumber || sendingCode || countdown > 0"
                                @click="sendCode">
                            <span v-if="countdown > 0">${msg("sendVerificationCode")} ({{ countdown }}s)</span>
                            <span v-else-if="sendingCode">${msg("sendVerificationCode")}...</span>
                            <span v-else>${msg("sendVerificationCode")}</span>
                        </button>
                    </div>
                </div>

                <div class="${properties.kcFormGroupClass!}" v-show="showCodeInput">
                    <label for="code" class="${properties.kcLabelClass!}">${msg("verificationCode")}</label>
                    <div class="${properties.kcInputWrapperClass!}">
                        <input type="text" id="code" class="${properties.kcInputClass!}" 
                               name="code" 
                               placeholder="${msg("verificationCode")}"
                               v-model="verificationCode"
                               maxlength="6"
                               aria-invalid="<#if messagesPerField.existsError('code')>true</#if>" />

                        <#if messagesPerField.existsError('code')>
                            <span id="input-error-code" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                ${kcSanitize(messagesPerField.get('code'))?no_esc}
                            </span>
                        </#if>
                    </div>
                </div>

                <div class="${properties.kcFormGroupClass!} ${properties.kcFormSettingClass!}">
                    <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                        <button class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" 
                                type="submit" 
                                name="submitAction" 
                                value="login"
                                v-show="showCodeInput"
                                :disabled="!verificationCode">
                            ${msg("doLogIn")}
                        </button>
                    </div>
                </div>

                <div class="${properties.kcFormGroupClass!}">
                    <div class="${properties.kcFormOptionsWrapperClass!}">
                        <#if realm.password>
                            <span><a href="${url.loginUrl}">${kcSanitize(msg("backToLogin"))?no_esc}</a></span>
                        </#if>
                    </div>
                </div>
            </form>
        </div>

        <script type="text/javascript">
            var app = new Vue({
                el: '#vue-app',
                data: {
                    phoneNumber: '${(attemptedPhoneNumber!'')}',
                    verificationCode: '',
                    showCodeInput: ${(attemptedPhoneNumber??)?string('true', 'false')},
                    sendingCode: false,
                    countdown: 0,
                    errorMessage: ''
                },
                mounted: function() {
                    <#if expires??>
                        this.disableSend(${expires});
                    </#if>
                    <#if message??>
                        <#if message.type = 'error'>
                            this.errorMessage = '${kcSanitize(message.summary)?no_esc}';
                        </#if>
                    </#if>
                },
                methods: {
                    sendCode: function(event) {
                        if (!this.phoneNumber) {
                            this.errorMessage = '${msg("requiredPhoneNumber")}';
                            return;
                        }
                        
                        this.sendingCode = true;
                        this.errorMessage = '';
                        
                        // 创建隐藏的提交按钮来发送验证码
                        var form = document.getElementById('kc-form-login');
                        var hiddenInput = document.createElement('input');
                        hiddenInput.type = 'hidden';
                        hiddenInput.name = 'submitAction';
                        hiddenInput.value = 'sendCode';
                        form.appendChild(hiddenInput);
                        
                        // 提交表单
                        form.submit();
                    },
                    disableSend: function(seconds) {
                        this.countdown = seconds;
                        this.showCodeInput = true;
                        
                        var timer = setInterval(() => {
                            this.countdown--;
                            if (this.countdown <= 0) {
                                clearInterval(timer);
                                this.sendingCode = false;
                            }
                        }, 1000);
                    }
                }
            });
        </script>
    </#if>
</@layout.registrationLayout> 