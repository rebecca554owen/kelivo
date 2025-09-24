#include "flutter_window.h"

#include <optional>
#include <fstream>
#include <vector>
#include <string>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Method channel for clipboard images
  auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "app.clipboard",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "getClipboardImages") {
          std::vector<std::string> paths;
          // Try to read CF_DIB/CF_DIBV5 from clipboard and save as BMP
          if (OpenClipboard(nullptr)) {
            UINT fmt = 0;
            if (IsClipboardFormatAvailable(CF_DIB)) fmt = CF_DIB;
            else if (IsClipboardFormatAvailable(CF_DIBV5)) fmt = CF_DIBV5;
            if (fmt != 0) {
              HANDLE hData = GetClipboardData(fmt);
              if (hData) {
                void* data = GlobalLock(hData);
                if (data) {
                  SIZE_T totalSize = GlobalSize(hData);
                  // Build BMP file header
                  BITMAPINFOHEADER* bih = reinterpret_cast<BITMAPINFOHEADER*>(data);
                  DWORD colorTableSize = 0;
                  if (bih->biBitCount <= 8) {
                    colorTableSize = (1u << bih->biBitCount) * 4u;
                  } else if (bih->biCompression == BI_BITFIELDS) {
                    colorTableSize = 12u;
                  }
                  DWORD bfOffBits = sizeof(BITMAPFILEHEADER) + bih->biSize + colorTableSize;
                  DWORD bfSize = static_cast<DWORD>(sizeof(BITMAPFILEHEADER) + totalSize);

                  BITMAPFILEHEADER bfh{};
                  bfh.bfType = 0x4D42; // 'BM'
                  bfh.bfSize = bfSize;
                  bfh.bfOffBits = bfOffBits;

                  wchar_t tempPath[MAX_PATH];
                  GetTempPathW(MAX_PATH, tempPath);
                  wchar_t filename[MAX_PATH];
                  swprintf_s(filename, L"pasted_%llu.bmp", static_cast<unsigned long long>(GetTickCount64()));
                  std::wstring fullPath = std::wstring(tempPath) + filename;

                  std::ofstream ofs(fullPath, std::ios::binary);
                  if (ofs.good()) {
                    ofs.write(reinterpret_cast<const char*>(&bfh), sizeof(BITMAPFILEHEADER));
                    ofs.write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(totalSize));
                    ofs.close();
                    // Convert to UTF-8
                    int len = WideCharToMultiByte(CP_UTF8, 0, fullPath.c_str(), -1, nullptr, 0, nullptr, nullptr);
                    std::string utf8(len - 1, '\0');
                    WideCharToMultiByte(CP_UTF8, 0, fullPath.c_str(), -1, utf8.data(), len, nullptr, nullptr);
                    paths.push_back(utf8);
                  }
                  GlobalUnlock(hData);
                }
              }
            }
            CloseClipboard();
          }
          flutter::EncodableList list;
          for (auto& p : paths) list.emplace_back(p);
          result->Success(list);
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
