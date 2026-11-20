using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ThongKeController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public ThongKeController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpGet("tong-quan-kho")]
        public async Task<IActionResult> GetTongQuanKho()
        {
            try
            {
                using var conn = _db.CreateConnection();
                var stats = await conn.QueryFirstOrDefaultAsync<ThongKeTongQuanDto>(
                    "sp_Module1_ThongKeTongQuan",
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<ThongKeTongQuanDto>.Ok(stats ?? new ThongKeTongQuanDto()));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
