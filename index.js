const app = require('express')()

app.all('/:id', (req, res)=>{
  console.log(req.params.id)
  res.sendFile("pixel.gif", {root: __dirname})
})

app.all('*', (req, res)=>{
  console.error("Accessed main page")
  res.sendStatus(200)
})

app.listen(process.env.PORT)

console.log("Now serving pixels.")
