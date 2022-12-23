// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract StateContext {
    using TransferHelper for IERC20;
    
    bool public isStakeActive = true;
    bool public isUnStakeActive = true;
    bool public apyEnabled = true;
    
    uint256 public apyTier = 1618;
    uint256 public totalStaked;

    IERC20 public token;
    address public rewardingWallet;
    mapping(address => User) public deposit;

    struct User {
        uint256 stakedAmount;
        uint256 totalAmount;
        uint256 depositTime;
        uint256 lastClaimTime;
        uint256 reward;
    }

    event Stake(address indexed staker, uint256 _amount, uint256 _lockPeriod);
    event Unstake(address indexed unstaker, uint256 unstakeTime);
    event Emergencyunstake(address indexed unstaker, uint256 unstakeTime);
    event Withdraw(address indexed withdrawer);
    event WithdrawToken(address indexed withdrawer, uint256 amount);
    event Claim(address staker, uint256 reward);
}

contract StakeSTATE is StateContext, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    constructor(IERC20 _token, address wallet) {
        token = _token;
        rewardingWallet = wallet;
    }

    receive() external payable {}
    
    /**
      * function to Enable or Disable the Reward
      */
    function flipApyEnabled() public onlyOwner {
        apyEnabled = !apyEnabled;
    }

    /**
      * function to set the apy. It takes one argument and it should be multiplied with 100.
      */
    function setApy(uint256 apy) public onlyOwner {
        apyTier = apy;
    }
    
    /**
      * function to set the rewarding Wallet. It takes one argument as address of wallet.
      */
    function setRewardingWallet(address wallet) public onlyOwner {
        rewardingWallet = wallet;
    }

    /**
      * function to change the state of staking. Enable or Disable staking.
      */
    function flipStakeState() public onlyOwner {
        isStakeActive = !isStakeActive;
    }

    /**
      * function to change the state of Unstaking. Enable or Disable Unstaking.
      */
    function flipUnStakeState() public onlyOwner {
        isUnStakeActive = !isUnStakeActive;
    }
    
    /**
      * function to set the Token Address. It takes one argument of token address.
      */
    function setTokenAddress(IERC20 _token) public onlyOwner {
        token = _token;
    }
    
    /**
      * Public function to stake the $STATE tokens. It takes one argument of amount as input.
      */
    function stake(uint256 _amount) public nonReentrant {
        require(token.balanceOf(_msgSender()) >= _amount, "You Do Not Have Sufficient Balance");
        require(token.allowance(_msgSender(), address(this)) >= _amount, "Tokens Not Approved");
        require(isStakeActive, "Staking Is Paused");

        _stakeTokens(_amount);
    }

    /**
      * Internal function to stake the $STATE tokens. It takes one argument of amount as input and called from public function.
      */
    function _stakeTokens(uint256 _amount) internal {        
        User storage wUser = deposit[_msgSender()];
        uint256 prevReward = checkReward(_msgSender());

        wUser.stakedAmount = wUser.stakedAmount.add(_amount);
        wUser.totalAmount = wUser.stakedAmount.add(_amount).add(prevReward);
        wUser.depositTime = block.timestamp;
        wUser.lastClaimTime = block.timestamp;
        wUser.reward = prevReward;

        TransferHelper.safeTransferFrom(address(token), _msgSender(), address(this), _amount);

        totalStaked += _amount;
      
        emit Stake(_msgSender(), _amount, block.timestamp);
    }

    /**
      * Public function to unstake the tokens. It takes one argument as an input.
      */
    function UnstakeTokens(uint256 amount) public nonReentrant {
        require(isUnStakeActive, "Unstaking Is Paused");

        _unstakeTokens(_msgSender(), amount);
    }

    /**
      * Internal function to unstake the tokens. It takes one argument as an input and called from public function.
      */
    function _unstakeTokens(address _address, uint256 amount) internal {
        User storage wUser = deposit[_address];
        require(wUser.stakedAmount >= amount, "Stake First To Unstake Tokens");

        if(apyEnabled) {
            _claim(_address);
        }
      
        token.transfer(_address, amount);

        totalStaked -= amount;

        wUser.stakedAmount = wUser.stakedAmount.sub(amount);
        wUser.totalAmount = wUser.totalAmount.sub(amount);
        wUser.depositTime = block.timestamp;

        emit Unstake(_address, block.timestamp);
    }

    /**
      * Intenal function to claim the token reward. It takes one argument of staker wallet address.
      */
    function _claim(address _address) internal {
        User storage info = deposit[_address];
        
        uint256 claimcurrentReward = checkReward(_address);
        claimcurrentReward = claimcurrentReward.add(info.reward);
        info.totalAmount = info.totalAmount.sub(claimcurrentReward);

        if(claimcurrentReward <= pendingRewards()) {
            TransferHelper.safeTransferFrom(address(token), rewardingWallet, _address, claimcurrentReward);
        } else {
            require(false, "Pending Rewards Not Allocated");
        }
        
        info.lastClaimTime = block.timestamp;
        info.reward = 0;
        
        emit Claim(_address, claimcurrentReward);
    }

    /**
      * Public function to claim the token reward.
      */
    function claim() public nonReentrant {
        User memory info = deposit[_msgSender()];
        require(info.stakedAmount > 0, "Not Staked");
        require(apyEnabled, "APY is not enabled");

        uint256 reward = checkReward(_msgSender());
        reward = reward.add(info.reward);
        require(reward > 0, "Current Reward Is 0");
        
        _claim(_msgSender());
    }

    /**
      * function to check the pending or approved rewarding amount of tokens.
      */
    function pendingRewards() public view returns (uint256) {
        return token.allowance(rewardingWallet, address(this));
    }

    /**
      * To withdraw tokens stuck in the smart contract. Only owner of contract can call this method.
      */
    function withdrawAnyTokens(address _token, address recipient, uint256 amount) public onlyOwner {
        IERC20 anyToken = IERC20(_token);
        anyToken.transfer(recipient, amount);
        
        emit WithdrawToken(recipient, amount);
    }

    /**
      * To withdraw Eth stuck in the contract. Only owner of contract can call this method.
      */
    function withdrawFunds() public onlyOwner {
       payable(_msgSender()).transfer(address(this).balance);
       
       emit Withdraw(_msgSender());
    }

    /**
      * function to get the ETH Balance of contract
      */
    function contracEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
      * Public function to check the Reward of staker wallet. It takes one argument as input and returns the rewarding amoun.
      */
    function checkReward(address _address) public view returns (uint256) {
        User memory cUser = deposit[_address];
        
        if(block.timestamp + 1 days > cUser.lastClaimTime) {
            uint256 stakedtime = (block.timestamp).sub(cUser.lastClaimTime);
            stakedtime = stakedtime / 1 days;

            uint256 reward = apyTier.mul(stakedtime).mul(cUser.stakedAmount).div(10000).div(365);
            
            return reward;
        } else {
            return 0;
        }
    }
}