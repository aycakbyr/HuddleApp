using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EtkinlikApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCommunitySystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CommunityId",
                table: "Messages",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "CommunityId",
                table: "Events",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Communities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ProfileImageUrl = table.Column<string>(type: "text", nullable: true),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Communities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Communities_Users_CreatedByUserId",
                        column: x => x.CreatedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "CommunityJoinRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CommunityId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    RequestedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    RespondedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommunityJoinRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CommunityJoinRequests_Communities_CommunityId",
                        column: x => x.CommunityId,
                        principalTable: "Communities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CommunityJoinRequests_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CommunityMembers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CommunityId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<int>(type: "integer", nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommunityMembers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CommunityMembers_Communities_CommunityId",
                        column: x => x.CommunityId,
                        principalTable: "Communities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CommunityMembers_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_CommunityId",
                table: "Messages",
                column: "CommunityId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_CommunityId",
                table: "Events",
                column: "CommunityId");

            migrationBuilder.CreateIndex(
                name: "IX_Communities_CreatedByUserId",
                table: "Communities",
                column: "CreatedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_CommunityJoinRequests_CommunityId_UserId",
                table: "CommunityJoinRequests",
                columns: new[] { "CommunityId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CommunityJoinRequests_UserId",
                table: "CommunityJoinRequests",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_CommunityMembers_CommunityId_UserId",
                table: "CommunityMembers",
                columns: new[] { "CommunityId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CommunityMembers_UserId",
                table: "CommunityMembers",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Events_Communities_CommunityId",
                table: "Events",
                column: "CommunityId",
                principalTable: "Communities",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Messages_Communities_CommunityId",
                table: "Messages",
                column: "CommunityId",
                principalTable: "Communities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Events_Communities_CommunityId",
                table: "Events");

            migrationBuilder.DropForeignKey(
                name: "FK_Messages_Communities_CommunityId",
                table: "Messages");

            migrationBuilder.DropTable(
                name: "CommunityJoinRequests");

            migrationBuilder.DropTable(
                name: "CommunityMembers");

            migrationBuilder.DropTable(
                name: "Communities");

            migrationBuilder.DropIndex(
                name: "IX_Messages_CommunityId",
                table: "Messages");

            migrationBuilder.DropIndex(
                name: "IX_Events_CommunityId",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "CommunityId",
                table: "Messages");

            migrationBuilder.DropColumn(
                name: "CommunityId",
                table: "Events");
        }
    }
}
