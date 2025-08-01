# Guide de test avec Postman - Web Service Relay

## 🚀 Installation et Configuration

### 1. Importer la collection

1. **Ouvrez Postman**
2. **Cliquez sur "Import"** (bouton en haut à gauche)
3. **Sélectionnez le fichier** `postman_collection.json`
4. **Cliquez sur "Import"**

### 2. Configurer les variables d'environnement

Dans Postman, allez dans **Environments** et créez un nouvel environnement :

```json
{
  "base_url": "http://localhost:8000",
  "societe": "rsp-bgs",
  "filename": "comptes_global_annee_2023.json"
}
```

## 📋 Tests étape par étape

### **Étape 1 : Vérifier le serveur**

#### Test 1.1 - Get Root Info
- **Méthode** : `GET`
- **URL** : `{{base_url}}/`
- **Attendu** : Informations sur l'API

**Réponse attendue** :
```json
{
  "message": "API MDM-FI avec WebSocket Relay",
  "version": "1.1.0",
  "features": [...],
  "endpoints": {...}
}
```

#### Test 1.2 - Get Relay Status
- **Méthode** : `GET`
- **URL** : `{{base_url}}/api/files/status`
- **Attendu** : Statut du relay

**Réponse attendue** :
```json
{
  "status": "ready",
  "societes_count": 3,
  "total_files": 45,
  "websocket_connections": 0,
  "last_update": "2023-12-19T10:30:00"
}
```

### **Étape 2 : Gestion des sociétés**

#### Test 2.1 - Get All Societes
- **Méthode** : `GET`
- **URL** : `{{base_url}}/api/files/societes`
- **Attendu** : Liste des sociétés disponibles

**Réponse attendue** :
```json
{
  "societes": ["rsp-bgs", "rsp-neg", "rsp-sb"]
}
```

#### Test 2.2 - Get Societe Files
- **Méthode** : `GET`
- **URL** : `{{base_url}}/api/files/societe/{{societe}}/files`
- **Attendu** : Fichiers de la société

**Réponse attendue** :
```json
{
  "societe": "rsp-bgs",
  "files": [
    {
      "filename": "comptes_global_annee_2023.json",
      "societe": "rsp-bgs",
      "size": 1024,
      "last_modified": "2023-12-19T10:30:00",
      "type_data": "comptes",
      "annee": "2023"
    }
  ]
}
```

### **Étape 3 : Upload de fichiers**

#### Test 3.1 - Upload JSON File
- **Méthode** : `POST`
- **URL** : `{{base_url}}/api/files/upload/{{societe}}`
- **Body** : `form-data`
- **Key** : `file`
- **Type** : `File`
- **Sélectionnez un fichier JSON**

**Fichier de test à créer** (`test_file.json`) :
```json
{
  "societe": "test-societe",
  "data": {
    "comptes": [
      {
        "numero": "601000",
        "intitule": "Achats de matières premières",
        "solde": 50000
      }
    ],
    "date_generation": "2023-12-19T10:30:00"
  }
}
```

**Réponse attendue** :
```json
{
  "message": "Fichier uploadé avec succès",
  "societe": "rsp-bgs",
  "filename": "test_file.json",
  "size": 245
}
```

### **Étape 4 : Download de fichiers**

#### Test 4.1 - Download JSON File
- **Méthode** : `GET`
- **URL** : `{{base_url}}/api/files/download/{{societe}}/{{filename}}`
- **Attendu** : Téléchargement du fichier JSON

### **Étape 5 : Synchronisation**

#### Test 5.1 - Sync Societe Files
- **Méthode** : `POST`
- **URL** : `{{base_url}}/api/files/sync/{{societe}}`
- **Attendu** : Synchronisation terminée

**Réponse attendue** :
```json
{
  "message": "Synchronisation terminée pour rsp-bgs",
  "societe": "rsp-bgs",
  "files_count": 15
}
```

### **Étape 6 : Suppression**

#### Test 6.1 - Delete File
- **Méthode** : `DELETE`
- **URL** : `{{base_url}}/api/files/delete/{{societe}}/{{filename}}`
- **Attendu** : Fichier supprimé

**Réponse attendue** :
```json
{
  "message": "Fichier supprimé avec succès"
}
```

## 🔧 Tests avancés

### **Test avec différentes sociétés**

1. **Changez la variable `societe`** :
   - `rsp-bgs`
   - `rsp-neg`
   - `rsp-sb`

2. **Testez chaque société** avec les mêmes endpoints

### **Test d'erreurs**

