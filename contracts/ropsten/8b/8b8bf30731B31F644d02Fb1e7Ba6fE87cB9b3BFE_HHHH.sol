// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@seongeun/standard-contract/contracts/ethereum/erc20/ERC20.sol";
import "@seongeun/standard-contract/contracts/ethereum/erc20/features/ERC20Freezable.sol";
import "@seongeun/standard-contract/contracts/common/access/Ownable.sol";
import "@seongeun/standard-contract/contracts/ethereum/erc20/features/ERC20Pausable.sol";
import "@seongeun/standard-contract/contracts/ethereum/erc20/features/ERC20Lockable.sol";
import "@seongeun/standard-contract/contracts/ethereum/erc20/features/ERC20BatchTransferable.sol";

contract HHHH is ERC20, ERC20Freezable, Ownable, ERC20Pausable, ERC20Lockable, ERC20BatchTransferable {
    constructor() ERC20("HHHH", "HHH") {
        _mint(msg.sender, 100123123 * 10 ** decimals());
        _setAccess(Access.OWNABLE);
        FeatureType[] memory _features = new FeatureType[](5);
        _features[0] = FeatureType.FREEZABLE;
        _features[1] = FeatureType.PAUSABLE;
        _features[2] = FeatureType.MINTABLE;
        _features[3] = FeatureType.LOCKABLE;
        _features[4] = FeatureType.BATCH_TRANSFERABLE;
        _setFeatures(_features);
    }

    function freeze(address account) public onlyOwner {
        _freeze(account);
    }

    function unfreeze(address account) public onlyOwner {
        _unfreeze(account);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function lock(address account, uint256 amount, bytes32 reason, uint256 release)
        public
        onlyOwner
    {
        _lock(account, amount, reason, release);
    }

    function batchLock(address[] calldata accounts, uint256[] calldata amounts, bytes32[] calldata reasons, uint256[] calldata releases)
        public
        onlyOwner
    {
        _batchLock(accounts, amounts, reasons, releases);
    }

    function transferWithLock(address account, uint256 amount, bytes32 reason, uint256 release)
        public
        onlyOwner
    {
        _transferWithLock(account, amount, reason, release);
    }

    function batchTransferWithLock(address[] calldata accounts, uint256[] calldata amounts, bytes32[] calldata reasons, uint256[] calldata releases)
        public
        onlyOwner
    {
        _batchTransferWithLock(accounts, amounts, reasons, releases);
    }

    function extendLock(address account, bytes32 reason, uint256 time)
        public
        onlyOwner
    {
        _extendLock(account, reason, time);
    }

    function increaseLockAmount(address account, bytes32 reason, uint256 amount)
        public
        onlyOwner
    {
        _increaseLockAmount(account, reason, amount);
    }

    function unlock(address account) public onlyOwner {
        _unlock(account);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Freezable, ERC20Pausable, ERC20Lockable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function balanceOf(address account)
        public
        view
        override(ERC20, ERC20Lockable)
        returns (uint256)
    {
        return super.balanceOf(account);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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
pragma solidity ^0.8.0;

import { Context } from "../../common/utils/Context.sol";
import { ERC165 } from "../../common/utils/introspection/ERC165.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC20Metadata } from "./interfaces/IERC20Metadata.sol";
import { ERC20Feature } from "./defaults/ERC20Feature.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata, ERC165, ERC20Feature {
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
   * @dev See {IKIP13-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC20).interfaceId ||
      interfaceId == type(IERC20Metadata).interfaceId ||
      ERC165.supportsInterface(interfaceId);
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
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
  function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
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
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
pragma solidity ^0.8.0;

abstract contract ERC20Feature {
  enum FeatureType {
    CAPPED,
    BURNABLE,
    FREEZABLE,
    PAUSABLE,
    MINTABLE,
    LOCKABLE,
    BATCH_TRANSFERABLE
  }

  enum Access {
    NONE,
    OWNABLE,
    ROLES
  }

  struct Features {
    bool capped;
    bool burnable;
    bool freezable;
    bool pausable;
    bool mintable;
    bool lockable;
    bool batchTransferable;
  }

  Features public features;
  Access public access;

  function _setFeatures(FeatureType[] memory _featureType)
    internal
    returns (bool)
  {
    Features memory _features = Features({
      capped: false,
      burnable: false,
      freezable: false,
      pausable: false,
      mintable: false,
      lockable: false,
      batchTransferable: false
    });

    for (uint256 i = 0; i < _featureType.length; i++) {
      if (_featureType[i] == FeatureType.CAPPED) {
        _features.capped = true;
      } else if (_featureType[i] == FeatureType.BURNABLE) {
        _features.burnable = true;
      } else if (_featureType[i] == FeatureType.FREEZABLE) {
        _features.freezable = true;
      } else if (_featureType[i] == FeatureType.PAUSABLE) {
        _features.pausable = true;
      } else if (_featureType[i] == FeatureType.MINTABLE) {
        _features.mintable = true;
      } else if (_featureType[i] == FeatureType.LOCKABLE) {
        _features.lockable = true;
      } else if (_featureType[i] == FeatureType.BATCH_TRANSFERABLE) {
        _features.batchTransferable = true;
      }
    }

    features = _features;
    return true;
  }

  function _setAccess(Access _access) internal returns (bool) {
    access = _access;
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "../ERC20.sol";
import { Strings } from "../../../common/utils/Strings.sol";

abstract contract ERC20Lockable is ERC20 {
  /**
   * @dev Reasons why a user"s tokens have been locked
   */
  mapping(address => bytes32[]) public lockReason;

  /**
   * @dev locked token structure
   */
  struct LockToken {
    uint256 amount;
    uint256 release;
    bool claimed;
  }

  /**
   * @dev Holds number & release of tokens locked for a given reason for
   *      a specified address
   */
  mapping(address => mapping(bytes32 => LockToken)) public locked;

  /**
   * @dev Records data of all the tokens Locked
   */
  event Locked(
    address indexed account,
    bytes32 indexed reason,
    uint256 amount,
    uint256 release
  );

  /**
   * @dev Records data of all the tokens unlocked
   */
  event Unlocked(
    address indexed account,
    bytes32 indexed reason,
    uint256 amount
  );

  /**
   * @dev Locks a specified amount of tokens against an address,
   *      for a specified reason and release
   * @param account Account to be locked
   * @param amount Number of tokens to be locked
   * @param reason The reason to lock tokens
   * @param release Release time in seconds
   */
  function _lock(
    address account,
    uint256 amount,
    bytes32 reason,
    uint256 release
  ) internal virtual returns (bool) {
    // If tokens are already locked, then functions extendLock or
    // increaseLockAmount should be used to make any changes
    require(
      account != address(0),
      "ERC20Lockable: lock account the zero address"
    );
    require(
      tokensLocked(account, reason) == 0,
      "ERC20Lockable: Tokens already locked"
    );
    require(amount != 0, "ERC20Lockable: Amount can not be zero");
    require(balanceOf(account) >= amount, "ERC20Lockable: Not enough amount");

    if (locked[account][reason].amount == 0) lockReason[account].push(reason);

    _transfer(account, address(this), amount);

    locked[account][reason] = LockToken(amount, release, false);

    emit Locked(account, reason, amount, release);
    return true;
  }

  /**
   * @dev Multiple locks a specified amount of tokens against an address,
   *      for a specified reason and release
   * @param accounts Each Account to be locked
   * @param amounts Each number of tokens to be locked
   * @param reasons Each the reason to lock tokens
   * @param releases Each release time in seconds
   */
  function _batchLock(
    address[] calldata accounts,
    uint256[] calldata amounts,
    bytes32[] calldata reasons,
    uint256[] calldata releases
  ) internal virtual returns (bool) {
    require(
      accounts.length == amounts.length &&
        amounts.length == reasons.length &&
        reasons.length == releases.length,
      "ERC20Lockable: invalid length"
    );

    for (uint256 i = 0; i < accounts.length; i++) {
      require(
        _lock(accounts[i], amounts[i], reasons[i], releases[i]),
        string(
          abi.encodePacked(
            "ERC20Lockable: unable to lock token on account ",
            Strings.toHexString(uint160(accounts[i]), 20),
            "with reasons ",
            string(abi.encodePacked(reasons[i]))
          )
        )
      );
    }

    return true;
  }

  /**
   * @dev Transfers and Locks a specified amount of tokens,
   *      for a specified reason and time
   * @param account adress to which tokens are to be transfered
   * @param amount Number of tokens to be transfered and locked
   * @param reason The reason to lock tokens
   * @param release Release time in seconds
   */
  function _transferWithLock(
    address account,
    uint256 amount,
    bytes32 reason,
    uint256 release
  ) internal virtual returns (bool) {
    require(
      account != address(0),
      "ERC20Lockable: lock account the zero address"
    );
    require(
      tokensLocked(account, reason) == 0,
      "ERC20Lockable: Tokens already locked"
    );
    require(amount != 0, "ERC20Lockable: Amount can not be zero");
    require(
      balanceOf(msg.sender) >= amount,
      "ERC20Lockable: Not enough amount"
    );

    _transfer(_msgSender(), account, amount);
    _lock(account, amount, reason, release);
    return true;
  }

  /**
   * @dev Multiple Transfers and Locks a specified amount of tokens,
   *      for a specified reason and time
   * @param accounts Each address to which tokens are to be transfered
   * @param amounts Each number of tokens to be transfered and locked
   * @param reasons Each the reason to lock tokens
   * @param releases Each release time in seconds
   */
  function _batchTransferWithLock(
    address[] calldata accounts,
    uint256[] calldata amounts,
    bytes32[] calldata reasons,
    uint256[] calldata releases
  ) internal virtual returns (bool) {
    require(
      accounts.length == amounts.length &&
        amounts.length == reasons.length &&
        reasons.length == releases.length,
      "ERC20Lockable: invalid length"
    );

    for (uint256 i = 0; i < accounts.length; i++) {
      require(
        _transferWithLock(accounts[i], amounts[i], reasons[i], releases[i]),
        string(
          abi.encodePacked(
            "ERC20Lockable: unable to lock token on account ",
            Strings.toHexString(uint160(accounts[i]), 20),
            "with reasons ",
            string(abi.encodePacked(reasons[i]))
          )
        )
      );
    }

    return true;
  }

  /**
   * @dev Returns tokens locked for a specified address for a
   *      specified reason
   *
   * @param account The address whose tokens are locked
   * @param reason The reason to query the lock tokens for
   */
  function tokensLocked(address account, bytes32 reason)
    public
    view
    returns (uint256 amount)
  {
    if (!locked[account][reason].claimed)
      amount = locked[account][reason].amount;
  }

  /**
   * @dev Returns tokens locked for a specified address for a
   *      specified reason at a specific time
   *
   * @param account The address whose tokens are locked
   * @param reason The reason to query the lock tokens for
   * @param time The timestamp to query the lock tokens for
   */
  function tokensLockedAtTime(
    address account,
    bytes32 reason,
    uint256 time
  ) public view returns (uint256 amount) {
    if (locked[account][reason].release > time)
      amount = locked[account][reason].amount;
  }

  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    uint256 unlockableAmount = getUnlockableTokens(account);
    return super.balanceOf(account) + unlockableAmount;
  }

  /**
   * @dev Returns total tokens held by an address (locked + transferable)
   * @param account The address to query the total balance of
   */
  function totalBalanceOf(address account)
    public
    view
    returns (uint256 amount)
  {
    amount = balanceOf(account);

    for (uint256 i = 0; i < lockReason[account].length; i++) {
      amount = amount + tokensLocked(account, lockReason[account][i]);
    }
  }

  /**
   * @dev Extends lock for a specified reason and time
   * @param account The account which lock release will increase
   * @param reason The reason to lock tokens
   * @param time Lock extension release time in seconds
   */
  function _extendLock(
    address account,
    bytes32 reason,
    uint256 time
  ) internal virtual returns (bool) {
    require(
      tokensLocked(account, reason) > 0,
      "ERC20Lockable: No tokens locked"
    );

    locked[account][reason].release = locked[account][reason].release + time;

    emit Locked(
      account,
      reason,
      locked[account][reason].amount,
      locked[account][reason].release
    );
    return true;
  }

  /**
   * @dev Increase number of tokens locked for a specified reason
   * @param account The account which lock amount will increase
   * @param reason The reason to lock tokens
   * @param amount Number of tokens to be increased
   */
  function _increaseLockAmount(
    address account,
    bytes32 reason,
    uint256 amount
  ) internal virtual returns (bool) {
    require(
      tokensLocked(account, reason) > 0,
      "ERC20Lockable: No tokens locked"
    );
    require(amount != 0, "ERC20Lockable: Amount can not be zero");
    require(balanceOf(account) >= amount, "ERC20Lockable: Not enough amount");

    _transfer(account, address(this), amount);

    locked[account][reason].amount = locked[account][reason].amount + amount;

    emit Locked(
      account,
      reason,
      locked[account][reason].amount,
      locked[account][reason].release
    );
    return true;
  }

  /**
   * @dev Returns unlockable tokens for a specified address for a specified reason
   * @param account The address to query the the unlockable token count of
   * @param reason The reason to query the unlockable tokens for
   */
  function tokensUnlockable(address account, bytes32 reason)
    public
    view
    returns (uint256 amount)
  {
    if (
      locked[account][reason].release <= block.timestamp &&
      !locked[account][reason].claimed
    )
      //solhint-disable-line
      amount = locked[account][reason].amount;
  }

  /**
   * @dev Unlocks the unlockable tokens of a specified address
   * @param account Address of user, claiming back unlockable tokens
   */
  function _unlock(address account)
    internal
    virtual
    returns (uint256 unlockableTokens)
  {
    uint256 lockedTokens;

    for (uint256 i = 0; i < lockReason[account].length; i++) {
      lockedTokens = tokensUnlockable(account, lockReason[account][i]);
      if (lockedTokens > 0) {
        unlockableTokens = unlockableTokens + lockedTokens;
        locked[account][lockReason[account][i]].claimed = true;
        emit Unlocked(account, lockReason[account][i], lockedTokens);
      }
    }

    if (unlockableTokens > 0) this.transfer(account, unlockableTokens);
  }

  /**
   * @dev Gets the unlockable tokens of a specified address
   * @param account The address to query the the unlockable token count of
   */
  function getUnlockableTokens(address account)
    public
    view
    returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[account].length; i++) {
      unlockableTokens =
        unlockableTokens +
        (tokensUnlockable(account, lockReason[account][i]));
    }
  }

  /**
   * @dev See {ERC20-_beforeTokenTransfer}.
   *
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    _unlock(from);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../common/security/Pausable.sol";

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
pragma solidity ^0.8.0;

import { ERC20 } from "../ERC20.sol";

abstract contract ERC20Freezable is ERC20 {
  /**
   * @dev user freezed
   * */
  mapping(address => bool) private freezed;

  /**
   * @dev Emitted when user freezed
   */
  event Freezed(address account);

  /**
   * @dev Emitted when user unfreezed
   */
  event UnFreezed(address account);

  /**
   * @dev  Returns true if account is freezed, and false otherwise.
   *
   * @param account The address
   */
  function isFreezed(address account) public view returns (bool) {
    return freezed[account];
  }

  function _freeze(address account) internal virtual {
    freezed[account] = true;
    emit Freezed(account);
  }

  function _unfreeze(address account) internal virtual {
    freezed[account] = false;
    emit UnFreezed(account);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!freezed[from], "ERC20Freezable: from freezed");
    require(!freezed[_msgSender()], "ERC20Freezable: sender freezed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "./IERC20.sol";

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
pragma solidity ^0.8.0;

import { ERC20 } from "../ERC20.sol";
import { Strings } from "../../../common/utils/Strings.sol";

/**
 * @dev Extension of {ERC20} that adds batch transfer of tokens.
 */
abstract contract ERC20BatchTransferable is ERC20 {
  /**
   * @dev Batch transfer of multiple tokens to multiple addresses
   *
   * Requirements:
   *
   * - the number of 'accounts' and the number of 'amounts' must be the same.
   */
  function batchTransfer(
    address[] calldata accounts,
    uint256[] calldata amounts
  ) public virtual returns (bool) {
    require(
      accounts.length == amounts.length,
      "ERC20BatchTransferable: invalid length"
    );

    for (uint256 i = 0; i < accounts.length; i++) {
      require(
        transfer(accounts[i], amounts[i]),
        string(
          abi.encodePacked(
            "ERC20BatchTransfable: can not transfer ",
            Strings.toHexString(uint256(amounts[i]), 32),
            "tokens to ",
            Strings.toHexString(uint160(accounts[i]), 20)
          )
        )
      );
    }

    return true;
  }
}