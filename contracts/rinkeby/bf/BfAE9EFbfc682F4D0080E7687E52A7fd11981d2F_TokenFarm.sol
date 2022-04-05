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

contract TokenFarm {
  string public name = 'Reward Token Farm';
  address public owner;
  IERC20 public rewToken;
  IERC20 public ethToken;
  uint256 public totalTokensStaked;

  address[] public stakers;
  mapping(address => uint256) public stakeBalance;
  mapping(address => bool) public isStaking;
  mapping(address => uint256) public stakeStart;
  mapping(address => uint256) public yieldBalance;

  constructor(address _rewTokenAddress, address _ethTokenAddress) {
    rewToken = IERC20(_rewTokenAddress);
    ethToken = IERC20(_ethTokenAddress);
    owner = msg.sender;
  }

  //1. Stake tokens
  function stake(uint256 _amount) public {
    require(_amount > 0 && ethToken.balanceOf(msg.sender) >= _amount, 'Amount cannont be 0');

    if (isStaking[msg.sender] == true) {
      uint256 transferYield = calculateYieldTotal(msg.sender);
      yieldBalance[msg.sender] = yieldBalance[msg.sender] + transferYield;
    }

    ethToken.transferFrom(msg.sender, address(this), _amount);
    stakeBalance[msg.sender] = stakeBalance[msg.sender] + _amount;
    totalTokensStaked = totalTokensStaked + _amount;
    stakeStart[msg.sender] = block.number;
    isStaking[msg.sender] = true;
  }

  //2. UnStake tokens
  function unstake(uint256 _unStakeamount) public {
    uint256 balance = stakeBalance[msg.sender];
    require(balance > 0, 'Amount cannont be 0');
    require(_unStakeamount <= balance, 'Ammount cannot be more than balance');

    uint256 transferYield = calculateYieldTotal(msg.sender);
    yieldBalance[msg.sender] = yieldBalance[msg.sender] + transferYield;
    ethToken.transfer(msg.sender, _unStakeamount);
    stakeBalance[msg.sender] = balance - _unStakeamount;
    totalTokensStaked = totalTokensStaked - _unStakeamount;
    stakeStart[msg.sender] = block.number;
    if (stakeBalance[msg.sender] == 0) {
      isStaking[msg.sender] = false;
    }
  }

  // 3. Calc Yield Time
  function calculateYieldTime(address _sender) public view returns (uint256) {
    uint256 stakeEnd = block.number;
    uint256 totalStakedTime = stakeEnd - stakeStart[_sender];
    return totalStakedTime;
  }

  // 4. Calculate Yield
  function calculateYieldTotal(address _sender) public view returns (uint256) {
    uint256 stakedTime = calculateYieldTime(_sender);
    uint256 yieldPerBlock = 1;
    uint256 rateTime = stakedTime * yieldPerBlock;
    uint256 yield = stakeBalance[_sender] * rateTime;
    return yield;
  }

  // 5. WithDraw Yield
  function withdrawYield() public {
    uint256 totalYield = calculateYieldTotal(msg.sender) + yieldBalance[msg.sender];
    require(totalYield > 0, 'Nothing to withdraw');
    yieldBalance[msg.sender] = 0;
    stakeStart[msg.sender] = block.number;
    rewToken.transfer(msg.sender, totalYield);
  }

  function unstakeAll() public {
    uint256 balance = stakeBalance[msg.sender];
    uint256 totalYield = calculateYieldTotal(msg.sender) + yieldBalance[msg.sender];
    require(balance > 0, 'Balance is 0');
    require(totalYield > 0, 'Yield is 0');
    stakeBalance[msg.sender] = 0;
    yieldBalance[msg.sender] = 0;
    stakeStart[msg.sender] = block.number;
    totalTokensStaked = totalTokensStaked - balance;
    rewToken.transfer(msg.sender, totalYield);
    ethToken.transfer(msg.sender, balance);
    if (stakeBalance[msg.sender] == 0) {
      isStaking[msg.sender] = false;
    }
  }

  function claimMockEth() public {
    uint256 ethClaim = 10000000000000000000;
    ethToken.transfer(msg.sender, ethClaim);
  }
}