using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PhieuSuaChuaController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public PhieuSuaChuaController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpPost("tao-phieu")]
        public async Task<IActionResult> TaoPhieu([FromBody] TaoPhieuRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var p = new DynamicParameters();
                p.Add("@BienSo", req.BienSo);
                p.Add("@MaCoVan", req.MaCoVan);
                p.Add("@SoODOLucNhan", req.SoODOLucNhan);
                p.Add("@GhiChuTinhTrang", req.GhiChuTinhTrang);
                p.Add("@MaPhieuMoi", dbType: DbType.Int32, direction: ParameterDirection.Output);

                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_PhieuSuaChua_TaoMoi",
                    p,
                    commandType: CommandType.StoredProcedure
                );

                int maPhieuMoi = p.Get<int>("@MaPhieuMoi");

                return Ok(ApiResponse<dynamic>.Ok(new
                {
                    MaPhieu = maPhieuMoi,
                    req.BienSo,
                    TrangThai = "ChoSua"
                }, "Tạo phiếu sửa chữa mới thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("{maPhieu}")]
        public async Task<IActionResult> GetById(int maPhieu)
        {
            try
            {
                using var conn = _db.CreateConnection();
                using var multi = await conn.QueryMultipleAsync(
                    "sp_PhieuSuaChua_LayChiTiet",
                    new { MaPhieu = maPhieu },
                    commandType: CommandType.StoredProcedure
                );

                var info = await multi.ReadFirstOrDefaultAsync<PhieuSuaChuaDto>();
                if (info == null)
                    return NotFound(ApiResponse<string>.Fail("Không tìm thấy phiếu sửa chữa!"));

                var items = (await multi.ReadAsync<ChiTietPhieuDto>()).ToList();

                var response = new PhieuSuaChuaChiTietResponse
                {
                    ThongTinPhieu = info,
                    DanhSachHangMuc = items
                };

                return Ok(ApiResponse<PhieuSuaChuaChiTietResponse>.Ok(response));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("them-phu-tung")]
        public async Task<IActionResult> ThemPhuTung([FromBody] ThemPhuTungPhieuRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_ChiTietPhieu_ThemPhuTung",
                    new
                    {
                        req.MaPhieu,
                        req.MaPT,
                        req.SoLuong,
                        req.DonGiaCustom
                    },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Thêm phụ tùng vào phiếu thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("them-dich-vu")]
        public async Task<IActionResult> ThemDichVu([FromBody] ThemDichVuPhieuRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_ChiTietPhieu_ThemDichVu",
                    new
                    {
                        req.MaPhieu,
                        req.MaDV,
                        req.SoLuong,
                        req.DonGiaCustom
                    },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Thêm dịch vụ vào phiếu thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPut("cap-nhat-so-luong")]
        public async Task<IActionResult> CapNhatSoLuong([FromBody] CapNhatSoLuongRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_ChiTietPhieu_CapNhatSoLuong",
                    new { req.MaCT, req.SoLuongMoi },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Cập nhật số lượng thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpDelete("xoa-hang-muc/{maCt}")]
        public async Task<IActionResult> XoaHangMuc(int maCt)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_ChiTietPhieu_XoaHangMuc",
                    new { MaCT = maCt },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Đã xóa hạng mục khỏi phiếu!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
