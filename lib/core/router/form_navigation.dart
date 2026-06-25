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

String addSalikRoute({FormReturnRoute from = FormReturnRoute.saliks}) =>
    '/saliks/add?from=${from.name}';

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
