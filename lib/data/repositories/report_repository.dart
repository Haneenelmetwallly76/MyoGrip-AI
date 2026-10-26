abstract interface class ReportRepository {
  Future<void> sendReport({required String clinicianName});
}

final class FakeReportRepository implements ReportRepository {
  FakeReportRepository({
    this.latency = const Duration(milliseconds: 400),
    this.forceFailure = false,
  });

  final Duration latency;
  bool forceFailure;

  @override
  Future<void> sendReport({required String clinicianName}) async {
    await Future<void>.delayed(latency);
    if (forceFailure) throw StateError('Could not send report');
  }
}
