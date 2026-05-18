/* //step 1: Create the function 
function updateVisitorCount(){
    //step 2: Grab the HTML element by its ID
    let countElement= document.getElementById("visitor-count");

    //step 3: Change the text inside that element
    countElement.innerText="1";

    //step 4: Log it to the console to prove it fired
    console.log("The counter function successfully ran!");
}

//step 5: Call the function so it runs when the page loads
updateVisitorCount();
*/
// We use 'async' because fetching data from the internet takes time
/*
async function updateVisitorCount(){
    try{

        //1. Call the API
        // We are using the free test API here that returns fake user data
        let response= await fetch("https://jsonplaceholder.typicode.com/users/1");

        //2. Translate the response into JSON format
        let data= await response.json();

        //3. Find our HTML element 
        let counterElement= document.getElementById("visitor-count");

        //4. Update the HTML
        //This test API returns an 'id' number so we will use that as our fake count!
        counterElement.innerText=data.id;

        console.log("Successfully fetched data:",data);
    }
    catch(error){
        console.error("Error fetching data:",error);
    }
}
updateVisitorCount();
*/
//Paste actual API Gateway URL
const api_url = "https://opgpp9eqqh.execute-api.us-east-2.amazonaws.com/count";
async function getVisitorCount(){
    try{
        //The Waiter takes the order
        const response = await fetch(api_url);

        //The waiter brings back the meal (JSON data )
        const data = await response.json();

        //Update HTML with the new number
        document.getElementById("visitor-count").innerText = data.visitor_count;

        console.log("Visitor count updated successfully");
    }
    catch(error){
        console.error("Error fetching visitor count:", error);
    }
}
getVisitorCount();