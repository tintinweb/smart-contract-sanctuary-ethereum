//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IStaking {

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stake(uint256 _amount, address _legionToken) external; 

    function withdraw(uint256 _amount, address _legionToken) external;
    
    function getReward() external;
}


contract StakingInterface {

    address immutable staking;

    constructor(address _staking){
        staking = _staking;
    }


    function rewardPerToken() external view returns (uint256){
        return IStaking(staking).rewardPerToken();
    }

    function earned(address account) external view returns (uint256){
        return IStaking(staking).earned(account);
    }

    function stake(uint256 _amount, address _legionToken) external {
        IStaking(staking).stake(_amount, _legionToken);
    }

    function withdraw(uint256 _amount, address _legionToken) external{
        IStaking(staking).withdraw(_amount, _legionToken);
    }
    
    function getReward() external {
        IStaking(staking).getReward();
    }
}