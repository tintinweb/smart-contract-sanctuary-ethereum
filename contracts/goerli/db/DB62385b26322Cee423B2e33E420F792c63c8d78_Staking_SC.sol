// SPDX-License-Identifier: MIT
//Not for prod due to the high gas consumption issue;

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Staking_SC {

   IERC20 public stakingToken;
   IERC20 public rewardsToken;

    constructor(address _stakingToken, address _rewardsToken, uint _fullRewardRate)   {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        fullRewardRate=_fullRewardRate;
    }

    uint public fullRewardRate;
    uint public lastTimeUpd;
    uint public totalStaked;
    Users[] public arrayUsers;
    mapping(address => uint) public violations; 
    
    struct Users {
        address user_address;
        uint balance;
        uint rewardBalance;
    }

    modifier recalcRewards() {
        recalcRewardForEveryUser();
        _;
    }

    function stake(uint _amount) public recalcRewards {  
         if (!_isExistUser(msg.sender)) {
            arrayUsers.push(Users(msg.sender, _amount, 0));
            } else { 
                for (uint i=0; i < arrayUsers.length;i++) { 
                    if (arrayUsers[i].user_address == msg.sender) {
                        uint userId=i;
                        arrayUsers[userId].balance += _amount;
                        break;
                    }
                
                }
                 
        }
        totalStaked += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function _isExistUser(address stakerAddress) public recalcRewards returns(bool) {
         for (uint i=0; i < arrayUsers.length;i++) {
            if (arrayUsers[i].user_address == stakerAddress) {
                return true; 
            }
        }
    }

    function unstake(uint _amount) public recalcRewards {
        require(_isExistUser(msg.sender));
        for (uint i=0; i < arrayUsers.length;i++) { 
            if (arrayUsers[i].user_address == msg.sender) {
                uint userId=i;
                    arrayUsers[userId].balance -= _amount;
                    break;
            }
                
        }
        totalStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function recalcRewardForEveryUser() public {
        for (uint i=0; i < arrayUsers.length;i++) { 
            arrayUsers[i].rewardBalance += fullRewardRate*1e18/totalStaked*arrayUsers[i].balance*(block.timestamp - lastTimeUpd)/1e18;
        }
        lastTimeUpd = block.timestamp;
    }

    function getRewards() public { 
        for (uint i=0; i < arrayUsers.length;i++) { 
            if (arrayUsers[i].user_address == msg.sender) {
                break;
                rewardsToken.transfer(msg.sender, arrayUsers[i].rewardBalance);
                arrayUsers[i].rewardBalance = 0;
            }
        }
    }

    function checkRewardsByUser(address user) public returns(uint) {
        recalcRewardForEveryUser();
        for (uint i=0; i < arrayUsers.length;i++) { 
            if (arrayUsers[i].user_address == user) {
                return arrayUsers[i].rewardBalance;
                break;
            }
        }
    }


    fallback() external {
        violations[msg.sender]++;
    }

}