/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VolumeManager 
{ 
    uint256[] public postionIDS;
    uint256 public oppositeBound;
    uint256 public time;

    function liquidatePosition(uint256 positionId,uint256 oppositeBoundAmount,uint256 deadline)external {
        delete postionIDS[positionId];
        oppositeBound = oppositeBoundAmount;
        time = deadline;
    }

    function update(uint256 _psotionsID) external {
        postionIDS.push(_psotionsID);
    }
}