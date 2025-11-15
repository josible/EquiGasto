import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();
  
  String get message;

  @override
  List<Object?> get props => [];
}

class ServerFailure extends Failure {
  @override
  final String message;

  const ServerFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  @override
  final String message;

  const NetworkFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  @override
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class NotFoundFailure extends Failure {
  @override
  final String message;

  const NotFoundFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ValidationFailure extends Failure {
  @override
  final String message;

  const ValidationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

