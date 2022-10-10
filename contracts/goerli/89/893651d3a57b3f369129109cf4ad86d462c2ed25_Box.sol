/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
contract Box{
    uint256 public val;
    function initialize(uint256 _val)external{
        val = _val;
    }

}