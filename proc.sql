/*****************************************************************************************
 * HỆ THỐNG QUẢN LÝ BẢO DƯỠNG XE MÁY TVB - KỲ THI KỸ NĂNG NGHỀ CẤP TỈNH NĂM 2026
 * TẬP LỆNH STORED PROCEDURES CHO CẢ 3 MODULE (proc.sql)
 * 
 * Cơ sở dữ liệu: QuanLyBaoTriXeMay (Microsoft SQL Server)
 * Gồm 7 bảng cốt lõi: TaiKhoan, KhachHang, XeMay, PhuTung, DichVu, PhieuSuaChua, ChiTietPhieu
 * 
 * PHÂN BỔ STORED PROCEDURES:
 * ---------------------------------------------------------------------------------------
 * [PHẦN CHUNG] : Xác thực đăng nhập, Đổi mật khẩu, Danh sách Kỹ thuật viên
 * [MODULE 1]   : Quản lý Kho Phụ tùng, Danh mục Dịch vụ, Nhập kho, Cảnh báo & Thống kê
 * [MODULE 2]   : Tiếp nhận xe (Tra cứu, Tạo nhanh khách + xe), Lập phiếu sửa chữa,
 *                Bảng điều phối trạng thái xưởng (Kanban), Chốt thanh toán trừ kho, In HĐ,
 *                Chăm sóc khách hàng & Nhắc lịch bảo dưỡng
 * [MODULE 3]   : Mobile Kỹ thuật viên (Việc được giao, Tiến độ, Thêm phụ tùng phát sinh,
 *                Hoàn tất sửa chữa), Sổ bảo dưỡng điện tử tra cứu lịch sử, Đặt lịch hẹn
 *****************************************************************************************/

USE QuanLyBaoTriXeMay;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- =======================================================================================
-- THỦ TỤC NỘI BỘ HỖ TRỢ: TÍNH LẠI VÀ ĐỒNG BỘ TỔNG TIỀN PHIẾU SỬA CHỮA
-- =======================================================================================
IF OBJECT_ID('sp_PhieuSuaChua_CapNhatTongTien', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhieuSuaChua_CapNhatTongTien;
GO
CREATE PROCEDURE sp_PhieuSuaChua_CapNhatTongTien
    @MaPhieu INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TongTien DECIMAL(18, 0);

    SELECT @TongTien = ISNULL(SUM(SoLuong * DonGiaLucBan), 0)
    FROM ChiTietPhieu
    WHERE MaPhieu = @MaPhieu;

    UPDATE PhieuSuaChua
    SET TongTien = @TongTien
    WHERE MaPhieu = @MaPhieu;
END;
GO


-- =======================================================================================
-- PHẦN CHUNG: TÀI KHOẢN, PHÂN QUYỀN & XÁC THỰC HỆ THỐNG
-- =======================================================================================

------------------------------------------------------------------------------------------
-- 1. sp_TaiKhoan_DangNhap: Đăng nhập hệ thống (Dùng chung Desktop WinForm, Web, Mobile)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_TaiKhoan_DangNhap', 'P') IS NOT NULL
    DROP PROCEDURE sp_TaiKhoan_DangNhap;
GO
CREATE PROCEDURE sp_TaiKhoan_DangNhap
    @TenDangNhap VARCHAR(50),
    @MatKhau VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaTK INT, @HoTen NVARCHAR(100), @VaiTro VARCHAR(20), @TrangThai BIT;

    SELECT 
        @MaTK = MaTK,
        @HoTen = HoTen,
        @VaiTro = VaiTro,
        @TrangThai = TrangThai
    FROM TaiKhoan
    WHERE TenDangNhap = @TenDangNhap AND MatKhau = @MatKhau;

    IF @MaTK IS NULL
    BEGIN
        RAISERROR(N'Tên đăng nhập hoặc mật khẩu không chính xác!', 16, 1);
        RETURN;
    END

    IF @TrangThai = 0
    BEGIN
        RAISERROR(N'Tài khoản hiện đang bị khóa. Vui lòng liên hệ Quản trị viên!', 16, 1);
        RETURN;
    END

    -- Trả về thông tin đăng nhập thành công
    SELECT 
        MaTK,
        TenDangNhap,
        HoTen,
        VaiTro,
        TrangThai,
        N'Đăng nhập thành công' AS ThongBao
    FROM TaiKhoan
    WHERE MaTK = @MaTK;
END;
GO

------------------------------------------------------------------------------------------
-- 2. sp_TaiKhoan_DoiMatKhau: Đổi mật khẩu tài khoản
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_TaiKhoan_DoiMatKhau', 'P') IS NOT NULL
    DROP PROCEDURE sp_TaiKhoan_DoiMatKhau;
GO
CREATE PROCEDURE sp_TaiKhoan_DoiMatKhau
    @MaTK INT,
    @MatKhauCu VARCHAR(255),
    @MatKhauMoi VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE MaTK = @MaTK AND MatKhau = @MatKhauCu)
        BEGIN
            RAISERROR(N'Mật khẩu cũ không chính xác!', 16, 1);
            RETURN;
        END

        IF LEN(LTRIM(RTRIM(@MatKhauMoi))) < 6
        BEGIN
            RAISERROR(N'Mật khẩu mới phải có ít nhất 6 ký tự!', 16, 1);
            RETURN;
        END

        UPDATE TaiKhoan
        SET MatKhau = @MatKhauMoi
        WHERE MaTK = @MaTK;

        SELECT 1 AS StatusCode, N'Đổi mật khẩu thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 3. sp_TaiKhoan_LayDanhSachKTV: Lấy danh sách Kỹ thuật viên đang hoạt động (giao việc)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_TaiKhoan_LayDanhSachKTV', 'P') IS NOT NULL
    DROP PROCEDURE sp_TaiKhoan_LayDanhSachKTV;
GO
CREATE PROCEDURE sp_TaiKhoan_LayDanhSachKTV
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        tk.MaTK,
        tk.TenDangNhap,
        tk.HoTen,
        tk.TrangThai,
        (SELECT COUNT(1) FROM PhieuSuaChua p WHERE p.MaKTV = tk.MaTK AND p.TrangThai = N'DangSua') AS SoXeDangLam
    FROM TaiKhoan tk
    WHERE tk.VaiTro = 'KyThuatVien' AND tk.TrangThai = 1
    ORDER BY SoXeDangLam ASC, tk.HoTen ASC;
END;
GO


-- =======================================================================================
-- MODULE 1: QUẢN LÝ KHO PHỤ TÙNG & DỊCH VỤ (DESKTOP WINFORM - ADMIN)
-- =======================================================================================

------------------------------------------------------------------------------------------
-- 4. sp_PhuTung_LayDanhSach: Lấy danh sách phụ tùng, kèm cờ cảnh báo tồn kho (nền/chữ đỏ)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_LayDanhSach', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_LayDanhSach;
GO
CREATE PROCEDURE sp_PhuTung_LayDanhSach
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        MaPT,
        TenPT,
        DonViTinh,
        GiaNhap,
        GiaBan,
        SoLuongTon,
        TonToiThieu,
        DongXeTuongThich,
        CASE 
            WHEN SoLuongTon < TonToiThieu THEN 1 
            ELSE 0 
        END AS CanhBaoSapHet -- Trả về 1 để WinForm tô màu đỏ
    FROM PhuTung
    ORDER BY 
        CASE WHEN SoLuongTon < TonToiThieu THEN 0 ELSE 1 END,
        MaPT ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 5. sp_PhuTung_TimKiem: Tìm kiếm phụ tùng theo MaPT hoặc TenPT (hỗ trợ tìm từ 2 ký tự)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_TimKiem', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_TimKiem;
GO
CREATE PROCEDURE sp_PhuTung_TimKiem
    @TuKhoa NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET @TuKhoa = LTRIM(RTRIM(@TuKhoa));

    SELECT 
        MaPT,
        TenPT,
        DonViTinh,
        GiaNhap,
        GiaBan,
        SoLuongTon,
        TonToiThieu,
        DongXeTuongThich,
        CASE 
            WHEN SoLuongTon < TonToiThieu THEN 1 
            ELSE 0 
        END AS CanhBaoSapHet
    FROM PhuTung
    WHERE 
        (@TuKhoa = '' OR @TuKhoa IS NULL)
        OR MaPT LIKE '%' + @TuKhoa + '%'
        OR TenPT LIKE '%' + @TuKhoa + '%'
        OR DongXeTuongThich LIKE '%' + @TuKhoa + '%'
    ORDER BY MaPT ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 6. sp_PhuTung_LayTheoMa: Lấy chi tiết một phụ tùng
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_LayTheoMa', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_LayTheoMa;
GO
CREATE PROCEDURE sp_PhuTung_LayTheoMa
    @MaPT VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        MaPT,
        TenPT,
        DonViTinh,
        GiaNhap,
        GiaBan,
        SoLuongTon,
        TonToiThieu,
        DongXeTuongThich,
        CASE WHEN SoLuongTon < TonToiThieu THEN 1 ELSE 0 END AS CanhBaoSapHet
    FROM PhuTung
    WHERE MaPT = @MaPT;
