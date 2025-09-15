# 🔌 Room-O-Matic API Endpoints Documentation

## 📋 Overview

This document provides a comprehensive overview of all API endpoints currently implemented in the Room-O-Matic system. The API is organized into several modules serving different client types and use cases.

**API Version**: v1  
**Base URL**: `https://api.room-o-matic.com` (production) or `http://localhost:3000` (development)  
**Authentication**: JWT Bearer tokens + API keys  
**Content-Type**: `application/json`

---

## 🏗️ API Architecture

### API Modules

1. **Core API** (`/api/v1/`) - Basic system endpoints
2. **Mobile API** (`/api/v1/mobile/`) - Mobile app integration endpoints  
3. **Web API** (`/api/v1/web/`) - Web navigation and frontend support
4. **WordPress API** (`/api/v1/wordpress/`) - WordPress plugin integration (planned)

---

## 🔧 Core API Endpoints

### System Health & Information

#### `GET /api/v1/health`
**Description**: System health check endpoint  
**Authentication**: None required  
**Response**:
```json
{
  "status": "ok",
  "timestamp": "2025-09-14T18:30:00Z",
  "version": "0.1.0"
}
```

#### `GET /api/v1/version`
**Description**: API and service version information  
**Authentication**: None required  
**Response**:
```json
{
  "api_version": "v1",
  "service_version": "0.1.0",
  "build_time": "2025-09-14T12:00:00Z",
  "git_commit": "abc123def456"
}
```

---

## 📱 Mobile API Endpoints

**Base Path**: `/api/v1/mobile/`  
**Authentication**: JWT Bearer tokens required for all endpoints except login

### Authentication Endpoints

#### `POST /api/v1/mobile/auth/login`
**Description**: Authenticate mobile device and obtain JWT tokens  
**Authentication**: API key + device ID required  
**Request Body**:
```json
{
  "api_key": "romo_live_abc123...",
  "device_id": "mobile_device_uuid",
  "device_info": {
    "platform": "ios",
    "os_version": "17.0",
    "app_version": "1.0.0",
    "device_model": "iPhone 15 Pro"
  }
}
```
**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user_id": "user_uuid",
  "quota_remaining": 1000,
  "subscription_tier": "professional"
}
```

#### `POST /api/v1/mobile/auth/refresh`
**Description**: Refresh expired access token using refresh token  
**Request Body**:
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```
**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 3600
}
```

#### `POST /api/v1/mobile/auth/logout`
**Description**: Logout and invalidate tokens  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "message": "Successfully logged out"
}
```

### Room Processing Endpoints

#### `POST /api/v1/mobile/rooms/upload`
**Description**: Upload room scan data for AI processing  
**Authentication**: Bearer token required  
**Content-Type**: `multipart/form-data`  
**Request Body**:
```json
{
  "room_scan": {
    "id": "scan_uuid",
    "room_name": "Living Room",
    "device_info": {
      "platform": "ios",
      "has_lidar": true,
      "camera_resolution": "4K"
    },
    "sensor_data": {
      "lidar_points": "base64_encoded_data",
      "camera_images": ["base64_image1", "base64_image2"],
      "motion_data": {...},
      "audio_data": {...}
    },
    "metadata": {
      "scan_duration": 45.2,
      "room_type": "living_room",
      "lighting_conditions": "natural"
    }
  }
}
```
**Response**:
```json
{
  "processing_id": "proc_uuid",
  "status": "queued",
  "estimated_completion": "2025-09-14T18:35:00Z",
  "cost_estimate": 0.05,
  "queue_position": 3
}
```

#### `GET /api/v1/mobile/rooms`
**Description**: Get user's room list with pagination  
**Authentication**: Bearer token required  
**Query Parameters**:
- `page` (default: 1)
- `limit` (default: 10, max: 50)
- `status` (optional: completed, processing, failed)

