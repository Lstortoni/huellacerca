using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class InitialGeography : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "paises",
                columns: table => new
                {
                    Codigo = table.Column<string>(type: "character varying(2)", maxLength: 2, nullable: false),
                    Nombre = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_paises", x => x.Codigo);
                });

            migrationBuilder.CreateTable(
                name: "provincias",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GeorefId = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    PaisCodigo = table.Column<string>(type: "character varying(2)", maxLength: 2, nullable: false),
                    Nombre = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Activa = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_provincias", x => x.Id);
                    table.ForeignKey(
                        name: "FK_provincias_paises_PaisCodigo",
                        column: x => x.PaisCodigo,
                        principalTable: "paises",
                        principalColumn: "Codigo",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "localidades",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GeorefId = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    ProvinciaId = table.Column<Guid>(type: "uuid", nullable: false),
                    Nombre = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    NombreBusqueda = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Activa = table.Column<bool>(type: "boolean", nullable: false),
                    Latitud = table.Column<decimal>(type: "numeric(10,7)", precision: 10, scale: 7, nullable: true),
                    Longitud = table.Column<decimal>(type: "numeric(10,7)", precision: 10, scale: 7, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_localidades", x => x.Id);
                    table.ForeignKey(
                        name: "FK_localidades_provincias_ProvinciaId",
                        column: x => x.ProvinciaId,
                        principalTable: "provincias",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_localidades_GeorefId",
                table: "localidades",
                column: "GeorefId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_localidades_ProvinciaId_NombreBusqueda",
                table: "localidades",
                columns: new[] { "ProvinciaId", "NombreBusqueda" });

            migrationBuilder.CreateIndex(
                name: "IX_provincias_GeorefId",
                table: "provincias",
                column: "GeorefId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_provincias_PaisCodigo",
                table: "provincias",
                column: "PaisCodigo");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "localidades");

            migrationBuilder.DropTable(
                name: "provincias");

            migrationBuilder.DropTable(
                name: "paises");
        }
    }
}
