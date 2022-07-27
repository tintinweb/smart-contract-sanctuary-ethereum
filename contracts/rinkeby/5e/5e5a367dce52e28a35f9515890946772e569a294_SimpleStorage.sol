/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage { // anthing inside the brackets{} is the content inside for the function
     
     uint256 /*public*/ favoriteNumber; // <- No specific number = 0. This button represent "show me the fav number". Public combined with fav number returns the value of favorite number.
     // People public person = People({favoriteNumber: 2, name: "Mounir"}); // <- this is ideally for only 1 person and favNumber.

    // a mapping is a data structure where a key is mapped to a single value. It is like a dictionary. 
     mapping(string => uint256) public nameToFavoriteNumber; //<- this is a great way for a list for many people! It says that string(name) is being "mapped" to uint256(favNumber). 

        struct People { // <- the function "struct" is make a list of variables. In this case, variables is: favNumber and name.
         uint256 favoriteNumber; 
         string name;
     }

    // uint256[] public favoriteNumbersList; // This is just another way to make an array
     People[] public people; // <- is empty so it does not gonna give any value. This is a dynamic array because we haven't specified how big the array(list) is going to be.


    function store(uint256 _favoriteNumber) public virtual { // <- function is storing the uint256 fav number. orange button "store" is using gas everytime we store a fav number. // New note: we have added "virtual" so we can override the function in our "ExtraStorage.sol".
         favoriteNumber = _favoriteNumber; // <- I think this is called "Scope". The reason we do this, is beacuse the "uint256 public favoriteNumber;" isn't is inside of the "function store". We have to identifier what is what. Not sure if this is correct.
         retrieve(); // <- This will call for the pure or view function. This will cost gas. It is only gnna cost gas if you're gonna use it in a function that is gonna cost gas.
         // favoriteNumber = favoriteNumber + 1; // <- The more "stuff" you do, the more gas it will cost. This basically means if our fav number is 5 then + it with 1.
        
     }
    // view & pure funtions doesnt use any gas, when called alone. Pure function is good for any math that you're gonna use over and over. 
    // view & pure funtions are basically reading from the blockchain off-chain and do not make a transaction. 
     function retrieve() public view returns(uint256) {
         return favoriteNumber;
     }
// (big case)People is refering to the name. (little case)people is refering to the array.
// struct, mappings and array need to be given memory or calldata when adding them as a parameter to different functions.
     function addPerson(string memory _name, uint256 _favoriteNumber) public {
         people.push(People(_favoriteNumber, _name));
         nameToFavoriteNumber[_name] = _favoriteNumber;
     } 
}





//  0xC2C2F31Dae6AaBB1DC43D98C3DF038eCceeFef7D <- Smart contract address