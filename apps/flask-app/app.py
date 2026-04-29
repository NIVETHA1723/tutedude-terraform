from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify(message="Hello from Flask Backend!")

@app.route('/api')
def api():
    return jsonify(
        status="success",
        data="This is data from the Flask API"
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
