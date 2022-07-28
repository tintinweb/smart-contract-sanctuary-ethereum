/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    uint public i;

    function callMe(uint256 j) public {
        i += j;
    }

    function getData(uint256 _num) public pure returns (bytes memory) {
        return abi.encodeWithSignature("callMe(uint256)", _num);
    }
}