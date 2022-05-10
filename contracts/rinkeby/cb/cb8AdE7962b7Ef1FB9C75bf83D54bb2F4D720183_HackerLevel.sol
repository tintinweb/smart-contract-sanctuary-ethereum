pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

contract HackerLevel {

  mapping(uint256 => uint256) public _levels;
    function level_up(uint256 hackerId) external {
        _levels[hackerId]++;
    }
    function level_down(uint256 hackerId) external {
        _levels[hackerId]--;
    }
}