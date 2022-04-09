/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

pragma solidity ^0.4.22;

contract Greeter {
    string greeting;
    address owner;

    modifier onlyOwner {
        require(isOwner(), "Only owner can do that!");
        _;
    }
    
    constructor(string _greeting) public {
        greeting = _greeting;
        owner = msg.sender;
    }

    function saySelam() public view returns(string) {
        if (isOwner()) {
            return "Selam Blockchain!";
        } else {
            return greeting;
        }
    }

    function setGreeting(string _newGreeting) public onlyOwner {
        greeting = _newGreeting;
    }
    
    function isOwner() view private returns(bool) {
        return msg.sender == owner;    
    }
}