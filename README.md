# Community Skill & Resource Exchange Platform

## Group Information
- **Group Number:**15
- **Project Title:** Community Skill & Resource Exchange Platform

### Group Members
| Name | Roll Number |
|------|-------------|
| Saad Ahmed ijaz  | 24P-0669 |
| Zarish Imran     | 24P-0683 |

## Project Description

A full-stack web application that helps people in a local community share their **skills** (tutoring, repairs, IT support, etc.) and **resources** (tools, books, equipment) with one another. Users can register, post what they offer, browse listings, send requests, and leave reviews — creating a self-supporting neighbourhood network.

**GitHub Repository:** `https://github.com/zarish-14/community-skill-resource-exchange-program

---
## Technologies Used

| Layer      | Technology                          |
|------------|-------------------------------------|
| Database   | PostgreSQL 15+                      |
| Backend    | Node.js 18+ / Express.js 4          |
| Frontend   | HTML5, CSS3, Vanilla JavaScript     |


---
## Database Tables
The application uses **10 tables**:

| Table          | Purpose |
|----------------|---------|
| `users`        | User accounts and profiles |
| `category`     | Skill/resource categories |
| `address`      | User addresses |
| `skill`        | Skills posted by users |
| `resource`     | Items listed for sharing |
| `request`      | Requests from users for skills/resources |
| `review`       | Ratings and feedback |
| `notification` | System and activity notifications |
| `transaction`  | Service/resource exchange records |
| `payment`      | Payment details per transaction |

---

## Installation & Setup

### Prerequisites
- Node.js 18 or higher — https://nodejs.org
- PostgreSQL 15 or higher — https://www.postgresql.org/download/
- Git
### Step 1 — Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/skillshare-platform.git
cd skillshare-platform
```
### Step 2 — Install dependencies
```bash
npm install
```
### Step 3 — Set up the database
Open **pgAdmin** or the `psql` terminal and run:

```sql
CREATE DATABASE skillshare_db;
```

Then load the schema:
```bash
psql -U postgres -d skillshare_db -f backend/db/schema.sql
```

### Step 4 — Configure environment variables
```bash
cp .env.example .env
```
Edit `.env` with your PostgreSQL credentials:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=skillshare_db
DB_USER=postgres
DB_PASSWORD=your_password_here
PORT=3000
```

### Step 5 — Run the application
```bash
# Development (auto-restart on changes)
npm run dev

# OR production
npm start
```

### Step 6 — Open in browser
```
http://localhost:3000
```

