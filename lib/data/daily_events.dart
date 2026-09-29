import '../models/daily_event.dart';

const dailyEvents = <DailyEvent>[
  DailyEvent(
    id: 'hot_weather',
    title: '今天很热',
    description: '天气越来越热了，很多人想买水。',
    type: 'market',
  ),
  DailyEvent(
    id: 'rainy_day',
    title: '今天下雨',
    description: '外面下着雨，街上的人少了一些。',
    type: 'market',
  ),
  DailyEvent(
    id: 'nearby_store_closed',
    title: '附近的商店今天关门',
    description: '附近一家小店今天没有营业。',
    type: 'business',
  ),
  DailyEvent(
    id: 'fresh_bread',
    title: '面包很受欢迎',
    description: '今天很多客人都在问面包。',
    type: 'market',
  ),
  DailyEvent(
    id: 'quiet_morning',
    title: '今天早上很安静',
    description: '街上的人不多，附近也比较安静。',
    type: 'normal',
  ),
  DailyEvent(
    id: 'busy_street',
    title: '今天街上很热闹',
    description: '附近今天人很多。',
    type: 'business',
  ),
];