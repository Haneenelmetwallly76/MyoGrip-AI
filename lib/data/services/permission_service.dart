abstract interface class PermissionService {
  Future<bool> requestLocalNetworkPermission();
}

final class FakePermissionService implements PermissionService {
  const FakePermissionService({this.granted = true});

  final bool granted;

  @override
  Future<bool> requestLocalNetworkPermission() async => granted;
}
