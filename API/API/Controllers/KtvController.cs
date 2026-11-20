using System.Data;
using API.Data;
using API.Models;
using Dapper;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class KtvController : ControllerBase
    {
        private readonly IDbConnectionFactory _db;

        public KtvController(IDbConnectionFactory db)
        {
            _db = db;
        }

        [HttpGet("cong-viec/{maKtv}")]
        public async Task<IActionResult> GetCongViec(int maKtv)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<KtvCongViecDto>(
                    "sp_KTV_LayDanhSachCongViec",
                    new { MaKTV = maKtv },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<KtvCongViecDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpGet("chi-tiet-cong-viec/{maPhieu}")]
        public async Task<IActionResult> GetChiTietCongViec(int maPhieu, [FromQuery] int? maKtv)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var list = await conn.QueryAsync<ChiTietPhieuDto>(
                    "sp_KTV_LayChiTietCongViec",
                    new { MaPhieu = maPhieu, MaKTV = maKtv },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<IEnumerable<ChiTietPhieuDto>>.Ok(list));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("cap-nhat-tien-do")]
        public async Task<IActionResult> CapNhatTienDo([FromBody] CapNhatTienDoRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_KTV_CapNhatTienDo",
                    new { req.MaCT, req.DaHoanThanh },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Cập nhật tiến độ thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("them-phu-tung-phat-sinh")]
        public async Task<IActionResult> ThemPhuTungPhatSinh([FromBody] KtvThemPhuTungPhatSinhRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_KTV_ThemPhuTungPhatSinh",
                    new { req.MaPhieu, req.MaPT, req.SoLuong },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Thêm phụ tùng phát sinh thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("them-dich-vu-phat-sinh")]
        public async Task<IActionResult> ThemDichVuPhatSinh([FromBody] KtvThemDichVuPhatSinhRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_KTV_ThemDichVuPhatSinh",
                    new { req.MaPhieu, req.MaDV, req.SoLuong },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Thêm dịch vụ phát sinh thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }

        [HttpPost("hoan-tat-sua-chua")]
        public async Task<IActionResult> HoanTatSuaChua([FromBody] KtvHoanTatRequest req)
        {
            try
            {
                using var conn = _db.CreateConnection();
                var result = await conn.QueryFirstOrDefaultAsync<dynamic>(
                    "sp_KTV_HoanTatSuaChua",
                    new { req.MaPhieu, req.MaKTV },
                    commandType: CommandType.StoredProcedure
                );
                return Ok(ApiResponse<dynamic>.Ok(result, "Hoàn tất sửa chữa thành công!"));
            }
            catch (Exception ex)
            {
                return BadRequest(ApiResponse<string>.Fail(ex.Message));
            }
        }
    }
}
