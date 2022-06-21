/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// File: Contracts/Library/MathLibrary.sol


pragma solidity  0.8.0;
library Math{
function pow(uint a, uint b) public view returns (uint, address) {
        return (a ** b, address(this));
        }
    }
// File: Contracts/demo/MathImplement.sol


pragma solidity  0.8.0;

contract MathImplement {
    using Math for *;
    address owner = address(this);
    function getPow(
      uint num1, uint num2) public view returns (
      uint, address) {
        return num1.pow(num2);
    }
}