# Hướng Dẫn Sử Dụng SUPER IIS MANAGER v4.0

## Giới Thiệu
SUPER IIS MANAGER v4.0 là một script PowerShell giúp quản lý IIS (Internet Information Services) trên Windows một cách dễ dàng thông qua giao diện dòng lệnh (CLI). Script hỗ trợ tạo, xóa website IIS, cấu hình firewall tự động, và xử lý lỗi an toàn.

## Yêu Cầu Hệ Thống
- **Hệ điều hành**: Windows Server (có IIS) hoặc Windows 10/11 với IIS enabled.
- **PowerShell**: Phiên bản 5.1 trở lên.
- **Quyền**: Phải chạy với quyền Administrator.
- **Modules**: WebAdministration (tự động import).

### Cài Đặt IIS (nếu chưa có)
1. Mở **Control Panel** > **Programs and Features** > **Turn Windows features on or off**.
2. Tích chọn **Internet Information Services** và các thành phần con (như IIS Management Console).
3. Khởi động lại máy nếu cần.

## Cách Chạy Script
1. Tải file `IIS.ps1` về máy.
2. Mở **PowerShell** với quyền **Administrator** (chuột phải > Run as Administrator).
3. Điều hướng đến thư mục chứa file: `cd F:\CODE\0_ngichlinhtinh\Tools`
4. Chạy script: `.\IIS.ps1`
5. Nếu gặp lỗi Execution Policy: Chạy `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` trước.

## Menu Chính
Script hiển thị menu với 6 lựa chọn:

### 1. Tạo Site (Nhập Tay)
- Nhập tên site, port, đường dẫn thư mục.
- Script sẽ:
  - Tạo thư mục nếu chưa có.
  - Tạo file `index.html` mẫu.
  - Cấp quyền cho IIS_IUSRS.
  - Tạo website IIS trên port chỉ định.
  - Mở firewall cho port đó.

### 2. Tạo Site (Từ File JSON)
- Sử dụng file JSON như `testsites.json` để tạo nhiều site cùng lúc.
- Cấu trúc JSON mẫu:
  ```json
  [
    {
      "SiteName": "WebBanHang",
      "Port": 8001,
      "Folder": "F:\\Test\\Webs\\BanHang"
    },
    {
      "SiteName": "WebTinTuc",
      "Port": 8002,
      "Folder": "F:\\Test\\Webs\\TinTuc"
    }
  ]
  ```
- Nhập đường dẫn file JSON (mặc định: `config.json` nếu không nhập).

### 3. Xóa Site (Nhập Tay)
- Nhập tên site cần xóa.
- Script sẽ xóa website, app pool (nếu có), rule firewall, và hỏi có xóa thư mục vật lý không.

### 4. Xóa Site (Từ File JSON)
- Sử dụng file JSON để xóa nhiều site.
- Yêu cầu xác nhận "OK" để tránh xóa nhầm.

### 5. Kiểm Tra Site & Port
- Hiển thị danh sách các website IIS hiện tại với tên, trạng thái, đường dẫn vật lý.

### 0. Thoát
- Thoát script.

## Xử Lý Lỗi
Script có cơ chế bắt lỗi:
- **Quyền Admin**: Kiểm tra ngay đầu, thoát nếu không có.
- **Đường Dẫn**: Kiểm tra ổ đĩa tồn tại.
- **Port**: Phát hiện nếu port bị chiếm bởi phần mềm khác.
- **JSON**: Kiểm tra cú pháp file JSON.
- **Firewall**: Tự động xóa rule cũ trước khi tạo mới.

## Lưu Ý Quan Trọng
- **Backup**: Luôn backup dữ liệu trước khi xóa site.
- **Port**: Đảm bảo port không bị sử dụng (kiểm tra bằng `netstat -ano | findstr :port`).
- **Firewall**: Script tự động mở port, nhưng có thể cần cấu hình thêm trong Windows Firewall.
- **Bảo Mật**: Thư mục site được cấp quyền ReadAndExecute cho IIS_IUSRS.
- **Test**: Sau khi tạo, truy cập `http://localhost:port` để kiểm tra.

## Ví Dụ Sử Dụng
1. Chạy script.
2. Chọn 1 (Tạo site nhập tay).
3. Nhập: SiteName = "MySite", Port = 8080, Folder = "C:\MySite"
4. Script tạo site và thông báo thành công.
5. Truy cập http://localhost:8080

## Liên Hệ
Nếu gặp vấn đề, kiểm tra log lỗi trong PowerShell hoặc file event log của IIS.

---
**Tác giả**: SUPER IIS MANAGER Team  
**Phiên bản**: 4.0 - Error Handling Edition  
**Ngày**: 25/11/2025