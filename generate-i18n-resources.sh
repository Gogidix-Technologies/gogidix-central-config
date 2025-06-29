#!/bin/bash

# Script to generate i18n language resource files for all central-configuration services

SERVICES=(
    "ci-cd-templates"
    "config-server"
    "database-migrations"
    "deployment-scripts"
    "disaster-recovery"
    "environment-config"
    "infrastructure-as-code"
    "kubernetes-manifests"
    "regional-deployment"
    "secrets-management"
)

LANGUAGES=("en" "fr" "de" "es" "ar")

# Function to create messages.properties for each language
create_language_file() {
    local service=$1
    local service_path=$2
    local lang=$3
    local file_path="$service_path/i18n/$lang/messages.properties"
    
    # Create language-specific directory if it doesn't exist
    mkdir -p "$service_path/i18n/$lang"
    
    # Get clean service name for display
    local display_name=$(echo "$service" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
    
    case $lang in
        "en")
            cat > "$file_path" << EOF
# English language resources for ${service}
app.name=${display_name}
app.description=Central Configuration Service - ${display_name}
app.version=1.0.0

# Common messages
message.welcome=Welcome to ${display_name}
message.success=Operation completed successfully
message.error=An error occurred
message.warning=Warning
message.info=Information

# Status messages
status.starting=Service is starting...
status.running=Service is running
status.stopping=Service is stopping...
status.stopped=Service has stopped
status.healthy=Service is healthy
status.unhealthy=Service is unhealthy

# Error messages
error.general=An unexpected error occurred
error.validation=Validation failed
error.notfound=Resource not found
error.unauthorized=Unauthorized access
error.forbidden=Access forbidden
error.conflict=Resource conflict
error.server=Internal server error
error.database=Database connection error
error.network=Network error
error.timeout=Operation timed out

# Validation messages
validation.required=This field is required
validation.invalid=Invalid value
validation.min.length=Minimum length is {0}
validation.max.length=Maximum length is {0}
validation.email=Invalid email format
validation.pattern=Invalid format

# API messages
api.request.received=Request received
api.response.sent=Response sent
api.authentication.required=Authentication required
api.authorization.failed=Authorization failed

# Database messages
db.connection.established=Database connection established
db.connection.failed=Database connection failed
db.query.executed=Query executed successfully
db.transaction.started=Transaction started
db.transaction.committed=Transaction committed
db.transaction.rollback=Transaction rolled back

# Configuration messages
config.loaded=Configuration loaded
config.reload=Configuration reloaded
config.update=Configuration updated
config.error=Configuration error

# Logging messages
log.level.changed=Log level changed to {0}
log.file.created=Log file created
log.rotation.performed=Log rotation performed
EOF
            ;;
        "fr")
            cat > "$file_path" << EOF
# French language resources for ${service}
app.name=${display_name}
app.description=Service de Configuration Centrale - ${display_name}
app.version=1.0.0

# Messages communs
message.welcome=Bienvenue dans ${display_name}
message.success=Opération terminée avec succès
message.error=Une erreur s'est produite
message.warning=Avertissement
message.info=Information

# Messages de statut
status.starting=Le service démarre...
status.running=Le service est en cours d'exécution
status.stopping=Le service s'arrête...
status.stopped=Le service s'est arrêté
status.healthy=Le service est sain
status.unhealthy=Le service est défaillant

# Messages d'erreur
error.general=Une erreur inattendue s'est produite
error.validation=La validation a échoué
error.notfound=Ressource introuvable
error.unauthorized=Accès non autorisé
error.forbidden=Accès interdit
error.conflict=Conflit de ressources
error.server=Erreur interne du serveur
error.database=Erreur de connexion à la base de données
error.network=Erreur réseau
error.timeout=Délai d'attente dépassé

# Messages de validation
validation.required=Ce champ est obligatoire
validation.invalid=Valeur invalide
validation.min.length=La longueur minimale est {0}
validation.max.length=La longueur maximale est {0}
validation.email=Format d'email invalide
validation.pattern=Format invalide

# Messages API
api.request.received=Requête reçue
api.response.sent=Réponse envoyée
api.authentication.required=Authentification requise
api.authorization.failed=Autorisation échouée

# Messages de base de données
db.connection.established=Connexion à la base de données établie
db.connection.failed=Échec de connexion à la base de données
db.query.executed=Requête exécutée avec succès
db.transaction.started=Transaction démarrée
db.transaction.committed=Transaction validée
db.transaction.rollback=Transaction annulée

# Messages de configuration
config.loaded=Configuration chargée
config.reload=Configuration rechargée
config.update=Configuration mise à jour
config.error=Erreur de configuration

