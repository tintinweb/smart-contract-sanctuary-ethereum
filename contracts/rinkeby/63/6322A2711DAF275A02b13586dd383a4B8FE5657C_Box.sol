/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Box {
    uint public value;

    function initailize(uint _value) external {
        value = _value;
    }
}