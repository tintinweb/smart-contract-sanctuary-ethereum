// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./MultiToken.sol";

contract WrappedERC20 is IERC20, IERC20Metadata {
  MultiToken private immutable _multiToken;
  string private _name;
  string private _symbol;

  constructor(
    MultiToken multiToken_,
    string memory name_,
    string memory symbol_
  ) {
    _multiToken = multiToken_;
    _name = name_;
    _symbol = symbol_;
  }

  modifier onlyMultiToken() {
    require(msg.sender == address(_multiToken), "Sender is not a multitoken");
    _;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function totalSupply() public view override returns (uint256) {
    return _multiToken.totalSupply(address(this));
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _multiToken.balanceOf(address(this), account);
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    _multiToken.transfer(address(this), msg.sender, to, amount);
    emit Transfer(msg.sender, to, amount);
    return true;
  }

  function emitTransfer(
    address from,
    address to,
    uint256 amount
  ) external onlyMultiToken {
    emit Transfer(from, to, amount);
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _multiToken.allowance(address(this), owner, spender);
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _multiToken.approve(address(this), msg.sender, spender, amount);
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function emitApprove(
    address owner,
    address spender,
    uint256 amount
  ) external onlyMultiToken {
    emit Approval(owner, spender, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    _multiToken.transferFrom(address(this), msg.sender, from, to, amount);
    emit Transfer(from, to, amount);
    return true;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./WrappedERC20.sol";

contract MultiToken is Ownable {
  event Transfer(address indexed token, address indexed from, address indexed to, uint256 value);

  event Approval(address indexed token, address indexed owner, address indexed spender, uint256 value);

  event TokenAdded(address indexed token);

  mapping(address => mapping(address => uint256)) private _balances;
  mapping(address => mapping(address => mapping(address => uint256))) private _allowances;
  mapping(address => uint256) private _totalSupply;
  mapping(address => bool) private _tokens;

  modifier onlyToken(address token) {
    require(_tokens[token], "MultiToken: Not a valid token");
    _;
  }

  function totalSupply(address token) public view returns (uint256) {
    return _totalSupply[token];
  }

  function balanceOf(address token, address account) public view returns (uint256) {
    return _balances[token][account];
  }

  function allowance(
    address token,
    address owner,
    address spender
  ) public view returns (uint256) {
    return _allowances[token][owner][spender];
  }

  function addToken(address token) public onlyOwner {
    _tokens[token] = true;
    emit TokenAdded(token);
  }

  function transfer(
    address token,
    address owner,
    address to,
    uint256 amount
  ) public onlyToken(token) returns (bool) {
    _transfer(token, owner, to, amount);
    return true;
  }

  function approve(
    address token,
    address sender,
    address spender,
    uint256 amount
  ) public onlyToken(token) returns (bool) {
    _approve(token, sender, spender, amount);
    return true;
  }

  function transferFrom(
    address token,
    address spender,
    address from,
    address to,
    uint256 amount
  ) public onlyToken(token) returns (bool) {
    _spendAllowance(token, from, spender, amount);
    _transfer(token, from, to, amount);
    return true;
  }

  function _mint(
    address token,
    address account,
    uint256 amount
  ) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply[token] += amount;
    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      _balances[token][account] += amount;
    }
    emit Transfer(token, address(0), account, amount);
  }

  function _burn(
    address token,
    address account,
    uint256 amount
  ) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = _balances[token][account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[token][account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply[token] -= amount;
    }

    emit Transfer(token, account, address(0), amount);
  }

  function _transfer(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    uint256 fromBalance = _balances[token][from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[token][from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      _balances[token][to] += amount;
    }

    emit Transfer(token, from, to, amount);
    // Emit Transfer event on the token as well
    WrappedERC20(token).emitTransfer(from, to, amount);
  }

  function _approve(
    address token,
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[token][owner][spender] = amount;
    emit Approval(token, owner, spender, amount);
    // Emit Approval event on the token as well
    WrappedERC20(token).emitApprove(owner, spender, amount);
  }

  function _spendAllowance(
    address token,
    address owner,
    address spender,
    uint256 amount
  ) internal {
    uint256 currentAllowance = allowance(token, owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(token, owner, spender, currentAllowance - amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}