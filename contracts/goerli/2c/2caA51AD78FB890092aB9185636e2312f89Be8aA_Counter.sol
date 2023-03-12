// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "openzeppelin-contracts/access/Ownable.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}