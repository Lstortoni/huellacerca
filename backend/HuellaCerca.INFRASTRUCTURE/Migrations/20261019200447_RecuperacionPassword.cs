using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class RecuperacionPassword : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "VersionSeguridad",
                table: "usuarios",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "VersionSeguridad",
                table: "refresh_tokens",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateTable(
                name: "recuperaciones_password",
                columns: table => new
                {
                    UsuarioId = table.Column<Guid>(type: "uuid", nullable: false),
                    CodigoId = table.Column<Guid>(type: "uuid", nullable: false),
                    CodigoHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    FechaSolicitud = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FechaExpiracion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IntentosFallidos = table.Column<int>(type: "integer", nullable: false),
                    CodigoVerificado = table.Column<bool>(type: "boolean", nullable: false),
                    PermisoHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    PermisoExpira = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    FechaUso = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    VentanaEnvios = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Envios = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_recuperaciones_password", x => x.UsuarioId);
                    table.ForeignKey(
                        name: "FK_recuperaciones_password_usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_recuperaciones_password_PermisoHash",
                table: "recuperaciones_password",
                column: "PermisoHash",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "recuperaciones_password");

            migrationBuilder.DropColumn(
                name: "VersionSeguridad",
                table: "usuarios");

            migrationBuilder.DropColumn(
                name: "VersionSeguridad",
                table: "refresh_tokens");
        }
    }
}
