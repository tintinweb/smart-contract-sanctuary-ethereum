// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external;
}

contract SaleContract {
    IERC20 public immutable erc20Contract;

    constructor(IERC20 inventory_) {
        erc20Contract = inventory_;
    }

    function transferToken(address from, address to, uint256 value) external {
        erc20Contract.transferFrom(from, to, value);
    }
}