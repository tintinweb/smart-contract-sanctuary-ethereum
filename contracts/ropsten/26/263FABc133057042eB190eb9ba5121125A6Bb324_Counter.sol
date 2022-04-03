// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Killable.sol";


contract Counter is Killable {
    uint256 number;

    function add() public {
        number = number + 1;
    }

    function put(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256){
        return number;
    }
}