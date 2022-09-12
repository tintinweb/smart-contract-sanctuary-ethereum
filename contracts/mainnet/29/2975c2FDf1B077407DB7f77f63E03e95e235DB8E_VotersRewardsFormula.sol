/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity 0.8.11;

interface IERC20 {
    function balanceOf(address) external view returns (uint);
}

interface IVoter {
    function totalWeight() external view returns(uint);
}

/*
Voters in total need to vote with 10x more ve than the weekly emissions to get full 100% of platform emissions
Example:
if 100 tokens are emitted, 1000 ve is need to emit full 100% to voter pools.
If only 200 ve votes then only 20% will be emitted for those voted pools
*/

contract VotersRewardsFormula {
  IVoter public voter;
  address public rewardsLocker;
  address public rewardToken;

  constructor(
    address _voter,
    address _rewardsLocker,
    address _rewardToken
    )
  {
    voter = IVoter(_voter);
    rewardsLocker = _rewardsLocker;
    rewardToken = _rewardToken;
  }

  function computeRewards() public view returns(uint) {
    uint totalWeight = voter.totalWeight();
    uint currentRewards = IERC20(rewardToken).balanceOf(rewardsLocker);
    uint xRewards = currentRewards * 10;

    if(totalWeight >= xRewards){
      return currentRewards;
    }
    // if rewards percent less than 1% return 0 
    else if(totalWeight < xRewards / 100){
      return 0;
    }
    // compute rewards percent
    else{
      uint percent = totalWeight * 100 / xRewards;
      return currentRewards / 100 * percent;
    }
  }
}