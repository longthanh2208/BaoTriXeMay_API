using API.Data;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình Database Connection Factory
builder.Services.AddSingleton<IDbConnectionFactory, DbConnectionFactory>();

// 2. Cấu hình CORS mở cho Web, Mobile và Desktop App
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 3. Cấu hình Controllers và JSON
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = null; // Giữ nguyên định dạng PascalCase theo CSDL và Model
    });

// 4. Cấu hình Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "TVB Motorcycle Maintenance System API",
        Version = "v1",
        Description = "Hệ thống API Backend quản lý bảo dưỡng xe máy TVB - Kỳ thi Kỹ năng nghề cấp tỉnh năm 2026.\nPhục vụ đầy đủ 3 Modules: Desktop WinForm (Quản lý kho), Web App (Tiếp nhận & Điều phối & Thanh toán), Mobile App (Kỹ thuật viên & Sổ bảo dưỡng khách hàng)."
    });
});

var app = builder.Build();

// 5. Cấu hình HTTP Request Pipeline
// Bật Swagger ở tất cả các môi trường (kể cả Production/Server) để tiện test và tích hợp
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "TVB Maintenance API v1");
    c.RoutePrefix = string.Empty; // Mở Swagger trực tiếp tại URL gốc (http://localhost:PORT/)
});

app.UseCors("AllowAll");

// Nếu chạy trên máy local dev thì chuyển hướng HTTPS, nhưng khi triển khai có thể linh hoạt HTTP/HTTPS
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthorization();

app.MapControllers();

app.Run();
