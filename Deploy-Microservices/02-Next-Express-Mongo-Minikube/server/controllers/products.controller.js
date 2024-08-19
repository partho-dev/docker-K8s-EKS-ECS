const Product = require("../models/product.model")


//Create products
const createProducts = async (req, res)=>{
    try {
        const payload = req.body
        const newProduct = new Product(payload)
        await newProduct.save()
        res.status(200).send(newProduct)

    } catch (error) {
        console.log(error.message)
    }
}


// Get Product
const getProducts = async (req, res)=>{
    // res.send("Hey, This is the product")
    const newProduct = await Product.find()
    try {
        if (newProduct.length > 0) {
            res.send(newProduct)
        }else{
            res.send("No Products Found")
        }
    } catch (error) {
        console.log(error.message)
    }
}


module.exports = {createProducts, getProducts}