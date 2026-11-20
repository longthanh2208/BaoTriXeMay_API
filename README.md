# Hệ Thống Quản Lý Bảo Dưỡng Xe Máy TVB (Hội Thi Kỹ Năng Nghề 2026)

Dự án phần mềm số hóa quy trình vận hành trung tâm bảo dưỡng & sửa chữa xe máy TVB gồm 3 Modules:
- **Module 1**: Quản lý kho phụ tùng & danh mục dịch vụ (WinForm Desktop App).
- **Module 2**: Tiếp nhận xe, điều phối xưởng (Kanban) & thanh toán (Web App).
- **Module 3**: Công cụ cho kỹ thuật viên & khách hàng (Mobile App / Portal).

---

## 1. Cấu trúc Thư mục

```text
Taynghe2026/
├── API/                          # Backend ASP.NET Core 8 Web API
│   ├── API/
│   │   ├── Controllers/          # Toàn bộ 10 Controller API phục vụ 3 Modules
│   │   ├── Data/                 # Quản lý kết nối SQL Server (DbConnectionFactory)
│   │   ├── Models/               # Các DTOs chuẩn hóa cho Request/Response
│   │   ├── appsettings.json      # Chuỗi kết nối Database
│   │   └── Program.cs            # Cấu hình CORS, Swagger, Dependency Injection
│   └── API.slnx
├── BaoTriXe/                     # Dự án WinForm Desktop (Module 1)
├── Web_Baotri/                   # Dự án Web ASP.NET Core MVC (Module 2)
├── QuanLyBaoTriXeMay_SQLServer.sql # Kịch bản khởi tạo CSDL & dữ liệu mẫu (7 bảng)
├── proc.sql                      # Toàn bộ 44+ Stored Procedures cho cả 3 Modules
├── TVB_Exam_Overview.docx        # Đề thi tổng quan
├── TVB_Module1_VN.docx           # Hướng dẫn chi tiết Module 1
├── TVB_Module2_VN.docx           # Hướng dẫn chi tiết Module 2
├── TVB_Module3_VN.docx           # Hướng dẫn chi tiết Module 3
└── README.md
```

---

## 2. Hướng dẫn Khởi chạy Cơ sở dữ liệu

1. Mở **SQL Server Management Studio (SSMS)** hoặc dùng `sqlcmd`.
2. Chạy file khởi tạo cấu trúc 7 bảng và dữ liệu mẫu:
   ```bash
   sqlcmd -S ".\SQLEXPRESS" -E -i "QuanLyBaoTriXeMay_SQLServer.sql"
   ```
3. Chạy file tạo Stored Procedures:
   ```bash
   sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "proc.sql"
   ```

---

## 3. Cấu hình và Khởi chạy API Backend

1. Di chuyển vào thư mục dự án API:
   ```bash
   cd API/API
   ```
2. Kiểm tra chuỗi kết nối trong `appsettings.json`:
   ```json
   "ConnectionStrings": {
     "QuanLyBaoTriXeMayConnection": "Server=.\\SQLEXPRESS;Database=QuanLyBaoTriXeMay;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true;"
   }
   ```
3. Chạy ứng dụng:
   ```bash
   dotnet run
   ```
4. Truy cập tài liệu tương tác Swagger UI:
   - URL: `http://localhost:5292/` hoặc `https://localhost:7112/`

---

## 4. Danh mục API Endpoints

### 4.1. Xác thực & Tài khoản (`/api/Auth`)
- `POST /api/Auth/login`: Đăng nhập hệ thống (kiểm tra tài khoản, mật khẩu, trạng thái).
- `POST /api/Auth/change-password`: Đổi mật khẩu tài khoản.
- `GET /api/Auth/ktv-list`: Lấy danh sách kỹ thuật viên đang hoạt động kèm số lượng xe đang làm.

### 4.2. Quản lý Phụ tùng (`/api/PhuTung`) - Module 1
- `GET /api/PhuTung`: Lấy danh sách phụ tùng (kèm cờ cảnh báo `CanhBaoSapHet` khi tồn kho < tồn tối thiểu).
- `GET /api/PhuTung/search?q={keyword}`: Tìm kiếm phụ tùng theo mã hoặc tên.
- `GET /api/PhuTung/{maPt}`: Xem chi tiết phụ tùng.
- `POST /api/PhuTung`: Thêm mới phụ tùng.
- `PUT /api/PhuTung/{maPt}`: Cập nhật thông tin phụ tùng.
- `DELETE /api/PhuTung/{maPt}`: Xóa phụ tùng (kiểm tra ràng buộc hóa đơn).
- `GET /api/PhuTung/canh-bao-ton-kho`: Danh sách phụ tùng cần nhập gấp.
- `POST /api/PhuTung/nhap-kho`: Nhập kho (tự động cộng dồn tồn kho và cập nhật giá nhập mới).

### 4.3. Quản lý Dịch vụ (`/api/DichVu`) - Module 1
- `GET /api/DichVu`: Danh sách dịch vụ & tiền công thợ.
- `GET /api/DichVu/search?q={keyword}`: Tìm kiếm dịch vụ.
- `GET /api/DichVu/{maDv}`: Chi tiết dịch vụ.
- `POST /api/DichVu`: Thêm mới dịch vụ.
- `PUT /api/DichVu/{maDv}`: Cập nhật dịch vụ.
- `DELETE /api/DichVu/{maDv}`: Xóa dịch vụ.

