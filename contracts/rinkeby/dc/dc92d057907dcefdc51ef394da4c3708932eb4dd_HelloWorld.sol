/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;
contract HelloWorld {
    //declare a state variable
    string public message;

    //setter function 
    function setMessage (string memory _message) public {
        message = _message;
    }
    

    //getter function 
    function getMessage () public view returns (string memory){
        require(bytes(message).length != 0, "Enter a Valid String message");
        return message;
    }
}