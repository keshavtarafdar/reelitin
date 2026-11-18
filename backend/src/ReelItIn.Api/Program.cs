using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using ReelItIn.Api.Data;
using ReelItIn.Api.Identity;

var builder = WebApplication.CreateBuilder(args);

// Register DB connection (MySQL 8.4), fail if missing
var connectionString = builder.Configuration.GetConnectionString("MySql")
    ?? throw new InvalidOperationException("ConnectionStrings:MySql must be configured.");

builder.Services.AddProblemDetails();
builder.Services.AddControllers();
builder.Services.AddOpenApi();

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 4, 0))));

// Identity registration to setup account-storage capabilities — use ASP.NET Identity account model, require unique emails,
// and persist accounts using EF Core's ApplicationDbContext.
builder.Services
    .AddIdentityCore<ApplicationUser>(options =>
    {
        options.User.RequireUniqueEmail = true;
    })
    .AddRoles<IdentityRole<Guid>>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

builder.Services
    .AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>("mysql");

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Define health endpoints
app.MapGet("/health/live", () => Results.Ok(new { status = "ok" }));
app.MapHealthChecks("/health/ready", new HealthCheckOptions());
app.MapControllers();

app.Run();

public partial class Program;
