import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/country_codes.dart';
import '../../../../core/data/reference_data.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/form_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/access_control.dart';
import '../../../../core/utils/firebase_errors.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/utils/icon_colors.dart';
import '../../../../core/utils/phone_number_utils.dart';
import '../../../../core/utils/pakistan_phone.dart';
import '../../../../core/utils/text_field_merge.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pakistan_phone_field.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
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

  final _name = TextEditingController();
  final _fatherName = TextEditingController();
  final _mobile = TextEditingController();
  final _whatsapp = TextEditingController();
  CountryDialCode _mobileCountry = kDefaultCountry;
  CountryDialCode _whatsappCountry = kDefaultCountry;
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

  bool get _isUrduForm => _formLocale == 'ur';

  String _localeLabel(String value) {
    final parts = value
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    return _isUrduForm ? parts.last : parts.first;
  }

  void _detectFormLocale(String name, String fatherName) {
    final sample = name.trim().isNotEmpty ? name.trim() : fatherName.trim();
    if (sample.isEmpty) {
      _formLocale = 'en';
      return;
    }
    _formLocale = containsUrduScript(sample) &&
            !RegExp(r'[A-Za-z]').hasMatch(sample)
        ? 'ur'
        : 'en';
  }

  @override
  void initState() {
    super.initState();
    void refreshHeader() {
      if (mounted) setState(() {});
    }

    for (final controller in [_name, _fatherName]) {
      controller.addListener(refreshHeader);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(syncServiceProvider).syncNow());
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _fatherName.dispose();
    _mobile.dispose();
    _whatsapp.dispose();
    _refName.dispose();
    _citySearch.dispose();
    _areaSearch.dispose();
    super.dispose();
  }

  Future<void> _populateFromSalik(
    Salik salik,
    List<City> cities,
    List<Area> areas,
  ) async {
    _name.text = salik.name;
    _fatherName.text = salik.fatherName;
    _detectFormLocale(salik.name, salik.fatherName);
    final mobileParsed = PhoneNumberUtils.parseStored(salik.mobileNumber);
    final whatsappParsed = PhoneNumberUtils.parseStored(salik.whatsappNumber);
    _mobileCountry = mobileParsed.country;
    _whatsappCountry = whatsappParsed.country;
    _mobile.text = PhoneNumberUtils.formatNationalDisplay(
      mobileParsed.country,
      mobileParsed.nationalDigits,
    );
    _whatsapp.text = PhoneNumberUtils.formatNationalDisplay(
      whatsappParsed.country,
      whatsappParsed.nationalDigits,
    );
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
    await _syncLocationLabels(cities, areas);
  }

  Future<void> _syncLocationLabels(List<City> cities, List<Area> areas) async {
    final repo = ref.read(areaRepositoryProvider);
    final city =
        findCityInList(_cityId, cities) ?? await repo.resolveCity(_cityId);
    if (city != null) {
      _citySearch.text = _localeLabel(city.cityName);
    }
    final area =
        findAreaInList(_areaId, areas) ?? await repo.resolveArea(_areaId);
    if (area != null) {
      _areaSearch.text = _localeLabel(area.areaName);
    }
  }

  bool _hasRequiredNames() {
    return _name.text.trim().isNotEmpty && _fatherName.text.trim().isNotEmpty;
  }

  bool _validateAll(AppLocalizations l10n) {
    if (!_hasRequiredNames() ||
        FormValidators.phoneField(
              _mobile.text,
              l10n,
              country: _mobileCountry,
            ) !=
            null ||
        _dateBaith.trim().isEmpty ||
        _cityId.isEmpty ||
        _areaId.isEmpty) {
      return false;
    }
    if (!_whatsappSameAsMobile &&
        FormValidators.optionalPhone(
              _whatsapp.text,
              l10n,
              country: _whatsappCountry,
            ) !=
            null) {
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
    final mobile = PhoneNumberUtils.toStored(_mobileCountry, _mobile.text);
    final whatsapp = _whatsappSameAsMobile
        ? mobile
        : (_whatsapp.text.trim().isEmpty
            ? mobile
            : PhoneNumberUtils.toStored(_whatsappCountry, _whatsapp.text));

    final salik = Salik(
      salikId: widget.salikId ?? '',
      name: _name.text.trim(),
      fatherName: _fatherName.text.trim(),
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
    final isUrdu = _isUrduForm;
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
                    return ListTile(
                      title: Text(_localeLabel(city.cityName)),
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
        _citySearch.text = _localeLabel(city.cityName);
      });
    } else if (result.startsWith('new:')) {
      final name = result.substring(4);
      if (name.isEmpty) return;
      final existingInList = cities.cast<City?>().firstWhere(
            (city) => city != null && cityMatchesNames(city, name: name),
            orElse: () => null,
          );
      if (existingInList != null) {
        setState(() {
          _cityId = existingInList.cityId;
          _areaId = '';
          _areaSearch.clear();
          _citySearch.text = _localeLabel(existingInList.cityName);
        });
        return;
      }
      setState(() => _loading = true);
      try {
        final repo = ref.read(areaRepositoryProvider);
        final city = await repo.createCity(name: name);
        if (mounted) {
          ref.invalidate(citiesProvider);
          ref.invalidate(areasByCityProvider(city.cityId));
          setState(() {
            _cityId = city.cityId;
            _areaId = '';
            _areaSearch.clear();
            _citySearch.text = _localeLabel(city.cityName);
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
    final isUrdu = _isUrduForm;
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
                    return ListTile(
                      title: Text(_localeLabel(area.areaName)),
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
        _areaSearch.text = _localeLabel(area.areaName);
      });
    } else if (result.startsWith('new:')) {
      final name = result.substring(4);
      if (name.isEmpty) return;
      setState(() => _loading = true);
      try {
        final repo = ref.read(areaRepositoryProvider);
        final area = await repo.createArea(cityId: _cityId, name: name);
        if (mounted) {
          ref.invalidate(areasByCityProvider(_cityId));
          setState(() {
            _areaId = area.areaId;
            _areaSearch.text = _localeLabel(area.areaName);
          });
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
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
      unawaited(_syncLocationLabels(cities, areas));
    }

    if (_cityId.isNotEmpty) {
      ref.listen(areasByCityProvider(_cityId), (previous, next) {
        if (widget.isEditing && _initialized && next.hasValue) {
          unawaited(_syncLocationLabels(cities, next.requireValue));
        }
      });
    }

    if (widget.isEditing && widget.salikId != null && !_initialized) {
      final salikAsync = ref.watch(salikByIdProvider(widget.salikId!));
      salikAsync.whenData((salik) {
        if (salik != null && !_initialized) {
          unawaited(() async {
            await _populateFromSalik(salik, cities, areas);
            if (mounted) setState(() => _initialized = true);
          }());
        }
      });
    } else if (!_initialized && session != null) {
      _gender = UserSession.normalizeGender(session.gender);
      _formLocale = 'en';
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
                  selectedIndex: _isUrduForm ? 1 : 0,
                  onSelected: (i) {
                    setState(() {
                      _formLocale = i == 1 ? 'ur' : 'en';
                      unawaited(_syncLocationLabels(cities, areas));
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
                        name: _name.text,
                        fatherName: _fatherName.text,
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
                          if (!_isUrduForm) ...[
                            TextFormField(
                              controller: _name,
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
                              controller: _fatherName,
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
                              controller: _name,
                              label: fl10n.t('name_urdu'),
                              prefixIcon: Icons.person_outline,
                              validator: (v) =>
                                  FormValidators.requiredField(v, fl10n),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            UrduField(
                              controller: _fatherName,
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
                              return InkWell(
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
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: fl10n.t('date_of_baith'),
                                    suffixIcon: IconColors.icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      colorIndex: 0,
                                    ),
                                    errorText: field.hasError
                                        ? field.errorText
                                        : null,
                                  ),
                                  child: Text(
                                    _dateBaith.isEmpty ? '—' : _dateBaith,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                ),
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
                            selectedCountry: _mobileCountry,
                            onCountryChanged: (country) {
                              setState(() {
                                _mobileCountry = country;
                                if (_whatsappSameAsMobile) {
                                  _whatsappCountry = country;
                                }
                              });
                            },
                            prefixIcon: Icons.phone,
                            colorIndex: 0,
                            validator: (v) => FormValidators.phoneField(
                              v,
                              fl10n,
                              country: _mobileCountry,
                            ),
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
                            onChanged: (v) => setState(() {
                              _whatsappSameAsMobile = v;
                              if (v) _whatsappCountry = _mobileCountry;
                            }),
                          ),
                          if (!_whatsappSameAsMobile) ...[
                            const SizedBox(height: AppSpacing.sm),
                            PakistanPhoneFormField(
                              controller: _whatsapp,
                              labelText: fl10n.t('whatsapp'),
                              selectedCountry: _whatsappCountry,
                              onCountryChanged: (country) {
                                setState(() => _whatsappCountry = country);
                              },
                              prefix: const WhatsAppMessageIcon(size: 22),
                              validator: (v) => FormValidators.optionalPhone(
                                v,
                                fl10n,
                                country: _whatsappCountry,
                              ),
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
