using SalesFlow.Application.Common.Models;

namespace SalesFlow.Application.Documents.Services;

public interface IDocumentGenerator
{
    /// <summary>
    /// Génère un PDF de devis ou facture pour un SalesOrder.
    /// Le statut du document détermine le titre (Devis / Bon de commande / Facture).
    /// </summary>
    /// <returns>Bytes du PDF + nom de fichier suggéré.</returns>
    Task<Result<GeneratedDocument>> GenerateSalesOrderPdfAsync(Guid salesOrderId, CancellationToken ct = default);
}

public record GeneratedDocument(byte[] Bytes, string FileName, string ContentType = "application/pdf");
