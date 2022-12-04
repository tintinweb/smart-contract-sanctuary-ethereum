// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract States {
   bool public isStakeActive = true;
   bool public isUnStakeActive = true;


    bool public earlyUstake;
    bool public apyEnabled = true;
    bool public autoCompund = false;

    using TransferHelper for IERC20;

    IERC20 public token;
    address public rewardingWallet;

    uint256 public unStakeFee;
    uint256 public apyTier = 1000;

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

contract StakePoolTokenForToken is States, Ownable, ReentrancyGuard{

    using SafeMath for uint256;

    constructor(IERC20 _token, address wallet){
        token = _token;
        rewardingWallet = wallet;
    }

    receive() external payable{}

    function flipApyEnabled() public onlyOwner {
        apyEnabled = !apyEnabled;
    }

    function setStakingToken(IERC20 _stakingtoken) public onlyOwner {
        token = _stakingtoken;
    }

    function setUnstakeFee(uint256 _fee) public onlyOwner {
        unStakeFee = _fee;
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

    
    function _stakeTokens(uint256 _amount)  internal {

        require(token.balanceOf(_msgSender())>=_amount, "you do not have sufficient balance");
        require(token.allowance(_msgSender(), address(this))>=_amount, "tokens not approved");
        require(isStakeActive, "staking is pause");
        
        User storage wUser = deposit[_msgSender()];
        uint256 prevReward = checkReward(_msgSender());

        wUser.stakedAmount = wUser.stakedAmount.add(_amount);
        wUser.totalAmount = wUser.stakedAmount.add(_amount).add(prevReward);
        wUser.depositTime = block.timestamp;
        wUser.lastClaimTime = block.timestamp;
        wUser.reward = prevReward;
        
        TransferHelper.safeTransferFrom(address(token), _msgSender(), address(this), _amount);

        totalStaked+=_amount;
        
        emit Stake(_msgSender(), _amount, block.timestamp);
    }

    function UnstakeTokens() public {
      require(isUnStakeActive, "staking is pause");
          _unstakeTokens(_msgSender());
    }

    function _unstakeTokens(address _address) internal {
        User memory wUser = deposit[_address];

        require(wUser.stakedAmount > 0, "deposit first");

        if(apyEnabled){
                _claim(_address);
        }
        token.transfer(_address,wUser.stakedAmount);

        totalStaked-=wUser.stakedAmount;
        deposit[_address] = User(0, 0, 0, 0, 0, block.timestamp);

        emit Unstake(_address, block.timestamp);
    }

    function EmergencyUnstake() public {
      User memory wUser = deposit[_msgSender()];

        require(wUser.stakedAmount > 0, "deposit first");

        token.transfer(_msgSender(),wUser.stakedAmount);

        totalStaked-=wUser.stakedAmount;
        deposit[_msgSender()] = User(0, 0, 0, 0, 0, block.timestamp);

        emit Emergencyunstake(_msgSender(), block.timestamp);
    }

    
    

    function _claim(address _address) internal {
        User storage info = deposit[_address];
        // uint256 claimcurrentReward = checkReward(_address);
        uint256 claimcurrentReward = checkReward(_address);
        claimcurrentReward = claimcurrentReward.add(info.reward);
        require(claimcurrentReward > 0, "Current Reward is 0");

        if(claimcurrentReward <= pendingRewards() ){
            TransferHelper.safeTransferFrom(address(token), rewardingWallet, _address, claimcurrentReward);
        } else{
            require(false, "Pending Rewards Not Allocated");
        }
        info.lastClaimTime = block.timestamp;
        emit Claim(_address , claimcurrentReward);
    }

    function claim() public {
        User memory info = deposit[_msgSender()];
        require(info.stakedAmount > 0, "Not Staked");
        require(apyEnabled, "No reward");
          _claim(_msgSender());
    }

    function pendingRewards() public view returns (uint256){
        return token.allowance(rewardingWallet, address(this));
    }

    function withdrawAnyTokens(address _token, address recipient, uint256 amount) public onlyOwner{
        require(_token != address(token), "can't withdraw Staking Token");
        IERC20 anyToken = IERC20(_token);
        anyToken.transfer(recipient, amount);
        emit WithdrawToken(recipient, amount);
    }

    function withdrawFunds() public onlyOwner{
       payable(_msgSender()).transfer(address(this).balance);
       emit Withdraw(_msgSender());
    }

    function contracEthBalance() public view returns (uint256) {
      return address(this).balance;
    }
    
    
    function checkReward(address _address) public view returns (uint256){

        User memory cUser = deposit[_address];
        require(block.timestamp + 1 seconds > cUser.lastClaimTime, "Time");

        uint256 stakedtime = (block.timestamp).sub(cUser.lastClaimTime);

        stakedtime = stakedtime / 1 seconds;

        uint256 reward= apyTier.mul(stakedtime).mul(cUser.stakedAmount).div(10000).div(365);
        return reward;
    }
}