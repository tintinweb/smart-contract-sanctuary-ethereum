/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

pragma solidity 0.8.7;

contract Checkin {
    string greeting;

    constructor(string memory _greeting) public {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function isSolved() public view returns (bool) {
        string memory key = "HelloNewstarCTF";
        return keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(greeting));
    }
}