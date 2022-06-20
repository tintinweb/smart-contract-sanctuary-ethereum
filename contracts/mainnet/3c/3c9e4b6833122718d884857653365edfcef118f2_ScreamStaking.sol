/**
AAAAHHHH! Welcome to..... 

SCREAM (AAHHHH)|ERC-20 

“Movies Don’t Create Psychos. Movies Make Psychos More Creative!” 🔪

🔪 Twitter: https://twitter.com/SCREAM_ETH

🔪 Website: https://screameth.com

🔪 Telegram: https://t.me/ScreamOfficialPortal
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Context.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Fees.sol";
 
contract ScreamStaking is Context, Ownable, Fees {
    using SafeERC20 for IERC20;

    /// @notice enum Status contains multiple status.
    enum Status { Collecting, Staking, Completed }

    struct VaultInfo {
        Status status; // vault status
        uint256 stakingPeriod; // the timestamp length of staking vault.
        uint256 startTimestamp;  // block.number when the vault start accouring rewards.
        uint256 stopTimestamp; // the block.number to end the staking vault.
        uint256 totalVaultShares; // total tokens deposited into Vault.
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }

    struct RewardInfo {
        uint256 lastRewardUpdateTimeStamp;
        uint256 rewardRate; // rewardRate is totalVaultRewards / stakingPeriod.
        uint256 pendingVaultRewards;
        uint256 claimedVaultRewards; // claimed rewards for the vault.
        uint256 remainingVaultRewards; // remaining rewards for this vault.        
    }
    
    IERC20 public token;
    VaultInfo public vault;
    RewardInfo private _reward;
    mapping(address => uint256) private _balances;

    error NotAuthorized();
    error NoZeroValues();
    error MaxStaked();
    error AddRewardsFailed();
    error DepositFailed();
    error RewardFailed();
    error WithdrawFailed();
    error NotCollecting();  
    error NotStaking();
    error NotCompleted();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 rewards);
    event StakingStarted();
    event StakingCompleted();

    /// @notice modifier checks that a user is staking.
    /// @param account The account address to check.
    modifier isStakeholder(address account) {
        if (_balances[account] == 0) revert NotAuthorized();
        _;
    }

    /// @notice modifier checks that contract is in status Collecting.
    modifier isCollecting() {
        if (vault.status != Status.Collecting) revert NotCollecting();
        _;
    }

    /// @notice modifier checks that contract has status Staking.
    modifier isStaking() {
        if (vault.status != Status.Staking) revert NotStaking();
        _;
    }

    /// @notice modifier checks that contract has status Completed.
    modifier isCompleted() {
        if (vault.status != Status.Completed) revert NotCompleted();
        _;
    }

    /// @notice modifier checks for zero values.
    /// @param amount The user amount to deposit in Wei.
    modifier noZeroValues(uint256 amount) {
        if (_msgSender() == address(0) || amount <= 0) revert NoZeroValues();
        _;
    }

    /// @notice modifier sets a max limit to 1 million tokens staked per user.
    modifier limiter(uint256 amount) {
        uint256 balance = _balances[_msgSender()];
        uint256 totalBalance = balance + amount;
        if (totalBalance >= 1000000000000000000000000) revert MaxStaked();
        _;
    }

    /// @notice modifier updates the vault reward stats.
    modifier updateVaultRewards() {
        require(_reward.remainingVaultRewards > 0);
        
        uint256 _currentValue = _reward.rewardRate * (block.timestamp - _reward.lastRewardUpdateTimeStamp);
        _reward.pendingVaultRewards += _currentValue;
        _reward.remainingVaultRewards -= _currentValue;
        _reward.lastRewardUpdateTimeStamp = block.timestamp;
        _;
    }

    /// @notice Constructor for TicketVault, staking contract.
    /// @param Token The token used for staking.
    constructor(
        address Token
    ) {
        token = IERC20(Token);
        feeAddress = _msgSender();
        vault.stakingPeriod = 4 weeks; // 1 month staking period.
        withdrawFeePeriod = vault.stakingPeriod; // 1 month fee period.
        withdrawPenaltyPeriod = 2 weeks; // 2 weeks penalty period.
        withdrawFee = 700; // 7% withdraw fee.
        vault.status = Status.Collecting; 
    }   

    /// @notice receive function reverts and returns the funds to the sender.
    receive() external payable {
        revert("not payable receive");
    }

/// ------------------------------- PUBLIC METHODS -------------------------------

    /// Method to get the users erc20 balance.
    /// @param account The account of the user to check.
    /// @return user erc20 balance.
    function getAccountErc20Balance(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    /// Method to get the users vault balance.
    /// @param account The account of the user to check.
    /// @return user balance staked in vault.
    function getAccountVaultBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// Method to get the vaults RewardInfo.
    function getRewardInfo() external view returns (
        uint256 lastRewardUpdateTimeStamp,
        uint256 rewardRate, 
        uint256 pendingVaultRewards,
        uint256 claimedVaultRewards, 
        uint256 remainingVaultRewards
    ) {
        return (
            _reward.lastRewardUpdateTimeStamp,
            _reward.rewardRate,
            _reward.pendingVaultRewards,
            _reward.claimedVaultRewards,
            _reward.remainingVaultRewards);
    }

    /// @notice Method to let a user deposit funds into the vault.
    /// @param amount The amount to be staked.
    function deposit(uint256 amount) external isCollecting limiter(amount) noZeroValues(amount) {
        _balances[_msgSender()] += amount;
        vault.totalVaultShares += amount;
        if (!_deposit(_msgSender(), amount)) revert DepositFailed();
        emit Deposit(_msgSender(), amount);
    }
    
    /// @notice Lets a user exit their position while status is Collecting. 
    /// @notice ATT. The user is subject to an 7% early withdraw fee.
    /// @dev Can only be executed while status is Collecting.
    function exitWhileCollecting() external isStakeholder(_msgSender()) isCollecting {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);
        vault.totalVaultShares -= _totalUserShares;
        
        // Pay 7% withdrawFee before withdraw.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();
        
        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Lets a user exit their position while staking. 
    /// @notice ATT. The user is subject to an 7% early withdraw fee.
    /// @dev Can only be executed while status is Staking.
    function exitWhileStaking() external isStakeholder(_msgSender()) isStaking updateVaultRewards {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);

        // if withdrawPenaltyPeriod is over, calculate user rewards.
        if (block.timestamp >= (vault.startTimestamp + withdrawPenaltyPeriod)) {
            uint256 _pendingUserReward = _calculateUserReward(_totalUserShares);
            _withdrawAmount += _pendingUserReward;

            _reward.pendingVaultRewards -= _pendingUserReward;
            _reward.remainingVaultRewards -= _pendingUserReward;
            _reward.claimedVaultRewards += _pendingUserReward;
        }
        vault.totalVaultShares -= _totalUserShares;

        // Pay 7% in withdrawFee before the withdraw is transacted.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();

        emit ExitWithFees(_msgSender(), _withdrawAmount, _feeAmount);
    }

    /// @notice Let the user remove their stake and receive the accumulated rewards, without paying extra fees.
    function withdraw() external isStakeholder(_msgSender()) isCompleted {
        require(_msgSender() != address(0), "Not zero adress");
        
        uint256 _totalUserShares =  _balances[_msgSender()];
        delete _balances[_msgSender()];
    
        uint256 _pendingUserReward = _calculateUserReward(_totalUserShares);
        
        if (!_withdraw(_msgSender(), _pendingUserReward)) revert RewardFailed();
        if (!_withdraw(_msgSender(), _totalUserShares)) revert WithdrawFailed();
        
        _reward.pendingVaultRewards -= _pendingUserReward;
        _reward.claimedVaultRewards += _pendingUserReward;
        vault.totalVaultShares -= _totalUserShares;

        emit Withdraw(_msgSender(), _totalUserShares, _pendingUserReward);
    }

/// ------------------------------- ADMIN METHODS -------------------------------

    /// @notice Add reward amount to the vault.
    /// @param amount The amount to deposit in Wei.
    /// @dev Restricted to onlyOwner.  
    function addRewards(uint256 amount) external onlyOwner {
        if (!_deposit(_msgSender(), amount)) revert AddRewardsFailed();
        
        vault.totalVaultRewards += amount;
        _reward.rewardRate = (vault.totalVaultRewards / vault.stakingPeriod);
        _reward.remainingVaultRewards += amount;
    }

    /// @notice Sets the contract status to Staking.
    function startStaking() external isCollecting onlyOwner {
        vault.status = Status.Staking;
        vault.startTimestamp = block.timestamp;
        vault.stopTimestamp = vault.startTimestamp + vault.stakingPeriod;
        _reward.lastRewardUpdateTimeStamp = vault.startTimestamp;

        emit StakingStarted();
    }

    /// @notice Sets the contract status to Completed.
    /// @dev modifier updateVaultRewards is called before status is set to Completed.
    function stopStaking() external isStaking onlyOwner {
        vault.status = Status.Completed;
        _reward.pendingVaultRewards += _reward.remainingVaultRewards;
        _reward.remainingVaultRewards = 0;
        emit StakingCompleted();
    }
    
/// ------------------------------- PRIVATE METHODS -------------------------------

    /// @notice Internal function to deposit funds to vault.
    /// @param _from The from address that deposits the funds.
    /// @param _amount The amount to be deposited in Wei.
    /// @return true if valid.
    function _deposit(address _from, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, address(this), _amount);
        return true;
    }
 
    /// @notice Internal function to withdraw funds from the vault.
    /// @param _to The address that receives the withdrawn funds.
    /// @param _amount The amount to be withdrawn.
    /// @return true if valid.
    function _withdraw(address _to, uint256 _amount) private returns (bool){
        token.safeTransfer(_to, _amount);
        return true;
    }

    /// @notice Internal function to calculate the pending user rewards.
    /// @param _totalUserShares The total amount deposited to vault by user.
    /// @return pending user reward amount.
    function _calculateUserReward(uint256 _totalUserShares) private view returns (uint256) {
        require(_reward.pendingVaultRewards > 0, "No pending rewards");
        
        uint256 _userPercentOfVault = _totalUserShares * 100 / vault.totalVaultShares;
        uint256 _pendingUserReward = _reward.pendingVaultRewards * _userPercentOfVault / 100;

        return _pendingUserReward;
    }

    function clearStuckBNBBalance(address addr) external onlyOwner{
        (bool sent,) =payable(addr).call{value: (address(this).balance)}("");
        require(sent);
    }

    function clearStuckTokenBalance(address addr, address tokenAddress) external onlyOwner{
        uint256 _bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).safeTransfer(addr, _bal);
    }
}