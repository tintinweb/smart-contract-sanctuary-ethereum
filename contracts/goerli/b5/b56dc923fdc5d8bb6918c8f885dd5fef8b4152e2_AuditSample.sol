/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract AuditSample {
    uint256 n = 5;
    function changeN(uint256 _n) public {
        n = _n;
    }
}