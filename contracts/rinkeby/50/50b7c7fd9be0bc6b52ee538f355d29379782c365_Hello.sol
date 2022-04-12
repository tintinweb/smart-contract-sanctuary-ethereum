/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// File: Hello.sol

pragma solidity ^0.8.0;

contract Hello {
    string greeting;

    function greet() public view returns (string memory) {
        return greeting;
    }
}