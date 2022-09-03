/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract EventExample {
    event LogRecieve(address indexed _sender,uint256 value);
    event LogFallback(address indexed sender, uint256 value, bytes _data);
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {
        emit LogRecieve(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value, msg.data);
    }
}