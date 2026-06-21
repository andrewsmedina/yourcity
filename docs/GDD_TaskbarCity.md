# Game Design Document — TaskbarCity

**Versão:** 0.1 Beta  
**Engine:** Godot 4  
**Gênero:** Idle / City Builder / Taskbar Game  
**Plataforma:** PC — Windows, Linux e macOS  
**Dev:** Solo

---

## Conceito

TaskbarCity é um city builder idle que roda em uma janela fina na borda da tela. A cidade cresce e funciona sozinha enquanto o jogador trabalha ou faz outra coisa. O jogador intervém em dois momentos: **proativamente**, construindo e melhorando zonas/serviços nos intervalos livres, e **reativamente**, tomando decisões rápidas quando crises aparecem (segurança, educação, saúde, tráfego, energia).

**Frase de pitch:** *"Sua cidade vive enquanto você trabalha."*

---

## Loop Principal

```
Cidade gera receita passivamente
        ↓
Jogador constrói/melhora zonas quando quer (proativo)
        ↓
Indicadores decaem com o tempo → crises surgem
        ↓
Jogador recebe notificação não-invasiva
        ↓
Jogador toma decisão rápida (ou deixa degradar)
        ↓
Cidade reage e evolui
        ↓
(repete)
```

Dois ritmos coexistem: o **idle** (deixar rodar, intervenção mínima) e o **ativo** (abrir a janela expandida e planejar a cidade). O jogo nunca tem "game over" silencioso — ignorar crises degrada a cidade lentamente, mas sempre é recuperável.

---

## Sistemas

### 1. Economia
- A cidade gera **Dinheiro** passivamente baseado em população e zonas ativas.
- Gastos fixos mensais: serviços públicos, salários de funcionários, manutenção.
- Saldo positivo = crescimento; saldo negativo = deterioração gradual (indicadores caem mais rápido).

### 2. Zonas (construção ativa)
O jogador desbloqueia slots de construção conforme a cidade evolui e decide o que colocar em cada slot.

| Zona | Função | Custo base | Efeito |
|------|--------|-----------|--------|
| Residencial | Gera população | $500 | +pop/seg |
| Comercial | Gera receita fiscal | $800 | +$/seg |
| Industrial | Gera empregos e receita, mas polui | $1.000 | +$/seg, −Saúde |
| Serviços | Sustenta indicadores (escola, hospital, delegacia, usina) | $1.500 | +indicador específico |

Cada serviço amarra a um indicador: delegacia→Segurança, escola→Educação, hospital→Saúde, vias/transporte→Tráfego, usina→Energia.

### 3. Indicadores da Cidade
- **Segurança** (0–100): delegacias e iluminação.
- **Educação** (0–100): escolas e bibliotecas.
- **Saúde** (0–100): hospitais, saneamento; reduzido por indústria.
- **Tráfego** (0–100): estradas e transporte público.
- **Energia** (0–100): usinas e rede elétrica; **consumida** por todas as zonas — quanto mais cidade, mais energia exigida.
- **Felicidade** (0–100): média ponderada dos 5 indicadores acima.

### 4. Efeito da Felicidade (o número que importa)
Felicidade não é decorativa — ela governa a dinâmica populacional e a receita:

| Felicidade | Efeito |
|-----------|--------|
| ≥ 70 | Imigração: população cresce mais rápido, bônus de receita |
| 40–69 | Estável |
| < 40 | Emigração: população encolhe, receita cai |

Manter Felicidade alta é o objetivo de médio prazo que conecta todos os outros sistemas.

### 5. Sistema de Crises
Crises aparecem quando um indicador cai abaixo de um limiar. O jogador recebe uma notificação e pode responder na hora ou deixar a crise degradar a cidade aos poucos (sem morte súbita).

| Crise | Gatilho | Consequência se ignorada |
|-------|---------|--------------------------|
| Onda de Crimes | Segurança < 30 | Felicidade e população caem gradualmente |
| Epidemia | Saúde < 30 | Mortalidade sobe, receita cai gradualmente |
| Evasão Escolar | Educação < 30 | Produtividade/receita caem gradualmente |
| Engarrafamento | Tráfego < 30 | Receita comercial cai gradualmente |
| Apagão | Energia < 30 | Zonas afetadas ficam offline até religar; todos os indicadores caem devagar |