END;
GO

------------------------------------------------------------------------------------------
-- 7. sp_PhuTung_ThemMoi: Thêm mới phụ tùng có kiểm tra ràng buộc nghiệp vụ
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_ThemMoi', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_ThemMoi;
GO
CREATE PROCEDURE sp_PhuTung_ThemMoi
    @MaPT VARCHAR(20),
    @TenPT NVARCHAR(150),
    @DonViTinh NVARCHAR(30),
    @GiaNhap DECIMAL(18, 0),
    @GiaBan DECIMAL(18, 0),
    @SoLuongTon INT = 0,
    @TonToiThieu INT = 5,
    @DongXeTuongThich NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Kiểm tra dữ liệu đầu vào bắt buộc
        IF @MaPT IS NULL OR LTRIM(RTRIM(@MaPT)) = ''
            THROW 50001, N'Mã phụ tùng không được để trống!', 1;
        
        IF @TenPT IS NULL OR LTRIM(RTRIM(@TenPT)) = ''
            THROW 50002, N'Tên phụ tùng không được để trống!', 1;

        IF @DonViTinh IS NULL OR LTRIM(RTRIM(@DonViTinh)) = ''
            THROW 50003, N'Đơn vị tính không được để trống!', 1;

        IF @GiaNhap < 0 OR @GiaBan < 0
            THROW 50004, N'Giá nhập và giá bán phải lớn hơn hoặc bằng 0!', 1;

        IF @SoLuongTon < 0 OR @TonToiThieu < 0
            THROW 50005, N'Số lượng tồn và tồn tối thiểu phải lớn hơn hoặc bằng 0!', 1;

        -- Kiểm tra trùng mã
        IF EXISTS (SELECT 1 FROM PhuTung WHERE MaPT = @MaPT)
            THROW 50006, N'Mã phụ tùng đã tồn tại trong hệ thống!', 1;

        INSERT INTO PhuTung (MaPT, TenPT, DonViTinh, GiaNhap, GiaBan, SoLuongTon, TonToiThieu, DongXeTuongThich)
        VALUES (LTRIM(RTRIM(@MaPT)), LTRIM(RTRIM(@TenPT)), LTRIM(RTRIM(@DonViTinh)), @GiaNhap, @GiaBan, @SoLuongTon, @TonToiThieu, @DongXeTuongThich);

        SELECT 1 AS StatusCode, N'Thêm phụ tùng mới thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 8. sp_PhuTung_CapNhat: Chỉnh sửa thông tin phụ tùng
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_CapNhat', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_CapNhat;
GO
CREATE PROCEDURE sp_PhuTung_CapNhat
    @MaPT VARCHAR(20),
    @TenPT NVARCHAR(150),
    @DonViTinh NVARCHAR(30),
    @GiaNhap DECIMAL(18, 0),
    @GiaBan DECIMAL(18, 0),
    @TonToiThieu INT,
    @DongXeTuongThich NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPT = @MaPT)
            THROW 50007, N'Phụ tùng không tồn tại!', 1;

        IF @GiaNhap < 0 OR @GiaBan < 0
            THROW 50008, N'Giá nhập và giá bán phải lớn hơn hoặc bằng 0!', 1;

        IF @TonToiThieu < 0
            THROW 50009, N'Tồn tối thiểu phải lớn hơn hoặc bằng 0!', 1;

        UPDATE PhuTung
        SET TenPT = LTRIM(RTRIM(@TenPT)),
            DonViTinh = LTRIM(RTRIM(@DonViTinh)),
            GiaNhap = @GiaNhap,
            GiaBan = @GiaBan,
            TonToiThieu = @TonToiThieu,
            DongXeTuongThich = @DongXeTuongThich
        WHERE MaPT = @MaPT;

        SELECT 1 AS StatusCode, N'Cập nhật phụ tùng thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 9. sp_PhuTung_Xoa: Xóa phụ tùng (Kiểm tra ràng buộc với ChiTietPhieu)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_Xoa;
GO
CREATE PROCEDURE sp_PhuTung_Xoa
    @MaPT VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPT = @MaPT)
            THROW 50010, N'Phụ tùng cần xóa không tồn tại!', 1;

        -- Kiểm tra phụ tùng đã từng được xuất hoặc lập trong phiếu sửa chữa chưa
        IF EXISTS (SELECT 1 FROM ChiTietPhieu WHERE MaPT = @MaPT)
            THROW 50011, N'Không thể xóa! Phụ tùng này đã phát sinh trong các phiếu sửa chữa.', 1;

        DELETE FROM PhuTung WHERE MaPT = @MaPT;

        SELECT 1 AS StatusCode, N'Đã xóa phụ tùng thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 10. sp_PhuTung_CanhBaoTonKho: Danh sách phụ tùng sắp hết hàng (SoLuongTon < TonToiThieu)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_CanhBaoTonKho', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_CanhBaoTonKho;
GO
CREATE PROCEDURE sp_PhuTung_CanhBaoTonKho
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        MaPT,
        TenPT,
        DonViTinh,
        GiaNhap,
        GiaBan,
        SoLuongTon,
        TonToiThieu,
        (TonToiThieu - SoLuongTon) AS SoLuongThieuHut,
        DongXeTuongThich
    FROM PhuTung
    WHERE SoLuongTon < TonToiThieu
    ORDER BY (TonToiThieu - SoLuongTon) DESC, SoLuongTon ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 11. sp_PhuTung_NhapKho: Nhập kho phụ tùng, tự động cộng tồn kho và cập nhật giá nhập
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhuTung_NhapKho', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhuTung_NhapKho;
GO
CREATE PROCEDURE sp_PhuTung_NhapKho
    @MaPT VARCHAR(20),
    @SoLuongNhap INT,
    @GiaNhapMoi DECIMAL(18, 0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPT = @MaPT)
            THROW 50012, N'Mã phụ tùng không tồn tại trong kho!', 1;

        IF @SoLuongNhap <= 0
            THROW 50013, N'Số lượng nhập phải lớn hơn 0!', 1;

        IF @GiaNhapMoi IS NOT NULL AND @GiaNhapMoi < 0
            THROW 50014, N'Giá nhập mới không được âm!', 1;

        -- Cập nhật tồn kho và giá nhập mới nếu có truyền
        UPDATE PhuTung
        SET 
            SoLuongTon = SoLuongTon + @SoLuongNhap,
            GiaNhap = CASE 
                        WHEN @GiaNhapMoi IS NOT NULL AND @GiaNhapMoi >= 0 THEN @GiaNhapMoi 
                        ELSE GiaNhap 
                      END
        WHERE MaPT = @MaPT;

        COMMIT TRANSACTION;

        SELECT 
            1 AS StatusCode, 
            N'Nhập kho thành công!' AS Message,
            MaPT,
            TenPT,
            SoLuongTon,
            GiaNhap
        FROM PhuTung 
        WHERE MaPT = @MaPT;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 12. sp_DichVu_LayDanhSach: Lấy danh sách dịch vụ (tiền công thợ)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DichVu_LayDanhSach', 'P') IS NOT NULL
    DROP PROCEDURE sp_DichVu_LayDanhSach;
GO
CREATE PROCEDURE sp_DichVu_LayDanhSach
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        MaDV,
        TenDV,
        DonGia,
        MoTa
    FROM DichVu
    ORDER BY MaDV ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 13. sp_DichVu_TimKiem: Tìm kiếm dịch vụ theo MaDV hoặc TenDV
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DichVu_TimKiem', 'P') IS NOT NULL
    DROP PROCEDURE sp_DichVu_TimKiem;
GO
CREATE PROCEDURE sp_DichVu_TimKiem
    @TuKhoa NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET @TuKhoa = LTRIM(RTRIM(@TuKhoa));

    SELECT 
        MaDV,
        TenDV,
        DonGia,
        MoTa
    FROM DichVu
    WHERE 
        (@TuKhoa = '' OR @TuKhoa IS NULL)
        OR MaDV LIKE '%' + @TuKhoa + '%'
        OR TenDV LIKE '%' + @TuKhoa + '%'
    ORDER BY MaDV ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 14. sp_DichVu_LayTheoMa: Lấy chi tiết 1 dịch vụ
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DichVu_LayTheoMa', 'P') IS NOT NULL
    DROP PROCEDURE sp_DichVu_LayTheoMa;
GO
CREATE PROCEDURE sp_DichVu_LayTheoMa
    @MaDV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MaDV, TenDV, DonGia, MoTa FROM DichVu WHERE MaDV = @MaDV;
END;
GO

------------------------------------------------------------------------------------------
-- 15. sp_DichVu_ThemMoi: Thêm dịch vụ mới
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DichVu_ThemMoi', 'P') IS NOT NULL
    DROP PROCEDURE sp_DichVu_ThemMoi;
