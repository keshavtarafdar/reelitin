# ADR 0001: ASP.NET Core and MySQL backend foundation

**Status:** Accepted

## Context

Reel It In needs to replace Firebase Authentication and Firestore with an authenticated API and relational database. The iPhone app must never connect directly to MySQL or receive database credentials. The roadmap requires .NET 10 LTS, ASP.NET Identity, MySQL, EF Core, and Pomelo.

As of September 2026, stable Pomelo is 9.0.0 and supports EF Core 9.x. Stable Pomelo support for EF Core 10 is not available.

## Decision

- Run and target .NET 10.
- Use EF Core 9.0.19, ASP.NET Identity 9.0.19, and Pomelo 9.0.0 together.
- Use MySQL 8.4 in Docker for local development.
- Keep one modular controller-based ASP.NET API under `backend/`; do not rewrite the Godot game in C#.
- Generate schema changes as reviewed EF migrations and apply them with a migrator account. The running API uses a separate account without schema-changing permissions.
- Keep the database private. Swift will eventually own the authenticated HTTPS client and Keychain storage; Godot will receive only a narrow game-data bridge.

## Consequences

- .NET 10 can be used immediately without relying on a prerelease MySQL provider.
- EF Core and Pomelo must be upgraded together when stable Pomelo 10 support becomes available.
- The initial migration contains Identity account tables only. Player profile, stats, refresh-token, focus, inventory, and economy tables are intentionally added in later vertical slices.
