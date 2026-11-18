using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using ReelItIn.Api.Identity;

namespace ReelItIn.Api.Data;

// EF Core's map of application tables. This maps the AppUser entity to Identity's relational model.
// Future migrations will use this mapping for MySQL schema changes.
public sealed class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
}
