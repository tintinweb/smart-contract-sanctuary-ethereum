/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
    // Block and epoch when epoch length was last updated
    function lastLengthUpdateEpoch() external view returns (uint256);
    function lastLengthUpdateBlock() external view returns (uint256);
    function epochLength() external view returns (uint256);
}

contract EpochDuration{
    address public stakingEpochManager;

    constructor(address _stakingEpochManager){
        stakingEpochManager=_stakingEpochManager;
    }

    function setStakingEpochManager(address _stakingEpochManager) external {
        stakingEpochManager=_stakingEpochManager;
    }

    function getEpoch() external view returns(uint256){
        return IEpochManager(stakingEpochManager).currentEpoch();
    }

    function epochStartBlock(uint256 _epoch) public view returns(uint256){
        uint256 updatedEpoch = IEpochManager(stakingEpochManager).lastLengthUpdateEpoch();
        uint256 updatedBlock = IEpochManager(stakingEpochManager).lastLengthUpdateBlock();
        uint256 epochLenght = IEpochManager(stakingEpochManager).epochLength();
        require(_epoch >= updatedEpoch);
        
        return updatedBlock + ((_epoch - updatedEpoch)*epochLenght);
    }
    function epochEndBlock(uint256 _epoch) public view returns(uint256){
        return epochStartBlock(_epoch+1);
    }
}