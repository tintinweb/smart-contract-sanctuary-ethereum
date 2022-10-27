// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract GasWar {
    address public minter;

    address[] public positions;

    constructor() {
        minter = msg.sender;
    }

    function restart() public {
        require(msg.sender == minter);

        delete positions;
    }

    function join() public {
        positions.push(msg.sender);
    }

    function winner() public view returns (address) {
        return positions[0];
    }
}