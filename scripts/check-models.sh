#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p .build/swift-cache
sources="native/Sources/DemoBrand.swift native/Sources/SessionHistory.swift native/Sources/PrototypeState.swift native/Sources/SampleData.swift native/Sources/WhatsAppData.swift"
# Fixed repository paths; no credentials, device IDs or signing team required.
xcrun swiftc -module-cache-path .build/swift-cache $sources native/Tests/main.swift -o .build/native-model-check
.build/native-model-check
xcrun swiftc -D WHATSAPP_DEMO -module-cache-path .build/swift-cache $sources native/Tests/WhatsApp/main.swift -o .build/whatsapp-model-check
.build/whatsapp-model-check
