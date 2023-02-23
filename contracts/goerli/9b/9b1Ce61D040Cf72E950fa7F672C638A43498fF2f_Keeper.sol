/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
interface IFastPriceFeed {
    function setPricesWithBitsAndExecute(
        uint256 _priceBits,
        uint256 _timestamp,
        uint256 _endIndexForIncreasePositions,
        uint256 _endIndexForDecreasePositions,
        uint256 _maxIncreasePositions,
        uint256 _maxDecreasePositions
    ) external;
}

interface IPositionRouter {
    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);
}

contract Keeper {
    address FPF;
    address PR;
    address owner;

    constructor(address _fpf, address _pr) {
        owner = msg.sender;
        FPF = _fpf;
        PR = _pr;   
    }

    function updateAddresses(address _fpf, address _pr) external {
        require(msg.sender == owner, "not allowed");
        FPF = _fpf;
        PR = _pr;   
    }

    function trigger() external {
        (uint256 startIndexForIncreasePositions, uint256 lengthForIncreasePositions, uint256 startIndexForDecreasePositions, uint256 lengthForDecreasePositions) = IPositionRouter(PR).getRequestQueueLengths();
        uint256 endIndexForIncreasePositions = startIndexForIncreasePositions + lengthForIncreasePositions;
        uint256 endIndexForDecreasePositions = startIndexForDecreasePositions + lengthForDecreasePositions;

        IFastPriceFeed(FPF).setPricesWithBitsAndExecute(0, block.timestamp, endIndexForIncreasePositions, endIndexForDecreasePositions, 0 , 10001);
        IFastPriceFeed(FPF).setPricesWithBitsAndExecute(0, block.timestamp, endIndexForIncreasePositions, endIndexForDecreasePositions, 1 , 10000);
    }
}