**Response**:
```json
{
  "rooms": [
    {
      "room_id": "room_uuid",
      "room_name": "Living Room",
      "created_at": "2025-09-14T10:00:00Z",
      "status": "completed",
      "processing_cost": 0.05,
      "has_3d_model": true
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "has_next": true,
    "has_prev": false
  }
}
```

#### `GET /api/v1/mobile/rooms/{room_id}`
**Description**: Get specific room details and analysis results  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "room_id": "room_uuid",
  "room_name": "Living Room", 
  "status": "completed",
  "created_at": "2025-09-14T10:00:00Z",
  "analysis_result": {
    "room_type": "living_room",
    "dimensions": {
      "width": 4.5,
      "length": 6.2,
      "height": 2.8,
      "area": 27.9,
      "volume": 78.1
    },
    "objects": [
      {
        "type": "sofa",
        "position": {"x": 2.0, "y": 0.0, "z": 1.0},
        "confidence": 0.95,
        "bounding_box": {...}
      }
    ],
    "lighting_analysis": {...},
    "recommendations": [...]
  },
  "processing_metadata": {
    "ai_provider": "openai",
    "processing_time": 15.3,
    "cost": 0.05
  }
}
```

### Processing Status Endpoints

#### `GET /api/v1/mobile/processing/{processing_id}/status`
**Description**: Get real-time processing status  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "processing_id": "proc_uuid",
  "status": "processing",
  "progress": 65,
  "queue_position": null,
  "estimated_completion": "2025-09-14T18:32:00Z",
  "provider_used": "openai",
  "cost_estimate": 0.05,
  "error_message": null
}
```

#### `GET /api/v1/mobile/processing/{processing_id}/result`
**Description**: Get completed processing results  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "processing_id": "proc_uuid",
  "status": "completed",
  "result": {
    "room_analysis": {...},
    "3d_model_url": "https://api.room-o-matic.com/models/room_uuid.obj",
    "cost_actual": 0.05,
    "processing_time": 15.3
  }
}
```

#### `POST /api/v1/mobile/processing/{processing_id}/cancel`
**Description**: Cancel processing job  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "message": "Processing job cancelled successfully",
  "refund_amount": 0.05
}
```

#### `GET /api/v1/mobile/processing/history`
**Description**: Get user's processing history  
**Authentication**: Bearer token required  
**Query Parameters**:
- `page` (default: 1)
- `limit` (default: 20)
- `status` (optional filter)

**Response**:
```json
{
  "history": [
    {
      "processing_id": "proc_uuid",
      "room_name": "Living Room",
      "status": "completed",
      "created_at": "2025-09-14T10:00:00Z",
      "cost": 0.05,
      "provider": "openai"
    }
  ],
  "pagination": {...}
}
```

#### `GET /api/v1/mobile/processing/queue/stats`
**Description**: Get queue statistics and system status  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "queue_stats": {
    "total_jobs": 150,
    "completed_jobs": 142,
    "failed_jobs": 3,
    "active_jobs": 5,
    "average_processing_time": 18.5
  },
  "system_health": {
    "ai_providers_status": "healthy",
    "estimated_wait_time": 120
  }
}
```

### User Management Endpoints

#### `GET /api/v1/mobile/user/profile`
**Description**: Get user profile and subscription details  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "user_id": "user_uuid",
  "email": "user@example.com",
  "subscription_tier": "professional",
  "quota_remaining": 950,
  "quota_limit": 1000,
  "quota_reset_date": "2025-10-01T00:00:00Z",
  "mobile_permissions": {
    "mobile_app_access": true,
    "mobile_upload_enabled": true,
    "mobile_processing_enabled": true,
    "mobile_export_enabled": true,
    "mobile_background_upload": true,
    "mobile_offline_sync": true
  },
  "account_status": "active"
}
```

