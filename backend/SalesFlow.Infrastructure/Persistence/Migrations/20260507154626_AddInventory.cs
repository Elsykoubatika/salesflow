using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SalesFlow.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddInventory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "inventory_items",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Sku = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Unit = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false, defaultValue: "pcs"),
                    Quantity = table.Column<decimal>(type: "numeric(14,3)", nullable: false),
                    ReorderThreshold = table.Column<decimal>(type: "numeric(14,3)", nullable: true),
                    Cost = table.Column<decimal>(type: "numeric(12,2)", nullable: true),
                    LastMovementAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_inventory_items", x => x.Id);
                    table.ForeignKey(
                        name: "FK_inventory_items_products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_inventory_items_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "inventory_movements",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    InventoryItemId = table.Column<Guid>(type: "uuid", nullable: false),
                    Change = table.Column<decimal>(type: "numeric(14,3)", nullable: false),
                    Reason = table.Column<int>(type: "integer", nullable: false),
                    ResultingQuantity = table.Column<decimal>(type: "numeric(14,3)", nullable: false),
                    Note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SalesOrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_inventory_movements", x => x.Id);
                    table.ForeignKey(
                        name: "FK_inventory_movements_inventory_items_InventoryItemId",
                        column: x => x.InventoryItemId,
                        principalTable: "inventory_items",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_inventory_items_ProductId",
                table: "inventory_items",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_items_UserId",
                table: "inventory_items",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_items_UserId_IsActive",
                table: "inventory_items",
                columns: new[] { "UserId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_inventory_items_UserId_Sku",
                table: "inventory_items",
                columns: new[] { "UserId", "Sku" });

            migrationBuilder.CreateIndex(
                name: "IX_inventory_movements_InventoryItemId",
                table: "inventory_movements",
                column: "InventoryItemId");

            migrationBuilder.CreateIndex(
                name: "IX_inventory_movements_InventoryItemId_CreatedAt",
                table: "inventory_movements",
                columns: new[] { "InventoryItemId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_inventory_movements_SalesOrderId",
                table: "inventory_movements",
                column: "SalesOrderId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "inventory_movements");

            migrationBuilder.DropTable(
                name: "inventory_items");
        }
    }
}
