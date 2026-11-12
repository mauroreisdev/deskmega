#!/bin/bash
# DeskMEGA: transforma o rustdesk-<versão>.deb gerado pelo build.py em deskmega-<versão>.deb.
# O código Linux usa o nome do app em minúsculas (APP_NAME = DeskMEGA -> "deskmega") para o
# serviço systemd, o arquivo .desktop e para achar os processos "--server"/"--tray", então o
# executável, o serviço e os atalhos precisam se chamar "deskmega".
set -euo pipefail
IN="$1"     # ex.: rustdesk-1.5.3.deb
OUT="$2"    # ex.: DeskMEGA-1.5.3-amd64.deb
W=$(mktemp -d)
dpkg-deb -R "$IN" "$W"

mv "$W/usr/share/rustdesk" "$W/usr/share/deskmega"
mv "$W/usr/share/deskmega/rustdesk" "$W/usr/share/deskmega/deskmega"
mv "$W/usr/share/deskmega/files/systemd/rustdesk.service" "$W/usr/share/deskmega/files/systemd/deskmega.service"
mv "$W/usr/share/icons/hicolor/256x256/apps/rustdesk.png" "$W/usr/share/icons/hicolor/256x256/apps/deskmega.png"
mv "$W/usr/share/icons/hicolor/scalable/apps/rustdesk.svg" "$W/usr/share/icons/hicolor/scalable/apps/deskmega.svg"
mv "$W/usr/share/applications/rustdesk.desktop" "$W/usr/share/applications/deskmega.desktop"
mv "$W/usr/share/applications/rustdesk-link.desktop" "$W/usr/share/applications/deskmega-link.desktop"

sed -i 's/RustDesk/DeskMEGA/g; s/rustdesk/deskmega/g' \
  "$W/usr/share/deskmega/files/systemd/deskmega.service" \
  "$W/usr/share/applications/deskmega.desktop" \
  "$W/usr/share/applications/deskmega-link.desktop" \
  "$W"/DEBIAN/postinst "$W"/DEBIAN/prerm "$W"/DEBIAN/postrm "$W"/DEBIAN/preinst
# textos do atalho em português
sed -i 's/^GenericName=Remote Desktop/GenericName=Suporte remoto/; s/^Comment=Remote Desktop/Comment=Suporte remoto MegaWifi/; s/^Name=Open a New Window/Name=Abrir nova janela/; s/teamviewer;//' \
  "$W/usr/share/applications/deskmega.desktop"

# arquivo de controle do pacote
sed -i 's/^Package: rustdesk$/Package: deskmega/; s/^Maintainer: .*/Maintainer: MegaWifi <noreply@megawifi.com.br>/; s|^Homepage: .*|Homepage: https://deskmega.megawifi.com.br|; s/^Description: .*/Description: DeskMEGA - suporte remoto da MegaWifi/' \
  "$W/DEBIAN/control"
grep -q '^Package: deskmega$' "$W/DEBIAN/control"

# nada de "rustdesk" visível sobrando nos arquivos de texto do pacote
if grep -rIl 'rustdesk' "$W/DEBIAN" "$W/usr/share/applications" "$W/usr/share/deskmega/files" ; then
  echo "ERRO: ainda há 'rustdesk' nos arquivos acima"; exit 1
fi

( cd "$W" && find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -0 md5sum > DEBIAN/md5sums )
dpkg-deb --root-owner-group -b "$W" "$OUT"
rm -rf "$W"
dpkg-deb -I "$OUT"
dpkg-deb -c "$OUT" | grep -v '/data/flutter_assets/' | head -40
