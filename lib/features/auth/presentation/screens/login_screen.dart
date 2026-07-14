import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/local_auth_store.dart';
import '../../../../core/auth/staff_email.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/env_badge.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final email =
          await ref.read(localAuthStoreProvider).getRememberedEmail();
      if (email != null && email.isNotEmpty && mounted) {
        _emailController.text = localPartFromStaffEmail(email);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loginError = null);
    await ref.read(authControllerProvider.notifier).signIn(
          composeStaffEmail(_emailController.text),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 360 || size.height < 640;
    final outerPadding = isCompact ? AppSpacing.md : AppSpacing.lg;
    final cardPadding = isCompact ? AppSpacing.md : AppSpacing.lg;
    final logoSize = isCompact ? 52.0 : 64.0;
    final titleSize = isCompact ? 20.0 : 22.0;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError) {
        setState(() {
          _loginError = mapFirebaseError(next.error!, l10n);
        });
      } else if (prev?.isLoading == true && next.hasValue) {
        setState(() => _loginError = null);
        final seedKey = ref.read(seedMessageProvider);
        if (seedKey != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t(seedKey))),
          );
          ref.read(seedMessageProvider.notifier).state = null;
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BrandedBackground(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    outerPadding,
                    outerPadding + MediaQuery.paddingOf(context).top,
                    outerPadding,
                    outerPadding + viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          viewInsets.bottom -
                          MediaQuery.paddingOf(context).top,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: size.width >= 600 ? 420 : double.infinity,
                        ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Align(
                                  alignment: Alignment.center,
                                  child: EnvBadge(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppLogo(size: logoSize),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  l10n.t('title'),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.forLocale(
                                    false,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.t('login_subtitle'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          labelText: l10n.t('email'),
                                          hintText: loginEmailHint(),
                                          suffixText: AppConfig.staffEmailDomain,
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                          ),
                                        ),
                                        keyboardType: TextInputType.text,
                                        autocorrect: false,
                                        validator: (v) =>
                                            staffEmailLocalPartValidator(
                                          v,
                                          l10n,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          labelText: l10n.t('password'),
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscure
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscure = !_obscure,
                                            ),
                                          ),
                                        ),
                                        obscureText: _obscure,
                                        validator: (v) =>
                                            FormValidators.requiredField(
                                          v,
                                          l10n,
                                        ),
                                      ),
                                      if (_loginError != null) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          _loginError!,
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.lg),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(
                                            double.infinity,
                                            48,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: authState.isLoading
                                            ? null
                                            : _submit,
                                        child: authState.isLoading
                                            ? const AppLoader(
                                                size: AppLoaderSize.small,
                                                color: Colors.white,
                                              )
                                            : Text(
                                                l10n.t('login'),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    );
  }
}
