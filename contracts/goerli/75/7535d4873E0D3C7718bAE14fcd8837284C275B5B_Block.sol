// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Block {
    address public owner;
    uint256 public blockTimestamp;
    uint256 public blockNumber;

    constructor() {
        owner = msg.sender;
        _update();
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner is allowed to call this function."
        );
        _;
    }

    function update() public onlyOwner {
        _update();
    }

    function _update() private {
        blockTimestamp = block.timestamp;
        blockNumber = block.number;
    }
}