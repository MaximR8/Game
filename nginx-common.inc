# Réglages partagés par les deux écoutes (HTTP et HTTPS).
# ⛔ Extension .inc et pas .conf : les .conf de conf.d sont inclus
#    automatiquement par nginx, on se retrouverait avec un doublon.
#
# Une liste en double est une liste fausse : ce fichier existe pour
# que les deux server{} ne divergent jamais.

root /usr/share/nginx/html;
index index.html;

# Les .gz sont pré-compressés à l'export : 39 Mo -> 10 Mo,
# sans coût processeur par requête sur le NAS.
gzip_static on;

# 🔴 Jamais une vieille version : le navigateur REDEMANDE chaque fichier à chaque
# lancement (no-cache), et nginx répond « 304, inchangé » s'il n'a pas bougé
# (ETag, Last-Modified). Un réexport est donc vu tout de suite.
# ⛔ Plus de « no-store » (25/09) : il interdisait de garder quoi que ce soit, et
#    le téléphone retéléchargeait les 26 Mo du jeu à CHAQUE lancement.
etag on;
add_header Cache-Control "no-cache, must-revalidate" always;

location ~ \.wasm$ {
    default_type application/wasm;
    gzip_static on;
    add_header Cache-Control "no-cache, must-revalidate" always;
}

location / {
    try_files $uri $uri/ =404;
}
