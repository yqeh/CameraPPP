# GitHub Actions → TestFlight 設定指南

在 **Windows 無 Xcode** 的情況下，push 程式碼到 GitHub 後，雲端 Mac 會自動建置並上傳 TestFlight，您只需用 iPhone 安裝測試。

## 流程概覽

```
Windows 改 code → git push → GitHub Actions (macOS) → TestFlight → iPhone 測試
```

---

## 第一步：Apple 開發者帳號準備

1. 確認已加入 [Apple Developer Program](https://developer.apple.com/programs/)（年費 USD $99）
2. 登入 [App Store Connect](https://appstoreconnect.apple.com)
3. **我的 App** → 建立 App（Bundle ID：`com.lin.energysaving`）
4. **功能** → 訂閱 → 建立月訂閱 / 年訂閱（Product ID 與 `SubscriptionConfig.swift` 一致）

---

## 第二步：建立 App Store Connect API 金鑰

1. App Store Connect → **使用者與存取** → **整合** → **App Store Connect API**
2. 點 **產生 API 金鑰**，角色選 **App 管理員** 或 **開發者**
3. 下載 `.p8` 檔（**只能下載一次，請妥善保存**）
4. 記下：
   - **Issuer ID**（整合頁面頂部）
   - **Key ID**（金鑰列表中）
   - **AuthKey_XXXXX.p8** 檔案內容

### 將 .p8 轉成 Base64（Windows PowerShell）

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\AuthKey_XXXXX.p8"))
```

複製輸出的整段 Base64 字串，稍後填入 GitHub Secret。

---

## 第三步：建立 GitHub 儲存庫並推送

若尚未建立遠端 repo：

```powershell
cd "C:\Users\User\OneDrive\文件\CameraPPP 1.6.6 上架正常版本 1.6.6\CameraPPP"
git remote add origin https://github.com/你的帳號/CameraPPP.git
git add .
git commit -m "Add GitHub Actions TestFlight CI"
git push -u origin main
```

---

## 第四步：設定 GitHub Secrets

GitHub  repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret 名稱 | 值 | 必填 |
|-------------|-----|------|
| `APP_STORE_CONNECT_KEY_ID` | API 金鑰 Key ID（例如 `AB12CD34EF`） | ✅ |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID（UUID 格式） | ✅ |
| `APP_STORE_CONNECT_KEY` | .p8 檔案的 **Base64** 字串 | ✅ |
| `BUILD_CERTIFICATE_BASE64` | 發佈憑證 .p12 的 Base64（簽章失敗時才需要） | 選填 |
| `P12_PASSWORD` | .p12 憑證密碼 | 選填 |

---

## 第五步：觸發建置

### 自動觸發
push 到 `main` 分支即自動執行。

### 手動觸發
GitHub → **Actions** → **iOS TestFlight** → **Run workflow**

---

## 第六步：iPhone 安裝 TestFlight

1. App Store 安裝 **TestFlight**
2. App Store Connect → **TestFlight** → 加入 **內部測試員**（您的 Apple ID  email）
3. 收到 TestFlight 邀請 email → 接受 → 安裝 App
4. 測試付費：App Store Connect → **使用者與存取** → **沙盒** → 建立沙盒測試帳號
5. iPhone：**設定 → App Store → 沙箱帳號** 登入沙盒帳號

---

## 常見問題

### Actions 一開始就失敗（0 秒、workflow file issue）

已修復：舊版 workflow 在 `if` 條件直接使用 secrets 會導致整個流程無法執行。請 pull 最新版後重試。

### Actions 失敗：缺少 APP_STORE_CONNECT_xxx

到 https://github.com/yqeh/CameraPPP/settings/secrets/actions 確認已設定 3 個 Secrets：

| Secret | 內容 |
|--------|------|
| `APP_STORE_CONNECT_KEY_ID` | Key ID（10 字元，例如 AB12CD34EF） |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID（UUID） |
| `APP_STORE_CONNECT_KEY` | .p8 檔案整份轉 **Base64**（不是貼 p8 原文） |

PowerShell 轉 Base64：
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\AuthKey_XXXXX.p8"))
```

### App Store Connect 尚未建立 App

必須先在 App Store Connect 建立 Bundle ID 為 `com.lin.energysaving` 的 App，否則上傳 TestFlight 會失敗。

### 建置失敗：Signing / Provisioning

多數情況在 App Store Connect 建立 App 並設定好 API 金鑰即可。若仍失敗：

1. 需借用 Mac 或雲端 Mac **匯出發佈憑證**（.p12）
2. 將 .p12 轉 Base64 填入 `BUILD_CERTIFICATE_BASE64`
3. 填入 `P12_PASSWORD`

### 建置失敗：Duplicate build number

Workflow 已用 `github.run_number` 自動遞增 Build Number，一般不需手動調整。

### 訂閱商品顯示「暫不可用」

TestFlight 版需先在 App Store Connect 建立訂閱商品，且狀態為 **準備提交**。沙盒環境可能需要數小時同步。

### 查看建置日誌

GitHub → **Actions** → 點選某次執行 → 展開 **Build and upload via Fastlane** 步驟。

---

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `.github/workflows/ios-testflight.yml` | GitHub Actions 工作流程 |
| `fastlane/Fastfile` | 建置與上傳邏輯 |
| `fastlane/Appfile` | Bundle ID 與 Team ID |
| `CameraPPP.xcodeproj/xcshareddata/xcschemes/CameraPPP.xcscheme` | CI 共用的 Xcode Scheme |
