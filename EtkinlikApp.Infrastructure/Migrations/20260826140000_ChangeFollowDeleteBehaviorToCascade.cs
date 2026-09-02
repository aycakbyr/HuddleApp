using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EtkinlikApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ChangeFollowDeleteBehaviorToCascade : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Follows_Users_FollowerId",
                table: "Follows");

            migrationBuilder.DropForeignKey(
                name: "FK_Follows_Users_FollowingId",
                table: "Follows");

            migrationBuilder.AddForeignKey(
                name: "FK_Follows_Users_FollowerId",
                table: "Follows",
                column: "FollowerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Follows_Users_FollowingId",
                table: "Follows",
                column: "FollowingId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Follows_Users_FollowerId",
                table: "Follows");

            migrationBuilder.DropForeignKey(
                name: "FK_Follows_Users_FollowingId",
                table: "Follows");

            migrationBuilder.AddForeignKey(
                name: "FK_Follows_Users_FollowerId",
                table: "Follows",
                column: "FollowerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Follows_Users_FollowingId",
                table: "Follows",
                column: "FollowingId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
