using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class PublicacionesMascotas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "publicaciones_mascotas",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MascoteroId = table.Column<Guid>(type: "uuid", nullable: false),
                    TipoPublicacion = table.Column<int>(type: "integer", nullable: false),
                    TipoMascota = table.Column<int>(type: "integer", nullable: false),
                    NombreMascota = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Descripcion = table.Column<string>(type: "character varying(3000)", maxLength: 3000, nullable: false),
                    FechaSuceso = table.Column<DateOnly>(type: "date", nullable: false),
                    LocalidadId = table.Column<Guid>(type: "uuid", nullable: false),
                    Zona = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    InformacionContacto = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    FechaCreacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Estado = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_publicaciones_mascotas", x => x.Id);
                    table.CheckConstraint("CK_publicaciones_mascotas_estado", "\"Estado\" IN (1, 2)");
                    table.CheckConstraint("CK_publicaciones_mascotas_mascota", "\"TipoMascota\" IN (1, 2, 3)");
                    table.CheckConstraint("CK_publicaciones_mascotas_tipo", "\"TipoPublicacion\" IN (1, 2)");
                    table.ForeignKey(
                        name: "FK_publicaciones_mascotas_localidades_LocalidadId",
                        column: x => x.LocalidadId,
                        principalTable: "localidades",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_publicaciones_mascotas_mascoteros_MascoteroId",
                        column: x => x.MascoteroId,
                        principalTable: "mascoteros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "fotos_publicaciones",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PublicacionMascotaId = table.Column<Guid>(type: "uuid", nullable: false),
                    RutaArchivo = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Orden = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_fotos_publicaciones", x => x.Id);
                    table.CheckConstraint("CK_fotos_publicaciones_orden", "\"Orden\" >= 0");
                    table.ForeignKey(
                        name: "FK_fotos_publicaciones_publicaciones_mascotas_PublicacionMasco~",
                        column: x => x.PublicacionMascotaId,
                        principalTable: "publicaciones_mascotas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_fotos_publicaciones_PublicacionMascotaId_Orden",
                table: "fotos_publicaciones",
                columns: new[] { "PublicacionMascotaId", "Orden" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_publicaciones_mascotas_FechaCreacion",
                table: "publicaciones_mascotas",
                column: "FechaCreacion");

            migrationBuilder.CreateIndex(
                name: "IX_publicaciones_mascotas_LocalidadId_Estado_FechaSuceso",
                table: "publicaciones_mascotas",
                columns: new[] { "LocalidadId", "Estado", "FechaSuceso" });

            migrationBuilder.CreateIndex(
                name: "IX_publicaciones_mascotas_MascoteroId",
                table: "publicaciones_mascotas",
                column: "MascoteroId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "fotos_publicaciones");

            migrationBuilder.DropTable(
                name: "publicaciones_mascotas");
        }
    }
}
