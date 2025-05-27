docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_PROXY=edge \
  -e KC_HOSTNAME=da16-68-65-246-83.ngrok-free.app \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_HOSTNAME_STRICT_HTTPS=false \
  quay.io/keycloak/keycloak:26.1.1 start-dev