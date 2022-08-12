/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract test4
{
    event mathical (uint num1, uint num2, uint result, string math);

    function sum (uint a , uint b) public
    {
        uint _sum = a + b;

        emit mathical (a , b , _sum , "+");
    }
}