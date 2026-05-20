using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SalesFlow.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddTechnicalAndLiberalModules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FinanceAccounts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountName = table.Column<string>(type: "text", nullable: false),
                    AccountType = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    CurrentBalance = table.Column<decimal>(type: "numeric", nullable: false),
                    Currency = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FinanceAccounts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FinanceAccounts_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LiberalContracts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    ContractNumber = table.Column<string>(type: "text", nullable: false),
                    ContractName = table.Column<string>(type: "text", nullable: false),
                    ServiceDescription = table.Column<string>(type: "text", nullable: false),
                    PricingModel = table.Column<string>(type: "text", nullable: false),
                    HourlyRate = table.Column<decimal>(type: "numeric", nullable: true),
                    DailyRate = table.Column<decimal>(type: "numeric", nullable: true),
                    ProjectRate = table.Column<decimal>(type: "numeric", nullable: true),
                    MonthlyRetainer = table.Column<decimal>(type: "numeric", nullable: true),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EngagementType = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    SignedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsRecurring = table.Column<bool>(type: "boolean", nullable: false),
                    RecurrencePattern = table.Column<string>(type: "text", nullable: true),
                    NextRenewalDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AutoRenew = table.Column<bool>(type: "boolean", nullable: false),
                    TotalBilled = table.Column<decimal>(type: "numeric", nullable: false),
                    TotalPaid = table.Column<decimal>(type: "numeric", nullable: false),
                    ContractDocument = table.Column<string>(type: "text", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LiberalContracts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LiberalContracts_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LiberalContracts_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LiberalProjects",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    ProjectType = table.Column<string>(type: "text", nullable: false),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    BudgetAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    EstimatedHours = table.Column<decimal>(type: "numeric", nullable: false),
                    HourlyRate = table.Column<decimal>(type: "numeric", nullable: false),
                    TotalInvoiced = table.Column<decimal>(type: "numeric", nullable: false),
                    TotalPaid = table.Column<decimal>(type: "numeric", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LiberalProjects", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LiberalProjects_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LiberalProjects_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MaintenancePlans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssetName = table.Column<string>(type: "text", nullable: false),
                    AssetModel = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Frequency = table.Column<string>(type: "text", nullable: false),
                    EstimatedCost = table.Column<decimal>(type: "numeric", nullable: false),
                    EstimatedDuration = table.Column<double>(type: "double precision", nullable: false),
                    LastMaintenanceDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    NextScheduledDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaintenancePlans", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MaintenancePlans_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MaintenancePlans_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProspectContacts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyName = table.Column<string>(type: "text", nullable: false),
                    ContactPerson = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: false),
                    PhoneNumber = table.Column<string>(type: "text", nullable: false),
                    Stage = table.Column<string>(type: "text", nullable: false),
                    Source = table.Column<string>(type: "text", nullable: true),
                    FirstContactDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastContactDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    NextFollowUpDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EstimatedValue = table.Column<decimal>(type: "numeric", nullable: false),
                    Probability = table.Column<decimal>(type: "numeric", nullable: false),
                    RenewalDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    NeedsRenewal = table.Column<bool>(type: "boolean", nullable: false),
                    RenewalReminders = table.Column<List<string>>(type: "text[]", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProspectContacts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProspectContacts_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TechnicalQuotes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    QuoteNumber = table.Column<string>(type: "text", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    ServiceLocation = table.Column<string>(type: "text", nullable: false),
                    EstimatedHours = table.Column<decimal>(type: "numeric", nullable: false),
                    HourlyRate = table.Column<decimal>(type: "numeric", nullable: false),
                    MaterialsCost = table.Column<decimal>(type: "numeric", nullable: false),
                    LaborCost = table.Column<decimal>(type: "numeric", nullable: false),
                    Total = table.Column<decimal>(type: "numeric", nullable: false),
                    CalculationContextJson = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AcceptedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TechnicalQuotes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TechnicalQuotes_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TechnicalQuotes_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FinanceBudgets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FinanceAccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    BudgetName = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    PlannedAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    SpentAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    Period = table.Column<string>(type: "text", nullable: false),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FinanceBudgets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FinanceBudgets_FinanceAccounts_FinanceAccountId",
                        column: x => x.FinanceAccountId,
                        principalTable: "FinanceAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FinanceCategory",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FinanceAccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    CategoryName = table.Column<string>(type: "text", nullable: false),
                    CategoryType = table.Column<string>(type: "text", nullable: false),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    Color = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FinanceCategory", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FinanceCategory_FinanceAccounts_FinanceAccountId",
                        column: x => x.FinanceAccountId,
                        principalTable: "FinanceAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FinanceTransactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FinanceAccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    TransactionType = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "text", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    TransactionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    PaymentMethod = table.Column<string>(type: "text", nullable: true),
                    ReferenceNumber = table.Column<string>(type: "text", nullable: true),
                    IsRecurring = table.Column<bool>(type: "boolean", nullable: false),
                    RecurrencePattern = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FinanceTransactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FinanceTransactions_FinanceAccounts_FinanceAccountId",
                        column: x => x.FinanceAccountId,
                        principalTable: "FinanceAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LiberalInvoices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ContractId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    InvoiceNumber = table.Column<string>(type: "text", nullable: false),
                    InvoiceDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DueDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ServiceStartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ServiceEndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TotalHours = table.Column<decimal>(type: "numeric", nullable: false),
                    BaseAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    ComplexityMultiplier = table.Column<decimal>(type: "numeric", nullable: false),
                    TaxAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    AdvancePayment = table.Column<decimal>(type: "numeric", nullable: false),
                    Total = table.Column<decimal>(type: "numeric", nullable: false),
                    DeliverableDetails = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    AmountPaid = table.Column<decimal>(type: "numeric", nullable: false),
                    PaidDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LiberalInvoices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LiberalInvoices_LiberalContracts_ContractId",
                        column: x => x.ContractId,
                        principalTable: "LiberalContracts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LiberalInvoices_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LiberalInvoices_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProjectDeliverables",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LiberalProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DueDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    CompletedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectDeliverables", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectDeliverables_LiberalProjects_LiberalProjectId",
                        column: x => x.LiberalProjectId,
                        principalTable: "LiberalProjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProjectDocument",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LiberalProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    DocumentName = table.Column<string>(type: "text", nullable: false),
                    DocumentType = table.Column<string>(type: "text", nullable: false),
                    FilePath = table.Column<string>(type: "text", nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    ContentType = table.Column<string>(type: "text", nullable: false),
                    IsTemplate = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectDocument", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectDocument_LiberalProjects_LiberalProjectId",
                        column: x => x.LiberalProjectId,
                        principalTable: "LiberalProjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProjectTask",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LiberalProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    Priority = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    DueDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EstimatedHours = table.Column<decimal>(type: "numeric", nullable: false),
                    ActualHours = table.Column<decimal>(type: "numeric", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectTask", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ProjectTask_LiberalProjects_LiberalProjectId",
                        column: x => x.LiberalProjectId,
                        principalTable: "LiberalProjects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MaintenanceTasks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MaintenancePlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    TaskName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Sequence = table.Column<int>(type: "integer", nullable: false),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaintenanceTasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MaintenanceTasks_MaintenancePlans_MaintenancePlanId",
                        column: x => x.MaintenancePlanId,
                        principalTable: "MaintenancePlans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PipelineEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProspectContactId = table.Column<Guid>(type: "uuid", nullable: false),
                    EventType = table.Column<string>(type: "text", nullable: false),
                    EventDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    IsRenewalEvent = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PipelineEvents", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PipelineEvents_ProspectContacts_ProspectContactId",
                        column: x => x.ProspectContactId,
                        principalTable: "ProspectContacts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TechnicalInterventions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalQuoteId = table.Column<Guid>(type: "uuid", nullable: true),
                    InterventionNumber = table.Column<string>(type: "text", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Location = table.Column<string>(type: "text", nullable: false),
                    StartTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: false),
                    PhotoUrls = table.Column<List<string>>(type: "text[]", nullable: false),
                    TotalAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TechnicalInterventions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TechnicalInterventions_TechnicalQuotes_TechnicalQuoteId",
                        column: x => x.TechnicalQuoteId,
                        principalTable: "TechnicalQuotes",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TechnicalInterventions_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TechnicalInterventions_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "InvoiceDeliverable",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LiberalInvoiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeliverableName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeliveryDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InvoiceDeliverable", x => x.Id);
                    table.ForeignKey(
                        name: "FK_InvoiceDeliverable_LiberalInvoices_LiberalInvoiceId",
                        column: x => x.LiberalInvoiceId,
                        principalTable: "LiberalInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PaymentRecord",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    LiberalInvoiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    PaymentDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PaymentMethod = table.Column<string>(type: "text", nullable: false),
                    TransactionReference = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentRecord", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PaymentRecord_LiberalInvoices_LiberalInvoiceId",
                        column: x => x.LiberalInvoiceId,
                        principalTable: "LiberalInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MaintenanceChecklistItem",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalInterventionId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    Order = table.Column<int>(type: "integer", nullable: false),
                    ChecklistTemplateId = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaintenanceChecklistItem", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MaintenanceChecklistItem_TechnicalInterventions_TechnicalIn~",
                        column: x => x.TechnicalInterventionId,
                        principalTable: "TechnicalInterventions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TechnicalChecklistItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalInterventionId = table.Column<Guid>(type: "uuid", nullable: false),
                    Task = table.Column<string>(type: "text", nullable: false),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TechnicalChecklistItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TechnicalChecklistItems_TechnicalInterventions_TechnicalInt~",
                        column: x => x.TechnicalInterventionId,
                        principalTable: "TechnicalInterventions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TechnicalInvoices",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientId = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalInterventionId = table.Column<Guid>(type: "uuid", nullable: true),
                    TechnicalQuoteId = table.Column<Guid>(type: "uuid", nullable: true),
                    InvoiceNumber = table.Column<string>(type: "text", nullable: false),
                    InvoiceDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DueDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    WorkStartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    WorkEndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ServiceDescription = table.Column<string>(type: "text", nullable: false),
                    LocationOfWork = table.Column<string>(type: "text", nullable: false),
                    HourlyRate = table.Column<decimal>(type: "numeric", nullable: false),
                    ActualHours = table.Column<decimal>(type: "numeric", nullable: false),
                    MaterialsCost = table.Column<decimal>(type: "numeric", nullable: false),
                    AdvancePayment = table.Column<decimal>(type: "numeric", nullable: false),
                    OtherDeductions = table.Column<decimal>(type: "numeric", nullable: false),
                    TaxAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    Total = table.Column<decimal>(type: "numeric", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    PaidDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AmountPaid = table.Column<decimal>(type: "numeric", nullable: false),
                    PdfFilePath = table.Column<string>(type: "text", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TechnicalInvoices", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TechnicalInvoices_TechnicalInterventions_TechnicalIntervent~",
                        column: x => x.TechnicalInterventionId,
                        principalTable: "TechnicalInterventions",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TechnicalInvoices_TechnicalQuotes_TechnicalQuoteId",
                        column: x => x.TechnicalQuoteId,
                        principalTable: "TechnicalQuotes",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TechnicalInvoices_clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TechnicalInvoices_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TechnicalPaymentRecords",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalInvoiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric", nullable: false),
                    PaymentDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PaymentMethod = table.Column<string>(type: "text", nullable: false),
                    MobileMoneyOperator = table.Column<string>(type: "text", nullable: true),
                    MobileMoneyReference = table.Column<string>(type: "text", nullable: true),
                    PhoneNumber = table.Column<string>(type: "text", nullable: true),
                    SenderName = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false),
                    IsVerified = table.Column<bool>(type: "boolean", nullable: false),
                    VerificationDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TechnicalPaymentRecords", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TechnicalPaymentRecords_TechnicalInvoices_TechnicalInvoiceId",
                        column: x => x.TechnicalInvoiceId,
                        principalTable: "TechnicalInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TechnicalQuoteItem",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalQuoteId = table.Column<Guid>(type: "uuid", nullable: false),
                    ItemName = table.Column<string>(type: "text", nullable: false),
                    ItemType = table.Column<string>(type: "text", nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric", nullable: false),
                    UnitPrice = table.Column<decimal>(type: "numeric", nullable: false),
                    Unit = table.Column<string>(type: "text", nullable: false),
                    TechnicalInterventionId = table.Column<Guid>(type: "uuid", nullable: true),
                    TechnicalInvoiceId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TechnicalQuoteItem", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TechnicalQuoteItem_TechnicalInterventions_TechnicalInterven~",
                        column: x => x.TechnicalInterventionId,
                        principalTable: "TechnicalInterventions",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TechnicalQuoteItem_TechnicalInvoices_TechnicalInvoiceId",
                        column: x => x.TechnicalInvoiceId,
                        principalTable: "TechnicalInvoices",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_TechnicalQuoteItem_TechnicalQuotes_TechnicalQuoteId",
                        column: x => x.TechnicalQuoteId,
                        principalTable: "TechnicalQuotes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PaymentProofDocument",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TechnicalPaymentRecordId = table.Column<Guid>(type: "uuid", nullable: false),
                    DocumentName = table.Column<string>(type: "text", nullable: false),
                    DocumentType = table.Column<string>(type: "text", nullable: false),
                    FilePath = table.Column<string>(type: "text", nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    UploadDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentProofDocument", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PaymentProofDocument_TechnicalPaymentRecords_TechnicalPayme~",
                        column: x => x.TechnicalPaymentRecordId,
                        principalTable: "TechnicalPaymentRecords",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_FinanceAccounts_UserId",
                table: "FinanceAccounts",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_FinanceBudgets_FinanceAccountId",
                table: "FinanceBudgets",
                column: "FinanceAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_FinanceCategory_FinanceAccountId",
                table: "FinanceCategory",
                column: "FinanceAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_FinanceTransactions_FinanceAccountId",
                table: "FinanceTransactions",
                column: "FinanceAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_InvoiceDeliverable_LiberalInvoiceId",
                table: "InvoiceDeliverable",
                column: "LiberalInvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalContracts_ClientId",
                table: "LiberalContracts",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalContracts_UserId",
                table: "LiberalContracts",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalInvoices_ClientId",
                table: "LiberalInvoices",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalInvoices_ContractId",
                table: "LiberalInvoices",
                column: "ContractId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalInvoices_UserId",
                table: "LiberalInvoices",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalProjects_ClientId",
                table: "LiberalProjects",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_LiberalProjects_UserId",
                table: "LiberalProjects",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceChecklistItem_TechnicalInterventionId",
                table: "MaintenanceChecklistItem",
                column: "TechnicalInterventionId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenancePlans_ClientId",
                table: "MaintenancePlans",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenancePlans_UserId",
                table: "MaintenancePlans",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceTasks_MaintenancePlanId",
                table: "MaintenanceTasks",
                column: "MaintenancePlanId");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentProofDocument_TechnicalPaymentRecordId",
                table: "PaymentProofDocument",
                column: "TechnicalPaymentRecordId");

            migrationBuilder.CreateIndex(
                name: "IX_PaymentRecord_LiberalInvoiceId",
                table: "PaymentRecord",
                column: "LiberalInvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_PipelineEvents_ProspectContactId",
                table: "PipelineEvents",
                column: "ProspectContactId");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectDeliverables_LiberalProjectId",
                table: "ProjectDeliverables",
                column: "LiberalProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectDocument_LiberalProjectId",
                table: "ProjectDocument",
                column: "LiberalProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectTask_LiberalProjectId",
                table: "ProjectTask",
                column: "LiberalProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ProspectContacts_UserId",
                table: "ProspectContacts",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalChecklistItems_TechnicalInterventionId",
                table: "TechnicalChecklistItems",
                column: "TechnicalInterventionId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInterventions_ClientId",
                table: "TechnicalInterventions",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInterventions_TechnicalQuoteId",
                table: "TechnicalInterventions",
                column: "TechnicalQuoteId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInterventions_UserId",
                table: "TechnicalInterventions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInvoices_ClientId",
                table: "TechnicalInvoices",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInvoices_TechnicalInterventionId",
                table: "TechnicalInvoices",
                column: "TechnicalInterventionId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInvoices_TechnicalQuoteId",
                table: "TechnicalInvoices",
                column: "TechnicalQuoteId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalInvoices_UserId",
                table: "TechnicalInvoices",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalPaymentRecords_TechnicalInvoiceId",
                table: "TechnicalPaymentRecords",
                column: "TechnicalInvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalQuoteItem_TechnicalInterventionId",
                table: "TechnicalQuoteItem",
                column: "TechnicalInterventionId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalQuoteItem_TechnicalInvoiceId",
                table: "TechnicalQuoteItem",
                column: "TechnicalInvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalQuoteItem_TechnicalQuoteId",
                table: "TechnicalQuoteItem",
                column: "TechnicalQuoteId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalQuotes_ClientId",
                table: "TechnicalQuotes",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_TechnicalQuotes_UserId",
                table: "TechnicalQuotes",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "FinanceBudgets");

            migrationBuilder.DropTable(
                name: "FinanceCategory");

            migrationBuilder.DropTable(
                name: "FinanceTransactions");

            migrationBuilder.DropTable(
                name: "InvoiceDeliverable");

            migrationBuilder.DropTable(
                name: "MaintenanceChecklistItem");

            migrationBuilder.DropTable(
                name: "MaintenanceTasks");

            migrationBuilder.DropTable(
                name: "PaymentProofDocument");

            migrationBuilder.DropTable(
                name: "PaymentRecord");

            migrationBuilder.DropTable(
                name: "PipelineEvents");

            migrationBuilder.DropTable(
                name: "ProjectDeliverables");

            migrationBuilder.DropTable(
                name: "ProjectDocument");

            migrationBuilder.DropTable(
                name: "ProjectTask");

            migrationBuilder.DropTable(
                name: "TechnicalChecklistItems");

            migrationBuilder.DropTable(
                name: "TechnicalQuoteItem");

            migrationBuilder.DropTable(
                name: "FinanceAccounts");

            migrationBuilder.DropTable(
                name: "MaintenancePlans");

            migrationBuilder.DropTable(
                name: "TechnicalPaymentRecords");

            migrationBuilder.DropTable(
                name: "LiberalInvoices");

            migrationBuilder.DropTable(
                name: "ProspectContacts");

            migrationBuilder.DropTable(
                name: "LiberalProjects");

            migrationBuilder.DropTable(
                name: "TechnicalInvoices");

            migrationBuilder.DropTable(
                name: "LiberalContracts");

            migrationBuilder.DropTable(
                name: "TechnicalInterventions");

            migrationBuilder.DropTable(
                name: "TechnicalQuotes");
        }
    }
}
