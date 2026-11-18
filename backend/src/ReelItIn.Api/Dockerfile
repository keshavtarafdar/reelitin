FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY src/ReelItIn.Api/ReelItIn.Api.csproj src/ReelItIn.Api/
WORKDIR /src/src/ReelItIn.Api
RUN dotnet restore
COPY src/ReelItIn.Api/ ./
RUN dotnet publish --configuration Release --output /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/publish ./
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "ReelItIn.Api.dll"]
