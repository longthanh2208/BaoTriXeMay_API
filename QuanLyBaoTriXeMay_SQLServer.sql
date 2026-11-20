-- Tạo cơ sở dữ liệu
CREATE DATABASE QuanLyBaoTriXeMay;
GO
USE QuanLyBaoTriXeMay;
GO

-- 1. Bảng Tài khoản & Phân quyền (Dùng chung cho Desktop, Web, Mobile)
CREATE TABLE TaiKhoan (
    MaTK INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap VARCHAR(50) NOT NULL UNIQUE,
    MatKhau VARCHAR(255) NOT NULL, -- Trong đề thi có thể lưu plain-text hoặc MD5/SHA256 tùy quy định
    HoTen NVARCHAR(100) NOT NULL,
    VaiTro VARCHAR(20) NOT NULL CHECK (VaiTro IN ('Admin', 'CoVan', 'KyThuatVien')),
    TrangThai BIT NOT NULL DEFAULT 1 -- 1: Hoạt động, 0: Khóa
);
GO

-- 2. Bảng Khách hàng
CREATE TABLE KhachHang (
    MaKH INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15) NOT NULL UNIQUE,
    DiaChi NVARCHAR(255) NULL,
    DaNhacLich BIT NOT NULL DEFAULT 0 -- Phục vụ chức năng chăm sóc khách hàng trên Web (Module 2)
);
GO

-- 3. Bảng Xe máy
CREATE TABLE XeMay (
    BienSo VARCHAR(20) PRIMARY KEY, -- Khóa chính tự nhiên giúp tra cứu cực nhanh ở cả 3 nền tảng
    MaKH INT NOT NULL,
    DongXe NVARCHAR(100) NOT NULL, -- VD: Honda AirBlade 125, Yamaha Exciter 155
    SoKhung VARCHAR(50) NULL,
    SoODOHienTai INT NOT NULL DEFAULT 0 CHECK (SoODOHienTai >= 0),
    NgayBaoDuongCuoi DATE NULL,
    CONSTRAINT FK_XeMay_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH) ON DELETE CASCADE
);
GO

-- 4. Bảng Phụ tùng & Vật tư (Quản lý kho trên Desktop App - Module 1)
CREATE TABLE PhuTung (
    MaPT VARCHAR(20) PRIMARY KEY, -- VD: PT001, PT002 (Hỗ trợ quét mã vạch)
    TenPT NVARCHAR(150) NOT NULL,
    DonViTinh NVARCHAR(30) NOT NULL, -- Chai, Cái, Bộ, Cặp
    GiaNhap DECIMAL(18, 0) NOT NULL CHECK (GiaNhap >= 0),
    GiaBan DECIMAL(18, 0) NOT NULL CHECK (GiaBan >= 0),
    SoLuongTon INT NOT NULL DEFAULT 0 CHECK (SoLuongTon >= 0), -- Ràng buộc không cho phép tồn kho âm
    TonToiThieu INT NOT NULL DEFAULT 5 CHECK (TonToiThieu >= 0),
    DongXeTuongThich NVARCHAR(100) NULL
);
GO

-- 5. Bảng Danh mục Dịch vụ (Tiền công thợ)
CREATE TABLE DichVu (
    MaDV VARCHAR(20) PRIMARY KEY, -- VD: DV001, DV002
    TenDV NVARCHAR(150) NOT NULL,
    DonGia DECIMAL(18, 0) NOT NULL CHECK (DonGia >= 0),
    MoTa NVARCHAR(255) NULL
);
GO

-- 6. Bảng Phiếu sửa chữa (Luồng xử lý chính giữa Web & Mobile)
CREATE TABLE PhieuSuaChua (
    MaPhieu INT IDENTITY(1,1) PRIMARY KEY,
    BienSo VARCHAR(20) NOT NULL,
    MaCoVan INT NULL, -- Tài khoản Cố vấn dịch vụ tạo phiếu
    MaKTV INT NULL,   -- Tài khoản Kỹ thuật viên được giao việc
    NgayTiepNhan DATETIME NOT NULL DEFAULT GETDATE(),
    NgayHoanThanh DATETIME NULL,
    SoODOLucNhan INT NOT NULL CHECK (SoODOLucNhan >= 0),
    GhiChuTinhTrang NVARCHAR(500) NULL,
    TrangThai NVARCHAR(30) NOT NULL DEFAULT N'ChoSua' 
        CHECK (TrangThai IN (N'ChoSua', N'DangSua', N'ChoThanhToan', N'DaThanhToan', N'DatLich')),
    TongTien DECIMAL(18, 0) NOT NULL DEFAULT 0 CHECK (TongTien >= 0),
    CONSTRAINT FK_Phieu_XeMay FOREIGN KEY (BienSo) REFERENCES XeMay(BienSo),
    CONSTRAINT FK_Phieu_CoVan FOREIGN KEY (MaCoVan) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT FK_Phieu_KTV FOREIGN KEY (MaKTV) REFERENCES TaiKhoan(MaTK)
);
GO

