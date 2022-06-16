/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// File: tests/MyContract.sol

pragma solidity >=0.7.0 <0.8.0;

contract MySmartContract {
    function Hello() public view returns (string memory) {
        return "Hello World";
    }
    function Greet(string memory str) public view returns (string memory) {
        return str;
    }
}