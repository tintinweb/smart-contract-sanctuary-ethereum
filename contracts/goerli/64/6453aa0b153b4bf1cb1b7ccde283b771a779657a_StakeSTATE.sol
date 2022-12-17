// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract StateContext {
    bool public isStakeActive = true;
    bool public isUnStakeActive = true;
     
    bool public apyEnabled = true;
    bool public autoCompund = false;

    using TransferHelper for IERC20;

    IERC20 public token;
    address public rewardingWallet;

    uint256 public apyTier = 1618;

    struct User {
        uint256 stakedAmount;
        uint256 totalAmount;
        uint256 depositTime;
        uint256 lastClaimTime;
        uint256 reward;
        uint256 endtime;
    }

    mapping(address => User) public deposit;

    uint256 public totalStaked;

    event Stake(address indexed staker, uint256 _amount, uint256 _lockPeriod);
    event Unstake(address indexed unstaker, uint256 unstakeTime);
    event Emergencyunstake(address indexed unstaker, uint256 unstakeTime);
    event Withdraw(address indexed withdrawer);
    event WithdrawToken(address indexed withdrawer, uint256 amount);
    event Claim(address staker, uint256 reward);
}

contract StakeSTATE is StateContext, Ownable, ReentrancyGuard{

    using SafeMath for uint256;

    constructor(IERC20 _token, address wallet){
        token = _token;
        rewardingWallet = wallet;
    }

    receive() external payable{}

    function flipApyEnabled() public onlyOwner {
        apyEnabled = !apyEnabled;
    }

    function setApy(uint256 apy) public onlyOwner {
        apyTier = apy;
    }
    
    function setRewardingWallet(address wallet) public onlyOwner{
        rewardingWallet = wallet;
    }

    function flipStakeState() public onlyOwner {
       isStakeActive = !isStakeActive;
    }

    function flipUnStakeState() public onlyOwner {
       isUnStakeActive = !isUnStakeActive;
    }
    
    function setTokenAddress(IERC20 _token) public onlyOwner {
       token = _token;
    }
    
    function stake(uint256 _amount) public {
        _stakeTokens(_amount);
    }

    uint256 public prevReward;
    function _stakeTokens(uint256 _amount) internal {

        require(token.balanceOf(_msgSender())>=_amount, "You Do Not Have Sufficient Balance");
        require(token.allowance(_msgSender(), address(this))>=_amount, "Tokens Not Approved");
        require(isStakeActive, "Staking Is Paused");
        
        User storage wUser = deposit[_msgSender()];
        prevReward = checkReward(_msgSender());

        wUser.stakedAmount = wUser.stakedAmount.add(_amount);
        wUser.totalAmount = wUser.stakedAmount.add(_amount).add(prevReward);
        wUser.depositTime = block.timestamp;
        wUser.lastClaimTime = block.timestamp;
        wUser.reward = prevReward;

        TransferHelper.safeTransferFrom(address(token), _msgSender(), address(this), _amount);

        totalStaked+=_amount;
        
        emit Stake(_msgSender(), _amount, block.timestamp);
    }

    function UnstakeTokens(uint256 amount) public {
      require(isUnStakeActive, "Staking Is Paused");
          _unstakeTokens(_msgSender(), amount);
    }
        // uint256 stakedAmount;
        // uint256 totalAmount;
        // uint256 depositTime;
        // uint256 lastClaimTime;
        // uint256 reward;
    function _unstakeTokens(address _address, uint256 amount) internal {
        User storage wUser = deposit[_address];

        require(wUser.stakedAmount >= amount, "Stake First To Unstake Tokens");
        // require(block.timestamp > wUser.lockPeriod, "Token locked");

        if(apyEnabled){
                _claim(_address);
        }
        token.transfer(_address, amount);

        totalStaked -= amount;

        wUser.stakedAmount = wUser.stakedAmount.sub(amount);
        wUser.totalAmount = wUser.totalAmount.sub(amount);
        wUser.depositTime = block.timestamp;
        wUser.lastClaimTime = block.timestamp;

        // deposit[_address] = User(0, 0, 0, 0, 0, block.timestamp);

        emit Unstake(_address, block.timestamp);
    }
    
    uint256 public claimcurrentReward;
    function _claim(address _address) internal {
        User storage info = deposit[_address];
        
        claimcurrentReward = checkReward(_address);
        claimcurrentReward = claimcurrentReward.add(info.reward);

        if(claimcurrentReward <= pendingRewards()){
            TransferHelper.safeTransferFrom(address(token), rewardingWallet, _address, claimcurrentReward);
        } else{
            require(false, "Pending Rewards Not Allocated");
        }
        info.lastClaimTime = block.timestamp;
        info.reward = 0;
        emit Claim(_address , claimcurrentReward);
    }

    function claim() public {
        User memory info = deposit[_msgSender()];
        require(info.stakedAmount > 0, "Not Staked");
        require(apyEnabled, "No Reward");

        uint256 reward = checkReward(_msgSender());
        reward = reward.add(info.reward);
        require(reward > 0, "Current Reward Is 0");
          _claim(_msgSender());
    }

    function pendingRewards() public view returns (uint256){
        return token.allowance(rewardingWallet, address(this));
    }

    function withdrawAnyTokens(address _token, address recipient, uint256 amount) public onlyOwner{
        // require(_token != address(token), "can't withdraw Staking Token");
        IERC20 anyToken = IERC20(_token);
        anyToken.transfer(recipient, amount);
        emit WithdrawToken(recipient, amount);
    }

    function withdrawFunds() public onlyOwner{
       payable(_msgSender()).transfer(address(this).balance);
       emit Withdraw(_msgSender());
    }

    function contracEthBalance() public view returns (uint256){
      return address(this).balance;
    }
    
    // uint256 public stakedtime;
    function checkReward(address _address) public view returns (uint256){

        User memory cUser = deposit[_address];
        if(block.timestamp + 1 days > cUser.lastClaimTime){

            uint256 stakedtime = (block.timestamp).sub(cUser.lastClaimTime);
            stakedtime = stakedtime / 1 days;

            uint256 reward= apyTier.mul(stakedtime).mul(cUser.stakedAmount).div(10000).div(365);
            return reward;
        }
        else{

            return 0;

        }
    }
}