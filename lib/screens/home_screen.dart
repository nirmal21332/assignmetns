import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:assignments/constants/app_colors.dart';
import 'package:assignments/models/task_model.dart';
import 'package:assignments/providers/auth_provider.dart';
import 'package:assignments/providers/task_provider.dart';
import 'package:assignments/providers/quote_provider.dart';
import 'package:assignments/widgets/task_card.dart';
import 'package:assignments/widgets/quote_card.dart';
import 'package:assignments/widgets/empty_state.dart';
import 'package:assignments/screens/add_edit_task_screen.dart';
import 'package:assignments/screens/login_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('HomeScreen: Building widget tree...');
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          debugPrint('HomeScreen: User is null, redirecting to login...');
          return const LoginScreen();
        }

        final userId = user.uid;
        debugPrint('HomeScreen: Authenticated user: $userId');

        final tasksAsync = ref.watch(userTasksStreamProvider(userId));
        final quoteState = ref.watch(quoteNotifierProvider);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceColor,
            elevation: 0,
            title: Text(
              'Task Manager',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: AppColors.textSecondary,
                  size: 24.w,
                ),
                onPressed: () => _handleLogout(context, ref),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              debugPrint('HomeScreen: Refreshing tasks and quote...');
              ref.invalidate(userTasksStreamProvider(userId));
              ref.read(quoteNotifierProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Quote Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h, left: 16.w, right: 16.w),
                    child: QuoteCard(
                      quoteState: quoteState,
                      onRefresh: () =>
                          ref.read(quoteNotifierProvider.notifier).refresh(),
                    ),
                  ),
                ),

                // Task List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    child: Text(
                      'Your Tasks',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // Task List
                tasksAsync.when(
                  data: (tasks) {
                    debugPrint('HomeScreen: Received ${tasks.length} tasks');
                    if (tasks.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.task_outlined,
                          title: 'No Tasks Yet',
                          subtitle:
                              'Tap the + button to create your first task',
                          buttonText: 'Add Task',
                          onButtonPressed: () => _navigateToAddTask(context),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final task = tasks[index];
                        return TaskCard(
                          key: ValueKey(task.id),
                          task: task,
                          onToggleComplete: () =>
                              _toggleTaskCompletion(context, ref, userId, task),
                          onEdit: () => _navigateToEditTask(context, task),
                          onDelete: () =>
                              _showDeleteDialog(context, ref, userId, task),
                        );
                      }, childCount: tasks.length),
                    );
                  },
                  loading: () {
                    debugPrint('HomeScreen: Loading tasks...');
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  error: (error, stack) {
                    debugPrint('HomeScreen: Error loading tasks: $error');
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48.w,
                                color: AppColors.errorColor,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Error loading tasks',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                error.toString().contains('permission-denied')
                                    ? 'Access denied. Please ensure you are logged in.'
                                    : 'Please check your internet connection and try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton.icon(
                                onPressed: () => ref.invalidate(
                                  userTasksStreamProvider(userId),
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddTask(context),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            icon: Icon(Icons.add, size: 24.w),
            label: Text(
              'Add Task',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
      loading: () {
        debugPrint('HomeScreen: Auth loading...');
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, _) {
        debugPrint('HomeScreen: Auth error: $error');
        return const LoginScreen();
      },
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddEditTaskScreen()));
  }

  void _navigateToEditTask(BuildContext context, TaskModel task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)));
  }

  void _toggleTaskCompletion(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TaskModel task,
  ) async {
    try {
      await ref
          .read(taskNotifierProvider(userId).notifier)
          .toggleTaskCompletion(task);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TaskModel task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(taskNotifierProvider(userId).notifier)
                    .deleteTask(task.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
