/// Minimal typed result used by repositories and use cases.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, {this.error});
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;
  String? get messageOrNull =>
      this is Failure<T> ? (this as Failure<T>).message : null;
}