-- 7. Bảng Chi tiết Phiếu sửa chữa (Lưu cả Dịch vụ và Phụ tùng phát sinh)
CREATE TABLE ChiTietPhieu (
    MaCT INT IDENTITY(1,1) PRIMARY KEY,
    MaPhieu INT NOT NULL,
    LoaiMuc VARCHAR(10) NOT NULL CHECK (LoaiMuc IN ('PhuTung', 'DichVu')),
    MaPT VARCHAR(20) NULL,
    MaDV VARCHAR(20) NULL,
    SoLuong INT NOT NULL DEFAULT 1 CHECK (SoLuong > 0),
    DonGiaLucBan DECIMAL(18, 0) NOT NULL CHECK (DonGiaLucBan >= 0),
    DaHoanThanh BIT NOT NULL DEFAULT 0, -- Kỹ thuật viên tick hoàn thành từng hạng mục trên Mobile (Module 3)
    CONSTRAINT FK_CT_Phieu FOREIGN KEY (MaPhieu) REFERENCES PhieuSuaChua(MaPhieu) ON DELETE CASCADE,
    CONSTRAINT FK_CT_PhuTung FOREIGN KEY (MaPT) REFERENCES PhuTung(MaPT),
    CONSTRAINT FK_CT_DichVu FOREIGN KEY (MaDV) REFERENCES DichVu(MaDV),
    -- Ràng buộc đảm bảo mỗi dòng chi tiết chỉ là Phụ tùng HOẶC Dịch vụ
    CONSTRAINT CHK_LoaiMuc_HopLe CHECK (
        (LoaiMuc = 'PhuTung' AND MaPT IS NOT NULL AND MaDV IS NULL) OR
        (LoaiMuc = 'DichVu' AND MaDV IS NOT NULL AND MaPT IS NULL)
    )
);
GO

-- 1. Thêm Tài khoản mẫu
INSERT INTO TaiKhoan (TenDangNhap, MatKhau, HoTen, VaiTro, TrangThai) VALUES
('admin', '123456', N'Nguyễn Văn Quản Lý', 'Admin', 1),
('covan1', '123456', N'Trần Thị Thu Ngân', 'CoVan', 1),
('ktv1', '123456', N'Lê Văn Thợ Cả', 'KyThuatVien', 1),
('ktv2', '123456', N'Phạm Hoàng Kỹ Thuật', 'KyThuatVien', 1);
GO

-- 2. Thêm Khách hàng mẫu
INSERT INTO KhachHang (HoTen, SoDienThoai, DiaChi, DaNhacLich) VALUES
(N'Hoàng Minh Tuấn', '0901234567', N'123 Đường 3/2, Phường 1, TP. Đà Lạt', 0),
(N'Đặng Thị Mai Anh', '0912345678', N'45 Phan Đình Phùng, Phường 2, TP. Đà Lạt', 0),
(N'Vũ Quốc Bảo', '0987654321', N'88 Bùi Thị Xuân, Phường 8, TP. Đà Lạt', 0);
GO

-- 3. Thêm Xe máy mẫu
-- Lưu ý: Xe 49B1-123.45 có ngày bảo dưỡng cuối từ tháng 6/2026 (quá 3 tháng so với hiện tại) -> Phục vụ test nhắc lịch
INSERT INTO XeMay (BienSo, MaKH, DongXe, SoKhung, SoODOHienTai, NgayBaoDuongCuoi) VALUES
('49B1-123.45', 1, N'Honda AirBlade 125', 'RLHJF6310NY123456', 16000, '2026-06-15'),
('49B1-678.90', 2, N'Yamaha Grande 2024', 'RLCSG6410PY678901', 6200, '2026-11-10'),
('60F2-999.88', 3, N'Honda Winner X', 'RLHKC3310MY999888', 24000, '2026-07-01');
GO

