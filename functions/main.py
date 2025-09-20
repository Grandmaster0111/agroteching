
# main.py
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from firebase_functions import firestore_fn, options

# Initialize Firebase Admin SDK
firebase_admin.initialize_app()
options.set_global_options(region="us-central1")

@firestore_fn.on_document_written("sensor_data/{sensor_id}")
def send_push_notification(event: firestore_fn.Event[firestore_fn.Change]) -> None:
    """
    Monitors sensor data and sends push notifications for critical events.
    """
    try:
        db = firestore.client()
        
        # Get the new sensor data from the event
        new_data = event.data.after.to_dict()
        
        soil_moisture = new_data.get("soil_moisture")
        water_tank_level = new_data.get("water_tank_level")
        
        notification_title = None
        notification_body = None
        
        # --- Notification Logic ---
        if soil_moisture is not None and soil_moisture < 15: # Critical moisture level
            notification_title = "Critical Alert: Low Soil Moisture"
            notification_body = "Soil moisture is critically low. Irrigation has been started automatically."
            
        elif water_tank_level is not None and water_tank_level < 20: # Low water tank level
            notification_title = "Warning: Low Water Tank"
            notification_body = f"Water tank is below 20% ({water_tank_level}%). Please refill soon."
            
        # If there's a notification to send
        if notification_title and notification_body:
            # Get all the FCM tokens from the 'fcm_tokens' collection
            tokens_ref = db.collection('fcm_tokens')
            tokens_snapshot = tokens_ref.get()
            
            fcm_tokens = [doc.to_dict()['token'] for doc in tokens_snapshot]
            
            if not fcm_tokens:
                print("No FCM tokens found. Cannot send notification.")
                return
                
            # Create the message payload
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=notification_title,
                    body=notification_body,
                ),
                tokens=fcm_tokens,
            )
            
            # Send the message
            response = messaging.send_multicast(message)
            print(f"Successfully sent message to {response.success_count} devices.")

    except Exception as e:
        print(f"An error occurred: {e}")
