from flask import Flask, jsonify, request
import mysql.connector

app = Flask(__name__)

# Connect to your XAMPP MySQL Database
def get_db_connection():
    connection = mysql.connector.connect(
        host='localhost',
        user='root',        # Default XAMPP username
        password='',        # Default XAMPP password is usually blank
        database='MindJourney'
    )
    return connection

# A simple test route to make sure the server is running
@app.route('/')
def home():
    return jsonify({"message": "MindJourney Python Backend is running!"})

# Route to get all journal entries
@app.route('/api/journals', methods=['GET'])
def get_journals():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM journal_entries")
        entries = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return jsonify(entries)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Running on port 5000 with debug mode ON
    app.run(debug=True, host='0.0.0.0', port=5001)