GO
CREATE PROCEDURE sp_DichVu_ThemMoi
    @MaDV VARCHAR(20),
    @TenDV NVARCHAR(150),
    @DonGia DECIMAL(18, 0),
    @MoTa NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @MaDV IS NULL OR LTRIM(RTRIM(@MaDV)) = ''
            THROW 50015, N'Mã dịch vụ không được để trống!', 1;

        IF @TenDV IS NULL OR LTRIM(RTRIM(@TenDV)) = ''
            THROW 50016, N'Tên dịch vụ không được để trống!', 1;

        IF @DonGia < 0
            THROW 50017, N'Đơn giá dịch vụ phải lớn hơn hoặc bằng 0!', 1;

        IF EXISTS (SELECT 1 FROM DichVu WHERE MaDV = @MaDV)
            THROW 50018, N'Mã dịch vụ đã tồn tại trong hệ thống!', 1;

        INSERT INTO DichVu (MaDV, TenDV, DonGia, MoTa)
        VALUES (LTRIM(RTRIM(@MaDV)), LTRIM(RTRIM(@TenDV)), @DonGia, @MoTa);

        SELECT 1 AS StatusCode, N'Thêm dịch vụ thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 16. sp_DichVu_CapNhat: Cập nhật dịch vụ
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DichVu_CapNhat', 'P') IS NOT NULL
    DROP PROCEDURE sp_DichVu_CapNhat;
GO
CREATE PROCEDURE sp_DichVu_CapNhat
    @MaDV VARCHAR(20),
    @TenDV NVARCHAR(150),
    @DonGia DECIMAL(18, 0),
    @MoTa NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM DichVu WHERE MaDV = @MaDV)
            THROW 50019, N'Dịch vụ không tồn tại!', 1;

        IF @DonGia < 0
            THROW 50020, N'Đơn giá dịch vụ phải lớn hơn hoặc bằng 0!', 1;

        UPDATE DichVu
        SET TenDV = LTRIM(RTRIM(@TenDV)),
            DonGia = @DonGia,
            MoTa = @MoTa
        WHERE MaDV = @MaDV;

        SELECT 1 AS StatusCode, N'Cập nhật dịch vụ thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 17. sp_DichVu_Xoa: Xóa dịch vụ
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DichVu_Xoa', 'P') IS NOT NULL
    DROP PROCEDURE sp_DichVu_Xoa;
GO
CREATE PROCEDURE sp_DichVu_Xoa
    @MaDV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM DichVu WHERE MaDV = @MaDV)
            THROW 50021, N'Dịch vụ cần xóa không tồn tại!', 1;

        IF EXISTS (SELECT 1 FROM ChiTietPhieu WHERE MaDV = @MaDV)
            THROW 50022, N'Không thể xóa! Dịch vụ này đã được áp dụng trong phiếu sửa chữa.', 1;

        DELETE FROM DichVu WHERE MaDV = @MaDV;

        SELECT 1 AS StatusCode, N'Đã xóa dịch vụ thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 18. sp_Module1_ThongKeTongQuan: Thống kê tổng quan kho phụ tùng & dịch vụ
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_Module1_ThongKeTongQuan', 'P') IS NOT NULL
    DROP PROCEDURE sp_Module1_ThongKeTongQuan;
GO
CREATE PROCEDURE sp_Module1_ThongKeTongQuan
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        (SELECT COUNT(1) FROM PhuTung) AS TongSoMatHangPhuTung,
        (SELECT ISNULL(SUM(SoLuongTon), 0) FROM PhuTung) AS TongSoLuongTonKho,
        (SELECT ISNULL(SUM(SoLuongTon * GiaNhap), 0) FROM PhuTung) AS TongGiaTriTonKhoGiaNhap,
        (SELECT ISNULL(SUM(SoLuongTon * GiaBan), 0) FROM PhuTung) AS TongGiaTriUocTinhGiaBan,
        (SELECT COUNT(1) FROM PhuTung WHERE SoLuongTon < TonToiThieu) AS SoMatHangCanhBaoSapHet,
        (SELECT COUNT(1) FROM DichVu) AS TongSoDichVu;
END;
GO


-- =======================================================================================
-- MODULE 2: TIẾP NHẬN XE, ĐIỀU PHỐI XƯỞNG & THANH TOÁN (WEB APP)
-- =======================================================================================

------------------------------------------------------------------------------------------
-- 19. sp_TiepNhan_TraCuuBienSo: Quét/nhập biển số tra cứu thông tin xe, khách hàng & lịch sử
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_TiepNhan_TraCuuBienSo', 'P') IS NOT NULL
    DROP PROCEDURE sp_TiepNhan_TraCuuBienSo;
GO
CREATE PROCEDURE sp_TiepNhan_TraCuuBienSo
    @BienSo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET @BienSo = LTRIM(RTRIM(@BienSo));

    -- Kiểm tra xe có tồn tại không
    IF EXISTS (SELECT 1 FROM XeMay WHERE BienSo = @BienSo)
    BEGIN
        -- Kết quả 1: Thông tin xe và chủ sở hữu
        SELECT 
            x.BienSo,
            x.DongXe,
            x.SoKhung,
            x.SoODOHienTai,
            x.NgayBaoDuongCuoi,
            kh.MaKH,
            kh.HoTen AS TenKhachHang,
            kh.SoDienThoai,
            kh.DiaChi,
            kh.DaNhacLich,
            1 AS TonTai
        FROM XeMay x
        INNER JOIN KhachHang kh ON x.MaKH = kh.MaKH
        WHERE x.BienSo = @BienSo;

        -- Kết quả 2: Lịch sử các lần sửa chữa trước đây của xe
        SELECT TOP 5
            p.MaPhieu,
            p.NgayTiepNhan,
            p.NgayHoanThanh,
            p.SoODOLucNhan,
            p.GhiChuTinhTrang,
            p.TrangThai,
            p.TongTien,
            tk.HoTen AS TenCoVan,
            ktv.HoTen AS TenKTV
        FROM PhieuSuaChua p
        LEFT JOIN TaiKhoan tk ON p.MaCoVan = tk.MaTK
        LEFT JOIN TaiKhoan ktv ON p.MaKTV = ktv.MaTK
        WHERE p.BienSo = @BienSo
        ORDER BY p.NgayTiepNhan DESC;
    END
    ELSE
    BEGIN
        -- Nếu xe chưa tồn tại, báo TonTai = 0 để Web mở form tạo nhanh
        SELECT 
            @BienSo AS BienSo,
            0 AS TonTai,
            N'Xe chưa từng vào xưởng, vui lòng tạo hồ sơ mới' AS ThongBao;
    END
END;
GO

------------------------------------------------------------------------------------------
-- 20. sp_KhachHang_TimKiemTheoSDT: Tìm thông tin khách hàng theo số điện thoại
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KhachHang_TimKiemTheoSDT', 'P') IS NOT NULL
    DROP PROCEDURE sp_KhachHang_TimKiemTheoSDT;
GO
CREATE PROCEDURE sp_KhachHang_TimKiemTheoSDT
    @SoDienThoai VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    SET @SoDienThoai = LTRIM(RTRIM(@SoDienThoai));

    SELECT 
        kh.MaKH,
        kh.HoTen,
        kh.SoDienThoai,
        kh.DiaChi,
        kh.DaNhacLich
    FROM KhachHang kh
    WHERE kh.SoDienThoai = @SoDienThoai;

    -- Danh sách xe của khách này nếu có
    SELECT 
        xm.BienSo,
        xm.DongXe,
        xm.SoKhung,
        xm.SoODOHienTai,
        xm.NgayBaoDuongCuoi
    FROM XeMay xm
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    WHERE kh.SoDienThoai = @SoDienThoai;
END;
GO

------------------------------------------------------------------------------------------
-- 21. sp_TiepNhan_TaoKhachVaXe: Tạo nhanh hồ sơ KhachHang + XeMay trên cùng một màn hình
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_TiepNhan_TaoKhachVaXe', 'P') IS NOT NULL
    DROP PROCEDURE sp_TiepNhan_TaoKhachVaXe;
