import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verdant/data/address.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/auth.dart';
import 'package:verdant/data/cart.dart';
import 'package:verdant/data/orders.dart';
import 'package:verdant/pages/auth.dart';
import 'package:verdant/widgets/components/product_card.dart';

http.Response _json(int status, Object? body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _user = {
  'id': 1,
  'email': 'sam@example.com',
  'name': 'Sam Doe',
  'location': '',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('sign in, then sign out clears the session', () async {
    final calls = <String>[];
    api = ApiClient(
      origin: 'http://test',
      client: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        return switch (request.url.path) {
          '/api/auth/login' => _json(200, {
            'data': {'token': 'abc', 'user': _user},
          }),
          '/api/sync' => _json(200, {
            'data': {'stores': {}, 'orders': []},
          }),
          _ => http.Response('', 204),
        };
      }),
    );

    await authStore.signIn(email: 'sam@example.com', password: 'growing-green');
    expect(authStore.user?.firstName, 'Sam');
    expect(api.token, 'abc');

    await authStore.signOut();
    expect(authStore.isSignedIn, isFalse);
    expect(api.token, isNull);
    expect(calls, contains('POST /api/auth/logout'));
  });

  test('a rejected session signs the user out', () async {
    var expired = false;
    api = ApiClient(
      origin: 'http://test',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return _json(200, {
            'data': {'token': 'abc', 'user': _user},
          });
        }
        if (expired) return _json(401, {'message': 'Please sign in again.'});
        return _json(200, {
          'data': {'stores': {}, 'orders': []},
        });
      }),
    );
    await authStore.init();
    await authStore.signIn(email: 'sam@example.com', password: 'growing-green');
    expired = true;
    await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
    await pumpEventQueue();
    expect(authStore.isSignedIn, isFalse);
  });

  testWidgets('the form validates and switches to registration', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.tap(find.text('New to Verdant? Create an account'));
    await tester.pump();
    expect(find.text('Start growing.'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });

  test('an empty address is not ready for checkout', () {
    expect(DeliveryAddress.empty.isComplete, isFalse);
  });

  test('order status comes from the server', () {
    const order = Order(
      items: [],
      subtotal: 10,
      discountLabel: null,
      discountAmount: 0,
      shipping: ShippingOption.standard,
      delivery: 6,
      total: 16,
      paymentTitle: 'Visa',
      serverStatus: 'shipped',
    );
    expect(order.status(), 'On its way');
  });

  testWidgets('the add button has a 48 dp touch area', (tester) async {
    var added = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 170,
              child: ProductCard(
                name: 'Fern',
                price: r'$10',
                image: MemoryImage(base64Decode(_pixel)),
                onAddTap: () => added++,
              ),
            ),
          ),
        ),
      ),
    );
    final area = tester.getRect(find.bySemanticsLabel('Add Fern to cart'));
    expect(area.width, greaterThanOrEqualTo(48));
    expect(area.height, greaterThanOrEqualTo(47));

    // Top-left of the area, well outside the 23 dp icon.
    await tester.tapAt(area.topLeft + const Offset(2, 2));
    expect(added, 1);
  });
}

const _pixel =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
