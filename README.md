# TrollScript Photo Extension (`libPhotoModule.dylib`)

适用于 **[TrollScript](https://github.com/dompling/TrollScript-Release)** 的原生系统相册扩展模块。

通过调用 iOS 官方 `Photos.framework`（`PHPhotoLibrary` / `PHAssetChangeRequest`），为 TrollScript 的 QuickJS 运行时补全原生的系统相册读写与媒体管理 API。

---

## 🌟 核心特性

- **官方服务索引**：使用 `PHAssetChangeRequest` 保存图片，自动由 iOS `assetsd` 生成缩略图并即时出现在系统相册“最近项目”与 iCloud。
- **高性能读取**：直接调用系统底层拉取最近相片资源，按需缩放或直接导出 Base64 数据。
- **自动挂载**：动态库在加载时自动通过 `fishhook` 拦截 QuickJS 上下文初始化，无需手动在脚本中 `import`，全局直接使用 `photo` 对象。
- **编辑器智能补全**：附带 `api/zh/photo.json`，放入 App 后内置 Runestone 编辑器直接支持语法高亮与代码提示。

---

## 📖 JavaScript API 规范

### 1. 请求 / 查询相册权限
```javascript
const status = photo.requestPermission();
// 返回: 'authorized' | 'denied' | 'restricted' | 'notDetermined' | 'limited'
console.log('相册权限状态:', status);
```

### 2. 获取最近照片列表
```javascript
const photos = photo.getRecent({
  limit: 10,           // 数量限制，默认 20
  mediaType: 'image'   // 'image' | 'video' | 'all'
});

photos.forEach(item => {
  console.log(`照片ID: ${item.id}, 尺寸: ${item.width}x${item.height}`);
});
```

### 3. 获取指定照片的 Base64 编码
```javascript
if (photos.length > 0) {
  const base64Data = photo.getBase64(photos[0].id);
  console.log('Base64 字符长度:', base64Data.length);
}
```

### 4. 保存本地图片文件到系统相册
```javascript
// 保存生成的图片到系统相册胶卷
const ok = photo.saveImage('/var/mobile/Documents/output.png');
console.log(ok ? '成功保存至系统相册' : '保存失败');
```

### 5. 从系统相册删除照片
```javascript
// 触发系统删除确认框
const deleted = photo.deletePhoto(photos[0].id);
console.log('删除结果:', deleted);
```

---

## 🛠️ 项目结构

```text
├── .github/workflows/
│   └── build.yml             # GitHub Actions 自动编译工作流 (macOS + Xcode)
├── api/
│   ├── zh/photo.json         # 中文 API 定义 (用于 TrollScript 内置编辑器代码提示)
│   └── en/photo.json         # 英文 API 定义
├── src/
│   ├── TSPhotoHelper.h/m     # Photos.framework 核心底层封装
│   ├── PhotoModuleBridge.m   # QuickJS 模块绑定与自动挂载
│   ├── fishhook.h/c          # Mach-O 动态符号绑定库
│   └── quickjs.h             # QuickJS 核心接口定义
├── build.sh                  # 本地编译脚本
├── Makefile                  # Makefile 编译配置
└── README.md
```

---

## 🔨 编译构建

### 方式 1：GitHub Actions 自动构建（推荐）
推送代码或创建标签（Tag）后，GitHub Actions 会自动在 macOS Runner 上启动编译，完成后可直接在 Actions 运行详情中下载 `libPhotoModule.dylib` 构件（Artifact）。

### 方式 2：本地编译 (macOS)
```bash
chmod +x ./build.sh
./build.sh
```
或：
```bash
make
```

---

## 💉 注入与安装

1. **放入动态库**：
   将编译生成的 `libPhotoModule.dylib` 放置到 TrollScript 运行环境中的合适路径，例如通过注入工具添加加载依赖：
   ```bash
   optool install -c load -p "@executable_path/Frameworks/libPhotoModule.dylib" -t TrollScript
   ```
2. **启用编辑器代码补全**：
   将 `api/zh/photo.json` 复制到 TrollScript App 包内的 `JSModulesAPI/zh/` 目录下即可。
