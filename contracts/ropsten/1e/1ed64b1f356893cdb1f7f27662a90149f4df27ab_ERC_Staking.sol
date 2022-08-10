/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface StakeInter{
    function transfer(address receiver , uint256 trantoken) external returns(bool);
    function transferfrom(address owner, address recetoken,uint256 value) external returns(bool);
}
contract ERC_Staking{

    event StakeEvent(uint256 amount, uint256 Time);
    event WithD(address a, uint256 b);
    mapping( address=>stake) StakeUser;

    uint256 public Reward;
    uint256 public TotalReward;
    
    StakeInter public StakeInterface;
    constructor(StakeInter _StakeInterface)
    {
    StakeInterface=_StakeInterface;
    Reward=10000000000000000;
    }
    struct stake
    { 
        uint256 amount;
        uint256 time;
    }
    function Stakes() public payable 
    {
      StakeUser[msg.sender] = stake(msg.value, block.timestamp);
      emit StakeEvent(msg.value, block.timestamp);
    }
    function withdraw() public 
    {
    require(block.timestamp>StakeUser[msg.sender].time + 60 seconds," not reahed");
     TotalReward = StakeUser[msg.sender].amount*2;
     StakeInterface.transfer(address(this), TotalReward);
     emit WithD(address(this), TotalReward);
    // payable(msg.sender).transfer(StakeUser[msg.sender].amount);
    }
    function UnStakes() public  
    {
        payable(msg.sender).transfer(StakeUser[msg.sender].amount);
    }

}