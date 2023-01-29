/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// lines that begin with // are comments which are ignored by the compiler, and are for humans to understand the contract
/*
We can also have multi line comments by enclosing text between /* and
*/
// the first thing we do in a soldity smart contract is we specify our preference of compiler version
pragma solidity ^0.8.17;
//the ^ character indicates that we can use the specified solidity version OR NEWER
// all solidity statements end with a ; semicolon.

/*
This contract stores a data string (text)
it makes the stored data string available for anyone to read
*/
contract MessageStore{
    //the contract keyword tells the compiler we're defining a new smart contract
    //there can be more than one contract defined in each .sol file
    //the entire smart contract (state + business logic) is contained between the {} braces

    // let's define some internal variables - this is the data that the smart contract knows about & remembers
    string private data;
    //string is describing the type of information we're storing in this smart contract - string means text
    //private keyword means that this information will be 'hidden' from other accounts
    //"data" is simply a name that we invented for this piece of contract state (also called a variable or field)

    /*
    every contract needs a 'constructor' function that tells the compiler how to initialize the contract when it's created
    a function is a unit of code that belongs and executes together - it can be invoked (called) from other bits of code
    every variable in solidity is either 'memory' or 'storage'
    the latter is more expensive to work with (in terms of gas) because it persists outside of the current transaction
    when declaring contract state, everything is assume to be storage (persists on chain)
    
    */
    constructor (string memory initialData){
        data = initialData;
        //in programming the = operator means assignment that is, whatever is on the right hand side of the =
        //will be copied over and stored in whatever variable is on the left hand side.
    }

    /*
    we can create functions to view or even modify the internal state of the contract
    the function we are going to define below allows anyone to view the "data"
    below, the first set of () braces contain any external information the function will need to do its job
    in this case, no external information is needed by the business logic
    the "public" keyword indicates that this function can be used by other contracts as part of the MessageStore interface
    the returns keyword describes the type of information that this function will provide as a response
    the "view" keyword indicates that this function will not alter the internal state of MessageStore
    */
    function viewData() public view returns(string memory){
        return data;
        //the return statement specifies which piece of information to provide as the response
    }
}