GO
CREATE PROCEDURE sp_TiepNhan_TaoKhachVaXe
    @HoTen NVARCHAR(100),
    @SoDienThoai VARCHAR(15),
    @DiaChi NVARCHAR(255) = NULL,
    @BienSo VARCHAR(20),
    @DongXe NVARCHAR(100),
    @SoKhung VARCHAR(50) = NULL,
    @SoODOHienTai INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        SET @SoDienThoai = LTRIM(RTRIM(@SoDienThoai));
        SET @BienSo = UPPER(LTRIM(RTRIM(@BienSo)));
        SET @HoTen = LTRIM(RTRIM(@HoTen));
        SET @DongXe = LTRIM(RTRIM(@DongXe));

        IF @HoTen = '' OR @SoDienThoai = '' OR @BienSo = '' OR @DongXe = ''
            THROW 50023, N'Vui lòng điền đầy đủ Họ tên, Số điện thoại, Biển số và Dòng xe!', 1;

        IF @SoODOHienTai < 0
            THROW 50024, N'Số ODO hiện tại không được nhỏ hơn 0!', 1;

        DECLARE @MaKH INT;

        -- 1. Xử lý khách hàng
        SELECT @MaKH = MaKH FROM KhachHang WHERE SoDienThoai = @SoDienThoai;

        IF @MaKH IS NULL
        BEGIN
            INSERT INTO KhachHang (HoTen, SoDienThoai, DiaChi, DaNhacLich)
            VALUES (@HoTen, @SoDienThoai, @DiaChi, 0);
            SET @MaKH = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            -- Cập nhật thông tin khách hàng nếu có thay đổi
            UPDATE KhachHang
            SET HoTen = @HoTen,
                DiaChi = ISNULL(@DiaChi, DiaChi)
            WHERE MaKH = @MaKH;
        END

        -- 2. Xử lý xe máy
        IF EXISTS (SELECT 1 FROM XeMay WHERE BienSo = @BienSo)
        BEGIN
            -- Cập nhật xe về chủ mới hoặc cập nhật thông tin
            UPDATE XeMay
            SET MaKH = @MaKH,
                DongXe = @DongXe,
                SoKhung = ISNULL(@SoKhung, SoKhung),
                SoODOHienTai = CASE WHEN @SoODOHienTai > SoODOHienTai THEN @SoODOHienTai ELSE SoODOHienTai END
            WHERE BienSo = @BienSo;
        END
        ELSE
        BEGIN
            INSERT INTO XeMay (BienSo, MaKH, DongXe, SoKhung, SoODOHienTai, NgayBaoDuongCuoi)
            VALUES (@BienSo, @MaKH, @DongXe, @SoKhung, @SoODOHienTai, NULL);
        END

        COMMIT TRANSACTION;

        -- Trả về dữ liệu sẵn sàng cho form lập phiếu
        SELECT 
            xm.BienSo,
            xm.DongXe,
            xm.SoKhung,
            xm.SoODOHienTai,
            kh.MaKH,
            kh.HoTen AS TenKhachHang,
            kh.SoDienThoai,
            kh.DiaChi,
            1 AS StatusCode,
            N'Tạo hồ sơ xe và khách hàng thành công!' AS Message
        FROM XeMay xm
        INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
        WHERE xm.BienSo = @BienSo;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 22. sp_PhieuSuaChua_TaoMoi: Tạo phiếu sửa chữa mới với trạng thái mặc định 'ChoSua'
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhieuSuaChua_TaoMoi', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhieuSuaChua_TaoMoi;
GO
CREATE PROCEDURE sp_PhieuSuaChua_TaoMoi
    @BienSo VARCHAR(20),
    @MaCoVan INT,
    @SoODOLucNhan INT,
    @GhiChuTinhTrang NVARCHAR(500) = NULL,
    @MaPhieuMoi INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @BienSo = UPPER(LTRIM(RTRIM(@BienSo)));

        IF NOT EXISTS (SELECT 1 FROM XeMay WHERE BienSo = @BienSo)
            THROW 50025, N'Xe máy với biển số này không tồn tại trong hệ thống!', 1;

        IF @SoODOLucNhan < 0
            THROW 50026, N'Số ODO lúc nhận không được nhỏ hơn 0!', 1;

        -- Cập nhật ODO xe nếu ODO lúc nhận lớn hơn
        UPDATE XeMay
        SET SoODOHienTai = @SoODOLucNhan
        WHERE BienSo = @BienSo AND @SoODOLucNhan > SoODOHienTai;

        -- Tạo phiếu với trạng thái ChoSua
        INSERT INTO PhieuSuaChua (
            BienSo,
            MaCoVan,
            MaKTV,
            NgayTiepNhan,
            NgayHoanThanh,
            SoODOLucNhan,
            GhiChuTinhTrang,
            TrangThai,
            TongTien
        )
        VALUES (
            @BienSo,
            @MaCoVan,
            NULL,               -- Chưa giao KTV
            GETDATE(),
            NULL,
            @SoODOLucNhan,
            @GhiChuTinhTrang,
            N'ChoSua',          -- Mặc định ChoSua
            0
        );

        SET @MaPhieuMoi = SCOPE_IDENTITY();

        SELECT 
            @MaPhieuMoi AS MaPhieu,
            @BienSo AS BienSo,
            N'ChoSua' AS TrangThai,
            N'Tạo phiếu sửa chữa mới thành công!' AS Message;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 23. sp_ChiTietPhieu_ThemPhuTung: Thêm phụ tùng vào phiếu, tự động lấy giá bán và cập nhật tổng tiền
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ChiTietPhieu_ThemPhuTung', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChiTietPhieu_ThemPhuTung;
GO
CREATE PROCEDURE sp_ChiTietPhieu_ThemPhuTung
    @MaPhieu INT,
    @MaPT VARCHAR(20),
    @SoLuong INT = 1,
    @DonGiaCustom DECIMAL(18, 0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu)
            THROW 50027, N'Phiếu sửa chữa không tồn tại!', 1;

        IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPT = @MaPT)
            THROW 50028, N'Mã phụ tùng không tồn tại!', 1;

        IF @SoLuong <= 0
            THROW 50029, N'Số lượng phụ tùng phải lớn hơn 0!', 1;

        DECLARE @DonGia DECIMAL(18, 0);
        IF @DonGiaCustom IS NOT NULL AND @DonGiaCustom >= 0
            SET @DonGia = @DonGiaCustom;
        ELSE
            SELECT @DonGia = GiaBan FROM PhuTung WHERE MaPT = @MaPT;

        -- Thêm dòng phụ tùng vào chi tiết phiếu
        INSERT INTO ChiTietPhieu (MaPhieu, LoaiMuc, MaPT, MaDV, SoLuong, DonGiaLucBan, DaHoanThanh)
        VALUES (@MaPhieu, 'PhuTung', @MaPT, NULL, @SoLuong, @DonGia, 0);

        -- Đồng bộ lại tổng tiền phiếu
        EXEC sp_PhieuSuaChua_CapNhatTongTien @MaPhieu;

        SELECT 
            SCOPE_IDENTITY() AS MaCT,
            @MaPhieu AS MaPhieu,
            N'Thêm phụ tùng vào phiếu thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 24. sp_ChiTietPhieu_ThemDichVu: Thêm dịch vụ vào phiếu, tự động lấy đơn giá và cập nhật tổng tiền
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ChiTietPhieu_ThemDichVu', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChiTietPhieu_ThemDichVu;
GO
CREATE PROCEDURE sp_ChiTietPhieu_ThemDichVu
    @MaPhieu INT,
    @MaDV VARCHAR(20),
    @SoLuong INT = 1,
    @DonGiaCustom DECIMAL(18, 0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu)
            THROW 50030, N'Phiếu sửa chữa không tồn tại!', 1;

        IF NOT EXISTS (SELECT 1 FROM DichVu WHERE MaDV = @MaDV)
            THROW 50031, N'Mã dịch vụ không tồn tại!', 1;

        IF @SoLuong <= 0
            THROW 50032, N'Số lượng dịch vụ phải lớn hơn 0!', 1;

        DECLARE @DonGia DECIMAL(18, 0);
        IF @DonGiaCustom IS NOT NULL AND @DonGiaCustom >= 0
            SET @DonGia = @DonGiaCustom;
        ELSE
            SELECT @DonGia = DonGia FROM DichVu WHERE MaDV = @MaDV;

        -- Thêm dòng dịch vụ vào chi tiết phiếu
        INSERT INTO ChiTietPhieu (MaPhieu, LoaiMuc, MaPT, MaDV, SoLuong, DonGiaLucBan, DaHoanThanh)
        VALUES (@MaPhieu, 'DichVu', NULL, @MaDV, @SoLuong, @DonGia, 0);

        -- Đồng bộ lại tổng tiền phiếu
        EXEC sp_PhieuSuaChua_CapNhatTongTien @MaPhieu;

        SELECT 
            SCOPE_IDENTITY() AS MaCT,
            @MaPhieu AS MaPhieu,
            N'Thêm dịch vụ vào phiếu thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 25. sp_ChiTietPhieu_XoaHangMuc: Xóa mục trong phiếu và tự động tính lại tổng tiền
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ChiTietPhieu_XoaHangMuc', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChiTietPhieu_XoaHangMuc;
GO
CREATE PROCEDURE sp_ChiTietPhieu_XoaHangMuc
    @MaCT INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @MaPhieu INT;
        SELECT @MaPhieu = MaPhieu FROM ChiTietPhieu WHERE MaCT = @MaCT;

        IF @MaPhieu IS NULL
            THROW 50033, N'Mục chi tiết không tồn tại!', 1;

        DELETE FROM ChiTietPhieu WHERE MaCT = @MaCT;

        -- Cập nhật lại tổng tiền phiếu
        EXEC sp_PhieuSuaChua_CapNhatTongTien @MaPhieu;

        SELECT 1 AS StatusCode, N'Đã xóa hạng mục khỏi phiếu!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 26. sp_ChiTietPhieu_CapNhatSoLuong: Sửa số lượng của hạng mục trong phiếu
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ChiTietPhieu_CapNhatSoLuong', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChiTietPhieu_CapNhatSoLuong;
GO
CREATE PROCEDURE sp_ChiTietPhieu_CapNhatSoLuong
    @MaCT INT,
    @SoLuongMoi INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @SoLuongMoi <= 0
            THROW 50034, N'Số lượng phải lớn hơn 0!', 1;

        DECLARE @MaPhieu INT;
        SELECT @MaPhieu = MaPhieu FROM ChiTietPhieu WHERE MaCT = @MaCT;

        IF @MaPhieu IS NULL
            THROW 50035, N'Mục chi tiết không tồn tại!', 1;

        UPDATE ChiTietPhieu
        SET SoLuong = @SoLuongMoi
        WHERE MaCT = @MaCT;

        EXEC sp_PhieuSuaChua_CapNhatTongTien @MaPhieu;

        SELECT 1 AS StatusCode, N'Cập nhật số lượng thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 27. sp_PhieuSuaChua_LayChiTiet: Lấy chi tiết toàn bộ phiếu (Thông tin phiếu + Bảng chi tiết)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_PhieuSuaChua_LayChiTiet', 'P') IS NOT NULL
    DROP PROCEDURE sp_PhieuSuaChua_LayChiTiet;
