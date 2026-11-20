using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DieuPhoiController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public DieuPhoiController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpGet("bang-trang-thai")]
        public async Task<IActionResult> GetBangTrangThai([FromQuery] string? trangThai)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<KanbanItemDto>(
                    "sp_DieuPhoi_LayBangTrangThai",
                    new { TrangThai = trangThai },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<KanbanItemDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("phan-cong-ktv")]
        public async Task<IActionResult> PhanCongKtv([FromBody] PhanCongKtvRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_DieuPhoi_PhanCongKTV",
                    new { req.MaPhieu, req.MaKTV },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Phân công kỹ thuật viên thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("chuyen-trang-thai")]
        public async Task<IActionResult> ChuyenTrangThai([FromBody] ChuyenTrangThaiRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_DieuPhoi_CapNhatTrangThai",
                    new { req.MaPhieu, req.TrangThaiMoi },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Cập nhật trạng thái thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
