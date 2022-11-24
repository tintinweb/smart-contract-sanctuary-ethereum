// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    
    uint256 public num;

    function init(uint256 _num) external {
        num = _num;
    }
}