# KeyGuardian - O Cofre Digital para Suas Senhas

KeyGuardian é um aplicativo móvel desenvolvido com Flutter que serve como um cofre de senhas seguro e intuitivo. Este projeto foi finalizado e implementa um fluxo completo de gerenciamento de credenciais com autenticação segura e criptografia.

## 🚀 Funcionalidades Implementadas

O aplicativo conta com as seguintes funcionalidades, organizadas por módulos:

*   **Autenticação (`auth`):**
    *   **Tela de Boas-vindas:** Ponto de partida com opções de login e cadastro.
    *   **Login e Cadastro:** Autenticação de usuários utilizando Firebase Auth.
    *   **Recuperação de Senha:** Fluxo para redefinição de senha via e-mail.
    *   **Perfil do Usuário:** Visualização e gerenciamento de dados da conta.

*   **Segurança (`master_key`):**
    *   **Chave Mestra:** Camada adicional de segurança. O usuário deve criar e validar uma chave mestra para acessar o cofre, garantindo que apenas o proprietário tenha acesso aos dados sensíveis.

*   **Cofre de Credenciais (`credentials`):**
    *   **Home:** Listagem de todas as credenciais salvas.
    *   **Adicionar Credencial:** Formulário para salvar novos logins e senhas.
    *   **Detalhes da Credencial:** Visualização segura e edição de informações de login.

*   **Ferramentas (`generator`):**
    *   **Gerador de Senhas:** Utilitário para criar senhas fortes e customizáveis (tamanho, caracteres especiais, números, etc.).

## 🏛️ Estrutura do Projeto

O projeto adota uma arquitetura baseada em **Features** (Funcionalidades), facilitando a manutenção e escalabilidade. A estrutura de pastas em `lib/` é organizada da seguinte forma:

*   **`lib/features/`**: Contém os módulos principais da aplicação.
    *   **`auth/`**: Telas e lógica de autenticação (Login, Cadastro, Perfil).
    *   **`credentials/`**: Gerenciamento das credenciais (Home, Adicionar, Detalhes).
    *   **`master_key/`**: Lógica e telas relacionadas à Chave Mestra.
    *   **`generator/`**: Funcionalidade do Gerador de Senhas.
*   **`lib/main.dart`**: Ponto de entrada da aplicação, configuração do Firebase e temas.

Cada feature geralmente segue uma subdivisão interna como `view` (telas e widgets), `bloc`/`controller` (gerenciamento de estado) e `data` (repositórios e models).

## 🛠️ Tecnologias Utilizadas

*   **Flutter:** Framework principal para desenvolvimento UI.
*   **Firebase:**
    *   **Authentication:** Gerenciamento de usuários.
    *   **Firestore:** Banco de dados NoSQL para armazenamento das credenciais (criptografadas).
*   **Gerenciamento de Estado:** Utilização de **Bloc/Cubit** para controle de estado reativo e previsível.
*   **Segurança:**
    *   **flutter_secure_storage:** Armazenamento seguro local.
    *   **encrypt:** Criptografia de dados sensíveis antes do envio ao banco.

## 🚀 Como Executar o Projeto

Para rodar este projeto em sua máquina local:

1.  **Pré-requisitos:** Certifique-se de ter o Flutter SDK instalado e configurado.
2.  **Clone o repositório:**
    ```bash
    git clone https://github.com/brennocm/keyguardian.git
    cd keyguardian
    ```
3.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```
4.  **Configuração do Firebase:** o repositório traz a configuração do projeto Firebase original (`lib/firebase_options.dart` e `android/app/google-services.json`). Para usar o seu próprio projeto, crie um no console do Firebase com Authentication (e-mail e senha) e Firestore, e gere os arquivos de novo:
    ```bash
    dart pub global activate flutterfire_cli
    flutterfire configure
    ```
5.  **Execute o aplicativo:**
    ```bash
    flutter run
    ```

## Licença

[MIT](LICENSE)
