using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ThanhToanController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public ThanhToanController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpPost("chot-hoa-don/{maPhieu}")]
        public async Task<IActionResult> ChotHoaDon(int maPhieu)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_ThanhToan_ChotHoaDon",
                    new { MaPhieu = maPhieu },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Chốt hóa đơn thành công! Đã trừ kho và cập nhật hồ sơ xe."));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("in-hoa-don/{maPhieu}")]
        public async Task<IActionResult> InHoaDon(int maPhieu)
        {
            try
            {
                using var conn = _db.CreateConnection();
                using var multi = await conn.QueryMultipleAsync(
                    "sp_ThanhToan_InHoaDon",
                    new { MaPhieu = maPhieu },
                    commandType: CommandType.StoredProcedure
                );

                var thongTin = await multi.ReadFirstOrDefaultAsync<ThongTinHoaDonDto>();
                if (thongTin == null)
                    return NotFound(ApiResponse<string>.Fail("Không tìm thấy thông tin hóa đơn!"));

                var chiTiet = (await multi.ReadAsync<ChiTietHoaDonInDto>()).ToList();

                var response = new HoaDonInResponse
                {
                    ThongTinChung = thongTin,
                    ChiTiet = chiTiet
                };

                return Ok(ApiResponse<HoaDonInResponse>.Ok(response));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("nhac-lich")]
        public async Task<IActionResult> GetDanhSachNhacLich([FromQuery] int soThang = 3)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<NhacLichDto>(
                    "sp_ChamSocKH_DanhSachNhacLich",
                    new { SoThangQuaHan = soThang },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<NhacLichDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("danh-dau-nhac-lich/{maKh}")]
        public async Task<IActionResult> DanhDauDaNhac(int maKh, [FromQuery] bool daNhac = true)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_ChamSocKH_DanhDauDaNhac",
                    new { MaKH = maKh, DaNhac = daNhac },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Cập nhật trạng thái nhắc lịch thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
