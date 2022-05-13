/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    uint public sum;

    function setSum(uint a, uint b) public {
        require(a >= b,"rquire a > b");
        sum = a - b;
    }
}