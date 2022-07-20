/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Total {
    uint256 public total = 0;

    function changeTotal(uint256 num) public {
        total = num;
    }
    function increaseTotal() public {
        total = total + 1;
    }
    function decreaseTotal() public {
        if(total != 0)
        {
            total = total - 1;
        }
    }
}