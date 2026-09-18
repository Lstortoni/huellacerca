using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class BuscoAdoptarFechaOpcional : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "FechaSuceso",
                table: "publicaciones_mascotas",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas",
                sql: "\"TipoPublicacion\" IN (1, 2, 3, 4)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "FechaSuceso",
                table: "publicaciones_mascotas",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1),
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas",
                sql: "\"TipoPublicacion\" IN (1, 2, 3)");
        }
    }
}
