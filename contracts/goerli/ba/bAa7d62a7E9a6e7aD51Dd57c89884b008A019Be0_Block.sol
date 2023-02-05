// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Block {
    address public owner;
    uint256 public blockTimestamp;
    uint256 public blockNumber;
    mapping(uint256 => mapping(address => bool)) public startCalls;

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

    function addStartCall(
        uint256 startTimestamp
    ) external afterStartTimestamp(startTimestamp) {
        startCalls[startTimestamp][msg.sender] = true;
    }

    modifier afterStartTimestamp(uint256 startTimestamp) {
        require(
            block.timestamp >= startTimestamp,
            "Start timestamp not reached."
        );
        _;
    }
}