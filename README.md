# Consumo de Água

App de controle de consumo de água.

```text
lib/
  main.dart
  ui/
    splash.dart
    home.dart
    style/
      colors.dart
      theme.dart
  models/
    consumo.dart
  root/
    file.dart
```

## Como rodar

```bash
flutter pub get
flutter run
```

## O que cada tela faz

- `Splash` - ícone do app, switch de tema escuro e botão `Entrar`.
- `Home` - lista de registros de água com data, quantidade em ml e peso atual, botão `+` para cadastrar, lixeira para excluir e toque no item para editar. Abaixo da lista, um gráfico de consumo.

## Regras

- Meta diária = `35 ml × peso atual (kg)`.
- O total do dia soma os registros com a mesma data.
- Os dados são salvos localmente com `SharedPreferences`, funcionando no celular e no web.

## Observação

- O `assets/icon.png` usado na Splash precisa existir e estar declarado no `pubspec.yaml`.
