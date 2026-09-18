using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class RecomendacionesConAspectos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Resguardo completo sin FK antes de quitar textos o consolidar duplicados.
            migrationBuilder.Sql("""
                LOCK TABLE recomendaciones IN ACCESS EXCLUSIVE MODE;
                CREATE TABLE recomendaciones_textos_respaldo AS
                SELECT r.*, first_value(r."Id") OVER (
                    PARTITION BY r."MascoteroId", r."PrestadorServicioId"
                    ORDER BY r."FechaCreacion", r."Id") AS "RecomendacionConservadaId",
                    now() AS "FechaRespaldo"
                FROM recomendaciones r;
                ALTER TABLE recomendaciones_textos_respaldo ADD PRIMARY KEY ("Id");
                DELETE FROM recomendaciones r USING recomendaciones_textos_respaldo a
                WHERE r."Id" = a."Id" AND r."Id" <> a."RecomendacionConservadaId";
                """);
            migrationBuilder.DropIndex(
                name: "IX_recomendaciones_MascoteroId",
                table: "recomendaciones");

            migrationBuilder.DropColumn(
                name: "Descripcion",
                table: "recomendaciones");

            migrationBuilder.DropColumn(
                name: "Titulo",
                table: "recomendaciones");

            migrationBuilder.CreateTable(
                name: "aspectos_recomendacion",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Nombre = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_aspectos_recomendacion", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "recomendaciones_aspectos",
                columns: table => new
                {
                    RecomendacionId = table.Column<Guid>(type: "uuid", nullable: false),
                    AspectoRecomendacionId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_recomendaciones_aspectos", x => new { x.RecomendacionId, x.AspectoRecomendacionId });
                    table.ForeignKey(
                        name: "FK_recomendaciones_aspectos_aspectos_recomendacion_AspectoReco~",
                        column: x => x.AspectoRecomendacionId,
                        principalTable: "aspectos_recomendacion",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_recomendaciones_aspectos_recomendaciones_RecomendacionId",
                        column: x => x.RecomendacionId,
                        principalTable: "recomendaciones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "aspectos_recomendacion",
                columns: new[] { "Id", "Activo", "Nombre" },
                values: new object[,]
                {
                    { new Guid("20000000-0000-0000-0000-000000000001"), true, "Buena atención" },
                    { new Guid("20000000-0000-0000-0000-000000000002"), true, "Responsabilidad" },
                    { new Guid("20000000-0000-0000-0000-000000000003"), true, "Cumplimiento" },
                    { new Guid("20000000-0000-0000-0000-000000000004"), true, "Buen trato con la mascota" },
                    { new Guid("20000000-0000-0000-0000-000000000005"), true, "Rapidez" },
                    { new Guid("20000000-0000-0000-0000-000000000006"), true, "Buena comunicación" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_recomendaciones_MascoteroId_PrestadorServicioId",
                table: "recomendaciones",
                columns: new[] { "MascoteroId", "PrestadorServicioId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_aspectos_recomendacion_Nombre",
                table: "aspectos_recomendacion",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_recomendaciones_aspectos_AspectoRecomendacionId",
                table: "recomendaciones_aspectos",
                column: "AspectoRecomendacionId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            throw new NotSupportedException("Restaurar explícitamente desde recomendaciones_textos_respaldo: una reversión automática perdería aspectos nuevos o resucitaría recomendaciones retiradas.");
        }
    }
}
