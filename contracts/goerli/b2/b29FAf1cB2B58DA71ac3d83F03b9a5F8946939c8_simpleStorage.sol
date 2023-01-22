// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract simpleStorage {
    uint256 fund;

    function get() public view returns(uint256){
        return fund;
    }

    function set(uint256 _val) external {
        fund = _val;
    }
}