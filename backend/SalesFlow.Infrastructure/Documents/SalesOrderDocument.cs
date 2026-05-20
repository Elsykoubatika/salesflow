using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Infrastructure.Documents;

/// <summary>
/// Layout QuestPDF pour un devis/facture SalesFlow.
/// Le titre et les zones affichées varient selon le Status du document.
/// </summary>
public class SalesOrderDocument : IDocument
{
    private readonly SalesOrder _order;
    private readonly User _merchant;
    private readonly Client _client;

    private static readonly string AccentColor = "#0F6E56";   // Teal 700 - cohérent avec UI
    private static readonly string MutedColor = "#6B6B68";
    private static readonly string LightBg = "#F5F5F2";

    public SalesOrderDocument(SalesOrder order, User merchant, Client client)
    {
        _order = order;
        _merchant = merchant;
        _client = client;
    }

    public DocumentMetadata GetMetadata() => new()
    {
        Title = $"{GetDocumentLabel()} {_order.OrderNumber}",
        Author = _merchant.FullName,
        Subject = $"Document pour {_client.FullName}"
    };

    public DocumentSettings GetSettings() => DocumentSettings.Default;

    public void Compose(IDocumentContainer container)
    {
        container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.Margin(40);
            page.DefaultTextStyle(t => t.FontSize(10).FontFamily(Fonts.Arial));

            page.Header().Element(ComposeHeader);
            page.Content().PaddingVertical(20).Element(ComposeContent);
            page.Footer().Element(ComposeFooter);
        });
    }

    // ─── Header : bandeau marchand + n° document ─────────────────────────────

    private void ComposeHeader(IContainer container)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text(_merchant.FullName).FontSize(16).Bold().FontColor(AccentColor);
                if (!string.IsNullOrWhiteSpace(_merchant.PhoneNumber))
                    col.Item().Text(_merchant.PhoneNumber).FontColor(MutedColor);
                col.Item().Text(_merchant.Email).FontColor(MutedColor);
                col.Item().Text("République du Congo").FontColor(MutedColor).FontSize(9);
            });

            row.ConstantItem(200).AlignRight().Column(col =>
            {
                col.Item().Text(GetDocumentLabel()).FontSize(20).Bold();
                col.Item().Text($"N° {_order.OrderNumber}").FontColor(MutedColor);
                col.Item().PaddingTop(6).Text($"Émis le {_order.CreatedAt:dd/MM/yyyy}").FontColor(MutedColor).FontSize(9);
                if (_order.ExpiresAt.HasValue && _order.Status == SalesOrderStatus.Draft || _order.Status == SalesOrderStatus.Sent)
                    col.Item().Text($"Valable jusqu'au {_order.ExpiresAt:dd/MM/yyyy}").FontColor(MutedColor).FontSize(9);
            });
        });
    }

    // ─── Content : client + lignes + totaux + notes ──────────────────────────

    private void ComposeContent(IContainer container)
    {
        container.Column(col =>
        {
            // Bloc client
            col.Item().Background(LightBg).Padding(12).Column(c =>
            {
                c.Item().Text("CLIENT").FontSize(8).FontColor(MutedColor).Bold().LetterSpacing(0.5f);
                c.Item().PaddingTop(4).Text(_client.FullName).Bold().FontSize(12);
                if (!string.IsNullOrWhiteSpace(_client.PhoneNumber))
                    c.Item().Text(_client.PhoneNumber!).FontColor(MutedColor);
                if (!string.IsNullOrWhiteSpace(_client.Email))
                    c.Item().Text(_client.Email!).FontColor(MutedColor);
                if (!string.IsNullOrWhiteSpace(_client.Address))
                    c.Item().Text(_client.Address!).FontColor(MutedColor);
                if (!string.IsNullOrWhiteSpace(_client.Region))
                    c.Item().Text(_client.Region!).FontColor(MutedColor);
            });

            // Tableau des lignes
            col.Item().PaddingTop(20).Element(ComposeItemsTable);

            // Totaux à droite
            col.Item().PaddingTop(10).AlignRight().Element(ComposeTotals);

            // Notes
            if (!string.IsNullOrWhiteSpace(_order.Notes))
            {
                col.Item().PaddingTop(20).Column(c =>
                {
                    c.Item().Text("NOTES").FontSize(8).FontColor(MutedColor).Bold().LetterSpacing(0.5f);
                    c.Item().PaddingTop(4).Text(_order.Notes!);
                });
            }

            // Mention statut si applicable
            if (_order.Status == SalesOrderStatus.Paid)
            {
                col.Item().PaddingTop(20).AlignCenter().Background("#E1F5EE").Padding(10)
                    .Text("✓ PAYÉ").FontSize(14).Bold().FontColor(AccentColor);
            }
            else if (_order.Status == SalesOrderStatus.Cancelled || _order.Status == SalesOrderStatus.Rejected)
            {
                col.Item().PaddingTop(20).AlignCenter().Background("#FCEBEB").Padding(10)
                    .Text(_order.Status == SalesOrderStatus.Cancelled ? "ANNULÉ" : "REFUSÉ")
                    .FontSize(14).Bold().FontColor("#A32D2D");
            }
        });
    }

    private void ComposeItemsTable(IContainer container)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(c =>
            {
                c.RelativeColumn(5);   // Description
                c.RelativeColumn(1.2f); // Quantité
                c.RelativeColumn(1.8f); // Prix unitaire
                c.RelativeColumn(2);   // Total ligne
            });

            // En-têtes
            table.Header(h =>
            {
                h.Cell().BorderBottom(1).BorderColor(AccentColor).PaddingVertical(6)
                    .Text("Désignation").Bold();
                h.Cell().BorderBottom(1).BorderColor(AccentColor).PaddingVertical(6).AlignRight()
                    .Text("Quantité").Bold();
                h.Cell().BorderBottom(1).BorderColor(AccentColor).PaddingVertical(6).AlignRight()
                    .Text("Prix unit.").Bold();
                h.Cell().BorderBottom(1).BorderColor(AccentColor).PaddingVertical(6).AlignRight()
                    .Text("Total").Bold();
            });

            foreach (var item in _order.Items)
            {
                table.Cell().BorderBottom(0.5f).BorderColor("#E0E0DC").PaddingVertical(6).Column(c =>
                {
                    c.Item().Text(item.Description);
                    if (!string.IsNullOrWhiteSpace(item.Notes))
                        c.Item().Text(item.Notes!).FontSize(8).FontColor(MutedColor).Italic();
                });
                table.Cell().BorderBottom(0.5f).BorderColor("#E0E0DC").PaddingVertical(6).AlignRight()
                    .Text(FormatQuantity(item.Quantity));
                table.Cell().BorderBottom(0.5f).BorderColor("#E0E0DC").PaddingVertical(6).AlignRight()
                    .Text(FormatMoney(item.UnitPrice, _order.Currency));
                table.Cell().BorderBottom(0.5f).BorderColor("#E0E0DC").PaddingVertical(6).AlignRight()
                    .Text(FormatMoney(item.LineTotal, _order.Currency)).Bold();
            }
        });
    }

    private void ComposeTotals(IContainer container)
    {
        container.Width(220).Column(col =>
        {
            col.Item().Row(r =>
            {
                r.RelativeItem().Text("Sous-total");
                r.ConstantItem(110).AlignRight().Text(FormatMoney(_order.Subtotal, _order.Currency));
            });

            if (_order.TaxAmount > 0)
            {
                col.Item().PaddingTop(2).Row(r =>
                {
                    r.RelativeItem().Text("TVA");
                    r.ConstantItem(110).AlignRight().Text(FormatMoney(_order.TaxAmount, _order.Currency));
                });
            }

            col.Item().PaddingTop(8).BorderTop(1).BorderColor(AccentColor).PaddingTop(6).Row(r =>
            {
                r.RelativeItem().Text("TOTAL").Bold().FontSize(12);
                r.ConstantItem(110).AlignRight()
                    .Text(FormatMoney(_order.Total, _order.Currency)).Bold().FontSize(13).FontColor(AccentColor);
            });
        });
    }

    // ─── Footer : Mobile Money + numéro de page ──────────────────────────────

    private void ComposeFooter(IContainer container)
    {
        container.Column(col =>
        {
            // Coordonnées de paiement (uniquement sur factures)
            if (_order.Status == SalesOrderStatus.Delivered || _order.Status == SalesOrderStatus.Accepted)
            {
                col.Item().PaddingBottom(8).Text("MODES DE PAIEMENT").FontSize(8).FontColor(MutedColor).Bold().LetterSpacing(0.5f);
                col.Item().Row(r =>
                {
                    r.RelativeItem().Text(t =>
                    {
                        t.Span("MTN MoMo : ").FontSize(9).Bold();
                        t.Span(_merchant.PhoneNumber ?? "—").FontSize(9);
                    });
                    r.RelativeItem().Text(t =>
                    {
                        t.Span("Airtel Money : ").FontSize(9).Bold();  
                        t.Span(_merchant.PhoneNumber ?? "—").FontSize(9);
                    });
                });
                col.Item().PaddingTop(8);
            }

            col.Item().BorderTop(0.5f).BorderColor("#D0D0CC").PaddingTop(6).Row(r =>
            {
                r.RelativeItem().Text("Document généré par SalesFlow Pro Congo").FontSize(8).FontColor(MutedColor);
                r.ConstantItem(100).AlignRight().Text(t =>
                {
                    t.DefaultTextStyle(s => s.FontSize(8).FontColor(MutedColor));
                    t.Span("Page ");
                    t.CurrentPageNumber();
                    t.Span(" / ");
                    t.TotalPages();
                });
            });
        });
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private string GetDocumentLabel() => _order.Status switch
    {
        SalesOrderStatus.Draft     => "DEVIS",
        SalesOrderStatus.Sent      => "DEVIS",
        SalesOrderStatus.Accepted  => "BON DE COMMANDE",
        SalesOrderStatus.Delivered => "FACTURE",
        SalesOrderStatus.Paid      => "FACTURE ACQUITTÉE",
        SalesOrderStatus.Rejected  => "DEVIS REFUSÉ",
        SalesOrderStatus.Cancelled => "DOCUMENT ANNULÉ",
        _                          => "DOCUMENT"
    };

    private static string FormatMoney(decimal amount, string currency)
    {
        // Format congolais : "25 000 XAF" (espace comme séparateur de milliers)
        var formatted = amount.ToString("N0", System.Globalization.CultureInfo.InvariantCulture).Replace(",", " ");
        return $"{formatted} {currency}";
    }

    private static string FormatQuantity(decimal quantity)
    {
        // Affiche sans décimales si entier, sinon avec
        return quantity == Math.Truncate(quantity)
            ? quantity.ToString("0")
            : quantity.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture);
    }
}
