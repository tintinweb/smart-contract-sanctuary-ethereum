// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "./openzeppelin/ERC20.sol";
import { IERC20 } from "./openzeppelin/IERC20.sol";
import "./openzeppelin/Ownable.sol";
import "./openzeppelin/IOwnable.sol";
import "./AggregatorV3Interface.sol";
import "./openzeppelin/SafeERC20.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
contract BondRedeemer is Ownable {
  //Incorrect boilerplate addresses
  using SafeERC20 for IERC20;
  address public constant BDAMM = 0xc4F125F56e10980A26093c5ad22AEa1FA93cfd57;
  address public constant DAMM = 0xD9aA9fD99c2C085ce82A7f084A451C2460FCd73e;
  address public constant CHAINLINK_DAMM = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c; //using $LINK Oracle for testing
  address public admin;
  bool public redeemAllowed = true;

  mapping(address => bool) public tokensPermitted;

  mapping(address => uint256) public discountRates;

  mapping(address => address) public oracles;

  event Redemption(address redeemer, uint256 quantityOfdAMM, uint256 bdAMMRedeemed, uint256 usdcQuantity);
  //event TokenPermitted(address token, uint256 discountRates, address oracle);
  event TokenPermitted(address token, uint256 discountRates, address oracle);

  event NewAdmin(address newAdminAdd);

  constructor() {
    admin = msg.sender;
  }

  function dAMMBalance() public view returns (uint256) {
    uint256 balance = IERC20(DAMM).balanceOf(address(this));
    return balance;
  }

  function getLatestPrice(address oracleAdd) public view returns (int256) {
    AggregatorV3Interface oraclePriceFeed = AggregatorV3Interface(oracleAdd);
    (
      ,
      /*uint80 roundID*/
      int256 price, /*uint startedAt*/
      ,
      ,

    ) = /*uint timeStamp*/
      /*uint80 answeredInRound*/
      oraclePriceFeed.latestRoundData();
    return price;
  }

  function getLatestDecimals(address oracleAdd) public view returns (uint8) {
    AggregatorV3Interface oraclePriceFeed = AggregatorV3Interface(oracleAdd);
    uint8 decimals = oraclePriceFeed.decimals();
    return decimals;
  }

  function changeAdmin(address newAdmin) public onlyOwner {
    require(msg.sender == admin);
    transferOwnership(newAdmin);
    emit NewAdmin(newAdmin);
  }

  // release trapped funds
  function withdrawTokens(address token) public onlyOwner {
    require(msg.sender == admin);
    if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
      payable(IOwnable(admin).owner()).transfer(address(this).balance);
    } else {
      uint256 balance = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(admin, balance);
    }
  }

  //Set allowable tokens
  //Discount rate in BPS
  //This is the real line, I took out the oracle for testing

  function permitToken(
    address token,
    uint256 discountRate,
    address oracle
  ) public onlyOwner {
    require(msg.sender == admin); //double bagging
    tokensPermitted[token] = true;
    oracles[token] = oracle;
    discountRates[token] = discountRate;
    emit TokenPermitted(token, discountRate, oracle);
  }

  //Allows the delisting of a bond redemption token
  function disableToken(address token) public onlyOwner returns (bool) {
    require(msg.sender == admin);
    require(tokensPermitted[token] == true, "Token is not listed");
    tokensPermitted[token] = false;
    return tokensPermitted[token];
  }

  /**
   * @notice BONDING REDEMPTIONS
   * @notice Users can redeem their liquidity bonding tokens for dAMM at a discount to market price
   * @notice
   * @param rawbdAMMToRedeem is the quantity of discounted dAMM the user desires to redeem for dAMM
   * @param paymentToken is the specified redemption token
   */
  function BondRedemption(address paymentToken, uint256 rawbdAMMToRedeem) public {
    require(redeemAllowed == true, "Liquidity Bonds temporarily disabled.");
    require(tokensPermitted[paymentToken] == true, "Token is not permitted for redemption");

    uint256 currentBal = dAMMBalance();
    //current token discount rate
    uint256 inverseDiscountRateInBPS = 10000 - discountRates[paymentToken];

    //Get latest decimals and token scale
    uint256 dAMMDecimalScaleUp = 1**(18 - uint256(getLatestDecimals(CHAINLINK_DAMM)));
    uint256 paymentTokenDecimalScaleUp = 1**(18 - uint256(getLatestDecimals(oracles[paymentToken])));

    //Converting chainlink data to scale
    uint256 dAMMPriceInUSD = uint256(getLatestPrice(oracles[CHAINLINK_DAMM])) * dAMMDecimalScaleUp;
    uint256 paymentTokenPrice = uint256(getLatestPrice(oracles[paymentToken])) * paymentTokenDecimalScaleUp;

    //Calculating bdAMM and paymentToken needed, seperated as two variables for clarity
    uint256 dAMMToReceive = rawbdAMMToRedeem * 1e18;
    uint256 rawbdAMMConverted = rawbdAMMToRedeem * 1e18;

    uint256 dollarsOfPaymentTokenOwed = (dAMMPriceInUSD * inverseDiscountRateInBPS) / 10000;
    uint256 paymentTokenOwed = dollarsOfPaymentTokenOwed / paymentTokenPrice;

    //Some extra safety checks
    require(IERC20(paymentToken).balanceOf(msg.sender) >= paymentTokenOwed);
    require((currentBal >= dAMMToReceive));

    //msg.sender sends bdAMM to admin, and USDC
    //for testing removing BDAMM as the ERC20 and using a test ERC20
    SafeERC20.safeTransferFrom(IERC20(BDAMM), msg.sender, admin, rawbdAMMConverted);
    SafeERC20.safeTransferFrom(IERC20(paymentToken), msg.sender, admin, paymentTokenOwed);
    //No reversion because of SafeTransfer above. If either fails minting doesn't occur.
    //Transfer dAMM to the redeemer
    SafeERC20.safeTransfer(IERC20(DAMM), msg.sender, dAMMToReceive);
    emit Redemption(msg.sender, dAMMToReceive, rawbdAMMToRedeem, paymentTokenOwed);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 totalSupply_,
    address account
  ) {
    _name = name_;
    _symbol = symbol_;
    _totalSupply = totalSupply_;
    _balances[account] = uint256(totalSupply_);
    emit Transfer(address(0), account, totalSupply_);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
   * `transferFrom`. This is semantically equivalent to an infinite approval.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * NOTE: Does not update the allowance if the current allowance
   * is the maximum `uint256`.
   *
   * Requirements:
   *
   * - `from` and `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   * - the caller must have allowance for ``from``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(owner, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `from` to `to`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
    }
    _balances[to] += amount;

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
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
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {Approval} event.
   */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

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
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
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
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
  constructor() {
    _transferOwnership(_msgSender());
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IOwnable {
  function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
  /**
   * @dev See {ERC20-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "ERC20Pausable: token transfer while paused");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    _requireNotPaused();
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    _requirePaused();
    _;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Throws if the contract is paused.
   */
  function _requireNotPaused() internal view virtual {
    require(!paused(), "Pausable: paused");
  }

  /**
   * @dev Throws if the contract is not paused.
   */
  function _requirePaused() internal view virtual {
    require(paused(), "Pausable: not paused");
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `_msgSender()` is missing `role`.
   * Overriding this function changes the behavior of the {onlyRole} modifier.
   *
   * Format of the revert message is described in {_checkRole}.
   *
   * _Available since v4.6._
   */
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked("AccessControl: account ", Strings.toHexString(uint160(account), 20), " is missing role ", Strings.toHexString(uint256(role), 32))
        )
      );
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleGranted} event.
   */
  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * May emit a {RoleGranted} event.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   *
   * NOTE: This function is deprecated in favor of {_grantRole}.
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleGranted} event.
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  /**
   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
   */
  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   * Role bearers are not sorted in any particular way, and their ordering may
   * change at any point.
   *
   * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
   * you perform all queries on the same block. See the following
   * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
   * for more information.
   */
  function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
    return _roleMembers[role].at(index);
  }

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
    return _roleMembers[role].length();
  }

  /**
   * @dev Overload {_grantRole} to track enumerable memberships
   */
  function _grantRole(bytes32 role, address account) internal virtual override {
    super._grantRole(role, account);
    _roleMembers[role].add(account);
  }

  /**
   * @dev Overload {_revokeRole} to track enumerable memberships
   */
  function _revokeRole(bytes32 role, address account) internal virtual override {
    super._revokeRole(role, account);
    _roleMembers[role].remove(account);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Set type with
  // bytes32 values.
  // The Set implementation uses private functions, and user-facing
  // implementations (such as AddressSet) are just wrappers around the
  // underlying Set.
  // This means that we can only create new EnumerableSets for types that fit
  // in bytes32.

  struct Set {
    // Storage of set values
    bytes32[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      if (lastIndex != toDeleteIndex) {
        bytes32 lastValue = set._values[lastIndex];

        // Move the last value to the index where the value to delete is
        set._values[toDeleteIndex] = lastValue;
        // Update the index for the moved value
        set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
      }

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    return set._values[index];
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function _values(Set storage set) private view returns (bytes32[] memory) {
    return set._values;
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    return _values(set._inner);
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(AddressSet storage set) internal view returns (address[] memory) {
    bytes32[] memory store = _values(set._inner);
    address[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }

  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(UintSet storage set) internal view returns (uint256[] memory) {
    bytes32[] memory store = _values(set._inner);
    uint256[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "./openzeppelin/ERC20.sol";
import "./openzeppelin/ERC20Burnable.sol";
import "./openzeppelin/ERC20Pausable.sol";
import "./openzeppelin/AccessControlEnumerable.sol";
import "./openzeppelin/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract USDC is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  uint256 private _decimals = 6;

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
   * account that deploys the contract.
   *
   * See {ERC20-constructor}.
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 decimals_
  ) ERC20(name, symbol, 0, _msgSender()) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    _decimals = decimals_;
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) public virtual {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
    _mint(to, amount);
  }

  // Hart: Override decimals from ERC20.sol to conform to USDC decimals
  function decimals() public view override returns (uint8) {
    return uint8(_decimals);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
    _spendAllowance(account, _msgSender(), amount);
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./openzeppelin/Ownable.sol";
import "./PriceOracle.sol";
import "./CErc20.sol";

contract SimplePriceOracle is PriceOracle, Ownable {
  mapping(address => uint) prices;
  event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

  function setDirectPrices(address[] calldata tokens, uint256[] calldata pricesToSet) external onlyOwner {
    require(tokens.length == pricesToSet.length, "tokens and prices must have the same length");
    for (uint i = 0; i < tokens.length; i ++) {
      setDirectPrice(tokens[i], pricesToSet[i]);
    }
  }

  function _getUnderlyingAddress(CToken cToken) private view returns (address) {
    address asset;
    if (compareStrings(cToken.symbol(), "dETH")) {
      asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    } else {
      asset = address(CErc20(address(cToken)).underlying());
    }
    return asset;
  }

  function getUnderlyingPrice(CToken cToken) public override view returns (uint) {
    return prices[_getUnderlyingAddress(cToken)];
  }

  function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public onlyOwner {
    address asset = _getUnderlyingAddress(cToken);
    emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
    prices[asset] = underlyingPriceMantissa;
  }

  function setDirectPrice(address asset, uint price) public onlyOwner {
    emit PricePosted(asset, prices[asset], price, price);
    prices[asset] = price;
  }

  // v1 price oracle interface for use as backing of proxy
  function assetPrices(address asset) external view returns (uint) {
    return prices[asset];
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";

abstract contract PriceOracle {
  /// @notice Indicator that this is a PriceOracle contract (for inspection)
  bool public constant isPriceOracle = true;

  /**
   * @notice Get the underlying price of a cToken asset
   * @param cToken The cToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   *  Zero means the price is unavailable.
   */
  function getUnderlyingPrice(CToken cToken) external view virtual returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";

interface CompLike {
  function delegate(address delegatee) external;
}

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
contract CErc20 is CToken, CErc20Interface {
  /**
   * @notice Initialize the new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   */
  function initialize(
    address underlying_,
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) public {
    // CToken initialize does the bulk of the work
    super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

    // Set underlying and sanity check it
    underlying = underlying_;
    EIP20Interface(underlying).totalSupply();
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (uint256) {
    mintInternal(mintAmount);
    return NO_ERROR;
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (uint256) {
    redeemInternal(redeemTokens);
    return NO_ERROR;
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external override returns (uint256) {
    redeemUnderlyingInternal(redeemAmount);
    return NO_ERROR;
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external override returns (uint256) {
    borrowInternal(borrowAmount);
    return NO_ERROR;
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay, or -1 for the full outstanding amount
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrow(uint256 repayAmount) external override returns (uint256) {
    repayBorrowInternal(repayAmount);
    return NO_ERROR;
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay, or -1 for the full outstanding amount
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external override returns (uint256) {
    repayBorrowBehalfInternal(borrower, repayAmount);
    return NO_ERROR;
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external override returns (uint256) {
    liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
    return NO_ERROR;
  }

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
   * @param token The address of the ERC-20 token to sweep
   */
  function sweepToken(EIP20NonStandardInterface token) external override {
    require(msg.sender == admin, "CErc20::sweepToken: only admin can sweep tokens");
    require(address(token) != underlying, "CErc20::sweepToken: can not sweep underlying token");
    uint256 balance = token.balanceOf(address(this));
    token.transfer(admin, balance);
  }

  /**
   * @notice The sender adds to reserves.
   * @param addAmount The amount fo underlying token to add as reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves(uint256 addAmount) external override returns (uint256) {
    return _addReservesInternal(addAmount);
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view virtual override returns (uint256) {
    EIP20Interface token = EIP20Interface(underlying);
    return token.balanceOf(address(this));
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount) internal virtual override returns (uint256) {
    // Read from storage once
    address underlying_ = underlying;
    EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying_);
    uint256 balanceBefore = EIP20Interface(underlying_).balanceOf(address(this));
    token.transferFrom(from, address(this), amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of override external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, "TOKEN_TRANSFER_IN_FAILED");

    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = EIP20Interface(underlying_).balanceOf(address(this));
    return balanceAfter - balanceBefore; // underflow already checked above, just subtract
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual override {
    EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
    token.transfer(to, amount);

    bool success;
    assembly {
      switch returndatasize()
      case 0 {
        // This is a non-standard ERC-20
        success := not(0) // set success to true
      }
      case 32 {
        // This is a compliant ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0) // Set `success = returndata` of override external call
      }
      default {
        // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    require(success, "TOKEN_TRANSFER_OUT_FAILED");
  }

  /**
   * @notice Admin call to delegate the votes of the COMP-like underlying
   * @param compLikeDelegatee The address to delegate votes to
   * @dev CTokens whose underlying are not CompLike should revert here
   */
  function _delegateCompLikeTo(address compLikeDelegatee) external {
    require(msg.sender == admin, "only the admin may set the comp-like delegate");
    CompLike(underlying).delegate(compLikeDelegatee);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./ErrorReporter.sol";
import "./EIP20Interface.sol";
import "./InterestRateModel.sol";
import "./ExponentialNoError.sol";

/**
 * @title Compound's CToken Contract
 * @notice Abstract base for CTokens
 * @author Compound
 */
abstract contract CToken is CTokenInterface, ExponentialNoError, TokenErrorReporter {
  /**
   * @notice Initialize the money market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ EIP-20 name of this token
   * @param symbol_ EIP-20 symbol of this token
   * @param decimals_ EIP-20 decimal precision of this token
   */
  function initialize(
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) public {
    require(msg.sender == admin, "only admin may initialize the market");
    require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

    // Set initial exchange rate
    initialExchangeRateMantissa = initialExchangeRateMantissa_;
    require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

    // Set the comptroller
    uint256 err = _setComptroller(comptroller_);
    require(err == NO_ERROR, "setting comptroller failed");

    // Initialize block number and borrow index (block number mocks depend on comptroller being set)
    accrualBlockNumber = getBlockNumber();
    borrowIndex = mantissaOne;

    // Set the interest rate model (depends on block number / borrow index)
    err = _setInterestRateModelFresh(interestRateModel_);
    require(err == NO_ERROR, "setting interest rate model failed");

    name = name_;
    symbol = symbol_;
    decimals = decimals_;

    // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
    _notEntered = true;
  }

  /**
   * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
   * @dev Called by both `transfer` and `transferFrom` internally
   * @param spender The address of the account performing the transfer
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param tokens The number of tokens to transfer
   * @return 0 if the transfer succeeded, else revert
   */
  function transferTokens(
    address spender,
    address src,
    address dst,
    uint256 tokens
  ) internal returns (uint256) {
    /* Fail if transfer not allowed */
    uint256 allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
    if (allowed != 0 && spender != admin) {
      revert TransferComptrollerRejection(allowed);
    }

    /* Do not allow self-transfers */
    if (src == dst) {
      revert TransferNotAllowed();
    }

    /* Get the allowance, infinite for the account owner */
    uint256 startingAllowance = 0;
    if (spender == src || spender == admin) {
      startingAllowance = type(uint256).max;
    } else {
      startingAllowance = transferAllowances[src][spender];
    }

    /* Do the calculations, checking for {under,over}flow */
    uint256 allowanceNew = startingAllowance - tokens;
    uint256 srcTokensNew = accountTokens[src] - tokens;
    uint256 dstTokensNew = accountTokens[dst] + tokens;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    accountTokens[src] = srcTokensNew;
    accountTokens[dst] = dstTokensNew;

    /* Eat some of the allowance (if necessary) */
    if (startingAllowance != type(uint256).max) {
      transferAllowances[src][spender] = allowanceNew;
    }

    /* We emit a Transfer event */
    emit Transfer(src, dst, tokens);

    // unused function
    // comptroller.transferVerify(address(this), src, dst, tokens);

    return NO_ERROR;
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
    return transferTokens(msg.sender, msg.sender, dst, amount) == NO_ERROR;
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external override nonReentrant returns (bool) {
    return transferTokens(msg.sender, src, dst, amount) == NO_ERROR;
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (uint256.max means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    address src = msg.sender;
    transferAllowances[src][spender] = amount;
    emit Approval(src, spender, amount);
    return true;
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return transferAllowances[owner][spender];
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view override returns (uint256) {
    return accountTokens[owner];
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external override returns (uint256) {
    Exp memory exchangeRate = Exp({ mantissa: exchangeRateCurrent() });
    return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by comptroller to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address account)
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (NO_ERROR, accountTokens[account], borrowBalanceStoredInternal(account), exchangeRateStoredInternal());
  }

  /**
   * @dev Function to simply retrieve block number
   *  This exists mainly for inheriting test contracts to stub this result.
   */
  function getBlockNumber() internal view virtual returns (uint256) {
    return block.number;
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view override returns (uint256) {
    return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view override returns (uint256) {
    return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
    accrueInterest();
    return totalBorrows;
  }

  /**
   * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
   * @param account The address whose balance should be calculated after updating borrowIndex
   * @return The calculated balance
   */
  function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
    accrueInterest();
    return borrowBalanceStored(account);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view override returns (uint256) {
    return borrowBalanceStoredInternal(account);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return (error code, the calculated balance or 0 if error code is non-zero)
   */
  function borrowBalanceStoredInternal(address account) internal view returns (uint256) {
    /* Get borrowBalance and borrowIndex */
    BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

    /* If borrowBalance = 0 then borrowIndex is likely also 0.
     * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
     */
    if (borrowSnapshot.principal == 0) {
      return 0;
    }

    /* Calculate new borrow balance using the interest index:
     *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
     */
    uint256 principalTimesIndex = borrowSnapshot.principal * borrowIndex;
    return principalTimesIndex / borrowSnapshot.interestIndex;
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public override nonReentrant returns (uint256) {
    accrueInterest();
    return exchangeRateStored();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view override returns (uint256) {
    return exchangeRateStoredInternal();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return calculated exchange rate scaled by 1e18
   */
  function exchangeRateStoredInternal() internal view virtual returns (uint256) {
    uint256 _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      /*
       * If there are no tokens minted:
       *  exchangeRate = initialExchangeRate
       */
      return initialExchangeRateMantissa;
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
       */
      uint256 totalCash = getCashPrior();
      uint256 cashPlusBorrowsMinusReserves = totalCash + totalBorrows - totalReserves;
      uint256 exchangeRate = (cashPlusBorrowsMinusReserves * expScale) / _totalSupply;

      return exchangeRate;
    }
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    return getCashPrior();
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   *   up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public virtual override returns (uint256) {
    /* Remember the initial block number */
    uint256 currentBlockNumber = getBlockNumber();
    uint256 accrualBlockNumberPrior = accrualBlockNumber;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumberPrior == currentBlockNumber) {
      return NO_ERROR;
    }

    /* Read the previous values out of storage */
    uint256 cashPrior = getCashPrior();
    uint256 borrowsPrior = totalBorrows;
    uint256 reservesPrior = totalReserves;
    uint256 borrowIndexPrior = borrowIndex;

    /* Calculate the current borrow interest rate */
    uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
    require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

    /* Calculate the number of blocks elapsed since the last accrual */
    uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    Exp memory simpleInterestFactor = mul_(Exp({ mantissa: borrowRateMantissa }), blockDelta);
    uint256 interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
    uint256 totalBorrowsNew = interestAccumulated + borrowsPrior;
    uint256 totalReservesNew = mul_ScalarTruncateAddUInt(Exp({ mantissa: reserveFactorMantissa }), interestAccumulated, reservesPrior);
    uint256 borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accrualBlockNumber = currentBlockNumber;
    borrowIndex = borrowIndexNew;
    totalBorrows = totalBorrowsNew;
    totalReserves = totalReservesNew;

    /* We emit an AccrueInterest event */
    emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

    return NO_ERROR;
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   */
  function mintInternal(uint256 mintAmount) internal nonReentrant {
    accrueInterest();
    // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
    mintFresh(msg.sender, mintAmount);
  }

  /**
   * @notice User supplies assets into the market and receives cTokens in exchange
   * @dev Assumes interest has already been accrued up to the current block
   * @param minter The address of the account which is supplying the assets
   * @param mintAmount The amount of the underlying asset to supply
   */
  function mintFresh(address minter, uint256 mintAmount) internal {
    /* Fail if mint not allowed */
    uint256 allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
    if (allowed != 0) {
      revert MintComptrollerRejection(allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert MintFreshnessCheck();
    }

    Exp memory exchangeRate = Exp({ mantissa: exchangeRateStoredInternal() });

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     *  We call `doTransferIn` for the minter and the mintAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
     *  side-effects occurred. The function returns the amount actually transferred,
     *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
     *  of cash.
     */
    uint256 actualMintAmount = doTransferIn(minter, mintAmount);

    /*
     * We get the current exchange rate and calculate the number of cTokens to be minted:
     *  mintTokens = actualMintAmount / exchangeRate
     */

    uint256 mintTokens = div_(actualMintAmount, exchangeRate);

    /*
     * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
     *  totalSupplyNew = totalSupply + mintTokens
     *  accountTokensNew = accountTokens[minter] + mintTokens
     * And write them into storage
     */
    totalSupply = totalSupply + mintTokens;
    accountTokens[minter] = accountTokens[minter] + mintTokens;

    /* We emit a Mint event, and a Transfer event */
    emit Mint(minter, actualMintAmount, mintTokens);
    emit Transfer(address(this), minter, mintTokens);

    /* We call the defense hook */
    // unused function
    // comptroller.mintVerify(address(this), minter, actualMintAmount, mintTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   */
  function redeemInternal(uint256 redeemTokens) internal nonReentrant {
    accrueInterest();
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    redeemFresh(payable(msg.sender), redeemTokens, 0);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to receive from redeeming cTokens
   */
  function redeemUnderlyingInternal(uint256 redeemAmount) internal nonReentrant {
    accrueInterest();
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    redeemFresh(payable(msg.sender), 0, redeemAmount);
  }

  /**
   * @notice User redeems cTokens in exchange for the underlying asset
   * @dev Assumes interest has already been accrued up to the current block
   * @param redeemer The address of the account which is redeeming the tokens
   * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   */
  function redeemFresh(
    address payable redeemer,
    uint256 redeemTokensIn,
    uint256 redeemAmountIn
  ) internal {
    require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

    /* exchangeRate = invoke Exchange Rate Stored() */
    Exp memory exchangeRate = Exp({ mantissa: exchangeRateStoredInternal() });

    uint256 redeemTokens;
    uint256 redeemAmount;
    /* If redeemTokensIn > 0: */
    if (redeemTokensIn > 0) {
      /*
       * We calculate the exchange rate and the amount of underlying to be redeemed:
       *  redeemTokens = redeemTokensIn
       *  redeemAmount = redeemTokensIn x exchangeRateCurrent
       */
      redeemTokens = redeemTokensIn;
      redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokensIn);
    } else {
      /*
       * We get the current exchange rate and calculate the amount to be redeemed:
       *  redeemTokens = redeemAmountIn / exchangeRate
       *  redeemAmount = redeemAmountIn
       */
      redeemTokens = div_(redeemAmountIn, exchangeRate);
      redeemAmount = redeemAmountIn;
    }

    /* Fail if redeem not allowed */
    uint256 allowed = comptroller.redeemAllowed(address(this), redeemer, redeemTokens);
    if (allowed != 0) {
      revert RedeemComptrollerRejection(allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert RedeemFreshnessCheck();
    }

    /* Fail gracefully if protocol has insufficient cash */
    if (getCashPrior() < redeemAmount) {
      revert RedeemTransferOutNotPossible();
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We write the previously calculated values into storage.
     *  Note: Avoid token reentrancy attacks by writing reduced supply before external transfer.
     */
    totalSupply = totalSupply - redeemTokens;
    accountTokens[redeemer] = accountTokens[redeemer] - redeemTokens;

    /*
     * We invoke doTransferOut for the redeemer and the redeemAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken has redeemAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    doTransferOut(redeemer, redeemAmount);

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), redeemTokens);
    emit Redeem(redeemer, redeemAmount, redeemTokens);

    /* We call the defense hook */
    comptroller.redeemVerify(address(this), redeemer, redeemAmount, redeemTokens);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   */
  function borrowInternal(uint256 borrowAmount) internal nonReentrant {
    accrueInterest();
    // borrowFresh emits borrow-specific logs on errors, so we don't need to
    borrowFresh(payable(msg.sender), borrowAmount);
  }

  /**
   * @notice Users borrow assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   */
  function borrowFresh(address payable borrower, uint256 borrowAmount) internal {
    /* Fail if borrow not allowed */
    uint256 allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
    if (allowed != 0) {
      revert BorrowComptrollerRejection(allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert BorrowFreshnessCheck();
    }

    /* Fail gracefully if protocol has insufficient underlying cash */
    if (getCashPrior() < borrowAmount) {
      revert BorrowCashNotAvailable();
    }

    /*
     * We calculate the new borrower and total borrow balances, failing on overflow:
     *  accountBorrowNew = accountBorrow + borrowAmount
     *  totalBorrowsNew = totalBorrows + borrowAmount
     */
    uint256 accountBorrowsPrev = borrowBalanceStoredInternal(borrower);
    uint256 accountBorrowsNew = accountBorrowsPrev + borrowAmount;
    uint256 totalBorrowsNew = totalBorrows + borrowAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing increased borrow before external transfer.
        `*/
    accountBorrows[borrower].principal = accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = totalBorrowsNew;

    /*
     * We invoke doTransferOut for the borrower and the borrowAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken borrowAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    doTransferOut(borrower, borrowAmount);

    /* We emit a Borrow event */
    emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay, or -1 for the full outstanding amount
   */
  function repayBorrowInternal(uint256 repayAmount) internal nonReentrant {
    accrueInterest();
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    repayBorrowFresh(msg.sender, msg.sender, repayAmount);
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay, or -1 for the full outstanding amount
   */
  function repayBorrowBehalfInternal(address borrower, uint256 repayAmount) internal nonReentrant {
    accrueInterest();
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    repayBorrowFresh(msg.sender, borrower, repayAmount);
  }

  /**
   * @notice Borrows are repaid by another user (possibly the borrower).
   * @param payer the account paying off the borrow
   * @param borrower the account with the debt being payed off
   * @param repayAmount the amount of underlying tokens being returned, or -1 for the full outstanding amount
   * @return (uint) the actual repayment amount.
   */
  function repayBorrowFresh(
    address payer,
    address borrower,
    uint256 repayAmount
  ) internal returns (uint256) {
    /* Fail if repayBorrow not allowed */
    uint256 allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
    if (allowed != 0) {
      revert RepayBorrowComptrollerRejection(allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert RepayBorrowFreshnessCheck();
    }

    /* We fetch the amount the borrower owes, with accumulated interest */
    uint256 accountBorrowsPrev = borrowBalanceStoredInternal(borrower);

    /* If repayAmount == -1, repayAmount = accountBorrows */
    uint256 repayAmountFinal = repayAmount == type(uint256).max ? accountBorrowsPrev : repayAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the payer and the repayAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional repayAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *   it returns the amount actually transferred, in case of a fee.
     */
    uint256 actualRepayAmount = doTransferIn(payer, repayAmountFinal);

    /*
     * We calculate the new borrower and total borrow balances, failing on underflow:
     *  accountBorrowsNew = accountBorrows - actualRepayAmount
     *  totalBorrowsNew = totalBorrows - actualRepayAmount
     */
    uint256 accountBorrowsNew = accountBorrowsPrev - actualRepayAmount;
    uint256 totalBorrowsNew = totalBorrows - actualRepayAmount;

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = totalBorrowsNew;

    /* We emit a RepayBorrow event */
    emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);

    return actualRepayAmount;
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   */
  function liquidateBorrowInternal(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) internal nonReentrant {
    require(msg.sender == admin, "only dAMM Foundation can liquidate borrowers");
    accrueInterest();
    uint256 error = cTokenCollateral.accrueInterest();
    if (error != NO_ERROR) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
      revert LiquidateAccrueCollateralInterestFailed(error);
    }

    // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
    liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
  }

  /**
   * @notice The liquidator liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The lender of this cToken to be liquidated, in the case of dAMM
   * @param liquidator The address repaying the borrow and seizing collateral
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   */
  function liquidateBorrowFresh(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) internal {
    /* Fail if liquidate not allowed */
    uint256 allowed = comptroller.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
    if (allowed != 0) {
      revert LiquidateComptrollerRejection(allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      revert LiquidateFreshnessCheck();
    }

    /* Verify cTokenCollateral market's block number equals current block number */
    if (cTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
      revert LiquidateCollateralFreshnessCheck();
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      revert LiquidateLiquidatorIsBorrower();
    }

    /* Fail if repayAmount = 0 */
    if (repayAmount == 0) {
      revert LiquidateCloseAmountIsZero();
    }

    /* Fail if repayAmount = -1 */
    if (repayAmount == type(uint256).max) {
      revert LiquidateCloseAmountIsUintMax();
    }

    /* Fail if repayBorrow fails */
    uint256 actualRepayAmount = repayBorrowFresh(liquidator, borrower, repayAmount);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We calculate the number of collateral tokens that will be seized */
    (uint256 amountSeizeError, uint256 seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(cTokenCollateral), actualRepayAmount);
    require(amountSeizeError == NO_ERROR, "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

    /* Revert if borrower collateral token balance < seizeTokens */
    require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

    // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
    if (address(cTokenCollateral) == address(this)) {
      seizeInternal(address(this), liquidator, borrower, seizeTokens);
    } else {
      require(cTokenCollateral.seize(liquidator, borrower, seizeTokens) == NO_ERROR, "token seizure failed");
    }

    /* We emit a LiquidateBorrow event */
    emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another cToken during the process of liquidation.
   *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external override nonReentrant returns (uint256) {
    seizeInternal(msg.sender, liquidator, borrower, seizeTokens);

    return NO_ERROR;
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
   *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
   * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   */
  function seizeInternal(
    address seizerToken,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) internal {
    /* Fail if seize not allowed */
    uint256 allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
    if (allowed != 0) {
      revert LiquidateSeizeComptrollerRejection(allowed);
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      revert LiquidateSeizeLiquidatorIsBorrower();
    }

    /*
     * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
     *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
     *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
     */
    uint256 protocolSeizeTokens = mul_(seizeTokens, Exp({ mantissa: protocolSeizeShareMantissa }));
    uint256 liquidatorSeizeTokens = seizeTokens - protocolSeizeTokens;
    Exp memory exchangeRate = Exp({ mantissa: exchangeRateStoredInternal() });
    uint256 protocolSeizeAmount = mul_ScalarTruncate(exchangeRate, protocolSeizeTokens);
    uint256 totalReservesNew = totalReserves + protocolSeizeAmount;

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the calculated values into storage */
    totalReserves = totalReservesNew;
    totalSupply = totalSupply - protocolSeizeTokens;
    accountTokens[borrower] = accountTokens[borrower] - seizeTokens;
    accountTokens[liquidator] = accountTokens[liquidator] + liquidatorSeizeTokens;

    /* Emit a Transfer event */
    emit Transfer(borrower, liquidator, liquidatorSeizeTokens);
    emit Transfer(borrower, address(this), protocolSeizeTokens);
    emit ReservesAdded(address(this), protocolSeizeAmount, totalReservesNew);
  }

  /*** Admin Functions ***/

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address payable newPendingAdmin) external override returns (uint256) {
    // Check caller = admin
    if (msg.sender != admin) {
      revert SetPendingAdminOwnerCheck();
    }

    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

    return NO_ERROR;
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external override returns (uint256) {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      revert AcceptAdminPendingAdminCheck();
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = payable(address(0));

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return NO_ERROR;
  }

  /**
   * @notice Sets a new comptroller for the market
   * @dev Admin function to set a new comptroller
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setComptroller(ComptrollerInterface newComptroller) public override returns (uint256) {
    // Check caller is admin
    if (msg.sender != admin) {
      revert SetComptrollerOwnerCheck();
    }

    ComptrollerInterface oldComptroller = comptroller;
    // Ensure invoke comptroller.isComptroller() returns true
    require(newComptroller.isComptroller(), "marker method returned false");

    // Set market's comptroller to newComptroller
    comptroller = newComptroller;

    // Emit NewComptroller(oldComptroller, newComptroller)
    emit NewComptroller(oldComptroller, newComptroller);

    return NO_ERROR;
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(uint256 newReserveFactorMantissa) external override nonReentrant returns (uint256) {
    accrueInterest();
    // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
    return _setReserveFactorFresh(newReserveFactorMantissa);
  }

  /**
   * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
   * @dev Admin function to set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactorFresh(uint256 newReserveFactorMantissa) internal returns (uint256) {
    // Check caller is admin
    if (msg.sender != admin) {
      revert SetReserveFactorAdminCheck();
    }

    // Verify market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert SetReserveFactorFreshCheck();
    }

    // Check newReserveFactor ≤ maxReserveFactor
    if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
      revert SetReserveFactorBoundsCheck();
    }

    uint256 oldReserveFactorMantissa = reserveFactorMantissa;
    reserveFactorMantissa = newReserveFactorMantissa;

    emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

    return NO_ERROR;
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring from msg.sender
   * @param addAmount Amount of addition to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReservesInternal(uint256 addAmount) internal nonReentrant returns (uint256) {
    accrueInterest();

    // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
    _addReservesFresh(addAmount);
    return NO_ERROR;
  }

  /**
   * @notice Add reserves by transferring from caller
   * @dev Requires fresh interest accrual
   * @param addAmount Amount of addition to reserves
   * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
   */
  function _addReservesFresh(uint256 addAmount) internal returns (uint256, uint256) {
    // totalReserves + actualAddAmount
    uint256 totalReservesNew;
    uint256 actualAddAmount;

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert AddReservesFactorFreshCheck(actualAddAmount);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the caller and the addAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional addAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *  it returns the amount actually transferred, in case of a fee.
     */

    actualAddAmount = doTransferIn(msg.sender, addAmount);

    totalReservesNew = totalReserves + actualAddAmount;

    // Store reserves[n+1] = reserves[n] + actualAddAmount
    totalReserves = totalReservesNew;

    /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
    emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

    /* Return (NO_ERROR, actualAddAmount) */
    return (NO_ERROR, actualAddAmount);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReserves(uint256 reduceAmount) external override nonReentrant returns (uint256) {
    accrueInterest();
    // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
    return _reduceReservesFresh(reduceAmount);
  }

  /**
   * @notice Reduces reserves by transferring to admin
   * @dev Requires fresh interest accrual
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReservesFresh(uint256 reduceAmount) internal returns (uint256) {
    // totalReserves - reduceAmount
    uint256 totalReservesNew;

    // Check caller is admin
    if (msg.sender != admin) {
      revert ReduceReservesAdminCheck();
    }

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert ReduceReservesFreshCheck();
    }

    // Fail gracefully if protocol has insufficient underlying cash
    if (getCashPrior() < reduceAmount) {
      revert ReduceReservesCashNotAvailable();
    }

    // Check reduceAmount ≤ reserves[n] (totalReserves)
    if (reduceAmount > totalReserves) {
      revert ReduceReservesCashValidation();
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    totalReservesNew = totalReserves - reduceAmount;

    // Store reserves[n+1] = reserves[n] - reduceAmount
    totalReserves = totalReservesNew;

    // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
    doTransferOut(admin, reduceAmount);

    emit ReservesReduced(admin, reduceAmount, totalReservesNew);

    return NO_ERROR;
  }

  /**
   * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(InterestRateModel newInterestRateModel) public override returns (uint256) {
    accrueInterest();
    // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
    return _setInterestRateModelFresh(newInterestRateModel);
  }

  /**
   * @notice updates the interest rate model (*requires fresh interest accrual)
   * @dev Admin function to update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint256) {
    // Used to store old model for use in the event that is emitted on success
    InterestRateModel oldInterestRateModel;

    // Check caller is admin
    if (msg.sender != admin) {
      revert SetInterestRateModelOwnerCheck();
    }

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      revert SetInterestRateModelFreshCheck();
    }

    // Track the market's current interest rate model
    oldInterestRateModel = interestRateModel;

    // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
    require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

    // Set the interest rate model to newInterestRateModel
    interestRateModel = newInterestRateModel;

    // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
    emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

    return NO_ERROR;
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying owned by this contract
   */
  function getCashPrior() internal view virtual returns (uint256);

  /**
   * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
   *  This may revert due to insufficient balance or insufficient allowance.
   */
  function doTransferIn(address from, uint256 amount) internal virtual returns (uint256);

  /**
   * @dev Performs a transfer out, ideally returning an explanatory error code upon failure rather than reverting.
   *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
   *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
   */
  function doTransferOut(address payable to, uint256 amount) internal virtual;

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(_notEntered, "re-entered");
    _notEntered = false;
    _;
    _notEntered = true; // get a gas-refund post-Istanbul
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) virtual external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) virtual external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function whitelistBorrowerAdd(address borrower) virtual external returns (uint);
    function setBorrowerLimits(address borrower, uint256 _borrowLimit) virtual external returns (uint);
    function getBorrowerLimits(address borrower) virtual external returns (uint);


    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) virtual external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) virtual external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";

contract CTokenStorage {
  /**
   * @dev Guard variable for re-entrancy checks
   */
  bool internal _notEntered;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  // Maximum borrow rate that can ever be applied (.0005% / block)
  uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

  // Maximum fraction of interest that can be set aside for reserves
  uint256 internal constant reserveFactorMaxMantissa = 1e18;

  /**
   * @notice Administrator for this contract
   */
  address payable public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address payable public pendingAdmin;

  /**
   * @notice Contract which oversees inter-cToken operations
   */
  ComptrollerInterface public comptroller;

  /**
   * @notice Model which tells what the current interest rate should be
   */
  InterestRateModel public interestRateModel;

  // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
  uint256 internal initialExchangeRateMantissa;

  /**
   * @notice Fraction of interest currently set aside for reserves
   */
  uint256 public reserveFactorMantissa;

  /**
   * @notice Block number that interest was last accrued at
   */
  uint256 public accrualBlockNumber;

  /**
   * @notice Accumulator of the total earned interest rate since the opening of the market
   */
  uint256 public borrowIndex;

  /**
   * @notice Total amount of outstanding borrows of the underlying in this market
   */
  uint256 public totalBorrows;

  /**
   * @notice Total amount of reserves of the underlying held in this market
   */
  uint256 public totalReserves;

  /**
   * @notice Total number of tokens in circulation
   */
  uint256 public totalSupply;

  // Official record of token balances for each account
  mapping(address => uint256) internal accountTokens;

  // Approved token transfer amounts on behalf of others
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /**
   * @notice Container for borrow balance information
   * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
   * @member interestIndex Global borrowIndex as of the most recent balance-changing action
   */
  struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
  }

  // Mapping of account addresses to outstanding borrow balances
  mapping(address => BorrowSnapshot) internal accountBorrows;

  /**
   * @notice Share of seized collateral that is added to reserves
   */
  uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
  /**
   * @notice Indicator that this is a CToken contract (for inspection)
   */
  bool public constant isCToken = true;

  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens);

  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when comptroller is changed
   */
  event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external virtual returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external virtual returns (bool);

  function approve(address spender, uint256 amount) external virtual returns (bool);

  function allowance(address owner, address spender) external view virtual returns (uint256);

  function balanceOf(address owner) external view virtual returns (uint256);

  function balanceOfUnderlying(address owner) external virtual returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    virtual
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function borrowRatePerBlock() external view virtual returns (uint256);

  function supplyRatePerBlock() external view virtual returns (uint256);

  function totalBorrowsCurrent() external virtual returns (uint256);

  function borrowBalanceCurrent(address account) external virtual returns (uint256);

  function borrowBalanceStored(address account) external view virtual returns (uint256);

  function exchangeRateCurrent() external virtual returns (uint256);

  function exchangeRateStored() external view virtual returns (uint256);

  function getCash() external view virtual returns (uint256);

  function accrueInterest() external virtual returns (uint256);

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external virtual returns (uint256);

  /*** Admin Functions ***/

  function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint256);

  function _acceptAdmin() external virtual returns (uint256);

  function _setComptroller(ComptrollerInterface newComptroller) external virtual returns (uint256);

  function _setReserveFactor(uint256 newReserveFactorMantissa) external virtual returns (uint256);

  function _reduceReserves(uint256 reduceAmount) external virtual returns (uint256);

  function _setInterestRateModel(InterestRateModel newInterestRateModel) external virtual returns (uint256);
}

