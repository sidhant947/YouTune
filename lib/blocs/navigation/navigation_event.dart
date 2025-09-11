// lib/blocs/navigation/navigation_event.dart
part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class ShowSearch extends NavigationEvent {}

class ShowHome extends NavigationEvent {}
