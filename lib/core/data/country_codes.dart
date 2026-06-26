class CountryDialCode {
  const CountryDialCode({
    required this.iso,
    required this.name,
    required this.dialCode,
  });

  final String iso;
  final String name;
  final String dialCode;

  String get dialDigits => dialCode.replaceAll('+', '');
}

const CountryDialCode kDefaultCountry = CountryDialCode(
  iso: 'PK',
  name: 'Pakistan',
  dialCode: '+92',
);

/// ITU dial codes sorted by country name.
const List<CountryDialCode> kCountryDialCodes = [

  CountryDialCode(iso: 'AF', name: 'Afghanistan', dialCode: '+93'),
  CountryDialCode(iso: 'AL', name: 'Albania', dialCode: '+355'),
  CountryDialCode(iso: 'DZ', name: 'Algeria', dialCode: '+213'),
  CountryDialCode(iso: 'AS', name: 'American Samoa', dialCode: '+1'),
  CountryDialCode(iso: 'AD', name: 'Andorra', dialCode: '+376'),
  CountryDialCode(iso: 'AO', name: 'Angola', dialCode: '+244'),
  CountryDialCode(iso: 'AI', name: 'Anguilla', dialCode: '+1'),
  CountryDialCode(iso: 'AG', name: 'Antigua and Barbuda', dialCode: '+1'),
  CountryDialCode(iso: 'AR', name: 'Argentina', dialCode: '+54'),
  CountryDialCode(iso: 'AM', name: 'Armenia', dialCode: '+374'),
  CountryDialCode(iso: 'AW', name: 'Aruba', dialCode: '+297'),
  CountryDialCode(iso: 'AU', name: 'Australia', dialCode: '+61'),
  CountryDialCode(iso: 'AT', name: 'Austria', dialCode: '+43'),
  CountryDialCode(iso: 'AZ', name: 'Azerbaijan', dialCode: '+994'),
  CountryDialCode(iso: 'BS', name: 'Bahamas', dialCode: '+1'),
  CountryDialCode(iso: 'BH', name: 'Bahrain', dialCode: '+973'),
  CountryDialCode(iso: 'BD', name: 'Bangladesh', dialCode: '+880'),
  CountryDialCode(iso: 'BB', name: 'Barbados', dialCode: '+1'),
  CountryDialCode(iso: 'BY', name: 'Belarus', dialCode: '+375'),
  CountryDialCode(iso: 'BE', name: 'Belgium', dialCode: '+32'),
  CountryDialCode(iso: 'BZ', name: 'Belize', dialCode: '+501'),
  CountryDialCode(iso: 'BJ', name: 'Benin', dialCode: '+229'),
  CountryDialCode(iso: 'BM', name: 'Bermuda', dialCode: '+1'),
  CountryDialCode(iso: 'BT', name: 'Bhutan', dialCode: '+975'),
  CountryDialCode(iso: 'BO', name: 'Bolivia', dialCode: '+591'),
  CountryDialCode(iso: 'BA', name: 'Bosnia and Herzegovina', dialCode: '+387'),
  CountryDialCode(iso: 'BW', name: 'Botswana', dialCode: '+267'),
  CountryDialCode(iso: 'BR', name: 'Brazil', dialCode: '+55'),
  CountryDialCode(iso: 'VG', name: 'British Virgin Islands', dialCode: '+1'),
  CountryDialCode(iso: 'BN', name: 'Brunei', dialCode: '+673'),
  CountryDialCode(iso: 'BG', name: 'Bulgaria', dialCode: '+359'),
  CountryDialCode(iso: 'BF', name: 'Burkina Faso', dialCode: '+226'),
  CountryDialCode(iso: 'BI', name: 'Burundi', dialCode: '+257'),
  CountryDialCode(iso: 'KH', name: 'Cambodia', dialCode: '+855'),
  CountryDialCode(iso: 'CM', name: 'Cameroon', dialCode: '+237'),
  CountryDialCode(iso: 'CA', name: 'Canada', dialCode: '+1'),
  CountryDialCode(iso: 'CV', name: 'Cape Verde', dialCode: '+238'),
  CountryDialCode(iso: 'KY', name: 'Cayman Islands', dialCode: '+1'),
  CountryDialCode(iso: 'CF', name: 'Central African Republic', dialCode: '+236'),
  CountryDialCode(iso: 'TD', name: 'Chad', dialCode: '+235'),
  CountryDialCode(iso: 'CL', name: 'Chile', dialCode: '+56'),
  CountryDialCode(iso: 'CN', name: 'China', dialCode: '+86'),
  CountryDialCode(iso: 'CO', name: 'Colombia', dialCode: '+57'),
  CountryDialCode(iso: 'KM', name: 'Comoros', dialCode: '+262'),
  CountryDialCode(iso: 'CG', name: 'Congo', dialCode: '+242'),
  CountryDialCode(iso: 'CD', name: 'Congo (DRC)', dialCode: '+243'),
  CountryDialCode(iso: 'CR', name: 'Costa Rica', dialCode: '+506'),
  CountryDialCode(iso: 'HR', name: 'Croatia', dialCode: '+385'),
  CountryDialCode(iso: 'CU', name: 'Cuba', dialCode: '+53'),
  CountryDialCode(iso: 'CY', name: 'Cyprus', dialCode: '+357'),
  CountryDialCode(iso: 'CZ', name: 'Czech Republic', dialCode: '+420'),
  CountryDialCode(iso: 'CI', name: 'Côte d\'Ivoire', dialCode: '+225'),
  CountryDialCode(iso: 'DK', name: 'Denmark', dialCode: '+45'),
  CountryDialCode(iso: 'DJ', name: 'Djibouti', dialCode: '+253'),
  CountryDialCode(iso: 'DM', name: 'Dominica', dialCode: '+1'),
  CountryDialCode(iso: 'DO', name: 'Dominican Republic', dialCode: '+1'),
  CountryDialCode(iso: 'EC', name: 'Ecuador', dialCode: '+593'),
  CountryDialCode(iso: 'EG', name: 'Egypt', dialCode: '+20'),
  CountryDialCode(iso: 'SV', name: 'El Salvador', dialCode: '+503'),
  CountryDialCode(iso: 'GQ', name: 'Equatorial Guinea', dialCode: '+240'),
  CountryDialCode(iso: 'ER', name: 'Eritrea', dialCode: '+291'),
  CountryDialCode(iso: 'EE', name: 'Estonia', dialCode: '+372'),
  CountryDialCode(iso: 'SZ', name: 'Eswatini', dialCode: '+268'),
  CountryDialCode(iso: 'ET', name: 'Ethiopia', dialCode: '+251'),
  CountryDialCode(iso: 'FJ', name: 'Fiji', dialCode: '+679'),
  CountryDialCode(iso: 'FI', name: 'Finland', dialCode: '+358'),
  CountryDialCode(iso: 'FR', name: 'France', dialCode: '+33'),
  CountryDialCode(iso: 'GF', name: 'French Guiana', dialCode: '+594'),
  CountryDialCode(iso: 'PF', name: 'French Polynesia', dialCode: '+689'),
  CountryDialCode(iso: 'GA', name: 'Gabon', dialCode: '+241'),
  CountryDialCode(iso: 'GM', name: 'Gambia', dialCode: '+220'),
  CountryDialCode(iso: 'GE', name: 'Georgia', dialCode: '+995'),
  CountryDialCode(iso: 'DE', name: 'Germany', dialCode: '+49'),
  CountryDialCode(iso: 'GH', name: 'Ghana', dialCode: '+233'),
  CountryDialCode(iso: 'GI', name: 'Gibraltar', dialCode: '+350'),
  CountryDialCode(iso: 'GR', name: 'Greece', dialCode: '+30'),
  CountryDialCode(iso: 'GL', name: 'Greenland', dialCode: '+299'),
  CountryDialCode(iso: 'GD', name: 'Grenada', dialCode: '+1'),
  CountryDialCode(iso: 'GP', name: 'Guadeloupe', dialCode: '+590'),
  CountryDialCode(iso: 'GU', name: 'Guam', dialCode: '+1'),
  CountryDialCode(iso: 'GT', name: 'Guatemala', dialCode: '+502'),
  CountryDialCode(iso: 'GN', name: 'Guinea', dialCode: '+224'),
  CountryDialCode(iso: 'GW', name: 'Guinea-Bissau', dialCode: '+245'),
  CountryDialCode(iso: 'GY', name: 'Guyana', dialCode: '+592'),
  CountryDialCode(iso: 'HT', name: 'Haiti', dialCode: '+509'),
  CountryDialCode(iso: 'HN', name: 'Honduras', dialCode: '+504'),
  CountryDialCode(iso: 'HK', name: 'Hong Kong', dialCode: '+852'),
  CountryDialCode(iso: 'HU', name: 'Hungary', dialCode: '+36'),
  CountryDialCode(iso: 'IS', name: 'Iceland', dialCode: '+354'),
  CountryDialCode(iso: 'IN', name: 'India', dialCode: '+91'),
  CountryDialCode(iso: 'ID', name: 'Indonesia', dialCode: '+62'),
  CountryDialCode(iso: 'IR', name: 'Iran', dialCode: '+98'),
  CountryDialCode(iso: 'IQ', name: 'Iraq', dialCode: '+964'),
  CountryDialCode(iso: 'IE', name: 'Ireland', dialCode: '+353'),
  CountryDialCode(iso: 'IL', name: 'Israel', dialCode: '+972'),
  CountryDialCode(iso: 'IT', name: 'Italy', dialCode: '+39'),
  CountryDialCode(iso: 'JM', name: 'Jamaica', dialCode: '+1'),
  CountryDialCode(iso: 'JP', name: 'Japan', dialCode: '+81'),
  CountryDialCode(iso: 'JO', name: 'Jordan', dialCode: '+962'),
  CountryDialCode(iso: 'KZ', name: 'Kazakhstan', dialCode: '+7'),
  CountryDialCode(iso: 'KE', name: 'Kenya', dialCode: '+254'),
  CountryDialCode(iso: 'KI', name: 'Kiribati', dialCode: '+686'),
  CountryDialCode(iso: 'XK', name: 'Kosovo', dialCode: '+383'),
  CountryDialCode(iso: 'KW', name: 'Kuwait', dialCode: '+965'),
  CountryDialCode(iso: 'KG', name: 'Kyrgyzstan', dialCode: '+996'),
  CountryDialCode(iso: 'LA', name: 'Laos', dialCode: '+856'),
  CountryDialCode(iso: 'LV', name: 'Latvia', dialCode: '+371'),
  CountryDialCode(iso: 'LB', name: 'Lebanon', dialCode: '+961'),
  CountryDialCode(iso: 'LS', name: 'Lesotho', dialCode: '+266'),
  CountryDialCode(iso: 'LR', name: 'Liberia', dialCode: '+231'),
  CountryDialCode(iso: 'LY', name: 'Libya', dialCode: '+218'),
  CountryDialCode(iso: 'LI', name: 'Liechtenstein', dialCode: '+423'),
  CountryDialCode(iso: 'LT', name: 'Lithuania', dialCode: '+370'),
  CountryDialCode(iso: 'LU', name: 'Luxembourg', dialCode: '+352'),
  CountryDialCode(iso: 'MO', name: 'Macau', dialCode: '+853'),
  CountryDialCode(iso: 'MG', name: 'Madagascar', dialCode: '+261'),
  CountryDialCode(iso: 'MW', name: 'Malawi', dialCode: '+265'),
  CountryDialCode(iso: 'MY', name: 'Malaysia', dialCode: '+60'),
  CountryDialCode(iso: 'MV', name: 'Maldives', dialCode: '+960'),
  CountryDialCode(iso: 'ML', name: 'Mali', dialCode: '+223'),
  CountryDialCode(iso: 'MT', name: 'Malta', dialCode: '+356'),
  CountryDialCode(iso: 'MH', name: 'Marshall Islands', dialCode: '+692'),
  CountryDialCode(iso: 'MQ', name: 'Martinique', dialCode: '+596'),
  CountryDialCode(iso: 'MR', name: 'Mauritania', dialCode: '+222'),
  CountryDialCode(iso: 'MU', name: 'Mauritius', dialCode: '+230'),
  CountryDialCode(iso: 'MX', name: 'Mexico', dialCode: '+52'),
  CountryDialCode(iso: 'FM', name: 'Micronesia', dialCode: '+691'),
  CountryDialCode(iso: 'MD', name: 'Moldova', dialCode: '+373'),
  CountryDialCode(iso: 'MC', name: 'Monaco', dialCode: '+377'),
  CountryDialCode(iso: 'MN', name: 'Mongolia', dialCode: '+976'),
  CountryDialCode(iso: 'ME', name: 'Montenegro', dialCode: '+382'),
  CountryDialCode(iso: 'MS', name: 'Montserrat', dialCode: '+1'),
  CountryDialCode(iso: 'MA', name: 'Morocco', dialCode: '+212'),
  CountryDialCode(iso: 'MZ', name: 'Mozambique', dialCode: '+258'),
  CountryDialCode(iso: 'MM', name: 'Myanmar', dialCode: '+95'),
  CountryDialCode(iso: 'NA', name: 'Namibia', dialCode: '+264'),
  CountryDialCode(iso: 'NR', name: 'Nauru', dialCode: '+674'),
  CountryDialCode(iso: 'NP', name: 'Nepal', dialCode: '+977'),
  CountryDialCode(iso: 'NL', name: 'Netherlands', dialCode: '+31'),
  CountryDialCode(iso: 'NC', name: 'New Caledonia', dialCode: '+687'),
  CountryDialCode(iso: 'NZ', name: 'New Zealand', dialCode: '+64'),
  CountryDialCode(iso: 'NI', name: 'Nicaragua', dialCode: '+505'),
  CountryDialCode(iso: 'NE', name: 'Niger', dialCode: '+227'),
  CountryDialCode(iso: 'NG', name: 'Nigeria', dialCode: '+234'),
  CountryDialCode(iso: 'NU', name: 'Niue', dialCode: '+683'),
  CountryDialCode(iso: 'NF', name: 'Norfolk Island', dialCode: '+672'),
  CountryDialCode(iso: 'KP', name: 'North Korea', dialCode: '+850'),
  CountryDialCode(iso: 'MK', name: 'North Macedonia', dialCode: '+389'),
  CountryDialCode(iso: 'NO', name: 'Norway', dialCode: '+47'),
  CountryDialCode(iso: 'OM', name: 'Oman', dialCode: '+968'),
  CountryDialCode(iso: 'PK', name: 'Pakistan', dialCode: '+92'),
  CountryDialCode(iso: 'PW', name: 'Palau', dialCode: '+680'),
  CountryDialCode(iso: 'PS', name: 'Palestine', dialCode: '+970'),
  CountryDialCode(iso: 'PA', name: 'Panama', dialCode: '+507'),
  CountryDialCode(iso: 'PG', name: 'Papua New Guinea', dialCode: '+675'),
  CountryDialCode(iso: 'PY', name: 'Paraguay', dialCode: '+595'),
  CountryDialCode(iso: 'PE', name: 'Peru', dialCode: '+51'),
  CountryDialCode(iso: 'PH', name: 'Philippines', dialCode: '+63'),
  CountryDialCode(iso: 'PL', name: 'Poland', dialCode: '+48'),
  CountryDialCode(iso: 'PT', name: 'Portugal', dialCode: '+351'),
  CountryDialCode(iso: 'PR', name: 'Puerto Rico', dialCode: '+1'),
  CountryDialCode(iso: 'QA', name: 'Qatar', dialCode: '+974'),
  CountryDialCode(iso: 'RO', name: 'Romania', dialCode: '+40'),
  CountryDialCode(iso: 'RU', name: 'Russia', dialCode: '+7'),
  CountryDialCode(iso: 'RW', name: 'Rwanda', dialCode: '+250'),
  CountryDialCode(iso: 'RE', name: 'Réunion', dialCode: '+262'),
  CountryDialCode(iso: 'KN', name: 'Saint Kitts and Nevis', dialCode: '+1'),
  CountryDialCode(iso: 'LC', name: 'Saint Lucia', dialCode: '+1'),
  CountryDialCode(iso: 'VC', name: 'Saint Vincent', dialCode: '+1'),
  CountryDialCode(iso: 'WS', name: 'Samoa', dialCode: '+685'),
  CountryDialCode(iso: 'SM', name: 'San Marino', dialCode: '+378'),
  CountryDialCode(iso: 'SA', name: 'Saudi Arabia', dialCode: '+966'),
  CountryDialCode(iso: 'SN', name: 'Senegal', dialCode: '+221'),
  CountryDialCode(iso: 'RS', name: 'Serbia', dialCode: '+381'),
  CountryDialCode(iso: 'SC', name: 'Seychelles', dialCode: '+248'),
  CountryDialCode(iso: 'SL', name: 'Sierra Leone', dialCode: '+232'),
  CountryDialCode(iso: 'SG', name: 'Singapore', dialCode: '+65'),
  CountryDialCode(iso: 'SK', name: 'Slovakia', dialCode: '+421'),
  CountryDialCode(iso: 'SI', name: 'Slovenia', dialCode: '+386'),
  CountryDialCode(iso: 'SB', name: 'Solomon Islands', dialCode: '+677'),
  CountryDialCode(iso: 'SO', name: 'Somalia', dialCode: '+252'),
  CountryDialCode(iso: 'ZA', name: 'South Africa', dialCode: '+27'),
  CountryDialCode(iso: 'KR', name: 'South Korea', dialCode: '+82'),
  CountryDialCode(iso: 'SS', name: 'South Sudan', dialCode: '+211'),
  CountryDialCode(iso: 'ES', name: 'Spain', dialCode: '+34'),
  CountryDialCode(iso: 'LK', name: 'Sri Lanka', dialCode: '+94'),
  CountryDialCode(iso: 'SD', name: 'Sudan', dialCode: '+249'),
  CountryDialCode(iso: 'SR', name: 'Suriname', dialCode: '+597'),
  CountryDialCode(iso: 'SE', name: 'Sweden', dialCode: '+46'),
  CountryDialCode(iso: 'CH', name: 'Switzerland', dialCode: '+41'),
  CountryDialCode(iso: 'SY', name: 'Syria', dialCode: '+963'),
  CountryDialCode(iso: 'ST', name: 'São Tomé and Príncipe', dialCode: '+239'),
  CountryDialCode(iso: 'TW', name: 'Taiwan', dialCode: '+886'),
  CountryDialCode(iso: 'TJ', name: 'Tajikistan', dialCode: '+992'),
  CountryDialCode(iso: 'TZ', name: 'Tanzania', dialCode: '+255'),
  CountryDialCode(iso: 'TH', name: 'Thailand', dialCode: '+66'),
  CountryDialCode(iso: 'TL', name: 'Timor-Leste', dialCode: '+670'),
  CountryDialCode(iso: 'TG', name: 'Togo', dialCode: '+228'),
  CountryDialCode(iso: 'TO', name: 'Tonga', dialCode: '+676'),
  CountryDialCode(iso: 'TT', name: 'Trinidad and Tobago', dialCode: '+1'),
  CountryDialCode(iso: 'TN', name: 'Tunisia', dialCode: '+216'),
  CountryDialCode(iso: 'TR', name: 'Turkey', dialCode: '+90'),
  CountryDialCode(iso: 'TM', name: 'Turkmenistan', dialCode: '+993'),
  CountryDialCode(iso: 'TC', name: 'Turks and Caicos', dialCode: '+1'),
  CountryDialCode(iso: 'VI', name: 'US Virgin Islands', dialCode: '+1'),
  CountryDialCode(iso: 'UG', name: 'Uganda', dialCode: '+256'),
  CountryDialCode(iso: 'UA', name: 'Ukraine', dialCode: '+380'),
  CountryDialCode(iso: 'AE', name: 'United Arab Emirates', dialCode: '+971'),
  CountryDialCode(iso: 'GB', name: 'United Kingdom', dialCode: '+44'),
  CountryDialCode(iso: 'US', name: 'United States', dialCode: '+1'),
  CountryDialCode(iso: 'UY', name: 'Uruguay', dialCode: '+598'),
  CountryDialCode(iso: 'UZ', name: 'Uzbekistan', dialCode: '+998'),
  CountryDialCode(iso: 'VU', name: 'Vanuatu', dialCode: '+678'),
  CountryDialCode(iso: 'VE', name: 'Venezuela', dialCode: '+58'),
  CountryDialCode(iso: 'VN', name: 'Vietnam', dialCode: '+84'),
  CountryDialCode(iso: 'YE', name: 'Yemen', dialCode: '+967'),
  CountryDialCode(iso: 'ZM', name: 'Zambia', dialCode: '+260'),
  CountryDialCode(iso: 'ZW', name: 'Zimbabwe', dialCode: '+263'),
];

