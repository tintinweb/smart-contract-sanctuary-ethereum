/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simple {
    uint public num = 1;

    function setnum(uint256 _num) public {
        num = _num;
    }
}