#### Test d'upload de fichier non-JSON
- **Méthode** : `POST`
- **URL** : `{{base_url}}/api/files/upload/{{societe}}`
- **Body** : Upload un fichier `.txt`
- **Attendu** : Erreur 400

#### Test de société inexistante
- **Méthode** : `GET`
- **URL** : `{{base_url}}/api/files/societe/societe-inexistante/files`
- **Attendu** : Erreur 404

#### Test de fichier inexistant
- **Méthode** : `GET`
- **URL** : `{{base_url}}/api/files/download/{{societe}}/fichier-inexistant.json`
- **Attendu** : Erreur 404

## 📊 Tests de performance

### **Test d'upload multiple**

1. **Créez plusieurs fichiers JSON** de différentes tailles
2. **Upload séquentiel** : Testez l'upload de 10 fichiers
3. **Upload parallèle** : Testez l'upload simultané

### **Test de download multiple**

1. **Téléchargez plusieurs fichiers** en parallèle
2. **Vérifiez les temps de réponse**
3. **Testez avec des fichiers volumineux**

## 🧪 Tests de validation

### **Validation des données JSON**

1. **Upload un fichier JSON valide**
2. **Upload un fichier JSON invalide**
3. **Vérifiez les réponses**

### **Validation des noms de fichiers**

1. **Testez avec des caractères spéciaux**
2. **Testez avec des espaces**
3. **Testez avec des accents**

## 📝 Scripts de test automatiques

### **Script Pre-request (optionnel)**

```javascript
// Générer un nom de fichier unique
pm.environment.set("timestamp", new Date().getTime());
pm.environment.set("unique_filename", "test_" + pm.environment.get("timestamp") + ".json");
```

### **Script de test (optionnel)**

```javascript
// Vérifier le statut de la réponse
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

// Vérifier le contenu de la réponse
pm.test("Response has required fields", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('message');
});
```

## 🚨 Tests WebSocket

### **Test avec wscat (alternative à Postman)**

```bash
# Installer wscat
npm install -g wscat

# Se connecter au WebSocket
wscat -c ws://localhost:8000/api/files/ws

# Envoyer un message
{"type": "test", "message": "Hello WebSocket"}
```

### **Test avec un navigateur**

1. **Ouvrez la console du navigateur**
2. **Exécutez le code JavaScript** :

```javascript
const ws = new WebSocket('ws://localhost:8000/api/files/ws');

ws.onopen = function() {
    console.log('Connecté au WebSocket');
};

ws.onmessage = function(event) {
    console.log('Message reçu:', JSON.parse(event.data));
};

ws.onclose = function() {
    console.log('Déconnecté du WebSocket');
};
```

## 📋 Checklist de test

### **Tests de base**
- [ ] Serveur accessible
- [ ] API root fonctionne
- [ ] Status du relay
- [ ] Liste des sociétés
- [ ] Fichiers d'une société

### **Tests d'upload**
- [ ] Upload fichier JSON valide
- [ ] Upload fichier non-JSON (erreur)
- [ ] Upload vers société inexistante
- [ ] Upload fichier volumineux

### **Tests de download**
- [ ] Download fichier existant
- [ ] Download fichier inexistant (erreur)
- [ ] Download depuis société inexistante

### **Tests de synchronisation**
- [ ] Sync société existante
- [ ] Sync société inexistante (erreur)

### **Tests de suppression**
- [ ] Supprimer fichier existant
- [ ] Supprimer fichier inexistant (erreur)

### **Tests WebSocket**
- [ ] Connexion WebSocket
- [ ] Réception notifications
- [ ] Déconnexion WebSocket

## 🐛 Dépannage Postman

### **Problèmes courants**

1. **Erreur de connexion**
   - Vérifiez que le serveur est démarré
   - Vérifiez l'URL dans les variables

2. **Erreur CORS**
   - Le serveur est configuré pour accepter toutes les origines
   - Vérifiez les headers de la requête

3. **Fichier non trouvé**
   - Vérifiez le nom du fichier dans les variables
   - Vérifiez que le fichier existe sur le serveur

4. **Upload échoue**
   - Vérifiez que le fichier est bien sélectionné
   - Vérifiez que c'est un fichier JSON
   - Vérifiez la taille du fichier

### **Logs utiles**

Dans Postman, allez dans **Console** (View > Show Postman Console) pour voir les détails des requêtes et réponses.

---

**Note** : Ces tests vous permettront de valider complètement le fonctionnement du Web Service Relay avant de l'intégrer dans votre application Flutter. 