GO
CREATE PROCEDURE sp_PhieuSuaChua_LayChiTiet
    @MaPhieu INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Resultset 1: Thông tin đầu phiếu
    SELECT 
        p.MaPhieu,
        p.BienSo,
        xm.DongXe,
        xm.SoKhung,
        kh.MaKH,
        kh.HoTen AS TenKhachHang,
        kh.SoDienThoai,
        kh.DiaChi,
        p.MaCoVan,
        cv.HoTen AS TenCoVan,
        p.MaKTV,
        ktv.HoTen AS TenKTV,
        p.NgayTiepNhan,
        p.NgayHoanThanh,
        p.SoODOLucNhan,
        p.GhiChuTinhTrang,
        p.TrangThai,
        p.TongTien
    FROM PhieuSuaChua p
    INNER JOIN XeMay xm ON p.BienSo = xm.BienSo
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    LEFT JOIN TaiKhoan cv ON p.MaCoVan = cv.MaTK
    LEFT JOIN TaiKhoan ktv ON p.MaKTV = ktv.MaTK
    WHERE p.MaPhieu = @MaPhieu;

    -- Resultset 2: Danh sách chi tiết phụ tùng & dịch vụ
    SELECT 
        ct.MaCT,
        ct.MaPhieu,
        ct.LoaiMuc,
        CASE ct.LoaiMuc 
            WHEN 'PhuTung' THEN pt.MaPT 
            ELSE dv.MaDV 
        END AS MaHangMuc,
        CASE ct.LoaiMuc 
            WHEN 'PhuTung' THEN pt.TenPT 
            ELSE dv.TenDV 
        END AS TenHangMuc,
        CASE ct.LoaiMuc 
            WHEN 'PhuTung' THEN pt.DonViTinh 
            ELSE N'Lần' 
        END AS DonViTinh,
        ct.SoLuong,
        ct.DonGiaLucBan,
        (ct.SoLuong * ct.DonGiaLucBan) AS ThanhTien,
        ct.DaHoanThanh
    FROM ChiTietPhieu ct
    LEFT JOIN PhuTung pt ON ct.MaPT = pt.MaPT
    LEFT JOIN DichVu dv ON ct.MaDV = dv.MaDV
    WHERE ct.MaPhieu = @MaPhieu
    ORDER BY ct.LoaiMuc DESC, ct.MaCT ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 28. sp_DieuPhoi_LayBangTrangThai: Lấy dữ liệu cho Bảng điều phối xưởng (Kanban 3 cột)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DieuPhoi_LayBangTrangThai', 'P') IS NOT NULL
    DROP PROCEDURE sp_DieuPhoi_LayBangTrangThai;
GO
CREATE PROCEDURE sp_DieuPhoi_LayBangTrangThai
    @TrangThai NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        p.MaPhieu,
        p.BienSo,
        xm.DongXe,
        kh.HoTen AS TenKhachHang,
        kh.SoDienThoai,
        p.SoODOLucNhan,
        p.GhiChuTinhTrang,
        p.TrangThai,
        p.TongTien,
        p.NgayTiepNhan,
        p.MaKTV,
        ktv.HoTen AS TenKTV,
        (SELECT COUNT(1) FROM ChiTietPhieu ct WHERE ct.MaPhieu = p.MaPhieu) AS TongSoHangMuc,
        (SELECT COUNT(1) FROM ChiTietPhieu ct WHERE ct.MaPhieu = p.MaPhieu AND ct.DaHoanThanh = 1) AS SoHangMucHoanThanh
    FROM PhieuSuaChua p
    INNER JOIN XeMay xm ON p.BienSo = xm.BienSo
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    LEFT JOIN TaiKhoan ktv ON p.MaKTV = ktv.MaTK
    WHERE 
        (@TrangThai IS NULL AND p.TrangThai IN (N'ChoSua', N'DangSua', N'ChoThanhToan', N'DatLich'))
        OR (@TrangThai IS NOT NULL AND p.TrangThai = @TrangThai)
    ORDER BY 
        CASE p.TrangThai
            WHEN N'ChoSua' THEN 1
            WHEN N'DangSua' THEN 2
            WHEN N'ChoThanhToan' THEN 3
            ELSE 4
        END,
        p.NgayTiepNhan ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 29. sp_DieuPhoi_PhanCongKTV: Gán thợ và chuyển trạng thái sang 'DangSua'
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DieuPhoi_PhanCongKTV', 'P') IS NOT NULL
    DROP PROCEDURE sp_DieuPhoi_PhanCongKTV;
GO
CREATE PROCEDURE sp_DieuPhoi_PhanCongKTV
    @MaPhieu INT,
    @MaKTV INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu)
            THROW 50036, N'Phiếu sửa chữa không tồn tại!', 1;

        IF NOT EXISTS (SELECT 1 FROM TaiKhoan WHERE MaTK = @MaKTV AND VaiTro = 'KyThuatVien' AND TrangThai = 1)
            THROW 50037, N'Kỹ thuật viên không hợp lệ hoặc đã bị khóa!', 1;

        UPDATE PhieuSuaChua
        SET 
            MaKTV = @MaKTV,
            TrangThai = N'DangSua'
        WHERE MaPhieu = @MaPhieu;

        SELECT 
            1 AS StatusCode, 
            N'Phân công kỹ thuật viên thành công, phiếu đã chuyển sang trạng thái Đang sửa!' AS Message,
            @MaPhieu AS MaPhieu,
            @MaKTV AS MaKTV,
            N'DangSua' AS TrangThai;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 30. sp_DieuPhoi_CapNhatTrangThai: Cập nhật trạng thái phiếu sửa chữa
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_DieuPhoi_CapNhatTrangThai', 'P') IS NOT NULL
    DROP PROCEDURE sp_DieuPhoi_CapNhatTrangThai;
GO
CREATE PROCEDURE sp_DieuPhoi_CapNhatTrangThai
    @MaPhieu INT,
    @TrangThaiMoi NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu)
            THROW 50038, N'Phiếu sửa chữa không tồn tại!', 1;

        IF @TrangThaiMoi NOT IN (N'ChoSua', N'DangSua', N'ChoThanhToan', N'DaThanhToan', N'DatLich')
            THROW 50039, N'Trạng thái mới không hợp lệ!', 1;

        UPDATE PhieuSuaChua
        SET TrangThai = @TrangThaiMoi
        WHERE MaPhieu = @MaPhieu;

        SELECT 1 AS StatusCode, N'Cập nhật trạng thái thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 31. sp_ThanhToan_ChotHoaDon: Thanh toán, tự động trừ tồn kho, cập nhật ODO & ngày bảo dưỡng
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ThanhToan_ChotHoaDon', 'P') IS NOT NULL
    DROP PROCEDURE sp_ThanhToan_ChotHoaDon;
