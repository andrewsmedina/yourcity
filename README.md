# 🏙️ TaskbarCity

> *Sua cidade vive enquanto você trabalha.*

City builder **idle** que roda em uma janela fina ancorada na borda da tela
(estilo taskbar). A cidade cresce e funciona sozinha enquanto você faz outra
coisa; você intervém **construindo** zonas e serviços nos intervalos livres e
**resolvendo crises** quando elas aparecem.

- **Engine:** Godot 4
- **Plataformas:** Windows, Linux e macOS
- **Gênero:** Idle / City Builder / Taskbar Game
- **Dev:** solo

## Como funciona

A cidade gera receita passivamente; cinco indicadores — Segurança, Educação,
Saúde, Tráfego e Energia — decaem com o tempo e, combinados, formam a
**Felicidade**, que governa o crescimento ou encolhimento da população. Quando um
indicador cai demais, surge uma **crise** (Crime, Epidemia, Evasão Escolar,
Engarrafamento, Apagão) com uma notificação não-invasiva e 2–3 opções de resposta.
Não há *game over* súbito: ignorar uma crise degrada a cidade aos poucos, e tudo é
recuperável.

Veja o design completo em [`docs/GDD_TaskbarCity.md`](docs/GDD_TaskbarCity.md).

## Status

🚧 Em desenvolvimento inicial (beta `0.1`) — ainda sem build jogável.

O trabalho é acompanhado nas
[GitHub Issues](https://github.com/andrewsmedina/yourcity/issues) sob o milestone
[`0.1`](https://github.com/andrewsmedina/yourcity/milestone/1).

## Referências

SimCity 4 e Cities: Skylines (gameplay), Rusty's Retirement e TBH: Task Bar Hero
(formato taskbar), Mini Motorways e Townscaper (visual).
