/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

/*
for multiple lines of comments ending with */
pragma solidity ^0.8.17;
// this means we can use 0.8.17 or newer

contract MassageStore{
    //there can be more the 1 contract in each .sol file
    //the entire smart contract is define between the curly brackets {}
    //which is state and business logic
    string private data;
    //private here means its hidden from other accounts
    // data is referred as a variable
    constructor () {
        data = "something";
    }
    // () contains all the external info that is needed for the function
        function viewData() public view returns(string memory){
            return data;
        }
}