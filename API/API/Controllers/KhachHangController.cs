using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class KhachHangController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public KhachHangController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpGet("so-bao-duong/{bienSo}")]
        public async Task<IActionResult> GetSoBaoDuong(string bienSo)
        {
            try
            {
                using var conn = _db.CreateConnection();
                using var multi = await conn.QueryMultipleAsync(
                    "sp_KhachHang_TraCuuSoBaoDuong",
                    new { BienSo = bienSo },
                    commandType: CommandType.StoredProcedure
                );

                var xeMay = await multi.ReadFirstOrDefaultAsync<ThongTinXeSoBaoDuongDto>();
                if (xeMay == null)
                    return NotFound(ApiResponse<string>.Fail("Không tìm thấy thông tin xe với biển số này!"));

                var lichSu = (await multi.ReadAsync<LichSuPhieuBaoDuongDto>()).ToList();

                var response = new SoBaoDuongResponse
                {
                    XeMay = xeMay,
                    DanhSachLichSu = lichSu
                };

                return Ok(ApiResponse<SoBaoDuongResponse>.Ok(response));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("lich-su-chi-tiet/{maPhieu}")]
        public async Task<IActionResult> GetChiTietLichSu(int maPhieu, [FromQuery] string bienSo)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<ChiTietPhieuDto>(
                    "sp_KhachHang_ChiTietPhieuLichSu",
                    new { MaPhieu = maPhieu, BienSo = bienSo },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<ChiTietPhieuDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("dat-lich-hen")]
        public async Task<IActionResult> DatLichHen([FromBody] DatLichHenRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_KhachHang_DatLichHen",
                    new
                    {
                        req.BienSo,
                        req.HoTenKhach,
                        req.SoDienThoai,
                        req.DongXe,
                        req.NgayHen,
                        req.SoODOHienTai,
                        req.GhiChuTinhTrang
                    },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Đặt lịch hẹn thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("tiep-nhan-lich-hen")]
        public async Task<IActionResult> TiepNhanLichHen([FromBody] TiepNhanLichHenRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_CoVan_TiepNhanLichHen",
                    new
                    {
                        req.MaPhieu,
                        req.MaCoVan,
                        SoODOLucNhan = req.SoODOLucNhanThucTe,
                        req.GhiChuBoSung
                    },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Tiếp nhận xe từ lịch hẹn thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
