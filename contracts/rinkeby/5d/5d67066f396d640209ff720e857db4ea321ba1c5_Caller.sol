/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Caller {
    function smokingApesBalanceOf(address owner) public view returns (uint256) {
        SmokingApes sa = SmokingApes(0xe62a9Ed27708698cfD5Eb95310d0010953843B13);
        return sa.balanceOf(owner);
    }
}

abstract contract SmokingApes {
    function balanceOf(address owner) public view virtual returns (uint256);
}