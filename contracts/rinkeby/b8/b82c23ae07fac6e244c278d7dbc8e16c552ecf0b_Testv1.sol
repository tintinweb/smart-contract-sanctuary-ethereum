/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Testv1 {
    uint public counter;
    struct Data {
        uint num1;
        uint num2;
    }

    Data[] public data;

    function addData(uint a, uint b) public {
        data[counter].num1 = a;
        data[counter].num2 = b;
        counter++;
    }
}