#### `GET /api/v1/mobile/user/api-keys`
**Description**: Get user's API keys for mobile devices  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "api_keys": [
    {
      "key_id": "key_uuid", 
      "key_name": "iPhone 15 Pro",
      "key_preview": "romo_live_abc123...***",
      "created_at": "2025-09-01T00:00:00Z",
      "last_used": "2025-09-14T10:00:00Z",
      "device_id": "mobile_device_uuid",
      "status": "active"
    }
  ],
  "max_keys": 5,
  "can_create_more": true
}
```

#### `POST /api/v1/mobile/user/api-keys`
**Description**: Create new API key for mobile device  
**Authentication**: Bearer token required  
**Request Body**:
```json
{
  "key_name": "iPhone 15 Pro Max",
  "device_id": "new_device_uuid",
  "permissions": ["mobile_upload", "mobile_processing"]
}
```
**Response**:
```json
{
  "key_id": "key_uuid",
  "api_key": "romo_live_new_key_full_value",
  "key_name": "iPhone 15 Pro Max",
  "created_at": "2025-09-14T18:30:00Z",
  "permissions": ["mobile_upload", "mobile_processing"]
}
```

#### `POST /api/v1/mobile/user/preferences`
**Description**: Update user preferences and settings  
**Authentication**: Bearer token required  
**Request Body**:
```json
{
  "preferences": {
    "default_room_type": "living_room",
    "preferred_ai_provider": "cost_optimized",
    "auto_sync": true,
    "push_notifications": true
  }
}
```

#### `GET /api/v1/mobile/user/usage-stats`
**Description**: Get user's usage statistics and analytics  
**Authentication**: Bearer token required  
**Response**:
```json
{
  "current_period": {
    "api_calls_used": 50,
    "api_calls_limit": 1000,
    "total_cost": 2.50,
    "rooms_processed": 12
  },
  "historical": {
    "total_rooms": 145,
    "total_cost": 72.50,
    "average_cost_per_room": 0.05,
    "most_used_provider": "openai"
  }
}
```

#### `POST /api/v1/mobile/user/subscription/upgrade`
**Description**: Request subscription tier upgrade  
**Authentication**: Bearer token required  
**Request Body**:
```json
{
  "target_tier": "enterprise"
}
```
**Response**:
```json
{
  "upgrade_request_id": "upgrade_uuid",
  "target_tier": "enterprise",
  "estimated_cost": 99.00,
  "effective_date": "2025-10-01T00:00:00Z",
  "status": "pending_payment"
}
```

---

## 🌐 Web API Endpoints

**Base Path**: `/api/v1/web/`  
**Purpose**: Support for web frontend and navigation

#### `GET /api/v1/web/navigation`
**Description**: Get navigation menu structure for web frontend  
**Authentication**: None required  
**Response**:
```json
{
  "menu_items": [
    {
      "label": "Dashboard",
      "path": "/dashboard",
      "icon": "dashboard",
      "children": []
    },
    {
      "label": "Rooms",
      "path": "/rooms", 
      "icon": "room",
      "children": [
        {
          "label": "Upload New",
          "path": "/rooms/upload",
          "icon": "upload"
        },
        {
          "label": "Browse Gallery",
          "path": "/rooms/gallery",
          "icon": "gallery"
        }
      ]
    },
    {
      "label": "Account",
      "path": "/account",
      "icon": "user",
      "children": [
        {
          "label": "Profile",
          "path": "/account/profile",
          "icon": "profile"
        },
        {
          "label": "Subscription",
          "path": "/account/subscription", 
          "icon": "subscription"
        },
        {
          "label": "API Keys",
          "path": "/account/api-keys",
          "icon": "key"
        }
      ]
    }
  ]
}
```

---

## 🔐 Authentication & Security

### API Key Format
- **Production**: `romo_live_` prefix + 32 character string
- **Development**: `romo_test_` prefix + 32 character string  
- **Example**: `romo_live_abc123def456ghi789jkl012mno345pq`

### JWT Token Structure
```json
{
  "sub": "user_uuid",
  "iat": 1726339800,
  "exp": 1726343400,
  "device_id": "mobile_device_uuid",
  "permissions": ["mobile_upload", "mobile_processing"],
  "subscription_tier": "professional"
}
```

### Authorization Header
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Mobile Permission Flags
- `mobile_app_access`: Basic mobile app API access
- `mobile_upload_enabled`: Upload room scans from mobile devices  
- `mobile_processing_enabled`: Process uploaded scans via AI
- `mobile_export_enabled`: Export and download processed results
- `mobile_background_upload`: Background upload queue processing
- `mobile_offline_sync`: Offline data synchronization when reconnected

---

## 📊 Rate Limiting

### Limits by Subscription Tier

| Tier | API Calls/Hour | Upload/Day | Processing/Month |
|------|----------------|------------|------------------|
| Free | 100 | 5 | 10 |
| Basic | 1,000 | 50 | 100 |
| Professional | 10,000 | 500 | 1,000 |
| Enterprise | Unlimited | Unlimited | Unlimited |

### Rate Limit Headers
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1726343400
```

