// ─── REQUESTS ────────────────────────────────────────────────
const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// CREATE
router.post('/', async (req, res) => {
  const { requester_id, skill_id, resource_id, message } = req.body;
  if (!requester_id || (!skill_id && !resource_id))
    return res.status(400).json({ error: 'requester_id and either skill_id or resource_id required.' });
  try {
    const result = await pool.query(
      `INSERT INTO request (requester_id, skill_id, resource_id, message)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [requester_id, skill_id || null, resource_id || null, message || null]
    );
    res.status(201).json({ message: 'Request submitted.', request: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// READ ALL (with optional filter by user)
router.get('/', async (req, res) => {
  const { user_id, status } = req.query;
  let query = `
    SELECT rq.*, u.name AS requester_name,
           s.title AS skill_title, r.title AS resource_title
    FROM request rq
    JOIN users u ON u.user_id = rq.requester_id
    LEFT JOIN skill s    ON s.skill_id = rq.skill_id
    LEFT JOIN resource r ON r.resource_id = rq.resource_id
    WHERE 1=1
  `;
  const params = [];
  if (user_id) { params.push(user_id); query += ` AND rq.requester_id = $${params.length}`; }
  if (status)  { params.push(status);  query += ` AND rq.status = $${params.length}`; }
  query += ' ORDER BY rq.requested_at DESC';
  try {
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// READ ONE
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT rq.*, u.name AS requester_name,
              s.title AS skill_title, r.title AS resource_title
       FROM request rq
       JOIN users u ON u.user_id = rq.requester_id
       LEFT JOIN skill s    ON s.skill_id = rq.skill_id
       LEFT JOIN resource r ON r.resource_id = rq.resource_id
       WHERE rq.request_id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found.' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// UPDATE status
router.put('/:id', async (req, res) => {
  const { status } = req.body;
  try {
    const result = await pool.query(
      `UPDATE request SET status = $1, updated_at = NOW()
       WHERE request_id = $2 RETURNING *`,
      [status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found.' });
    res.json({ message: 'Request updated.', request: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// DELETE
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM request WHERE request_id = $1 RETURNING request_id',
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found.' });
    res.json({ message: 'Request cancelled.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
