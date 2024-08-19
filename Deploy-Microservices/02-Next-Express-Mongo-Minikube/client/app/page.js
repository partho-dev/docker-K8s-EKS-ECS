// import Image from "next/image";
'use client'
import { useEffect, useState } from "react";
import axios from "axios";
const serverApi = "http://localhost:3002/api/v1/products/"

export default function Home() {

  const [products, setProducts] = useState([])
  const [productName, setProductName ] = useState()
  const [productPrice, setProductPrice] = useState()

// SetChange 
const handleNameChange = (e)=>{
  setProductName(e.target.value)
}
const handlePriceChange = (e)=>{
  setProductPrice(e.target.value)
}

//push the data to DB upon submit
const handleSubmit = async (e)=>{
  e.preventDefault()

  const productData = {
    name : productName,
    price : productPrice
  }

  try {
    await axios.post(serverApi, productData)

    //refresh the list of products with the new lists once the products are pushed into DB
    const response = await axios.get(serverApi)
    setProducts(response.data)
    setProductName('')
    setProductPrice('')
  } catch (error) {
    console.log(error.message)
    
  }
}

  useEffect(()=>{
    const fetchAPI = async ()=>{
      try {
      let response = await axios.get(serverApi)
      console.log(response.data)
      setProducts(response.data)
      } catch (error) {
        console.log(error)
      }
    } 
    fetchAPI()
  }, [])

  return (
    <main className="flex min-h-screen p-10 gap-10 ">

      <div>
        <p> Create Products</p>
        <form onSubmit={handleSubmit} >
          <div className='flex gap-6'>
          <input className=' text-slate-950 rounded-md mr-2 placeholder-slate-400 focus:outline-none mt-1 px-2' type="text" placeholder = "Samsung" value = {productName} onChange={handleNameChange} />
          <input className=' text-slate-950 rounded-md mr-2 placeholder-slate-400 focus:outline-none mt-1 px-2' type="text" placeholder = "100" value={productPrice} onChange={handlePriceChange} />
          <button> Create Product </button>
          </div>
        </form>

      </div>

      <div>
      <p> List of Producrs</p>
      {products.length > 0 ? products.map((elem)=>( 
      <div key={elem._id} className='flex gap-3' > 
        <p> {elem.name}</p> 
        <p> {elem.price}</p> 
      </div> )) : <h1> No Products</h1>}
      </div>

    </main>
  );
}
