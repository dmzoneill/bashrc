#!/bin/bash

# Redhatter - Red Hat VPN/OTP/token service
export REDHATTER_API_URL="http://localhost:8009"
export REQUESTS_CA_BUNDLE="/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
export NODE_EXTRA_CA_CERTS="$REQUESTS_CA_BUNDLE"
export LOG_LEVEL="INFO"
