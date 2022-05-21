/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract CoinFlip {

    bool public side;
    uint256 public blockValue;

    constructor() {
        side = false;
        blockValue = 0;
    }

    function flip(bool _side) external payable returns (bool) {
        side = _side;
        return _side;
    }

    function setBlockValue(uint256 _blockValue) external returns (bool) {
        blockValue = _blockValue;
        uint256 coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        side = coinFlip == 1 ? true : false;
        return true;
    }

    receive() external payable {}
    
}