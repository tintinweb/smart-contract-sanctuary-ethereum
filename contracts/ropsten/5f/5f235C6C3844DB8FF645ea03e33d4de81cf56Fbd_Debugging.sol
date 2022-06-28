/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Debugging {
    uint256 counter;
    constructor(uint256 _counter) {
        counter = _counter;
    }
    function _setCounter(uint256 _counter) internal {
        counter = _counter;
    }
    function increment(uint256 value) public {
        uint256 newValue = counter + value;
        _setCounter(newValue);
    }
    function decrement(uint256 value) public {
        uint256 newValue = counter - value;
        _setCounter(newValue);
    }
    function getCounter() public view returns(uint256) {
        return counter;
    }
}