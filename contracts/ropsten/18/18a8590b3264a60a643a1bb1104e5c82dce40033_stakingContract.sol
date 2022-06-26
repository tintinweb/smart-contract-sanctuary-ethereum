pragma solidity ^0.8.0;

import "./IERC20.sol";


contract stakingContract {
    IERC20 public staketokenAdd;
    IERC20 public lptokenAdd;
    IERC20 public rewardtokenAdd;
    

    mapping (address => uint) public timeOfStaking;
    event Withdraw (address);
    event Stake (address);

    constructor(IERC20 _StakeToken, IERC20 _RewardToken, IERC20 _LPToken) {
        staketokenAdd =_StakeToken;
        rewardtokenAdd = _RewardToken;
        lptokenAdd = _LPToken;
    }

    function getStakeTokenBalofContract() public view returns(uint){
        return staketokenAdd.balanceOf(address(this));    
    }
    
    function getLPTokenBalofContract() public view returns(uint){
        return lptokenAdd.balanceOf(address(this));
    }
    
    function getRewardTokenBalofContract() public view returns(uint){
      return  rewardtokenAdd.balanceOf(address(this));
    }
    
    //gert amount curently staked by staker
    function getStakedAmount( address staker) public view returns(uint){
        return lptokenAdd.balanceOf(staker);
    }
    
    function timeOfstaking( address _staker) public view returns (uint) {
        return timeOfStaking[_staker] ;
    }
     
    function stake(uint _amountToBeStaked) public {
        require (staketokenAdd.balanceOf(msg.sender ) >= _amountToBeStaked , 'you have no stake tokens to stake');
        require(timeOfStaking[msg.sender] == 0, 'you cannot stake again until you claim previous reward from last stake');
    
        // transfer the stake token to the staking contract 
        staketokenAdd.transferFrom(msg.sender, address(this), _amountToBeStaked);
        
        //send lp tokens to the function caller. the lp tokens are evidence of amount of tokens staked.
        lptokenAdd.mint(msg.sender, _amountToBeStaked);

        //time tokens were staked by msg.sender
        timeOfStaking[msg.sender] = block.timestamp;

        emit Stake(msg.sender);
    } 
    
    
    function withdrawAndReward() public{ 
         //make sure lptokenBalOfSender is greater or less than the withdrawalAmount
        require(lptokenAdd.balanceOf(msg.sender) > 0, 'you have no staked tokens');
        uint lpamount = lptokenAdd.balanceOf(msg.sender);

        //burn lp token with msg.sender 
        lptokenAdd.burn(msg.sender, lpamount);

        // transfer staked tokens back to owner 
        staketokenAdd.transfer(msg.sender, lpamount);
        
        // calculate interest to be paid as reward tokens
        uint interest = lpamount/100;
        
        //transfer reward tokens to owner, they serve as interest on the Stake
        rewardtokenAdd.mint(msg.sender, interest);

        timeOfStaking[msg.sender] = 0;
        emit Withdraw(msg.sender);
    }
    
      
}