GO
CREATE PROCEDURE sp_ThanhToan_ChotHoaDon
    @MaPhieu INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kiểm tra phiếu có tồn tại và hợp lệ
        DECLARE @TrangThaiHienTai NVARCHAR(30), @BienSo VARCHAR(20), @SoODOLucNhan INT;
        SELECT 
            @TrangThaiHienTai = TrangThai,
            @BienSo = BienSo,
            @SoODOLucNhan = SoODOLucNhan
        FROM PhieuSuaChua
        WHERE MaPhieu = @MaPhieu;

        IF @TrangThaiHienTai IS NULL
            THROW 50040, N'Phiếu sửa chữa không tồn tại!', 1;

        IF @TrangThaiHienTai = N'DaThanhToan'
            THROW 50041, N'Phiếu sửa chữa này đã được thanh toán trước đó!', 1;

        -- 2. Kiểm tra tồn kho của TẤT CẢ phụ tùng trong phiếu
        -- Nếu có phụ tùng không đủ số lượng tồn -> Báo lỗi chi tiết và hủy giao dịch
        DECLARE @TenPTThieu NVARCHAR(150), @MaPTThieu VARCHAR(20), @TonHienTai INT, @CanXuat INT;

        SELECT TOP 1 
            @MaPTThieu = pt.MaPT,
            @TenPTThieu = pt.TenPT,
            @TonHienTai = pt.SoLuongTon,
            @CanXuat = SUM(ct.SoLuong)
        FROM ChiTietPhieu ct
        INNER JOIN PhuTung pt ON ct.MaPT = pt.MaPT
        WHERE ct.MaPhieu = @MaPhieu AND ct.LoaiMuc = 'PhuTung'
        GROUP BY pt.MaPT, pt.TenPT, pt.SoLuongTon
        HAVING pt.SoLuongTon < SUM(ct.SoLuong);

        IF @MaPTThieu IS NOT NULL
        BEGIN
            DECLARE @ErrMsg NVARCHAR(500);
            SET @ErrMsg = N'Không đủ tồn kho để thanh toán và xuất phụ tùng: [' + @MaPTThieu + N'] ' + @TenPTThieu 
                        + N' (Tồn kho: ' + CAST(@TonHienTai AS NVARCHAR(10)) 
                        + N', Cần xuất: ' + CAST(@CanXuat AS NVARCHAR(10)) + N')!';
            THROW 50042, @ErrMsg, 1;
        END

        -- 3. Tự động trừ SoLuongTon của phụ tùng trong kho
        UPDATE pt
        SET pt.SoLuongTon = pt.SoLuongTon - tongXuat.SoLuong
        FROM PhuTung pt
        INNER JOIN (
            SELECT MaPT, SUM(SoLuong) AS SoLuong
            FROM ChiTietPhieu
            WHERE MaPhieu = @MaPhieu AND LoaiMuc = 'PhuTung'
            GROUP BY MaPT
        ) tongXuat ON pt.MaPT = tongXuat.MaPT;

        -- 4. Cập nhật thông tin xe máy (Số ODO hiện tại và Ngày bảo dưỡng cuối)
        UPDATE XeMay
        SET 
            SoODOHienTai = CASE WHEN @SoODOLucNhan > SoODOHienTai THEN @SoODOLucNhan ELSE SoODOHienTai END,
            NgayBaoDuongCuoi = CAST(GETDATE() AS DATE)
        WHERE BienSo = @BienSo;

        -- Đánh dấu khách hàng đã hoàn thành đợt bảo dưỡng mới (reset DaNhacLich = 0)
        UPDATE kh
        SET kh.DaNhacLich = 0
        FROM KhachHang kh
        INNER JOIN XeMay xm ON kh.MaKH = xm.MaKH
        WHERE xm.BienSo = @BienSo;

        -- 5. Cập nhật phiếu sửa chữa sang DaThanhToan
        UPDATE PhieuSuaChua
        SET 
            TrangThai = N'DaThanhToan',
            NgayHoanThanh = GETDATE()
        WHERE MaPhieu = @MaPhieu;

        -- Đảm bảo tất cả hạng mục trong phiếu đánh dấu DaHoanThanh = 1
        UPDATE ChiTietPhieu
        SET DaHoanThanh = 1
        WHERE MaPhieu = @MaPhieu;

        COMMIT TRANSACTION;

        SELECT 
            1 AS StatusCode, 
            N'Thanh toán phiếu thành công! Đã trừ kho phụ tùng và cập nhật hồ sơ xe.' AS Message,
            @MaPhieu AS MaPhieu,
            N'DaThanhToan' AS TrangThai;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 32. sp_ThanhToan_InHoaDon: Lấy dữ liệu in hóa đơn thanh toán hoàn chỉnh
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ThanhToan_InHoaDon', 'P') IS NOT NULL
    DROP PROCEDURE sp_ThanhToan_InHoaDon;
GO
CREATE PROCEDURE sp_ThanhToan_InHoaDon
    @MaPhieu INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Resultset 1: Thông tin trung tâm & hóa đơn
    SELECT 
        N'TRUNG TÂM BẢO DƯỠNG & SỬA CHỮA XE MÁY TVB' AS TenTrungTam,
        N'Đà Lạt, Lâm Đồng - Hotline: 0901.234.567' AS DiaChiTrungTam,
        p.MaPhieu AS SoHoaDon,
        p.NgayTiepNhan,
        ISNULL(p.NgayHoanThanh, GETDATE()) AS NgayThanhToan,
        p.BienSo,
        xm.DongXe,
        p.SoODOLucNhan,
        kh.HoTen AS TenKhachHang,
        kh.SoDienThoai,
        kh.DiaChi AS DiaChiKhachHang,
        cv.HoTen AS TenNhanVienTiepNhan,
        ktv.HoTen AS TenKyThuatVien,
        p.GhiChuTinhTrang,
        p.TrangThai,
        p.TongTien
    FROM PhieuSuaChua p
    INNER JOIN XeMay xm ON p.BienSo = xm.BienSo
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    LEFT JOIN TaiKhoan cv ON p.MaCoVan = cv.MaTK
    LEFT JOIN TaiKhoan ktv ON p.MaKTV = ktv.MaTK
    WHERE p.MaPhieu = @MaPhieu;

    -- Resultset 2: Bảng chi tiết thanh toán từng hạng mục
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ct.LoaiMuc DESC, ct.MaCT ASC) AS STT,
        ct.LoaiMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.TenPT ELSE dv.TenDV END AS TenHangMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.DonViTinh ELSE N'Lần' END AS DonViTinh,
        ct.SoLuong,
        ct.DonGiaLucBan,
        (ct.SoLuong * ct.DonGiaLucBan) AS ThanhTien
    FROM ChiTietPhieu ct
    LEFT JOIN PhuTung pt ON ct.MaPT = pt.MaPT
    LEFT JOIN DichVu dv ON ct.MaDV = dv.MaDV
    WHERE ct.MaPhieu = @MaPhieu;
END;
GO

------------------------------------------------------------------------------------------
-- 33. sp_ChamSocKH_DanhSachNhacLich: Tìm xe quá hạn bảo dưỡng định kỳ (>= 3 tháng)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ChamSocKH_DanhSachNhacLich', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChamSocKH_DanhSachNhacLich;
GO
CREATE PROCEDURE sp_ChamSocKH_DanhSachNhacLich
    @SoThangQuaHan INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        kh.MaKH,
        kh.HoTen AS TenKhachHang,
        kh.SoDienThoai,
        kh.DiaChi,
        xm.BienSo,
        xm.DongXe,
        xm.SoODOHienTai,
        xm.NgayBaoDuongCuoi,
        DATEDIFF(DAY, xm.NgayBaoDuongCuoi, GETDATE()) AS SoNgayChuaBaoDuong,
        kh.DaNhacLich
    FROM XeMay xm
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    WHERE 
        (xm.NgayBaoDuongCuoi IS NOT NULL AND xm.NgayBaoDuongCuoi <= DATEADD(MONTH, -@SoThangQuaHan, GETDATE()))
        AND kh.DaNhacLich = 0
    ORDER BY xm.NgayBaoDuongCuoi ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 34. sp_ChamSocKH_DanhDauDaNhac: Đánh dấu đã nhắc lịch cho khách hàng
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_ChamSocKH_DanhDauDaNhac', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChamSocKH_DanhDauDaNhac;
GO
CREATE PROCEDURE sp_ChamSocKH_DanhDauDaNhac
    @MaKH INT,
    @DaNhac BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE KhachHang
    SET DaNhacLich = @DaNhac
    WHERE MaKH = @MaKH;

    SELECT 1 AS StatusCode, N'Đã cập nhật trạng thái nhắc lịch!' AS Message;
END;
GO


-- =======================================================================================
-- MODULE 3: CÔNG CỤ CHO KỸ THUẬT VIÊN & KHÁCH HÀNG (MOBILE APP & PORTAL)
-- =======================================================================================

------------------------------------------------------------------------------------------
-- 35. sp_KTV_LayDanhSachCongViec: Danh sách phiếu được giao cho KTV (TrangThai = 'DangSua')
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KTV_LayDanhSachCongViec', 'P') IS NOT NULL
    DROP PROCEDURE sp_KTV_LayDanhSachCongViec;
