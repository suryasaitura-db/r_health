#!/usr/bin/env python3
"""
Test script for R_Health FastAPI backend
Verifies all endpoints are working correctly
"""
import requests
import json

BASE_URL = "http://localhost:8000"


def test_endpoint(name: str, url: str):
    """Test a single endpoint"""
    try:
        response = requests.get(url, timeout=30)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ {name}: {len(data) if isinstance(data, list) else 'OK'} {'records' if isinstance(data, list) else ''}")
            return True
        else:
            print(f"✗ {name}: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ {name}: {str(e)[:100]}")
        return False


def main():
    print("\n" + "="*80)
    print("R_HEALTH API ENDPOINT TESTS")
    print("="*80 + "\n")

    endpoints = [
        ("Root Endpoint", f"{BASE_URL}/"),
        ("Health Check", f"{BASE_URL}/health"),
        ("Capacity Management", f"{BASE_URL}/api/capacity-management?limit=10"),
        ("Capacity Summary", f"{BASE_URL}/api/capacity-management/summary"),
        ("Denials Management", f"{BASE_URL}/api/denials-management?limit=10"),
        ("Denials Summary", f"{BASE_URL}/api/denials-management/summary"),
        ("Clinical Trials", f"{BASE_URL}/api/clinical-trial-matching?limit=10"),
        ("Trials Summary", f"{BASE_URL}/api/clinical-trial-matching/summary"),
        ("Timely Filing", f"{BASE_URL}/api/timely-filing-appeals?limit=10"),
        ("Filing Summary", f"{BASE_URL}/api/timely-filing-appeals/summary"),
        ("Documentation", f"{BASE_URL}/api/documentation-management?limit=10"),
        ("Docs Summary", f"{BASE_URL}/api/documentation-management/summary"),
        ("Payers List", f"{BASE_URL}/api/payers"),
        ("DRG Codes List", f"{BASE_URL}/api/drg-codes"),
    ]

    passed = 0
    failed = 0

    for name, url in endpoints:
        if test_endpoint(name, url):
            passed += 1
        else:
            failed += 1

    print("\n" + "="*80)
    print(f"Results: {passed} passed, {failed} failed")
    print("="*80 + "\n")

    return failed == 0


if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
