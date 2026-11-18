using ReelItIn.Api.Identity;

namespace ReelItIn.Api.Tests;

public sealed class ApplicationUserTests
{
    [Fact]
    public void New_user_has_a_unique_identifier()
    {
        var user = new ApplicationUser { Id = Guid.NewGuid() };

        Assert.NotEqual(Guid.Empty, user.Id);
    }
}
