using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SalesFlow.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddInventoryAndFinance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TechnicalQuoteItem_TechnicalInterventions_TechnicalInterven~",
                table: "TechnicalQuoteItem");

            migrationBuilder.DropForeignKey(
                name: "FK_TechnicalQuoteItem_TechnicalInvoices_TechnicalInvoiceId",
                table: "TechnicalQuoteItem");

            migrationBuilder.DropForeignKey(
                name: "FK_TechnicalQuoteItem_TechnicalQuotes_TechnicalQuoteId",
                table: "TechnicalQuoteItem");

            migrationBuilder.DropPrimaryKey(
                name: "PK_TechnicalQuoteItem",
                table: "TechnicalQuoteItem");

            migrationBuilder.RenameTable(
                name: "TechnicalQuoteItem",
                newName: "TechnicalQuoteItems");

            migrationBuilder.RenameIndex(
                name: "IX_TechnicalQuoteItem_TechnicalQuoteId",
                table: "TechnicalQuoteItems",
                newName: "IX_TechnicalQuoteItems_TechnicalQuoteId");

            migrationBuilder.RenameIndex(
                name: "IX_TechnicalQuoteItem_TechnicalInvoiceId",
                table: "TechnicalQuoteItems",
                newName: "IX_TechnicalQuoteItems_TechnicalInvoiceId");

            migrationBuilder.RenameIndex(
                name: "IX_TechnicalQuoteItem_TechnicalInterventionId",
                table: "TechnicalQuoteItems",
                newName: "IX_TechnicalQuoteItems_TechnicalInterventionId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_TechnicalQuoteItems",
                table: "TechnicalQuoteItems",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TechnicalQuoteItems_TechnicalInterventions_TechnicalInterve~",
                table: "TechnicalQuoteItems",
                column: "TechnicalInterventionId",
                principalTable: "TechnicalInterventions",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TechnicalQuoteItems_TechnicalInvoices_TechnicalInvoiceId",
                table: "TechnicalQuoteItems",
                column: "TechnicalInvoiceId",
                principalTable: "TechnicalInvoices",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TechnicalQuoteItems_TechnicalQuotes_TechnicalQuoteId",
                table: "TechnicalQuoteItems",
                column: "TechnicalQuoteId",
                principalTable: "TechnicalQuotes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TechnicalQuoteItems_TechnicalInterventions_TechnicalInterve~",
                table: "TechnicalQuoteItems");

            migrationBuilder.DropForeignKey(
                name: "FK_TechnicalQuoteItems_TechnicalInvoices_TechnicalInvoiceId",
                table: "TechnicalQuoteItems");

            migrationBuilder.DropForeignKey(
                name: "FK_TechnicalQuoteItems_TechnicalQuotes_TechnicalQuoteId",
                table: "TechnicalQuoteItems");

            migrationBuilder.DropPrimaryKey(
                name: "PK_TechnicalQuoteItems",
                table: "TechnicalQuoteItems");

            migrationBuilder.RenameTable(
                name: "TechnicalQuoteItems",
                newName: "TechnicalQuoteItem");

            migrationBuilder.RenameIndex(
                name: "IX_TechnicalQuoteItems_TechnicalQuoteId",
                table: "TechnicalQuoteItem",
                newName: "IX_TechnicalQuoteItem_TechnicalQuoteId");

            migrationBuilder.RenameIndex(
                name: "IX_TechnicalQuoteItems_TechnicalInvoiceId",
                table: "TechnicalQuoteItem",
                newName: "IX_TechnicalQuoteItem_TechnicalInvoiceId");

            migrationBuilder.RenameIndex(
                name: "IX_TechnicalQuoteItems_TechnicalInterventionId",
                table: "TechnicalQuoteItem",
                newName: "IX_TechnicalQuoteItem_TechnicalInterventionId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_TechnicalQuoteItem",
                table: "TechnicalQuoteItem",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TechnicalQuoteItem_TechnicalInterventions_TechnicalInterven~",
                table: "TechnicalQuoteItem",
                column: "TechnicalInterventionId",
                principalTable: "TechnicalInterventions",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TechnicalQuoteItem_TechnicalInvoices_TechnicalInvoiceId",
                table: "TechnicalQuoteItem",
                column: "TechnicalInvoiceId",
                principalTable: "TechnicalInvoices",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TechnicalQuoteItem_TechnicalQuotes_TechnicalQuoteId",
                table: "TechnicalQuoteItem",
                column: "TechnicalQuoteId",
                principalTable: "TechnicalQuotes",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
