import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/auth.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/owned_plants.dart';
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/data/settings.dart';
import 'package:verdant/data/shop_filter.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/data/sync.dart';
import 'package:verdant/l10n/i18n.dart';
import 'package:verdant/l10n/it.dart';
import 'package:verdant/models/product.dart';
import 'package:verdant/pages/activity.dart';
import 'package:verdant/pages/auth.dart';
import 'package:verdant/pages/care_reminder.dart';
import 'package:verdant/pages/cart.dart';
import 'package:verdant/pages/checkout.dart';
import 'package:verdant/pages/greenhouse.dart';
import 'package:verdant/pages/homepage.dart';
import 'package:verdant/pages/notifications.dart';
import 'package:verdant/pages/personal_plant_details.dart';
import 'package:verdant/pages/plants.dart';
import 'package:verdant/pages/product_details.dart';
import 'package:verdant/pages/profile.dart';
import 'package:verdant/pages/profile/account.dart';
import 'package:verdant/pages/profile/addresses.dart';
import 'package:verdant/pages/profile/care_reminders.dart';
import 'package:verdant/pages/profile/help.dart';
import 'package:verdant/pages/profile/orders.dart';
import 'package:verdant/pages/profile/payment_methods.dart';
import 'package:verdant/pages/profile/privacy.dart';
import 'package:verdant/theme/theme.dart';
import 'package:verdant/utils/money.dart';
import 'package:verdant/widgets/components/app_bottom_navigation.dart';

const _testImage = 'assets/images/autumn_botanical_still_life.png';

List<Map<String, dynamic>> _catalogue() => (jsonDecode(
  File('backend/src/data/products.json').readAsStringSync(),
) as List).cast<Map<String, dynamic>>();

/// The real catalogue, with images from the app's assets.
class _FakeRepository implements ProductRepository {
  final _items = _catalogue();

  Map<String, dynamic> _local(Map<String, dynamic> p) => {
    ...p,
    'image': _testImage,
    'images': [_testImage],
  };

  @override
  Future<List<ProductSummary>> getProducts({String? category}) async => [
    for (final p in _items) ProductSummary.fromJson(_local(p)),
  ];

  @override
  Future<List<ProductSummary>> getFeaturedProducts() async => [
    for (final p in _items.where((p) => p['featured'] == true).take(3))
      ProductSummary.fromJson(_local(p)),
  ];

