using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class IdentidadYRecomendaciones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,");

            migrationBuilder.CreateTable(
                name: "mascoteros",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Nombre = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Apellido = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Telefono = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    LocalidadId = table.Column<Guid>(type: "uuid", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_mascoteros", x => x.Id);
                    table.ForeignKey(
                        name: "FK_mascoteros_localidades_LocalidadId",
                        column: x => x.LocalidadId,
                        principalTable: "localidades",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "rubros",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Nombre = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_rubros", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "usuarios",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MascoteroId = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(254)", maxLength: 254, nullable: false),
                    PasswordHash = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    EmailConfirmado = table.Column<bool>(type: "boolean", nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UltimoAcceso = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_usuarios", x => x.Id);
                    table.ForeignKey(
                        name: "FK_usuarios_mascoteros_MascoteroId",
                        column: x => x.MascoteroId,
                        principalTable: "mascoteros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "prestadores_servicio",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Nombre = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    NombreBusqueda = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    RubroId = table.Column<Guid>(type: "uuid", nullable: false),
                    LocalidadId = table.Column<Guid>(type: "uuid", nullable: false),
                    MascoteroCreadorId = table.Column<Guid>(type: "uuid", nullable: false),
                    Direccion = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: true),
                    Telefono = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    Enlace = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_prestadores_servicio", x => x.Id);
                    table.ForeignKey(
                        name: "FK_prestadores_servicio_localidades_LocalidadId",
                        column: x => x.LocalidadId,
                        principalTable: "localidades",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_prestadores_servicio_mascoteros_MascoteroCreadorId",
                        column: x => x.MascoteroCreadorId,
                        principalTable: "mascoteros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_prestadores_servicio_rubros_RubroId",
                        column: x => x.RubroId,
                        principalTable: "rubros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "refresh_tokens",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UsuarioId = table.Column<Guid>(type: "uuid", nullable: false),
                    SesionId = table.Column<Guid>(type: "uuid", nullable: false),
                    TokenHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FechaExpiracion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FechaRevocacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_refresh_tokens", x => x.Id);
                    table.ForeignKey(
                        name: "FK_refresh_tokens_usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "recomendaciones",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MascoteroId = table.Column<Guid>(type: "uuid", nullable: false),
                    PrestadorServicioId = table.Column<Guid>(type: "uuid", nullable: false),
                    Titulo = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "character varying(3000)", maxLength: 3000, nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_recomendaciones", x => x.Id);
                    table.ForeignKey(
                        name: "FK_recomendaciones_mascoteros_MascoteroId",
                        column: x => x.MascoteroId,
                        principalTable: "mascoteros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_recomendaciones_prestadores_servicio_PrestadorServicioId",
                        column: x => x.PrestadorServicioId,
                        principalTable: "prestadores_servicio",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "rubros",
                columns: new[] { "Id", "Activo", "Nombre" },
                values: new object[,]
                {
                    { new Guid("10000000-0000-0000-0000-000000000001"), true, "Veterinaria" },
                    { new Guid("10000000-0000-0000-0000-000000000002"), true, "Peluquería" },
                    { new Guid("10000000-0000-0000-0000-000000000003"), true, "Paseador" },
                    { new Guid("10000000-0000-0000-0000-000000000004"), true, "Cuidado y guardería" },
                    { new Guid("10000000-0000-0000-0000-000000000005"), true, "Tienda de mascotas" },
                    { new Guid("10000000-0000-0000-0000-000000000006"), true, "Otro" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_mascoteros_LocalidadId",
                table: "mascoteros",
                column: "LocalidadId");

            migrationBuilder.CreateIndex(
                name: "IX_prestadores_servicio_LocalidadId",
                table: "prestadores_servicio",
                column: "LocalidadId");

            migrationBuilder.CreateIndex(
                name: "IX_prestadores_servicio_MascoteroCreadorId",
                table: "prestadores_servicio",
                column: "MascoteroCreadorId");

            migrationBuilder.CreateIndex(
                name: "IX_prestadores_servicio_RubroId_LocalidadId",
                table: "prestadores_servicio",
                columns: new[] { "RubroId", "LocalidadId" });

            migrationBuilder.CreateIndex(
                name: "IX_recomendaciones_FechaCreacion",
                table: "recomendaciones",
                column: "FechaCreacion");

            migrationBuilder.CreateIndex(
                name: "IX_recomendaciones_MascoteroId",
                table: "recomendaciones",
                column: "MascoteroId");

            migrationBuilder.CreateIndex(
                name: "IX_recomendaciones_PrestadorServicioId",
                table: "recomendaciones",
                column: "PrestadorServicioId");

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_FechaExpiracion",
                table: "refresh_tokens",
                column: "FechaExpiracion");

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_SesionId",
                table: "refresh_tokens",
                column: "SesionId");

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_TokenHash",
                table: "refresh_tokens",
                column: "TokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_refresh_tokens_UsuarioId",
                table: "refresh_tokens",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_rubros_Nombre",
                table: "rubros",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_Email",
                table: "usuarios",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_usuarios_MascoteroId",
                table: "usuarios",
                column: "MascoteroId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "recomendaciones");

            migrationBuilder.DropTable(
                name: "refresh_tokens");

            migrationBuilder.DropTable(
                name: "prestadores_servicio");

            migrationBuilder.DropTable(
                name: "usuarios");

            migrationBuilder.DropTable(
                name: "rubros");

            migrationBuilder.DropTable(
                name: "mascoteros");

            migrationBuilder.AlterDatabase()
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }
    }
}
