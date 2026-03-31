using MarketplaceApi.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddSingleton<AlbumStore>();
builder.Services.AddSingleton<CartStore>();

builder.Services.AddHealthChecks();

var app = builder.Build();

app.MapOpenApi();

app.MapHealthChecks("/health");

app.UseAuthorization();

app.MapControllers();

app.Run();
