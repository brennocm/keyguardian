import 'package:equatable/equatable.dart';
import 'package:atividade_01/core/models/credential_model.dart';

abstract class CredentialEvent extends Equatable {
  const CredentialEvent();

  @override
  List<Object> get props => [];
}

class LoadCredentials extends CredentialEvent {
  final String masterKey;
  const LoadCredentials(this.masterKey);

  @override
  List<Object> get props => [masterKey];
}

class AddCredential extends CredentialEvent {
  final CredentialModel credential;
  final String masterKey;

  const AddCredential(this.credential, this.masterKey);

  @override
  List<Object> get props => [credential, masterKey];
}

class UpdateCredential extends CredentialEvent {
  final CredentialModel credential;
  final String masterKey;

  const UpdateCredential(this.credential, this.masterKey);

  @override
  List<Object> get props => [credential, masterKey];
}

class DeleteCredential extends CredentialEvent {
  final String credentialId;

  const DeleteCredential(this.credentialId);

  @override
  List<Object> get props => [credentialId];
}