# 阿里云短信服务提供者使用指南

本模块提供了两个不同的阿里云短信服务实现，使用统一的配置参数，通过`api-type`参数来选择使用哪个API：

## 🚀 两种实现方式

### 1. `dypns` - 短信验证码专用服务（默认）
- **API**: `dypnsapi20170525`
- **用途**: 专门用于发送短信验证码
- **特点**: 优化的验证码发送服务，支持验证码有效期管理

### 2. `dysms` - 通用短信服务
- **API**: `dysmsapi20170525`
- **用途**: 通用短信发送服务
- **特点**: 功能更全面，支持各种类型的短信发送

## 📦 部署方式

```bash
# 复制jar包到Keycloak providers目录
cp target/providers/keycloak-phone-provider.jar ${KEYCLOAK_HOME}/providers/
cp target/providers/keycloak-phone-provider.resources.jar ${KEYCLOAK_HOME}/providers/
cp target/providers/keycloak-sms-provider-aliyun.jar ${KEYCLOAK_HOME}/providers/

# 构建 Keycloak
${KEYCLOAK_HOME}/bin/kc.sh build
```

## ⚙️ 配置参数

### 使用 `dypns` API (短信验证码专用 - 默认)

```bash
${KEYCLOAK_HOME}/bin/kc.sh start \
  --spi-phone-default-service=aliyun \
  --spi-message-sender-service-aliyun-api-type=dypns \
  --spi-message-sender-service-aliyun-key=${accessKey} \
  --spi-message-sender-service-aliyun-secret=${accessSecret} \
  --spi-message-sender-service-aliyun-sign-name=${signName} \
  --spi-message-sender-service-aliyun-auth-template=${templateId}
```

### 使用 `dysms` API (通用短信服务)

```bash
${KEYCLOAK_HOME}/bin/kc.sh start \
  --spi-phone-default-service=aliyun \
  --spi-message-sender-service-aliyun-api-type=dysms \
  --spi-message-sender-service-aliyun-key=${accessKey} \
  --spi-message-sender-service-aliyun-secret=${accessSecret} \
  --spi-message-sender-service-aliyun-sign-name=${signName} \
  --spi-message-sender-service-aliyun-auth-template=${templateId}
```

### 简化配置（使用默认dypns API）

```bash
${KEYCLOAK_HOME}/bin/kc.sh start \
  --spi-phone-default-service=aliyun \
  --spi-message-sender-service-aliyun-key=${accessKey} \
  --spi-message-sender-service-aliyun-secret=${accessSecret} \
  --spi-message-sender-service-aliyun-sign-name=${signName} \
  --spi-message-sender-service-aliyun-auth-template=${templateId}
```

## 🔧 配置参数说明

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `api-type` | API类型选择 | `dypns` | `dypns` 或 `dysms` |
| `key` | 阿里云 AccessKey ID | - | `LTAI4G...` |
| `secret` | 阿里云 AccessKey Secret | - | `abc123...` |
| `sign-name` | 短信签名 | Realm显示名称 | `我的应用` |
| `{type}-template` | 短信模板 ID | - | `SMS_123456789` |

## 📋 模板配置

### 通用模板配置
```bash
--spi-message-sender-service-aliyun-{type}-template={templateId}
```

### 示例配置
```bash
# 认证验证码模板
--spi-message-sender-service-aliyun-auth-template=SMS_123456789

# 注册验证码模板
--spi-message-sender-service-aliyun-registration-template=SMS_987654321

# 重置密码模板
--spi-message-sender-service-aliyun-reset-template=SMS_555666777
```

### Realm 特定模板
```bash
# 为特定 Realm 配置模板
--spi-message-sender-service-aliyun-myrealm-auth-template=SMS_REALM_123
```

## 📊 支持的认证类型

| 类型 | 描述 | 配置键 |
|------|------|--------|
| `auth` | 登录认证 | `auth-template` |
| `registration` | 用户注册 | `registration-template` |
| `reset` | 密码重置 | `reset-template` |
| `otp` | 一次性密码 | `otp-template` |
| `verify` | 验证 | `verify-template` |

## 🔍 API 差异对比

| 特性 | dypns | dysms |
|------|-------|-------|
| API 版本 | dypnsapi20170525 | dysmsapi20170525 |
| 主要用途 | 短信验证码 | 通用短信 |
| 请求参数 | `phoneNumber` (单个) | `phoneNumbers` (可多个) |
| 响应字段 | `VerifyCode`, `OutId` | `BizId`, `RequestId` |
| 模板参数 | `{"code":"123456","min":"5"}` | `{"code":"123456","expires":"5"}` |
| 端点 | `dypnsapi.aliyuncs.com` | `dysmsapi.aliyuncs.com` |

## 🚨 注意事项

1. **API选择**: 
   - 如果不指定 `api-type`，默认使用 `dypns` (短信验证码专用)
   - 两个API使用相同的配置参数名称

2. **模板格式**: 两个实现的模板参数格式略有不同
   - `dypns`: 使用 `min` 表示分钟数
   - `dysms`: 使用 `expires` 表示过期时间

3. **签名配置**: 
   - 如果不指定 `sign-name`，系统会使用 Realm 的显示名称
   - 确保签名已在阿里云控制台中审核通过

4. **统一配置**: 两个实现使用完全相同的配置参数，便于切换

## 📝 完整配置示例

### 使用 dypns API（推荐用于验证码场景）
```bash
${KEYCLOAK_HOME}/bin/kc.sh start \
  --spi-phone-default-service=aliyun \
  --spi-message-sender-service-aliyun-api-type=dypns \
  --spi-message-sender-service-aliyun-key=LTAI4G... \
  --spi-message-sender-service-aliyun-secret=abc123... \
  --spi-message-sender-service-aliyun-sign-name=我的应用 \
  --spi-message-sender-service-aliyun-auth-template=SMS_123456789 \
  --spi-message-sender-service-aliyun-registration-template=SMS_987654321 \
  --spi-message-sender-service-aliyun-reset-template=SMS_555666777
```

### 使用 dysms API（推荐用于通用短信场景）
```bash
${KEYCLOAK_HOME}/bin/kc.sh start \
  --spi-phone-default-service=aliyun \
  --spi-message-sender-service-aliyun-api-type=dysms \
  --spi-message-sender-service-aliyun-key=LTAI4G... \
  --spi-message-sender-service-aliyun-secret=abc123... \
  --spi-message-sender-service-aliyun-sign-name=我的应用 \
  --spi-message-sender-service-aliyun-auth-template=SMS_123456789 \
  --spi-message-sender-service-aliyun-registration-template=SMS_987654321 \
  --spi-message-sender-service-aliyun-reset-template=SMS_555666777
```

## 🔗 相关链接

- [阿里云短信服务文档](https://help.aliyun.com/product/44282.html)
- [dypnsapi API 文档](https://help.aliyun.com/document_detail/111741.html)
- [dysmsapi API 文档](https://help.aliyun.com/document_detail/101414.html)

---

通过统一的配置参数，轻松切换不同的API实现！ 🎉 