contract CErc20Storage {
  /**
   * @notice Underlying asset for this CToken
   */
  address public underlying;
}

abstract contract CErc20Interface is CErc20Storage {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external virtual returns (uint256);

  function redeem(uint256 redeemTokens) external virtual returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

  function borrow(uint256 borrowAmount) external virtual returns (uint256);

  function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external virtual returns (uint256);

  function sweepToken(EIP20NonStandardInterface token) external virtual;

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external virtual returns (uint256);
}

contract CDelegationStorage {
  /**
   * @notice Implementation address for this contract
   */
  address public implementation;
}

abstract contract CDelegatorInterface is CDelegationStorage {
  /**
   * @notice Emitted when implementation is changed
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) external virtual;
}

abstract contract CDelegateInterface is CDelegationStorage {
  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @dev Should revert if any issues arise which make it unfit for delegation
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) external virtual;

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() external virtual;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract ComptrollerErrorReporter {
  enum Error {
    NO_ERROR,
    UNAUTHORIZED,
    COMPTROLLER_MISMATCH,
    INSUFFICIENT_SHORTFALL,
    INSUFFICIENT_LIQUIDITY,
    INVALID_CLOSE_FACTOR,
    INVALID_COLLATERAL_FACTOR,
    INVALID_LIQUIDATION_INCENTIVE,
    MARKET_NOT_ENTERED, // no longer possible
    MARKET_NOT_LISTED,
    MARKET_ALREADY_LISTED,
    MATH_ERROR,
    NONZERO_BORROW_BALANCE,
    PRICE_ERROR,
    REJECTION,
    SNAPSHOT_ERROR,
    TOO_MANY_ASSETS,
    TOO_MUCH_REPAY
  }

  enum FailureInfo {
    ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
    ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
    EXIT_MARKET_BALANCE_OWED,
    EXIT_MARKET_REJECTION,
    SET_CLOSE_FACTOR_OWNER_CHECK,
    SET_CLOSE_FACTOR_VALIDATION,
    SET_COLLATERAL_FACTOR_OWNER_CHECK,
    SET_COLLATERAL_FACTOR_NO_EXISTS,
    SET_COLLATERAL_FACTOR_VALIDATION,
    SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
    SET_IMPLEMENTATION_OWNER_CHECK,
    SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
    SET_LIQUIDATION_INCENTIVE_VALIDATION,
    SET_MAX_ASSETS_OWNER_CHECK,
    SET_PENDING_ADMIN_OWNER_CHECK,
    SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
    SET_PRICE_ORACLE_OWNER_CHECK,
    SUPPORT_MARKET_EXISTS,
    SUPPORT_MARKET_OWNER_CHECK,
    SET_PAUSE_GUARDIAN_OWNER_CHECK,
    SET_BORROWER_LIMIT_CHECK
  }

  /**
   * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
   * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
   **/
  event Failure(uint256 error, uint256 info, uint256 detail);

  /**
   * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
   */
  function fail(Error err, FailureInfo info) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), 0);

    return uint256(err);
  }

  /**
   * @dev use this when reporting an opaque error from an upgradeable collaborator contract
   */
  function failOpaque(
    Error err,
    FailureInfo info,
    uint256 opaqueError
  ) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), opaqueError);

    return uint256(err);
  }
}

