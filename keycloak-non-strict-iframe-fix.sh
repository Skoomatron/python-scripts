docker run --rm -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_PROXY=edge \
  -e KC_HOSTNAME=da16-68-65-246-83.ngrok-free.app \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME_STRICT_HTTPS=false \
  -e KC_HTTP_RELATIVE_PATH=/ \
  -e KC_SPI_THEME_DEFAULT=keycloak \
  -e KC_THEME_CACHE_THEMES=false \
  -e KC_THEME_CACHE_TEMPLATES=false \
  -e KC_FRAME_OPTIONS=ALLOWALL \
  quay.io/keycloak/keycloak:26.1.1 start-dev
