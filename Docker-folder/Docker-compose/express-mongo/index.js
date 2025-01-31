const express = require("express")
const mongoose = require("mongoose")
require("dotenv").config()
const app = express()

app.get("/", (req, res)=>{
    res.send("Connected to express")

})

const dbConnect = async()=>{
    try {
        // await mongoose.connect('mongodb://mongo:27017/mydatabase')
        await mongoose.connect(process.env.MONGO_URL)
        console.log("mongo db connection done")

        app.listen(process.env.PORT, ()=>{
            console.log(`The app is listening on port ${process.env.PORT}`)
        })
        
    } catch (error) {
        console.log('db connection was not done')
    }
    
}

dbConnect()
