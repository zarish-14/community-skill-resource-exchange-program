const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// CREATE transaction + optional payment
router.post('/', async (req, res) => {
  const { request_id, provider_id, receiver_id, amount, txn_type, method } = req.body;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const txn = await client.query(
      `INSERT INTO transaction (request_id, provider_id, receiver_id, amount, txn_type)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [request_id, provider_id, receiver_id, amount || 0, txn_type || 'service']
    );

    if (amount && amount > 0) {
      await client.query(
        `INSERT INTO payment (txn_id, payer_id, amount, method, status)
         VALUES ($1,$2,$3,$4,'completed')`,
        [txn.rows[0].txn_id, receiver_id, amount, method || 'cash']
      );
    }

    await client.query('COMMIT');
    res.status(201).json({ message: 'Transaction recorded.', transaction: txn.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Transaction failed.' });
  } finally {
    client.release();
  }
});

// READ transactions for a user
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.*, p.method, p.status AS payment_status,
              u1.name AS provider_name, u2.name AS receiver_name
       FROM transaction t
       LEFT JOIN payment p ON p.txn_id = t.txn_id
       JOIN users u1 ON u1.user_id = t.provider_id
       JOIN users u2 ON u2.user_id = t.receiver_id
       WHERE t.provider_id = $1 OR t.receiver_id = $1
       ORDER BY t.created_at DESC`,
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// UPDATE transaction status
router.put('/:id', async (req, res) => {
  const { status } = req.body;
  try {
    const result = await pool.query(
      'UPDATE transaction SET status = $1 WHERE txn_id = $2 RETURNING *',
      [status, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

// DELETE
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM transaction WHERE txn_id = $1', [req.params.id]);
    res.json({ message: 'Transaction deleted.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
