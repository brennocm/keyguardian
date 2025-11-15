import 'package:flutter_bloc/flutter_bloc.dart';

// 1. Imports
import 'package:atividade_01/features/2_credentials/bloc/credential_event.dart';
import 'package:atividade_01/features/2_credentials/bloc/credential_state.dart';
import 'package:atividade_01/features/2_credentials/data/credential_provider.dart';
import 'package:atividade_01/core/models/credential_model.dart'; // Import necessário para o onData

class CredentialBloc extends Bloc<CredentialEvent, CredentialState> {
  
  final CredentialProvider _provider;
  // A variável _credentialsSubscription foi REMOVIDA

  CredentialBloc({required CredentialProvider provider})
      : _provider = provider,
        super(CredentialInitial()) {
    
    // 5. Registre os "handlers" para cada evento
    on<LoadCredentials>(_onLoadCredentials); // Esta função agora é async
    on<AddCredential>(_onAddCredential);
    on<UpdateCredential>(_onUpdateCredential);
    on<DeleteCredential>(_onDeleteCredential);
  }

  // --- MÉTODOS DE HANDLER ---

  // ⬇️⬇️ ESTE É O MÉTODO CORRIGIDO ⬇️⬇️
  Future<void> _onLoadCredentials(LoadCredentials event, Emitter<CredentialState> emit) async {
    emit(CredentialLoading());
    try {
      // 'emit.forEach' é a forma correta de "ouvir" um Stream
      // Ele gerencia a inscrição e o cancelamento automaticamente.
      await emit.forEach(
        _provider.getCredentials(), // O Stream que queremos ouvir
        onData: (List<CredentialModel> credentials) {
          // Para cada novo dado do Stream, emita o estado de sucesso
          return CredentialLoaded(credentials);
        },
        onError: (error, stackTrace) {
          // Se o Stream falhar, emita o estado de falha
          return CredentialFailure(error.toString());
        },
      );
    } catch (e) {
      // Se "ouvir" o Stream falhar (ex: provider falhou)
      emit(CredentialFailure(e.toString()));
    }
  }

  // Os outros handlers já estavam corretos
  Future<void> _onAddCredential(AddCredential event, Emitter<CredentialState> emit) async {
    try {
      // (TODO: Lógica de Criptografia vai aqui)
      await _provider.addCredential(event.credential);
      emit(CredentialOperationSuccess());
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }

  Future<void> _onUpdateCredential(UpdateCredential event, Emitter<CredentialState> emit) async {
    try {
      // (TODO: Lógica de Criptografia vai aqui)
      await _provider.updateCredential(event.credential);
      emit(CredentialOperationSuccess());
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }

  Future<void> _onDeleteCredential(DeleteCredential event, Emitter<CredentialState> emit) async {
    try {
      await _provider.deleteCredential(event.credentialId);
      emit(CredentialOperationSuccess());
    } catch (e) {
      emit(CredentialFailure(e.toString()));
    }
  }

  // O método 'close()' foi REMOVIDO
}