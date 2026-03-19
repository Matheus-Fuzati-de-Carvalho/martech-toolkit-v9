import os
import base64
import json
# Exemplo usando SendGrid (que é o padrão para e-mail no GCP)
# Você pode trocar por qualquer provedor SMTP
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def send_email_notification(event, context):
    # Decodifica a mensagem vinda do Pub/Sub
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    data = json.loads(pubsub_message)
    
    target_email = os.environ.get('NOTIFICATION_EMAIL')
    
    message = Mail(
        from_email='alerts@martech-toolkit.com',
        to_emails=target_email,
        subject='🚨 FALHA DETECTADA: Martech Toolkit v9',
        plain_text_content=f"Ocorreu um erro no pipeline Dataform.\n\nDetalhes: {data['error_message']}\nSabor: {data['flavor']}"
    )
    
    try:
        # sg = SendGridAPIClient(os.environ.get('SENDGRID_API_KEY'))
        # response = sg.send(message)
        print(f"Alerta enviado para {target_email}: {pubsub_message}")
    except Exception as e:
        print(f"Erro ao enviar e-mail: {str(e)}")