const express = require ('express')
const app = express()

const peopleRouter = require('./routes/people')

app.use(express.json())
app.get("/", (req, res)=>{
    res.send("Welcome to Express API - to know other routes append on URL /api/people")
})

app.use('/api/people', peopleRouter)

const port = 3000
app.listen(port, ()=>{
    console.log(`The server is listening on port ${port}`)
})