GO
CREATE PROCEDURE sp_KTV_LayDanhSachCongViec
    @MaKTV INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        p.MaPhieu,
        p.BienSo,
        xm.DongXe,
        p.SoODOLucNhan,
        p.GhiChuTinhTrang,
        p.NgayTiepNhan,
        p.TrangThai,
        kh.HoTen AS TenKhachHang,
        kh.SoDienThoai,
        (SELECT COUNT(1) FROM ChiTietPhieu ct WHERE ct.MaPhieu = p.MaPhieu) AS TongHangMuc,
        (SELECT COUNT(1) FROM ChiTietPhieu ct WHERE ct.MaPhieu = p.MaPhieu AND ct.DaHoanThanh = 1) AS DaXong
    FROM PhieuSuaChua p
    INNER JOIN XeMay xm ON p.BienSo = xm.BienSo
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    WHERE p.MaKTV = @MaKTV AND p.TrangThai = N'DangSua'
    ORDER BY p.NgayTiepNhan ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 36. sp_KTV_LayChiTietCongViec: Lấy chi tiết các hạng mục thợ cần làm trong 1 phiếu
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KTV_LayChiTietCongViec', 'P') IS NOT NULL
    DROP PROCEDURE sp_KTV_LayChiTietCongViec;
GO
CREATE PROCEDURE sp_KTV_LayChiTietCongViec
    @MaPhieu INT,
    @MaKTV INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra phiếu có tồn tại và (nếu truyền MaKTV) thuộc thợ đó không
    IF NOT EXISTS (
        SELECT 1 FROM PhieuSuaChua 
        WHERE MaPhieu = @MaPhieu AND (@MaKTV IS NULL OR MaKTV = @MaKTV)
    )
    BEGIN
        RAISERROR(N'Phiếu sửa chữa không tồn tại hoặc bạn không được phân công phiếu này!', 16, 1);
        RETURN;
    END

    SELECT 
        ct.MaCT,
        ct.MaPhieu,
        ct.LoaiMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.MaPT ELSE dv.MaDV END AS MaHangMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.TenPT ELSE dv.TenDV END AS TenHangMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.DonViTinh ELSE N'Lần' END AS DonViTinh,
        ct.SoLuong,
        ct.DonGiaLucBan,
        ct.DaHoanThanh
    FROM ChiTietPhieu ct
    LEFT JOIN PhuTung pt ON ct.MaPT = pt.MaPT
    LEFT JOIN DichVu dv ON ct.MaDV = dv.MaDV
    WHERE ct.MaPhieu = @MaPhieu
    ORDER BY ct.DaHoanThanh ASC, ct.MaCT ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 37. sp_KTV_CapNhatTienDo: Kỹ thuật viên tick hoàn thành từng hạng mục trên Mobile
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KTV_CapNhatTienDo', 'P') IS NOT NULL
    DROP PROCEDURE sp_KTV_CapNhatTienDo;
GO
CREATE PROCEDURE sp_KTV_CapNhatTienDo
    @MaCT INT,
    @DaHoanThanh BIT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM ChiTietPhieu WHERE MaCT = @MaCT)
            THROW 50043, N'Mục chi tiết không tồn tại!', 1;

        UPDATE ChiTietPhieu
        SET DaHoanThanh = @DaHoanThanh
        WHERE MaCT = @MaCT;

        SELECT 
            1 AS StatusCode, 
            N'Cập nhật tiến độ hạng mục thành công!' AS Message,
            @MaCT AS MaCT,
            @DaHoanThanh AS DaHoanThanh;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 38. sp_KTV_ThemPhuTungPhatSinh: KTV thêm phụ tùng phát sinh (Kiểm tra tồn kho trước)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KTV_ThemPhuTungPhatSinh', 'P') IS NOT NULL
    DROP PROCEDURE sp_KTV_ThemPhuTungPhatSinh;
GO
CREATE PROCEDURE sp_KTV_ThemPhuTungPhatSinh
    @MaPhieu INT,
    @MaPT VARCHAR(20),
    @SoLuong INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu AND TrangThai = N'DangSua')
            THROW 50044, N'Phiếu sửa chữa không tồn tại hoặc không ở trạng thái Đang sửa!', 1;

        IF @SoLuong <= 0
            THROW 50045, N'Số lượng phụ tùng phát sinh phải lớn hơn 0!', 1;

        DECLARE @TenPT NVARCHAR(150), @SoLuongTon INT, @GiaBan DECIMAL(18, 0);
        SELECT 
            @TenPT = TenPT,
            @SoLuongTon = SoLuongTon,
            @GiaBan = GiaBan
        FROM PhuTung
        WHERE MaPT = @MaPT;

        IF @TenPT IS NULL
            THROW 50046, N'Mã phụ tùng không tồn tại trong kho!', 1;

        -- KIỂM TRA TỒN KHO TRƯỚC KHI THÊM THEO ĐÚNG ĐỀ BÀI
        IF @SoLuongTon < @SoLuong
        BEGIN
            DECLARE @Err NVARCHAR(300);
            SET @Err = N'Tồn kho không đủ để xuất! Hiện chỉ còn ' + CAST(@SoLuongTon AS NVARCHAR(10)) + N' ' + @TenPT;
            THROW 50047, @Err, 1;
        END

        -- Thêm vào chi tiết phiếu với DaHoanThanh = 0
        INSERT INTO ChiTietPhieu (MaPhieu, LoaiMuc, MaPT, MaDV, SoLuong, DonGiaLucBan, DaHoanThanh)
        VALUES (@MaPhieu, 'PhuTung', @MaPT, NULL, @SoLuong, @GiaBan, 0);

        -- Đồng bộ lại tổng tiền phiếu
        EXEC sp_PhieuSuaChua_CapNhatTongTien @MaPhieu;

        SELECT 
            SCOPE_IDENTITY() AS MaCT,
            @MaPhieu AS MaPhieu,
            @TenPT AS TenPT,
            @SoLuong AS SoLuong,
            @GiaBan AS DonGia,
            1 AS StatusCode,
            N'Đã thêm phụ tùng phát sinh thành công!' AS Message;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 39. sp_KTV_ThemDichVuPhatSinh: KTV thêm dịch vụ / công thợ phát sinh
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KTV_ThemDichVuPhatSinh', 'P') IS NOT NULL
    DROP PROCEDURE sp_KTV_ThemDichVuPhatSinh;
GO
CREATE PROCEDURE sp_KTV_ThemDichVuPhatSinh
    @MaPhieu INT,
    @MaDV VARCHAR(20),
    @SoLuong INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu AND TrangThai = N'DangSua')
            THROW 50048, N'Phiếu sửa chữa không tồn tại hoặc không ở trạng thái Đang sửa!', 1;

        IF @SoLuong <= 0
            THROW 50049, N'Số lượng dịch vụ phải lớn hơn 0!', 1;

        DECLARE @TenDV NVARCHAR(150), @DonGia DECIMAL(18, 0);
        SELECT @TenDV = TenDV, @DonGia = DonGia FROM DichVu WHERE MaDV = @MaDV;

        IF @TenDV IS NULL
            THROW 50050, N'Dịch vụ không tồn tại!', 1;

        INSERT INTO ChiTietPhieu (MaPhieu, LoaiMuc, MaPT, MaDV, SoLuong, DonGiaLucBan, DaHoanThanh)
        VALUES (@MaPhieu, 'DichVu', NULL, @MaDV, @SoLuong, @DonGia, 0);

        EXEC sp_PhieuSuaChua_CapNhatTongTien @MaPhieu;

        SELECT 
            SCOPE_IDENTITY() AS MaCT,
            @MaPhieu AS MaPhieu,
            @TenDV AS TenDV,
            @SoLuong AS SoLuong,
            @DonGia AS DonGia,
            1 AS StatusCode,
            N'Đã thêm dịch vụ phát sinh thành công!' AS Message;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 40. sp_KTV_HoanTatSuaChua: Nút 'Hoàn tất sửa chữa' chuyển trạng thái sang 'ChoThanhToan'
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KTV_HoanTatSuaChua', 'P') IS NOT NULL
    DROP PROCEDURE sp_KTV_HoanTatSuaChua;
GO
CREATE PROCEDURE sp_KTV_HoanTatSuaChua
    @MaPhieu INT,
    @MaKTV INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM PhieuSuaChua 
            WHERE MaPhieu = @MaPhieu AND MaKTV = @MaKTV AND TrangThai = N'DangSua'
        )
        BEGIN
            THROW 50051, N'Không tìm thấy phiếu đang sửa chữa thuộc kỹ thuật viên này!', 1;
        END

        -- Tự động đánh dấu tất cả các hạng mục của phiếu là đã hoàn thành
        UPDATE ChiTietPhieu
        SET DaHoanThanh = 1
        WHERE MaPhieu = @MaPhieu;

        -- Chuyển trạng thái phiếu sang ChoThanhToan
        UPDATE PhieuSuaChua
        SET TrangThai = N'ChoThanhToan'
        WHERE MaPhieu = @MaPhieu;

        SELECT 
            1 AS StatusCode,
            N'Hoàn tất sửa chữa thành công! Phiếu đã chuyển sang Chờ thanh toán.' AS Message,
            @MaPhieu AS MaPhieu,
            N'ChoThanhToan' AS TrangThai;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 41. sp_KhachHang_TraCuuSoBaoDuong: Sổ bảo dưỡng điện tử (Tra cứu theo biển số, không cần đăng nhập)
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KhachHang_TraCuuSoBaoDuong', 'P') IS NOT NULL
    DROP PROCEDURE sp_KhachHang_TraCuuSoBaoDuong;
