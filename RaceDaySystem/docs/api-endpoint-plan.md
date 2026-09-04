# RaceDay Management System - API Endpoint Plan

## API Overview
- **Base URL**: `/api/`
- **Version**: v1
- **Authentication**: JWT Bearer tokens
- **Response Format**: JSON
- **Rate Limiting**: 100 requests per minute for authenticated users, 20 for unauthenticated

## Authentication & Authorization
- **JWT Implementation**: ASP.NET Core Identity with JWT Bearer Authentication
- **Token Expiry**: 1 hour (refresh token available)
- **Role-based Access**: Organiser and Participant roles enforced at API level
- **Password Hashing**: BCrypt or PBKDF2

## Common Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### Error Response
```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email is required"
    }
  ],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## API Endpoints Table

### Authentication Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | `/api/auth/register` | Register a new user account with role selection | None (Public) | `{ "email": "string", "password": "string", "fullName": "string", "role": "string" }` | 201 Created: User object; 400 Bad Request: Validation errors; 409 Conflict: Email already exists |
| POST | `/api/auth/login` | Authenticate user and return JWT token | None (Public) | `{ "email": "string", "password": "string" }` | 200 OK: `{ "token": "string", "user": { ... } }`; 401 Unauthorized: Invalid credentials; 400 Bad Request: Missing fields |
| POST | `/api/auth/refresh` | Refresh JWT token using refresh token | Any (Logged in) | `{ "refreshToken": "string" }` | 200 OK: `{ "token": "string" }`; 401 Unauthorized: Invalid token |
| POST | `/api/auth/logout` | Logout user and invalidate token | Any (Logged in) | None | 200 OK: Logout successful |

### User Profile Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | `/api/users/profile` | Get current user's profile information | Any (Logged in) | None | 200 OK: User object; 404 Not Found: User not found |
| PUT | `/api/users/profile` | Update current user's profile | Any (Logged in) | `{ "fullName": "string", "email": "string" }` | 200 OK: Updated user; 400 Bad Request: Validation errors; 409 Conflict: Email already used |
| GET | `/api/users/{id}/enrolments` | Get all enrolments for a specific user | Any (Logged in) | None (URL param: id) | 200 OK: List of enrolments with category and event details; 404 Not Found: User not found; 403 Forbidden: Cannot view other's enrolments |
| GET | `/api/users/participants` | Get all participants (for organiser management) | Organiser | None | 200 OK: List of participants with enrolment counts; 403 Forbidden: Not organiser |

### Event Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | `/api/events` | Get all events with optional filters | None (Public) | None (Query: status, dateFrom, dateTo, search, page, pageSize) | 200 OK: Paginated list of events with basic info; 400 Bad Request: Invalid query parameters |
| GET | `/api/events/{id}` | Get detailed event information by ID | None (Public) | None (URL param: id) | 200 OK: Event object with categories and enrolments count; 404 Not Found: Event not found |
| POST | `/api/events` | Create a new event | Organiser | `{ "eventName": "string", "description": "string", "eventDate": "datetime", "location": "string", "maxParticipants": "int", "status": "string" }` | 201 Created: Event object; 400 Bad Request: Validation errors; 403 Forbidden: Not organiser |
| PUT | `/api/events/{id}` | Update an existing event | Organiser | `{ "eventName": "string", "description": "string", "eventDate": "datetime", "location": "string", "maxParticipants": "int", "status": "string" }` | 200 OK: Updated event; 404 Not Found: Event not found; 403 Forbidden: Not event organiser |
| DELETE | `/api/events/{id}` | Soft delete an event (or cancel if upcoming) | Organiser | None (URL param: id) | 204 No Content; 404 Not Found: Event not found; 403 Forbidden: Not event organiser; 409 Conflict: Event has confirmed enrolments |
| GET | `/api/events/{id}/categories` | Get all categories for a specific event | None (Public) | None (URL param: id) | 200 OK: List of categories with enrolment counts; 404 Not Found: Event not found |
| GET | `/api/events/{id}/enrolments` | Get all enrolments for an event | Organiser | None (URL param: id, Query: status, paymentStatus) | 200 OK: List of enrolments with participant details; 404 Not Found: Event not found; 403 Forbidden: Not event organiser |
| GET | `/api/events/organiser/{organiserId}` | Get events created by a specific organiser | Any (Logged in) | None (URL param: organiserId) | 200 OK: List of events; 404 Not Found: Organiser not found |

### Category Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| GET | `/api/categories` | Get all categories with optional filters | None (Public) | None (Query: eventId, search) | 200 OK: List of categories with event details |
| GET | `/api/categories/{id}` | Get detailed category information | None (Public) | None (URL param: id) | 200 OK: Category object with event and enrolment details; 404 Not Found: Category not found |
| POST | `/api/events/{eventId}/categories` | Create a new category for an event | Organiser | `{ "categoryName": "string", "description": "string", "minAge": "int", "maxAge": "int", "genderRestriction": "string" }` | 201 Created: Category object; 400 Bad Request: Validation errors; 404 Not Found: Event not found; 403 Forbidden: Not event organiser |
| PUT | `/api/categories/{id}` | Update category details | Organiser | `{ "categoryName": "string", "description": "string", "minAge": "int", "maxAge": "int", "genderRestriction": "string" }` | 200 OK: Updated category; 404 Not Found: Category not found; 403 Forbidden: Not event organiser |
| DELETE | `/api/categories/{id}` | Delete a category (if no enrolments) | Organiser | None (URL param: id) | 204 No Content; 404 Not Found: Category not found; 403 Forbidden: Not event organiser; 409 Conflict: Category has enrolments |
| GET | `/api/categories/{id}/enrolments` | Get all enrolments for a category | Organiser | None (URL param: id) | 200 OK: List of enrolments; 404 Not Found: Category not found; 403 Forbidden: Not event organiser |

### Enrolment Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | `/api/enrolments` | Enrol in an event category | Participant | `{ "categoryId": "int" }` | 201 Created: Enrolment object; 400 Bad Request: Already enrolled or validation error; 404 Not Found: Category not found; 409 Conflict: Max participants reached or event full |
| GET | `/api/enrolments/participant` | Get current user's enrolments | Participant | None | 200 OK: List of enrolments with category and event details |
| GET | `/api/enrolments/{id}` | Get specific enrolment details | Any (Logged in) | None (URL param: id) | 200 OK: Enrolment object; 404 Not Found: Enrolment not found; 403 Forbidden: Not your enrolment (participant) or not organiser |
| PUT | `/api/enrolments/{id}/status` | Update enrolment status (confirm/cancel) | Organiser | `{ "status": "string" }` | 200 OK: Updated enrolment; 404 Not Found: Enrolment not found; 403 Forbidden: Not event organiser |
| DELETE | `/api/enrolments/{id}` | Cancel enrolment (participant only) | Participant | None (URL param: id) | 204 No Content; 404 Not Found: Enrolment not found; 403 Forbidden: Not your enrolment or cannot cancel confirmed |
| GET | `/api/enrolments/event/{eventId}` | Get all enrolments for an event | Organiser | None (URL param: eventId) | 200 OK: List of enrolments; 404 Not Found: Event not found; 403 Forbidden: Not event organiser |

### Result Management Endpoints

| HTTP Method | Route | Description | Role Required | Request Body | Expected Response |
|---|---|---|---|---|---|
| POST | `/api/results` | Capture participant result | Organiser | `{ "enrolmentId": "int", "finishTime": "time", "position": "int", "status": "string", "notes": "string" }` | 201 Created: Result object; 400 Bad Request: Already has result or validation error; 404 Not Found: Enrolment not found; 403 Forbidden: Not event organiser |
| GET | `/api/results/participant` | Get current user's results | Participant | None | 200 OK: List of results with event and category details |
| GET | `/api/results/enrolment/{enrolmentId}` | Get result for a specific enrolment | Any (Logged in) | None (URL param: enrolmentId) | 200 OK: Result object; 404 Not Found: Result not found or enrolment not found; 403 Forbidden: Not your enrolment or not organiser |
| PUT | `/api/results/{id}` | Update result details | Organiser | `{ "finishTime": "time", "position": "int", "status": "string", "notes": "string" }` | 200 OK: Updated result; 404 Not Found: Result not found; 403 Forbidden: Not event organiser |
| DELETE | `/api/results/{id}` | Delete a result | Organiser | None (URL param: id) | 204 No Content; 404 Not Found: Result not found; 403 Forbidden: Not event organiser |
| GET | `/api/results/event/{eventId}` | Get all results for an event (with leaderboard) | Organiser | None (URL param: eventId, Query: categoryId) | 200 OK: List of results with participant details and rankings; 404 Not Found: Event not found; 403 Forbidden: Not event organiser |
| GET | `/api/results/leaderboard/{eventId}` | Get public leaderboard for an event | None (Public) | None (URL param: eventId, Query: categoryId) | 200 OK: Leaderboard list sorted by position with anonymized names; 404 Not Found: Event not found |

## API Design Decisions

### Why RESTful Design?
- Follows industry standards for API design
- Uses HTTP methods semantically (GET for reading, POST for creating, PUT for updating, DELETE for removing)
- Resource-based URLs make the API intuitive and predictable

### Role-based Access Control
- **Organiser**: Full CRUD on events, categories, enrolments, and results
- **Participant**: Read events, self-enrolment, view own data
- **Public**: Read-only access to events and leaderboards

### Security Considerations
- JWT tokens with short expiry (1 hour)
- HTTPS enforced in production
- Password hashing with BCrypt
- Input validation on all endpoints
- SQL injection prevention through Entity Framework Core

### Performance Optimizations
- Pagination on collection endpoints
- Filtering capabilities to reduce data transfer
- Selective field projection (planned for v2)
- Caching for public endpoints (planned for v2)

### Versioning Strategy
- API version included in URL: `/api/v1/...`
- Backward compatible changes allowed
- Breaking changes require new version

## Validation Rules

### User Registration
- Email: Valid email format, unique
- Password: Minimum 8 characters, at least one uppercase, one lowercase, one number
- FullName: Required, minimum 2 characters
- Role: Must be either "Organiser" or "Participant"

### Event Creation
- EventName: Required, max 255 characters
- EventDate: Must be in the future
- MaxParticipants: Must be > 0
- Status: Must be "Upcoming", "Ongoing", "Completed", or "Cancelled"

### Category Creation
- CategoryName: Required, max 255 characters
- MinAge: Must be >= 0 if provided
- MaxAge: Must be > MinAge if both provided
- GenderRestriction: Must be "None", "Male", or "Female"

### Enrolment
- Participant must not already be enrolled in the category
- Category must have capacity
- Event must not be completed or cancelled

### Result
- FinishTime: Must be valid time format (HH:MM:SS)
- Position: Must be positive integer
- Status: Must be "DNS", "DNF", "Finished", or "Disqualified"

## API Testing Strategy
- Unit tests for all controller methods
- Integration tests for database operations
- Postman collection for manual testing
- GitHub Actions for CI/CD automated testing

## Sample API Calls

### Register as Participant
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "john.runner@example.com",
  "password": "SecurePass123!",
  "fullName": "John Runner",
  "role": "Participant"
}
```

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john.runner@example.com",
  "password": "SecurePass123!"
}
```

### Create Event (as Organiser)
```http
POST /api/events
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "eventName": "City Marathon 2024",
  "description": "Annual city marathon event",
  "eventDate": "2024-06-15T08:00:00Z",
  "location": "Central Park, NYC",
  "maxParticipants": 500,
  "status": "Upcoming"
}
```

### Enrol in Event (as Participant)
```http
POST /api/enrolments
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "categoryId": 1
}
```

### Submit Result (as Organiser)
```http
POST /api/results
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
  "enrolmentId": 1,
  "finishTime": "03:45:20",
  "position": 1,
  "status": "Finished",
  "notes": "First place finish"
}
```

## Postman Collection
A Postman collection will be provided in the `/docs` folder for testing all endpoints.

## API Changelog
- v1.0.0: Initial release (current)

---

This API plan is subject to change during implementation. Any deviations from this plan must be documented in the README.
