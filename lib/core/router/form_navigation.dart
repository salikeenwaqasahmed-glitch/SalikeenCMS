import 'package:go_router/go_router.dart';

enum FormReturnRoute { dashboard, saliks, profile }

FormReturnRoute parseFormReturn(String? from) {
  switch (from) {
    case 'dashboard':
      return FormReturnRoute.dashboard;
    case 'profile':
      return FormReturnRoute.profile;
    default:
      return FormReturnRoute.saliks;
  }
}

String addSalikRoute({
  FormReturnRoute from = FormReturnRoute.saliks,
  String? name,
  String? mobile,
}) {
  final params = <String, String>{'from': from.name};
  final trimmedName = name?.trim() ?? '';
  final trimmedMobile = mobile?.trim() ?? '';
  if (trimmedName.isNotEmpty) params['name'] = trimmedName;
  if (trimmedMobile.isNotEmpty) params['mobile'] = trimmedMobile;
  final query = params.entries
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return '/saliks/add?$query';
}

String editSalikRoute(String id, {FormReturnRoute from = FormReturnRoute.saliks}) =>
    '/saliks/edit/$id?from=${from.name}';

void exitSalikForm(GoRouter router, {required FormReturnRoute from, String? salikId}) {
  switch (from) {
    case FormReturnRoute.dashboard:
      router.go('/');
    case FormReturnRoute.profile:
      if (salikId != null && salikId.isNotEmpty) {
        router.go('/saliks/profile/$salikId');
      } else {
        router.go('/saliks');
      }
    case FormReturnRoute.saliks:
      router.go('/saliks');
  }
}
