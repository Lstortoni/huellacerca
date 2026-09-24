using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class NotificacionesCoincidencias : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Notificaciones",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MascoteroId = table.Column<Guid>(type: "uuid", nullable: false),
                    PublicacionId = table.Column<Guid>(type: "uuid", nullable: false),
                    PublicacionCoincidenteId = table.Column<Guid>(type: "uuid", nullable: false),
                    Titulo = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Mensaje = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    FechaLectura = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notificaciones", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Notificaciones_mascoteros_MascoteroId",
                        column: x => x.MascoteroId,
                        principalTable: "mascoteros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Notificaciones_publicaciones_mascotas_PublicacionCoincident~",
                        column: x => x.PublicacionCoincidenteId,
                        principalTable: "publicaciones_mascotas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Notificaciones_publicaciones_mascotas_PublicacionId",
                        column: x => x.PublicacionId,
                        principalTable: "publicaciones_mascotas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "NotificacionesPendientes",
                columns: table => new
                {
                    PublicacionId = table.Column<Guid>(type: "uuid", nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificacionesPendientes", x => x.PublicacionId);
                    table.ForeignKey(
                        name: "FK_NotificacionesPendientes_publicaciones_mascotas_Publicacion~",
                        column: x => x.PublicacionId,
                        principalTable: "publicaciones_mascotas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Notificaciones_MascoteroId",
                table: "Notificaciones",
                column: "MascoteroId",
                filter: "\"FechaLectura\" IS NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Notificaciones_MascoteroId_FechaCreacion_Id",
                table: "Notificaciones",
                columns: new[] { "MascoteroId", "FechaCreacion", "Id" });

            migrationBuilder.CreateIndex(
                name: "IX_Notificaciones_MascoteroId_PublicacionId_PublicacionCoincid~",
                table: "Notificaciones",
                columns: new[] { "MascoteroId", "PublicacionId", "PublicacionCoincidenteId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Notificaciones_PublicacionCoincidenteId",
                table: "Notificaciones",
                column: "PublicacionCoincidenteId");

            migrationBuilder.CreateIndex(
                name: "IX_Notificaciones_PublicacionId",
                table: "Notificaciones",
                column: "PublicacionId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificacionesPendientes_FechaCreacion",
                table: "NotificacionesPendientes",
                column: "FechaCreacion");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Notificaciones");

            migrationBuilder.DropTable(
                name: "NotificacionesPendientes");
        }
    }
}
