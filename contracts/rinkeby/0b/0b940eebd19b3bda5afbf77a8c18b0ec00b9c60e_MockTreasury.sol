// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MockTreasury {
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function initialize(address govenor, uint256 timelockDelay) external {
        // do nothing
    }

    function execute(address target, bytes calldata data) public {
        // require(msg.sender == owner, "only owner");
        target.call(data);
    }
}