using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Documents.Services;

namespace SalesFlow.Infrastructure.Documents;

public class PdfDocumentGenerator : IDocumentGenerator
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public PdfDocumentGenerator(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<GeneratedDocument>> GenerateSalesOrderPdfAsync(Guid salesOrderId, CancellationToken ct = default)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        // Charger commande + marchand + client + lignes en une requête
        var order = await _db.SalesOrders
            .AsNoTracking()
            .Include(o => o.Items)
            .Include(o => o.Client)
            .Include(o => o.User)
            .FirstOrDefaultAsync(o => o.Id == salesOrderId && o.UserId == userId, ct);

        if (order is null)
            return Result<GeneratedDocument>.Failure("Devis/commande introuvable.");

        if (order.User is null || order.Client is null)
            return Result<GeneratedDocument>.Failure("Données incomplètes — impossible de générer le document.");

        // Tri des items pour rendu cohérent (par ordre de création)
        order.Items = order.Items.OrderBy(i => i.CreatedAt).ToList();

        var document = new SalesOrderDocument(order, order.User, order.Client);
        var bytes = document.GeneratePdf();

        var fileName = $"{order.OrderNumber}.pdf";
        return Result<GeneratedDocument>.Success(new GeneratedDocument(bytes, fileName));
    }
}
