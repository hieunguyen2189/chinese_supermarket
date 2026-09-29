import '../models/customer_review.dart';
import '../models/game_state.dart';

class CustomerReviewService {
  CustomerReview createDailyReview(GameState state) {
    final total = state.customerCount;

    if (total <= 0) {
      return CustomerReview(
        day: state.day,
        ratingTenths: 50,
        servedCustomers: 0,
        skippedCustomers: 0,
        totalCustomers: 0,
        comment: '今天没有顾客。',
      );
    }

    final served = state.servedCustomersToday;
    final skipped = state.skippedCustomersToday;

    final serviceRate = served / total;

    int rating;

    if (serviceRate >= 1.0) {
      rating = 50;
    } else if (serviceRate >= 0.9) {
      rating = 47;
    } else if (serviceRate >= 0.8) {
      rating = 45;
    } else if (serviceRate >= 0.7) {
      rating = 43;
    } else if (serviceRate >= 0.6) {
      rating = 40;
    } else if (serviceRate >= 0.5) {
      rating = 37;
    } else if (serviceRate >= 0.4) {
      rating = 34;
    } else {
      rating = 30;
    }

    String comment;

    if (rating >= 47) {
      comment = '今天服务很好，顾客都很满意。';
    } else if (rating >= 45) {
      comment = '今天的服务不错，大多数顾客都满意。';
    } else if (rating >= 40) {
      comment = '今天还不错，不过有一些顾客没有买到东西。';
    } else if (rating >= 35) {
      comment = '一些顾客觉得服务不够好。';
    } else {
      comment = '今天有不少顾客没有得到服务。';
    }

    return CustomerReview(
      day: state.day,
      ratingTenths: rating,
      servedCustomers: served,
      skippedCustomers: skipped,
      totalCustomers: total,
      comment: comment,
    );
  }

  void applyReview(
      GameState state,
      CustomerReview review,
      ) {
    state.customerReviews.insert(0, review);

    if (state.customerReviews.length > 30) {
      state.customerReviews.removeLast();
    }

    state.reviewCount++;

    if (state.reviewCount <= 1) {
      state.shopRatingTenths = review.ratingTenths;
    } else {
      final oldTotal =
          state.shopRatingTenths * (state.reviewCount - 1);

      state.shopRatingTenths =
          ((oldTotal + review.ratingTenths) /
              state.reviewCount)
              .round();
    }

    state.servedCustomersToday = 0;
    state.skippedCustomersToday = 0;
  }
}