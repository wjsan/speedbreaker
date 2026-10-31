# SpeedBreaker + InsertPlay (ISO PAL-ES dublada)

Scripts deste fork (`wjsan/speedbreaker`) para rodar o SpeedBreaker com uma ISO
**PAL espanhola modificada** (dublagem) em um SD card do
[InsertPlay](https://github.com/wjsan/insertplay), mantendo os saves do Xenia.
Ficam numa pasta própria, para o *Sync fork* com o upstream nunca dar conflito.

## Por que é preciso

- O instalador oficial só aceita o `default.xex` USA (`aebdf3c1…`) e PAL-ES
  (`aad15fc2…`) e verifica os 49 arquivos. A ISO dublada altera o xex
  (`684ceef9…`), os vídeos `*_spanish_pal.wmv` e `NFS/zzdata0/5/9.bin` e `zdir.bin`.
- O xex dublado tem o **mesmo layout de código do PAL-ES** (CRT, entry point
  `8262E960`). O runtime escolhe o código recompilado pelo SHA-256 do xex;
  `patch-xex-hash.sh` troca o hash PAL-ES gravado em `lib/SpeedBreaker` pelo
  do xex dublado, e o jogo roda com o código PAL-ES.
- Passando o xex direto ao `speedbreaker.sh` (modo "XEX on the command line"),
  o runtime não exige o instalador.
- Idioma `spanish` = vídeos `_pal` e falas `copspeech_sp`, ou seja, a dublagem.

## Arquivos

| Script | O que faz |
|---|---|
| `update-speedbreaker.sh <dir> [--tag vX.Y.Z]` | Baixa a release oficial (verifica o sha256), extrai por cima de `<dir>` mantendo `data/`, `cache/` e `portable.txt`, e reaplica o patch. |
| `patch-xex-hash.sh <dir> [default.xex]` | Aplica só o patch do hash (idempotente). |
| `extract-xiso.py <iso> <dir>` | Extrai a ISO (XISO ou Redump completa) para `<dir>`. |
| `import-xenia-save.sh <xenia-title-dir> <dir>` | Converte saves do Xenia (`content/<perfil>/454107D9`) para `data/save-pal-es/`. |
| `insertplay-start.sh` | Lançador do SD card do InsertPlay (com o guard de GUID). |

## Montar do zero (SD card do InsertPlay)

```sh
SD="/run/media/$USER/Need for Speed M"   # raiz do SD (ext4/btrfs; nunca FAT/exFAT/NTFS)
SB="$SD/speedbreaker"

./update-speedbreaker.sh "$SB"                  # release oficial
touch "$SB/portable.txt"                        # tudo dentro de speedbreaker/
./extract-xiso.py game.iso "$SB/data/game"      # ~6,4 GB
./patch-xex-hash.sh "$SB"
./import-xenia-save.sh ".../Xenia/content/<perfil>/454107D9" "$SB"   # opcional
cp insertplay-start.sh "$SD/" && chmod +x "$SD/insertplay-start.sh"
```

Na primeira execução, ajuste `language = "spanish"` em `[game]` de
`$SB/data/settings.toml` (ou use `NFSMW_LANGUAGE=spanish`).

Mantenha `shortcut-identity.json`, `steam-shortcut.json`, `libraryfolder.vdf`,
`steam-artwork/`, `autorun.sh`, `insertplay-guid-guard.sh` e `install-shortcut.sh`
do SD: assim o atalho da Steam (mesmo GUID) continua valendo.

Espaço: release (~200 MB) + jogo (~6,4 GB) + cache/logs ≈ 7 GB; cabe num SD de 8 GB.

## Atualizar

1. No GitHub, *Sync fork* em `wjsan/speedbreaker` (ou `git pull upstream main`).
2. `git pull` no clone e, com o jogo fechado:

```sh
./insertplay/update-speedbreaker.sh "/run/media/$USER/Need for Speed M/speedbreaker"
```

Saves, configurações e o jogo extraído ficam intactos. Se uma versão futura
mudar como o hash é guardado, o script para com erro em vez de corromper nada.
