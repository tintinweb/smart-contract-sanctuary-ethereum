/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// File: contracts\interfaces\ILockedCvx.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ILockedCvx{
     struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    function lock(address _account, uint256 _amount, uint256 _spendRatio) external;
    function processExpiredLocks(bool _relock) external;
    function getReward(address _account, bool _stake) external;
    function balanceAtEpochOf(uint256 _epoch, address _user) view external returns(uint256 amount);
    function totalSupplyAtEpoch(uint256 _epoch) view external returns(uint256 supply);
    function epochCount() external view returns(uint256);
    function epochs(uint256 _id) external view returns(uint224,uint32);
    function checkpointEpoch() external;
    function balanceOf(address _account) external view returns(uint256);
    function lockedBalanceOf(address _user) external view returns(uint256 amount);
    function pendingLockOf(address _user) external view returns(uint256 amount);
    function pendingLockAtEpochOf(uint256 _epoch, address _user) view external returns(uint256 amount);
    function totalSupply() view external returns(uint256 supply);
    function lockedBalances(
        address _user
    ) view external returns(
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    );
    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) external;
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
    function setStakeLimits(uint256 _minimum, uint256 _maximum) external;
    function setBoost(uint256 _max, uint256 _rate, address _receivingAddress) external;
    function setKickIncentive(uint256 _rate, uint256 _delay) external;
    function shutdown() external;
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
}

// File: contracts\VotingBalanceV2Gauges.sol
pragma solidity 0.6.12;

contract VotingBalanceV2Gauges{

    address public constant oldlocker = address(0xD18140b4B819b895A3dba5442F959fA44994AF50);
    address public constant locker = address(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);
    uint256 public constant rewardsDuration = 86400 * 7;
    uint256 public constant lockDuration = rewardsDuration * 17;

    constructor() public {
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function balanceOf(address _account) external view returns(uint256){

        //compute to find previous epoch
        uint256 currentEpoch = block.timestamp / rewardsDuration * rewardsDuration;
        uint256 latestindex = ILockedCvx(locker).epochCount() - 1;
        uint256 epochindex = latestindex;

        //there may or may not have been a checkpoint in the new epoch
        //thus get date of latest epoch and compare to block.timestamp
        //if epoch.date >= current epoch then there was a checkpoint and need to move index back to get prev
        (, uint32 _date) = ILockedCvx(locker).epochs(epochindex);
        if(_date >= currentEpoch){
            //if end date is already the current epoch,  minus 1 to get the previous
            epochindex--;
        }

        //check again because new locker has an extra epoch for the following week
        // note: the epochindex-- above can not be -= 2 because there may have been 0 locks for a given week
        //       thus best to check one at a time
        // length -1 = next
        // length -2 = current
        // length -3 = previous
        (, _date) = ILockedCvx(locker).epochs(epochindex);
        if(_date >= currentEpoch){
            //if end date is already the current epoch,  minus 1 to get the previous
            epochindex--;
        }

        //get balances of previous epoch
        uint256 balanceAtPrev = ILockedCvx(locker).balanceAtEpochOf(epochindex, _account);
        uint256 balanceAtCurrent = ILockedCvx(locker).balanceAtEpochOf( latestindex>epochindex ? epochindex+1 : epochindex, _account);
        return max(balanceAtPrev , balanceAtCurrent);
    }

    function totalSupply() view external returns(uint256){
        return ILockedCvx(locker).totalSupply();
    }
}