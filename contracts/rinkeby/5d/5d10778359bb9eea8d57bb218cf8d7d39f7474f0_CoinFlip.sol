/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract CoinFlip {

    bool public side;

    constructor() {

    }

    function flip(bool _side) external payable {
        side = _side;
    }

    receive() external payable {}
    
}