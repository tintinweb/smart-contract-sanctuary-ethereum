/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.6;

contract WallyTestKeepersContract{

    uint256 public num;

    function auto_increase() public {
        num += 1;
    }

    function get_number() public returns(uint256) {
        return num;
    }

}