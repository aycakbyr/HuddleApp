using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EtkinlikApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MakeCommunityPhotoReusableForDm : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<Guid>(
                name: "CommunityId",
                table: "CommunityPhotos",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddColumn<Guid>(
                name: "ReceiverId",
                table: "CommunityPhotos",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_CommunityPhotos_ReceiverId",
                table: "CommunityPhotos",
                column: "ReceiverId");

            migrationBuilder.AddForeignKey(
                name: "FK_CommunityPhotos_Users_ReceiverId",
                table: "CommunityPhotos",
                column: "ReceiverId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CommunityPhotos_Users_ReceiverId",
                table: "CommunityPhotos");

            migrationBuilder.DropIndex(
                name: "IX_CommunityPhotos_ReceiverId",
                table: "CommunityPhotos");

            migrationBuilder.DropColumn(
                name: "ReceiverId",
                table: "CommunityPhotos");

            migrationBuilder.AlterColumn<Guid>(
                name: "CommunityId",
                table: "CommunityPhotos",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);
        }
    }
}
