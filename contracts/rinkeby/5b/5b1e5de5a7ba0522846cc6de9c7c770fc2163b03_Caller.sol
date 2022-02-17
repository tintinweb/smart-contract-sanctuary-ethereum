/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Caller {
    function smokingApesBalanceOf(address owner, address contractAddress) public view returns (uint256) {
        SmokingApes sa = SmokingApes(contractAddress);
        return sa.balanceOf(owner);
    }
}

abstract contract SmokingApes {
    function balanceOf(address owner) public view virtual returns (uint256);
}