using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class FotoUnicaR2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Antes no había un cargador de archivos. No convertir rutas antiguas en claves R2 a ciegas.
            migrationBuilder.Sql("""
                DO $$ BEGIN
                    IF EXISTS (SELECT 1 FROM fotos_publicaciones) THEN
                        RAISE EXCEPTION 'Hay referencias de fotos anteriores. Migrar sus archivos a R2 antes de aplicar FotoUnicaR2.';
                    END IF;
                END $$;
                """);
            migrationBuilder.DropIndex(
                name: "IX_fotos_publicaciones_PublicacionMascotaId_Orden",
                table: "fotos_publicaciones");

            migrationBuilder.DropCheckConstraint(
                name: "CK_fotos_publicaciones_orden",
                table: "fotos_publicaciones");

            migrationBuilder.DropColumn(
                name: "Orden",
                table: "fotos_publicaciones");

            migrationBuilder.RenameColumn(
                name: "RutaArchivo",
                table: "fotos_publicaciones",
                newName: "ObjectKey");

            migrationBuilder.CreateTable(
                name: "fotos_pendientes_limpieza",
                columns: table => new
                {
                    ObjectKey = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    LimpiarDesdeUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_fotos_pendientes_limpieza", x => x.ObjectKey);
                });

            migrationBuilder.CreateIndex(
                name: "IX_fotos_publicaciones_PublicacionMascotaId",
                table: "fotos_publicaciones",
                column: "PublicacionMascotaId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_fotos_pendientes_limpieza_LimpiarDesdeUtc",
                table: "fotos_pendientes_limpieza",
                column: "LimpiarDesdeUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "fotos_pendientes_limpieza");

            migrationBuilder.DropIndex(
                name: "IX_fotos_publicaciones_PublicacionMascotaId",
                table: "fotos_publicaciones");

            migrationBuilder.RenameColumn(
                name: "ObjectKey",
                table: "fotos_publicaciones",
                newName: "RutaArchivo");

            migrationBuilder.AddColumn<int>(
                name: "Orden",
                table: "fotos_publicaciones",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_fotos_publicaciones_PublicacionMascotaId_Orden",
                table: "fotos_publicaciones",
                columns: new[] { "PublicacionMascotaId", "Orden" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_fotos_publicaciones_orden",
                table: "fotos_publicaciones",
                sql: "\"Orden\" >= 0");
        }
    }
}
