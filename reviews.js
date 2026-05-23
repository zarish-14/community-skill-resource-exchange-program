const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// CREATE
router.post('/', async (req, res) => {
  const { reviewer_id, reviewee_id, request_id, rating, comment } = req.body;
  if (!reviewer_id || !reviewee_id || !rating)
    return res.status(400).json({ error: 'reviewer_id, reviewee_id, and rating are required.' });
  if (reviewer_id == reviewee_id)
    return res.status(400).json({ error: 'Cannot review yourself.' });
  try {
    const result = await pool.query(
      `INSERT INTO review (reviewer_id, reviewee_id, request_id, rating, comment)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [reviewer_id, reviewee_id, request_id || null, rating, comment || null]
    );
    res.status(201).json({ message: 'Review submitted.', review: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error.' });
  }
});

// READ: reviews for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT rv.*, u.name AS reviewer_name
       FROM review rv
       JOIN users u ON u.user_id = rv.reviewer_id
       WHERE rv.reviewee_id = $1
       ORDER BY rv.created_at DESC`,
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// UPDATE
router.put('/:id', async (req, res) => {
  const { rating, comment } = req.body;
  try {
    const result = await pool.query(
      `UPDATE review SET rating = COALESCE($1, rating), comment = COALESCE($2, comment)
       WHERE review_id = $3 RETURNING *`,
      [rating, comment, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Review not found.' });
    res.json({ message: 'Review updated.', review: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// DELETE
router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM review WHERE review_id = $1 RETURNING review_id',
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Review not found.' });
    res.json({ message: 'Review deleted.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
