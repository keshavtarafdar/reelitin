# Reel It In backend

This folder is a modular ASP.NET Core API, not a rewrite of the Godot game. Godot will eventually render game state supplied through a Swift-owned API client; it will never connect to MySQL.

## Layer 2: local foundation

- **.NET 10** runs the API.
- **EF Core 9.0.19** maps C# classes to relational data.
- **Pomelo 9.0.0** is the MySQL-specific EF Core provider. Its major version matches EF Core 9; it is intentionally not paired with EF Core 10 because Pomelo has no stable EF Core 10 release yet.
- **MySQL 8.4** runs in Docker for local development.
- **ASP.NET Identity** supplies the database model and password-handling services for accounts. Login endpoints and JWT issuance arrive in the accounts layer, not in this foundation layer.

## Local start

1. Copy `.env.example` to `.env` and replace the sample passwords locally.
2. Run `docker compose up --build` from this directory.
3. `GET http://localhost:8081/health/live` confirms that the API process is running.
4. `GET http://localhost:8081/health/ready` confirms that MySQL is reachable after a migration has created the schema.

The MySQL port binds only to this Mac (`127.0.0.1:3307`), not the local network. The API runtime account has only application-data permissions. The migration account can change schema but is never used by the running API.

## Apply schema migrations

Start MySQL first with `docker compose up -d mysql`. Then run the repository-local EF tool from the repository root:

```sh
ConnectionStrings__MySql='Server=127.0.0.1;Port=3307;Database=reelitin;User ID=reelitin_migrator;Password=your-local-migrator-password' \
  dotnet tool run dotnet-ef database update --project backend/src/ReelItIn.Api
```

This is intentionally a separate operation from starting the API. It makes schema changes visible and reviewable before they happen.
