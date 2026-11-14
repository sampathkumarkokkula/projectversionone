import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/media/image_processor.dart';
import '../../data/remote/supabase_backend.dart';
import '../../domain/lock_service.dart';
import '../../domain/message_service.dart';
import '../../domain/ports.dart';
import '../../domain/session_establisher.dart';

String formatClock(BuildContext context, int epochMs) {
  final time = DateTime.fromMillisecondsSinceEpoch(epochMs);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
  );
}

/// Short timestamp for the chat list: time today, otherwise the date.
String formatListTime(BuildContext context, int epochMs) {
  final time = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final now = DateTime.now();
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return formatClock(context, epochMs);
  }
  return MaterialLocalizations.of(context).formatShortMonthDay(time);
}

/// User-facing text for an error. Never includes server payloads or secrets.
String describeError(Object error) {
  if (error is PasswordPolicyException) return error.message;
  if (error is UsernameTakenException) return 'That username is already taken.';
  if (error is SelfChatException) return 'That is your own username.';
  if (error is UsernameChangeTooSoonException) return 'You can change your username once every 24 hours.';
  if (error is AccountSuspendedException) {
    return 'This account was suspended after spam reports and can no longer send messages.';
  }
  if (error is EmailBlockedException) return 'This e-mail address can\'t be used with BVM.';
  if (error is ChatBlockedException) return 'Unblock this person to send messages.';
  if (error is UnsupportedImageException) return 'This picture format isn\'t supported. Try a JPEG or PNG.';
  if (error is ArgumentError && '${error.message}'.contains('image too large')) {
    return 'This photo is too large to send.';
  }
  if (error is PeerGoneException) return 'This person deleted their account.';
  if (error is PeerUnavailableException) return 'This person cannot receive messages right now. Try again later.';
  if (error is DeviceReplacedException) {
    return 'Your account is active on another phone. Use that phone, or uninstall BVM here to erase it.';
  }
  if (error is StateError && error.message.contains('different account')) {
    return 'That code belongs to a different account.';
  }
  if (error is AuthException) {
    final code = error.code ?? '';
    if (code.contains('otp_expired') || error.message.toLowerCase().contains('expired')) {
      return 'That code is wrong or has expired. Request a new one.';
    }
    if (error.statusCode == '429' || code.contains('rate_limit')) {
      return 'Too many requests. Wait a minute and try again.';
    }
    if (error.message.contains('cannot be used')) return 'This e-mail address can\'t be used with BVM.';
    return 'Sign-in failed. Check the code and try again.';
  }
  if (error is SocketException || error.toString().contains('SocketException')) {
    return 'No connection. Check your internet connection and try again.';
  }
  if (error is PostgrestException) return 'The server rejected the request. Try again later.';
  return 'Something went wrong. Try again.';
}