CountryDialCode? findCountryByIso(String iso) {
  final normalized = iso.trim().toUpperCase();
  for (final country in kCountryDialCodes) {
    if (country.iso == normalized) return country;
  }
  return null;
}

const Map<String, String> _preferredIsoByDialDigits = {
  '1': 'US',
  '7': 'RU',
  '44': 'GB',
  '262': 'RE',
};

CountryDialCode _pickBetterMatch(CountryDialCode current, CountryDialCode candidate) {
  final preferredIso = _preferredIsoByDialDigits[current.dialDigits];
  if (preferredIso == current.iso) return current;
  if (preferredIso == candidate.iso) return candidate;
  return current;
}

CountryDialCode? findCountryByDialCode(String dialCode) {
  final digits = dialCode.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  CountryDialCode? match;
  var bestLength = 0;
  for (final country in kCountryDialCodes) {
    final code = country.dialDigits;
    if (!digits.startsWith(code)) continue;
    if (code.length > bestLength) {
      match = country;
      bestLength = code.length;
      continue;
    }
    if (code.length == bestLength && match != null) {
      match = _pickBetterMatch(match, country);
    }
  }
  return match;
}

List<CountryDialCode> filterCountries(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kCountryDialCodes;
  return kCountryDialCodes.where((country) {
    return country.name.toLowerCase().contains(q) ||
        country.iso.toLowerCase().contains(q) ||
        country.dialCode.contains(q) ||
        country.dialDigits.contains(q.replaceAll('+', ''));
  }).toList();
}

