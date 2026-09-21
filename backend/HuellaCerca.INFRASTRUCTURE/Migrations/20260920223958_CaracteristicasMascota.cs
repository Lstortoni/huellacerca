using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class CaracteristicasMascota : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ColorOjos",
                table: "publicaciones_mascotas",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ColorPredominante",
                table: "publicaciones_mascotas",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Pelaje",
                table: "publicaciones_mascotas",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Raza",
                table: "publicaciones_mascotas",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Tamano",
                table: "publicaciones_mascotas",
                type: "integer",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_caracteristicas_otro",
                table: "publicaciones_mascotas",
                sql: "\"TipoMascota\" <> 3 OR (\"Raza\" IS NULL AND \"Pelaje\" IS NULL AND \"ColorOjos\" IS NULL)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_color",
                table: "publicaciones_mascotas",
                sql: "\"ColorPredominante\" IS NULL OR \"ColorPredominante\" IN (1, 2, 3, 4, 5, 6, 7)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_ojos",
                table: "publicaciones_mascotas",
                sql: "\"ColorOjos\" IS NULL OR \"ColorOjos\" IN (1, 2, 3)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_pelaje",
                table: "publicaciones_mascotas",
                sql: "\"Pelaje\" IS NULL OR \"Pelaje\" IN (1, 2, 3)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_raza",
                table: "publicaciones_mascotas",
                sql: "\"Raza\" IS NULL OR \"Raza\" IN (1, 2)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_tamano",
                table: "publicaciones_mascotas",
                sql: "\"Tamano\" IS NULL OR \"Tamano\" IN (1, 2, 3)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_caracteristicas_otro",
                table: "publicaciones_mascotas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_color",
                table: "publicaciones_mascotas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_ojos",
                table: "publicaciones_mascotas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_pelaje",
                table: "publicaciones_mascotas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_raza",
                table: "publicaciones_mascotas");

            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_tamano",
                table: "publicaciones_mascotas");

            migrationBuilder.DropColumn(
                name: "ColorOjos",
                table: "publicaciones_mascotas");

            migrationBuilder.DropColumn(
                name: "ColorPredominante",
                table: "publicaciones_mascotas");

            migrationBuilder.DropColumn(
                name: "Pelaje",
                table: "publicaciones_mascotas");

            migrationBuilder.DropColumn(
                name: "Raza",
                table: "publicaciones_mascotas");

            migrationBuilder.DropColumn(
                name: "Tamano",
                table: "publicaciones_mascotas");
        }
    }
}
