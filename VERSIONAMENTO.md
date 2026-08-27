# Convenção de versionamento

## Sequência

O projeto começa em `V.0.1.0`. O último número avança a cada entrega concluída:

`V.0.1.0` → `V.0.1.1` → … → `V.0.1.9` → `V.0.2.0`

O mesmo padrão continua nas séries seguintes. Enquanto o jogo estiver em
protótipo, o primeiro número permanece em `0`.

## Fechamento de uma alteração de código

Ao concluir uma alteração:

1. atualizar `VERSION` e `application/config/version` em `project.godot`;
2. exibir a versão atual no protótipo;
3. registrar a entrega no `CHANGELOG.md`;
4. criar o commit com título e descrição;
5. criar uma tag Git anotada usando exatamente a mesma versão.

## Formato do commit

**Título**

```text
V.0.1.0 — Resumo curto da entrega
```

**Descrição**

```text
- mudança principal realizada
- comportamento adicionado ou corrigido
- verificação executada e limitações conhecidas
```

Cada versão corresponde, portanto, a um commit e a uma tag que podem ser usados
como ponto de retorno.
