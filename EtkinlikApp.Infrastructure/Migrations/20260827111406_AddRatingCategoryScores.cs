using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EtkinlikApp.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddRatingCategoryScores : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CommunicationScore",
                table: "Ratings",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OrganizationScore",
                table: "Ratings",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "WarmthScore",
                table: "Ratings",
                type: "integer",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_Ratings_CommunicationScore",
                table: "Ratings",
                sql: "\"CommunicationScore\" IS NULL OR (\"CommunicationScore\" >= 1 AND \"CommunicationScore\" <= 5)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Ratings_OrganizationScore",
                table: "Ratings",
                sql: "\"OrganizationScore\" IS NULL OR (\"OrganizationScore\" >= 1 AND \"OrganizationScore\" <= 5)");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Ratings_WarmthScore",
                table: "Ratings",
                sql: "\"WarmthScore\" IS NULL OR (\"WarmthScore\" >= 1 AND \"WarmthScore\" <= 5)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Ratings_CommunicationScore",
                table: "Ratings");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Ratings_OrganizationScore",
                table: "Ratings");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Ratings_WarmthScore",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "CommunicationScore",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "OrganizationScore",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "WarmthScore",
                table: "Ratings");
        }
    }
}
