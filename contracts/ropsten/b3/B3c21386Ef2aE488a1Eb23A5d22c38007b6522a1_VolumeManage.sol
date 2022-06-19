//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VolumeManage 
{ 
    uint256[] public postionIDS;
    uint256 public oppositeBound;
    uint256 public time;

    function liquidatePosition(uint256 positionId,uint256 oppositeBoundAmount,uint256 deadline) external returns (uint256 baseAmount,uint256 quoteAmount) {
        delete postionIDS[positionId];
        oppositeBound = oppositeBoundAmount;
        time = deadline;
        baseAmount = 0;
        quoteAmount = 0;
    }

    function update(uint256 _psotionsID) external {
        postionIDS.push(_psotionsID);
    }
}