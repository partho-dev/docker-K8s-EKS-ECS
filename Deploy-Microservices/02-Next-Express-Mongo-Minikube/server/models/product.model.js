const mongoose = require("mongoose")

const productSchema = new mongoose.Schema({
    name : String,
    price : Number
}, {timestamps:true, toJSON:{getters:true}, id:false})

const Product = mongoose.model("Product", productSchema)

module.exports = Product