**Filosofia idle-friendly:** o "timer" não pune com falha instantânea. Ele marca a janela em que a resposta é mais barata/eficaz — agir cedo custa menos, agir tarde custa mais, mas nunca é tarde demais.

### 6. Decisões do Jogador
Quando uma crise aparece, o jogador escolhe entre 2–3 opções rápidas:

**Exemplo — Crise de Crime:**
- 🏛️ Construir nova delegacia (−$5.000, efeito permanente)
- 👮 Contratar mais policiais (−$1.000/mês, efeito temporário)
- 🔦 Instalar câmeras (−$2.000, efeito médio)

---

## Interface

### Janela Taskbar
- Largura: tela inteira horizontal.
- Altura: ~120px (modo idle) → expansível para ~300px (modo ativo / crise).
- Visual: pixel art, estilo retro.

### Comportamento por plataforma
A "janela fixa na borda" tem implementação diferente em cada SO — tratado explicitamente no beta:

| SO | Estratégia |
|----|-----------|
| Windows | Janela borderless, always-on-top, ancorada acima da taskbar (AppBar opcional pós-beta) |
| Linux | Janela borderless always-on-top; respeitar hints de WM (dock/strut quando suportado) |
| macOS | **Não há taskbar.** Janela borderless flutuante ancorada na borda inferior, acima do Dock, com nível de janela apropriado; ícone na **menu bar** para abrir/silenciar. Tratar permissões e comportamento de Spaces/fullscreen |

### Elementos visuais
- Skyline da cidade animada crescendo ao longo do tempo.
- Indicadores dos 5 sistemas em barrinhas coloridas + Felicidade em destaque.
- Ícone de notificação piscando quando há crise.
- Relógio da cidade (ciclo dia/noite).

### Notificações
- Toast popup sobre a taskbar (Windows/Linux) / sobre o Dock (macOS).
- Som suave opcional.
- Não invasivo — pode ser adiado/silenciado temporariamente.

---

## Progressão

### Fases da Cidade
| Fase | População | Desbloqueios |
|------|-----------|--------------|
| Vilarejo | 0–500 | Sistemas básicos, primeiros slots de construção |
| Cidade Pequena | 500–5.000 | Transporte público, mais slots |
| Cidade Média | 5.000–50.000 | Aeroporto, metrô |
| Metrópole | 50.000+ | Projetos especiais |

### Projetos Especiais (endgame)
- Parque tecnológico (boost de educação e renda).
- Cidade sustentável (boost de saúde e felicidade).
- Hub de transporte (resolve tráfego permanentemente).

---

## Balanceamento Base (provisório — ajustar no playtest)

Valores iniciais só para destravar o primeiro playtest do loop. Tudo sujeito a ajuste.

| Parâmetro | Valor inicial |
|-----------|--------------|
| Receita base por zona comercial | +$2/seg |
| População por zona residencial | +1 pop / 3 seg |
| Decaimento passivo de indicador | −1 ponto / 20 seg |
| Boost de serviço sobre indicador | +0,5 ponto/seg enquanto ativo |
| Limiar de crise | indicador < 30 |
| Consumo de energia | 1 unidade por zona ativa |
| Custo médio de decisão de crise | $1.000–$5.000 |

Escala de tempo alvo: uma "vida idle" deve dar pra acompanhar checando a cada 15–30 min sem perder a cidade.

---

## Monetização (futuro)
- Gratuito com opção de compra única no Steam.
- Sem anúncios, sem pay-to-win.
- DLCs cosméticos: temas visuais para a cidade (cyberpunk, medieval, etc.).

---

## Referências
- **Gameplay:** SimCity 4, Cities: Skylines.
- **Formato:** Rusty's Retirement, TBH: Task Bar Hero.
- **Visual:** Mini Motorways, Townscaper.

---

## Escopo do Beta
Ver todo list separado (`TaskbarCity_TodoList.jsx`).