GO
CREATE PROCEDURE sp_KhachHang_TraCuuSoBaoDuong
    @BienSo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET @BienSo = UPPER(LTRIM(RTRIM(@BienSo)));

    -- 1. Thông tin tổng quan của xe
    SELECT 
        xm.BienSo,
        xm.DongXe,
        xm.SoKhung,
        xm.SoODOHienTai,
        xm.NgayBaoDuongCuoi,
        kh.HoTen AS TenChuXe
    FROM XeMay xm
    INNER JOIN KhachHang kh ON xm.MaKH = kh.MaKH
    WHERE xm.BienSo = @BienSo;

    -- 2. Toàn bộ lịch sử các phiếu đã hoàn thành thanh toán
    SELECT 
        p.MaPhieu,
        p.NgayTiepNhan,
        p.NgayHoanThanh,
        p.SoODOLucNhan,
        p.GhiChuTinhTrang,
        p.TongTien,
        p.TrangThai
    FROM PhieuSuaChua p
    WHERE p.BienSo = @BienSo AND p.TrangThai = N'DaThanhToan'
    ORDER BY p.NgayTiepNhan DESC;
END;
GO

------------------------------------------------------------------------------------------
-- 42. sp_KhachHang_ChiTietPhieuLichSu: Xem chi tiết phụ tùng & dịch vụ của 1 phiếu lịch sử
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KhachHang_ChiTietPhieuLichSu', 'P') IS NOT NULL
    DROP PROCEDURE sp_KhachHang_ChiTietPhieuLichSu;
GO
CREATE PROCEDURE sp_KhachHang_ChiTietPhieuLichSu
    @MaPhieu INT,
    @BienSo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET @BienSo = UPPER(LTRIM(RTRIM(@BienSo)));

    -- Kiểm tra phiếu có thuộc biển số này không để bảo mật
    IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu AND BienSo = @BienSo)
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin lịch sử của xe này!', 16, 1);
        RETURN;
    END

    SELECT 
        ct.MaCT,
        ct.LoaiMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.TenPT ELSE dv.TenDV END AS TenHangMuc,
        CASE ct.LoaiMuc WHEN 'PhuTung' THEN pt.DonViTinh ELSE N'Lần' END AS DonViTinh,
        ct.SoLuong,
        ct.DonGiaLucBan,
        (ct.SoLuong * ct.DonGiaLucBan) AS ThanhTien
    FROM ChiTietPhieu ct
    LEFT JOIN PhuTung pt ON ct.MaPT = pt.MaPT
    LEFT JOIN DichVu dv ON ct.MaDV = dv.MaDV
    WHERE ct.MaPhieu = @MaPhieu
    ORDER BY ct.LoaiMuc DESC, ct.MaCT ASC;
END;
GO

------------------------------------------------------------------------------------------
-- 43. sp_KhachHang_DatLichHen: Khách đặt lịch hẹn online, tạo phiếu trạng thái 'DatLich'
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_KhachHang_DatLichHen', 'P') IS NOT NULL
    DROP PROCEDURE sp_KhachHang_DatLichHen;
GO
CREATE PROCEDURE sp_KhachHang_DatLichHen
    @BienSo VARCHAR(20),
    @HoTenKhach NVARCHAR(100),
    @SoDienThoai VARCHAR(15),
    @DongXe NVARCHAR(100),
    @NgayHen DATETIME,
    @SoODOHienTai INT = 0,
    @GhiChuTinhTrang NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        SET @BienSo = UPPER(LTRIM(RTRIM(@BienSo)));
        SET @SoDienThoai = LTRIM(RTRIM(@SoDienThoai));
        SET @HoTenKhach = LTRIM(RTRIM(@HoTenKhach));
        SET @DongXe = LTRIM(RTRIM(@DongXe));

        IF @BienSo = '' OR @SoDienThoai = '' OR @HoTenKhach = ''
            THROW 50052, N'Biển số, số điện thoại và họ tên không được để trống!', 1;

        IF @NgayHen < CAST(GETDATE() AS DATE)
            THROW 50053, N'Ngày hẹn không được nhỏ hơn ngày hiện tại!', 1;

        -- 1. Đảm bảo Khách hàng đã tồn tại
        DECLARE @MaKH INT;
        SELECT @MaKH = MaKH FROM KhachHang WHERE SoDienThoai = @SoDienThoai;

        IF @MaKH IS NULL
        BEGIN
            INSERT INTO KhachHang (HoTen, SoDienThoai, DaNhacLich)
            VALUES (@HoTenKhach, @SoDienThoai, 0);
            SET @MaKH = SCOPE_IDENTITY();
        END

        -- 2. Đảm bảo Xe đã tồn tại
        IF NOT EXISTS (SELECT 1 FROM XeMay WHERE BienSo = @BienSo)
        BEGIN
            INSERT INTO XeMay (BienSo, MaKH, DongXe, SoODOHienTai)
            VALUES (@BienSo, @MaKH, @DongXe, @SoODOHienTai);
        END

        -- 3. Tạo phiếu sửa chữa với trạng thái 'DatLich'
        INSERT INTO PhieuSuaChua (
            BienSo,
            MaCoVan,
            MaKTV,
            NgayTiepNhan,
            NgayHoanThanh,
            SoODOLucNhan,
            GhiChuTinhTrang,
            TrangThai,
            TongTien
        )
        VALUES (
            @BienSo,
            NULL,               -- Chưa có Cố vấn tiếp nhận
            NULL,               -- Chưa giao KTV
            @NgayHen,
            NULL,
            @SoODOHienTai,
            @GhiChuTinhTrang,
            N'DatLich',         -- Trạng thái Đặt lịch hẹn
            0
        );

        DECLARE @MaPhieuMoi INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT 
            @MaPhieuMoi AS MaPhieu,
            @BienSo AS BienSo,
            @NgayHen AS NgayHen,
            N'DatLich' AS TrangThai,
            1 AS StatusCode,
            N'Đặt lịch hẹn thành công! Trung tâm TVB hân hạnh phục vụ quý khách.' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------------------------
-- 44. sp_CoVan_TiepNhanLichHen: Cố vấn tiếp nhận xe đặt lịch khi khách mang xe đến trung tâm
------------------------------------------------------------------------------------------
IF OBJECT_ID('sp_CoVan_TiepNhanLichHen', 'P') IS NOT NULL
    DROP PROCEDURE sp_CoVan_TiepNhanLichHen;
GO
CREATE PROCEDURE sp_CoVan_TiepNhanLichHen
    @MaPhieu INT,
    @MaCoVan INT,
    @SoODOLucNhan INT = NULL,
    @GhiChuThem NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM PhieuSuaChua WHERE MaPhieu = @MaPhieu AND TrangThai = N'DatLich')
            THROW 50054, N'Phiếu hẹn không tồn tại hoặc đã được tiếp nhận!', 1;

        UPDATE PhieuSuaChua
        SET 
            MaCoVan = @MaCoVan,
            TrangThai = N'ChoSua',
            NgayTiepNhan = GETDATE(),
            SoODOLucNhan = ISNULL(@SoODOLucNhan, SoODOLucNhan),
            GhiChuTinhTrang = CASE 
                                WHEN @GhiChuThem IS NOT NULL AND @GhiChuThem <> '' 
                                THEN ISNULL(GhiChuTinhTrang + N' | Tiếp nhận: ', N'Tiếp nhận: ') + @GhiChuThem
                                ELSE GhiChuTinhTrang 
                              END
        WHERE MaPhieu = @MaPhieu;

        -- Cập nhật ODO xe nếu ODO lúc nhận lớn hơn
        IF @SoODOLucNhan IS NOT NULL
        BEGIN
            UPDATE xm
            SET xm.SoODOHienTai = @SoODOLucNhan
            FROM XeMay xm
            INNER JOIN PhieuSuaChua p ON xm.BienSo = p.BienSo
            WHERE p.MaPhieu = @MaPhieu AND @SoODOLucNhan > xm.SoODOHienTai;
        END

        SELECT 
            1 AS StatusCode,
            N'Đã tiếp nhận xe từ lịch hẹn, phiếu chuyển sang trạng thái Chờ sửa!' AS Message,
            @MaPhieu AS MaPhieu,
            N'ChoSua' AS TrangThai;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
