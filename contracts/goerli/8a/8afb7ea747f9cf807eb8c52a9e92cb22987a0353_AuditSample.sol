/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract AuditSample {
    uint256 l = 5;
    function changeK(uint256 _n) public {
        l = _n + 2;
    }
}