---

## ❌ Error Responses

### Standard Error Format
```json
{
  "error": {
    "code": "INVALID_API_KEY",
    "message": "The provided API key is invalid or expired",
    "details": {
      "field": "api_key",
      "reason": "key_not_found"
    }
  },
  "request_id": "req_uuid",
  "timestamp": "2025-09-14T18:30:00Z"
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `INVALID_REQUEST` | Request validation failed |
| 401 | `INVALID_API_KEY` | API key invalid or missing |
| 401 | `TOKEN_EXPIRED` | JWT token has expired |
| 403 | `INSUFFICIENT_PERMISSIONS` | User lacks required permissions |
| 403 | `QUOTA_EXCEEDED` | User has exceeded their quota |
| 404 | `RESOURCE_NOT_FOUND` | Requested resource does not exist |
| 409 | `PROCESSING_IN_PROGRESS` | Room is already being processed |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests |
| 500 | `INTERNAL_SERVER_ERROR` | Server error occurred |
| 503 | `SERVICE_UNAVAILABLE` | AI providers unavailable |

---

## 🔄 WebSocket Endpoints (Future)

**Planned for real-time updates**:
- `ws://api.room-o-matic.com/v1/mobile/processing/{processing_id}/stream`
- `ws://api.room-o-matic.com/v1/mobile/notifications`

---

## 📈 API Versioning

- **Current Version**: v1
- **API Path**: `/api/v1/`
- **Version Header**: `API-Version: v1` (optional)
- **Backward Compatibility**: Maintained for 12 months
- **Deprecation Notice**: 6 months advance notice via headers and documentation

---

## 🧪 Testing & Examples

### cURL Examples

**Login**:
```bash
curl -X POST https://api.room-o-matic.com/api/v1/mobile/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "romo_live_abc123def456...",
    "device_id": "mobile_device_uuid",
    "device_info": {
      "platform": "ios",
      "os_version": "17.0",
      "app_version": "1.0.0"
    }
  }'
```

**Upload Room**:
```bash
curl -X POST https://api.room-o-matic.com/api/v1/mobile/rooms/upload \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{
    "room_scan": {
      "room_name": "Living Room",
      "sensor_data": {...}
    }
  }'
```

**Check Status**:
```bash
curl -X GET https://api.room-o-matic.com/api/v1/mobile/processing/proc_uuid/status \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

---

## 📚 Additional Resources

- **OpenAPI Specification**: `/api/v1/openapi.json` (planned)
- **API Client SDKs**: Available for iOS, Android, JavaScript, Python
- **Postman Collection**: [Room-O-Matic API Collection](link-to-postman)
- **Integration Guide**: `/docs/MOBILE_RUST_SERVER_INTEGRATION_GUIDE.md`
- **Mobile App Development**: See Flutter project integration documentation

---

**Last Updated**: September 14, 2025  
**API Status**: Active Development  
**Next Planned Features**: WebSocket support, WordPress plugin endpoints, admin dashboard API
