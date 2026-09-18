using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace HuellaCerca.INFRASTRUCTURE.Migrations
{
    /// <inheritdoc />
    public partial class PublicacionesAdopcion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas",
                sql: "\"TipoPublicacion\" IN (1, 2, 3)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas");

            migrationBuilder.AddCheckConstraint(
                name: "CK_publicaciones_mascotas_tipo",
                table: "publicaciones_mascotas",
                sql: "\"TipoPublicacion\" IN (1, 2)");
        }
    }
}