contract TokenErrorReporter {
  uint256 public constant NO_ERROR = 0; // support legacy return codes

  error TransferComptrollerRejection(uint256 errorCode);
  error TransferNotAllowed();
  error TransferNotEnough();
  error TransferTooMuch();

  error MintComptrollerRejection(uint256 errorCode);
  error MintFreshnessCheck();

  error RedeemComptrollerRejection(uint256 errorCode);
  error RedeemFreshnessCheck();
  error RedeemTransferOutNotPossible();

  error BorrowComptrollerRejection(uint256 errorCode);
  error BorrowFreshnessCheck();
  error BorrowCashNotAvailable();

  error RepayBorrowComptrollerRejection(uint256 errorCode);
  error RepayBorrowFreshnessCheck();

  error LiquidateComptrollerRejection(uint256 errorCode);
  error LiquidateFreshnessCheck();
  error LiquidateCollateralFreshnessCheck();
  error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
  error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
  error LiquidateLiquidatorIsBorrower();
  error LiquidateCloseAmountIsZero();
  error LiquidateCloseAmountIsUintMax();
  error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

  error LiquidateSeizeComptrollerRejection(uint256 errorCode);
  error LiquidateSeizeLiquidatorIsBorrower();

  error AcceptAdminPendingAdminCheck();

  error SetComptrollerOwnerCheck();
  error SetPendingAdminOwnerCheck();

  error SetReserveFactorAdminCheck();
  error SetReserveFactorFreshCheck();
  error SetReserveFactorBoundsCheck();

  error AddReservesFactorFreshCheck(uint256 actualAddAmount);

  error ReduceReservesAdminCheck();
  error ReduceReservesFreshCheck();
  error ReduceReservesCashNotAvailable();
  error ReduceReservesCashValidation();

  error SetInterestRateModelOwnerCheck();
  error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  /**
   * @notice Get the total number of tokens in circulation
   * @return The supply of tokens
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Gets the balance of the specified address
   * @param owner The address from which the balance will be retrieved
   * @return balance The balance
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return success Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external returns (bool success);

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return success Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool success);

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return success Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool success);

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return remaining The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
abstract contract InterestRateModel {
  /// @notice Indicator that this is an InterestRateModel contract (for inspection)
  bool public constant isInterestRateModel = true;

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view virtual returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
  uint256 constant expScale = 1e18;
  uint256 constant doubleScale = 1e36;
  uint256 constant halfExpScale = expScale / 2;
  uint256 constant mantissaOne = expScale;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint256) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: add_(a.mantissa, b.mantissa) });
  }

  function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({ mantissa: add_(a.mantissa, b.mantissa) });
  }

  function add_(uint256 a, uint256 b) internal pure returns (uint256) {
    return a + b;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: sub_(a.mantissa, b.mantissa) });
  }

  function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({ mantissa: sub_(a.mantissa, b.mantissa) });
  }

  function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: mul_(a.mantissa, b.mantissa) / expScale });
  }

  function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({ mantissa: mul_(a.mantissa, b) });
  }

  function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({ mantissa: mul_(a.mantissa, b.mantissa) / doubleScale });
  }

  function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({ mantissa: mul_(a.mantissa, b) });
  }

  function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
    return a * b;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({ mantissa: div_(mul_(a.mantissa, expScale), b.mantissa) });
  }

  function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({ mantissa: div_(a.mantissa, b) });
  }

  function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({ mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa) });
  }

  function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({ mantissa: div_(a.mantissa, b) });
  }

  function div_(uint256 a, Double memory b) internal pure returns (uint256) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
    return Double({ mantissa: div_(mul_(a, doubleScale), b) });
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
  /**
   * @notice Get the total number of tokens in circulation
   * @return The supply of tokens
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Gets the balance of the specified address
   * @param owner The address from which the balance will be retrieved
   * @return balance The balance
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transfer(address dst, uint256 amount) external;

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external;

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved
   * @return success Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool success);

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return remaining The number of tokens allowed to be spent
   */
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../CErc20.sol";
import "../CToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../Governance/GovernorAlpha.sol";
import "../Governance/Comp.sol";

interface ComptrollerLensInterface {
  function markets(address) external view returns (bool, uint256);

  function oracle() external view returns (PriceOracle);

  function getAccountLiquidity(address)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getAssetsIn(address) external view returns (CToken[] memory);

  function claimComp(address) external;

  function compAccrued(address) external view returns (uint256);

  function compSpeeds(address) external view returns (uint256);

  function compSupplySpeeds(address) external view returns (uint256);

  function compBorrowSpeeds(address) external view returns (uint256);

  function borrowCaps(address) external view returns (uint256);
}

interface GovernorBravoInterface {
  struct Receipt {
    bool hasVoted;
    uint8 support;
    uint96 votes;
  }
  struct Proposal {
    uint256 id;
    address proposer;
    uint256 eta;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    bool canceled;
    bool executed;
  }

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function proposals(uint256 proposalId) external view returns (Proposal memory);

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);
}

