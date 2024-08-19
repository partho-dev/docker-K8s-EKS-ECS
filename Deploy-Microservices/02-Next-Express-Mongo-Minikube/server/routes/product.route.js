const express = require("express")
const router = express.Router()

const {getProducts, createProducts } = require("../controllers/products.controller")

// Create 
router.post("/products", createProducts)
//Get 
router.get("/products", getProducts)


module.exports = router