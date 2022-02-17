/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISmokingApes {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Caller {
    function balanceOf(address owner) public view returns (uint256) {
        return ISmokingApes(0xe62a9Ed27708698cfD5Eb95310d0010953843B13).balanceOf(owner);
    }
}