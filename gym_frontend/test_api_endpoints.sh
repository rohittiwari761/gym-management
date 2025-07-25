#!/bin/bash

# Gym Management API Diagnostic Script
# Usage: ./test_api_endpoints.sh [your-email] [your-password]

BASE_URL="https://gym-management-production-2168.up.railway.app/api"
EMAIL=${1:-"test@example.com"}
PASSWORD=${2:-"your-password"}

echo "🔍 Testing Gym Management API Endpoints"
echo "========================================="
echo "Base URL: $BASE_URL"
echo "Email: $EMAIL"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local auth_header=$3
    local data=$4
    local description=$5
    
    echo -e "${YELLOW}Testing: $description${NC}"
    echo "Endpoint: $method $BASE_URL$endpoint"
    
    if [ "$method" = "GET" ]; then
        if [ -n "$auth_header" ]; then
            response=$(curl -s -w "\n%{http_code}:%{time_total}" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                -H "$auth_header" \
                --max-time 20 \
                "$BASE_URL$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}:%{time_total}" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                --max-time 20 \
                "$BASE_URL$endpoint")
        fi
    else
        response=$(curl -s -w "\n%{http_code}:%{time_total}" \
            -X "$method" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$data" \
            --max-time 20 \
            "$BASE_URL$endpoint")
    fi
    
    # Extract status code and time
    status_line=$(echo "$response" | tail -n 1)
    status_code=$(echo "$status_line" | cut -d':' -f1)
    time_total=$(echo "$status_line" | cut -d':' -f2)
    response_body=$(echo "$response" | sed '$d')
    
    # Print results
    if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
        echo -e "${GREEN}✅ SUCCESS${NC} - Status: $status_code, Time: ${time_total}s"
    elif [ "$status_code" = "000" ]; then
        echo -e "${RED}❌ TIMEOUT/CONNECTION FAILED${NC} - No response received"
    else
        echo -e "${RED}❌ FAILED${NC} - Status: $status_code, Time: ${time_total}s"
    fi
    
    # Show response preview
    if [ ${#response_body} -gt 0 ]; then
        echo "Response preview: $(echo "$response_body" | head -c 200)..."
    fi
    echo ""
}

# Test 1: Health Check
test_endpoint "GET" "/health/" "" "" "Health Check (No Auth)"

# Test 2: Root API
test_endpoint "GET" "/" "" "" "Root API Endpoint"

# Test 3: Authentication
echo -e "${YELLOW}Testing: Authentication${NC}"
echo "Endpoint: POST $BASE_URL/auth/login/"

login_data="{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}"
auth_response=$(curl -s -w "\n%{http_code}:%{time_total}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$login_data" \
    --max-time 20 \
    "$BASE_URL/auth/login/")

auth_status_line=$(echo "$auth_response" | tail -n 1)
auth_status_code=$(echo "$auth_status_line" | cut -d':' -f1)
auth_time=$(echo "$auth_status_line" | cut -d':' -f2)
auth_body=$(echo "$auth_response" | sed '$d')

if [ "$auth_status_code" = "200" ]; then
    echo -e "${GREEN}✅ LOGIN SUCCESS${NC} - Status: $auth_status_code, Time: ${auth_time}s"
    
    # Extract token
    TOKEN=$(echo "$auth_body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo "Token obtained: ${TOKEN:0:20}..."
        AUTH_HEADER="Authorization: Token $TOKEN"
        
        # Test authenticated endpoints
        test_endpoint "GET" "/equipment/" "$AUTH_HEADER" "" "Equipment Endpoint (MAIN ISSUE)"
        test_endpoint "GET" "/members/" "$AUTH_HEADER" "" "Members Endpoint"
        test_endpoint "GET" "/trainers/" "$AUTH_HEADER" "" "Trainers Endpoint"
        test_endpoint "GET" "/equipment/working/" "$AUTH_HEADER" "" "Working Equipment Endpoint"
        
    else
        echo -e "${RED}❌ No token found in login response${NC}"
    fi
else
    echo -e "${RED}❌ LOGIN FAILED${NC} - Status: $auth_status_code, Time: ${auth_time}s"
    echo "Response: $auth_body"
fi

echo ""
echo "🏁 Testing Complete"
echo "==================="
echo ""
echo "📊 Summary:"
echo "- If health check fails: Server is down or sleeping"
echo "- If login fails: Check credentials or auth endpoint"
echo "- If equipment fails but others work: Equipment-specific issue"
echo "- If all authenticated endpoints fail: Token/auth issue"
echo "- If timeouts occur: Server performance issue"