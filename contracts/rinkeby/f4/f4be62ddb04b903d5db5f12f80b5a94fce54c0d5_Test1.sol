// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./B2.sol";

contract Test1 {

    uint256 num;

    function setNumber(uint256 number) external {
        num = number;
    }

    function setOtherNumber(uint256 number) external {
        Test2 aa = new Test2();
        aa.setNumber(number);
    }
}