/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

pragma solidity ^0.8.0;

contract Greeter {
    
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function get_greeting() public view returns (string memory) {
        return greeting;
    }

    function set_greeting(string memory _greeting) public {
        greeting = _greeting;
    }
}