import psycopg2
from flask import Flask, request, jsonify
import uuid
import datetime

app = Flask(__name__)

# Подключение к БД
conn = psycopg2.connect(
    dbname="coffee_db",
    user="user",
    password="password",
    host="db"
)
cursor = conn.cursor()

@app.route('/coffee', methods=['POST'])
def coffee():
    try:
        payment = float(request.json['payment'])
        coffee_type = "Espresso" if payment < 2.00 else "Latte" if payment < 3.00 else "Cappuccino"

        transaction_id = str(uuid.uuid4())
        timestamp = datetime.datetime.utcnow()

        # Вставка транзакции в БД
        cursor.execute(
            "INSERT INTO transactions (id, timestamp, payment, coffee_type) VALUES (%s, %s, %s, %s)",
            (transaction_id, timestamp, payment, coffee_type)
        )
        conn.commit()

        return jsonify({
            "transaction_id": transaction_id,
            "timestamp": timestamp,
            "payment": payment,
            "coffee_type": coffee_type
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
