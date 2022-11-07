/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ChampsOnlyStaking {
    function checkAuth(address owner) external view returns (bool);
}

contract ChampsOnlyStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        bool isStaked = ChampsOnlyStaking(address(0x71996799126Fb9B8D020DBbFD351290bf3B02Aa4)).checkAuth(owner);
        if (isStaked) {
            return 1;
        } else {
            return 0;
        }
    }
}