using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SalesFlow.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddProofs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "proofs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ImageBytes = table.Column<byte[]>(type: "bytea", nullable: false),
                    ImageContentType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ImageSizeBytes = table.Column<int>(type: "integer", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(14,2)", nullable: true),
                    Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, defaultValue: "XAF"),
                    TransactionReference = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Operator = table.Column<int>(type: "integer", nullable: false),
                    TransactionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    ErrorMessage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: true),
                    SalesOrderId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_proofs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_proofs_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_proofs_sales_orders_SalesOrderId",
                        column: x => x.SalesOrderId,
                        principalTable: "sales_orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_proofs_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_proofs_ClientId",
                table: "proofs",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_proofs_SalesOrderId",
                table: "proofs",
                column: "SalesOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_proofs_TransactionReference",
                table: "proofs",
                column: "TransactionReference");

            migrationBuilder.CreateIndex(
                name: "IX_proofs_UserId",
                table: "proofs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_proofs_UserId_Status",
                table: "proofs",
                columns: new[] { "UserId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "proofs");
        }
    }
}
