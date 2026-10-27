using Microsoft.EntityFrameworkCore;
using MyoGrip.Api.Models;

namespace MyoGrip.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Clinic> Clinics => Set<Clinic>();
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<ProstheticSettings> Settings => Set<ProstheticSettings>();
    public DbSet<SyncBatch> SyncBatches => Set<SyncBatch>();
    public DbSet<LogEntry> LogEntries => Set<LogEntry>();
    public DbSet<Report> Reports => Set<Report>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder b)
    {

        b.Entity<Clinic>().HasIndex(c => c.Code).IsUnique();
        b.Entity<AppUser>().HasIndex(u => u.Email).IsUnique();
        b.Entity<ProstheticSettings>().HasIndex(s => s.UserId).IsUnique();
        b.Entity<SyncBatch>().HasIndex(s => new { s.UserId, s.BatchId }).IsUnique();
        b.Entity<Report>().HasIndex(r => new { r.ClinicId, r.CreatedAt });
        b.Entity<AuditLog>().HasIndex(a => a.ClinicianId);
    }
}
