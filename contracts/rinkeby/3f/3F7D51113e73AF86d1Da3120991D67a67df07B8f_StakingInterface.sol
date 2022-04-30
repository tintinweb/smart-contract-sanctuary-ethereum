/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

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

    address constant staking = 0x294Ed456a59d5704238Ed41BF6485C7711a8ab52;


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