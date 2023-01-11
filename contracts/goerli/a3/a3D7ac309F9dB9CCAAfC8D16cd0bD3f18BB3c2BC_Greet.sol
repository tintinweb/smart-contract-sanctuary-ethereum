/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//import "hardhat/console.sol";

contract Greet{
    
        string public greet;
        //declaring a event
        event newgreet(address owner);
    
constructor(string memory _greet){
    
    //console.log("deploy greeter with string %s", _greet);
    greet = _greet;
}

//recive greetings from contract 
function greeting()public view returns(string memory){
    
    //console.log("current greeting is \"%s\"", greet);
    return (greet);
}

function set_greeting(string memory _greet) public {

    //console.log("change greetings from: \"%s\" to: \"%s\"", greet, _greet);
    emit newgreet(msg.sender);
    greet = _greet;
}
}