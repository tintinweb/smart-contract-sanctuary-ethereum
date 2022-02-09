/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Ownable{
     address private owner;

     event OwnerShip_Transferred(address indexed previous,address indexed current);

     constructor(){
     owner = msg.sender; 
     emit OwnerShip_Transferred(address(0),owner);
     }

     function _owner() public view returns(address){
         return owner;
     }

     modifier onlyOwner(){
         if(owner != msg.sender){ revert("Only owner can execute this"); }
         _;
     }
     

     function ownership_transfer(address new_owner) onlyOwner public{
        _transferOwnership(new_owner);
     }

     function _transferOwnership(address newOwner) internal {
         require(newOwner != address(0), "Ownable: new owner is the zero address");
         owner = newOwner;
         emit OwnerShip_Transferred(owner, newOwner);
     }
       function renounceOwnership() onlyOwner public  {
        owner  = address(0);
        emit OwnerShip_Transferred(owner, address(0));
  }
}

contract teststaking1 is Ownable{

   IERC20 token;
   uint256 totalStakedRecord;
   uint256 currentlyStaked;
   uint256 public AllocationReward;
   uint256 public minStakingAmount;
   uint256 APR;

   constructor(IERC20 _token,uint _APR,uint256 allocation_reward,uint256 minS)
   {
     token=_token;
     APR=_APR;
     AllocationReward=allocation_reward * 10e18;
     minStakingAmount=minS;
   }

   struct Stake
   {
       uint256 totalStaked;
       uint256 totalClaimAmount;
       uint256[] claim;
       uint256[] amount;
       uint256[] since;
       uint256[] expiry;
   }

   mapping(address => Stake) Stake_Holders;  
   
   function total_staked()public view returns(uint256)
   {
     return totalStakedRecord;
   }
  
   function change_APR(uint256 _apr) public 
   onlyOwner 
   {
       APR=_apr;
   }

   function change_minStakingAmount(uint256 _msa) public 
   onlyOwner 
   {
       minStakingAmount=_msa;
   }

   function currently_staked()public view returns(uint256)
   {
     return currentlyStaked;
   }

   function currentAPR()public view returns(uint)
   {
     return APR;
   }
   
   function stake(uint256 staking_amount,uint256 locking_period)public returns(bool)
   {
     require(token.balanceOf(msg.sender) >= staking_amount && staking_amount>=minStakingAmount,"The amount is less");
     require(locking_period > 0,"Wrong Locking period input");
     _stake(staking_amount,locking_period);
     return true;
   }
                                             
   function _stake(uint256 stakingAmount,uint lockingPeriod) internal 
   {
       address user= msg.sender;
       uint256 currentTime=block.timestamp;
       uint256 guaranteed_reward=calculate_reward(stakingAmount);
       require(user != address(0),"InValid address");
       require(AllocationReward>=guaranteed_reward,"Insufficient allocation reward");
       Stake_Holders[user].amount.push(stakingAmount);
       Stake_Holders[user].since.push(currentTime);
       Stake_Holders[user].expiry.push(currentTime+lockingPeriod);
       Stake_Holders[user].claim.push(guaranteed_reward);
       Stake_Holders[user].totalClaimAmount+=stakingAmount;
       Stake_Holders[user].totalStaked+= stakingAmount;
       totalStakedRecord+=stakingAmount;
       currentlyStaked+=stakingAmount;
       AllocationReward-=guaranteed_reward;
       token.transferFrom(msg.sender,address(this),stakingAmount);
   }

   function calculate_reward(uint256 amount)internal view returns(uint256)
   {
        return (amount*APR)/100;
   }

   function withdraw() public returns(bool)
   {
       require(Stake_Holders[msg.sender].totalStaked>0,"The user have never staked");
       _withdrawStakes(msg.sender);
       return true;
   }

   function _withdrawStakes(address user) internal
   {
       uint current_blockTime=block.timestamp;
       uint withdraw_amount;
      for(uint i=0;i<Stake_Holders[user].expiry.length;i++)
      {
         if(Stake_Holders[user].expiry[i]<=current_blockTime && Stake_Holders[user].amount[i]>0)
         {
          withdraw_amount+=Stake_Holders[user].amount[i];
          Stake_Holders[user].amount[i]=0;
         }
      }
       require(withdraw_amount!=0,"Cannot withdraw before a locking period");
       Stake_Holders[user].totalStaked -= withdraw_amount;
       token.transfer(user,withdraw_amount);
       currentlyStaked -=withdraw_amount;
       if(Stake_Holders[user].totalStaked==0)
       {
        //  Claim();
         delete Stake_Holders[user];
       }
   }

//    function Claim()public { 
//        uint256 rewardCalculation;
//        uint256 rewardPerSecond;
//        uint256 current_blockTime=block.timestamp;
//        address user=msg.sender;
//        for(uint i=0;i<Stake_Holders[user].since.length && Stake_Holders[user].since[i]+10 days<=current_blockTime;i++){
//          rewardPerSecond=10e18*Stake_Holders[user].claim[i]/(Stake_Holders[user].expiry[i]-Stake_Holders[user].since[i]);
//          if(Stake_Holders[user].expiry[i]<current_blockTime){

//          }
//        }
       
    
//       //  token.transfer(user,rewardCalculation);
//    }

   function end()public{
     withdraw();
    //  Claim();
   }

   function hasStake(address user)public view returns(uint256){
     user=msg.sender;
     return Stake_Holders[user].totalStaked;
   }





   event display(uint256 indexed,uint256 indexed,uint256 indexed,uint256,uint256,uint);
   function stakesTesting(address g)public{
    //    uint256 totalStaked;
    //    uint256 totalClaimAmount;
    //    uint256[] claim;
    //    uint256[] amount;
    //    uint256[] since;
    //    uint256[] expiry;
     for(uint i=0;i<Stake_Holders[g].amount.length;i++){
        emit display(Stake_Holders[g].totalStaked,Stake_Holders[g].totalClaimAmount,Stake_Holders[g].claim[i],Stake_Holders[g].amount[i],Stake_Holders[g].since[i],Stake_Holders[g].expiry[i]);
     }
   }
}