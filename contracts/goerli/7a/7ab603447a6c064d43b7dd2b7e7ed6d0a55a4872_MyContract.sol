/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.0;
contract MyContract {
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }
}