using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EtkinlikApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsAnnouncementToMessage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsAnnouncement",
                table: "Messages",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsAnnouncement",
                table: "Messages");
        }
    }
}
