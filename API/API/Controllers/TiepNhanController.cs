using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TiepNhanController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public TiepNhanController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpGet("tra-cuu/{bienSo}")]
        public async Task<IActionResult> TraCuuBienSo(string bienSo)
        {
            try
            {
                using var conn = _db.CreateConnection();
                using var multi = await conn.QueryMultipleAsync(
                    "sp_TiepNhan_TraCuuBienSo",
                    new { BienSo = bienSo },
                    commandType: CommandType.StoredProcedure
                );

                var xeMayRow = await multi.ReadFirstOrDefaultAsync<dynamic>();
                var dict = xeMayRow as IDictionary<string, object>;
                if (dict == null || (dict.TryGetValue("TonTai", out var tonTaiVal) && Convert.ToInt32(tonTaiVal) == 0))
                {
                    return Ok(ApiResponse<TraCuuBienSoResponse>.Ok(new TraCuuBienSoResponse
                    {
                        TonTai = false,
                        ThongBao = "Xe chưa từng vào xưởng, vui lòng tạo hồ sơ mới."
                    }));
                }

                var xeMayDto = new XeMayDto
                {
                    BienSo = dict.TryGetValue("BienSo", out var bs) ? bs?.ToString() ?? string.Empty : string.Empty,
                    DongXe = dict.TryGetValue("DongXe", out var dx) ? dx?.ToString() ?? string.Empty : string.Empty,
                    SoKhung = dict.TryGetValue("SoKhung", out var sk) ? sk?.ToString() : null,
                    SoODOHienTai = dict.TryGetValue("SoODOHienTai", out var odo) && odo != null ? Convert.ToInt32(odo) : 0,
                    NgayBaoDuongCuoi = dict.TryGetValue("NgayBaoDuongCuoi", out var nbd) && nbd != null ? Convert.ToDateTime(nbd) : null,
                    MaKH = dict.TryGetValue("MaKH", out var mkh) && mkh != null ? Convert.ToInt32(mkh) : 0,
                    TenKhachHang = dict.TryGetValue("TenKhachHang", out var tkh) ? tkh?.ToString() ?? string.Empty : string.Empty,
                    SoDienThoai = dict.TryGetValue("SoDienThoai", out var sdt) ? sdt?.ToString() ?? string.Empty : string.Empty,
                    DiaChi = dict.TryGetValue("DiaChi", out var dc) ? dc?.ToString() : null,
                    DaNhacLich = dict.TryGetValue("DaNhacLich", out var dnl) && dnl != null && Convert.ToBoolean(dnl)
                };

                var lichSu = (await multi.ReadAsync<LichSuPhieuNganDto>()).ToList();

                var response = new TraCuuBienSoResponse
                {
                    TonTai = true,
                    XeMay = xeMayDto,
                    LichSuSuaChua = lichSu
                };

                return Ok(ApiResponse<TraCuuBienSoResponse>.Ok(response));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("khach-hang/sdt/{sdt}")]
        public async Task<IActionResult> TimKhachHangTheoSdt(string sdt)
        {
            try
            {
                using var conn = _db.CreateConnection();
                using var multi = await conn.QueryMultipleAsync(
                    "sp_KhachHang_TimKiemTheoSDT",
                    new { SoDienThoai = sdt },
                    commandType: CommandType.StoredProcedure
                );

                var khach = await multi.ReadFirstOrDefaultAsync<dynamic>();
                if (khach == null)
                    return NotFound(ApiResponse<string>.Fail("Không tìm thấy khách hàng với số điện thoại này!"));

                var dsXe = await multi.ReadAsync<dynamic>();

                return Ok(ApiResponse<dynamic>.Ok(new
                {
                    KhachHang = khach,
                    DanhSachXe = dsXe
                }));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("tao-khach-va-xe")]
        public async Task<IActionResult> TaoKhachVaXe([FromBody] TaoKhachVaXeRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_TiepNhan_TaoKhachVaXe",
                    new
                    {
                        req.HoTen,
                        req.SoDienThoai,
                        req.DiaChi,
                        req.BienSo,
                        req.DongXe,
                        req.SoKhung,
                        req.SoODOHienTai
                    },
                    commandType: CommandType.StoredProcedure
                );

                return Ok(ApiResponse<dynamic>.Ok(result, "Tạo hồ sơ khách hàng và xe máy thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