# Messages de journalisation
log.level.changed=Niveau de journalisation changé en {0}
log.file.created=Fichier de journal créé
log.rotation.performed=Rotation des journaux effectuée
EOF
            ;;
        "de")
            cat > "$file_path" << EOF
# German language resources for ${service}
app.name=${display_name}
app.description=Zentrale Konfigurationsdienst - ${display_name}
app.version=1.0.0

# Allgemeine Nachrichten
message.welcome=Willkommen bei ${display_name}
message.success=Vorgang erfolgreich abgeschlossen
message.error=Ein Fehler ist aufgetreten
message.warning=Warnung
message.info=Information

# Statusnachrichten
status.starting=Dienst wird gestartet...
status.running=Dienst läuft
status.stopping=Dienst wird beendet...
status.stopped=Dienst wurde beendet
status.healthy=Dienst ist gesund
status.unhealthy=Dienst ist fehlerhaft

# Fehlermeldungen
error.general=Ein unerwarteter Fehler ist aufgetreten
error.validation=Validierung fehlgeschlagen
error.notfound=Ressource nicht gefunden
error.unauthorized=Nicht autorisierter Zugriff
error.forbidden=Zugriff verboten
error.conflict=Ressourcenkonflikt
error.server=Interner Serverfehler
error.database=Datenbankverbindungsfehler
error.network=Netzwerkfehler
error.timeout=Zeitüberschreitung

# Validierungsnachrichten
validation.required=Dieses Feld ist erforderlich
validation.invalid=Ungültiger Wert
validation.min.length=Mindestlänge ist {0}
validation.max.length=Maximale Länge ist {0}
validation.email=Ungültiges E-Mail-Format
validation.pattern=Ungültiges Format

# API-Nachrichten
api.request.received=Anfrage empfangen
api.response.sent=Antwort gesendet
api.authentication.required=Authentifizierung erforderlich
api.authorization.failed=Autorisierung fehlgeschlagen

# Datenbanknachrichten
db.connection.established=Datenbankverbindung hergestellt
db.connection.failed=Datenbankverbindung fehlgeschlagen
db.query.executed=Abfrage erfolgreich ausgeführt
db.transaction.started=Transaktion gestartet
db.transaction.committed=Transaktion bestätigt
db.transaction.rollback=Transaktion zurückgerollt

# Konfigurationsnachrichten
config.loaded=Konfiguration geladen
config.reload=Konfiguration neu geladen
config.update=Konfiguration aktualisiert
config.error=Konfigurationsfehler

# Protokollierungsnachrichten
log.level.changed=Protokollierungsebene geändert zu {0}
log.file.created=Protokolldatei erstellt
log.rotation.performed=Protokollrotation durchgeführt
EOF
            ;;
        "es")
            cat > "$file_path" << EOF
# Spanish language resources for ${service}
app.name=${display_name}
app.description=Servicio de Configuración Central - ${display_name}
app.version=1.0.0

# Mensajes comunes
message.welcome=Bienvenido a ${display_name}
message.success=Operación completada con éxito
message.error=Se produjo un error
message.warning=Advertencia
message.info=Información

# Mensajes de estado
status.starting=El servicio está iniciando...
status.running=El servicio está en ejecución
status.stopping=El servicio se está deteniendo...
status.stopped=El servicio se ha detenido
status.healthy=El servicio está saludable
status.unhealthy=El servicio no está saludable

# Mensajes de error
error.general=Se produjo un error inesperado
error.validation=La validación falló
error.notfound=Recurso no encontrado
error.unauthorized=Acceso no autorizado
error.forbidden=Acceso prohibido
error.conflict=Conflicto de recursos
error.server=Error interno del servidor
error.database=Error de conexión a la base de datos
error.network=Error de red
error.timeout=Tiempo de espera agotado

# Mensajes de validación
validation.required=Este campo es obligatorio
validation.invalid=Valor inválido
validation.min.length=La longitud mínima es {0}
validation.max.length=La longitud máxima es {0}
validation.email=Formato de correo electrónico inválido
validation.pattern=Formato inválido

# Mensajes API
api.request.received=Solicitud recibida
api.response.sent=Respuesta enviada
api.authentication.required=Autenticación requerida
api.authorization.failed=Autorización fallida

# Mensajes de base de datos
db.connection.established=Conexión a base de datos establecida
db.connection.failed=Falló la conexión a la base de datos
db.query.executed=Consulta ejecutada con éxito
db.transaction.started=Transacción iniciada
db.transaction.committed=Transacción confirmada
db.transaction.rollback=Transacción revertida

# Mensajes de configuración
config.loaded=Configuración cargada
config.reload=Configuración recargada
config.update=Configuración actualizada
config.error=Error de configuración

