# Keycloak Phone 主题背景自定义说明

## 概述

已为您的Keycloak Phone主题创建了现代化的登录界面背景样式，包含多种背景效果和响应式设计。

## 当前配置

### 已配置文件
- `resources/css/login.css` - 主要样式文件
- `theme.properties` - 已添加CSS引用

### 背景样式特性
- ✅ 现代化卡片设计（圆角、阴影、毛玻璃效果）
- ✅ 响应式布局（支持移动设备）
- ✅ 优化的表单和按钮样式
- ✅ 手机登录特有样式
- ✅ 多种背景选项（纯色、渐变、图片）

## 使用方法

### 1. 当前效果
默认使用淡蓝色背景 `#f8fafc`，适合商务场景。

### 2. 切换到渐变背景
在 `login.css` 中，将第6行的背景色注释掉，取消第9行的注释：
```css
/* background-color: #f8fafc; */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### 3. 使用图片背景

#### 步骤1：添加背景图片
将背景图片放置到：
```
resources/img/login-bg.jpg
```

#### 步骤2：修改CSS
在 `login.css` 中，注释掉纯色背景，启用图片背景代码：
```css
/* background-color: #f8fafc; */

/* 启用以下图片背景代码 */
background-image: url('../img/login-bg.jpg');
background-size: cover;
background-position: center center;
background-repeat: no-repeat;
background-attachment: fixed;
```

### 4. 自定义颜色方案

#### 修改主色调
在 `login.css` 中找到以下部分进行自定义：

**按钮颜色：**
```css
.btn-primary {
    background: linear-gradient(135deg, #your-color 0%, #your-dark-color 100%);
}
```

**表单焦点颜色：**
```css
.form-control:focus {
    border-color: #your-color;
    box-shadow: 0 0 0 3px rgba(your-rgb-values, 0.1);
}
```

## 高级自定义

### 创建动画渐变背景
```css
body.login-pf {
    background: linear-gradient(-45deg, #ee7752, #e73c7e, #23a6d5, #23d5ab);
    background-size: 400% 400%;
    animation: gradientShift 15s ease infinite;
}

@keyframes gradientShift {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}
```

### 添加暗黑模式支持
```css
@media (prefers-color-scheme: dark) {
    body.login-pf {
        background: linear-gradient(135deg, #1f2937 0%, #111827 100%);
    }
    
    .login-pf-page .card-pf {
        background: rgba(31, 41, 55, 0.95);
        color: #f9fafb;
    }
}
```

## 部署说明

### 开发环境测试
1. 重新编译项目：`mvn clean package`
2. 重启Keycloak服务
3. 访问登录页面查看效果

### 生产环境部署
1. 确保CSS缓存已清除
2. 如使用图片背景，确保图片文件已正确部署
3. 测试不同浏览器的兼容性

## 故障排除

### 样式未生效
1. 检查 `theme.properties` 中是否正确引用了CSS文件
2. 清除浏览器缓存
3. 检查Keycloak主题配置

### 图片无法显示
1. 确认图片路径正确：`../img/your-image.jpg`
2. 检查图片文件格式（推荐 JPG、PNG）
3. 确认图片文件大小（建议小于2MB）

### 移动端显示问题
已包含响应式设计，如需进一步优化：
```css
@media (max-width: 480px) {
    .login-pf-page .card-pf {
        margin: 0.5rem;
        padding: 1.5rem;
    }
}
```

## 推荐图片规格

- **尺寸：** 1920×1080 或更高
- **格式：** JPG（压缩性好）或PNG（透明背景）
- **大小：** 小于2MB
- **风格：** 避免过于复杂的图案，确保文字可读性

## 主题兼容性

- ✅ Keycloak 20.x+
- ✅ 现代浏览器（Chrome、Firefox、Safari、Edge）
- ✅ 移动设备（iOS Safari、Android Chrome） 