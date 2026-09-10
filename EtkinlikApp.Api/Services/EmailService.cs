using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace EtkinlikApp.Api.Services;

// şifremi unuttum akışında sıfırlama kodunu kullanıcının mailine gönderen servis (Gmail SMTP + Uygulama Şifresi üzerinden)
public class EmailService
{
    private readonly IConfiguration _config;

    public EmailService(IConfiguration config)
    {
        _config = config;
    }

    public async Task SendPasswordResetCodeAsync(string toEmail, string code)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_config["Email:SenderName"], _config["Email:SenderEmail"]));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = "Huddle - Şifre Sıfırlama Kodu";

        message.Body = new TextPart("plain")
        {
            Text = $"Şifreni sıfırlamak için kodun: {code}\n\nBu kod 15 dakika geçerlidir. Bu isteği sen yapmadıysan bu maili görmezden gelebilirsin."
        };

        using var client = new SmtpClient();
        await client.ConnectAsync(_config["Email:SmtpHost"], int.Parse(_config["Email:SmtpPort"]!), SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(_config["Email:SenderEmail"], _config["Email:AppPassword"]);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}
