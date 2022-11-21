/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract MyTest
{
    uint $number = 0;

    function getNumber() external view returns(uint)
    {
        return $number;
    }

    function setNuber(uint $newNumber) external returns(bool)
    {
        $number = $newNumber;
        return true;
    }
}