import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:model/email/attachment.dart';

class GetEmailContentLoading extends LoadingState {}

class GetEmailContentSuccess extends UIState {
  final String htmlEmailContent;
  final List<Attachment>? attachments;
  final List<Attachment>? inlineImages;
  final Email? emailCurrent;

  GetEmailContentSuccess({
    required this.htmlEmailContent,
    this.attachments,
    this.inlineImages,
    this.emailCurrent
  });

  @override
  List<Object?> get props => [
    htmlEmailContent,
    attachments,
    inlineImages,
    emailCurrent
  ];
}

class GetEmailContentFromThreadCacheSuccess extends GetEmailContentSuccess {
  GetEmailContentFromThreadCacheSuccess({
    required super.htmlEmailContent,
    super.attachments,
    super.inlineImages,
    super.emailCurrent,
  });
}

class GetEmailContentFromCacheSuccess extends UIState {
  final String htmlEmailContent;
  final List<Attachment>? attachments;
  final List<Attachment>? inlineImages;
  final Email emailCurrent;

  GetEmailContentFromCacheSuccess({
    required this.htmlEmailContent,
    required this.emailCurrent,
    this.attachments,
    this.inlineImages,
  });

  @override
  List<Object?> get props => [
    htmlEmailContent,
    attachments,
    inlineImages,
    emailCurrent,
  ];
}

class LoadEmailContentCompleted extends UIState {}

class GetEmailContentFailure extends FeatureFailure {

  GetEmailContentFailure(dynamic exception, {super.onRetry})
    : super(exception: exception);
}