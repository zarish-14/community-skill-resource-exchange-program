const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// ── CREATE ── POST /api/resources
router.post('/', async (req, res) => {
  const { user_id, category_id, title, description, condition, share_type } = req.body;
  if (!user_id || !title)
    return res.status(400).json({ error: 'user_id and title are required.' });
  try {
    const result = await pool.query(
      `INSERT INTO resource (user_id, category_id, title, description, condition, share_type)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [user_id, category_id || null, title, description || null,
       condition || 'good', share_type || 'borrow']
    );
    res.status(201).json({ message: 'Resource listed.', resource: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── READ ALL ── GET /api/resources
router.get('/', async (req, res) => {
  const { category, search, share_type } = req.query;
  let query = `
    SELECT r.*, u.name AS owner_name, c.name AS category_name, c.icon
    FROM resource r
    JOIN users u ON u.user_id = r.user_id
    LEFT JOIN category c ON c.category_id = r.category_id
    WHERE r.is_available = TRUE
  `;
  const params = [];

  if (category) {
    params.push(category);
    query += ` AND r.category_id = $${params.length}`;
  }
  if (share_type) {
    params.push(share_type);
    query += ` AND r.share_type = $${params.length}`;
  }
  if (search) {
    params.push(`%${search}%`);
    query += ` AND (r.title ILIKE $${params.length} OR r.description ILIKE $${params.length})`;
  }

  query += ' ORDER BY r.created_at DESC';

  try {
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── READ ONE ── GET /api/resources/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT r.*, u.name AS owner_name, u.email AS owner_email,
              c.name AS category_name
       FROM resource r
       JOIN users u ON u.user_id = r.user_id
       LEFT JOIN category c ON c.category_id = r.category_id
       WHERE r.resource_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Resource not found.' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── UPDATE ── PUT /api/resources/:id
router.put('/:id', async (req, res) => {
  const { title, description, condition, share_type, is_available } = req.body;
  try {
    const result = await pool.query(
      `UPDATE resource SET
         title        = COALESCE($1, title),
         description  = COALESCE($2, description),
         condition    = COALESCE($3, condition),
         share_type   = COALESCE($4, share_type),
         is_available = COALESCE($5, is_available)
       WHERE resource_id = $6 RETURNING *`,
      [title, description, condition, share_type, is_available, req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Resource not found.' });
    res.json({ message: 'Resource updated.', resource: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── DELETE ── DELETE /api/resources/:id
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM resource WHERE resource_id = $1 RETURNING resource_id, title',
      [req.params.id]
    );
    if (result.rows.length === 0)
      return res.status(404).json({ error: 'Resource not found.' });
    res.json({ message: 'Resource deleted.', resource: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
