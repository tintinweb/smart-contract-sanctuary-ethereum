/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

//lines are ignored by the compiler
/* 
we can also have multi line comments 
by enclosing text between /* and
*/
//the first thing we do in the card is we pecify our preference of compiler version
pragma solidity ^0.8.17;
//the ^ character indicates that we can use the specified solidity version
//all solidity statements end wiht a ; semicolon

/*
This contract stores a data string (text)
it makes the store data string availale for anyone to read
*/
contract MessageStore{
    //the contract keyword tells the compilier we're defining a new smart contract
    //threre can be more than one contract defined in each .sol file
    //the entire smart contract definition {business logic + state}is contained between the [] braces
    
    //variables - this is the data that smart contract know about & remembers
    string private data;
    //srting is the discribing the type of information we are storing in this smart contract - string means text
    //private keyword means that this information will be `hidden` from other accounts
    //"data" is simply a name that we invented for this piece of contract state(alos called variable of field)  

    /*
    every contract needs a `constructor` function that tells compiler how to initialized the contract when it's created
    a function is a unit of code that belongs and exucates together - it can ve invoked (called ) from othe bits of code
    every variable in solidity is either `memory` or `storage` - tha latter is more expensive to work wiht(in terms of gas) because is persists outside of the current transaction
    when declaring contract state, everything is assuemed to be storage.
    */
    constructor(string memory initialData){
        data = initialData; 
        //in programing the = operator means assignment that is, what ever is on the right hand side of the = 
        //will be copied over and stored in whatever variable is on the lefe hand side.

    }

    /*
    we can create function to view or even modify the internal stata of the contract
    the function we are going to define aloow anyone to view the "data"
    below the first set of () braces contain any external information the function will need to do its job
    in this case, no external infromation is needed by the business logic
    the "public keyword" incicates that this function can be used by other contracts as part of MessageStore interface
    the returns keyword describes the type of information that this function will provide as a response
    the view key word indicates that this function will not alter the internal state of MessageStore
    */

    
    function viewData() public view returns(string memory){
        return data;
        //the returns keyword describes the type of information that this function will provide as a response
    }

}