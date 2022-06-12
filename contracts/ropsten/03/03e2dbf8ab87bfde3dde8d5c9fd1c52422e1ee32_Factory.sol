/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

pragma solidity ^0.8.0;

contract Greeter {
    
    string private greeting1;

    constructor(string memory _greeting) {
        greeting1 = _greeting;
    }

    function get_greeting() public view returns (string memory) {
        return greeting1;
    }

    function set_greeting(string memory _greeting) public {
        greeting1 = _greeting;
    }
}

contract Factory {
   function CreateNewGreeter(string memory _greeting) public {
     new Greeter(_greeting);
   }
}