  @override
  Future<ProductDetails> getProductDetails(int id) async {
    final p = _items.firstWhere((p) => p['id'] == id);
    return ProductDetails.fromJson({
      ..._local(p),
      'related': [
        for (final r in p['relatedIds'] as List)
          _local(_items.firstWhere((i) => i['id'] == r)),
      ],
    });
  }
}

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }

  await family('Inter', [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ]);
  await family('Lora', ['Lora-Regular.ttf']);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Storage.init();
    await _loadFonts();
  });

  tearDown(() => appSettings.language = AppLanguage.en);

  test('every translation keeps its placeholders', () {
    final holes = RegExp(r'\{\d+\}');
    Set<String> of(String s) => holes.allMatches(s).map((m) => m[0]!).toSet();
    for (final e in italian.entries) {
      expect(e.value.trim(), isNotEmpty, reason: e.key);
      expect(of(e.value), of(e.key), reason: e.key);
    }
  });

  test('the whole catalogue is translated', () {
    const fields = [
      'name',
      'eyebrow',
      'availabilityLabel',
      'tag',
      'summary',
      'variantLabel',
      'variantDetail',
      'purchaseNote',
      'descriptionTitle',
      'description',
      'growth',
      'goodToKnow',
    ];
    for (final p in _catalogue()) {
      for (final field in fields) {
        if (p[field] is String) {
          expect(italian, contains(p[field]), reason: '${p['id']} $field');
        }
      }
      for (final tag in p['tags'] as List) {
        expect(italian, contains(tag['label']), reason: '${p['id']} tag');
      }
      for (final step in p['careSteps'] as List) {
        expect(italian, contains(step['title']), reason: '${p['id']} step');
        expect(italian, contains(step['description']), reason: '${p['id']}');
      }
    }
  });

  test('language changes text, dates and prices', () {
    appSettings.language = AppLanguage.it;
    expect('Sign in'.tr, 'Accedi');
    expect(trArgs('Order {0}', ['VRD-1']), 'Ordine VRD-1');
    expect(formatMoney(38.5), r'$38,50');
    expect(appDate('MMM d').format(DateTime(2026, 11, 5)), '5 nov');
    expect(appDate('h:mm a').format(DateTime(2026, 11, 5, 15, 30)), '15:30');
    expect(I18n.server('Only 2 left of Hydrangea.'), contains('Ortensia'));

    appSettings.language = AppLanguage.en;
    expect('Sign in'.tr, 'Sign in');
    expect(formatMoney(38.5), r'$38.50');
    expect(appDate('MMM d').format(DateTime(2026, 11, 5)), 'Nov 5');
  });

  test('the language survives erasing the phone data', () async {
    appSettings.language = AppLanguage.it;
    await Storage.clearAll();
    appSettings.restore();
    expect(appSettings.language, AppLanguage.it);
    expect(I18n.isItalian, isTrue);
  });

  test('filters and saved values stay language-neutral', () {
    appSettings.language = AppLanguage.it;
    const outdoor = ProductSummary(
      id: 1,
      name: 'Hydrangea',
      price: 36,
      image: '',
      category: 'plants',
      tags: ['Outdoor'],
    );
    expect(outdoor.name, 'Ortensia');
    expect(ShopCategory.outdoorPlants.matches(outdoor), isTrue);

    final plant = OwnedPlant(
      id: 'x',
      name: 'Pothos dorato',
      room: 'Soggiorno',
      species: 'Epipremnum aureum',
      imagePath: _testImage,
      addedOn: DateTime(2026),
    );
    expect(plant.toJson()['name'], 'Golden Pothos');
    expect(plant.toJson()['room'], 'Living room');
    expect(plant.room, 'Soggiorno');

    final custom = OwnedPlant(
      id: 'y',
      name: 'Cucina',
      room: 'Mansarda',
      species: 'Other',
      imagePath: _testImage,
      addedOn: DateTime(2026),
    );
    expect(custom.toJson()['name'], 'Cucina');
    expect(custom.toJson()['room'], 'Mansarda');

    appSettings.language = AppLanguage.en;
    expect(plant.name, 'Golden Pothos');
    expect(plant.room, 'Living room');
    expect(custom.name, 'Cucina');
  });

  group('Italian text fits a small phone:', () {
    setUpAll(() async {
      productRepository = _FakeRepository();
      api = ApiClient(
        origin: 'http://test',
        client: MockClient((request) async {
          final data = switch (request.url.path) {
            '/api/auth/login' => {
              'token': 'abc',
              'user': {
                'id': 1,
                'email': 'sam@example.com',
                'name': 'Sam Doe',
                'location': 'Roma',
              },
            },
            '/api/sync' => {'stores': {}, 'orders': []},
            _ => null,
          };
          return http.Response(jsonEncode({'data': data}), 200);
        }),
      );
      await authStore.signIn(email: 'sam@example.com', password: 'password1');
      // These tests only render pages: nothing should be uploaded.
      syncService.stop();
      cart.add(productId: 12, name: 'Leaf shine oil', unitPrice: 14, image: '');
    });

    testWidgets('the Profile setting switches the language', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const Profile()),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Language'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      expect(appSettings.language, AppLanguage.it);
      expect(find.text('Lingua'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
    });

    final pages = <String, Widget Function()>{
      'auth': () => const AuthPage(),
      'home': () => const Homepage(),
      'plants': () => const Plants(),
      'greenhouse': () => const Greenhouse(),
      'activity': () => const Activity(),
      'profile': () => const Profile(),
      'cart': () => const CartPage(),
      'checkout': () => const CheckoutPage(),
      'notifications': () => const NotificationsPage(),
      'orders': () => const OrdersPage(),
      'addresses': () => const AddressPage(),
      'payment methods': () => const PaymentMethodsPage(),
      'care reminders': () => const CareRemindersPage(),
      'help': () => const HelpPage(),
      'privacy': () => const PrivacyPage(),
      'account': () => const AccountPage(),
      'plant details': () => const PersonalPlantDetails(plantId: 'monstera'),
      'reminder form': () => CareReminderPage(plant: ownedPlants.first),
      for (final p in _catalogue())
        'product ${p['id']}': () =>
            ProductDetailsPage(productId: p['id'] as int),
      'bottom bar': () => Scaffold(
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    };

    for (final MapEntry(key: name, value: page) in pages.entries) {
      testWidgets(name, (tester) async {
        appSettings.language = AppLanguage.it;
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('it', 'IT'),
            supportedLocales: const [Locale('it', 'IT')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: page(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
