// SPDX-License-Identifier: Unlisenced

pragma solidity ^0.8.0;

interface Target {
    function amountForDevs() external view returns (uint);
}

contract Interaction 
{
    function getCount() external view returns (uint) {
        return Target(0x449DD76bc5D8306d1784430Bad2c16e6B7f15188).amountForDevs();
    }
}