const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// ── GET unread notifications for a user
router.get('/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM notification WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── CREATE notification
router.post('/', async (req, res) => {
  const { user_id, type, message } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO notification (user_id, type, message) VALUES ($1,$2,$3) RETURNING *`,
      [user_id, type || 'system', message]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── MARK as read
router.put('/:id/read', async (req, res) => {
  try {
    await pool.query(
      'UPDATE notification SET is_read = TRUE WHERE notif_id = $1',
      [req.params.id]
    );
    res.json({ message: 'Marked as read.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// ── DELETE notification
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM notification WHERE notif_id = $1', [req.params.id]);
    res.json({ message: 'Notification deleted.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
