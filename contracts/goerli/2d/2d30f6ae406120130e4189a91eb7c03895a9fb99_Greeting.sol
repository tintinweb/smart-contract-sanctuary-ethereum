/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

pragma solidity 0.8.17;

contract Greeting {
    string public greeting;

    constructor(string memory _greeting) public {
        greeting = _greeting;
    }

    event GreetingChanged(string _greeting);

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
}