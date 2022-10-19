// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SafeERC20.sol';
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public rewards; //ether

    uint256 public minStake;

    uint256 public allowWithdrawTime;

    uint256 public startTime;

    uint256 public endTime;

    address public marketingAddress;

    uint256 public numberStakes;

    // The staked token
    IERC20 public stakingToken;

    uint256 public totalStaked;
    uint256 public totalStakedValue;

    struct UserInfo {
      uint256 amount;
    }

    struct Stake {
      uint256 amount;     // amount to stake
      uint256 stakeTime; // stake time
    }

    mapping(address => Stake[]) public userStakes;
    mapping(address => UserInfo) public userStaked;

    event Deposit(address indexed user, uint256 amount, uint256 amountValue);
    event Withdraw(address indexed user, uint256 amount);

    event RewardsUpdated(uint256 rewards);
    event MinStakeUpdated(uint256 minStake);

    event ClaimedRewards(address indexed user, uint256 tokenAmount, uint256 ethAmount);

    constructor(
      uint256 _allowWithdrawTime,
      uint256 _endTime,
      uint256 _minStake,
      address _marketingAddress,
      IERC20 _stakingToken
    ) {
      allowWithdrawTime = _allowWithdrawTime;
      endTime = _endTime;
      minStake = _minStake;
      marketingAddress = _marketingAddress;
      stakingToken = _stakingToken;
      startTime = block.timestamp;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     */
    function deposit(uint256 _amount) external payable nonReentrant {
        require(block.timestamp < endTime, "Staking ended");
        require(_amount > 0, "Amount should be greator than 0");
        require(_amount >= minStake, "Amount should be greator than min stake");

        UserInfo storage user = userStaked[msg.sender];

        uint256 amountValue = (_amount * (endTime - block.timestamp)) / 3600;

        stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        totalStaked = totalStaked + _amount;
        totalStakedValue = totalStakedValue + amountValue;

        user.amount = user.amount + _amount;

        numberStakes += 1;

        _addStake(msg.sender, _amount);

        emit Deposit(msg.sender, _amount, amountValue);
    }

    function _addStake(address _account, uint256 _amount) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 i = stakes.length;

        stakes.push(); // grow the array
        // find the spot where we can insert the current stake
        // this should make an increasing list sorted by end
        // stakes[i] = stakes[i - 1];

        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.amount = _amount;
        newStake.stakeTime = block.timestamp;
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     */
    function withdraw(uint256 _amount) external payable nonReentrant {
        require(block.timestamp < endTime, "Staking ended");
        require(_amount > 0, "Amount should be greator than 0");
        require(_amount >= minStake, "Amount should be greator than min stake");

         UserInfo storage user = userStaked[msg.sender];

        require(_amount <= user.amount, "Amount should be lesser than staked amount");
       
        Stake[] storage stakes = userStakes[msg.sender];

        uint256 amountValue;

        uint256 remainAmount = _amount;

        uint256 j = stakes.length - 1;

        while(remainAmount > 0 && j >= 0) {
          if (stakes[j].amount > remainAmount) {
            amountValue = amountValue + (remainAmount * (endTime - stakes[j].stakeTime)) / 3600;
            Stake storage newStake = stakes[j];
            newStake.amount = stakes[j].amount - remainAmount;

            remainAmount = 0;
          } else {
            amountValue = amountValue + (stakes[j].amount * (endTime - stakes[j].stakeTime)) / 3600;
            remainAmount = remainAmount - stakes[j].amount;
            
            stakes.pop();
            if (j >= 1) {
              j = j - 1;
            }
            
            
          } 
        }
  
        user.amount = user.amount - _amount;

        totalStaked = totalStaked - _amount;
        totalStakedValue = totalStakedValue - amountValue;

        stakingToken.safeTransfer(address(msg.sender), _amount);
       
        emit Withdraw(msg.sender, _amount);
    }

    function claimRewards() external payable nonReentrant {
      require(block.timestamp >= allowWithdrawTime, "Withdraw time: Cannot claim token");
      
      UserInfo storage user = userStaked[msg.sender];

      require(user.amount > 0, "User don't have staking token");

      Stake[] storage stakes = userStakes[msg.sender];

      uint256 rewardTime;

      uint256 rewardAmountValue;

      if (block.timestamp >= endTime) {
        rewardTime = endTime;
      } else {
        rewardTime = block.timestamp;
      }

      for (uint256 i = 0; i < stakes.length; i++) {
        rewardAmountValue += (stakes[i].amount * (rewardTime - stakes[i].stakeTime)) / 3600;
      }

      uint256 userRewards = ((rewardAmountValue * rewards) / totalStakedValue);

      rewards = rewards - userRewards;
      totalStakedValue = totalStakedValue - rewardAmountValue;

      payable(address(msg.sender)).transfer(userRewards);
      stakingToken.safeTransfer(address(msg.sender), user.amount);

      user.amount = 0;

      delete(userStakes[msg.sender]);

      emit ClaimedRewards(msg.sender, user.amount, userRewards);
    }

    function getContractBalance() public view returns (uint256) {
      return address(this).balance;
    }


    function getTokenBalance() public view returns (uint256) {
      return stakingToken.balanceOf(address(this));
    }

    function getNumberUserStakes(address account) public view returns (uint256) {
      return userStakes[account].length;
    }


    receive() external payable {
      rewards = rewards + msg.value;
      emit RewardsUpdated(rewards);
    }

    function withdrawBalances() external payable onlyOwner {
      if (address(this).balance > 0) {
        payable(address(marketingAddress)).transfer(address(this).balance);
      }
    }


    function addRewards(uint256 _rewards) external payable onlyOwner {
      require(_rewards > 0, "Rewards not valid");

      payable(address(this)).transfer(_rewards);

      rewards = rewards + _rewards;
      emit RewardsUpdated(rewards);
    }


    function setMinStake(uint256 _minStake) external onlyOwner {
        require(_minStake > 0, "lower limit reached");
        minStake = _minStake;
        emit MinStakeUpdated(_minStake);
    }


    function setMarketingAddress(address _marketingAddress) external onlyOwner {
      require(_marketingAddress != address(0), 'Marketing address invalid');
      marketingAddress = _marketingAddress;
    }
}