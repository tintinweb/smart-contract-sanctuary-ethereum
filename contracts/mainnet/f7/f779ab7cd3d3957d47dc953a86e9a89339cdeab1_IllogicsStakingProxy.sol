/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IIllogics {
    function ownerStaked(address owner) external view returns (uint256[] memory);
}

contract IllogicsStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = IIllogics(address(0x8EE5DD62A654a60f6F17A99d544102f37B58dA26)).ownerStaked(owner);
        uint256 balance = tokenIds.length;
        return balance;
    }
}