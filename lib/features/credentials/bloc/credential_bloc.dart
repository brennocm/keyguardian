import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:atividade_01/features/credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/credentials/bloc/credential_state.dart';
import 'package:atividade_01/features/credentials/data/credential_provider.dart';
import 'package:atividade_01/core/models/credential_model.dart';

class CredentialBloc extends Bloc<CredentialEvent, CredentialState> {
  final CredentialProvider _provider;

  CredentialBloc({required CredentialProvider provider})
      : _provider = provider,
        super(CredentialInitial()) {
    
    on<LoadCredentials>(_onLoadCredentials);
    on<AddCredential>(_onAddCredential);
    on<UpdateCredential>(_onUpdateCredential);
    on<DeleteCredential>(_onDeleteCredential);
  }

  /// Carrega as credenciais descriptografadas
  Future<void> _onLoadCredentials(
    LoadCredentials event,
    Emitter<CredentialState> emit,
  ) async {
    emit(CredentialLoading());
    try {
      await emit.forEach(
        _provider.getCredentials(event.masterKey),
        onData: (List<CredentialModel> credentials) {
          return CredentialLoaded(credentials);
        },
        onError: (error, stackTrace) {
          return CredentialFailure(error.toString());
        },
      );
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }

  /// Adiciona uma nova credencial criptografada
  Future<void> _onAddCredential(
    AddCredential event,
    Emitter<CredentialState> emit,
  ) async {
    try {
      await _provider.addCredential(event.credential, event.masterKey);
      emit(CredentialOperationSuccess());
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }

  /// Atualiza uma credencial existente
  Future<void> _onUpdateCredential(
    UpdateCredential event,
    Emitter<CredentialState> emit,
  ) async {
    try {
      await _provider.updateCredential(event.credential, event.masterKey);
      emit(CredentialOperationSuccess());
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }

  /// Deleta uma credencial
  Future<void> _onDeleteCredential(
    DeleteCredential event,
    Emitter<CredentialState> emit,
  ) async {
    try {
      await _provider.deleteCredential(event.credentialId);
      emit(CredentialOperationSuccess());
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }
}
