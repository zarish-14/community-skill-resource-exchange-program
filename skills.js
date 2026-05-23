const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// ── CREATE ── POST /api/skills
router.post('/', async (req, res) => {
  const { user_id, category_id, title, description, price_type, price } = req.body;
  if (!user_id || !title)
    return res.status(400).json({ error: 'user_id and title are required.' });
  try {
    const result = await pool.query(
      `INSERT INTO skill (user_id, category_id, title, description, price_type, price)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING *`,
      [user_id, category_id || null, title, description || null,
       price_type || 'free', price || 0]
    );
    res.status(201).json({ message: 'Skill posted.', skill: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── READ ALL ── GET /api/skills?category=&search=&available=
router.get('/', async (req, res) => {
  const { category, search, available } = req.query;
  let query = `
    SELECT s.*, u.name AS provider_name, c.name AS category_name, c.icon AS category_icon
    FROM skill s
    JOIN users u ON u.user_id = s.user_id
    LEFT JOIN category c ON c.category_id = s.category_id
    WHERE 1=1
  `;
  const params = [];

  if (available === 'true') {
    params.push(true);
    query += ` AND s.is_available = $${params.length}`;
  }
  if (category) {
    params.push(category);
    query += ` AND s.category_id = $${params.length}`;
  }
  if (search) {
    params.push(`%${search}%`);
    query += ` AND (s.title ILIKE $${params.length} OR s.description ILIKE $${params.length})`;
  }

  query += ' ORDER BY s.created_at DESC';

  try {
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── READ ONE ── GET /api/skills/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT s.*, u.name AS provider_name, u.email AS provider_email,
              c.name AS category_name, c.icon
       FROM skill s
       JOIN users u ON u.user_id = s.user_id
       LEFT JOIN category c ON c.category_id = s.category_id
       WHERE s.skill_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Skill not found.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── UPDATE ── PUT /api/skills/:id
router.put('/:id', async (req, res) => {
  const { title, description, price_type, price, is_available, category_id } = req.body;
  try {
    const result = await pool.query(
      `UPDATE skill SET
         title        = COALESCE($1, title),
         description  = COALESCE($2, description),
         price_type   = COALESCE($3, price_type),
         price        = COALESCE($4, price),
         is_available = COALESCE($5, is_available),
         category_id  = COALESCE($6, category_id)
       WHERE skill_id = $7
       RETURNING *`,
      [title, description, price_type, price, is_available, category_id, req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Skill not found.' });
    res.json({ message: 'Skill updated.', skill: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── DELETE ── DELETE /api/skills/:id
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM skill WHERE skill_id = $1 RETURNING skill_id, title',
      [req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Skill not found.' });
    res.json({ message: 'Skill deleted.', skill: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
