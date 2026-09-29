import 'dart:math';

import '../data/daily_events.dart';
import '../models/daily_event.dart';
import '../models/game_state.dart';

class DailySimulationService {
  final Random _random = Random();

  static const List<String> weatherTypes = [
    'sunny',
    'cloudy',
    'rainy',
    'hot',
  ];

  Future<void> prepareDay(GameState state) async {
    if (state.simulationDay == state.day) {
      return;
    }

    state.weather =
    weatherTypes[_random.nextInt(weatherTypes.length)];

    state.marketTrends.clear();

    _generateMarketTrends(state);

    state.customerCount = _generateCustomerCount(state);

    state.dailyEvents = _generateEvents(state);

    state.simulationDay = state.day;
  }

  void _generateMarketTrends(GameState state) {
    const products = [
      'apple',
      'banana',
      'water',
      'milk',
      'bread',
    ];

    for (final productId in products) {
      final roll = _random.nextInt(100);

      if (roll < 15) {
        state.marketTrends[productId] = 30;
      } else if (roll < 35) {
        state.marketTrends[productId] = 15;
      } else if (roll < 80) {
        state.marketTrends[productId] = 0;
      } else if (roll < 95) {
        state.marketTrends[productId] = -10;
      } else {
        state.marketTrends[productId] = -20;
      }
    }

    if (state.weather == 'hot') {
      state.marketTrends['water'] =
          (state.marketTrends['water'] ?? 0) + 30;
    }

    if (state.weather == 'rainy') {
      state.marketTrends['water'] =
          (state.marketTrends['water'] ?? 0) - 10;
    }
  }

  int _generateCustomerCount(GameState state) {
    int count = 6;

    count += state.reputation ~/ 3;

    // Day 1 = Monday.
    final weekday = ((state.day - 1) % 7) + 1;

    if (weekday == 6 || weekday == 7) {
      count += 3;
    }

    switch (state.weather) {
      case 'sunny':
        count += 1;
        break;

      case 'hot':
        count += 2;
        break;

      case 'cloudy':
        break;

      case 'rainy':
        count -= 2;
        break;
    }

    count += _random.nextInt(5) - 2;

    return max(2, min(count, 20));
  }

  List<DailyEvent> _generateEvents(GameState state) {
    final shuffled = [...dailyEvents]..shuffle(_random);

    final roll = _random.nextInt(100);

    int eventCount;

    if (roll < 55) {
      eventCount = 1;
    } else if (roll < 85) {
      eventCount = 2;
    } else {
      eventCount = 3;
    }

    return shuffled.take(eventCount).toList();
  }
}