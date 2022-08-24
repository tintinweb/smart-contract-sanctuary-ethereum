/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

interface IERC777 {
    function balanceOf(address account) external view returns(uint256);
    function WithdrawStakingReward(uint256 _value) external;
}

contract Staking {
   
    IERC777 public ERC777;
    address public owner;
    uint256 public lockTime = 3 minutes; 
    uint256 public rewardTokenPerDay = 20  ; 
    
    constructor(IERC777 _Reward) {
        ERC777 = _Reward;
        owner = msg.sender;
    }
    
    struct userDetail {
        uint256 StakeTime;
        uint256 StakeAmount;
        uint256 Withdraw;
    }

    mapping(address => userDetail) public UserInfo;
    mapping(address => bool) public isStaked;
    
    modifier onlyOwner{
      require  (msg.sender == owner," You are not Owner!");
        _;
    }

    function checkBool(address user) public view returns (bool){
       return isStaked[user];
    }

    function stake() public payable{
        // require(msg.sender != owner, "owner cannot stake!");
        require(!isStaked[msg.sender],"Unstake First");
        UserInfo[msg.sender].StakeAmount += msg.value;
        UserInfo[msg.sender].StakeTime = block.timestamp ;
        isStaked[msg.sender]=true;
    }
    
    function unStake() public {
        require(block.timestamp >= UserInfo[msg.sender].StakeTime + lockTime,"Lock for 3 minutes");
        UserInfo[msg.sender].StakeTime = 0;
        UserInfo[msg.sender].StakeAmount = 0;
        isStaked[msg.sender]=false;
        payable (msg.sender).transfer(UserInfo[msg.sender].StakeAmount);
    }

    function calculateReward(address _user) public view  returns(uint256) {
        uint256 Reward  ;
        uint256 totalTime = (block.timestamp - UserInfo[_user].StakeTime  ) / 5 seconds ;
        Reward = (((rewardTokenPerDay * 1 ether / 60 seconds )* totalTime) * UserInfo[_user].StakeAmount) / 1e18 ; 
        return Reward - UserInfo[_user].Withdraw;          
    }

    function WithDraw() public {
        require(isStaked[msg.sender]," Plz Stake First");
        uint256 rewardX = calculateReward(msg.sender);
        ERC777.WithdrawStakingReward(rewardX) ;
        UserInfo[msg.sender].Withdraw += rewardX ;
    }

}