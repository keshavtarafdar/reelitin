using Microsoft.AspNetCore.Identity;

namespace ReelItIn.Api.Identity;

// Authentication record for one player; mostly inherited from IdentityUser (e.g. password hash, email, etc.)
// with a Guid PK. Btw, sealed = cannot be inherited from
public sealed class ApplicationUser : IdentityUser<Guid>
{
}
