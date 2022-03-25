/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract Staking{

  address public stakingToken;
  address public rewardToken;

  uint public rewardTime = 600000;
  uint public freezeTime = 1200000;
  uint public rewardShare = 20;

  function setRewardTime(uint _rewardTime) external {
    rewardTime = _rewardTime;
  }

  function setFreezeTime(uint _freezeTime) external {
    freezeTime = _freezeTime;
  }

  function setRewardShare(uint _rewardShare) external {
    rewardShare = _rewardShare;
  }

  struct Stakeholder{
    uint256 stake;
    uint256 timestamp;
    uint256 reward;
    bool exist;
  }

  event Stake(address indexed stakeholder, uint amount, uint timestamp);
  event Unstake(address indexed stakeholder, uint amount, uint remain);
  event Claim(address indexed stakeholder, uint amount, uint remain);

  mapping (address=>Stakeholder) stakeholders;

  constructor(address _stakingToken, address _rewardToken) public {
    stakingToken = _stakingToken;
    rewardToken = _rewardToken;
  }

  function stake(uint _amount) external {
    IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);

    if(!stakeholders[msg.sender].exist){
      stakeholders[msg.sender].exist = true;
    }

    stakeholders[msg.sender].timestamp = block.timestamp;
    stakeholders[msg.sender].stake += _amount;
    stakeholders[msg.sender].reward += (_amount/100)*rewardShare;
    emit Stake(msg.sender, _amount, block.timestamp);
  }

  function getStakeholder(address _stakeholder) view external returns(Stakeholder memory){
    Stakeholder memory stakeholder = stakeholders[_stakeholder];
    return stakeholder;
  }

  function _claim(Stakeholder storage _stakeholder, uint _amount) internal {
    require(block.timestamp - _stakeholder.timestamp >= rewardTime && _stakeholder.exist, "U have no reward tokens yet!");
    IERC20(rewardToken).transfer(msg.sender, _amount);
    _stakeholder.reward -= _amount;
    emit Claim(msg.sender, _amount, _stakeholder.reward);
  }

  function claimAll() external {
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    uint _amount = stakeholder.reward;
    _claim(stakeholder, _amount);
  }

  function claim(uint _amount) external {
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    require(stakeholder.reward >= _amount, "You haven't such a big value of reward tokens");
    _claim(stakeholder, _amount);
  }

  function unstake(uint _amount) external {
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    require(stakeholder.exist, "You have no stake tokens.");
    _unstake(stakeholder, _amount);
  }

  function unstakeAll() external {
    Stakeholder storage stakeholder = stakeholders[msg.sender];
    require(stakeholder.exist, "You have no stake tokens.");
    _unstake(stakeholder, stakeholder.stake);
  }

  function _unstake(Stakeholder storage _stakeholder, uint _amount) internal {
    require(_stakeholder.stake >= _amount, "You have no such a big amount of stake tokens.");
    require(block.timestamp - _stakeholder.timestamp >= freezeTime, "U cant get back your reward tokens yet!");
    IERC20(stakingToken).transfer(msg.sender, _amount);
    _stakeholder.stake -= _amount;
    emit Unstake(msg.sender, _amount, _stakeholder.stake);
  }

}
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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