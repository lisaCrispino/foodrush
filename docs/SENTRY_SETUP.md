# FoodRush — Guia de Configuração do Sentry

## 1. Visão Geral

O **FoodRush** é um aplicativo Flutter de delivery que utiliza o **Sentry** como plataforma de monitoramento e observabilidade. Este documento detalha tudo que você precisa para configurar o ambiente, conectar o Sentry ao projeto e interpretar os dados coletados.

---

## 2. Dependências Necessárias

### pubspec.yaml

```yaml
dependencies:
  sentry_flutter: ^9.21.0  # SDK principal
  go_router: ^14.0.0        # Navegação (compatível com SentryNavigatorObserver)
  flutter_riverpod: ^2.5.1  # Gerenciamento de estado
  dio: ^5.7.0               # HTTP client (integrado ao Sentry)
  google_fonts: ^6.2.0      # Tipografia Poppins
  flutter_animate: ^4.5.0   # Animações declarativas
  shimmer: ^3.0.0           # Loading skeleton
  cached_network_image: ^3.3.0
  shared_preferences: ^2.3.0
  intl: ^0.19.0
  badges: ^3.1.2
  smooth_page_indicator: ^1.2.0
  uuid: ^4.4.0
```

Instalar:
```bash
flutter pub get
```

---

## 3. Criar Conta e Projeto no Sentry

1. Acesse [https://sentry.io](https://sentry.io) e crie uma conta gratuita.
2. Clique em **Create Project**.
3. Selecione a plataforma **Flutter**.
4. Dê um nome ao projeto (ex: `foodrush`).
5. Clique em **Create Project**.
6. Você será redirecionado para a página de configuração — anote o **DSN** exibido.

O DSN tem o formato:
```
https://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX@oYYYYYY.ingest.sentry.io/ZZZZZZZ
```

---

## 4. Configurar o DSN no Projeto

Abra `lib/main.dart` e substitua `'SEU_DSN_AQUI'` pelo DSN copiado:

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'https://sua_chave@o123.ingest.sentry.io/456';
    // ... demais opções
  },
  appRunner: () => runApp(...),
);
```

> **Segurança:** Para projetos em produção, use variáveis de ambiente:
> ```dart
> options.dsn = const String.fromEnvironment('SENTRY_DSN');
> ```
> E compile com:
> ```bash
> flutter run --dart-define=SENTRY_DSN=https://...
> ```

---

## 5. Configuração Android

### android/app/build.gradle

```groovy
android {
    defaultConfig {
        // ...
        minSdkVersion 21  // Requisito mínimo do Sentry Flutter
    }
}
```

O `sentry_flutter` adiciona automaticamente as permissões de Internet necessárias.

### Para Release builds com ProGuard

No arquivo `android/app/proguard-rules.pro`:
```
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**
```

---

## 6. Configuração iOS

No `ios/Runner/Info.plist`, nenhuma configuração adicional é necessária para o SDK básico.

Para **crash handling nativo** (padrão, já habilitado), o Sentry usa a API nativa do iOS automaticamente.

### Minimum Deployment Target

Certifique-se que o `ios/Podfile` tem:
```ruby
platform :ios, '13.0'
```

---

## 7. Funcionalidades Implementadas

### 7.1 Inicialização (`lib/main.dart`)

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'SEU_DSN_AQUI';
    options.tracesSampleRate = 1.0;        // 100% das transações monitoradas
    options.profilesSampleRate = 1.0;      // Profiling (iOS/macOS alpha)
    options.attachScreenshot = true;       // Screenshot automático em erros
    options.attachViewHierarchy = true;    // View hierarchy em erros
    options.environment = kReleaseMode ? 'production' : 'development';
    options.debug = kDebugMode;
    options.sendDefaultPii = true;         // Captura IP e dados de usuário
    options.maxBreadcrumbs = 150;          // Últimas 150 ações do usuário
    options.autoSessionTracking = true;    // Rastreia sessões automaticamente
  },
  appRunner: () => runApp(
    ProviderScope(child: SentryWidget(child: FoodRushApp())),
  ),
);
```

