/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract Random {
    uint256 m = 5;
    function changeN(uint256 _m) public {
        m = _m + 1;
    }
}