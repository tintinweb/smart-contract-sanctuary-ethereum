/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    uint public i;

    function callMe(uint256 j) public returns(bool) {
        i += j;
        return true;
    }

    function getData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("callMe(uint256)", 123);
    }
}