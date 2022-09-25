/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// File: contracts/Contract.sol



// Solidity Version. 
pragma solidity ^0.8.4;


// Initialising Smart Contract. 
contract Sample {

    uint public num = 10;
    string public data = "This is String";
    bool trueOrFalse = true;
    address public user;

    //Array
    uint[] public array;

    // Calling function to change the "data" variable. 
    function setData(string memory _str) public {
        data = _str;
    }

    //Calling function to add data into array. 
    function insertIntoArray(uint _num) public {
        array.push(_num);
    }

    // Assigning the value to the address.
    function setUsr() public{
        user = msg.sender;
    }
}