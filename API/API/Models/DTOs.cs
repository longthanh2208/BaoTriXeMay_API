namespace API.Models
{
    // ==========================================
    // CHUNG & AUTH
    // ==========================================
    public class ApiResponse<T>
    {
        public bool Success { get; set; } = true;
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; }

        public static ApiResponse<T> Ok(T data, string message = "Thành công") =>
            new ApiResponse<T> { Success = true, Message = message, Data = data };

        public static ApiResponse<T> Fail(string message) =>
            new ApiResponse<T> { Success = false, Message = message, Data = default };
    }

    public class LoginRequest
    {
        public string TenDangNhap { get; set; } = string.Empty;
        public string MatKhau { get; set; } = string.Empty;
    }

    public class LoginResponse
    {
        public int MaTK { get; set; }
        public string TenDangNhap { get; set; } = string.Empty;
        public string HoTen { get; set; } = string.Empty;
        public string VaiTro { get; set; } = string.Empty;
        public bool TrangThai { get; set; }
        public string ThongBao { get; set; } = string.Empty;
    }

    public class DoiMatKhauRequest
    {
        public int MaTK { get; set; }
        public string MatKhauCu { get; set; } = string.Empty;
        public string MatKhauMoi { get; set; } = string.Empty;
    }

    public class KtvDto
    {
        public int MaTK { get; set; }
        public string TenDangNhap { get; set; } = string.Empty;
        public string HoTen { get; set; } = string.Empty;
        public bool TrangThai { get; set; }
        public int SoXeDangLam { get; set; }
    }

    // ==========================================
    // MODULE 1: PHỤ TÙNG, DỊCH VỤ, KHO
    // ==========================================
    public class PhuTungDto
    {
        public string MaPT { get; set; } = string.Empty;
        public string TenPT { get; set; } = string.Empty;
        public string DonViTinh { get; set; } = string.Empty;
        public decimal GiaNhap { get; set; }
        public decimal GiaBan { get; set; }
        public int SoLuongTon { get; set; }
        public int TonToiThieu { get; set; }
        public string? DongXeTuongThich { get; set; }
        public int CanhBaoSapHet { get; set; } // 1: Cảnh báo đỏ, 0: Bình thường
    }

    public class CanhBaoPhuTungDto : PhuTungDto
    {
        public int SoLuongThieuHut { get; set; }
    }

    public class ThemPhuTungRequest
    {
        public string MaPT { get; set; } = string.Empty;
        public string TenPT { get; set; } = string.Empty;
        public string DonViTinh { get; set; } = string.Empty;
        public decimal GiaNhap { get; set; }
        public decimal GiaBan { get; set; }
        public int SoLuongTon { get; set; } = 0;
        public int TonToiThieu { get; set; } = 5;
        public string? DongXeTuongThich { get; set; }
    }

    public class CapNhatPhuTungRequest
    {
        public string MaPT { get; set; } = string.Empty;
        public string TenPT { get; set; } = string.Empty;
        public string DonViTinh { get; set; } = string.Empty;
        public decimal GiaNhap { get; set; }
        public decimal GiaBan { get; set; }
        public int TonToiThieu { get; set; }
        public string? DongXeTuongThich { get; set; }
    }

    public class NhapKhoRequest
    {
        public string MaPT { get; set; } = string.Empty;
        public int SoLuongNhap { get; set; }
        public decimal? GiaNhapMoi { get; set; }
    }

    public class DichVuDto
    {
        public string MaDV { get; set; } = string.Empty;
        public string TenDV { get; set; } = string.Empty;
        public decimal DonGia { get; set; }
        public string? MoTa { get; set; }
    }

    public class ThemDichVuRequest
    {
        public string MaDV { get; set; } = string.Empty;
        public string TenDV { get; set; } = string.Empty;
        public decimal DonGia { get; set; }
        public string? MoTa { get; set; }
    }

    public class CapNhatDichVuRequest
    {
        public string MaDV { get; set; } = string.Empty;
        public string TenDV { get; set; } = string.Empty;
        public decimal DonGia { get; set; }
        public string? MoTa { get; set; }
    }

    public class ThongKeTongQuanDto
    {
        public int TongSoMatHangPhuTung { get; set; }
        public int TongSoLuongTonKho { get; set; }
        public decimal TongGiaTriTonKhoGiaNhap { get; set; }
        public decimal TongGiaTriUocTinhGiaBan { get; set; }
        public int SoMatHangCanhBaoSapHet { get; set; }
        public int TongSoDichVu { get; set; }
    }

    // ==========================================
    // MODULE 2: TIẾP NHẬN, ĐIỀU PHỐI, THANH TOÁN
    // ==========================================
    public class TraCuuBienSoResponse
    {
        public bool TonTai { get; set; }
        public string? ThongBao { get; set; }
        public XeMayDto? XeMay { get; set; }
        public List<LichSuPhieuNganDto> LichSuSuaChua { get; set; } = new();
    }

    public class XeMayDto
    {
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public string? SoKhung { get; set; }
        public int SoODOHienTai { get; set; }
        public DateTime? NgayBaoDuongCuoi { get; set; }
        public int MaKH { get; set; }
        public string TenKhachHang { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string? DiaChi { get; set; }
        public bool DaNhacLich { get; set; }
    }

    public class LichSuPhieuNganDto
    {
        public int MaPhieu { get; set; }
        public DateTime NgayTiepNhan { get; set; }
        public DateTime? NgayHoanThanh { get; set; }
        public int SoODOLucNhan { get; set; }
        public string? GhiChuTinhTrang { get; set; }
        public string TrangThai { get; set; } = string.Empty;
        public decimal TongTien { get; set; }
        public string? TenCoVan { get; set; }
        public string? TenKTV { get; set; }
    }

    public class TaoKhachVaXeRequest
    {
        public string HoTen { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string? DiaChi { get; set; }
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public string? SoKhung { get; set; }
        public int SoODOHienTai { get; set; } = 0;
    }

    public class TaoPhieuRequest
    {
        public string BienSo { get; set; } = string.Empty;
        public int MaCoVan { get; set; }
        public int SoODOLucNhan { get; set; }
        public string? GhiChuTinhTrang { get; set; }
    }

    public class ThemPhuTungPhieuRequest
    {
        public int MaPhieu { get; set; }
        public string MaPT { get; set; } = string.Empty;
        public int SoLuong { get; set; } = 1;
        public decimal? DonGiaCustom { get; set; }
    }

    public class ThemDichVuPhieuRequest
    {
        public int MaPhieu { get; set; }
        public string MaDV { get; set; } = string.Empty;
        public int SoLuong { get; set; } = 1;
        public decimal? DonGiaCustom { get; set; }
    }

    public class CapNhatSoLuongRequest
    {
        public int MaCT { get; set; }
        public int SoLuongMoi { get; set; }
    }

    public class PhieuSuaChuaChiTietResponse
    {
        public PhieuSuaChuaDto? ThongTinPhieu { get; set; }
        public List<ChiTietPhieuDto> DanhSachHangMuc { get; set; } = new();
    }

    public class PhieuSuaChuaDto
    {
        public int MaPhieu { get; set; }
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public string? SoKhung { get; set; }
        public int MaKH { get; set; }
        public string TenKhachHang { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string? DiaChi { get; set; }
        public int? MaCoVan { get; set; }
        public string? TenCoVan { get; set; }
        public int? MaKTV { get; set; }
        public string? TenKTV { get; set; }
        public DateTime NgayTiepNhan { get; set; }
        public DateTime? NgayHoanThanh { get; set; }
        public int SoODOLucNhan { get; set; }
        public string? GhiChuTinhTrang { get; set; }
        public string TrangThai { get; set; } = string.Empty;
        public decimal TongTien { get; set; }
    }

    public class ChiTietPhieuDto
    {
        public int MaCT { get; set; }
        public int MaPhieu { get; set; }
        public string LoaiMuc { get; set; } = string.Empty;
        public string MaHangMuc { get; set; } = string.Empty;
        public string TenHangMuc { get; set; } = string.Empty;
        public string DonViTinh { get; set; } = string.Empty;
        public int SoLuong { get; set; }
        public decimal DonGiaLucBan { get; set; }
        public decimal ThanhTien { get; set; }
        public bool DaHoanThanh { get; set; }
    }

    public class KanbanItemDto
    {
        public int MaPhieu { get; set; }
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public string TenKhachHang { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public int SoODOLucNhan { get; set; }
        public string? GhiChuTinhTrang { get; set; }
        public string TrangThai { get; set; } = string.Empty;
        public decimal TongTien { get; set; }
        public DateTime NgayTiepNhan { get; set; }
        public int? MaKTV { get; set; }
        public string? TenKTV { get; set; }
        public int TongSoHangMuc { get; set; }
        public int SoHangMucHoanThanh { get; set; }
    }

    public class PhanCongKtvRequest
    {
        public int MaPhieu { get; set; }
        public int MaKTV { get; set; }
    }

    public class ChuyenTrangThaiRequest
    {
        public int MaPhieu { get; set; }
        public string TrangThaiMoi { get; set; } = string.Empty;
    }

    public class HoaDonInResponse
    {
        public ThongTinHoaDonDto? ThongTinChung { get; set; }
        public List<ChiTietHoaDonInDto> ChiTiet { get; set; } = new();
    }

    public class ThongTinHoaDonDto
    {
        public string TenTrungTam { get; set; } = string.Empty;
        public string DiaChiTrungTam { get; set; } = string.Empty;
        public int SoHoaDon { get; set; }
        public DateTime NgayTiepNhan { get; set; }
        public DateTime NgayThanhToan { get; set; }
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public int SoODOLucNhan { get; set; }
        public string TenKhachHang { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string? DiaChiKhachHang { get; set; }
        public string? TenNhanVienTiepNhan { get; set; }
        public string? TenKyThuatVien { get; set; }
        public string? GhiChuTinhTrang { get; set; }
        public string TrangThai { get; set; } = string.Empty;
        public decimal TongTien { get; set; }
    }

    public class ChiTietHoaDonInDto
    {
        public long STT { get; set; }
        public string LoaiMuc { get; set; } = string.Empty;
        public string TenHangMuc { get; set; } = string.Empty;
        public string DonViTinh { get; set; } = string.Empty;
        public int SoLuong { get; set; }
        public decimal DonGiaLucBan { get; set; }
        public decimal ThanhTien { get; set; }
    }

    public class NhacLichDto
    {
        public int MaKH { get; set; }
        public string TenKhachHang { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string? DiaChi { get; set; }
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public int SoODOHienTai { get; set; }
        public DateTime NgayBaoDuongCuoi { get; set; }
        public int SoNgayChuaBaoDuong { get; set; }
        public bool DaNhacLich { get; set; }
    }

    // ==========================================
    // MODULE 3: KỸ THUẬT VIÊN & KHÁCH HÀNG
    // ==========================================
    public class KtvCongViecDto
    {
        public int MaPhieu { get; set; }
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public int SoODOLucNhan { get; set; }
        public string? GhiChuTinhTrang { get; set; }
        public DateTime NgayTiepNhan { get; set; }
        public string TrangThai { get; set; } = string.Empty;
        public string TenKhachHang { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public int TongHangMuc { get; set; }
        public int DaXong { get; set; }
    }

    public class CapNhatTienDoRequest
    {
        public int MaCT { get; set; }
        public bool DaHoanThanh { get; set; }
    }

    public class KtvThemPhuTungPhatSinhRequest
    {
        public int MaPhieu { get; set; }
        public string MaPT { get; set; } = string.Empty;
        public int SoLuong { get; set; } = 1;
    }

    public class KtvThemDichVuPhatSinhRequest
    {
        public int MaPhieu { get; set; }
        public string MaDV { get; set; } = string.Empty;
        public int SoLuong { get; set; } = 1;
    }

    public class KtvHoanTatRequest
    {
        public int MaPhieu { get; set; }
        public int MaKTV { get; set; }
    }

    public class SoBaoDuongResponse
    {
        public ThongTinXeSoBaoDuongDto? XeMay { get; set; }
        public List<LichSuPhieuBaoDuongDto> DanhSachLichSu { get; set; } = new();
    }

    public class ThongTinXeSoBaoDuongDto
    {
        public string BienSo { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public string? SoKhung { get; set; }
        public int SoODOHienTai { get; set; }
        public DateTime? NgayBaoDuongCuoi { get; set; }
        public string TenChuXe { get; set; } = string.Empty;
    }

    public class LichSuPhieuBaoDuongDto
    {
        public int MaPhieu { get; set; }
        public DateTime NgayTiepNhan { get; set; }
        public DateTime? NgayHoanThanh { get; set; }
        public int SoODOLucNhan { get; set; }
        public string? GhiChuTinhTrang { get; set; }
        public decimal TongTien { get; set; }
        public string TrangThai { get; set; } = string.Empty;
    }

    public class DatLichHenRequest
    {
        public string BienSo { get; set; } = string.Empty;
        public string HoTenKhach { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string DongXe { get; set; } = string.Empty;
        public DateTime NgayHen { get; set; }
        public int SoODOHienTai { get; set; } = 0;
        public string? GhiChuTinhTrang { get; set; }
    }

    public class TiepNhanLichHenRequest
    {
        public int MaPhieu { get; set; }
        public int MaCoVan { get; set; }
        public int? SoODOLucNhanThucTe { get; set; }
        public string? GhiChuBoSung { get; set; }
    }
}
