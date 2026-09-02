using EtkinlikApp.Api.DTOs;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly AppDbContext _context;
    public CategoriesController(AppDbContext context)
    {
        _context = context;
    }

    //get api/categories
    [HttpGet]
    public async Task<IActionResult> GetCategories()
    {
        var categories = await _context.Categories
             .OrderBy(c => c.Name)
             .Select(c => new CategoryDto
             {
                 Id = c.Id,
                 Name = c.Name,
                 Icon = c.Icon
             })
             .ToListAsync();
        
        return Ok(categories);
    }
}