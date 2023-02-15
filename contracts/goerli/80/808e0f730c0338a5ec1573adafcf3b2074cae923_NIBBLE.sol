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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Nibble
/// @author Nibble Team
/// @notice A revolution in the making by means of Democracy in a decentralised new world; this is a platform for the gamers by the gamers! NO DEGENS HERE!

import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";


contract NIBBLE is
  ERC20,
  Ownable,
  ReentrancyGuard
{
  /// @notice The stage of the token sale
  /// @param SaleOne - The first stage of the token sale
  /// @param SaleTwo - The second stage of the token sale
  /// @param SaleThree - The third stage of the token sale
  /// @param Live - The final stage of the token sale
  enum Stages {
    SaleOne,
    SaleTwo,
    SaleThree,
    Live
  }

  /// @notice The current stage of the token sale
  Stages public stage;
  /// @notice 
  bool public isTaxable;
  /// @notice boolean to check if the contract is paused
  bool public paused;
  /// @notice The address of the multisig wallet
  address public multiSigWallet;
  /// @notice The address of the underlying owner
  address public immutable underlying;
  /// @notice an array of all the minter addresses
  address[] public minters;
  address[] public routers;
  /// @notice The address of the minter that is pending to be added
  address public pendingMinter;
  uint256 public delayMinter;
  /// @notice The delay for the minter to be added
  uint256 public constant DELAY = 2 days;
  /// @notice The max amount of tokens that can be held by any wallet
  /// @dev This is to prevent whales from holding too many tokens
  uint256 public constant MAX_WALLET_BALANCE = 17600 * 10**18;
  /// @notice The max amount of tokens that can be minted in each stage
  uint256 public constant MAX_STAGE_SUPPLY = 296000 * 10**18;
  /// @notice The max amount of tokens that can be minted
  /// @dev This is to prevent the total supply from exceeding the max
  uint256 public constant MAX_TOTAL_SUPPLY = 888000 * 10**18;
  /// @notice The default cooldown time after interacting with the contract
  uint256 public cooldownTime = 60 minutes;
  /// @notice The default tax fee for each transaction
  /// @dev value / 10000 = tax fee% (e.g. 250 / 10000 = 2.5%)
  uint96 public taxFee;
  /// @notice address => timestamp of last interaction with the contract
  mapping(address => uint256) public cooldowns;
  /// @notice address => boolean to check if the address is excluded from the cooldown
  mapping(address => bool) public addrsExcludedFromCooldown;
  /// @notice address => boolean to check if the address is excluded from the tax
  mapping(address => bool) public addrsExcludedFromTax;
  /// @notice address => boolean to check if the address is excluded from the max wallet balance
  mapping(address => bool) public addrsExcludedFromMaxWalletBalance;
  /// @notice address => boolean to check if the address is a minter
  mapping(address => bool) public isMinter;
  mapping(address => bool) public isRouter;

  event Minted(address to, uint256 amount);
  event TaxFeeChanged(uint96 taxFee);
  event CooldownTimeChanged(uint256 cooldownTime);
  event StageChanged(Stages stage);
  event CooldownSet(address addr, uint256 cooldown);
  event TransferWithTax(
    address sender,
    address taxRecipient,
    uint256 amount,
    uint256 taxAmount
  );
  event TransferWithoutTax(
    address sender,
    address recipient,
    uint256 amount
  );
  event MinterApplied(address addedMinter);
  event MinterRevoked(address removedMinter);
  event MinterPending(address pendingMinter, uint256 pendingDelay);

  /// @notice Constructor for the Nibble token
  /// @param name - The name of the token
  /// @param symbol - The symbol of the token
  /// @param _multiSigWallet - The address of the multisig wallet
  /// @param _coreTeamAddrs - The addresses of the core team
  /// @param _taxFee - The default tax fee for each transaction
  constructor(
    string memory name,
    string memory symbol,
    address _underlying,
    address _multiSigWallet,
    address[] memory _coreTeamAddrs,
    uint96 _taxFee
  ) ERC20(name, symbol) {
    multiSigWallet = _multiSigWallet;
    transferOwnership(_multiSigWallet);
    //set to Stage one
    stage = Stages.SaleOne;
    taxFee = _taxFee;
    //add core team addresses to excluded list
    addrsExcludedFromCooldown[_multiSigWallet] = true;
    addrsExcludedFromTax[_multiSigWallet] = true;
    addrsExcludedFromMaxWalletBalance[_multiSigWallet] = true;
    for (uint256 i = 0; i < _coreTeamAddrs.length; i++) {
      addrsExcludedFromCooldown[_coreTeamAddrs[i]] = true;
      addrsExcludedFromTax[_coreTeamAddrs[i]] = true;
      addrsExcludedFromMaxWalletBalance[_coreTeamAddrs[i]] = true;
    }
    underlying = _underlying;
    isTaxable = false;
  }

  /// @notice checks if the address is zero
  /// @param _addr - The address to check
  modifier isNotZero(address _addr) {
    require(_addr != address(0), "NIBBLE: Address cannot be zero");
    _;
  }

  /// @notice checks if the contract is paused
  modifier isNotPaused() {
    require(!paused, "NIBBLE: Contract is paused");
    _;
  }

  /// @notice checks if the msg.sender is a minter, or owner
  modifier onlyAuth() {
    require(
      isMinter[msg.sender] || msg.sender == owner(),
      "NIBBLE: Only authorised addresses can mint"
    );
    _;
  }

  /// @notice Only Owner function to mint tokens, Mints full supply of tokens for each stage
  /// @param to - The address to mint tokens to
  /// @param amount - The amount of tokens to mint
  function mint(address to, uint256 amount) external onlyAuth returns (bool) {
    require(amount <= MAX_STAGE_SUPPLY, "NIBBLE: Cannot mint more than max supply");
    require(totalSupply() + amount <= MAX_TOTAL_SUPPLY, "NIBBLE: Cannot mint more than max total supply");

    _mint(to, amount);
    return true;
    }

  /// @notice Only Authorized function to burn tokens
  /// @param from - The address to burn tokens from
  /// @param amount - The amount of tokens to burn
  function burn(address from, uint256 amount) external onlyAuth returns (bool) {
    require(from != address(0), "AnyswapV3ERC20: address(0x0)");
    _burn(from, amount);
    return true;
  }

  /// @notice Only Owner function to set stage of token sale
  function setStage(Stages _stage) external onlyOwner {
    require(_stage != stage, "NIBBLE: Cannot set stage to current stage");
    require(uint256(_stage) > uint256(stage), "NIBBLE: Cannot set stage to previous stage");
    if (_stage == Stages.SaleOne) {
      taxFee = 4000;
    } else if (_stage == Stages.SaleTwo) {
      taxFee = 3000;
    } else if (_stage == Stages.SaleThree) {
      taxFee = 2000;
    } else if (_stage == Stages.Live) {
      taxFee = 250;
    }
    stage = _stage;
    emit StageChanged(stage);
  }

  /// @notice Only owner function to pause the contract
  function togglePause() external onlyOwner {
    paused = !paused;
  }

  /// @notice Only owner function to exclude addresses from the cooldown
  /// @param _addrs - The addresses to exclude from the cooldown
  function excludedAddrsFromCooldown(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromCooldown[_addrs[i]] = true;
    }
  }

  /// @notice Only owner function to remove excluded addresses from the cooldown
  /// @param _addrs - The addresses to remove from the excluded list
  function removeExcludedAddrsFromCooldown(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromCooldown[_addrs[i]] = false;
    }
  }

  /// @notice Only owner function to exclude addresses from the tax
  /// @param _addrs - The addresses to exclude from the tax
  function excludedAddrsFromTax(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromTax[_addrs[i]] = true;
    }
  }

  /// @notice Only owner function to remove excluded addresses from the tax
  /// @param _addrs - The addresses to remove from the excluded list
  function removeExcludedAddrsFromTax(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromTax[_addrs[i]] = false;
    }
  }

  /// @notice Only owner function to exclude addresses from the max wallet balance
  /// @param _addrs - The addresses to exclude from the max wallet balance
  function excludedAddrsFromMaxWalletBalance(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromMaxWalletBalance[_addrs[i]] = true;
    }
  }

  /// @notice Only owner function to remove excluded addresses from the max wallet balance
  /// @param _addrs - The addresses to remove from the excluded list
  function removeExcludedAddrsFromMaxWalletBalance(address[] calldata _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != multiSigWallet, "NIBBLE: Cannot remove multiSigWallet from excluded list");
      require(_addrs[i] != address(0), "NIBBLE: Address cannot be zero");
      addrsExcludedFromMaxWalletBalance[_addrs[i]] = false;
    }
  }

  /// @notice Only owner function to set the cooldown time
  /// @param _cooldownTime The new cooldown time in seconds
  /// @dev cooldown time is the time after interacting with the contract before the user can interact again
  function setCooldownTime(uint256 _cooldownTime) external onlyOwner {
    require(_cooldownTime >= 0, "NIBBLE: Cooldown time cannot be negative");
    require(_cooldownTime <= 86400, "NIBBLE: Cooldown time cannot be greater than 24 hours");
    cooldownTime = _cooldownTime;
    emit CooldownTimeChanged(cooldownTime);
  }

  /// @notice Only owner function to set the current tax fee
  /// @param _taxFee The new tax fee is denominated by 10000 (e.g. 250 = 2.5%)
  function setTaxFee(uint96 _taxFee) external onlyOwner  {
    require(_taxFee >= 0, "NIBBLE: Tax fee cannot be negative");
    require(_taxFee <= 5000, "NIBBLE: Tax fee cannot be greater than 100%");
    taxFee = _taxFee;
    emit TaxFeeChanged(taxFee);
  }

  /// @notice Only owner function to set the multiSigWallet address
  /// @param newAddrs The new multiSigWallet address
  /// @dev The new address will get ownership of the contract
  function setMultiSigWallet(address newAddrs) external onlyOwner isNotZero(newAddrs) {
    multiSigWallet = newAddrs;
    transferOwnership(multiSigWallet);
  }

  function addRouters(address[] calldata _routers) external onlyOwner {
    for (uint256 i = 0; i < _routers.length; i++) {
      require(_routers[i] != address(0), "NIBBLE: Address cannot be zero");
      isRouter[_routers[i]] = true;
    }
  }

  function removeRouters(address[] calldata _routers) external onlyOwner {
    for (uint256 i = 0; i < _routers.length; i++) {
      require(_routers[i] != address(0), "NIBBLE: Address cannot be zero");
      isRouter[_routers[i]] = false;
    }
  }

  /// @notice Only owner function to set minter address
  /// @param _auth The address of the minter
  /// @dev The _auth address will be set into pendingMinter, after the DELAY period, the owner can apply the minter
  function setMinter(address _auth) external onlyOwner isNotZero(_auth) {
    pendingMinter = _auth;
    delayMinter = block.timestamp + DELAY;
    emit MinterPending(pendingMinter, delayMinter);
  }

  /// @notice Only owner function to revoke minter address
  /// @param _auth The address of the minter
  function revokeMinter(address _auth) external onlyOwner {
    isMinter[_auth] = false;
    emit MinterRevoked(_auth);
  }

  /// @notice Only owner function to apply minter address
  /// @dev The minter address will be applied after the delay period
  function applyMinter() external onlyOwner {
    require(pendingMinter != address(0) && block.timestamp >= delayMinter, "NIBBLE: Cannot apply minter");
    isMinter[pendingMinter] = true;
    minters.push(pendingMinter);
    pendingMinter = address(0);
    delayMinter = 0;
    emit MinterApplied(minters[minters.length - 1]);
  }

  function setTaxable(bool taxable) external onlyOwner {
    isTaxable = taxable;
  }

  /// @notice Internal mint function to mint tokens
  /// @param account The address of the recipient
  /// @param amount The amount of tokens to mint
  function _mint(address account, uint256 amount) internal override isNotZero(account) {
    //Check if the total supply will exceed the max total supply
    require(
      totalSupply() + amount <= MAX_TOTAL_SUPPLY,
      "Cannot exceed max total supply"
    );
    //check if the wallet balance will exceed the max wallet balance
    if(!addrsExcludedFromMaxWalletBalance[account]) {
      require(
        balanceOf(account) + amount <= MAX_WALLET_BALANCE,
        "Cannot exceed max wallet balance"
      );
    }
    //check if the stage is correct
    if(stage == Stages.SaleOne) {
      require(
        totalSupply() + amount <= MAX_STAGE_SUPPLY,
        'Cannot exceed max stage supply'
      );
    } else if(stage == Stages.SaleTwo) {
      require(
        totalSupply() + amount <= MAX_STAGE_SUPPLY * 2,
        'Cannot exceed max stage supply'
      );
    } else if(stage == Stages.SaleThree) {
      require(
        totalSupply() + amount <= MAX_STAGE_SUPPLY * 3,
        'Cannot exceed max stage supply'
      );
    }
    emit Minted(account, amount);
    super._mint(account, amount);
  }

  /// @notice Internal function called before any token transfer
  /// @param from The address of the sender
  /// @param to The address of the recipient
  /// @param amount The amount of tokens to transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override  {
    require(!paused, "NIBBLE: Contract is paused");
    //check if the wallet balance will exceed the max wallet balance
    if (addrsExcludedFromMaxWalletBalance[to]) {
      return;
    } else {
      require(
        balanceOf(to) + amount <= MAX_WALLET_BALANCE,
        "Cannot exceed max wallet balance"
      );
    }
    //check if the address is excluded from cooldown
    if (addrsExcludedFromCooldown[from] || addrsExcludedFromCooldown[to]) {
      return;
    }
    //check if the address is on cooldown
    require(
      block.timestamp >= cooldowns[from],
      "Cannot transfer tokens during cooldown"
    );
    super._beforeTokenTransfer(from, to, amount);
  }

  /// @notice Internal function to transfer tokens
  /// @param sender The address of the sender
  /// @param recipient The address of the recipient
  /// @param amount The amount of tokens to transfer
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal override isNotPaused {
    require(sender != address(0), "NIBBLE: Cannot transfer from the zero address");
    require(recipient != address(0), "NIBBLE: Cannot transfer to the zero address");
    require(amount > 0, "NIBBLE: Cannot transfer zero amount");
    //check isTaxable bool to determine if tax should be applied
    if (isTaxable) {
      //Check if tx is swapping tokens
      if (isRouter[recipient] || isRouter[msg.sender]) {
        //Check if the address is excluded from tax
        if (addrsExcludedFromTax[sender]) {
          super._transfer(sender, recipient, amount);
          !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
          emit CooldownSet(sender, cooldowns[sender]);
          emit TransferWithoutTax(sender, recipient, amount);
          return;
        } else {
          //Calculate tax amount
          uint256 taxAmount = amount * taxFee / 10000;
          //Calculate amount to transfer
          uint256 transferAmount = amount - taxAmount;
          //Transfer tokens
          super._transfer(sender, recipient, transferAmount);
          //Transfer tax to the tax address
          super._transfer(sender, multiSigWallet, taxAmount);
          !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
          emit TransferWithTax(sender, multiSigWallet, amount, taxAmount);
          emit CooldownSet(sender, cooldowns[sender]);
          return;
        }
      } else {
        super._transfer(sender, recipient, amount);
        !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
        emit CooldownSet(sender, cooldowns[sender]);
        return;

      }
    } else {
      super._transfer(sender, recipient, amount);
      !addrsExcludedFromCooldown[sender] ? cooldowns[sender] = block.timestamp + cooldownTime : cooldowns[sender] = block.timestamp;
      emit CooldownSet(sender, cooldowns[sender]);
      return;
    }
  }
}