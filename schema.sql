-- ============================================================
-- Community Skill & Resource Exchange Platform - DB Schema
-- PostgreSQL
-- ============================================================

-- Drop tables in reverse dependency order (for clean resets)
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS transaction CASCADE;
DROP TABLE IF EXISTS notification CASCADE;
DROP TABLE IF EXISTS review CASCADE;
DROP TABLE IF EXISTS request CASCADE;
DROP TABLE IF EXISTS resource CASCADE;
DROP TABLE IF EXISTS skill CASCADE;
DROP TABLE IF EXISTS address CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ─── USERS ───────────────────────────────────────────────────
CREATE TABLE users (
    user_id     SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,          -- hashed (bcrypt)
    phone       VARCHAR(20),
    bio         TEXT,
    avatar_url  TEXT,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── CATEGORY ────────────────────────────────────────────────
CREATE TABLE category (
    category_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) UNIQUE NOT NULL,
    description   TEXT,
    icon          VARCHAR(50)          -- emoji or icon name
);

-- ─── ADDRESS ─────────────────────────────────────────────────
CREATE TABLE address (
    address_id  SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    street      VARCHAR(200),
    city        VARCHAR(100) NOT NULL,
    state       VARCHAR(100),
    country     VARCHAR(100) DEFAULT 'Pakistan',
    zip_code    VARCHAR(20),
    is_default  BOOLEAN DEFAULT FALSE
);

