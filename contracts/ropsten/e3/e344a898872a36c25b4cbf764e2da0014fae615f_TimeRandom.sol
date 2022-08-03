// SPDX-License-Identifier: MIT
// gabl22 @ github.com

pragma solidity >=0.8.0 <0.9.0;

library TimeRandom {

    function randomInt(uint min, uint max) external view returns(uint) {
        return randomInt(max - min) + min;
    }

    function randomInt(uint max) public view returns(uint) {
        return time() % max;
    }

    function time() public view returns(uint) {
        return block.timestamp;
    }
}