### 4.4. Thống kê Kho (`/api/ThongKe`) - Module 1
- `GET /api/ThongKe/tong-quan-kho`: Báo cáo số mặt hàng, tồn kho, tổng giá trị tồn kho theo giá nhập và giá bán.

### 4.5. Tiếp nhận Xe (`/api/TiepNhan`) - Module 2
- `GET /api/TiepNhan/tra-cuu/{bienSo}`: Quét/tra cứu biển số xe và 5 lần sửa chữa gần nhất.
- `GET /api/TiepNhan/khach-hang/sdt/{sdt}`: Tìm khách hàng và danh sách xe theo số điện thoại.
- `POST /api/TiepNhan/tao-khach-va-xe`: Tạo nhanh hồ sơ Khách hàng + Xe máy trên cùng 1 màn hình.

### 4.6. Lập Phiếu & Báo giá (`/api/PhieuSuaChua`) - Module 2
- `POST /api/PhieuSuaChua/tao-phieu`: Tạo phiếu sửa chữa mới với trạng thái mặc định `'ChoSua'`.
- `GET /api/PhieuSuaChua/{maPhieu}`: Xem chi tiết phiếu và các hạng mục phụ tùng/dịch vụ.
- `POST /api/PhieuSuaChua/them-phu-tung`: Thêm phụ tùng vào phiếu, tự động tính tổng tiền.
- `POST /api/PhieuSuaChua/them-dich-vu`: Thêm dịch vụ vào phiếu, tự động tính tổng tiền.
- `PUT /api/PhieuSuaChua/cap-nhat-so-luong`: Điều chỉnh số lượng hạng mục.
- `DELETE /api/PhieuSuaChua/xoa-hang-muc/{maCt}`: Xóa hạng mục khỏi phiếu.

### 4.7. Điều phối Xưởng (`/api/DieuPhoi`) - Module 2
- `GET /api/DieuPhoi/bang-trang-thai`: Lấy dữ liệu cho bảng Kanban 3 cột (`ChoSua`, `DangSua`, `ChoThanhToan`).
- `POST /api/DieuPhoi/phan-cong-ktv`: Phân công kỹ thuật viên và tự động chuyển sang `'DangSua'`.
- `POST /api/DieuPhoi/chuyen-trang-thai`: Chuyển trạng thái phiếu.

### 4.8. Thanh toán & Chăm sóc KH (`/api/ThanhToan`) - Module 2
- `POST /api/ThanhToan/chot-hoa-don/{maPhieu}`: Chốt hóa đơn thanh toán:
  - Kiểm tra tồn kho của tất cả phụ tùng trong phiếu.
  - Tự động trừ tồn kho phụ tùng.
  - Cập nhật số ODO và ngày bảo dưỡng cuối của xe.
  - Chuyển trạng thái sang `'DaThanhToan'`.
- `GET /api/ThanhToan/in-hoa-don/{maPhieu}`: Lấy dữ liệu in hóa đơn thanh toán chi tiết.
- `GET /api/ThanhToan/nhac-lich?soThang=3`: Danh sách xe quá hạn bảo dưỡng định kỳ.
- `POST /api/ThanhToan/danh-dau-nhac-lich/{maKh}`: Đánh dấu đã liên hệ nhắc lịch.

### 4.9. Kỹ thuật viên Mobile (`/api/Ktv`) - Module 3
- `GET /api/Ktv/cong-viec/{maKtv}`: Danh sách phiếu đang phân công cho KTV (`DangSua`).
- `GET /api/Ktv/chi-tiet-cong-viec/{maPhieu}`: Chi tiết các hạng mục thợ cần làm.
- `POST /api/Ktv/cap-nhat-tien-do`: Tick hoàn thành từng hạng mục (`DaHoanThanh = 1`).
- `POST /api/Ktv/them-phu-tung-phat-sinh`: Thêm phụ tùng phát sinh (kiểm tra tồn kho trước khi thêm).
- `POST /api/Ktv/them-dich-vu-phat-sinh`: Thêm công thợ phát sinh.
- `POST /api/Ktv/hoan-tat-sua-chua`: Nút "Hoàn tất sửa chữa" chuyển phiếu sang `'ChoThanhToan'`.

### 4.10. Khách hàng Portal & Đặt lịch (`/api/KhachHang`) - Module 3
- `GET /api/KhachHang/so-bao-duong/{bienSo}`: Sổ bảo dưỡng điện tử (tra cứu theo biển số, không cần đăng nhập).
- `GET /api/KhachHang/lich-su-chi-tiet/{maPhieu}?bienSo={bienSo}`: Chi tiết các hạng mục trong lần bảo dưỡng trước.
- `POST /api/KhachHang/dat-lich-hen`: Khách đặt lịch bảo dưỡng trực tuyến (trạng thái `'DatLich'`).
- `POST /api/KhachHang/tiep-nhan-lich-hen`: Cố vấn tiếp nhận xe hẹn sang `'ChoSua'`.

---

## 5. Hướng dẫn Đẩy Dự án lên GitHub

```bash
# 1. Khởi tạo Git repo
git init

# 2. Thêm toàn bộ mã nguồn
git add .

# 3. Tạo commit đầu tiên
git commit -m "feat: complete backend API, stored procedures and project setup for TVB 2026"

# 4. Đổi tên nhánh sang main
git branch -M main

# 5. Liên kết kho lưu trữ GitHub của bạn
git remote add origin https://github.com/<USERNAME>/<REPO_NAME>.git

# 6. Đẩy mã nguồn lên GitHub
git push -u origin main
```
