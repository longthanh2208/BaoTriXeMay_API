using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public AuthController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<LoginResponse>(
                    "sp_TaiKhoan_DangNhap",
                    new { req.TenDangNhap, req.MatKhau },
                    commandType: CommandType.StoredProcedure
                );

                if (result == null)
                    return BadRequest(ApiResponse<string>.Fail("Tên đăng nhập hoặc mật khẩu không chính xác!"));

                return Ok(ApiResponse<LoginResponse>.Ok(result, "Đăng nhập thành công"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] DoiMatKhauRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_TaiKhoan_DoiMatKhau",
                    new { req.MaTK, req.MatKhauCu, req.MatKhauMoi },
                    commandType: CommandType.StoredProcedure
                );

                return Ok(ApiResponse<dynamic>.Ok(result, "Đổi mật khẩu thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("ktv-list")]
        public async Task<IActionResult> GetKtvList()
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<KtvDto>(
                    "sp_TaiKhoan_LayDanhSachKTV",
                    commandType: CommandType.StoredProcedure
                );

                return Ok(ApiResponse<IEnumerable<KtvDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
