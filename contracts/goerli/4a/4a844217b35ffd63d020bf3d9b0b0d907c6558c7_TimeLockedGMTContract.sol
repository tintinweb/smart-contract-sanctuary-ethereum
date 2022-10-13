// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract TimeLockedGMTContract is Ownable {

  uint256 private _totalSupply;
  uint256 private _lockedSupply;

  IERC20 private _token = IERC20(0xf08934FB6F94AD0801D76Ab2BEF0cFF6E97ebcA7);

  mapping (address => uint256) private _balances;
  mapping (address => uint256[]) private _timestamps;
  mapping (address => uint256[]) private _purchases;

  event ExtractTokens(address indexed to, uint256 value);
  event PutTokens(address indexed owner, uint256 value);

  function putTokensToTimeLock(address account, uint256 amount, uint256 timestamp) public virtual onlyOwner {
    require(_lockedSupply + amount <= totalSupply(), "Not enought tokens on TimeLockedGMTContract");
    _balances[account] += amount;
    _timestamps[account].push(timestamp);
    _purchases[account].push(amount);
    _lockedSupply += amount;
    emit PutTokens(account, amount);
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  function timestampsOf(address account) public view virtual returns (uint256[] memory) {
    return _timestamps[account];
  }
  function purchasesOf(address account) public view virtual returns (uint256[] memory) {
    return _purchases[account];
  }

  function extractTokens() public virtual returns (uint256) {
    uint256 valueToExtract = _extractTokensByAddress(msg.sender);
    return valueToExtract;
  }

  function extractTokensByAddress(address account) public virtual onlyOwner returns (uint256) {
    uint256 valueToExtract = _extractTokensByAddress(account);
    return valueToExtract;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _token.balanceOf(address(this));
  }
  function lockedSupply() public view virtual returns (uint256) {
    return _lockedSupply;
  }

  function _extractTokensByAddress(address account) internal virtual returns (uint256) {
    require(_balances[account] > 0, "Balance equals or less then zero");
    uint256 valueToExtract = 0;
    for (uint256 i = 0; i < _timestamps[account].length; i++) {
      if (_timestamps[account][i] < block.timestamp) {
        valueToExtract += _purchases[account][i];
        _balances[account] -= _purchases[account][i];
        _lockedSupply -= _purchases[account][i];
        _purchases[account][i] = 0;
      }
    }
    require(valueToExtract > 0, "Value to extract equals or less then zero");
    _token.transfer(account, valueToExtract);
    emit ExtractTokens(account, valueToExtract);
    return valueToExtract;
  }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}