-- 4. Thêm Phụ tùng mẫu
-- Lưu ý: PT003 (Lọc gió) và PT005 (Bố thắng) có SoLuongTon < TonToiThieu -> Test cảnh báo đỏ trên Desktop
INSERT INTO PhuTung (MaPT, TenPT, DonViTinh, GiaNhap, GiaBan, SoLuongTon, TonToiThieu, DongXeTuongThich) VALUES
('PT001', N'Nhớt Motul Scooter Expert 10W40 0.8L', N'Chai', 110000, 155000, 25, 10, N'Xe tay ga'),
('PT002', N'Nhớt Honda Tổng hợp 10W30 1.2L', N'Chai', 135000, 185000, 18, 8, N'Winner X, Sonic, CBR'),
('PT003', N'Lọc gió động cơ AirBlade 125', N'Cái', 65000, 110000, 3, 5, N'Honda AirBlade 125/150'),
('PT004', N'Bugi NGK Iridium CPR8EAIX-9', N'Cái', 160000, 220000, 12, 5, N'Đa số xe số & tay ga'),
('PT005', N'Má phanh (Bố thắng) đĩa trước Honda', N'Cặp', 55000, 95000, 2, 6, N'Honda AirBlade, Vision, Lead'),
('PT006', N'Bộ nhông sên dĩa DID 428HD', N'Bộ', 280000, 390000, 7, 4, N'Winner X, Exciter');
GO

-- 5. Thêm Dịch vụ mẫu
INSERT INTO DichVu (MaDV, TenDV, DonGia, MoTa) VALUES
('DV001', N'Thay nhớt máy & kiểm tra áp suất lốp', 20000, N'Miễn phí công nếu mua nhớt tại tiệm hoặc tính phí cơ bản'),
('DV002', N'Bảo dưỡng toàn bộ xe tay ga (Vệ sinh nồi, kim phun)', 250000, N'Gói bảo dưỡng định kỳ 10.000km'),
('DV003', N'Thay bố thắng đĩa & xả gió dầu phanh', 50000, N'Công thay thế và căn chỉnh hệ thống phanh'),
('DV004', N'Thay nhông sên dĩa & căn chỉnh xích', 60000, N'Công tháo lắp và bôi trơn xích tải'),
('DV005', N'Rửa xe bọt tuyết chi tiết', 35000, N'Vệ sinh ngoại thất xe');
GO

-- 6. Thêm Phiếu sửa chữa mẫu
-- Phiếu 1: Đã hoàn thành thanh toán trong quá khứ (Dùng để khách hàng tra cứu lịch sử trên Mobile App)
INSERT INTO PhieuSuaChua (BienSo, MaCoVan, MaKTV, NgayTiepNhan, NgayHoanThanh, SoODOLucNhan, GhiChuTinhTrang, TrangThai, TongTien) VALUES
('49B1-123.45', 2, 3, '2026-06-15 08:30:00', '2026-06-15 09:15:00', 16000, N'Thay nhớt định kỳ, kiểm tra thắng trước', N'DaThanhToan', 175000);

-- Phiếu 2: Đang sửa chữa tại xưởng (Dùng để Kỹ thuật viên đăng nhập Mobile App thấy việc ngay)
INSERT INTO PhieuSuaChua (BienSo, MaCoVan, MaKTV, NgayTiepNhan, NgayHoanThanh, SoODOLucNhan, GhiChuTinhTrang, TrangThai, TongTien) VALUES
('49B1-678.90', 2, 3, GETDATE(), NULL, 6200, N'Xe chạy lì máy, kêu nồi sau, cần bảo dưỡng nồi và thay nhớt', N'DangSua', 405000);

-- Phiếu 3: Khách đặt lịch online từ Mobile App đang chờ xác nhận trên Web App
INSERT INTO PhieuSuaChua (BienSo, MaCoVan, MaKTV, NgayTiepNhan, NgayHoanThanh, SoODOLucNhan, GhiChuTinhTrang, TrangThai, TongTien) VALUES
('60F2-999.88', NULL, NULL, DATEADD(DAY, 1, GETDATE()), NULL, 24000, N'Đặt lịch thay nhông sên dĩa và nhớt máy sáng mai', N'DatLich', 0);
GO

-- 7. Thêm Chi tiết phiếu mẫu
-- Chi tiết cho Phiếu 1 (Đã thanh toán)
INSERT INTO ChiTietPhieu (MaPhieu, LoaiMuc, MaPT, MaDV, SoLuong, DonGiaLucBan, DaHoanThanh) VALUES
(1, 'PhuTung', 'PT001', NULL, 1, 155000, 1),
(1, 'DichVu', NULL, 'DV001', 1, 20000, 1);

-- Chi tiết cho Phiếu 2 (Đang sửa - Kỹ thuật viên ktv1 đang làm)
INSERT INTO ChiTietPhieu (MaPhieu, LoaiMuc, MaPT, MaDV, SoLuong, DonGiaLucBan, DaHoanThanh) VALUES
(2, 'PhuTung', 'PT001', NULL, 1, 155000, 1), -- Đã thay nhớt xong
(2, 'DichVu', NULL, 'DV002', 1, 250000, 0);  -- Đang vệ sinh nồi (chưa tick hoàn thành)
GO