import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:assignments/constants/app_colors.dart';
import 'package:assignments/models/task_model.dart';
import 'package:assignments/utils/validators.dart';
import 'package:assignments/widgets/custom_text_field.dart';
import 'package:assignments/widgets/custom_button.dart';
import 'package:assignments/providers/auth_provider.dart';
import 'package:assignments/providers/task_provider.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isCompleted = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.date;
      _isCompleted = widget.task!.isCompleted;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to save a task.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // For new tasks we pass Timestamp.now() as a placeholder; the
      // FirestoreService will overwrite it with FieldValue.serverTimestamp()
      // before the write reaches Firestore.
      final task = TaskModel(
        id: _isEditing ? widget.task!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        isCompleted: _isCompleted,
        createdAt: _isEditing ? widget.task!.createdAt : Timestamp.now(),
      );

      if (_isEditing) {
        await ref
            .read(taskNotifierProvider(user.uid).notifier)
            .updateTask(task);
      } else {
        await ref.read(taskNotifierProvider(user.uid).notifier).addTask(task);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Task updated successfully'
                  : 'Task added successfully',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is already logged in TaskNotifier; surface it to the user.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary, size: 24.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'Add Task',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                hintText: 'Enter task title',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.title),
                validator: Validators.validateTaskTitle,
              ),
              SizedBox(height: 16.h),

              // Description Field
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Enter task description (optional)',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                prefixIcon: const Icon(Icons.description_outlined),
                validator: Validators.validateTaskDescription,
              ),
              SizedBox(height: 16.h),

              // Date Picker
              Text(
                'Due Date',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.inputFillColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryColor,
                        size: 20.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          dateFormat.format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Completion Status Toggle (only for editing)
              if (_isEditing) ...[
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.inputFillColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _isCompleted
                            ? AppColors.completedColor
                            : AppColors.pendingColor,
                        size: 24.w,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _isCompleted
                              ? AppColors.completedColor
                              : AppColors.pendingColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isCompleted,
                        onChanged: (value) {
                          setState(() => _isCompleted = value);
                        },
                        activeThumbColor: AppColors.completedColor,
                        activeTrackColor: AppColors.completedColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],

              // Save Button
              CustomButton(
                text: _isEditing ? 'Update Task' : 'Add Task',
                onPressed: _handleSave,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
