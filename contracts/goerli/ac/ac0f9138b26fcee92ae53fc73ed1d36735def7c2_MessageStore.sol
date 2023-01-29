/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

//comments to understand, they are ignored by compiler
/*
text in between
*/
// to specify the compiler version
pragma solidity ^0.8.17;
// ^ indicates, that we can use the specific version or newer
// all statements ends with ;

/*
Explanation 
*/
contract MessageStore{
 // will describe a new smart contract
 // there will be more than one .sol file
 //   {} between these are contract definition 

 // internal variables - data smart contract knows about and remembers 
 string private data;
 // 'string' describes the typo if information in the contract - string means text
 //private means this info will be hidden from other accounts
 // data is a name for this contract

 /*
 every contract needs a 'constructor' - a function for initiating the contract
 a function is a unit of code, that belongs and executes together 
 below the first set of () contain any external info to do its job
 */
 constructor (string memory initialData) {
data = initialData;
 }

 /*
 Additional functions can view or modify the data 
 */
 function viewData () public view returns (string memory){
     return data;
 }
}