-- ─── SKILL ───────────────────────────────────────────────────
CREATE TABLE skill (
    skill_id      SERIAL PRIMARY KEY,
    user_id       INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id   INT REFERENCES category(category_id),
    title         VARCHAR(150) NOT NULL,
    description   TEXT,
    price_type    VARCHAR(20) DEFAULT 'free'    -- 'free', 'paid', 'barter'
                  CHECK (price_type IN ('free','paid','barter')),
    price         NUMERIC(10,2) DEFAULT 0,
    is_available  BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── RESOURCE ────────────────────────────────────────────────
CREATE TABLE resource (
    resource_id   SERIAL PRIMARY KEY,
    user_id       INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id   INT REFERENCES category(category_id),
    title         VARCHAR(150) NOT NULL,
    description   TEXT,
    condition     VARCHAR(50) DEFAULT 'good'    -- 'new','good','fair','poor'
                  CHECK (condition IN ('new','good','fair','poor')),
    share_type    VARCHAR(20) DEFAULT 'borrow'  -- 'borrow','donate','sell'
                  CHECK (share_type IN ('borrow','donate','sell')),
    is_available  BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── REQUEST ─────────────────────────────────────────────────
CREATE TABLE request (
    request_id    SERIAL PRIMARY KEY,
    requester_id  INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    skill_id      INT REFERENCES skill(skill_id) ON DELETE SET NULL,
    resource_id   INT REFERENCES resource(resource_id) ON DELETE SET NULL,
    message       TEXT,
    status        VARCHAR(20) DEFAULT 'pending'
                  CHECK (status IN ('pending','accepted','rejected','completed','cancelled')),
    requested_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT request_has_target CHECK (
        (skill_id IS NOT NULL AND resource_id IS NULL) OR
        (resource_id IS NOT NULL AND skill_id IS NULL)
    )
);

-- ─── REVIEW ──────────────────────────────────────────────────
CREATE TABLE review (
    review_id     SERIAL PRIMARY KEY,
    reviewer_id   INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    reviewee_id   INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    request_id    INT REFERENCES request(request_id) ON DELETE SET NULL,
    rating        INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment       TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT no_self_review CHECK (reviewer_id <> reviewee_id)
);

-- ─── NOTIFICATION ────────────────────────────────────────────
CREATE TABLE notification (
    notif_id    SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    type        VARCHAR(50),                    -- 'request','review','system'
    message     TEXT NOT NULL,
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── TRANSACTION ─────────────────────────────────────────────
CREATE TABLE transaction (
    txn_id        SERIAL PRIMARY KEY,
    request_id    INT NOT NULL REFERENCES request(request_id) ON DELETE CASCADE,
    provider_id   INT NOT NULL REFERENCES users(user_id),
    receiver_id   INT NOT NULL REFERENCES users(user_id),
    amount        NUMERIC(10,2) DEFAULT 0,
    txn_type      VARCHAR(20) DEFAULT 'service'
                  CHECK (txn_type IN ('service','borrow','donation')),
    status        VARCHAR(20) DEFAULT 'pending'
                  CHECK (status IN ('pending','completed','failed','refunded')),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── PAYMENT ─────────────────────────────────────────────────
CREATE TABLE payment (
    payment_id      SERIAL PRIMARY KEY,
    txn_id          INT NOT NULL REFERENCES transaction(txn_id) ON DELETE CASCADE,
    payer_id        INT NOT NULL REFERENCES users(user_id),
    amount          NUMERIC(10,2) NOT NULL,
    method          VARCHAR(50) DEFAULT 'cash'  -- 'cash','easypaisa','jazzcash','card'
                    CHECK (method IN ('cash','easypaisa','jazzcash','card')),
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending','completed','failed','refunded')),
    reference_no    VARCHAR(100),
    paid_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─── INDEXES ─────────────────────────────────────────────────
CREATE INDEX idx_skill_user      ON skill(user_id);
CREATE INDEX idx_skill_category  ON skill(category_id);
CREATE INDEX idx_resource_user   ON resource(user_id);
CREATE INDEX idx_request_status  ON request(status);
CREATE INDEX idx_notif_user      ON notification(user_id);
CREATE INDEX idx_review_reviewee ON review(reviewee_id);

-- ════════════════════════════════════════════════════════════
-- SEED DATA — All 10 Tables
-- ════════════════════════════════════════════════════════════

-- ─── 1. CATEGORY ─────────────────────────────────────────────
INSERT INTO category (name, description, icon) VALUES
  ('Education',    'Tutoring, coaching, teaching',           '📚'),
  ('Repairs',      'Home, electronics, vehicle repairs',     '🔧'),
  ('Technology',   'IT support, web dev, design',            '💻'),
  ('Health',       'Fitness, nutrition, mental wellness',     '🏥'),
  ('Arts & Crafts','Painting, sewing, handicrafts',          '🎨'),
  ('Transport',    'Rides, delivery, moving help',           '🚗'),
  ('Tools',        'Power tools, gardening equipment',       '🪚'),
  ('Books',        'Textbooks, novels, reference material',  '📖');

-- ─── 2. USERS ────────────────────────────────────────────────
-- Passwords are bcrypt hashes of 'password123'
INSERT INTO users (name, email, password, phone, bio) VALUES
  ('Ali Hassan',     'ali@example.com',     '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-300-1111111', 'Math teacher with 5 years of experience in Peshawar.'),
  ('Sara Khan',      'sara@example.com',    '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-301-2222222', 'Graphic designer and web developer. Love helping others learn tech.'),
  ('Usman Tariq',    'usman@example.com',   '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-302-3333333', 'Electrician and home repair expert. Available on weekends.'),
  ('Fatima Noor',    'fatima@example.com',  '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-303-4444444', 'Fitness coach and nutritionist. Helping community stay healthy.'),
  ('Bilal Ahmed',    'bilal@example.com',   '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-304-5555555', 'Computer science student. Can help with programming and IT issues.'),
  ('Zara Malik',     'zara@example.com',    '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-305-6666666', 'Artist and craft teacher. Runs weekend art workshops.'),
  ('Hamza Qureshi',  'hamza@example.com',   '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-306-7777777', 'Car mechanic with 10 years experience. Also gives driving lessons.'),
  ('Ayesha Siddiqui','ayesha@example.com',  '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+92-307-8888888', 'English language teacher. Specialises in IELTS preparation.');
-- Note: All sample passwords above = 'password123'

-- ─── 3. ADDRESS ──────────────────────────────────────────────
INSERT INTO address (user_id, street, city, state, country, zip_code, is_default) VALUES
  (1, 'House 12, Street 4, Hayatabad',   'Peshawar',    'KPK',   'Pakistan', '25000', TRUE),
  (2, 'Flat 3B, University Town',        'Peshawar',    'KPK',   'Pakistan', '25120', TRUE),
  (3, 'Shop 7, Saddar Bazaar',           'Peshawar',    'KPK',   'Pakistan', '25000', TRUE),
  (4, 'House 45, Phase 5, DHA',          'Peshawar',    'KPK',   'Pakistan', '25100', TRUE),
  (5, 'Hostel Block C, UET Campus',      'Peshawar',    'KPK',   'Pakistan', '25120', TRUE),
  (6, 'House 8, Gulbahar Colony',        'Peshawar',    'KPK',   'Pakistan', '25000', TRUE),
  (7, 'Workshop, Ring Road',             'Peshawar',    'KPK',   'Pakistan', '25000', TRUE),
  (8, 'House 22, Warsak Road',           'Peshawar',    'KPK',   'Pakistan', '25100', TRUE);

-- ─── 4. SKILL ────────────────────────────────────────────────
INSERT INTO skill (user_id, category_id, title, description, price_type, price, is_available) VALUES
  (1, 1, 'Mathematics Tutoring (Matric & FSc)', 'I teach Algebra, Calculus and Statistics for Matric and FSc students. Home visits available in Hayatabad area.', 'paid',   500.00, TRUE),
  (1, 1, 'Physics Tutoring',                    'Conceptual and numerical physics for FSc Part 1 and Part 2. Group sessions available at discount.', 'paid',   400.00, TRUE),
  (2, 3, 'Web Development Training',            'Learn HTML, CSS, JavaScript from scratch. I provide hands-on projects and mentoring.', 'paid',   800.00, TRUE),
  (2, 3, 'Graphic Design Help',                 'Logo design, poster making, Canva and Photoshop tutorials. Portfolio building assistance.', 'barter', 0.00,   TRUE),
  (3, 2, 'Home Electrical Repairs',             'Fix wiring, fans, switches, and electrical faults. Safe and professional work guaranteed.', 'paid',   600.00, TRUE),
  (3, 2, 'Plumbing Services',                   'Pipe fixing, water pump installation, and leakage repair. Available on call.', 'paid',   500.00, TRUE),
  (4, 4, 'Personal Fitness Training',           'Customised workout plans for weight loss or muscle gain. Home visits or outdoor sessions in Shahi Bagh Park.', 'paid',   700.00, TRUE),
  (4, 4, 'Nutrition & Diet Planning',           'Get a personalised meal plan based on your health goals. Online consultations also available.', 'free',   0.00,   TRUE),
  (5, 3, 'Python Programming Tutoring',         'Learn Python from basics to OOP and file handling. Assignments and projects included.', 'free',   0.00,   TRUE),
  (5, 3, 'PC Troubleshooting & Repair',         'Fix slow computers, remove viruses, reinstall Windows, hardware upgrades.', 'paid',   300.00, TRUE),
  (6, 5, 'Painting & Drawing Classes',          'Watercolour and pencil sketching for beginners. Materials provided in first session.', 'paid',   400.00, TRUE),
  (6, 5, 'Handmade Craft Workshops',            'Learn embroidery, crochet and jewellery making. Weekend group classes available.', 'paid',   350.00, TRUE),
  (7, 2, 'Car Engine Repair & Service',         'Complete car servicing, oil change, brake repair and engine diagnostics.', 'paid',   1200.00,TRUE),
  (7, 6, 'Driving Lessons',                     'Learn driving with a patient and experienced instructor. Both manual and automatic.', 'paid',   800.00, TRUE),
  (8, 1, 'English Language Tutoring',           'Spoken English, grammar correction and IELTS preparation. Online and in-person sessions.', 'paid',   600.00, TRUE),
  (8, 1, 'Essay & Report Writing Help',         'Assistance with academic essays, CVs, cover letters and professional reports.', 'barter', 0.00,   TRUE);

-- ─── 5. RESOURCE ─────────────────────────────────────────────
INSERT INTO resource (user_id, category_id, title, description, condition, share_type, is_available) VALUES
  (1, 8,  'FSc Physics Textbook (Part 1 & 2)',    'Punjab textbook board FSc Physics. Good condition, no missing pages.',            'good', 'borrow',  TRUE),
  (1, 8,  'Matric Mathematics Guide',             'Complete solved exercises. Very helpful for board exam preparation.',             'good', 'donate',  TRUE),
  (2, 3,  'Laptop — Dell Inspiron 15',            'Available for short-term loan (1 week max). Core i5, 8GB RAM, Windows 11.',      'good', 'borrow',  TRUE),
  (3, 7,  'Power Drill (Bosch)',                  'Corded electric drill, ideal for wall drilling. Return within 3 days please.',   'good', 'borrow',  TRUE),
  (3, 7,  'Toolbox (Full Set)',                   'Screwdrivers, spanners, pliers, tape measure. Borrow for home projects.',        'good', 'borrow',  TRUE),
  (4, 4,  'Yoga Mat',                             'Clean and lightly used yoga mat. Available to borrow for workout sessions.',     'good', 'borrow',  TRUE),
  (4, 4,  'Dumbbell Set (5kg pair)',              'Two 5kg dumbbells. Donate to someone who needs them for home workouts.',         'good', 'donate',  TRUE),
  (5, 3,  'C++ Programming Book (Deitel)',        'University-level C++ textbook. Borrow for a semester, return in good condition.','fair', 'borrow',  TRUE),
  (5, 8,  'Data Structures Handwritten Notes',    'Complete handwritten notes for Data Structures and Algorithms course.',          'good', 'donate',  TRUE),
  (6, 5,  'Watercolour Paint Set',                'Professional grade paints, 24 colours. Borrow for your art project.',           'good', 'borrow',  TRUE),
  (6, 5,  'Canvas Boards (Pack of 5)',            'Blank stretched canvases ready to paint. Selling at low price.',                'new',  'sell',    TRUE),
  (7, 7,  'Car Jack (Hydraulic)',                 'Heavy-duty hydraulic jack, 2 tonne capacity. Borrow for tyre change.',          'good', 'borrow',  TRUE),
  (7, 7,  'Jump Start Cables',                    'Car battery jump-start cables. Borrow anytime you need them.',                  'good', 'borrow',  TRUE),
  (8, 8,  'IELTS Preparation Books (Full Set)',   'Cambridge IELTS books 1 through 14. Available to borrow one at a time.',       'good', 'borrow',  TRUE),
  (8, 8,  'English Grammar in Use (Murphy)',      'Classic grammar reference book. Donate to a student who needs it.',             'fair', 'donate',  TRUE);

-- ─── 6. REQUEST ──────────────────────────────────────────────
INSERT INTO request (requester_id, skill_id, resource_id, message, status) VALUES
  (2, 1,  NULL, 'Salaam! I need help with FSc Calculus. Can we arrange sessions 3 times a week?',         'accepted'),
  (3, 3,  NULL, 'I want to learn web development. When can we start? I am free in evenings.',             'pending'),
  (4, 9,  NULL, 'Can you teach me Python? I am a beginner but a fast learner.',                           'completed'),
  (5, 7,  NULL, 'I would like personal training sessions, 3 mornings a week. What is your schedule?',     'accepted'),
  (6, 13, NULL, 'My car engine is making a noise. Can you check it this Saturday?',                       'pending'),
  (7, 15, NULL, 'I need IELTS preparation. My test is in 2 months. Can we do intensive sessions?',        'accepted'),
  (1, 11, NULL, 'I want to join painting classes for my daughter aged 10. Is that okay?',                 'completed'),
  (8, 5,  NULL, 'My fan stopped working. Can you come and fix it tomorrow morning?',                      'rejected'),
  (3, NULL, 4,  'Can I borrow the power drill this weekend? I need to hang shelves.',                     'accepted'),
  (5, NULL, 2,  'I will take the Laptop if still available. Just for one week for a project.',            'pending'),
  (6, NULL, 6,  'Can I borrow the yoga mat for 2 weeks? Just started doing yoga at home.',               'completed'),
  (1, NULL, 14, 'I need the IELTS Cambridge books. Can I borrow books 10 to 12 first?',                  'accepted'),
  (7, NULL, 8,  'Please lend me the C++ book. I have an exam next month.',                               'pending'),
  (4, NULL, 12, 'Need the car jack this Sunday for a tyre change. Will return same day.',                 'accepted');

-- ─── 7. REVIEW ───────────────────────────────────────────────
INSERT INTO review (reviewer_id, reviewee_id, request_id, rating, comment) VALUES
  (2, 1, 1, 5, 'Excellent teacher! Ali explained Calculus in a very simple way. Highly recommend.'),
  (4, 5, 3, 5, 'Bilal is very patient and explains everything step by step. Great Python teacher.'),
  (5, 4, 4, 4, 'Fatima is very professional and motivating. Good training sessions.'),
  (1, 6, 7, 5, 'Zara is wonderful with kids. My daughter loved the painting class.'),
  (7, 8, 6, 5, 'Ayesha is a fantastic English teacher. Very structured IELTS preparation.'),
  (3, 3, 9, 4, 'Sara was very helpful. The power drill worked perfectly. Returned it the next day.'),
  (6, 4, 11, 5, 'Got the yoga mat in great condition. Fatima is very generous. Thank you!'),
  (1, 8, 12, 4, 'IELTS books are very helpful. Ayesha is kind and easy to communicate with.'),
  (3, 2, 2, 3, 'Good knowledge but sessions were sometimes delayed. Overall still useful.'),
  (8, 3, 8, 2, 'The repair was not done properly the first time and had to call again.');

-- ─── 8. NOTIFICATION ─────────────────────────────────────────
INSERT INTO notification (user_id, type, message, is_read) VALUES
  (1, 'request',  'Sara Khan has sent a request for your Mathematics Tutoring skill.',         FALSE),
  (1, 'review',   'You received a 5-star review from Sara Khan. Great work!',                 TRUE),
  (2, 'request',  'Usman Tariq has requested your Web Development Training.',                 FALSE),
  (3, 'request',  'Bilal Ahmed wants to borrow your Power Drill this weekend.',               TRUE),
  (4, 'request',  'Bilal Ahmed has sent a request for Personal Fitness Training.',            FALSE),
  (4, 'review',   'You received a 4-star review from Bilal Ahmed.',                          TRUE),
  (5, 'request',  'Fatima Noor has requested your Python Programming Tutoring.',              TRUE),
  (5, 'request',  'Zara Malik wants to borrow your Laptop.',                                 FALSE),
  (6, 'request',  'Hamza Qureshi has requested your Car Engine Repair service.',             FALSE),
  (6, 'review',   'Ali Hassan left a 5-star review for your Painting Classes. Well done!',   FALSE),
  (7, 'request',  'Ayesha Siddiqui requested IELTS tutoring. Please respond.',               TRUE),
  (7, 'request',  'Fatima Noor wants to borrow your Car Jack this Sunday.',                  FALSE),
  (8, 'request',  'Ali Hassan borrowed your IELTS books. Please confirm.',                   FALSE),
  (8, 'review',   'Hamza Qureshi gave you a 5-star review for English tutoring!',            TRUE),
  (2, 'system',   'Welcome to SkillShare! Complete your profile to get more requests.',       TRUE),
  (3, 'system',   'Your listing for Home Electrical Repairs is getting views!',              FALSE);

-- ─── 9. TRANSACTION ──────────────────────────────────────────
INSERT INTO transaction (request_id, provider_id, receiver_id, amount, txn_type, status) VALUES
  (1,  1, 2,  1500.00, 'service',  'completed'),   -- 3 sessions of Math tutoring
  (3,  5, 4,  0.00,    'service',  'completed'),   -- Free Python tutoring
  (4,  4, 5,  2100.00, 'service',  'completed'),   -- 3 fitness sessions
  (7,  6, 1,  800.00,  'service',  'completed'),   -- 2 painting classes
  (6,  8, 7,  1200.00, 'service',  'completed'),   -- 2 IELTS sessions
  (9,  3, 3,  0.00,    'borrow',   'completed'),   -- Power drill borrow (free)
  (11, 4, 6,  0.00,    'borrow',   'completed'),   -- Yoga mat borrow (free)
  (12, 8, 1,  0.00,    'borrow',   'completed'),   -- IELTS books borrow (free)
  (14, 7, 4,  0.00,    'borrow',   'completed');   -- Car jack borrow (free)

-- ─── 10. PAYMENT ─────────────────────────────────────────────
INSERT INTO payment (txn_id, payer_id, amount, method, status, reference_no) VALUES
  (1, 2, 1500.00, 'easypaisa', 'completed', 'EP-2024-001122'),
  (3, 5, 2100.00, 'jazzcash',  'completed', 'JC-2024-003344'),
  (4, 1, 800.00,  'cash',      'completed', 'CASH-001'),
  (5, 7, 1200.00, 'card',      'completed', 'CARD-2024-007788'),
  (6, 7, 1200.00, 'easypaisa', 'completed', 'EP-2024-009900');
-- Note: borrow transactions (txn 6,7,8,9) have no payment as they are free