**SentryWidget** captura erros de renderização do Flutter que não seriam capturados pelo Dart Zone. É obrigatório envolver a raiz do app.

### 7.2 Rastreamento de Rotas (`lib/core/router/app_router.dart`)

```dart
GoRouter(
  observers: [SentryNavigatorObserver()],
  routes: [...],
)
```

Cada navegação entre telas cria automaticamente uma **transaction** no Sentry com:
- Nome da rota
- Tempo de carregamento (Time to Initial Display)
- Breadcrumb de navegação

### 7.3 Monitoramento HTTP (`lib/core/network/dio_client.dart`)

```dart
dio.httpClientAdapter = SentryHttpClientAdapter(
  captureFailedRequests: true,
  networkTracing: true,
  failedRequestStatusCodes: [SentryStatusCode.range(400, 599)],
);
```

Monitora automaticamente:
- URLs e métodos de todas as requisições
- Status codes de resposta
- Tempo de resposta de cada request
- Erros de rede (timeout, sem conexão)

### 7.4 Contexto de Usuário (`lib/data/repositories/auth_repository.dart`)

```dart
await Sentry.configureScope(
  (scope) => scope.setUser(
    SentryUser(id: user.id, email: user.email, username: user.name),
  ),
);
```

Após o login, **todos os eventos** são associados ao usuário logado. No dashboard do Sentry você verá quais usuários foram afetados por cada erro.

O logout limpa o contexto:
```dart
await Sentry.configureScope((scope) => scope.setUser(null));
```

### 7.5 Breadcrumbs (`lib/core/monitoring/sentry_service.dart`)

Trilha cronológica de ações do usuário, incluída automaticamente em cada evento de erro:

| Ação | Categoria | Onde |
|---|---|---|
| Tela inicial aberta | navigation | HomeScreen |
| Restaurante visualizado | navigation | RestaurantDetailScreen |
| Item adicionado ao carrinho | cart | CartRepository |
| Item removido do carrinho | cart | CartRepository |
| Carrinho visualizado | cart | CartScreen |
| Login realizado | auth | AuthRepository |
| Logout | auth | AuthRepository |
| Pedido iniciado | checkout | CheckoutScreen |
| Pedido realizado | order | OrderRepository |
| Status do pedido atualizado | order | OrderRepository |
| Erro de teste disparado | debug | ProfileScreen |

### 7.6 Performance Transactions

Transações de performance criadas manualmente:

| Transaction | Operation | Onde |
|---|---|---|
| `auth.login` | user | AuthRepository.login() |
| `auth.register` | user | AuthRepository.register() |
| `load.restaurants` | db | RestaurantRepository.getRestaurants() |
| `load.menu` | db | RestaurantRepository.getMenuItems() |
| `checkout.place_order` | task | OrderRepository.placeOrder() |

Cada transaction contém **spans** filho para etapas individuais:
- `validate.credentials` → `save.session`
- `fetch.list` (dentro de load.restaurants)
- `validate.order` → `save.order`

### 7.7 Captura Manual de Exceções

Em qualquer ponto da aplicação:
```dart
try {
  // operação crítica
} catch (e, st) {
  await SentryService.captureException(e, stackTrace: st, hint: 'contexto');
  rethrow;
}
```

Na tela de Perfil há um **botão de teste** que dispara um erro controlado para demonstração.

---

## 8. Visualizando Dados no Dashboard Sentry

### 8.1 Erros e Issues
- Menu: **Issues**
- Veja erros agrupados por fingerprint
- Clique em um issue para ver: stack trace, breadcrumbs, contexto do usuário, screenshot, view hierarchy

### 8.2 Performance
- Menu: **Performance**
- Filtre por transaction name (ex: `checkout.place_order`)
- Analise p50, p95, p99 de latência
- Identifique gargalos em spans específicos

### 8.3 Sessões e Crash-free Rate
- Menu: **Releases**
- Veja a taxa de sessões sem crash
- Compare entre versões do app

### 8.4 Usuários Afetados
- Nos detalhes de um issue, clique na aba **Users**
- Veja quais usuários foram impactados
- Filtre por email ou userId

