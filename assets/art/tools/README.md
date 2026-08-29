# Ferramenta da prova de personagens

`build_character_prototype.py` transforma a fonte aprovada em um protótipo técnico reproduzível.

Ambiente validado:

- Python 3.12.13
- Pillow 12.3.0, fixado em `requirements.txt`

Exemplo a partir da raiz do repositório:

```powershell
python assets/art/tools/build_character_prototype.py `
  --input assets/art/source/personagens_conceito_simplificado.png `
  --sprites assets/art/characters/prototypes/personagens_se_48px_16c.png `
  --preview assets/art/qa/personagens_se_48px_16c_zoom8.png `
  --palette assets/art/palette/paleta_sertao_16.png `
  --scene assets/art/qa/cena_atual_base.png `
  --scene-test assets/art/qa/teste_personagens_cena_atual_145x.png
```

O script não usa rede, não altera arquivos da engine e escreve somente nos caminhos fornecidos.
