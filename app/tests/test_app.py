import pytest
import sys
import os

# Add parent directory to path so app can be imported
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page_status(client):
    """Test that the homepage loads successfully with HTTP 200"""
    response = client.get('/')
    assert response.status_code == 200
    assert b"DevOps Automated Web App" in response.data

def test_health_endpoint(client):
    """Test that the health endpoint responds with UP status"""
    response = client.get('/health')
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['status'] == "UP"
    assert json_data['service'] == "Flask-DevOps-Demo"
