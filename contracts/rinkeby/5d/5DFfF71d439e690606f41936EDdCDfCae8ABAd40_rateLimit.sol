// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
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
}

contract rateLimit {
mapping(address=>uint256) public rate; //tracks amount sent for the last timeLimit time
mapping(address=>uint256) public timestamp; //tracks most recent send
uint256 public timeLimit; //how long in seconds to limit within, recommend 1h = 3600
uint16 public rateLimit; //the basis points (00.x%) to allow as the max sent within the last timeLimit time

function ltransfer(uint256 amount,address addrs, address token) public{
    lTransfer(addrs, amount, token);
}

fallback() payable external{}

function updateLimits(uint16 _rateLimit, uint256 _timeLimit) internal{
rateLimit = _rateLimit;
timeLimit = _timeLimit; 
}

function lTransfer(address to, uint256 amount, address token) internal{
  if (address(token) == address(0)){
    rate[token] -= address(this).balance * rateLimit / (timeLimit / (block.timestamp - timestamp[token])) / 1000;
    rate[token] += amount;
    require(rate[token] <= rateLimit * address(this).balance / 1000);
    timestamp[token] = block.timestamp;
    payable(to).transfer(amount);}
  else{
    rate[token] -= IERC20(token).balanceOf(address(this)) * rateLimit / (timeLimit / (block.timestamp - timestamp[token])) / 1000;
    rate[token] += amount;
    require(rate[token] <= rateLimit * IERC20(token).balanceOf(address(this)) / 1000);
    timestamp[token] = block.timestamp;
    IERC20(token).transfer(to,amount);
  }
}
}