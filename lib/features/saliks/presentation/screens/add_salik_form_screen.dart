import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/form_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/localized_text.dart';
import '../../../../core/utils/icon_colors.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pakistan_phone_field.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
import '../../../../core/utils/pakistan_phone.dart';
import '../../../../core/widgets/salik_widgets.dart';
import '../../../../core/widgets/urdu_field.dart';
import '../../../auth/domain/user_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/segment_pill_bar.dart';
import '../../data/area_repository.dart';
import '../../data/salik_repository.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/salik.dart';
import '../providers/area_provider.dart';
import '../providers/salik_provider.dart';

class AddSalikFormScreen extends ConsumerStatefulWidget {
  const AddSalikFormScreen({this.salikId, super.key});

  final String? salikId;

  bool get isEditing => salikId != null;

  @override
  ConsumerState<AddSalikFormScreen> createState() => _AddSalikFormScreenState();
}

class _AddSalikFormScreenState extends ConsumerState<AddSalikFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialized = false;
  String _formLocale = 'en';
  bool _whatsappSameAsMobile = true;

  final _nameEng = TextEditingController();
  final _nameUrdu = TextEditingController();
  final _fatherEng = TextEditingController();
  final _fatherUrdu = TextEditingController();
  final _mobile = TextEditingController();
  final _whatsapp = TextEditingController();
  final _refName = TextEditingController();
  final _citySearch = TextEditingController();
  final _areaSearch = TextEditingController();

  String _cityId = '';
  String _areaId = '';
  String _gender = 'Male';
  String _dateBaith = DateTime.now().toIso8601String().split('T').first;
  String _createdDate = DateTime.now().toIso8601String().split('T').first;
  bool _nafiAsbat = false;
  bool _sahibMehfil = false;

  FormReturnRoute get _returnRoute => parseFormReturn(
        GoRouterState.of(context).uri.queryParameters['from'],
      );

  AppLocalizations get _fl10n => AppLocalizations(Locale(_formLocale));

  @override
  void initState() {
    super.initState();
    void refreshHeader() {
      if (mounted) setState(() {});
    }

    for (final controller in [
      _nameEng,
      _nameUrdu,
      _fatherEng,
      _fatherUrdu,
    ]) {
      controller.addListener(refreshHeader);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(syncServiceProvider).syncNow());
    });
  }

  @override
  void dispose() {
    _nameEng.dispose();
    _nameUrdu.dispose();
    _fatherEng.dispose();
    _fatherUrdu.dispose();
    _mobile.dispose();
    _whatsapp.dispose();
    _refName.dispose();
    _citySearch.dispose();
    _areaSearch.dispose();
    super.dispose();
  }

  void _populateFromSalik(Salik salik, List<City> cities, List<Area> areas) {
    _nameEng.text = salik.nameEnglish;
    _nameUrdu.text = salik.nameUrdu;
    _fatherEng.text = salik.fatherNameEnglish;
    _fatherUrdu.text = salik.fatherNameUrdu;
    _mobile.text = PakistanPhone.formatFromStored(salik.mobileNumber);
    _whatsapp.text = PakistanPhone.formatFromStored(salik.whatsappNumber);
    _refName.text = salik.referenceName;
    _cityId = salik.cityId;
    _areaId = salik.areaId;
    _gender = UserSession.normalizeGender(salik.genderId);
    _dateBaith = salik.dateOfBaith;
    _createdDate = salik.createdDate;
    _nafiAsbat = salik.isNafiAsbat;
    _sahibMehfil = salik.isSahibEMehfil;
    _whatsappSameAsMobile = SalikRepository.normalizePhone(salik.mobileNumber) ==
        SalikRepository.normalizePhone(salik.whatsappNumber);
    _syncLocationLabels(cities, areas);
  }

  void _syncLocationLabels(List<City> cities, List<Area> areas) {
    final city = cities.where((c) => c.cityId == _cityId).firstOrNull;
    if (city != null) {
      _citySearch.text = localizedCityName(
        cityName: city.cityName,
        cityNameUrdu: city.cityNameUrdu,
        preferUrdu: _formLocale == 'ur',
      );
    }
    final area = areas.where((a) => a.areaId == _areaId).firstOrNull;
    if (area != null) {
      _areaSearch.text = localizedAreaName(
        areaName: area.areaName,
        areaNameUrdu: area.areaNameUrdu,
        preferUrdu: _formLocale == 'ur',
      );
    }
  }

  bool _hasNameInOneLanguage() {
    if (_formLocale == 'en') {
      return _nameEng.text.trim().isNotEmpty &&
          _fatherEng.text.trim().isNotEmpty;
    }
    return _nameUrdu.text.trim().isNotEmpty &&
        _fatherUrdu.text.trim().isNotEmpty;
  }

  String _saveNameEnglish() =>
      _formLocale == 'en' ? _nameEng.text.trim() : '';

  String _saveNameUrdu() => _formLocale == 'ur' ? _nameUrdu.text.trim() : '';

  String _saveFatherEnglish() =>
      _formLocale == 'en' ? _fatherEng.text.trim() : '';

  String _saveFatherUrdu() =>
      _formLocale == 'ur' ? _fatherUrdu.text.trim() : '';

  bool _validateAll(AppLocalizations l10n) {
    if (!_hasNameInOneLanguage() ||
        FormValidators.phoneField(_mobile.text, l10n) != null ||
        _dateBaith.trim().isEmpty ||
        _cityId.isEmpty ||
        _areaId.isEmpty) {
      return false;
    }
    if (!_whatsappSameAsMobile &&
        FormValidators.optionalPhone(_whatsapp.text, l10n) != null) {
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAll(l10n)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('name_one_language_required'))),
      );
      return;
    }

    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    if (widget.isEditing && !AccessControl.canUpdate(session.role)) {
      _showNoAccess();
      return;
    }
    if (!widget.isEditing && !AccessControl.canCreate(session.role)) {
      _showNoAccess();
      return;
    }

    setState(() => _loading = true);
    final today = DateTime.now().toIso8601String().split('T').first;
    final effectiveGender = AccessControl.effectiveGender(session, _gender);
    final mobile = PakistanPhone.toStored(_mobile.text);
    final whatsapp = _whatsappSameAsMobile
        ? mobile
        : (_whatsapp.text.trim().isEmpty
            ? mobile
            : PakistanPhone.toStored(_whatsapp.text));

    final salik = Salik(
      salikId: widget.salikId ?? '',
      nameEnglish: _saveNameEnglish(),
      nameUrdu: _saveNameUrdu(),
      fatherNameEnglish: _saveFatherEnglish(),
      fatherNameUrdu: _saveFatherUrdu(),
      mobileNumber: mobile,
      whatsappNumber: whatsapp,
      cityId: _cityId,
      areaId: _areaId,
      genderId: effectiveGender,
      bazamId: '',
      khanqahId: '',
      salikCategoryId: '',
      dateOfBaith: _dateBaith,
      referenceName: _refName.text.trim(),
      referenceMobile: '',
      isNafiAsbat: _nafiAsbat,
      isSahibEMehfil: _sahibMehfil,
      nafiZikrId: '',
      profilePicture: '',
      createdDate: widget.isEditing ? _createdDate : today,
      modifiedDate: today,
      isActive: true,
    );

    try {
      final repo = ref.read(salikRepositoryProvider);
      if (widget.isEditing) {
        await repo.updateSalik(
          salik.copyWith(salikId: widget.salikId!),
          session: session,
        );
      } else {
        await repo.createSalik(salik, session: session);
      }
      if (mounted) {
        final isEditor = AccessControl.isEditor(session.role);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.t(
                widget.isEditing
                    ? 'update_success'
                    : isEditor
                        ? 'submit_for_approval'
                        : 'register_success',
              ),
            ),
          ),
        );
        exitSalikForm(
          GoRouter.of(context),
          from: _returnRoute,
          salikId: widget.salikId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapFirebaseError(e, l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showNoAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('no_access'))),
    );
  }

  void _handleBack() {
    exitSalikForm(
      GoRouter.of(context),
      from: _returnRoute,
      salikId: widget.salikId,
    );
  }

  Future<void> _pickOrCreateCity(List<City> cities) async {
    final fl10n = _fl10n;
    final isUrdu = _formLocale == 'ur';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: _citySearch.text);
        return AlertDialog(
          title: Text(fl10n.t('city')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: fl10n.t('search_placeholder'),
                ),
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView(
                  children: cities.map((city) {
                    final label =
                        isUrdu ? city.cityNameUrdu : city.cityName;
                    return ListTile(
                      title: Text(label),
                      onTap: () => Navigator.pop(ctx, 'pick:${city.cityId}'),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(fl10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'new:${controller.text.trim()}'),
              child: Text(fl10n.t('add_new_city')),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;

    if (result.startsWith('pick:')) {
      final id = result.substring(5);
      final city = cities.firstWhere((c) => c.cityId == id);
      setState(() {
        _cityId = id;
        _areaId = '';
        _areaSearch.clear();
        _citySearch.text = isUrdu ? city.cityNameUrdu : city.cityName;
      });
    } else if (result.startsWith('new:')) {
      final name = result.substring(4);
      if (name.isEmpty) return;
      setState(() => _loading = true);
      try {
        final repo = ref.read(areaRepositoryProvider);
        final city = await repo.createCity(
          nameEn: isUrdu ? '' : name,
          nameUr: isUrdu ? name : '',
        );
        if (mounted) {
          ref.invalidate(citiesProvider);
          ref.invalidate(areasByCityProvider(city.cityId));
          setState(() {
            _cityId = city.cityId;
            _areaId = '';
            _areaSearch.clear();
            _citySearch.text = isUrdu ? city.cityNameUrdu : city.cityName;
          });
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickOrCreateArea(List<Area> areas) async {
    if (_cityId.isEmpty) return;
    final fl10n = _fl10n;
    final isUrdu = _formLocale == 'ur';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: _areaSearch.text);
        return AlertDialog(
          title: Text(fl10n.t('area')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: fl10n.t('search_placeholder'),
                ),
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView(
                  children: areas.map((area) {
                    final label =
                        isUrdu ? area.areaNameUrdu : area.areaName;
                    return ListTile(
                      title: Text(label),
                      onTap: () => Navigator.pop(ctx, 'pick:${area.areaId}'),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(fl10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'new:${controller.text.trim()}'),
              child: Text(fl10n.t('add_new_area')),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;

    if (result.startsWith('pick:')) {
      final id = result.substring(5);
      final area = areas.firstWhere((a) => a.areaId == id);
      setState(() {
        _areaId = id;
        _areaSearch.text = isUrdu ? area.areaNameUrdu : area.areaName;
      });
    } else if (result.startsWith('new:')) {
      final name = result.substring(4);
      if (name.isEmpty) return;
      setState(() => _loading = true);
      try {
        final repo = ref.read(areaRepositoryProvider);
        final area = await repo.createArea(
          cityId: _cityId,
          nameEn: isUrdu ? '' : name,
          nameUr: isUrdu ? name : '',
        );
        if (mounted) {
          ref.invalidate(areasByCityProvider(_cityId));
          setState(() {
            _areaId = area.areaId;
            _areaSearch.text = isUrdu ? area.areaNameUrdu : area.areaName;
          });
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  String _headerDisplayName(AppLocalizations fl10n) {
    if (_formLocale == 'ur') {
      final urdu = _nameUrdu.text.trim();
      if (urdu.isNotEmpty) return urdu;
      final english = _nameEng.text.trim();
      if (english.isNotEmpty) return english;
    } else {
      final english = _nameEng.text.trim();
      if (english.isNotEmpty) return english;
      final urdu = _nameUrdu.text.trim();
      if (urdu.isNotEmpty) return urdu;
    }
    return widget.isEditing ? fl10n.t('edit_salik') : fl10n.t('add_salik');
  }

  String _headerDisplayFather() {
    if (_formLocale == 'ur') {
      final urdu = _fatherUrdu.text.trim();
      if (urdu.isNotEmpty) return urdu;
      return _fatherEng.text.trim();
    }
    final english = _fatherEng.text.trim();
    if (english.isNotEmpty) return english;
    return _fatherUrdu.text.trim();
  }

  Widget _buildGenderField(AppLocalizations fl10n, bool canPickGender) {
    if (canPickGender) {
      return DropdownButtonFormField<String>(
        initialValue: _gender,
        decoration: InputDecoration(
          labelText: fl10n.t('gender'),
          prefixIcon: IconColors.icon(Icons.wc, size: 22, colorIndex: 1),
        ),
        items: [
          DropdownMenuItem(value: 'Male', child: Text(fl10n.t('male'))),
          DropdownMenuItem(value: 'Female', child: Text(fl10n.t('female'))),
        ],
        validator: (v) => FormValidators.selectRequired(v, fl10n),
        onChanged: (v) {
          if (v != null) setState(() => _gender = v);
        },
      );
    }

    final label = _gender == 'Female' ? fl10n.t('female') : fl10n.t('male');

    return InputDecorator(
      decoration: InputDecoration(
        labelText: fl10n.t('gender'),
        prefixIcon: IconColors.icon(Icons.wc, size: 22, colorIndex: 1),
        suffixIcon: IconColors.icon(Icons.lock_outline, size: 20, colorIndex: 0),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Chip(
          label: Text(label),
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(currentSessionProvider);
    final citiesAsync = ref.watch(citiesProvider);
    final cities = citiesAsync.valueOrNull ?? [];
    final areasAsync = _cityId.isEmpty
        ? const AsyncValue<List<Area>>.data([])
        : ref.watch(areasByCityProvider(_cityId));
    final areas = areasAsync.valueOrNull ?? [];

    if (!_initialized && cities.isNotEmpty && _cityId.isEmpty) {
      _cityId = cities.first.cityId;
      _syncLocationLabels(cities, areas);
    }

    if (widget.isEditing && widget.salikId != null && !_initialized) {
      final salikAsync = ref.watch(salikByIdProvider(widget.salikId!));
      salikAsync.whenData((salik) {
        if (salik != null && !_initialized) {
          _populateFromSalik(salik, cities, areas);
          _initialized = true;
        }
      });
    } else if (!_initialized && session != null) {
      _gender = UserSession.normalizeGender(session.gender);
      _formLocale = l10n.isUrdu ? 'ur' : 'en';
      _initialized = true;
    }

    if (session != null &&
        !widget.isEditing &&
        !AccessControl.canCreate(session.role)) {
      return AppScaffold(
        title: l10n.t('add_salik'),
        showBackButton: true,
        onBack: _handleBack,
        body: Center(child: Text(l10n.t('no_access'))),
      );
    }

    final canPickGender =
        session != null && AccessControl.canSetGender(session);
    final fl10n = _fl10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AppScaffold(
        title: widget.isEditing ? fl10n.t('edit_salik') : fl10n.t('add_salik'),
        showBackButton: true,
        onBack: _handleBack,
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: SegmentPillBar(
                  labels: const ['English', 'اردو'],
                  selectedIndex: _formLocale == 'ur' ? 1 : 0,
                  onSelected: (i) {
                    setState(() {
                      _formLocale = i == 1 ? 'ur' : 'en';
                      _syncLocationLabels(cities, areas);
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  fl10n.t('name_one_language_hint'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileHeader(
                        name: _headerDisplayName(fl10n),
                        subtitle:
                            '${l10n.t('father_name')}: ${_headerDisplayFather()}',
                        badge: _sahibMehfil
                            ? Chip(
                                label: Text(l10n.t('sahib_e_mehfil')),
                                backgroundColor: Colors.amber.shade50,
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      InfoGroupCard(
                        title: l10n.t('step_personal'),
                        children: [
                          if (_formLocale == 'en') ...[
                            TextFormField(
                              controller: _nameEng,
                              decoration: InputDecoration(
                                labelText: fl10n.t('name_english'),
                                prefixIcon: IconColors.icon(
                                  Icons.person_outline,
                                  size: 22,
                                  colorIndex: 0,
                                ),
                              ),
                              validator: (v) =>
                                  FormValidators.requiredField(v, fl10n),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _fatherEng,
                              decoration: InputDecoration(
                                labelText: fl10n.t('father_english'),
                                prefixIcon: IconColors.icon(
                                  Icons.person_outline,
                                  size: 22,
                                  colorIndex: 1,
                                ),
                              ),
                              validator: (v) =>
                                  FormValidators.requiredField(v, fl10n),
                            ),
                          ] else ...[
                            UrduField(
                              controller: _nameUrdu,
                              label: fl10n.t('name_urdu'),
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  FormValidators.requiredField(v, fl10n),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            UrduField(
                              controller: _fatherUrdu,
                              label: fl10n.t('father_urdu'),
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  FormValidators.requiredField(v, fl10n),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          FormField<String>(
                            initialValue: _dateBaith,
                            validator: (v) => v == null || v.isEmpty
                                ? fl10n.t('required_field')
                                : null,
                            builder: (field) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: IconColors.icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      colorIndex: 0,
                                    ),
                                    title: Text(fl10n.t('date_of_baith')),
                                    subtitle: Text(_dateBaith),
                                    trailing: IconColors.icon(
                                      Icons.chevron_right,
                                      size: 18,
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            DateTime.tryParse(_dateBaith) ??
                                                DateTime.now(),
                                        firstDate: DateTime(1990),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _dateBaith = picked
                                              .toIso8601String()
                                              .split('T')
                                              .first;
                                        });
                                        field.didChange(_dateBaith);
                                      }
                                    },
                                  ),
                                  if (field.hasError)
                                    Text(
                                      field.errorText!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildGenderField(fl10n, canPickGender),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _refName,
                            decoration: InputDecoration(
                              labelText: fl10n.t('reference'),
                              prefixIcon: IconColors.icon(
                                Icons.person_outline,
                                size: 22,
                                colorIndex: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InfoGroupCard(
                        title: l10n.t('contact_info'),
                        children: [
                          PakistanPhoneFormField(
                            controller: _mobile,
                            labelText: fl10n.t('mobile'),
                            prefixIcon: Icons.phone,
                            colorIndex: 0,
                            validator: (v) =>
                                FormValidators.phoneField(v, fl10n),
                            onChanged: (_) => setState(() {}),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(fl10n.t('same_as_mobile')),
                            subtitle: Text(
                              _whatsappSameAsMobile
                                  ? (_mobile.text.trim().isNotEmpty
                                      ? fl10n
                                          .t('whatsapp_same_preview')
                                          .replaceAll(
                                            '{number}',
                                            _mobile.text.trim(),
                                          )
                                      : fl10n.t('whatsapp_same_hint'))
                                  : fl10n.t('whatsapp_different_hint'),
                              style: TextStyle(
                                fontSize: 13,
                                color: _whatsappSameAsMobile
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade600,
                              ),
                            ),
                            value: _whatsappSameAsMobile,
                            onChanged: (v) =>
                                setState(() => _whatsappSameAsMobile = v),
                          ),
                          if (!_whatsappSameAsMobile) ...[
                            const SizedBox(height: AppSpacing.sm),
                            PakistanPhoneFormField(
                              controller: _whatsapp,
                              labelText: fl10n.t('whatsapp'),
                              prefix: const WhatsAppMessageIcon(size: 22),
                              validator: (v) =>
                                  FormValidators.optionalPhone(v, fl10n),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      InfoGroupCard(
                        title: l10n.t('location_info'),
                        children: [
                          TextFormField(
                            controller: _citySearch,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: fl10n.t('city'),
                              prefixIcon: IconColors.icon(
                                Icons.location_city,
                                size: 22,
                                colorIndex: 0,
                              ),
                              suffixIcon: IconColors.icon(Icons.arrow_drop_down, size: 22),
                            ),
                            validator: (_) => _cityId.isEmpty
                                ? fl10n.t('error_select_required')
                                : null,
                            onTap: () => _pickOrCreateCity(cities),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _areaSearch,
                            readOnly: true,
                            enabled: _cityId.isNotEmpty,
                            decoration: InputDecoration(
                              labelText: fl10n.t('area'),
                              prefixIcon: IconColors.icon(
                                Icons.map,
                                size: 22,
                                colorIndex: 1,
                              ),
                              suffixIcon: IconColors.icon(Icons.arrow_drop_down, size: 22),
                            ),
                            validator: (_) => _areaId.isEmpty
                                ? fl10n.t('error_select_required')
                                : null,
                            onTap: _cityId.isEmpty
                                ? null
                                : () => _pickOrCreateArea(areas),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        title: Text(l10n.t('nafi_asbat')),
                        value: _nafiAsbat,
                        onChanged: (v) => setState(() => _nafiAsbat = v),
                      ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        title: Text(l10n.t('sahib_e_mehfil')),
                        value: _sahibMehfil,
                        onChanged: (v) => setState(() => _sahibMehfil = v),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const AppLoader(
                            size: AppLoaderSize.small,
                            color: Colors.white,
                          )
                        : Text(fl10n.t('submit')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
