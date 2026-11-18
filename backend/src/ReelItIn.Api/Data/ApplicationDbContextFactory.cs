using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace ReelItIn.Api.Data;

// Lets EF tooling create the model for migrations without reading a real credential from source control
public sealed class ApplicationDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>();
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__MySql")
            ?? "Server=127.0.0.1;Port=3307;Database=reelitin;User ID=reelitin_migrator;Password=design-time-only";

        options.UseMySql(
            connectionString,
            new MySqlServerVersion(new Version(8, 4, 0)));

        return new ApplicationDbContext(options.Options);
    }
}
