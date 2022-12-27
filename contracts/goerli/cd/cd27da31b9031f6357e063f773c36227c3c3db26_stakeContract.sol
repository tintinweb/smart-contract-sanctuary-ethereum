/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract stakeContract {
    struct staker{
        uint256 totalStake;
        string status;
        uint256 timestamp;
        uint256 apy;
        uint256 deductionFees;
    }
    mapping(address => staker) public _staked;
    // address private owner;
    // IERC20 public TokenAddress; //IERC20 datatype
    // uint256 reward; 
    uint256 public totalStaked;
    uint256 public totalActiveStakers;
    uint256 public apyPercentage;

    constructor( ){
    // TokenAddress = IERC20(_tokenAddress);
    }

    function stake(uint256 amount, uint time) external {
    //    require(TokenAddress.balanceOf(msg.sender) > amount);
       require(_staked[msg.sender].totalStake==0,"You are already a staker");
       if(time == 30) {
           _staked[msg.sender].status = "silver";
           _staked[msg.sender].timestamp = 30 days;
           _staked[msg.sender].apy = 4;
           _staked[msg.sender].deductionFees = 30;

       } 
       else if (time == 60){
           _staked[msg.sender].status = "Gold";
           _staked[msg.sender].timestamp = 60 days;
           _staked[msg.sender].apy = 8;
           _staked[msg.sender].deductionFees = 15;

       }
       else if (time == 90){
           _staked[msg.sender].status = "Diamond";
           _staked[msg.sender].timestamp = 90 days;
           _staked[msg.sender].apy = 12;
           _staked[msg.sender].deductionFees = 10;
       }
       else{
           revert ("Lockup Period is Invalid, Valid Period are 30, 60 and 90 Days");
       }
    //    TokenAddress.transferFrom(msg.sender,address(this), amount);//(address owner,address buyer,numofTokens)
       totalActiveStakers++;
       _staked[msg.sender].totalStake += amount;
       totalStaked+=amount;
    
    }

    function unstake() external{
        require(_staked[msg.sender].totalStake>0, "You are not a staker");
        delete _staked[msg.sender];
    }
}