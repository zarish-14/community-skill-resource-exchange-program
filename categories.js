const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM category ORDER BY name');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

router.post('/', async (req, res) => {
  const { name, description, icon } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO category (name, description, icon) VALUES ($1,$2,$3) RETURNING *',
      [name, description || null, icon || null]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

router.put('/:id', async (req, res) => {
  const { name, description, icon } = req.body;
  try {
    const result = await pool.query(
      `UPDATE category SET name = COALESCE($1,name), description = COALESCE($2,description),
       icon = COALESCE($3,icon) WHERE category_id = $4 RETURNING *`,
      [name, description, icon, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM category WHERE category_id = $1', [req.params.id]);
    res.json({ message: 'Category deleted.' });
  } catch (err) {
    res.status(500).json({ error: 'Server error.' });
  }
});

module.exports = router;