---

## 9. Alertas e Notificações

### Configurar alerta de nova regressão
1. Vá em **Alerts > Create Alert**
2. Tipo: **Issue Alert**
3. Condição: "A new issue is created"
4. Ação: Enviar email / Slack / PagerDuty

### Alerta de degradação de performance
1. Tipo: **Metric Alert**
2. Métrica: `transaction.duration`
3. Threshold: `p95 > 2000ms`
4. Filtre por transaction: `checkout.place_order`

---

## 10. Upload de Source Maps (Dart Obfuscation)

Para builds obfuscados (`--obfuscate --split-debug-info`), suba os símbolos para o Sentry para legibilidade das stack traces:

```bash
# Instalar Sentry CLI
npm install -g @sentry/cli

# Upload de debug symbols (após build)
sentry-cli debug-files upload \
  --org SUA_ORG \
  --project foodrush \
  build/app/outputs/symbols/
```

Ou use o `sentry_dart_plugin` no `pubspec.yaml`:
```yaml
dev_dependencies:
  sentry_dart_plugin: ^1.8.0
```

E configure o `sentry.properties`:
```properties
auth.token=SEU_AUTH_TOKEN
org=SUA_ORG
project=foodrush
upload_debug_symbols=true
upload_sources=true
```

---

## 11. Boas Práticas Implementadas

| Prática | Implementação |
|---|---|
| Não vaze PII em logs | Breadcrumbs não incluem senhas |
| Sampling em produção | `tracesSampleRate: 1.0` (ajuste para 0.1–0.2 em alto volume) |
| Contexto de usuário | Sempre setado após login, limpo no logout |
| Transações com spans | Granularidade para identificar gargalos |
| Hints em exceções | Facilita triagem de erros no dashboard |
| Environment | Separa eventos dev/production |

---

## 12. Comandos Úteis

```bash
# Instalar dependências
flutter pub get

# Rodar em modo debug
flutter run

# Build de release para Android
flutter build apk --release

# Build com obfuscação (recomendado para produção)
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Analisar código
flutter analyze

# Rodar testes
flutter test
```

---

## 13. Estrutura de Arquivos do Projeto

```
lib/
├── main.dart                         ← SentryFlutter.init
├── app.dart                          ← MaterialApp.router
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── router/app_router.dart        ← SentryNavigatorObserver
│   ├── theme/app_theme.dart
│   ├── network/dio_client.dart       ← SentryHttpClientAdapter
│   └── monitoring/sentry_service.dart ← Wrapper da API Sentry
├── data/
│   ├── models/                       ← user, restaurant, menu_item, cart_item, order, category
│   ├── datasources/mock_data.dart    ← Dados para demonstração
│   └── repositories/                 ← Transações Sentry em cada repositório
└── features/
    ├── splash/                        ← Auto-navegação baseada em auth
    ├── auth/                          ← Login/Register + user context Sentry
    ├── home/                          ← Lista de restaurantes com shimmer
    ├── restaurant/                    ← Cardápio + adicionar ao carrinho
    ├── cart/                          ← Carrinho com swipe-to-delete
    ├── checkout/                      ← Transaction checkout.place_order
    ├── order/                         ← Tracking animado + histórico
    └── profile/                       ← Botão de teste de erro Sentry
```

---

## 14. Troubleshooting

### Eventos não aparecem no Sentry
- Verifique se o DSN está correto em `main.dart`
- Confirme que o dispositivo tem acesso à internet
- No modo debug, use `options.debug = true` para ver logs do SDK

### Screenshots não aparecem
- Certifique-se que `options.attachScreenshot = true`
- Screenshots requerem `SentryWidget` envolvendo o app

### Performance transactions não aparecem
- `tracesSampleRate` deve ser `> 0`
- Certifique-se de chamar `await transaction.finish()` sempre (inclusive no catch)

### Erro "SentryHttpClientAdapter not found"
- Verifique que está usando `sentry_flutter` (não `sentry` puro)
- O adapter está disponível apenas no pacote Flutter

---

*Gerado para o projeto FoodRush — Monitoramento e Observabilidade com Sentry*
