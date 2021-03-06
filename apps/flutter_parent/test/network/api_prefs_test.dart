// Copyright (C) 2019 - present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:ui';

import 'package:flutter_parent/models/login.dart';
import 'package:flutter_parent/models/mobile_verify_result.dart';
import 'package:flutter_parent/models/reminder.dart';
import 'package:flutter_parent/network/utils/api_prefs.dart';
import 'package:flutter_parent/utils/db/reminder_db.dart';
import 'package:flutter_parent/utils/notification_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info/package_info.dart';

import '../utils/canvas_model_utils.dart';
import '../utils/platform_config.dart';
import '../utils/test_app.dart';

void main() {
  tearDown(() {
    ApiPrefs.clean();
  });

  test('is logged in throws error if not initiailzed', () {
    expect(() => ApiPrefs.isLoggedIn(), throwsStateError);
  });

  test('is logged in returns false', () async {
    await setupPlatformChannels();
    expect(ApiPrefs.isLoggedIn(), false);
  });

  test('is logged in returns false with no login uuid', () async {
    var login = Login((b) => b
      ..domain = 'domain'
      ..accessToken = 'token'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());
    await setupPlatformChannels(config: PlatformConfig());
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.isLoggedIn(), false);
  });

  test('is logged in returns false with no valid uuid but no matching login', () async {
    var login = Login((b) => b
      ..uuid = 'uuid'
      ..domain = 'domain'
      ..accessToken = 'token'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: 'other_uuid'}));
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.isLoggedIn(), false);
  });

  test('is logged in returns true with a valid uuid and matching login', () async {
    var login = Login((b) => b
      ..domain = 'domain'
      ..accessToken = 'token'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.isLoggedIn(), true);
  });

  test('getApiUrl returns the domain with the api path added', () async {
    var login = Login((b) => b
      ..domain = 'domain'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.getApiUrl(), 'domain/api/v1/');
  });

  test('switchLogins updates current login data', () async {
    await setupPlatformChannels();

    Login user = Login((b) => b
      ..accessToken = 'token'
      ..refreshToken = 'refresh'
      ..domain = 'domain'
      ..clientId = 'clientId'
      ..clientSecret = 'clientSecret'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());

    ApiPrefs.switchLogins(user);

    expect(ApiPrefs.getAuthToken(), user.accessToken);
    expect(ApiPrefs.getRefreshToken(), user.refreshToken);
    expect(ApiPrefs.getDomain(), user.domain);
    expect(ApiPrefs.getClientId(), user.clientId);
    expect(ApiPrefs.getClientSecret(), user.clientSecret);
    expect(ApiPrefs.getUser(), user.user);
  });

  test('perform logout clears out data', () async {
    var login = Login((b) => b
      ..domain = 'domain'
      ..accessToken = 'accessToken'
      ..refreshToken = 'refreshToken'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());

    await setupPlatformChannels(
        config: PlatformConfig(
      mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid},
    ));
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.getDomain(), login.domain);
    expect(ApiPrefs.getAuthToken(), login.accessToken);
    expect(ApiPrefs.getRefreshToken(), login.refreshToken);
    expect(ApiPrefs.getCurrentLoginUuid(), login.uuid);

    await ApiPrefs.performLogout(switchingLogins: true);

    expect(ApiPrefs.getDomain(), null);
    expect(ApiPrefs.getAuthToken(), null);
    expect(ApiPrefs.getRefreshToken(), null);
    expect(ApiPrefs.getCurrentLoginUuid(), null);
  });

  test('perform logout clears out reminder', () async {
    final reminderDb = _MockReminderDb();
    final notificationUtil = _MockNotificationUtil();
    setupTestLocator((locator) {
      locator.registerLazySingleton<ReminderDb>(() => reminderDb);
      locator.registerLazySingleton<NotificationUtil>(() => notificationUtil);
    });

    final reminder = Reminder((b) => b..id = 1234);
    when(reminderDb.getAllForUser(any, any)).thenAnswer((_) async => [reminder]);

    var login = Login((b) => b
      ..domain = 'domain'
      ..accessToken = 'accessToken'
      ..refreshToken = 'refreshToken'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());

    await setupPlatformChannels(
        config: PlatformConfig(
      mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid},
    ));
    await ApiPrefs.addLogin(login);
    await ApiPrefs.performLogout(switchingLogins: false);

    verify(reminderDb.getAllForUser(login.domain, login.user.id));
    verify(notificationUtil.deleteNotifications([reminder.id]));
    verify(reminderDb.deleteAllForUser(login.domain, login.user.id));
  });

  test('setting user updates stored user', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    final user = CanvasModelTestUtils.mockUser();
    await ApiPrefs.setUser(user);

    expect(ApiPrefs.getUser(), user);
  });

  test('setting user updates with new locale rebuilds the app', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));

    expect(ApiPrefs.getUser(), null);

    await ApiPrefs.addLogin(login);

    final user = CanvasModelTestUtils.mockUser();
    final app = _MockApp();
    await ApiPrefs.setUser(user, app: app);

    verify(app.rebuild(any)).called(1);
  });

  test('effectiveLocale returns the devices locale', () async {
    await setupPlatformChannels();

    final deviceLocale = window.locale.toLanguageTag();

    final localeParts = deviceLocale.split('-');
    expect(ApiPrefs.effectiveLocale(), Locale(localeParts.first, localeParts.last));
  });

  test('effectiveLocale returns the users effective locale', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    final user = CanvasModelTestUtils.mockUser();
    await ApiPrefs.setUser(user);

    expect(ApiPrefs.effectiveLocale(), Locale(user.effectiveLocale, user.effectiveLocale));
  });

  test('effectiveLocale returns the users locale if effective locale is null', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    final user = CanvasModelTestUtils.mockUser().rebuild((b) => b
      ..effectiveLocale = null
      ..locale = 'jp');

    await ApiPrefs.setUser(user);

    expect(ApiPrefs.effectiveLocale(), Locale(user.locale, user.locale));
  });

  test('effectiveLocale returns the users locale if effective locale is null', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    final user = CanvasModelTestUtils.mockUser().rebuild((b) => b..effectiveLocale = 'en-AU-x-unimelb');

    await ApiPrefs.setUser(user);

    expect(
        ApiPrefs.effectiveLocale(), Locale.fromSubtags(languageCode: 'en', countryCode: 'AU', scriptCode: 'unimelb'));
  });

  test('getUser throws error if not initialized', () {
    expect(() => ApiPrefs.getUser(), throwsStateError);
  });

  test('getUser returns null', () async {
    await setupPlatformChannels();
    expect(ApiPrefs.getUser(), null);
  });

  test('getHeaderMap throws state error', () {
    expect(() => ApiPrefs.getHeaderMap(), throwsStateError);
  });

  test('getHeaderMap returns a map with the accept-language from prefs', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    final user = CanvasModelTestUtils.mockUser().rebuild((b) => b..effectiveLocale = 'en-US');
    await ApiPrefs.setUser(user);

    expect(ApiPrefs.getHeaderMap()['accept-language'], 'en,US');
  });

  test('getHeaderMap returns a map with the accept-language from device', () async {
    final login = Login();
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    final deviceLocale = window.locale;
    final user = CanvasModelTestUtils.mockUser().rebuild((b) => b..effectiveLocale = 'ar');
    await ApiPrefs.setUser(user);

    expect(ApiPrefs.getHeaderMap(forceDeviceLanguage: true)['accept-language'],
        deviceLocale.toLanguageTag().replaceAll('-', ','));
  });

  test('getHeaderMap returns a map with the token from prefs', () async {
    var login = Login((b) => b
      ..accessToken = 'token'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.getHeaderMap()['Authorization'], 'Bearer token');
  });

  test('getHeaderMap returns a map with the token passed in', () async {
    var login = Login((b) => b
      ..accessToken = 'token'
      ..user = CanvasModelTestUtils.mockUser().toBuilder());
    await setupPlatformChannels(config: PlatformConfig(mockPrefs: {ApiPrefs.KEY_CURRENT_LOGIN_UUID: login.uuid}));
    await ApiPrefs.addLogin(login);

    expect(ApiPrefs.getHeaderMap(token: 'other token')['Authorization'], 'Bearer other token');
  });

  test('getHeaderMap returns a map with the correct user-agent from prefs', () async {
    await setupPlatformChannels();
    var info = await PackageInfo.fromPlatform();
    var userAgent = 'androidParent/${info.version} (${info.buildNumber})';

    expect(ApiPrefs.getUserAgent(), userAgent);
    expect(ApiPrefs.getHeaderMap()['User-Agent'], ApiPrefs.getUserAgent());
  });

  test('getHeaderMap returns a map with the extra headers passed in', () async {
    await setupPlatformChannels();

    final map = {'key': 'value'};

    expect(ApiPrefs.getHeaderMap(extraHeaders: map)['key'], 'value');
  });

  test('gets and sets hasMigrated', () async {
    await setupPlatformChannels();
    await ApiPrefs.setHasMigrated(true);

    expect(ApiPrefs.getHasMigrated(), isTrue);
  });
}

MobileVerifyResult _mockVerifyResult(String domain) => MobileVerifyResult((b) {
      return b
        ..baseUrl = domain
        ..authorized = true
        ..result = VerifyResultEnum.success
        ..clientId = 'clientId'
        ..clientSecret = 'clientSecret'
        ..apiKey = 'key'
        ..build();
    });

abstract class _Rebuildable {
  void rebuild(Locale locale);
}

class _MockApp extends Mock implements _Rebuildable {}

class _MockReminderDb extends Mock implements ReminderDb {}

class _MockNotificationUtil extends Mock implements NotificationUtil {}
