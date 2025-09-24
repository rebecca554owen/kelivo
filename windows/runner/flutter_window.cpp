#include "flutter_window.h"

#include <optional>
#include <fstream>
#include <vector>
#include <string>
#include <wincodec.h>
#include <objbase.h>  // CoInitializeEx / CoUninitialize

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
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Method channel for clipboard images.
  auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "app.clipboard",
      &flutter::StandardMethodCodec::GetInstance());

  // Use exact signature to satisfy SetMethodCallHandler type.
  channel->SetMethodCallHandler(
      [this](
          const flutter::MethodCall<flutter::EncodableValue>& call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getClipboardImages") {
          std::vector<std::string> paths;

          // Initialize COM for WIC on this thread.
          const HRESULT co_hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

          // Read CF_DIB / CF_DIBV5 from clipboard and save as PNG via WIC.
          if (OpenClipboard(nullptr)) {
            UINT fmt = 0;
            if (IsClipboardFormatAvailable(CF_DIB)) fmt = CF_DIB;
            else if (IsClipboardFormatAvailable(CF_DIBV5)) fmt = CF_DIBV5;

            if (fmt != 0) {
              HANDLE hData = GetClipboardData(fmt);
              if (hData) {
                void* data = GlobalLock(hData);
                if (data) {
                  BITMAPINFO* bmi = reinterpret_cast<BITMAPINFO*>(data);
                  // Point to pixel bits after BITMAPINFOHEADER (+ palette/masks if present).
                  BYTE* bits = reinterpret_cast<BYTE*>(data) + bmi->bmiHeader.biSize;
                  if (bmi->bmiHeader.biBitCount <= 8) {
                    // FIX (C4334): use 64-bit 1ULL to avoid 32-bit shift warning.
                    const size_t palette_entries = static_cast<size_t>(1ULL << bmi->bmiHeader.biBitCount);
                    bits += static_cast<size_t>(sizeof(RGBQUAD)) * palette_entries;
                  } else if (bmi->bmiHeader.biCompression == BI_BITFIELDS) {
                    bits += 12; // three DWORD masks
                  }

                  HDC hdc = GetDC(nullptr);
                  HBITMAP hbmp = CreateDIBitmap(
                      hdc, &bmi->bmiHeader, CBM_INIT, bits, bmi, DIB_RGB_COLORS);
                  ReleaseDC(nullptr, hdc);

                  if (hbmp) {
                    IWICImagingFactory* factory = nullptr;
                    if (SUCCEEDED(CoCreateInstance(
                            CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER,
                            IID_PPV_ARGS(&factory)))) {

                      IWICBitmap* wicBitmap = nullptr;
                      // Valid alpha options: WICBitmapUseAlpha / WICBitmapUsePremultipliedAlpha / WICBitmapIgnoreAlpha
                      if (SUCCEEDED(factory->CreateBitmapFromHBITMAP(
                              hbmp, 0, WICBitmapUseAlpha, &wicBitmap))) {

                        wchar_t tempPath[MAX_PATH];
                        GetTempPathW(MAX_PATH, tempPath);
                        wchar_t filename[MAX_PATH];
                        swprintf_s(filename, L"pasted_%llu.png",
                                   static_cast<unsigned long long>(GetTickCount64()));
                        std::wstring fullPath = std::wstring(tempPath) + filename;

                        IWICStream* stream = nullptr;
                        if (SUCCEEDED(factory->CreateStream(&stream)) &&
                            SUCCEEDED(stream->InitializeFromFilename(fullPath.c_str(), GENERIC_WRITE))) {

                          IWICBitmapEncoder* encoder = nullptr;
                          if (SUCCEEDED(factory->CreateEncoder(GUID_ContainerFormatPng, nullptr, &encoder)) &&
                              SUCCEEDED(encoder->Initialize(stream, WICBitmapEncoderNoCache))) {

                            IWICBitmapFrameEncode* frame = nullptr;
                            if (SUCCEEDED(encoder->CreateNewFrame(&frame, nullptr)) &&
                                SUCCEEDED(frame->Initialize(nullptr)) &&
                                // Optional: SetSize / SetPixelFormat. WriteSource often suffices.
                                SUCCEEDED(frame->WriteSource(wicBitmap, nullptr)) &&
                                SUCCEEDED(frame->Commit()) &&
                                SUCCEEDED(encoder->Commit())) {

                              // Convert wide path to UTF-8 for Flutter side.
                              int len = WideCharToMultiByte(
                                  CP_UTF8, 0, fullPath.c_str(), -1, nullptr, 0, nullptr, nullptr);
                              std::string utf8(len - 1, '\0');
                              WideCharToMultiByte(
                                  CP_UTF8, 0, fullPath.c_str(), -1, utf8.data(), len, nullptr, nullptr);
                              paths.push_back(utf8);
                            }
                            if (frame) frame->Release();
                            if (encoder) encoder->Release();
                          }
                          if (stream) stream->Release();
                        }
                        if (wicBitmap) wicBitmap->Release();
                      }
                      if (factory) factory->Release();
                    }
                    DeleteObject(hbmp);
                  }
                  GlobalUnlock(hData);
                }
              }
            }
            CloseClipboard();
          }

          // Return UTF-8 paths as EncodableList.
          flutter::EncodableList list;
          for (auto& p : paths) list.emplace_back(p);
          result->Success(list);

          if (SUCCEEDED(co_hr)) {
            CoUninitialize();
          }
          return;
        }

        result->NotImplemented();
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Ensure a frame is pending so the window shows.
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
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
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
