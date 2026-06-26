import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/saliks/domain/entities/duplicate_salik_reason.dart';
import '../../features/saliks/data/salik_repository.dart';
import '../auth/local_auth_store.dart';
import '../localization/app_localizations.dart';

String mapFirebaseError(Object error, AppLocalizations l10n) {
  if (error is SalikPermissionException) {
    return error.message;
  }
  if (error is DuplicateSalikException) {
    switch (error.reason) {
      case DuplicateSalikReason.mobile:
        return l10n.t('duplicate_mobile');
      case DuplicateSalikReason.nameEnglish:
      case DuplicateSalikReason.nameUrdu:
        return l10n.t('duplicate_person');
    }
  }
  if (error is ProfileNotFoundException) {
    return l10n.t('error_no_profile');
  }
  if (error is OfflineWrongPasswordException) {
    return l10n.t('offline_wrong_password');
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.t('error_wrong_password');
      case 'user-not-found':
        return l10n.t('error_user_not_found');
      case 'network-request-failed':
        return l10n.t('error_network');
      default:
        return error.message ?? l10n.t('error_generic');
    }
  }
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return l10n.t('error_permission_denied');
    }
    return error.message ?? l10n.t('error_generic');
  }
  final text = error.toString();
  if (text.contains('permission-denied') ||
      text.contains('PERMISSION_DENIED')) {
    return l10n.t('error_permission_denied');
  }
  return l10n.t('error_generic');
}
