/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: BSL 1.1
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.17;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: contracts/SubscriptionToken.sol

contract SubscriptionToken is IERC20, IERC20Metadata, Context {
  // Custom error can save deployment and run time cost: https://blog.soliditylang.org/2021/04/21/custom-errors/.
  error UNAUTHORIZED(address caller);
  error ZERO_ADDRESS();
  error EXCEED_BALANCE();
  error REQUIRE_ERC777_RECIPIENT(address target);

  // name() and symbol() methods are implicitly defined, this save contract deployment cost.
  string public name;
  string public symbol;
  address public immutable owner;

  constructor(string memory name_, string memory symbol_) {
    owner = _msgSender();
    name = name_;
    symbol = symbol_;
  }

  function decimals() public pure override returns (uint8) {
    return 0;
  }

  event Withdrawal(uint256 indexed, address indexed);

  function withdraw() external {
    if (_msgSender() != owner) {
      revert UNAUTHORIZED(_msgSender());
    }

    uint256 amount = address(this).balance;
    payable(owner).transfer(amount);

    emit Withdrawal(amount, owner);
  }

  ////////////////////////////////////////////////////////////////////////////
  /*                            Dynamic balance                             */
  mapping(address => uint256) internal timeValue;
  uint256 private constant _tokenToTimeQuantum = 86400; // Number of seconds each token corresponding to = 24 hours

  /**
   * @dev Returns the amount of tokens owned by an account (`subscriber`).
   *
   * number of balacne is ceiling function of [`timeValue[subscriber]` - `current time`)
   */
  function balanceOf(address subscriber) public view override returns (uint256) {
    uint256 timeCeiling = timeValue[subscriber] + _tokenToTimeQuantum - 1;
    if (block.timestamp > timeCeiling) {
      return 0; // check for overflow
    } else {
      return (timeCeiling - block.timestamp) / _tokenToTimeQuantum; // could return 0
    }
  }

  uint256 public totalMinted;

  /**
   * @dev Returns the amount of tokens minted.
   *
   * Calculate the total supply in circulation would make every transfer/mint event cost additional 20k+ gas.
   * And this O(N) function could be very slow once the number of user grows too big.
   */
  function totalSupply() public view override returns (uint256) {
    return totalMinted;
  }

  ////////////////////////////////////////////////////////////////////////////
  /*                              IERC20 Methods                            */

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
   */
  function transferFrom(
    address holder,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(holder, spender, amount);
    _transfer(holder, recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Emits a {Sent} event.
   */
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal {
    if (from == address(0) || to == address(0)) {
      revert ZERO_ADDRESS();
    }
    _beforeTokenTransfer(from, to, amount);

    _reCalculateTimeValue(from, to, amount);

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  function _reCalculateTimeValue(
    address from,
    address to,
    uint256 amount
  ) private {
    _beforeTokenTransfer(from, to, amount);

    uint256 fromTimeValue = timeValue[from];
    uint256 tokenToTimeQuantum = _tokenToTimeQuantum;

    // value = 2, time = 2.2 => able to move (amount <= 1)
    if (fromTimeValue + tokenToTimeQuantum <= block.timestamp + amount * tokenToTimeQuantum) {
      revert EXCEED_BALANCE();
    }

    unchecked {
      timeValue[from] = fromTimeValue - amount * tokenToTimeQuantum;

      // renew subscription if necessary
      if (block.timestamp > timeValue[to]) {
        timeValue[to] = block.timestamp - (block.timestamp % tokenToTimeQuantum);
      }
      timeValue[to] += amount * tokenToTimeQuantum;
    }
  }

  // Subscription price.
  uint256 public dailySubscriptionPrice = 0 ether;

  error INSUFFICIENT_AMOUNT(uint256 sent, uint256 minimumExpected);

  // error EOA_ONLY();

  function mint(uint256 amount) external payable {
    // if (_msgSender() != tx.origin) revert EOA_ONLY();

    uint256 minimumExpectedAmount = amount * dailySubscriptionPrice;
    uint256 sendValue = msg.value;
    if (sendValue < minimumExpectedAmount) revert INSUFFICIENT_AMOUNT(sendValue, minimumExpectedAmount);

    _mint(_msgSender(), amount);

    // Refund the remaining amount if any
    if (msg.value > minimumExpectedAmount) {
      payable(_msgSender()).transfer(msg.value - minimumExpectedAmount);
    }
  }

  /**
   * @dev Mint tokens. Emits a {Transfer} event with `from` set to the zero address.
   * @param account address token holder address
   * @param amount uint256 amount of tokens to mint
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    if (account == address(0)) {
      revert ZERO_ADDRESS();
    }

    _beforeTokenTransfer(address(0), account, amount);

    uint256 tokenToTimeQuantum = _tokenToTimeQuantum;

    unchecked {
      // Renew subscription if necessary
      if (block.timestamp > timeValue[account]) {
        timeValue[account] = block.timestamp - (block.timestamp % tokenToTimeQuantum);
      }

      timeValue[account] += amount * tokenToTimeQuantum;
      totalMinted += amount;
    }

    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function burn(uint256 amount) public {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Burn tokens
   * @param from address token holder address
   * @param amount uint256 amount of tokens to burn
   */
  function _burn(address from, uint256 amount) internal {
    if (from == address(0)) {
      revert ZERO_ADDRESS();
    }

    _beforeTokenTransfer(from, address(0), amount);

    uint256 fromTimeValue = timeValue[from];
    uint256 tokenToTimeQuantum = _tokenToTimeQuantum;

    if (fromTimeValue + tokenToTimeQuantum <= block.timestamp + amount * tokenToTimeQuantum) {
      revert EXCEED_BALANCE();
    }

    unchecked {
      timeValue[from] = fromTimeValue - amount * tokenToTimeQuantum;
    }

    emit Transfer(from, address(0), amount);

    _afterTokenTransfer(from, address(0), amount);
  }

  ////////////////////////////////////////////////////////////////////////////
  /*                            ERC20-allowances                            */
  mapping(address => mapping(address => uint256)) private _allowances;

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address holder, address spender) public view override returns (uint256) {
    return _allowances[holder][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    address holder = _msgSender();
    _approve(holder, spender, value);
    return true;
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address holder,
    address spender,
    uint256 value
  ) internal {
    if (holder == address(0) || spender == address(0)) {
      revert ZERO_ADDRESS();
    }

    _allowances[holder][spender] = value;
    emit Approval(holder, spender, value);
  }

  error EXCEED_ALLOWANCE(address spender, address owner, uint256 actualAllowance);

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {IERC20-Approval} event.
   */
  function _spendAllowance(
    address owner_,
    address spender,
    uint256 amount
  ) internal {
    uint256 currentAllowance = allowance(owner_, spender);

    // Only update if there is no overflow occurs.
    if (currentAllowance < type(uint256).max / _tokenToTimeQuantum) {
      if (currentAllowance > amount) {
        revert EXCEED_ALLOWANCE(owner, spender, currentAllowance);
      }
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  ////////////////////////////////////////////////////////////////////////////
  /*                          Token transfer hooks                          */

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}