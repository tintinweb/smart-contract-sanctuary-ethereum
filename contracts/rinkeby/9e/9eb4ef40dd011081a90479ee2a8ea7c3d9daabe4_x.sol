// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./MainContract.sol";

contract x {

    function Spend(uint256 amount) public{
        BM(0x13E64a966afE9cdf4E0C3fa3faf5EAeD55B9f2A9).spendPoints(0x0af5aFB1Be30830d4C25a9f67136A96fbBc5492e, amount);
    }
}