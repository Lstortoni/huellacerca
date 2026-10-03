using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class DispositivosYEnviosPush : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DispositivosPush",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MascoteroId = table.Column<Guid>(type: "uuid", nullable: false),
                    SesionId = table.Column<Guid>(type: "uuid", nullable: false),
                    Token = table.Column<string>(type: "character varying(2048)", maxLength: 2048, nullable: false),
                    Plataforma = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false),
                    Version = table.Column<Guid>(type: "uuid", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DispositivosPush", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DispositivosPush_mascoteros_MascoteroId",
                        column: x => x.MascoteroId,
                        principalTable: "mascoteros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EnviosPush",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    NotificacionId = table.Column<Guid>(type: "uuid", nullable: false),
                    DispositivoPushId = table.Column<Guid>(type: "uuid", nullable: false),
                    VersionDispositivo = table.Column<Guid>(type: "uuid", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ProximoIntento = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Intentos = table.Column<int>(type: "integer", nullable: false),
                    Reserva = table.Column<Guid>(type: "uuid", nullable: true),
                    FechaFinalizacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Resultado = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EnviosPush", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EnviosPush_DispositivosPush_DispositivoPushId",
                        column: x => x.DispositivoPushId,
                        principalTable: "DispositivosPush",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EnviosPush_Notificaciones_NotificacionId",
                        column: x => x.NotificacionId,
                        principalTable: "Notificaciones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DispositivosPush_MascoteroId_Activo",
                table: "DispositivosPush",
                columns: new[] { "MascoteroId", "Activo" });

            migrationBuilder.CreateIndex(
                name: "IX_DispositivosPush_Token",
                table: "DispositivosPush",
                column: "Token",
                unique: true,
                filter: "\"Activo\" = TRUE");

            migrationBuilder.CreateIndex(
                name: "IX_EnviosPush_DispositivoPushId",
                table: "EnviosPush",
                column: "DispositivoPushId");

            migrationBuilder.CreateIndex(
                name: "IX_EnviosPush_NotificacionId_DispositivoPushId",
                table: "EnviosPush",
                columns: new[] { "NotificacionId", "DispositivoPushId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EnviosPush_ProximoIntento",
                table: "EnviosPush",
                column: "ProximoIntento",
                filter: "\"FechaFinalizacion\" IS NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EnviosPush");

            migrationBuilder.DropTable(
                name: "DispositivosPush");
        }
    }
}