contract CompoundLens {
  struct CTokenMetadata {
    address cToken;
    uint256 exchangeRateCurrent;
    uint256 supplyRatePerBlock;
    uint256 borrowRatePerBlock;
    uint256 reserveFactorMantissa;
    uint256 totalBorrows;
    uint256 totalReserves;
    uint256 totalSupply;
    uint256 totalCash;
    bool isListed;
    uint256 collateralFactorMantissa;
    address underlyingAssetAddress;
    uint256 cTokenDecimals;
    uint256 underlyingDecimals;
    uint256 compSupplySpeed;
    uint256 compBorrowSpeed;
    uint256 borrowCap;
  }

  function getCompSpeeds(ComptrollerLensInterface comptroller, CToken cToken) internal returns (uint256, uint256) {
    // Getting comp speeds is gnarly due to not every network having the
    // split comp speeds from Proposal 62 and other networks don't even
    // have comp speeds.
    uint256 compSupplySpeed = 0;
    (bool compSupplySpeedSuccess, bytes memory compSupplySpeedReturnData) = address(comptroller).call(
      abi.encodePacked(comptroller.compSupplySpeeds.selector, abi.encode(address(cToken)))
    );
    if (compSupplySpeedSuccess) {
      compSupplySpeed = abi.decode(compSupplySpeedReturnData, (uint256));
    }

    uint256 compBorrowSpeed = 0;
    (bool compBorrowSpeedSuccess, bytes memory compBorrowSpeedReturnData) = address(comptroller).call(
      abi.encodePacked(comptroller.compBorrowSpeeds.selector, abi.encode(address(cToken)))
    );
    if (compBorrowSpeedSuccess) {
      compBorrowSpeed = abi.decode(compBorrowSpeedReturnData, (uint256));
    }

    // If the split comp speeds call doesn't work, try the  oldest non-spit version.
    if (!compSupplySpeedSuccess || !compBorrowSpeedSuccess) {
      (bool compSpeedSuccess, bytes memory compSpeedReturnData) = address(comptroller).call(
        abi.encodePacked(comptroller.compSpeeds.selector, abi.encode(address(cToken)))
      );
      if (compSpeedSuccess) {
        compSupplySpeed = compBorrowSpeed = abi.decode(compSpeedReturnData, (uint256));
      }
    }
    return (compSupplySpeed, compBorrowSpeed);
  }

  function cTokenMetadata(CToken cToken) public returns (CTokenMetadata memory) {
    uint256 exchangeRateCurrent = cToken.exchangeRateCurrent();
    ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(cToken.comptroller()));
    (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(address(cToken));
    address underlyingAssetAddress;
    uint256 underlyingDecimals;

    if (compareStrings(cToken.symbol(), "dETH")) {
      underlyingAssetAddress = address(0);
      underlyingDecimals = 18;
    } else {
      CErc20 cErc20 = CErc20(address(cToken));
      underlyingAssetAddress = cErc20.underlying();
      underlyingDecimals = EIP20Interface(cErc20.underlying()).decimals();
    }

    (uint256 compSupplySpeed, uint256 compBorrowSpeed) = getCompSpeeds(comptroller, cToken);

    uint256 borrowCap = 0;
    (bool borrowCapSuccess, bytes memory borrowCapReturnData) = address(comptroller).call(
      abi.encodePacked(comptroller.borrowCaps.selector, abi.encode(address(cToken)))
    );
    if (borrowCapSuccess) {
      borrowCap = abi.decode(borrowCapReturnData, (uint256));
    }

    return
      CTokenMetadata({
        cToken: address(cToken),
        exchangeRateCurrent: exchangeRateCurrent,
        supplyRatePerBlock: cToken.supplyRatePerBlock(),
        borrowRatePerBlock: cToken.borrowRatePerBlock(),
        reserveFactorMantissa: cToken.reserveFactorMantissa(),
        totalBorrows: cToken.totalBorrows(),
        totalReserves: cToken.totalReserves(),
        totalSupply: cToken.totalSupply(),
        totalCash: cToken.getCash(),
        isListed: isListed,
        collateralFactorMantissa: collateralFactorMantissa,
        underlyingAssetAddress: underlyingAssetAddress,
        cTokenDecimals: cToken.decimals(),
        underlyingDecimals: underlyingDecimals,
        compSupplySpeed: compSupplySpeed,
        compBorrowSpeed: compBorrowSpeed,
        borrowCap: borrowCap
      });
  }

  function cTokenMetadataAll(CToken[] calldata cTokens) external returns (CTokenMetadata[] memory) {
    uint256 cTokenCount = cTokens.length;
    CTokenMetadata[] memory res = new CTokenMetadata[](cTokenCount);
    for (uint256 i = 0; i < cTokenCount; i++) {
      res[i] = cTokenMetadata(cTokens[i]);
    }
    return res;
  }

  struct CTokenBalances {
    address cToken;
    uint256 balanceOf;
    uint256 borrowBalanceCurrent;
    uint256 balanceOfUnderlying;
    uint256 tokenBalance;
    uint256 tokenAllowance;
  }

  function cTokenBalances(CToken cToken, address payable account) public returns (CTokenBalances memory) {
    uint256 balanceOf = cToken.balanceOf(account);
    uint256 borrowBalanceCurrent = cToken.borrowBalanceCurrent(account);
    uint256 balanceOfUnderlying = cToken.balanceOfUnderlying(account);
    uint256 tokenBalance;
    uint256 tokenAllowance;

    if (compareStrings(cToken.symbol(), "dETH")) {
      tokenBalance = account.balance;
      tokenAllowance = account.balance;
    } else {
      CErc20 cErc20 = CErc20(address(cToken));
      EIP20Interface underlying = EIP20Interface(cErc20.underlying());
      tokenBalance = underlying.balanceOf(account);
      tokenAllowance = underlying.allowance(account, address(cToken));
    }

    return
      CTokenBalances({
        cToken: address(cToken),
        balanceOf: balanceOf,
        borrowBalanceCurrent: borrowBalanceCurrent,
        balanceOfUnderlying: balanceOfUnderlying,
        tokenBalance: tokenBalance,
        tokenAllowance: tokenAllowance
      });
  }

  function cTokenBalancesAll(CToken[] calldata cTokens, address payable account) external returns (CTokenBalances[] memory) {
    uint256 cTokenCount = cTokens.length;
    CTokenBalances[] memory res = new CTokenBalances[](cTokenCount);
    for (uint256 i = 0; i < cTokenCount; i++) {
      res[i] = cTokenBalances(cTokens[i], account);
    }
    return res;
  }

  struct CTokenUnderlyingPrice {
    address cToken;
    uint256 underlyingPrice;
  }

  function cTokenUnderlyingPrice(CToken cToken) public returns (CTokenUnderlyingPrice memory) {
    ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(cToken.comptroller()));
    PriceOracle priceOracle = comptroller.oracle();

    return CTokenUnderlyingPrice({ cToken: address(cToken), underlyingPrice: priceOracle.getUnderlyingPrice(cToken) });
  }

  function cTokenUnderlyingPriceAll(CToken[] calldata cTokens) external returns (CTokenUnderlyingPrice[] memory) {
    uint256 cTokenCount = cTokens.length;
    CTokenUnderlyingPrice[] memory res = new CTokenUnderlyingPrice[](cTokenCount);
    for (uint256 i = 0; i < cTokenCount; i++) {
      res[i] = cTokenUnderlyingPrice(cTokens[i]);
    }
    return res;
  }

  struct AccountLimits {
    CToken[] markets;
    uint256 liquidity;
    uint256 shortfall;
  }

  function getAccountLimits(ComptrollerLensInterface comptroller, address account) public returns (AccountLimits memory) {
    (uint256 errorCode, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(account);
    require(errorCode == 0);

    return AccountLimits({ markets: comptroller.getAssetsIn(account), liquidity: liquidity, shortfall: shortfall });
  }

  struct GovReceipt {
    uint256 proposalId;
    bool hasVoted;
    bool support;
    uint96 votes;
  }

  function getGovReceipts(
    GovernorAlpha governor,
    address voter,
    uint256[] memory proposalIds
  ) public view returns (GovReceipt[] memory) {
    uint256 proposalCount = proposalIds.length;
    GovReceipt[] memory res = new GovReceipt[](proposalCount);
    for (uint256 i = 0; i < proposalCount; i++) {
      GovernorAlpha.Receipt memory receipt = governor.getReceipt(proposalIds[i], voter);
      res[i] = GovReceipt({ proposalId: proposalIds[i], hasVoted: receipt.hasVoted, support: receipt.support, votes: receipt.votes });
    }
    return res;
  }

  struct GovBravoReceipt {
    uint256 proposalId;
    bool hasVoted;
    uint8 support;
    uint96 votes;
  }

  function getGovBravoReceipts(
    GovernorBravoInterface governor,
    address voter,
    uint256[] memory proposalIds
  ) public view returns (GovBravoReceipt[] memory) {
    uint256 proposalCount = proposalIds.length;
    GovBravoReceipt[] memory res = new GovBravoReceipt[](proposalCount);
    for (uint256 i = 0; i < proposalCount; i++) {
      GovernorBravoInterface.Receipt memory receipt = governor.getReceipt(proposalIds[i], voter);
      res[i] = GovBravoReceipt({ proposalId: proposalIds[i], hasVoted: receipt.hasVoted, support: receipt.support, votes: receipt.votes });
    }
    return res;
  }

  struct GovProposal {
    uint256 proposalId;
    address proposer;
    uint256 eta;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    bool canceled;
    bool executed;
  }

  function setProposal(
    GovProposal memory res,
    GovernorAlpha governor,
    uint256 proposalId
  ) internal view {
    (, address proposer, uint256 eta, uint256 startBlock, uint256 endBlock, uint256 forVotes, uint256 againstVotes, bool canceled, bool executed) = governor
      .proposals(proposalId);
    res.proposalId = proposalId;
    res.proposer = proposer;
    res.eta = eta;
    res.startBlock = startBlock;
    res.endBlock = endBlock;
    res.forVotes = forVotes;
    res.againstVotes = againstVotes;
    res.canceled = canceled;
    res.executed = executed;
  }

  function getGovProposals(GovernorAlpha governor, uint256[] calldata proposalIds) external view returns (GovProposal[] memory) {
    GovProposal[] memory res = new GovProposal[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      (address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas) = governor.getActions(proposalIds[i]);
      res[i] = GovProposal({
        proposalId: 0,
        proposer: address(0),
        eta: 0,
        targets: targets,
        values: values,
        signatures: signatures,
        calldatas: calldatas,
        startBlock: 0,
        endBlock: 0,
        forVotes: 0,
        againstVotes: 0,
        canceled: false,
        executed: false
      });
      setProposal(res[i], governor, proposalIds[i]);
    }
    return res;
  }

  struct GovBravoProposal {
    uint256 proposalId;
    address proposer;
    uint256 eta;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
    bool canceled;
    bool executed;
  }

  function setBravoProposal(
    GovBravoProposal memory res,
    GovernorBravoInterface governor,
    uint256 proposalId
  ) internal view {
    GovernorBravoInterface.Proposal memory p = governor.proposals(proposalId);

    res.proposalId = proposalId;
    res.proposer = p.proposer;
    res.eta = p.eta;
    res.startBlock = p.startBlock;
    res.endBlock = p.endBlock;
    res.forVotes = p.forVotes;
    res.againstVotes = p.againstVotes;
    res.abstainVotes = p.abstainVotes;
    res.canceled = p.canceled;
    res.executed = p.executed;
  }

  function getGovBravoProposals(GovernorBravoInterface governor, uint256[] calldata proposalIds) external view returns (GovBravoProposal[] memory) {
    GovBravoProposal[] memory res = new GovBravoProposal[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      (address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas) = governor.getActions(proposalIds[i]);
      res[i] = GovBravoProposal({
        proposalId: 0,
        proposer: address(0),
        eta: 0,
        targets: targets,
        values: values,
        signatures: signatures,
        calldatas: calldatas,
        startBlock: 0,
        endBlock: 0,
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        canceled: false,
        executed: false
      });
      setBravoProposal(res[i], governor, proposalIds[i]);
    }
    return res;
  }

  struct CompBalanceMetadata {
    uint256 balance;
    uint256 votes;
    address delegate;
  }

  function getCompBalanceMetadata(Comp comp, address account) external view returns (CompBalanceMetadata memory) {
    return CompBalanceMetadata({ balance: comp.balanceOf(account), votes: uint256(comp.getCurrentVotes(account)), delegate: comp.delegates(account) });
  }

  struct CompBalanceMetadataExt {
    uint256 balance;
    uint256 votes;
    address delegate;
    uint256 allocated;
  }

  function getCompBalanceMetadataExt(
    Comp comp,
    ComptrollerLensInterface comptroller,
    address account
  ) external returns (CompBalanceMetadataExt memory) {
    uint256 balance = comp.balanceOf(account);
    comptroller.claimComp(account);
    uint256 newBalance = comp.balanceOf(account);
    uint256 accrued = comptroller.compAccrued(account);
    uint256 total = add(accrued, newBalance, "sum comp total");
    uint256 allocated = sub(total, balance, "sub allocated");

    return CompBalanceMetadataExt({ balance: balance, votes: uint256(comp.getCurrentVotes(account)), delegate: comp.delegates(account), allocated: allocated });
  }

  struct CompVotes {
    uint256 blockNumber;
    uint256 votes;
  }

  function getCompVotes(
    Comp comp,
    address account,
    uint32[] calldata blockNumbers
  ) external view returns (CompVotes[] memory) {
    CompVotes[] memory res = new CompVotes[](blockNumbers.length);
    for (uint256 i = 0; i < blockNumbers.length; i++) {
      res[i] = CompVotes({ blockNumber: uint256(blockNumbers[i]), votes: uint256(comp.getPriorVotes(account, blockNumbers[i])) });
    }
    return res;
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function add(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract GovernorAlpha {
  /// @notice The name of this contract
  string public constant name = "Compound Governor Alpha";

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() public pure returns (uint256) {
    return 400000e18;
  } // 400,000 = 4% of Comp

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() public pure returns (uint256) {
    return 100000e18;
  } // 100,000 = 1% of Comp

  /// @notice The maximum number of actions that can be included in a proposal
  function proposalMaxOperations() public pure returns (uint256) {
    return 10;
  } // 10 actions

  /// @notice The delay before voting on a proposal may take place, once proposed
  function votingDelay() public pure returns (uint256) {
    return 1;
  } // 1 block

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() public pure virtual returns (uint256) {
    return 17280;
  } // ~3 days in blocks (assuming 15s blocks)

  /// @notice The address of the Compound Protocol Timelock
  TimelockInterface public timelock;

  /// @notice The address of the Compound governance token
  CompInterface public comp;

  /// @notice The address of the Governor Guardian
  address public guardian;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  struct Proposal {
    /// @notice Unique id for looking up a proposal
    uint256 id;
    /// @notice Creator of the proposal
    address proposer;
    /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    /// @notice the ordered list of target addresses for calls to be made
    address[] targets;
    /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    /// @notice The ordered list of function signatures to be called
    string[] signatures;
    /// @notice The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    /// @notice The block at which voting begins: holders must delegate their votes prior to this block
    uint256 startBlock;
    /// @notice The block at which voting ends: votes must be cast prior to this block
    uint256 endBlock;
    /// @notice Current number of votes in favor of this proposal
    uint256 forVotes;
    /// @notice Current number of votes in opposition to this proposal
    uint256 againstVotes;
    /// @notice Flag marking whether the proposal has been canceled
    bool canceled;
    /// @notice Flag marking whether the proposal has been executed
    bool executed;
    /// @notice Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;
    /// @notice Whether or not the voter supports the proposal
    bool support;
    /// @notice The number of votes the voter had, which were cast
    uint96 votes;
  }

  /// @notice Possible states that a proposal may be in
  enum ProposalState {
    Pending,
    Active,
    Canceled,
    Defeated,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startBlock,
    uint256 endBlock,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  constructor(
    address timelock_,
    address comp_,
    address guardian_
  ) public {
    timelock = TimelockInterface(timelock_);
    comp = CompInterface(comp_);
    guardian = guardian_;
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description
  ) public returns (uint256) {
    require(comp.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");
    require(
      targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
      "GovernorAlpha::propose: proposal function information arity mismatch"
    );
    require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
    require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

    uint256 latestProposalId = latestProposalIds[msg.sender];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
      require(
        proposersLatestProposalState != ProposalState.Pending,
        "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal"
      );
    }

    uint256 startBlock = add256(block.number, votingDelay());
    uint256 endBlock = add256(startBlock, votingPeriod());

    proposalCount++;
    uint256 proposalId = proposalCount;
    Proposal storage newProposal = proposals[proposalId];
    // This should never happen but add a check in case.
    require(newProposal.id == 0, "GovernorAlpha::propose: ProposalID collsion");
    newProposal.id = proposalId;
    newProposal.proposer = msg.sender;
    newProposal.eta = 0;
    newProposal.targets = targets;
    newProposal.values = values;
    newProposal.signatures = signatures;
    newProposal.calldatas = calldatas;
    newProposal.startBlock = startBlock;
    newProposal.endBlock = endBlock;
    newProposal.forVotes = 0;
    newProposal.againstVotes = 0;
    newProposal.canceled = false;
    newProposal.executed = false;

    latestProposalIds[newProposal.proposer] = newProposal.id;

    emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
    return newProposal.id;
  }

  function queue(uint256 proposalId) public {
    require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
    Proposal storage proposal = proposals[proposalId];
    uint256 eta = add256(block.timestamp, timelock.delay());
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
    }
    proposal.eta = eta;
    emit ProposalQueued(proposalId, eta);
  }

  function _queueOrRevert(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) internal {
    require(
      !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
      "GovernorAlpha::_queueOrRevert: proposal action already queued at eta"
    );
    timelock.queueTransaction(target, value, signature, data, eta);
  }

  function execute(uint256 proposalId) public payable {
    require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.executeTransaction{ value: proposal.values[i] }(
        proposal.targets[i],
        proposal.values[i],
        proposal.signatures[i],
        proposal.calldatas[i],
        proposal.eta
      );
    }
    emit ProposalExecuted(proposalId);
  }

  function cancel(uint256 proposalId) public {
    ProposalState state = state(proposalId);
    require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

    Proposal storage proposal = proposals[proposalId];
    require(
      msg.sender == guardian || comp.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(),
      "GovernorAlpha::cancel: proposer above threshold"
    );

    proposal.canceled = true;
    for (uint256 i = 0; i < proposal.targets.length; i++) {
      timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
    }

    emit ProposalCanceled(proposalId);
  }

  function getActions(uint256 proposalId)
    public
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    )
  {
    Proposal storage p = proposals[proposalId];
    return (p.targets, p.values, p.signatures, p.calldatas);
  }

  function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.number <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.number <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
      return ProposalState.Defeated;
    } else if (proposal.eta == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function castVote(uint256 proposalId, bool support) public {
    return _castVote(msg.sender, proposalId, support);
  }

  function castVoteBySig(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
    return _castVote(signatory, proposalId, support);
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal {
    require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
    uint96 votes = comp.getPriorVotes(voter, proposal.startBlock);

    if (support) {
      proposal.forVotes = add256(proposal.forVotes, votes);
    } else {
      proposal.againstVotes = add256(proposal.againstVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    emit VoteCast(voter, proposalId, support, votes);
  }

  function __acceptAdmin() public {
    require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
    timelock.acceptAdmin();
  }

  function __abdicate() public {
    require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
    guardian = address(0);
  }

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
    timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
  }

  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
    timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

interface TimelockInterface {
  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function acceptAdmin() external;

  function queuedTransactions(bytes32 hash) external view returns (bool);

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);
}

interface CompInterface {
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract Comp {
  /// @notice EIP-20 token name for this token
  string public constant name = "Bonded dAMM";

  /// @notice EIP-20 token symbol for this token
  string public constant symbol = "BDAMM";

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  /// @notice Total number of tokens in circulation
  uint256 public constant totalSupply = 25000000e18; // 25 million bdAMM

  /// @notice Allowance amounts on behalf of others
  mapping(address => mapping(address => uint96)) internal allowances;

  /// @notice Official record of token balances for each account
  mapping(address => uint96) internal balances;

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /**
   * @notice Construct a new Comp token
   * @param account The initial account to grant all the tokens
   */
  constructor(address account) public {
    balances[account] = uint96(totalSupply);
    emit Transfer(address(0), account, totalSupply);
  }

  /**
   * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
   * @param account The address of the account holding the funds
   * @param spender The address of the account spending the funds
   * @return The number of tokens approved
   */
  function allowance(address account, address spender) external view returns (uint256) {
    return allowances[account][spender];
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == type(uint256).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "BDAMM::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Get the number of tokens held by the `account`
   * @param account The address of the account to get the balance of
   * @return The number of tokens held
   */
  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "BDAMM::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "BDAMM::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != type(uint96).max) {
      uint96 newAllowance = sub96(spenderAllowance, amount, "BDAMM::transferFrom: transfer amount exceeds spender allowance");
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "BDAMM::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "BDAMM::delegateBySig: invalid nonce");
    require(block.timestamp <= expiry, "BDAMM::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
   * @notice Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
    require(blockNumber < block.number, "BDAMM::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(
    address src,
    address dst,
    uint96 amount
  ) internal {
    require(src != address(0), "BDAMM::_transferTokens: cannot transfer from the zero address");
    require(dst != address(0), "BDAMM::_transferTokens: cannot transfer to the zero address");

    balances[src] = sub96(balances[src], amount, "BDAMM::_transferTokens: transfer amount exceeds balance");
    balances[dst] = add96(balances[dst], amount, "BDAMM::_transferTokens: transfer amount overflows");
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint96 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "BDAMM::_moveVotes: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "BDAMM::_moveVotes: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint96 oldVotes,
    uint96 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, "BDAMM::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";
import "./ErrorReporter.sol";
import "./PriceOracle.sol";
import "./ComptrollerInterface.sol";
import "./ComptrollerStorage.sol";
import "./Unitroller.sol";
import "./Governance/Comp.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
contract ComptrollerG7 is ComptrollerV5Storage, ComptrollerInterface, ComptrollerErrorReporter, ExponentialNoError {
    /// @notice Emitted when an admin supports a market
    event MarketListed(CToken cToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(CToken cToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(CToken cToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(CToken cToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(CToken cToken, string action, bool pauseState);

    /// @notice Emitted when a new COMP speed is calculated for a market
    event CompSpeedUpdated(CToken indexed cToken, uint newSpeed);

    /// @notice Emitted when a new COMP speed is set for a contributor
    event ContributorCompSpeedUpdated(address indexed contributor, uint newSpeed);

    /// @notice Emitted when COMP is distributed to a supplier
    event DistributedSupplierComp(CToken indexed cToken, address indexed supplier, uint compDelta, uint compSupplyIndex);

    /// @notice Emitted when COMP is distributed to a borrower
    event DistributedBorrowerComp(CToken indexed cToken, address indexed borrower, uint compDelta, uint compBorrowIndex);

    /// @notice Emitted when borrow cap for a cToken is changed
    event NewBorrowCap(CToken indexed cToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    /// @notice Emitted when new borrower is whitelisted
    event BorrowerWhitelisted(address borrower);

    /// @notice Emitted when borrower's limits are changed
    event BorrowerLimitChanged(address borrower, uint256 borrowLimit);

    /// @notice Emitted when COMP is granted by admin
    event CompGranted(address recipient, uint amount);

    /// @notice The initial COMP index for a market
    uint224 public constant compInitialIndex = 1e36;

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    address private _compAddress;

    constructor(address compAddress) public {
        _compAddress = compAddress;
        admin = msg.sender;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (CToken[] memory) {
        CToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param cToken The cToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, CToken cToken) external view returns (bool) {
        return markets[address(cToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param cTokens The list of addresses of the cToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory cTokens) override public returns (uint[] memory) {
        uint len = cTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            CToken cToken = CToken(cTokens[i]);

            results[i] = uint(addToMarketInternal(cToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param cToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(CToken cToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(cToken)];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(cToken);

        emit MarketEntered(cToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param cTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address cTokenAddress) override external returns (uint) {
        CToken cToken = CToken(cTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the cToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = cToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(cTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(cToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set cToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete cToken from the account’s list of assets */
        // load into memory for faster iteration
        CToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == cToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        CToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(cToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param cToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address cToken, address minter, uint mintAmount) override external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[cToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(cToken);
        distributeSupplierComp(cToken, minter);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param cToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(address cToken, address minter, uint actualMintAmount, uint mintTokens) override external {
        // Shh - currently unused
        cToken;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param cToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of cTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) override external returns (uint) {
        uint allowed = redeemAllowedInternal(cToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(cToken);
        distributeSupplierComp(cToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address cToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[cToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param cToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) override external {
        // Shh - currently unused
        cToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    function whitelistBorrowerAdd(address borrower) public override returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_BORROWER_LIMIT_CHECK);
        }

        borrowerArray[borrower] = true;
        borrowLimit[borrower] = 0;

        emit BorrowerWhitelisted(borrower);


        return 0;
    }

    //Sets the notional limit of borrows for an address
    function setBorrowerLimits(address borrower, uint256 _borrowLimit) public override returns (uint) {
        if (msg.sender != admin || borrowerArray[borrower] != true) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_BORROWER_LIMIT_CHECK);
        }
        borrowLimit[borrower] = _borrowLimit;

        emit BorrowerLimitChanged(borrower, _borrowLimit);

        return (_borrowLimit);
    }

    //Returns the notional value of borrows allowed for a borrower
    function getBorrowerLimits(address borrower) public override view returns (uint256) {
        require(borrowerArray[borrower] == true, "Address not permitted to borrow");
        return borrowLimit[borrower];
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param cToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address cToken, address borrower, uint borrowAmount) override external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[cToken], "borrow is paused");

        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!markets[cToken].accountMembership[borrower]) {
            // only cTokens may call borrowAllowed if borrower not in market
            require(msg.sender == cToken, "sender must be cToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(CToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[cToken].accountMembership[borrower]);
        }

        if (oracle.getUnderlyingPrice(CToken(cToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        uint borrowCap = borrowCaps[cToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = CToken(cToken).totalBorrows();
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, CToken(cToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }

        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: CToken(cToken).borrowIndex()});
        updateCompBorrowIndex(cToken, borrowIndex);
        distributeBorrowerComp(cToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param cToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(address cToken, address borrower, uint borrowAmount) override external {
        // Shh - currently unused
        cToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param cToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) override external returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[cToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: CToken(cToken).borrowIndex()});
        updateCompBorrowIndex(cToken, borrowIndex);
        distributeBorrowerComp(cToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param cToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint actualRepayAmount,
        uint borrowerIndex) override external {
        // Shh - currently unused
        cToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) override external returns (uint) {
        // Shh - currently unused
        liquidator;

        if (!markets[cTokenBorrowed].isListed || !markets[cTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance = CToken(cTokenBorrowed).borrowBalanceStored(borrower);
        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint actualRepayAmount,
        uint seizeTokens) override external {
        // Shh - currently unused
        cTokenBorrowed;
        cTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) override external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[cTokenCollateral].isListed || !markets[cTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (CToken(cTokenCollateral).comptroller() != CToken(cTokenBorrowed).comptroller()) {
            return uint(Error.COMPTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(cTokenCollateral);
        distributeSupplierComp(cTokenCollateral, borrower);
        distributeSupplierComp(cTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param cTokenCollateral Asset which was used as collateral and will be seized
     * @param cTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) override external {
        // Shh - currently unused
        cTokenCollateral;
        cTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param cToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of cTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(address cToken, address src, address dst, uint transferTokens) override external returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(cToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateCompSupplyIndex(cToken);
        distributeSupplierComp(cToken, src);
        distributeSupplierComp(cToken, dst);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param cToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of cTokens to transfer
     */
    function transferVerify(address cToken, address src, address dst, uint transferTokens) override external {
        // Shh - currently unused
        cToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `cTokenBalance` is the number of cTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint cTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, CToken(address(0)), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, CToken(address(0)), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, CToken(cTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral cToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        CToken cTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        CToken[] memory assets = accountAssets[account];

        /*
          Start with an assumed collateral value equal to the borrower limit. This sets a baseline for determining
          whether borrows and redemptions should be allowed
        */
        vars.sumCollateral = borrowLimit[account];

        for (uint i = 0; i < assets.length; i++) {
            CToken asset = assets[i];

            // Read the balances and exchange rate from the cToken
            (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * cTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.cTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with cTokenModify
            if (asset == cTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in cToken.liquidateBorrowFresh)
     * @param cTokenBorrowed The address of the borrowed cToken
     * @param cTokenCollateral The address of the collateral cToken
     * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
     * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint actualRepayAmount) override external view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(CToken(cTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(CToken(cTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint exchangeRateMantissa = CToken(cTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the comptroller
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
        require(msg.sender == admin, "only admin can set close factor");

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param cToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(CToken cToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(cToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(cToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(cToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param cToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(CToken cToken) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[address(cToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        cToken.isCToken(); // Sanity check to make sure its really a CToken

        // Note that isComped is not in active use anymore
        Market storage market = markets[address(cToken)];
        market.isListed = true;
        market.isComped = false;
        market.collateralFactorMantissa = 0;

        _addMarketInternal(address(cToken));

        emit MarketListed(cToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address cToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != CToken(cToken), "market already added");
        }
        allMarkets.push(CToken(cToken));
    }


    /**
      * @notice Set the given borrow caps for the given cToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param cTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(CToken[] calldata cTokens, uint[] calldata newBorrowCaps) external {
        require(msg.sender == admin || msg.sender == borrowCapGuardian, "only admin or borrow cap guardian can set borrow caps");

        uint numMarkets = cTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for(uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(cTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(cTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external {
        require(msg.sender == admin, "only admin can set borrow cap guardian");

        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;

        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;

        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _setMintPaused(CToken cToken, bool state) public returns (bool) {
        require(markets[address(cToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        mintGuardianPaused[address(cToken)] = state;
        emit ActionPaused(cToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(CToken cToken, bool state) public returns (bool) {
        require(markets[address(cToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        borrowGuardianPaused[address(cToken)] = state;
        emit ActionPaused(cToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || state == true, "only admin can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "only unitroller admin can change brains");
        require(unitroller._acceptImplementation() == 0, "change not authorized");
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }

    /*** Comp Distribution ***/

    /**
     * @notice Set COMP speed for a single market
     * @param cToken The market whose COMP speed to update
     * @param compSpeed New COMP speed for market
     */
    function setCompSpeedInternal(CToken cToken, uint compSpeed) internal {
        uint currentCompSpeed = compSpeeds[address(cToken)];
        if (currentCompSpeed != 0) {
            // note that COMP speed could be set to 0 to halt liquidity rewards for a market
            Exp memory borrowIndex = Exp({mantissa: cToken.borrowIndex()});
            updateCompSupplyIndex(address(cToken));
            updateCompBorrowIndex(address(cToken), borrowIndex);
        } else if (compSpeed != 0) {
            // Add the COMP market
            Market storage market = markets[address(cToken)];
            require(market.isListed == true, "comp market is not listed");

            if (compSupplyState[address(cToken)].index == 0 && compSupplyState[address(cToken)].block == 0) {
                compSupplyState[address(cToken)] = CompMarketState({
                    index: compInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }

            if (compBorrowState[address(cToken)].index == 0 && compBorrowState[address(cToken)].block == 0) {
                compBorrowState[address(cToken)] = CompMarketState({
                    index: compInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }
        }

        if (currentCompSpeed != compSpeed) {
            compSpeeds[address(cToken)] = compSpeed;
            emit CompSpeedUpdated(cToken, compSpeed);
        }
    }

    /**
     * @notice Accrue COMP to the market by updating the supply index
     * @param cToken The market whose supply index to update
     */
    function updateCompSupplyIndex(address cToken) internal {
        CompMarketState storage supplyState = compSupplyState[cToken];
        uint supplySpeed = compSpeeds[cToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = CToken(cToken).totalSupply();
            uint compAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(compAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            compSupplyState[cToken] = CompMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Accrue COMP to the market by updating the borrow index
     * @param cToken The market whose borrow index to update
     */
    function updateCompBorrowIndex(address cToken, Exp memory marketBorrowIndex) internal {
        CompMarketState storage borrowState = compBorrowState[cToken];
        uint borrowSpeed = compSpeeds[cToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(CToken(cToken).totalBorrows(), marketBorrowIndex);
            uint compAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(compAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            compBorrowState[cToken] = CompMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Calculate COMP accrued by a supplier and possibly transfer it to them
     * @param cToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute COMP to
     */
    function distributeSupplierComp(address cToken, address supplier) internal {
        CompMarketState storage supplyState = compSupplyState[cToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: compSupplierIndex[cToken][supplier]});
        compSupplierIndex[cToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = compInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = CToken(cToken).balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(compAccrued[supplier], supplierDelta);
        compAccrued[supplier] = supplierAccrued;
        emit DistributedSupplierComp(CToken(cToken), supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate COMP accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param cToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute COMP to
     */
    function distributeBorrowerComp(address cToken, address borrower, Exp memory marketBorrowIndex) internal {
        CompMarketState storage borrowState = compBorrowState[cToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: compBorrowerIndex[cToken][borrower]});
        compBorrowerIndex[cToken][borrower] = borrowIndex.mantissa;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(CToken(cToken).borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(compAccrued[borrower], borrowerDelta);
            compAccrued[borrower] = borrowerAccrued;
            emit DistributedBorrowerComp(CToken(cToken), borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Calculate additional accrued COMP for a contributor since last accrual
     * @param contributor The address to calculate contributor rewards for
     */
    function updateContributorRewards(address contributor) public {
        uint compSpeed = compContributorSpeeds[contributor];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && compSpeed > 0) {
            uint newAccrued = mul_(deltaBlocks, compSpeed);
            uint contributorAccrued = add_(compAccrued[contributor], newAccrued);

            compAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;
        }
    }

    /**
     * @notice Claim all the comp accrued by holder in all markets
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) public {
        return claimComp(holder, allMarkets);
    }

    /**
     * @notice Claim all the comp accrued by holder in the specified markets
     * @param holder The address to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     */
    function claimComp(address holder, CToken[] memory cTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimComp(holders, cTokens, true, true);
    }

    /**
     * @notice Claim all comp accrued by the holders
     * @param holders The addresses to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     * @param borrowers Whether or not to claim COMP earned by borrowing
     * @param suppliers Whether or not to claim COMP earned by supplying
     */
    function claimComp(address[] memory holders, CToken[] memory cTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < cTokens.length; i++) {
            CToken cToken = cTokens[i];
            require(markets[address(cToken)].isListed, "market must be listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa: cToken.borrowIndex()});
                updateCompBorrowIndex(address(cToken), borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerComp(address(cToken), holders[j], borrowIndex);
                    compAccrued[holders[j]] = grantCompInternal(holders[j], compAccrued[holders[j]]);
                }
            }
            if (suppliers == true) {
                updateCompSupplyIndex(address(cToken));
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierComp(address(cToken), holders[j]);
                    compAccrued[holders[j]] = grantCompInternal(holders[j], compAccrued[holders[j]]);
                }
            }
        }
    }

    /**
     * @notice Transfer COMP to the user
     * @dev Note: If there is not enough COMP, we do not perform the transfer all.
     * @param user The address of the user to transfer COMP to
     * @param amount The amount of COMP to (possibly) transfer
     * @return The amount of COMP which was NOT transferred to the user
     */
    function grantCompInternal(address user, uint amount) internal returns (uint) {
        Comp comp = Comp(getCompAddress());
        uint compRemaining = comp.balanceOf(address(this));
        if (amount > 0 && amount <= compRemaining) {
            comp.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    /*** Comp Distribution Admin ***/

    /**
     * @notice Transfer COMP to the recipient
     * @dev Note: If there is not enough COMP, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer COMP to
     * @param amount The amount of COMP to (possibly) transfer
     */
    function _grantComp(address recipient, uint amount) public {
        require(adminOrInitializing(), "only admin can grant comp");
        uint amountLeft = grantCompInternal(recipient, amount);
        require(amountLeft == 0, "insufficient comp for grant");
        emit CompGranted(recipient, amount);
    }

    /**
     * @notice Set COMP speed for a single market
     * @param cToken The market whose COMP speed to update
     * @param compSpeed New COMP speed for market
     */
    function _setCompSpeed(CToken cToken, uint compSpeed) public {
        require(adminOrInitializing(), "only admin can set comp speed");
        setCompSpeedInternal(cToken, compSpeed);
    }

    /**
     * @notice Set COMP speed for a single contributor
     * @param contributor The contributor whose COMP speed to update
     * @param compSpeed New COMP speed for contributor
     */
    function _setContributorCompSpeed(address contributor, uint compSpeed) public {
        require(adminOrInitializing(), "only admin can set comp speed");

        // note that COMP speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (compSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        compContributorSpeeds[contributor] = compSpeed;

        emit ContributorCompSpeedUpdated(contributor, compSpeed);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (CToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the COMP token
     * @return The address of COMP
     */
    function getCompAddress() public view returns (address) {
        return _compAddress;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";
import "./PriceOracle.sol";

contract UnitrollerAdminStorage {
  /**
   * @notice Administrator for this contract
   */
  address public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address public pendingAdmin;

  /**
   * @notice Active brains of Unitroller
   */
  address public comptrollerImplementation;

  /**
   * @notice Pending brains of Unitroller
   */
  address public pendingComptrollerImplementation;
}

contract ComptrollerV1Storage is UnitrollerAdminStorage {
  /**
   * @notice Oracle which gives the price of any given asset
   */
  PriceOracle public oracle;

  /**
   * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
   */
  uint256 public closeFactorMantissa;

  /**
   * @notice Multiplier representing the discount on collateral that a liquidator receives
   */
  uint256 public liquidationIncentiveMantissa;

  /**
   * @notice Max number of assets a single account can participate in (borrow or use as collateral)
   */
  uint256 public maxAssets;

  /**
   * @notice Per-account mapping of "assets you are in", capped by maxAssets
   */
  mapping(address => CToken[]) public accountAssets;

  mapping(address => bool) public borrowerArray;

  mapping(address => uint256) public borrowLimit;
}

contract ComptrollerV2Storage is ComptrollerV1Storage {
  struct Market {
    // Whether or not this market is listed
    bool isListed;
    //  Multiplier representing the most one can borrow against their collateral in this market.
    //  For instance, 0.9 to allow borrowing 90% of collateral value.
    //  Must be between 0 and 1, and stored as a mantissa.
    uint256 collateralFactorMantissa;
    // Per-market mapping of "accounts in this asset"
    mapping(address => bool) accountMembership;
    // Whether or not this market receives COMP
    bool isComped;
  }

  /**
   * @notice Official mapping of cTokens -> Market metadata
   * @dev Used e.g. to determine if a market is supported
   */
  mapping(address => Market) public markets;

  /**
   * @notice The Pause Guardian can pause certain actions as a safety mechanism.
   *  Actions which allow users to remove their own assets cannot be paused.
   *  Liquidation / seizing / transfer can only be paused globally, not by market.
   */
  address public pauseGuardian;
  bool public _mintGuardianPaused;
  bool public _borrowGuardianPaused;
  bool public transferGuardianPaused;
  bool public seizeGuardianPaused;
  mapping(address => bool) public mintGuardianPaused;
  mapping(address => bool) public borrowGuardianPaused;
}

contract ComptrollerV3Storage is ComptrollerV2Storage {
  struct CompMarketState {
    // The market's last updated compBorrowIndex or compSupplyIndex
    uint224 index;
    // The block number the index was last updated at
    uint32 block;
  }

  /// @notice A list of all markets
  CToken[] public allMarkets;

  /// @notice The rate at which the flywheel distributes COMP, per block
  uint256 public compRate;

  /// @notice The portion of compRate that each market currently receives
  mapping(address => uint256) public compSpeeds;

  /// @notice The COMP market supply state for each market
  mapping(address => CompMarketState) public compSupplyState;

  /// @notice The COMP market borrow state for each market
  mapping(address => CompMarketState) public compBorrowState;

  /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
  mapping(address => mapping(address => uint256)) public compSupplierIndex;

  /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
  mapping(address => mapping(address => uint256)) public compBorrowerIndex;

  /// @notice The COMP accrued but not yet transferred to each user
  mapping(address => uint256) public compAccrued;
}

contract ComptrollerV4Storage is ComptrollerV3Storage {
  // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
  address public borrowCapGuardian;

  // @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
  mapping(address => uint256) public borrowCaps;
}

contract ComptrollerV5Storage is ComptrollerV4Storage {
  /// @notice The portion of COMP that each contributor receives per block
  mapping(address => uint256) public compContributorSpeeds;

  /// @notice Last block at which a contributor's COMP rewards have been allocated
  mapping(address => uint256) public lastContributorBlock;
}

contract ComptrollerV6Storage is ComptrollerV5Storage {
  /// @notice The rate at which comp is distributed to the corresponding borrow market (per block)
  mapping(address => uint256) public compBorrowSpeeds;

  /// @notice The rate at which comp is distributed to the corresponding supply market (per block)
  mapping(address => uint256) public compSupplySpeeds;
}

contract ComptrollerV7Storage is ComptrollerV6Storage {
  /// @notice Flag indicating whether the function to fix COMP accruals has been executed (RE: proposal 62 bug)
  bool public proposal65FixExecuted;

  /// @notice Accounting storage mapping account addresses to how much COMP they owe the protocol.
  mapping(address => uint256) public compReceivable;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./ErrorReporter.sol";
import "./ComptrollerStorage.sol";

/**
 * @title ComptrollerCore
 * @dev Storage for the comptroller is at this address, while execution is delegated to the `comptrollerImplementation`.
 * CTokens should reference this contract as their comptroller.
 */
contract Unitroller is UnitrollerAdminStorage, ComptrollerErrorReporter {
  /**
   * @notice Emitted when pendingComptrollerImplementation is changed
   */
  event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

  /**
   * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Emitted _compAddress is initially set (when accepting the first comptroller implementation)
   */
  event NewCompAddress(address oldAddress, address newAddress);

  address private _compAddress;

  constructor() {
    // Set admin to caller
    admin = msg.sender;
  }

  /*** Admin Functions ***/
  function _setPendingImplementation(address newPendingImplementation) public returns (uint256) {
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
    }

    address oldPendingImplementation = pendingComptrollerImplementation;

    pendingComptrollerImplementation = newPendingImplementation;

    emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts new implementation of comptroller. msg.sender must be pendingImplementation
   * @dev Admin function for new implementation to accept it's role as implementation
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptImplementation() public returns (uint256) {
    // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
    if (msg.sender != pendingComptrollerImplementation || pendingComptrollerImplementation == address(0)) {
      return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
    }

    // Save current values for inclusion in log
    address oldImplementation = comptrollerImplementation;
    address oldPendingImplementation = pendingComptrollerImplementation;

    if (_compAddress == address(0)) {
      (bool success, bytes memory compAddress) = pendingComptrollerImplementation.call(abi.encodeWithSignature("getCompAddress()"));
      require(success, "failed at getCompAddress()");
      _compAddress = abi.decode(compAddress, (address));
      emit NewCompAddress(address(0), _compAddress);
    }

    comptrollerImplementation = pendingComptrollerImplementation;

    pendingComptrollerImplementation = address(0);

    emit NewImplementation(oldImplementation, comptrollerImplementation);
    emit NewPendingImplementation(oldPendingImplementation, pendingComptrollerImplementation);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address newPendingAdmin) public returns (uint256) {
    // Check caller = admin
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
    }

    // Save current value, if any, for inclusion in log
    address oldPendingAdmin = pendingAdmin;

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
    emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() public returns (uint256) {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = address(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @dev Delegates execution to an implementation contract.
   * It returns to the external caller whatever the implementation returns
   * or forwards reverts.
   */
  fallback() external payable {
    // delegate all other functions to current implementation
    (bool success, ) = comptrollerImplementation.delegatecall(msg.data);

    assembly {
      let free_mem_ptr := mload(0x40)
      returndatacopy(free_mem_ptr, 0, returndatasize())

      switch success
      case 0 {
        revert(free_mem_ptr, returndatasize())
      }
      default {
        return(free_mem_ptr, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CToken.sol";

/**
 * @title Compound's CEther Contract
 * @notice CToken which wraps Ether
 * @author Compound
 */
contract CEther is CToken {
  /**
   * @notice Construct a new CEther money market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  constructor(
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_
  ) {
    // Creator of the contract is admin during initialization
    admin = payable(msg.sender);

    initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

    // Set the proper admin now that initialization is done
    admin = admin_;
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Reverts upon any failure
   */
  function mint() external payable {
    mintInternal(msg.value);
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256) {
    redeemInternal(redeemTokens);
    return NO_ERROR;
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
    redeemUnderlyingInternal(redeemAmount);
    return NO_ERROR;
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external returns (uint256) {
    borrowInternal(borrowAmount);
    return NO_ERROR;
  }

  /**
   * @notice Sender repays their own borrow
   * @dev Reverts upon any failure
   */
  function repayBorrow() external payable {
    repayBorrowInternal(msg.value);
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @dev Reverts upon any failure
   * @param borrower the account with the debt being payed off
   */
  function repayBorrowBehalf(address borrower) external payable {
    repayBorrowBehalfInternal(borrower, msg.value);
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @dev Reverts upon any failure
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   */
  function liquidateBorrow(address borrower, CToken cTokenCollateral) external payable {
    liquidateBorrowInternal(borrower, msg.value, cTokenCollateral);
  }

  /**
   * @notice The sender adds to reserves.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves() external payable returns (uint256) {
    return _addReservesInternal(msg.value);
  }

  /**
   * @notice Send Ether to CEther to mint
   */
  receive() external payable {
    mintInternal(msg.value);
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of Ether, before this message
   * @dev This excludes the value of the current message, if any
   * @return The quantity of Ether owned by this contract
   */
  function getCashPrior() internal view override returns (uint256) {
    return address(this).balance - msg.value;
  }

  /**
   * @notice Perform the actual transfer in, which is a no-op
   * @param from Address sending the Ether
   * @param amount Amount of Ether being sent
   * @return The actual amount of Ether transferred
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    // Sanity checks
    require(msg.sender == from, "sender mismatch");
    require(msg.value == amount, "value mismatch");
    return amount;
  }

  function doTransferOut(address payable to, uint256 amount) internal virtual override {
    /* Send the Ether, with minimal gas and revert on failure */
    to.transfer(amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CEther.sol";

/**
 * @title Compound's Maximillion Contract
 * @author Compound
 */
contract Maximillion {
  /**
   * @notice The default cEther market to repay in
   */
  CEther public cEther;

  /**
   * @notice Construct a Maximillion to repay max in a CEther market
   */
  constructor(CEther cEther_) public {
    cEther = cEther_;
  }

  /**
   * @notice msg.sender sends Ether to repay an account's borrow in the cEther market
   * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
   * @param borrower The address of the borrower account to repay on behalf of
   */
  function repayBehalf(address borrower) public payable {
    repayBehalfExplicit(borrower, cEther);
  }

  /**
   * @notice msg.sender sends Ether to repay an account's borrow in a cEther market
   * @dev The provided Ether is applied towards the borrow balance, any excess is refunded
   * @param borrower The address of the borrower account to repay on behalf of
   * @param cEther_ The address of the cEther contract to repay in
   */
  function repayBehalfExplicit(address borrower, CEther cEther_) public payable {
    uint256 received = msg.value;
    uint256 borrows = cEther_.borrowBalanceCurrent(borrower);
    if (received > borrows) {
      cEther_.repayBorrowBehalf{ value: borrows }(borrower);
      payable(msg.sender).transfer(received - borrows);
    } else {
      cEther_.repayBorrowBehalf{ value: received }(borrower);
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./InterestRateModel.sol";

/**
 * @title Compound's WhitePaperInterestRateModel Contract
 * @author Compound
 * @notice The parameterized model described in section 2.4 of the original Compound Protocol whitepaper
 */
contract WhitePaperInterestRateModel is InterestRateModel {
  event NewInterestParams(uint256 baseRatePerBlock, uint256 multiplierPerBlock);

  uint256 private constant BASE = 1e18;

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2629800;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
   */
  constructor(uint256 baseRatePerYear, uint256 multiplierPerYear) public {
    baseRatePerBlock = baseRatePerYear / blocksPerYear;
    multiplierPerBlock = multiplierPerYear / blocksPerYear;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, BASE]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return (borrows * BASE) / (cash + borrows - reserves);
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by BASE)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    uint256 ur = utilizationRate(cash, borrows, reserves);
    return ((ur * multiplierPerBlock) / BASE) + baseRatePerBlock;
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by BASE)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = BASE - reserveFactorMantissa;
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / BASE;
    return (utilizationRate(cash, borrows, reserves) * rateToPool) / BASE;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./BaseJumpRateModelV2.sol";
import "./InterestRateModel.sol";

/**
 * @title Compound's JumpRateModel Contract V2 for V2 cTokens
 * @author Arr00
 * @notice Supports only for V2 cTokens
 */
contract JumpRateModelV2 is InterestRateModel, BaseJumpRateModelV2 {
  /**
   * @notice Calculates the current borrow rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view override returns (uint256) {
    return getBorrowRateInternal(cash, borrows, reserves);
  }

  constructor(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_,
    address owner_
  ) public BaseJumpRateModelV2(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_, owner_) {}
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./InterestRateModel.sol";

/**
 * @title Logic for Compound's JumpRateModel Contract V2.
 * @author Compound (modified by Dharma Labs, refactored by Arr00)
 * @notice Version 2 modifies Version 1 by enabling updateable parameters.
 */
abstract contract BaseJumpRateModelV2 is InterestRateModel {
  event NewInterestParams(uint256 baseRatePerBlock, uint256 multiplierPerBlock, uint256 jumpMultiplierPerBlock, uint256 kink);

  uint256 private constant BASE = 1e18;

  /**
   * @notice The address of the owner, i.e. the Timelock contract, which can update parameters directly
   */
  address public owner;

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2102400;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice The multiplierPerBlock after hitting a specified utilization point
   */
  uint256 public jumpMultiplierPerBlock;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public kink;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   * @param owner_ The address of the owner, i.e. the Timelock contract (which has the ability to update parameters directly)
   */
  constructor(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_,
    address owner_
  ) internal {
    owner = owner_;

    updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
  }

  /**
   * @notice Update the parameters of the interest rate model (only callable by owner, i.e. Timelock)
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  function updateJumpRateModel(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) external virtual {
    require(msg.sender == owner, "only the owner may call this function.");

    updateJumpRateModelInternal(baseRatePerYear, multiplierPerYear, jumpMultiplierPerYear, kink_);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, BASE]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return (borrows * BASE) / (cash + borrows - reserves);
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by BASE)
   */
  function getBorrowRateInternal(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) internal view returns (uint256) {
    uint256 util = utilizationRate(cash, borrows, reserves);

    if (util <= kink) {
      return ((util * multiplierPerBlock) / BASE) + baseRatePerBlock;
    } else {
      uint256 normalRate = ((kink * multiplierPerBlock) / BASE) + baseRatePerBlock;
      uint256 excessUtil = util - kink;
      return ((excessUtil * jumpMultiplierPerBlock) / BASE) + normalRate;
    }
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by BASE)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view virtual override returns (uint256) {
    uint256 oneMinusReserveFactor = BASE - reserveFactorMantissa;
    uint256 borrowRate = getBorrowRateInternal(cash, borrows, reserves);
    uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / BASE;
    return (utilizationRate(cash, borrows, reserves) * rateToPool) / BASE;
  }

  /**
   * @notice Internal function to update the parameters of the interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  function updateJumpRateModelInternal(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) internal {
    baseRatePerBlock = baseRatePerYear / blocksPerYear;
    multiplierPerBlock = (multiplierPerYear * BASE) / (blocksPerYear * kink_);
    jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;
    kink = kink_;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./InterestRateModel.sol";

/**
 * @title Compound's JumpRateModel Contract
 * @author Compound
 */
contract JumpRateModel is InterestRateModel {
  event NewInterestParams(uint256 baseRatePerBlock, uint256 multiplierPerBlock, uint256 jumpMultiplierPerBlock, uint256 kink);

  uint256 private constant BASE = 1e18;

  /**
   * @notice The approximate number of blocks per year that is assumed by the interest rate model
   */
  uint256 public constant blocksPerYear = 2629800;

  /**
   * @notice The multiplier of utilization rate that gives the slope of the interest rate
   */
  uint256 public multiplierPerBlock;

  /**
   * @notice The base interest rate which is the y-intercept when utilization rate is 0
   */
  uint256 public baseRatePerBlock;

  /**
   * @notice The multiplierPerBlock after hitting a specified utilization point
   */
  uint256 public jumpMultiplierPerBlock;

  /**
   * @notice The utilization point at which the jump multiplier is applied
   */
  uint256 public kink;

  /**
   * @notice Construct an interest rate model
   * @param baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
   * @param multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
   * @param jumpMultiplierPerYear The multiplierPerBlock after hitting a specified utilization point
   * @param kink_ The utilization point at which the jump multiplier is applied
   */
  constructor(
    uint256 baseRatePerYear,
    uint256 multiplierPerYear,
    uint256 jumpMultiplierPerYear,
    uint256 kink_
  ) public {
    baseRatePerBlock = baseRatePerYear / blocksPerYear;
    multiplierPerBlock = multiplierPerYear / blocksPerYear;
    jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;
    kink = kink_;

    emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
  }

  /**
   * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market (currently unused)
   * @return The utilization rate as a mantissa between [0, BASE]
   */
  function utilizationRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public pure returns (uint256) {
    // Utilization rate is 0 when there are no borrows
    if (borrows == 0) {
      return 0;
    }

    return (borrows * BASE) / (cash + borrows - reserves);
  }

  /**
   * @notice Calculates the current borrow rate per block, with the error code expected by the market
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @return The borrow rate percentage per block as a mantissa (scaled by BASE)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) public view override returns (uint256) {
    uint256 util = utilizationRate(cash, borrows, reserves);

    if (util <= kink) {
      return ((util * multiplierPerBlock) / BASE) + baseRatePerBlock;
    } else {
      uint256 normalRate = ((kink * multiplierPerBlock) / BASE) + baseRatePerBlock;
      uint256 excessUtil = util - kink;
      return ((excessUtil * jumpMultiplierPerBlock) / BASE) + normalRate;
    }
  }

  /**
   * @notice Calculates the current supply rate per block
   * @param cash The amount of cash in the market
   * @param borrows The amount of borrows in the market
   * @param reserves The amount of reserves in the market
   * @param reserveFactorMantissa The current reserve factor for the market
   * @return The supply rate percentage per block as a mantissa (scaled by BASE)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) public view override returns (uint256) {
    uint256 oneMinusReserveFactor = BASE - reserveFactorMantissa;
    uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
    uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / BASE;
    return (utilizationRate(cash, borrows, reserves) * rateToPool) / BASE;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CTokenInterfaces.sol";

/**
 * @title Compound's CErc20Delegator Contract
 * @notice CTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author Compound
 */
contract CErc20Delegator is CTokenInterface, CErc20Interface, CDelegatorInterface {
  /**
   * @notice Construct a new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   * @param implementation_ The address of the implementation the contract delegates to
   * @param becomeImplementationData The encoded args for becomeImplementation
   */
  constructor(
    address underlying_,
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    address implementation_,
    bytes memory becomeImplementationData
  ) {
    // Creator of the contract is admin during initialization
    admin = payable(msg.sender);

    // First delegate gets to initialize the delegator (i.e. storage contract)
    delegateTo(
      implementation_,
      abi.encodeWithSignature(
        "initialize(address,address,address,uint256,string,string,uint8)",
        underlying_,
        comptroller_,
        interestRateModel_,
        initialExchangeRateMantissa_,
        name_,
        symbol_,
        decimals_
      )
    );

    // New implementations always get set via the settor (post-initialize)
    _setImplementation(implementation_, false, becomeImplementationData);

    // Set the proper admin now that initialization is done
    admin = admin_;
  }

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) public override {
    require(msg.sender == admin, "CErc20Delegator::_setImplementation: Caller must be admin");

    if (allowResign) {
      delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
    }

    address oldImplementation = implementation;
    implementation = implementation_;

    delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

    emit NewImplementation(oldImplementation, implementation);
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("mint(uint256)", mintAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("redeem(uint256)", redeemTokens));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("redeemUnderlying(uint256)", redeemAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrow(uint256)", borrowAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay, or -1 for the full outstanding amount
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrow(uint256 repayAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("repayBorrow(uint256)", repayAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay, or -1 for the full outstanding amount
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", borrower, repayAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("liquidateBorrow(address,uint256,address)", borrower, repayAmount, cTokenCollateral));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external override returns (bool) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("transfer(address,uint256)", dst, amount));
    return abi.decode(data, (bool));
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external override returns (bool) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("transferFrom(address,address,uint256)", src, dst, amount));
    return abi.decode(data, (bool));
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("approve(address,uint256)", spender, amount));
    return abi.decode(data, (bool));
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("allowance(address,address)", owner, spender));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("balanceOf(address)", owner));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("balanceOfUnderlying(address)", owner));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by comptroller to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address account)
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getAccountSnapshot(address)", account));
    return abi.decode(data, (uint256, uint256, uint256, uint256));
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("borrowRatePerBlock()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("supplyRatePerBlock()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("totalBorrowsCurrent()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
   * @param account The address whose balance should be calculated after updating borrowIndex
   * @return The calculated balance
   */
  function borrowBalanceCurrent(address account) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("borrowBalanceCurrent(address)", account));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("borrowBalanceStored(address)", account));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("exchangeRateCurrent()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("exchangeRateStored()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view override returns (uint256) {
    bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("getCash()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves.
   * @dev This calculates interest accrued from the last checkpointed block
   *      up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("accrueInterest()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another cToken during the process of liquidation.
   *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("seize(address,address,uint256)", liquidator, borrower, seizeTokens));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
   * @param token The address of the ERC-20 token to sweep
   */
  function sweepToken(EIP20NonStandardInterface token) external override {
    delegateToImplementation(abi.encodeWithSignature("sweepToken(address)", token));
  }

  /*** Admin Functions ***/

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address payable newPendingAdmin) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setPendingAdmin(address)", newPendingAdmin));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Sets a new comptroller for the market
   * @dev Admin function to set a new comptroller
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setComptroller(ComptrollerInterface newComptroller) public override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setComptroller(address)", newComptroller));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(uint256 newReserveFactorMantissa) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setReserveFactor(uint256)", newReserveFactorMantissa));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_acceptAdmin()"));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrues interest and adds reserves by transferring from admin
   * @param addAmount Amount of reserves to add
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves(uint256 addAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_addReserves(uint256)", addAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReserves(uint256 reduceAmount) external override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_reduceReserves(uint256)", reduceAmount));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(InterestRateModel newInterestRateModel) public override returns (uint256) {
    bytes memory data = delegateToImplementation(abi.encodeWithSignature("_setInterestRateModel(address)", newInterestRateModel));
    return abi.decode(data, (uint256));
  }

  /**
   * @notice Internal method to delegate execution to another contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   * @param callee The contract to delegatecall
   * @param data The raw data to delegatecall
   * @return The returned bytes from the delegatecall
   */
  function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
    (bool success, bytes memory returnData) = callee.delegatecall(data);
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize())
      }
    }
    return returnData;
  }

  /**
   * @notice Delegates execution to the implementation contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   * @param data The raw data to delegatecall
   * @return The returned bytes from the delegatecall
   */
  function delegateToImplementation(bytes memory data) public returns (bytes memory) {
    return delegateTo(implementation, data);
  }

  /**
   * @notice Delegates execution to an implementation contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
   * @param data The raw data to delegatecall
   * @return The returned bytes from the delegatecall
   */
  function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
    (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
    assembly {
      if eq(success, 0) {
        revert(add(returnData, 0x20), returndatasize())
      }
    }
    return abi.decode(returnData, (bytes));
  }

  /**
   * @notice Delegates execution to an implementation contract
   * @dev It returns to the external caller whatever the implementation returns or forwards reverts
   */
  fallback() external payable {
    require(msg.value == 0, "CErc20Delegator:fallback: cannot send value to fallback");

    // delegate all other functions to current implementation
    (bool success, ) = implementation.delegatecall(msg.data);

    assembly {
      let free_mem_ptr := mload(0x40)
      returndatacopy(free_mem_ptr, 0, returndatasize())

      switch success
      case 0 {
        revert(free_mem_ptr, returndatasize())
      }
      default {
        return(free_mem_ptr, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Reservoir Contract
 * @notice Distributes a token to a different contract at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Compound
 */
contract Reservoir {
  /// @notice The block number when the Reservoir started (immutable)
  uint256 public dripStart;

  /// @notice Tokens per block that to drip to target (immutable)
  uint256 public dripRate;

  /// @notice Reference to token to drip (immutable)
  EIP20Interface public token;

  /// @notice Target to receive dripped tokens (immutable)
  address public target;

  /// @notice Amount that has already been dripped
  uint256 public dripped;

  /**
   * @notice Constructs a Reservoir
   * @param dripRate_ Numer of tokens per block to drip
   * @param token_ The token to drip
   * @param target_ The recipient of dripped tokens
   */
  constructor(
    uint256 dripRate_,
    EIP20Interface token_,
    address target_
  ) public {
    dripStart = block.number;
    dripRate = dripRate_;
    token = token_;
    target = target_;
    dripped = 0;
  }

  /**
   * @notice Drips the maximum amount of tokens to match the drip rate since inception
   * @dev Note: this will only drip up to the amount of tokens available.
   * @return The amount of tokens dripped in this call
   */
  function drip() public returns (uint256) {
    // First, read storage into memory
    EIP20Interface token_ = token;
    uint256 reservoirBalance_ = token_.balanceOf(address(this)); // TODO: Verify this is a static call
    uint256 dripRate_ = dripRate;
    uint256 dripStart_ = dripStart;
    uint256 dripped_ = dripped;
    address target_ = target;
    uint256 blockNumber_ = block.number;

    // Next, calculate intermediate values
    uint256 dripTotal_ = mul(dripRate_, blockNumber_ - dripStart_, "dripTotal overflow");
    uint256 deltaDrip_ = sub(dripTotal_, dripped_, "deltaDrip underflow");
    uint256 toDrip_ = min(reservoirBalance_, deltaDrip_);
    uint256 drippedNext_ = add(dripped_, toDrip_, "tautological");

    // Finally, write new `dripped` value and transfer tokens to target
    dripped = drippedNext_;
    token_.transfer(target_, toDrip_);

    return toDrip_;
  }

  /* Internal helper functions for safe math */

  function add(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c;
    unchecked {
      c = a + b;
    }
    require(c >= a, errorMessage);
    return c;
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c;
    unchecked {
      c = a * b;
    }
    require(c / a == b, errorMessage);
    return c;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }
}

import "./EIP20Interface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./EIP20Interface.sol";
import "./openzeppelin/Ownable.sol";

contract Faucet is Ownable {
  event Funded(address fundee, EIP20Interface token, uint256 amount);
  event SkippingFundingAlreadyFunded(address fundee, EIP20Interface token, uint256 currentBalance);
  event SkippingFundingFaucetDry(address fundee, EIP20Interface token, uint256 faucetBalance);
  mapping(address => bool) public fundees;
  EIP20Interface[] public supportedTokens;

  constructor(EIP20Interface[] memory tokens) {
    supportedTokens = tokens;
  }

  function tap() external {
    address fundee = tx.origin;
    require(!fundees[fundee], "account has already been funded");
    fundees[fundee] = true;
    _seed(fundee, supportedTokens);
  }

  /*
    Allows Faucet owner to fund a fundee that has previously been funded (and therefor won't be
    to call `tap()`)
  */
  function seed(address fundee) external onlyOwner {
    _seed(fundee, supportedTokens);
  }

  function _seed(address fundee, EIP20Interface[] memory tokens) internal {
    for (uint i = 0; i < tokens.length; i += 1) {
      EIP20Interface token = tokens[i];
      /*
        Don't attempt to fund USDT; it isn't ERC20 conformant and will break the seed call because
        transfer doesn't return a bool
      */
      if (
        keccak256(abi.encodePacked(token.symbol())) != keccak256(abi.encodePacked("USDT"))
      ) {

        uint256 amount = 1000 * (10 ** (token.decimals()));
        uint256 faucetBalance = token.balanceOf(address(this));
        uint256 fundeeBalance = token.balanceOf(fundee);
        if (fundeeBalance >= amount) {
          emit SkippingFundingAlreadyFunded(fundee, token, fundeeBalance);
        } else if (faucetBalance < amount) {
          emit SkippingFundingFaucetDry(fundee, token, faucetBalance);
        } else {
          require(token.transfer(fundee, amount), "something went wrong with token transfer");
          emit Funded(fundee, token, amount);
        }

      }
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CErc20.sol";

/**
 * @title Compound's CErc20Immutable Contract
 * @notice CTokens which wrap an EIP-20 underlying and are immutable
 * @author Compound
 */
contract CErc20Immutable is CErc20 {
  /**
   * @notice Construct a new money market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   */
  constructor(
    address underlying_,
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_
  ) {
    // Creator of the contract is admin during initialization
    admin = payable(msg.sender);

    // Initialize the market
    initialize(underlying_, comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

    // Set the proper admin now that initialization is done
    admin = admin_;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CErc20.sol";

/**
 * @title Compound's CErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Compound
 */
contract CErc20Delegate is CErc20, CDelegateInterface {
  /**
   * @notice Construct an empty delegate
   */
  constructor() {}

  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) public virtual override {
    // Shh -- currently unused
    data;

    // Shh -- we don't ever want this hook to be marked pure
    if (false) {
      implementation = address(0);
    }

    require(msg.sender == admin, "only the admin may call _becomeImplementation");
  }

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() public virtual override {
    // Shh -- we don't ever want this hook to be marked pure
    if (false) {
      implementation = address(0);
    }

    require(msg.sender == admin, "only the admin may call _resignImplementation");
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./CErc20Delegate.sol";

/**
 * @title Compound's CDai Contract
 * @notice CToken which wraps Multi-Collateral DAI
 * @author Compound
 */
contract CDaiDelegate is CErc20Delegate {
  /**
   * @notice DAI adapter address
   */
  address public daiJoinAddress;

  /**
   * @notice DAI Savings Rate (DSR) pot address
   */
  address public potAddress;

  /**
   * @notice DAI vat address
   */
  address public vatAddress;

  /**
   * @notice Delegate interface to become the implementation
   * @param data The encoded arguments for becoming
   */
  function _becomeImplementation(bytes memory data) public override {
    require(msg.sender == admin, "only the admin may initialize the implementation");

    (address daiJoinAddress_, address potAddress_) = abi.decode(data, (address, address));
    return _becomeImplementation(daiJoinAddress_, potAddress_);
  }

  /**
   * @notice Explicit interface to become the implementation
   * @param daiJoinAddress_ DAI adapter address
   * @param potAddress_ DAI Savings Rate (DSR) pot address
   */
  function _becomeImplementation(address daiJoinAddress_, address potAddress_) internal {
    // Get dai and vat and sanity check the underlying
    DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress_);
    PotLike pot = PotLike(potAddress_);
    GemLike dai = daiJoin.dai();
    VatLike vat = daiJoin.vat();
    require(address(dai) == underlying, "DAI must be the same as underlying");

    // Remember the relevant addresses
    daiJoinAddress = daiJoinAddress_;
    potAddress = potAddress_;
    vatAddress = address(vat);

    // Approve moving our DAI into the vat through daiJoin
    dai.approve(daiJoinAddress, type(uint256).max);

    // Approve the pot to transfer our funds within the vat
    vat.hope(potAddress);
    vat.hope(daiJoinAddress);

    // Accumulate DSR interest -- must do this in order to doTransferIn
    pot.drip();

    // Transfer all cash in (doTransferIn does this regardless of amount)
    doTransferIn(address(this), 0);
  }

  /**
   * @notice Delegate interface to resign the implementation
   */
  function _resignImplementation() public override {
    require(msg.sender == admin, "only the admin may abandon the implementation");

    // Transfer all cash out of the DSR - note that this relies on self-transfer
    DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress);
    PotLike pot = PotLike(potAddress);
    VatLike vat = VatLike(vatAddress);

    // Accumulate interest
    pot.drip();

    // Calculate the total amount in the pot, and move it out
    uint256 pie = pot.pie(address(this));
    pot.exit(pie);

    // Checks the actual balance of DAI in the vat after the pot exit
    uint256 bal = vat.dai(address(this));

    // Remove our whole balance
    daiJoin.exit(address(this), bal / RAY);
  }

  /*** CToken Overrides ***/

  /**
   * @notice Accrues DSR then applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   *      up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public override returns (uint256) {
    // Accumulate DSR interest
    PotLike(potAddress).drip();

    // Accumulate CToken interest
    return super.accrueInterest();
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view override returns (uint256) {
    PotLike pot = PotLike(potAddress);
    uint256 pie = pot.pie(address(this));
    return mul(pot.chi(), pie) / RAY;
  }

  /**
   * @notice Transfer the underlying to this contract and sweep into DSR pot
   * @param from Address to transfer funds from
   * @param amount Amount of underlying to transfer
   * @return The actual amount that is transferred
   */
  function doTransferIn(address from, uint256 amount) internal override returns (uint256) {
    // Read from storage once
    address underlying_ = underlying;
    // Perform the EIP-20 transfer in
    EIP20Interface token = EIP20Interface(underlying_);
    require(token.transferFrom(from, address(this), amount), "unexpected EIP-20 transfer in return");

    DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress);
    GemLike dai = GemLike(underlying_);
    PotLike pot = PotLike(potAddress);
    VatLike vat = VatLike(vatAddress);

    // Convert all our DAI to internal DAI in the vat
    daiJoin.join(address(this), dai.balanceOf(address(this)));

    // Checks the actual balance of DAI in the vat after the join
    uint256 bal = vat.dai(address(this));

    // Calculate the percentage increase to th pot for the entire vat, and move it in
    // Note: We may leave a tiny bit of DAI in the vat...but we do the whole thing every time
    uint256 pie = bal / pot.chi();
    pot.join(pie);

    return amount;
  }

  /**
   * @notice Transfer the underlying from this contract, after sweeping out of DSR pot
   * @param to Address to transfer funds to
   * @param amount Amount of underlying to transfer
   */
  function doTransferOut(address payable to, uint256 amount) internal override {
    DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress);
    PotLike pot = PotLike(potAddress);

    // Calculate the percentage decrease from the pot, and move that much out
    // Note: Use a slightly larger pie size to ensure that we get at least amount in the vat
    uint256 pie = add(mul(amount, RAY) / pot.chi(), 1);
    pot.exit(pie);

    daiJoin.exit(to, amount);
  }

  /*** Maker Internals ***/

  uint256 constant RAY = 10**27;

  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "add-overflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "mul-overflow");
  }
}

/*** Maker Interfaces ***/

interface PotLike {
  function chi() external view returns (uint256);

  function pie(address) external view returns (uint256);

  function drip() external returns (uint256);

  function join(uint256) external;

  function exit(uint256) external;
}

interface GemLike {
  function approve(address, uint256) external;

  function balanceOf(address) external view returns (uint256);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);
}

interface VatLike {
  function dai(address) external view returns (uint256);

  function hope(address) external;
}

interface DaiJoinLike {
  function vat() external returns (VatLike);

  function dai() external returns (GemLike);

  function join(address, uint256) external payable;

  function exit(address, uint256) external;
}