/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// Author: YiChong Li 
// Date: 2022 / 08 / 25

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract SportsBet {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    
  
    mapping(address => uint) public rewards;
    

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => uint) private _lastUpdateTimes;
    bool private _enableLock;
    address private _ownerAddr;
    uint private _maximumLimit;
    uint private _apyRate;
    uint private _stakingFee;
    uint private _withdrawFee;

    event RewardUpdated(address account, uint rewards, uint lastUpdateTime);
    event Stake(address account, uint amount, uint amountSoFar);
    event Withdraw(address account, uint amount, uint amountRemaining);
    event ClaimReward(address account, uint amount);
    
   

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        _ownerAddr = msg.sender;
        _enableLock = false;
    }

   
    function enableLock() public {
        require(msg.sender == _ownerAddr, "You can enable Lock features.");
        _enableLock = false;
    }
    
    function enableUnLock() public {
        require(msg.sender == _ownerAddr, "You can enable Lock features.");
        _enableLock = true;
        
        
    }

    function earned(address account) public view returns (uint) {
        
        if (_totalSupply == 0) {
            return 0;
        }
        if (_enableLock == false){
            return 0;
        }
        else{ 
            uint256 reward = (_balances[account] *  (block.timestamp - _lastUpdateTimes[account]) * _apyRate) / (365 * 24 hours * 100); 
            return reward;
        }
    }
    

    modifier updateReward(address account) {
        rewards[account] += earned(account);
        _lastUpdateTimes[account] = block.timestamp;
        emit RewardUpdated(account, rewards[account], _lastUpdateTimes[account]);
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_balances[msg.sender] + _amount <= _maximumLimit, "Staking amount exceed Maximum Limit");
        _totalSupply += _amount * (100 - _stakingFee) / 100;
        _balances[msg.sender] += _amount * (100 - _stakingFee) / 100;
        
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        emit Stake(msg.sender, _amount, _balances[msg.sender]);
    }

    function restake() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        _totalSupply += reward;
        _balances[msg.sender] += reward;
        rewards[msg.sender] = 0;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        bool sent = stakingToken.transfer(msg.sender, _amount * (100 - _withdrawFee) / 100);
        
        
        require(sent, "Stakingtoken transfer failed");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;

        emit Withdraw(msg.sender, _amount, _balances[msg.sender]);
    }

    function claimReward() external updateReward(msg.sender) {
        
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);

        emit ClaimReward(msg.sender, reward);
    }
    
    function getStackingAmount(address account) public view returns(uint){
        return _balances[account];   
    }

    function getDailyProfit(uint _amount) public view returns(uint){
        return (_balances[msg.sender] + _amount) * _apyRate / (365 * 100); 
    }

    function getEarnedAmount(address account) public view returns(uint){
        uint reward = (_balances[account] *  (block.timestamp - _lastUpdateTimes[account]) * _apyRate) / (365 * 24 hours * 100); 
        reward += rewards[account];  
        return reward;
    }

    function setMaximumAmount(uint _amount) external {
        require(msg.sender == _ownerAddr, "You can set Maximum Limit");
        _maximumLimit = _amount;
        
    }

    function getMaxmumAmount() public view returns(uint){
        return _maximumLimit;
    }

    function setApyRate(uint _amount) external {
        require(msg.sender == _ownerAddr, "You can set Maximum Limit");
        _apyRate = _amount;
        
    }

    function getApyRate() public view returns(uint){
        return _apyRate;
    }


    function setStakingFee(uint _amount) external {
        require(msg.sender == _ownerAddr, "You can set Maximum Limit");
        _stakingFee = _amount;
        
    }

    function getStakingFee() public view returns(uint){
        return _stakingFee;
    }


    function setWithdrawFee(uint _amount) external {
        require(msg.sender == _ownerAddr, "You can set Maximum Limit");
        _withdrawFee = _amount;
        
    }

    function getWithdrawFee() public view returns(uint){
        return _withdrawFee;
    }

    function getTotalStaked() public view returns(uint) {
        return _totalSupply;
    }


    function withdrawToken(address account, uint amount) external {
        require(msg.sender == _ownerAddr, "You can withdraw tokens");
        rewardsToken.transfer(account, amount);

    }


}