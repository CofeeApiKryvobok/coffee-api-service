from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import uuid
import datetime

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@postgres-service:5432/coffee_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Transaction(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    amount = db.Column(db.Numeric(10, 2))
    coffee_type = db.Column(db.String(50))

@app.route('/order', methods=['POST'])
def order():
    data = request.json
    payment = data.get('payment')

    if payment < 2.00:
        coffee_type = 'Espresso'
    elif 2.00 <= payment < 3.00:
        coffee_type = 'Latte'
    else:
        coffee_type = 'Cappuccino'

    transaction = Transaction(amount=payment, coffee_type=coffee_type)
    db.session.add(transaction)
    db.session.commit()

    return jsonify({'coffee_type': coffee_type})

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'OK'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