# Mensajes de registro
log.level.changed=Nivel de registro cambiado a {0}
log.file.created=Archivo de registro creado
log.rotation.performed=Rotación de registros realizada
EOF
            ;;
        "ar")
            cat > "$file_path" << EOF
# Arabic language resources for ${service}
app.name=${display_name}
app.description=خدمة التكوين المركزي - ${display_name}
app.version=1.0.0

# الرسائل الشائعة
message.welcome=مرحباً بك في ${display_name}
message.success=تمت العملية بنجاح
message.error=حدث خطأ
message.warning=تحذير
message.info=معلومات

# رسائل الحالة
status.starting=الخدمة قيد البدء...
status.running=الخدمة قيد التشغيل
status.stopping=الخدمة قيد الإيقاف...
status.stopped=تم إيقاف الخدمة
status.healthy=الخدمة سليمة
status.unhealthy=الخدمة غير سليمة

# رسائل الخطأ
error.general=حدث خطأ غير متوقع
error.validation=فشل التحقق
error.notfound=المورد غير موجود
error.unauthorized=وصول غير مصرح به
error.forbidden=الوصول محظور
error.conflict=تعارض في الموارد
error.server=خطأ داخلي في الخادم
error.database=خطأ في اتصال قاعدة البيانات
error.network=خطأ في الشبكة
error.timeout=انتهت مهلة العملية

# رسائل التحقق
validation.required=هذا الحقل مطلوب
validation.invalid=قيمة غير صالحة
validation.min.length=الحد الأدنى للطول هو {0}
validation.max.length=الحد الأقصى للطول هو {0}
validation.email=تنسيق البريد الإلكتروني غير صالح
validation.pattern=تنسيق غير صالح

# رسائل API
api.request.received=تم استلام الطلب
api.response.sent=تم إرسال الرد
api.authentication.required=المصادقة مطلوبة
api.authorization.failed=فشل التفويض

# رسائل قاعدة البيانات
db.connection.established=تم إنشاء اتصال قاعدة البيانات
db.connection.failed=فشل اتصال قاعدة البيانات
db.query.executed=تم تنفيذ الاستعلام بنجاح
db.transaction.started=بدأت المعاملة
db.transaction.committed=تم تأكيد المعاملة
db.transaction.rollback=تم التراجع عن المعاملة

# رسائل التكوين
config.loaded=تم تحميل التكوين
config.reload=تمت إعادة تحميل التكوين
config.update=تم تحديث التكوين
config.error=خطأ في التكوين

# رسائل التسجيل
log.level.changed=تم تغيير مستوى السجل إلى {0}
log.file.created=تم إنشاء ملف السجل
log.rotation.performed=تم تدوير السجلات
EOF
            ;;
    esac
}

# Function to create i18n configuration file
create_i18n_config() {
    local service=$1
    local service_path=$2
    
    cat > "$service_path/i18n/i18n-config.json" << EOF
{
  "service": "${service}",
  "defaultLanguage": "en",
  "supportedLanguages": ["en", "fr", "de", "es", "ar"],
  "fallbackLanguage": "en",
  "encoding": "UTF-8",
  "dateFormat": {
    "en": "MM/dd/yyyy",
    "fr": "dd/MM/yyyy",
    "de": "dd.MM.yyyy",
    "es": "dd/MM/yyyy",
    "ar": "yyyy/MM/dd"
  },
  "numberFormat": {
    "en": {"decimal": ".", "thousands": ","},
    "fr": {"decimal": ",", "thousands": " "},
    "de": {"decimal": ",", "thousands": "."},
    "es": {"decimal": ",", "thousands": "."},
    "ar": {"decimal": "٫", "thousands": "٬"}
  },
  "currency": {
    "en": "USD",
    "fr": "EUR",
    "de": "EUR",
    "es": "EUR",
    "ar": "USD"
  },
  "rtl": {
    "ar": true
  }
}
EOF
}

# Main execution
echo "Generating i18n language resources for all central-configuration services..."

for service in "${SERVICES[@]}"; do
    echo "Processing ${service}..."
    service_path="/mnt/c/Users/frich/Desktop/Exalt-Application-Limited/Exalt-Application-Limited/social-ecommerce-ecosystem/central-configuration/${service}"
    
    if [ -d "${service_path}/i18n" ]; then
        # Create language files
        for lang in "${LANGUAGES[@]}"; do
            create_language_file "${service}" "${service_path}" "${lang}"
            echo "  ✅ Created ${lang} resources"
        done
        
        # Create i18n configuration
        create_i18n_config "${service}" "${service_path}"
        echo "  ✅ Created i18n configuration"
        
        echo "✅ Generated i18n resources for ${service}"
    else
        echo "❌ i18n directory not found for ${service}"
    fi
done

echo "i18n resource generation complete!"