using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SalesFlow.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddDealsModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DealEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DealShareId = table.Column<Guid>(type: "uuid", nullable: false),
                    EventType = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    SaleAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    OrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    CommissionEarned = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    IpHash = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    UserAgent = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DealEvents", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Deals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatorUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    ContentImages = table.Column<string>(type: "text", nullable: true),
                    ContentMaterials = table.Column<string>(type: "text", nullable: true),
                    CommissionType = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    CommissionAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    CommissionPercent = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true),
                    Currency = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    Conditions = table.Column<string>(type: "text", nullable: true),
                    StockAvailable = table.Column<int>(type: "integer", nullable: true),
                    ActiveFrom = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ActiveTo = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<string>(type: "text", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Deals", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DealShares",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DealId = table.Column<Guid>(type: "uuid", nullable: false),
                    AffiliateUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Channel = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    UniqueCode = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DealShares", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DealEvents_DealShareId",
                table: "DealEvents",
                column: "DealShareId");

            migrationBuilder.CreateIndex(
                name: "IX_DealEvents_DealShareId_EventType_CreatedAt",
                table: "DealEvents",
                columns: new[] { "DealShareId", "EventType", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_DealEvents_EventType",
                table: "DealEvents",
                column: "EventType");

            migrationBuilder.CreateIndex(
                name: "IX_Deals_CreatorUserId",
                table: "Deals",
                column: "CreatorUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Deals_Status",
                table: "Deals",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_Deals_Status_ActiveFrom_ActiveTo",
                table: "Deals",
                columns: new[] { "Status", "ActiveFrom", "ActiveTo" });

            migrationBuilder.CreateIndex(
                name: "IX_DealShares_AffiliateUserId",
                table: "DealShares",
                column: "AffiliateUserId");

            migrationBuilder.CreateIndex(
                name: "IX_DealShares_DealId",
                table: "DealShares",
                column: "DealId");

            migrationBuilder.CreateIndex(
                name: "IX_DealShares_DealId_AffiliateUserId_Channel",
                table: "DealShares",
                columns: new[] { "DealId", "AffiliateUserId", "Channel" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DealShares_UniqueCode",
                table: "DealShares",
                column: "UniqueCode",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DealEvents");

            migrationBuilder.DropTable(
                name: "Deals");

            migrationBuilder.DropTable(
                name: "DealShares");
        }
    }
}
