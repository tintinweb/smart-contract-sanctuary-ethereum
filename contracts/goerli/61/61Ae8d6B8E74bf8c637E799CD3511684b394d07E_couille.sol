/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// File: contracts/couille.sol

pragma solidity >=0.8.19;

contract couille {

    uint256 public counter = 0;

    constructor() {

    }

    function increment(uint256 value) external {
        counter += value;
    }
}