/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 a;

    //advanced//

    function viewA() public view returns (uint256) {
        return a;
    }

    function modifyA(uint256 _a) public returns (bool) {
        a = _a;
        return true;
    }
}