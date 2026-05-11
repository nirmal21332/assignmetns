import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assignments/constants/app_colors.dart';
import 'package:assignments/services/quote_service.dart';

class QuoteCard extends StatelessWidget {
  final AsyncValue<Quote> quoteState;
  final VoidCallback onRefresh;

  const QuoteCard({
    super.key,
    required this.quoteState,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: quoteState.when(
        data: (quote) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: AppColors.primaryColor,
                  size: 24.w,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                    size: 22.w,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(4.w),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '"${quote.quote}"',
              style: TextStyle(
                fontSize: 15.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '— ${quote.author}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 24.w,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                    size: 22.w,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.all(4.w),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Unable to load quote',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tap refresh to try again',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
