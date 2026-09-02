using EtkinlikApp.Core.Enums;

namespace EtkinlikApp.Api.DTOs;

public class RegisterDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public Gender Gender { get; set; } = Gender.Unspecified;
    public DateTime BirthDate { get; set; } 
}

public class LoginDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class UpdateUsernameDto
{
    public string Username { get; set; } = string.Empty;
}