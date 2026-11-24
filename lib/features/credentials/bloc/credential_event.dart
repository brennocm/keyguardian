import 'package:equatable/equatable.dart';
import 'package:atividade_01/core/models/credential_model.dart';
import 'package:atividade_01/core/crypto/vault_crypto.dart';

abstract class CredentialEvent extends Equatable {
  const CredentialEvent();

  @override
  List<Object> get props => [];
}

class LoadCredentials extends CredentialEvent {
  final VaultKey vaultKey;
  const LoadCredentials(this.vaultKey);

  @override
  List<Object> get props => [vaultKey];
}

class AddCredential extends CredentialEvent {
  final CredentialModel credential;
  final VaultKey vaultKey;

  const AddCredential(this.credential, this.vaultKey);

  @override
  List<Object> get props => [credential, vaultKey];
}

class UpdateCredential extends CredentialEvent {
  final CredentialModel credential;
  final VaultKey vaultKey;

  const UpdateCredential(this.credential, this.vaultKey);

  @override
  List<Object> get props => [credential, vaultKey];
}

class DeleteCredential extends CredentialEvent {
  final String credentialId;

  const DeleteCredential(this.credentialId);

  @override
  List<Object> get props => [credentialId];
}