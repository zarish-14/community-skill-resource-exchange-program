const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcrypt');
const pool    = require('../db/pool');

// ── CREATE: Register a new user ── POST /api/users/register
router.post('/register', async (req, res) => {
  const { name, email, password, phone, bio } = req.body;
  if (!name || !email || !password)
    return res.status(400).json({ error: 'Name, email and password are required.' });

  try {
    // Check duplicate email
    const exists = await pool.query(
      'SELECT user_id FROM users WHERE email = $1', [email]
    );
    if (exists.rows.length > 0)
      return res.status(409).json({ error: 'Email already registered.' });

    const hashed = await bcrypt.hash(password, 10);

    // Parameterised query — safe from SQL injection
    const result = await pool.query(
      `INSERT INTO users (name, email, password, phone, bio)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING user_id, name, email, phone, bio, created_at`,
      [name, email, hashed, phone || null, bio || null]
    );
    res.status(201).json({ message: 'User registered successfully.', user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── LOGIN ── POST /api/users/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ error: 'Email and password required.' });

  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 AND is_active = TRUE', [email]
    );
    if (result.rows.length === 0)
      return res.status(401).json({ error: 'Invalid credentials.' });

    const user  = result.rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.status(401).json({ error: 'Invalid credentials.' });

    // In production: return a JWT. For this project we return user info.
    const { password: _, ...safeUser } = user;
    res.json({ message: 'Login successful.', user: safeUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── READ: Get all users ── GET /api/users
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT user_id, name, email, phone, bio, avatar_url, is_active, created_at FROM users ORDER BY created_at DESC'
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── READ: Get single user by ID ── GET /api/users/:id
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT u.user_id, u.name, u.email, u.phone, u.bio, u.avatar_url, u.created_at,
              a.city, a.state, a.country,
              ROUND(AVG(r.rating), 1) AS avg_rating,
              COUNT(r.review_id) AS total_reviews
       FROM users u
       LEFT JOIN address a ON a.user_id = u.user_id AND a.is_default = TRUE
       LEFT JOIN review r  ON r.reviewee_id = u.user_id
       WHERE u.user_id = $1
       GROUP BY u.user_id, a.city, a.state, a.country`,
      [id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'User not found.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── UPDATE: Update user profile ── PUT /api/users/:id
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { name, phone, bio, avatar_url } = req.body;
  try {
    const result = await pool.query(
      `UPDATE users SET name = COALESCE($1, name),
                        phone = COALESCE($2, phone),
                        bio = COALESCE($3, bio),
                        avatar_url = COALESCE($4, avatar_url)
       WHERE user_id = $5
       RETURNING user_id, name, email, phone, bio, avatar_url`,
      [name, phone, bio, avatar_url, id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'User not found.' });
    res.json({ message: 'Profile updated.', user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── DELETE: Deactivate (soft delete) user ── DELETE /api/users/:id
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      'UPDATE users SET is_active = FALSE WHERE user_id = $1 RETURNING user_id, name',
      [id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'User not found.' });
    res.json({ message: 'User deactivated.', user: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
