import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/shimmer_loading.dart';
import 'package:retro_route/model/notification_model.dart';
import 'package:retro_route/repository/notification_repo.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/notification_view_model/notification_view_model.dart';

class NotificationView extends ConsumerStatefulWidget {
  const NotificationView({super.key});

  @override
  ConsumerState<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends ConsumerState<NotificationView> {
  bool _hasMarkedAsRead = false;

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80.sp,
            color: Colors.grey[900],
          ),
          verticalSpacer(height: 16.h),
          customText(
            text: "No notifications",
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
          verticalSpacer(height: 8.h),
          customText(
            text: "Your notifications will appear here",
            fontSize: 15.sp,
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Fetch notifications on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authNotifierProvider).value?.data?.token;
      if (token != null) {
        ref.read(notificationsProvider.notifier).fetchNotifications(token);
      }
    });
  }

  Future<void> _markUnreadAsRead(List<NotificationModel> notifications) async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null) return;

    List<NotificationModel> updatedNotifications = List.from(notifications);
    bool hasChanges = false;

    for (int i = 0; i < updatedNotifications.length; i++) {
      if (!updatedNotifications[i].isRead) {
        try {
          await ref.read(notificationRepoProvider).markNotificationAsRead(
            notificationId: updatedNotifications[i].id,
            token: token,
          );
          // Create updated notification
          updatedNotifications[i] = NotificationModel(
            id: updatedNotifications[i].id,
            userId: updatedNotifications[i].userId,
            title: updatedNotifications[i].title,
            message: updatedNotifications[i].message,
            isRead: true,
            createdAt: updatedNotifications[i].createdAt,
            updatedAt: DateTime.now(),
            version: updatedNotifications[i].version,
            metadata: updatedNotifications[i].metadata,
          );
          hasChanges = true;
        } catch (e) {
          // Handle error, maybe log or show toast
        }
      }
    }

    if (hasChanges) {
      // Update the state
      ref
          .read(notificationsProvider.notifier)
          .replaceNotifications(updatedNotifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final token = ref.watch(authNotifierProvider).value?.data?.token;

    // Listen for notifications load and mark unread as read
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasValue && !_hasMarkedAsRead) {
        _markUnreadAsRead(next.value!);
        _hasMarkedAsRead = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
        title: customText(
          text: "Notifications",
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        centerTitle: true,
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final deleteCallback = token == null
                  ? null
                  : () async {
                      await ref
                          .read(notificationsProvider.notifier)
                          .deleteNotification(notification.id, token);
                    };
              return Dismissible(
                key: ValueKey(notification.id),
                direction: deleteCallback != null
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.w),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.white, size: 28.sp),
                ),
                onDismissed: (_) => deleteCallback?.call(),
                child: _NotificationCard(
                  notification: notification,
                  onDelete: deleteCallback,
                ),
              );
            },
          );
        },
        loading: () {
          if (token == null) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: 6, // show 6 fake shimmering notification cards
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: const ShimmerNotificationCard(),
            ),
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              customText(
                text: "Failed to load notifications",
                fontSize: 18.sp,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
              verticalSpacer(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  final token = ref.read(authNotifierProvider).value?.data?.token;
                  if (token != null) {
                    ref.read(notificationsProvider.notifier).fetchNotifications(token);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: customText(
                  text: "Retry",
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500, color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDelete;

  const _NotificationCard({required this.notification, this.onDelete});

  void _handleTap(BuildContext context) {
    final meta = notification.metadata;
    if (meta == null) return;
    final screen = meta['screen'] as String?;
    final orderId = meta['orderId'] as String?;
    if (screen == null) return;

    switch (screen) {
      case 'CrateApproval':
        goRouter.push('${AppRoutes.crateApproval}?orderId=$orderId');
        break;
      case 'PoolReport':
        goRouter.push('${AppRoutes.poolReport}?orderId=$orderId');
        break;
      case 'OrderHistory':
        goRouter.push(AppRoutes.orderHistory);
        break;
      case 'DriverDeliveries':
      case 'DriverOrderDetail':
        goRouter.push(AppRoutes.driverHome);
        break;
    }
  }

  String _timeAgo(DateTime utcTime) {
    final local = utcTime.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = notification.metadata?['screen'] != null;

    return GestureDetector(
      onTap: hasAction ? () => _handleTap(context) : null,
      child: Card(
      color: notification.isRead ? AppColors.cardBgColor : Colors.blue[50],
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Stack(
        children: [
        Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: customText(
                    text: notification.title,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            verticalSpacer(height: 8.h),
            customText(
              text: notification.message,
              fontSize: 14.sp,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
              maxLine: 3,
              textFlow: TextOverflow.ellipsis,
            ),
            verticalSpacer(height: 12.h),
            customText(
              text: _timeAgo(notification.createdAt),
              fontSize: 12.sp,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            if (hasAction) ...[
              verticalSpacer(height: 8.h),
              Row(
                children: [
                  Icon(Icons.arrow_forward_ios,
                      size: 12.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  customText(
                    text: 'Tap to view',
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
          if (onDelete != null)
            Positioned(
              bottom: 10.h,
              right: 10.w,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.btnColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 26.sp, color: AppColors.btnColor),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}