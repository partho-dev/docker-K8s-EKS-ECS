const express = require("express")
const app = express()
const mongoose = require("mongoose")
const cors = require("cors")
require("dotenv").config()
app.use(express.json())
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST'],
  }))
// app.use(express.urlencoded({extends:true}))

const productRoute = require("./routes/product.route")

// Routes
app.use("/api/v1", productRoute)

const port = process.env.PORT || 3002

const dbConnection = async ()=>{
    try {
        await mongoose.connect(process.env.MONGO_URL)
        // await mongoose.connect(`mongodb://k8s-mongo-service/<db-collection-name>`)
        console.log("Db connection successful")
        app.listen(port, ()=>{
            console.log(`The server is connected to port: ${port}`)
        })

    } catch (error) {
        console.log(error.message)
        
    }
}
dbConnection()