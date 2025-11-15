import 'package:equatable/equatable.dart';
import 'package:atividade_01/core/models/credential_model.dart';

abstract class CredentialState extends Equatable {
  const CredentialState();

  @override
  List<Object> get props => [];
}

// Estado inicial, BLoC acabou de começar
class CredentialInitial extends CredentialState {}

// Estado de "Carregando..." 
class CredentialLoading extends CredentialState {}

// Estado de sucesso: Lista carregada
class CredentialLoaded extends CredentialState {
  final List<CredentialModel> credentials;

  const CredentialLoaded(this.credentials);

  @override
  List<Object> get props => [credentials];
}

// Estado de sucesso: Operação (Add, Update, Delete) 
class CredentialOperationSuccess extends CredentialState {}

// Estado de falha: Algo deu errado
class CredentialFailure extends CredentialState {
  final String error;

  const CredentialFailure(this.error);

  @override
  List<Object> get props => [error];
}