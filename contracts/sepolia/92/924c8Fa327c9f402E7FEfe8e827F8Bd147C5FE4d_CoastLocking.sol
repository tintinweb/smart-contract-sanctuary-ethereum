// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoastLocking {
  
  address public CONTRACT_ADDRESS = address(this);
  address manager = 0xc3F9beD906C1FfCD35fE6332be251544C94B070f;

  mapping (address => mapping (address => uint256)) public locked;
  mapping (address => uint256) public penalties;

  event Lock(address token, address locker, uint amount);
  event Unlock(address token, address unlocker, uint amount);


  modifier manager_function(){
    require(msg.sender==manager,"Only the manager can call this function");
    _;}
  
  
  function lock(address tokenAddress, uint amount) public {

    require(IERC20(tokenAddress).allowance(msg.sender,CONTRACT_ADDRESS) >= amount, "You need to approve the contract to transfer your tokens");
    
    IERC20(tokenAddress).transferFrom(msg.sender,CONTRACT_ADDRESS, amount);

    locked[msg.sender][tokenAddress] += amount;

    emit Lock(tokenAddress, msg.sender, amount);

  }


  function unlockSome(address tokenAddress, uint amount) public {

    require(locked[msg.sender][tokenAddress] >= amount, "You don't have that many tokens locked");

    locked[msg.sender][tokenAddress] -= amount;
    penalties[tokenAddress] += (5 * amount) / 100;
    
    IERC20(tokenAddress).transfer(msg.sender, (95 * amount) / 100);

    emit Unlock(tokenAddress, msg.sender, amount);

  }

  
  function unlockAll(address tokenAddress) public {

    require(locked[msg.sender][tokenAddress] > 0, "You don't have any tokens locked");
    
    uint amount = locked[msg.sender][tokenAddress];
    locked[msg.sender][tokenAddress] = 0;
    penalties[tokenAddress] += (5 * amount) / 100;
    
    IERC20(tokenAddress).transfer(msg.sender, (95 * amount) / 100);

    emit Unlock(tokenAddress, msg.sender, amount);

  }


  function withdrawToken(address tokenAddress) manager_function public {

    uint amount = penalties[tokenAddress];
    
    IERC20(tokenAddress).transfer(manager,amount);

    penalties[tokenAddress] = 0;

  }

  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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