using System.Data;
using Microsoft.Data.SqlClient;

namespace API.Data
{
    public interface IDbConnectionFactory
    {
        IDbConnection CreateConnection();
    }

    public class DbConnectionFactory : IDbConnectionFactory
    {
        private readonly string _connectionString;

        public DbConnectionFactory(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("QuanLyBaoTriXeMayConnection")
                ?? throw new InvalidOperationException("Connection string 'QuanLyBaoTriXeMayConnection' not found.");
        }

        public IDbConnection CreateConnection()
        {
            return new SqlConnection(_connectionString);
        }
    }
}
