// lib/blocs/navigation/navigation_state.dart
part of 'navigation_bloc.dart';

class NavigationState extends Equatable {
  final bool isSearchVisible;

  const NavigationState({this.isSearchVisible = false});

  NavigationState copyWith({bool? isSearchVisible}) {
    return NavigationState(
      isSearchVisible: isSearchVisible ?? this.isSearchVisible,
    );
  }

  @override
  List<Object> get props => [isSearchVisible];
}
