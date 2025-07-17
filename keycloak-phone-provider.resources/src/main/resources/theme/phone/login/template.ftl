<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" class="${properties.kcHtmlClass!}">

<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="robots" content="noindex, nofollow">

    <#if properties.meta?has_content>
        <#list properties.meta?split(' ') as meta>
            <meta name="${meta?split('==')[0]}" content="${meta?split('==')[1]}"/>
        </#list>
    </#if>
    <title>${msg("loginTitle",(realm.displayName!''))}</title>
    <link rel="icon" href="${url.resourcesPath}/img/favicon.ico" />
    <#if properties.stylesCommon?has_content>
        <#list properties.stylesCommon?split(' ') as style>
            <link href="${url.resourcesCommonPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <#if properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <#if properties.scripts?has_content>
        <#list properties.scripts?split(' ') as script>
            <script src="${url.resourcesPath}/${script}" type="text/javascript"></script>
        </#list>
    </#if>
    <#if scripts??>
        <#list scripts as script>
            <script src="${script}" type="text/javascript"></script>
        </#list>
    </#if>
    
    <!-- 自定义背景样式 -->
    <style>
    body #kc-container-wrapper{
        display: flex;
        flex-direction: column;
        align-items: center;
        position: fixed;
        top: 15%;
    }
    body div.kc-logo-text {
        background-image: url('${url.resourcesPath}/img/keycloak-logo.png');
        background-size: 100% 100%;
        background-repeat: no-repeat;
        background-position: center;
        height: 122px;
        width: 522px;
    }
    h1#kc-page-title{
        margin: 0
    }
    div.kc-logo-text span{
        display: none !important;
    }
    .login-pf .container{
        background-color: none;
        padding: 0
    }
        /* 自定义全页面背景 */
        body.login-pf {
            /* 动态渐变背景 */
            background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
            background-size: 400% 400%;
            animation: gradientShift 15s ease infinite;
            min-height: 100vh;
        }
        
        @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        /* 自定义登录卡片样式 */
        .login-pf-page .card-pf {
            background: #fff;
            backdrop-filter: blur(20px);
            border-radius: 24px;
            box-shadow: none;
            border: 1px solid rgba(255, 255, 255, 0.3);
           color: #000;
            max-width: 500px;
      
        }
        .login-pf-page .login-pf-header{
            margin: 0
        }
        /* 登录页面标题样式 */
        .login-pf-header h1 {
            color: #1f2937;
            font-weight: 700;
            font-size: 2rem;
            text-align: center;
            margin-bottom: 2rem;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        #kc-form-buttons{
            margin-top: 0
        }
    </style>
</head>

<body class="login-pf ${bodyClass}">
    <div class="login-pf-page">
        <div id="kc-container" class="container">
            <div id="kc-container-wrapper" class="row">
               
                
                <div id="kc-header" class="${properties.kcHeaderClass!}">
                    <div id="kc-header-wrapper" class="${properties.kcHeaderWrapperClass!}">
                        <div class="kc-logo-text"><span>SynNovatour</span></div>
                    </div>
                </div>
                
                <div class="${properties.kcFormCardClass!} col-xs-12 col-sm-8 col-md-6 col-lg-5">
                    <div class="card-pf ${properties.kcCardClass!}">
                        <header class="login-pf-header">
                            <h1 id="kc-page-title"><#nested "header"></h1>
                        </header>
                        <div id="kc-content">
                            <div id="kc-content-wrapper">
                                <#-- App-initiated actions should not see warning messages about the need to complete the action -->
                                <#-- during login.                                                                               -->
                                <#if displayMessage && message?? && (message.type != 'warning' || !isAppInitiatedAction??)>
                                    <div class="alert-${message.type} ${properties.kcAlertClass!} pf-m-<#if message.type = 'error'>danger<#else>${message.type}</#if>">
                                        <div class="pf-c-alert__icon">
                                            <#if message.type = 'success'><span class="${properties.kcFeedbackSuccessIcon!}"></span></#if>
                                            <#if message.type = 'warning'><span class="${properties.kcFeedbackWarningIcon!}"></span></#if>
                                            <#if message.type = 'error'><span class="${properties.kcFeedbackErrorIcon!}"></span></#if>
                                            <#if message.type = 'info'><span class="${properties.kcFeedbackInfoIcon!}"></span></#if>
                                        </div>
                                        <span class="${properties.kcAlertTitleClass!}">${kcSanitize(message.summary)?no_esc}</span>
                                    </div>
                                </#if>
                                
                                <#nested "form">
                                
                                <#if auth?? && auth.showTryAnotherWayLink() && showAnotherWayIfPresent>
                                    <form id="kc-select-try-another-way-form" action="${url.loginAction}" method="post">
                                        <div class="${properties.kcFormGroupClass!}">
                                            <input type="hidden" name="tryAnotherWay" value="on"/>
                                            <a href="#" id="try-another-way"
                                               onclick="document.forms['kc-select-try-another-way-form'].submit();return false;">${msg("doTryAnotherWay")}</a>
                                        </div>
                                    </form>
                                </#if>
                                
                                <#if displayInfo>
                                    <div id="kc-info" class="${properties.kcSignUpClass!}">
                                        <div id="kc-info-wrapper" class="${properties.kcInfoAreaWrapperClass!}">
                                            <#nested "info">
                                        </div>
                                    </div>
                                </#if>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
</#macro>