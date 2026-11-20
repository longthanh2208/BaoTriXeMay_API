using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PhuTungController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public PhuTungController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<PhuTungDto>(
                    "sp_PhuTung_LayDanhSach",
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<PhuTungDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("search")]
        public async Task<IActionResult> Search([FromQuery] string? q)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<PhuTungDto>(
                    "sp_PhuTung_TimKiem",
                    new { TuKhoa = q ?? string.Empty },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<PhuTungDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("{maPt}")]
        public async Task<IActionResult> GetById(string maPt)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var item = await conn.QueryFirstOrDefaultAsync<PhuTungDto>(
                    "sp_PhuTung_LayTheoMa",
                    new { MaPT = maPt },
                    commandType: CommandType.StoredProcedure
                );

                if (item == null)
                    return NotFound(ApiResponse<string>.Fail("Không tìm thấy phụ tùng!"));

                return Ok(ApiResponse<PhuTungDto>.Ok(item));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ThemPhuTungRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_PhuTung_ThemMoi",
                    new
                    {
                        req.MaPT,
                        req.TenPT,
                        req.DonViTinh,
                        req.GiaNhap,
                        req.GiaBan,
                        req.SoLuongTon,
                        req.TonToiThieu,
                        req.DongXeTuongThich
                    },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Thêm phụ tùng thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPut("{maPt}")]
        public async Task<IActionResult> Update(string maPt, [FromBody] CapNhatPhuTungRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_PhuTung_CapNhat",
                    new
                    {
                        MaPT = maPt,
                        req.TenPT,
                        req.DonViTinh,
                        req.GiaNhap,
                        req.GiaBan,
                        req.TonToiThieu,
                        req.DongXeTuongThich
                    },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Cập nhật phụ tùng thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpDelete("{maPt}")]
        public async Task<IActionResult> Delete(string maPt)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_PhuTung_Xoa",
                    new { MaPT = maPt },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Xóa phụ tùng thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("canh-bao-ton-kho")]
        public async Task<IActionResult> GetCanhBaoTonKho()
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<CanhBaoPhuTungDto>(
                    "sp_PhuTung_CanhBaoTonKho",
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<CanhBaoPhuTungDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("nhap-kho")]
        public async Task<IActionResult> NhapKho([FromBody] NhapKhoRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_PhuTung_NhapKho",
                    new { req.MaPT, req.SoLuongNhap, req.GiaNhapMoi },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Nhập kho thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
