/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

pragma solidity ^0.8.7;
contract greeter{
    string greeting;
    
    function greet(string memory _greeting)public {
        greeting=_greeting;
    }
    function getGreeting() public view returns(string memory) {
        return greeting;
    }
}