# 🛡️ RAPPORT D'AUDIT DE SÉCURITÉ WHITE-HAT (SAST)
**Application :** Bayan (بَيَان) — Shazam for Holy Qur'an  
**Identifiant de bundle :** `tools.rea.Bayan`  
**Cible :** iOS 17.0+ / iPadOS / macOS (Catalyst)  
**Méthodologie :** Analyse Statique de Sécurité Applicative (SAST) & Référentiel OWASP Mobile Application Security (MASVS v2.0)  
**Statut du Build :** Production Milestone Release v1.1.100 (Build #100)  
**Date :** 24 Octobre 2026  

---

## 📋 1. RÉSUMÉ EXÉCUTIF & MATRICE DES RISQUES

L'audit de sécurité approfondi du code source de l'application **Bayan** a permis d'analyser l'intégralité des flux d'ingestion de données, les mécanismes cryptographiques, la persistance locale et distante (iCloud), ainsi que les surfaces d'attaque réseau et logique métier.

### Matrice Synthétique des Vulnérabilités Identifiées

| ID | Catégorie | Niveau de Risque | Référence CWE | Fichier Cible | Statut |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **VULN-01** | Injection & Assainissement | **ÉLEVÉ** | CWE-91 / CWE-79 | `Services/BayanCastService.swift` | ✅ Corrigé & Validé |
| **VULN-02** | Validation d'Entrée Deep Link | **MOYEN** | CWE-20 / CWE-1284 | `Views/MainTabView.swift` | ✅ Corrigé & Validé |
| **VULN-03** | Stockage en Clair de Données | **MOYEN** | CWE-312 / CWE-359 | `Models/QuranSyncManager.swift` | ✅ Corrigé & Validé |
| **VULN-04** | Intégrité des Licences & IAP | **ÉLEVÉ** | CWE-603 / CWE-312 | `Services/TipJarService.swift` | ✅ Corrigé & Validé |
| **VULN-05** | Logique Métier & Débit (DoS) | **ÉLEVÉ** | CWE-770 / CWE-400 | `Services/QuranAudioDownloadService.swift` | ✅ Corrigé & Validé |
| **VULN-06** | Réseau Local & CORS Permissif | **ÉLEVÉ** | CWE-942 / CWE-306 | `Services/BayanCastService.swift` | ✅ Corrigé & Validé |

---

## 🔍 2. ANALYSE DÉTAILLÉE DES VULNÉRABILITÉS & CORRECTIFS

### [VULN-01] Injection SOAP/XML & Cross-Site Scripting (XSS) dans le Moteur de Cast DLNA/Web
- **Type de vulnérabilité :** XML/SOAP Parameter Injection (CWE-91) & Unescaped HTML/XSS (CWE-79)
- **Localisation :** `Services/BayanCastService.swift` (Lignes 326–337 et 484–520)
- **Code Vulnérable :**
```swift
// Concaténation brute dans l'enveloppe XML SOAP :
let soapBody = """
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <s:Body>
    <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
      <CurrentURI>\(audioUrl.absoluteString)</CurrentURI>
      <CurrentURIMetaData></CurrentURIMetaData>
    </u:SetAVTransportURI>
  </s:Body>
</s:Envelope>
"""

// Interpolation HTML sans échappement d'entités :
let html = """
...
<title>Bayan Cast • \(surahName)</title>
<h1>\(surahArabic)</h1>
<p>\(reciterName)</p>
...
"""
```
- **Scénario d'Attaque :**
  1. **Injection SOAP / SSRF :** L'URL audio est directement interpolée dans l'enveloppe XML UPnP sans validation d'entités. Si une métadonnée ou une URL de redirection contient des délimiteurs XML (`</CurrentURI><CurrentURI>http://attacker-controlled.lan/malicious.mp3</CurrentURI>`), le parseur SOAP exécute une injection de paramètres, pouvant mener à du Server-Side Request Forgery (SSRF) sur des équipements multimédia du réseau local.
  2. **XSS Réfléchi :** Le serveur HTTP embarqué injecte les variables de texte sans encodage HTML. Une chaîne contenant `"><script>alert(document.cookie)</script>` est interprétée directement par tout navigateur consultant le lecteur web local.
- **Correctif White-Hat :**
```swift
extension String {
    public var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    public var htmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

// Utilisation sécurisée :
let safeUri = audioUrl.absoluteString.xmlEscaped
let safeSurah = surahName.htmlEscaped
let safeReciter = reciterName.htmlEscaped
```

---

### [VULN-02] Absence de Bornage des Paramètres sur les Liens Profonds (`bayan://`)
- **Type de vulnérabilité :** Improper Input Validation & Array Out-of-Bounds (CWE-20 / CWE-1284)
- **Localisation :** `Views/MainTabView.swift` (Lignes 230–239)
- **Code Vulnérable :**
```swift
let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
let surahIdStr = components?.queryItems?.first(where: { $0.name == "id" || $0.name == "surah" })?.value
let ayahIdStr = components?.queryItems?.first(where: { $0.name == "ayah" })?.value

if let sId = Int(surahIdStr ?? ""), let surah = QuranDataService.shared.surah(for: sId) {
    let aId = Int(ayahIdStr ?? "") ?? 1
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        AudioPlayerService.shared.play(surah: surah, ayah: aId)
    }
}
```
- **Scénario d'Attaque :**  
  Un acteur malveillant peut diffuser un lien profond forgé (`bayan://surah?id=1&ayah=999999` ou `ayah=-50`) via un message ou un QR code piégé. Bien que `sId` soit vérifié par `surah(for:)`, `aId` n'est pas borné par rapport au nombre total de versets de la sourate (`surah.totalAyahs`), entraînant des requêtes CDN invalides en boucle, des désynchronisations de widgets ou des crashs d'indexation mémoire.
- **Correctif White-Hat :**
```swift
if let sId = Int(surahIdStr ?? ""),
   (1...114).contains(sId),
   let surah = QuranDataService.shared.surah(for: sId) {
    let rawAyah = Int(ayahIdStr ?? "") ?? 1
    // Borner strictement entre 1 et le nombre maximal de versets
    let safeAyah = max(1, min(rawAyah, surah.totalAyahs))
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        AudioPlayerService.shared.play(surah: surah, ayah: safeAyah)
    }
}
```

---

### [VULN-03] Persistance en Clair de l'Historique de Reconnaissance Audio dans `UserDefaults`
- **Type de vulnérabilité :** Cleartext Storage of Sensitive User Activity in Local Plist (CWE-312 / CWE-359)
- **Localisation :** `Models/QuranSyncManager.swift` (Lignes 76–86)
- **Code Vulnérable :**
```swift
private func saveHistory() {
    if let encoded = try? JSONEncoder().encode(recentRecognitions) {
        UserDefaults.standard.set(encoded, forKey: historyStorageKey)
    }
}
```
- **Scénario d'Attaque :**  
  Tandis que les marque-pages et l'historique de prières ont été sécurisés par chiffrement matériel AES-256-GCM, l'historique complet de reconnaissance acoustique Shazam/Speech est écrit au format JSON non chiffré dans le fichier `.plist` de l'application. En cas d'extraction de sauvegarde non chiffrée ou d'accès physique sur appareil déverrouillé, l'activité de récitation et les métadonnées de l'utilisateur sont exposées.
- **Correctif White-Hat :**
```swift
private let encryptedFileName = "bayan_recognition_history.enc"

private func saveHistory() {
    do {
        let data = try JSONEncoder().encode(recentRecognitions)
        try BayanDataEncryptionService.shared.encrypt(data: data, toFileNamed: encryptedFileName)
    } catch {
        #if DEBUG
        print("⚠️ Échec du chiffrement de l'historique : \(error)")
        #endif
    }
}

private func loadHistory() {
    if let decryptedData = try? BayanDataEncryptionService.shared.decrypt(fromFileNamed: encryptedFileName),
       let decoded = try? JSONDecoder().decode([RecognitionResult].self, from: decryptedData) {
        self.recentRecognitions = decoded
        return
    }

    // Migration transparente depuis UserDefaults si données héritées
    if let legacyData = UserDefaults.standard.data(forKey: historyStorageKey),
       let decoded = try? JSONDecoder().decode([RecognitionResult].self, from: legacyData) {
        self.recentRecognitions = decoded
        saveHistory()
        UserDefaults.standard.removeObject(forKey: historyStorageKey)
        return
    }

    self.recentRecognitions = [RecognitionResult.sample]
}
```

---

### [VULN-04] Falsification des Droits In-App Purchase (IAP) via `UserDefaults` Modifiable
- **Type de vulnérabilité :** Client-Side Entitlement Tampering & Improper Authorization (CWE-603 / CWE-312)
- **Localisation :** `Services/TipJarService.swift` (Lignes 29–37)
- **Code Vulnérable :**
```swift
public var isSupporter: Bool {
    get { UserDefaults.standard.bool(forKey: "bayan_is_supporter") }
    set { UserDefaults.standard.set(newValue, forKey: "bayan_is_supporter") }
}
```
- **Scénario d'Attaque :**  
  L'état de bienfaiteur/supporter repose sur un simple booléen dans `UserDefaults.standard`. Sur un appareil sideloadé ou jailbreaké, un attaquant peut modifier `bayan_is_supporter` à `true` via Filza, un tweak ou un fichier `.plist` modifié, sans jamais valider une transaction signée Apple (JWS) auprès de StoreKit 2.
- **Correctif White-Hat :**
```swift
private let kKeychainSupporterKey = "bayan_secure_is_supporter"
private let kKeychainTierKey = "bayan_secure_supporter_tier"

public var isSupporter: Bool {
    get {
        return BayanKeychainService.shared.getString(forKey: kKeychainSupporterKey) == "1"
    }
    set {
        BayanKeychainService.shared.set(string: newValue ? "1" : "0", forKey: kKeychainSupporterKey)
        UserDefaults.standard.removeObject(forKey: "bayan_is_supporter")
    }
}

@MainActor
public func verifyActiveEntitlements() async {
    var hasValidEntitlement = false
    var verifiedTier = ""

    for await result in Transaction.currentEntitlements {
        guard case .verified(let transaction) = result else { continue }
        if Self.productIdentifiers.contains(transaction.productID) && transaction.revocationDate == nil {
            hasValidEntitlement = true
            verifiedTier = transaction.productID
        }
    }

    self.isSupporter = hasValidEntitlement
    if hasValidEntitlement {
        BayanKeychainService.shared.set(string: verifiedTier, forKey: kKeychainTierKey)
    }
}
```

---

### [VULN-05] Boucle de Téléchargement Massive Non Étranglée & Saturation Réseau
- **Type de vulnérabilité :** Uncontrolled Resource Consumption & Connection Flooding (CWE-770 / CWE-400)
- **Localisation :** `Services/QuranAudioDownloadService.swift` (Lignes 81–92)
- **Code Vulnérable :**
```swift
// Déclenchement simultané de tous les versets d'une sourate
for ayah in 1...surah.totalAyahs {
    if localAudioUrl(reciterId: reciter.id, surah: surah.id, ayah: ayah) != nil {
        continue
    }
    if let remoteUrl = reciter.audioUrl(surah: surah.id, ayah: ayah) {
        let task = urlSession.downloadTask(with: remoteUrl)
        taskToSurahKey[task.taskIdentifier] = (reciter.id, surah.id, ayah, surah.totalAyahs)
        task.resume()
    }
}
```
- **Scénario d'Attaque :**  
  Pour une sourate volumineuse (ex. Sourate Al-Baqarah avec 286 versets), la méthode instancie **286 tâches de téléchargement HTTP simultanées** en une fraction de seconde vers les serveurs CDN (`everyayah.com`).  
  1. Les CDN Cloudflare interprètent ce pic comme une attaque par déni de service distribué (DDoS Layer 7) ou du scraping agressif et bannissent temporairement l'IP cliente (**HTTP 429 Too Many Requests**).
  2. Épuisement des sockets réseau et pic mémoire sur l'iPhone.
  3. Risque de corruption mémoire car `taskToSurahKey` est modifié sans synchronisation de thread.
- **Correctif White-Hat :**
```swift
private let maxConcurrentDownloads = 3
private var pendingDownloadQueue: [(reciter: Reciter, surah: Surah, ayah: Int)] = []
private var activeDownloadCount = 0
private let queueLock = NSLock()

public func downloadSurah(_ surah: Surah, reciter: Reciter) {
    let key = "\(reciter.id)_\(surah.id)"
    guard !activeDownloads.contains(key) else { return }

    activeDownloads.insert(key)
    downloadProgress[key] = 0.05

    queueLock.lock()
    for ayah in 1...surah.totalAyahs {
        if localAudioUrl(reciterId: reciter.id, surah: surah.id, ayah: ayah) == nil {
            pendingDownloadQueue.append((reciter, surah, ayah))
        }
    }
    queueLock.unlock()

    processNextQueuedDownloads()
}

private func processNextQueuedDownloads() {
    queueLock.lock()
    defer { queueLock.unlock() }

    while activeDownloadCount < maxConcurrentDownloads && !pendingDownloadQueue.isEmpty {
        let item = pendingDownloadQueue.removeFirst()
        guard let remoteUrl = item.reciter.audioUrl(surah: item.surah.id, ayah: item.ayah) else { continue }

        activeDownloadCount += 1
        let task = urlSession.downloadTask(with: remoteUrl)
        taskToSurahKey[task.taskIdentifier] = (item.reciter.id, item.surah.id, item.ayah, item.surah.totalAyahs)
        task.resume()
    }
}
```

---

### [VULN-06] Absence d'Authentification & CORS Wildcard (`*`) sur le Serveur Web Cast Embarqué
- **Type de vulnérabilité :** Permissive Cross-Origin Resource Sharing (CORS) Misconfiguration (CWE-942) & Missing Authentication (CWE-306)
- **Localisation :** `Services/BayanCastService.swift` (Lignes 425–473)
- **Code Vulnérable :**
```swift
if path.hasPrefix("/api/status") {
    return generateStatusJSONResponse()
} else if path.hasPrefix("/api/toggle") {
    AudioPlayerService.shared.togglePlayPause()
    return generateStatusJSONResponse()
}

// En-tête permissif dans generateStatusJSONResponse :
let headers = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\n...\r\n\r\n"
```
- **Scénario d'Attaque :**  
  Le serveur local `NWListener` écoute sur `0.0.0.0:8088`. En raison de l'en-tête `Access-Control-Allow-Origin: *` et de l'absence totale de jeton d'authentification :
  1. **Prise de contrôle à distance par CSRF :** Tout site web visité par l'utilisateur sur son iPhone ou un ordinateur du même réseau local peut exécuter un script JavaScript en arrière-plan (`fetch("http://192.168.1.X:8088/api/toggle")`) pour commander la lecture audio sans consentement.
  2. **Fuite de vie privée sur le réseau local :** Tout équipement connecté au même Wi-Fi peut sonder `/api/status` en continu pour surveiller la sourate et le verset en cours de récitation.
- **Correctif White-Hat :**
```swift
private var sessionAccessToken: String = UUID().uuidString.prefix(8).lowercased()

public func startWebCastServer() {
    guard webListener == nil else { return }
    self.sessionAccessToken = UUID().uuidString.prefix(8).lowercased()
    refreshLocalIP()
    // ...
}

private func processHTTPRequest(_ request: String) -> Data {
    let firstLine = request.components(separatedBy: "\r\n").first ?? ""
    let parts = firstLine.components(separatedBy: " ")
    guard parts.count >= 2 else { return "HTTP/1.1 400 Bad Request\r\n\r\n".data(using: .utf8)! }

    let rawPath = parts[1]
    guard let components = URLComponents(string: rawPath) else {
        return "HTTP/1.1 400 Bad Request\r\n\r\n".data(using: .utf8)!
    }

    let path = components.path
    let token = components.queryItems?.first(where: { $0.name == "token" })?.value

    // Contrôle d'accès strict sur l'API de commande
    if path.hasPrefix("/api/") {
        guard token == sessionAccessToken else {
            return "HTTP/1.1 401 Unauthorized\r\nContent-Type: text/plain\r\n\r\nAccès refusé : Jeton de session requis.".data(using: .utf8)!
        }

        if path.hasPrefix("/api/status") {
            return generateStatusJSONResponse()
        } else if path.hasPrefix("/api/toggle") {
            DispatchQueue.main.async { AudioPlayerService.shared.togglePlayPause() }
            return generateStatusJSONResponse()
        } else if path.hasPrefix("/api/next") {
            DispatchQueue.main.async { AudioPlayerService.shared.nextAyah() }
            return generateStatusJSONResponse()
        } else if path.hasPrefix("/api/prev") {
            DispatchQueue.main.async { AudioPlayerService.shared.previousAyah() }
            return generateStatusJSONResponse()
        }
    }

    return generateHTMLWebPlayerResponse()
}
```

---

## 🛡️ 3. COUCHES DE SÉCURITÉ DÉJÀ VALIDÉES EN PRODUCTION (BUILD #100)

L'application intègre d'ores et déjà un ensemble de défenses de pointe validées lors du Build #100 :
1. **Épinglage de Certificat SSL/TLS (SPKI SHA-256) :** Toutes les connexions sortantes vers les CDN et APIs sont protégées contre les proxys MITM (Burp, Charles, Proxyman) via `BayanSecureNetworkSession`.
2. **Chiffrement Matériel AES-256-GCM :** Les marque-pages (`BookmarkService`), sessions de compte (`BayanAuthService`) et historiques de prière (`PrayerTrackerService`) sont chiffrés avec une clé maître gérée par la Secure Enclave.
3. **Floutage de Confidentialité GPS (Grid ~11 km) :** Les coordonnées CoreLocation sont quantifiées à 0,1° décimal par `BayanLocationPrivacyGuard`, masquant le domicile de l'utilisateur tout en maintenant une précision de Qibla à < 0,02°.
4. **Détection d'Intégrité & Anti-Reverse Engineering :** Sondes silencieuses de détection de jailbreak, analyse de table d'images Mach-O (`_dyld_get_image_name` pour Frida/Cycript) et détection de débogueur via `sysctl(P_TRACED)` dans `BayanRuntimeIntegrityGuard`.
5. **App Attest & Intégrité de Conteneur :** Validation dynamique du Bundle ID (`tools.rea.Bayan`) et génération de clés cryptographiques matérielles via `DCAppAttestService`.
6. **Verrouillage Biométrique & Écran de Confidentialité :** Verrouillage par Face ID / Touch ID et masque d'occultation automatique lors du passage en arrière-plan (App Switcher).

---

## 📱 4. TÉLÉCHARGEMENT DU PAQUET TESTÉ (IPA)

- **Version :** `v1.1.100` (Build #100)
- **Fichier IPA direct :** [Bayan_v1.1.100.ipa](https://github.com/RAIKO05/BAYAN/releases/download/v1.1.100/Bayan_v1.1.100.ipa)
- **Lien Universel :** [Bayan.ipa](https://github.com/RAIKO05/BAYAN/releases/download/v1.1.100/Bayan.ipa)
- **Publication GitHub :** [Release v1.1.100 sur GitHub](https://github.com/RAIKO05/BAYAN/releases/tag/v1.1.100)
