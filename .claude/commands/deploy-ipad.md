---
description: Clean deploy to iPad - 100% ensures latest build is installed
---

# Deploy to iPad

完全清理并重新部署 app 到 iPad，确保没有缓存干扰。

## 流程

按以下步骤严格顺序执行，每步确认成功后再进行下一步：

### Step 0: 关闭设备上的 app

```bash
xcrun devicectl device process terminate --device B292B314-8726-5284-B40C-5C8DE849BD7C com.ming.ankianna.AnkiAnna 2>&1 || echo "App not running, OK"
```

### Step 1: 卸载 app

```bash
xcrun devicectl device uninstall app --device B292B314-8726-5284-B40C-5C8DE849BD7C com.ming.ankianna.AnkiAnna 2>&1
```

确认输出包含 "app uninstalled" 或类似成功信息。

### Step 2: 删除 DerivedData + Clean Build

先删除项目的 DerivedData 目录，确保零缓存：

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/AnkiAnna-*
```

然后 clean build：

```bash
xcodebuild clean build \
  -workspace AnkiAnna.xcworkspace \
  -scheme AnkiAnna \
  -destination 'platform=iOS,name=盛明的iPad' \
  -allowProvisioningUpdates 2>&1 | tail -5
```

确认输出 `** BUILD SUCCEEDED **`。

### Step 3: 安装 app

找到刚构建的 .app 路径并安装：

```bash
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/AnkiAnna-*/Build/Products/Debug-iphoneos/AnkiAnna.app -maxdepth 0 2>/dev/null)
xcrun devicectl device install app --device B292B314-8726-5284-B40C-5C8DE849BD7C "$APP_PATH" 2>&1
```

### Step 4: 验证安装的是最新 build

检查 .app 的构建时间戳（应在最近 5 分钟内）：

```bash
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/AnkiAnna-*/Build/Products/Debug-iphoneos/AnkiAnna.app -maxdepth 0 2>/dev/null)
stat -f "Built: %Sm" -t "%Y-%m-%d %H:%M:%S" "$APP_PATH"
echo "Now:   $(date '+%Y-%m-%d %H:%M:%S')"
```

两个时间应相差不超过 5 分钟，否则说明安装的不是最新 build。

### Step 5: 启动 app（可选）

```bash
xcrun devicectl device process launch --device B292B314-8726-5284-B40C-5C8DE849BD7C com.ming.ankianna.AnkiAnna 2>&1
```

如果报 "Locked" 错误，提醒用户解锁 iPad 手动打开 app。

## 注意事项

- 设备 ID: `B292B314-8726-5284-B40C-5C8DE849BD7C` (盛明的iPad)
- Bundle ID: `com.ming.ankianna.AnkiAnna`
- 必须使用 xcworkspace（项目用了 CocoaPods）
- build 超时设为 300s（5 分钟）
- 如果设备未连接，先运行 `xcrun devicectl list devices` 检查
