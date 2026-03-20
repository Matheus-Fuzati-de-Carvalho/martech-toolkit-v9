import os
import base64
import json
import smtplib
from email.message import EmailMessage

def send_email_notification(event, context):
    # 1. Decodifica a mensagem do Pub/Sub
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    data = json.loads(pubsub_message)
    
    # 2. Configurações vindas do Terraform (Env Vars)
    email_user = os.environ.get('EMAIL_USER')        # Seu e-mail (remetente)
    email_pass = os.environ.get('EMAIL_PASSWORD')    # Sua "Senha de App"
    target_email = os.environ.get('NOTIFICATION_EMAIL') # Destinatário
    
    # 3. Monta o corpo do e-mail
    msg = EmailMessage()
    msg['Subject'] = '🚨 ALERTA: Falha no Martech Toolkit v9'
    msg['From'] = email_user
    msg['To'] = target_email
    
    corpo = f"""
    Ocorreu um erro no pipeline Dataform.
    
    -------------------------------------------
    PROJETO: {data.get('project', 'N/A')}
    SABOR: {data.get('flavor', 'N/A')}
    ERRO: {data.get('error_message', 'Sem detalhes')}
    -------------------------------------------
    
    Verifique o console do Google Cloud para mais detalhes.
    """
    msg.set_content(corpo)

    # 4. Envio via SMTP (Porta 587 é obrigatória no GCP)
    try:
        # Se for Gmail: smtp.gmail.com | Se for Outlook: smtp-mail.outlook.com
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls() # Inicia criptografia obrigatória
            server.login(email_user, email_pass)
            server.send_message(msg)
            print(f"✅ E-mail de alerta enviado com sucesso para {target_email}")
    except Exception as e:
        print(f"❌ Falha crítica no envio via SMTP: {str(e)}")