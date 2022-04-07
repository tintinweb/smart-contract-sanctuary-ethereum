// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function __PaymentSplitter_init(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        __PaymentSplitter_init_unchained(payees, shares_);
    }

    function __PaymentSplitter_init_unchained(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";
import "./dependencies/CONTRewardManagement.sol";
import "./dependencies/LiquidityRouter.sol";

contract ZeroXBlock is Initializable, ERC20Upgradeable, OwnableUpgradeable, PaymentSplitterUpgradeable {
    CONTRewardManagement public _crm;

    IJoeRouter02 public uniswapV2Router;
    uint256 private constant HUNDRED_PERCENT = 100_000_000;

    uint256 public ownedContsLimit;
    uint256 private mintContLimit;

    address public uniswapV2Pair;
    uint256 public totalTokensPaidForMinting;

    // ***** Pools Address *****
    address public developmentFundPool;
    address public treasuryPool;
    address public rewardsPool;
    address public liquidityPool;

    // ***** Storage for fees *****
    uint256 public rewardsFee;
    uint256 public treasuryFee;
    uint256 public liquidityPoolFee;
    uint256 public developmentFee;
    uint256 public totalFees;

    uint256 public cashoutFee;

    // ***** Storage for swapping *****
    bool public enableAutoSwapTreasury;
    bool public enableAutoSwapDevFund;
    address public usdcToken;

    // ***** Anti-bot *****
    bool public antiBotEnabled;
    uint256 public launchBuyLimit;
    uint256 public launchBuyTimeout;
    mapping(address => uint256) public _lastBuyOnLaunch;

    // ***** Blacklist storage *****
    mapping(address => bool) public _isBlacklisted;

    // ***** Market makers pairs *****
    mapping(address => bool) public automatedMarketMakerPairs;

    // ***** Enable Cashout *****
    bool public enableCashout;
    bool public enableMintConts;

    // ***** V2 new storages *****
    address public cashoutTaxPool;
    LiquidityRouter public _liqRouter;

    // ***** Events *****
    event ContsMinted(address sender);
    event RewardCashoutOne(address sender, uint256 index);
    event RewardCashoutAll(address sender);
    event Funded(string walletName, ContType cType, address token, uint256 amount);

    // ***** Constructor *****
    function initialize(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory balances,
        uint256[] memory fees,
        address usdcAddr
    ) public initializer {
        require(addresses.length > 0 && balances.length > 0, "ADDR & BALANCE ERROR");

        __Ownable_init();
        __ERC20_init("0xBlock", "0xB");
        __PaymentSplitter_init(payees, shares);

        require(
            addresses[1] != address(0) &&
                addresses[2] != address(0) &&
                addresses[3] != address(0) &&
                addresses[4] != address(0),
            "POOL ZERO FOUND"
        );
        developmentFundPool = addresses[1];
        liquidityPool = addresses[2];
        treasuryPool = addresses[3];
        rewardsPool = addresses[4];

        cashoutTaxPool = rewardsPool;

        require(fees[0] > 0 && fees[1] > 0 && fees[2] > 0 && fees[3] > 0 && fees[4] > 0, "0% FEES FOUND");
        developmentFee = fees[0];
        treasuryFee = fees[1];
        rewardsFee = fees[2];
        liquidityPoolFee = fees[3];
        cashoutFee = fees[4];

        totalFees = rewardsFee + liquidityPoolFee + developmentFee + treasuryFee;

        require(addresses.length == balances.length, "ADDR & BALANCE ERROR");

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], balances[i] * (10**18));
        }
        require(totalSupply() == 1e24, "TTL SUPPLY DIFF 1 MIL");

        usdcToken = usdcAddr;
        ownedContsLimit = 100;
        mintContLimit = 10;
        enableAutoSwapTreasury = false;
        enableAutoSwapDevFund = true;
        enableMintConts = true;
        enableCashout = true;
    }

    // ***** WRITE functions for admin *****
    function setUSDCAddress(address newAddress) external onlyOwner {
        usdcToken = newAddress;
    }

    function setEnableCashout(bool _enableCashout) external onlyOwner {
        enableCashout = _enableCashout;
    }

    function setEnableMintConts(bool value) external onlyOwner {
        enableMintConts = value;
    }

    function setContManagement(address crm) external onlyOwner {
        require(crm != address(0), "NEW_CRM: zero addr");
        _crm = CONTRewardManagement(crm);
    }

    function setLiquidityRouter(address payable liqRouter) external onlyOwner {
        require(liqRouter != address(0), "NEW_LROUTER: zero addr");
        _liqRouter = LiquidityRouter(liqRouter);
    }

    function updateCashoutTaxPool(address payable wall) external onlyOwner {
        require(wall != address(0), "UPD_WALL: zero addr");
        cashoutTaxPool = wall;
    }

    function updateDevelopmentFundWallet(address payable wall) external onlyOwner {
        require(wall != address(0), "UPD_WALL: zero addr");
        developmentFundPool = wall;
    }

    function updateLiquidityWallet(address payable wall) external onlyOwner {
        require(wall != address(0), "UPD_WALL: zero addr");
        liquidityPool = wall;
    }

    function updateRewardsWallet(address payable wall) external onlyOwner {
        require(wall != address(0), "UPD_WALL: zero addr");
        rewardsPool = wall;
    }

    function updateTreasuryWallet(address payable wall) external onlyOwner {
        require(wall != address(0), "UPD_WALL: zero addr");
        treasuryPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        uint256 newTotalFee = liquidityPoolFee + developmentFee + treasuryFee + value;
        require(newTotalFee <= 100, "FEES: total exceeding 100%");
        rewardsFee = value;
        totalFees = newTotalFee;
    }

    function updateLiquidityFee(uint256 value) external onlyOwner {
        uint256 newTotalFee = rewardsFee + developmentFee + treasuryFee + value;
        require(newTotalFee <= 100, "FEES: total exceeding 100%");
        liquidityPoolFee = value;
        totalFees = newTotalFee;
    }

    function updateDevelopmentFee(uint256 value) external onlyOwner {
        uint256 newTotalFee = rewardsFee + liquidityPoolFee + treasuryFee + value;
        require(newTotalFee <= 100, "FEES: total exceeding 100%");
        developmentFee = value;
        totalFees = newTotalFee;
    }

    function updateTreasuryFee(uint256 value) external onlyOwner {
        uint256 newTotalFee = rewardsFee + liquidityPoolFee + developmentFee + value;
        require(newTotalFee <= 100, "FEES: total exceeding 100%");
        treasuryFee = value;
        totalFees = newTotalFee;
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        require(value <= 100, "FEES: cashout exceeding 100%");
        cashoutFee = value;
    }

    function setBlacklistStatus(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function changeEnableAutoSwapTreasury(bool newVal) external onlyOwner {
        enableAutoSwapTreasury = newVal;
    }

    function changeEnableAutoSwapDevFund(bool newVal) external onlyOwner {
        enableAutoSwapDevFund = newVal;
    }

    function rescueMissentToken(address userAddr, uint256 tokens) external onlyOwner {
        require(tokens <= balanceOf(address(this)), "SAVE_MISSENT: tokens exceed addr balance");
        require(userAddr != address(0), "SAVE_MISSENT: zero_address");
        _transfer(address(this), userAddr, tokens);
    }

    // ***** Private helpers functions *****
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "ERC20: Blacklisted address");

        super._transfer(from, to, amount);
    }

    // Send fund from sender to pool.
    // amount send will be in 0xB. Will be converted if target token is in other tokens
    // Emit Funded.
    // ** not yet supported to fund from cashout or swaps
    function _fund(
        address sender,
        string memory targetWalletName,
        address targetWalletAddress,
        ContType cType,
        address token,
        uint256 amount
    ) private {
        if (token == address(this)) {
            _transfer(sender, targetWalletAddress, amount);
        } else {
            _transfer(sender, address(_liqRouter), amount);
            _liqRouter.swapExact0xBForTokenNoFee(targetWalletAddress, token, amount);
        }
        emit Funded(targetWalletName, cType, token, amount);
    }

    // ***** WRITE functions for public *****
    function swapExact0xBForToken(
        address tokenAddr,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 wait
    ) public {
        address sender = msg.sender;
        require(balanceOf(sender) >= amountIn, "SWAP: insufficient balance");
        _transfer(sender, address(_liqRouter), amountIn);
        _liqRouter.swapExact0xBForToken(sender, tokenAddr, amountIn, amountOutMin, block.timestamp + wait);
    }

    function swap0xBForExactToken(
        address tokenAddr,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 wait
    ) public {
        address sender = msg.sender;
        require(balanceOf(sender) >= amountInMax, "SWAP: insufficient balance");
        _transfer(sender, address(_liqRouter), amountInMax);
        _liqRouter.swap0xBForExactToken(sender, tokenAddr, amountOut, amountInMax, block.timestamp + wait);
    }

    function swapExactTokenFor0xB(
        address tokenAddr,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 wait
    ) public {
        address sender = msg.sender;
        IERC20 targetToken = IERC20(tokenAddr);
        require(targetToken.balanceOf(sender) >= amountIn, "SWAP: insufficient balance");
        targetToken.transferFrom(sender, address(_liqRouter), amountIn);
        _liqRouter.swapExactTokenFor0xB(sender, tokenAddr, amountIn, amountOutMin, block.timestamp + wait);
    }

    function swapTokenForExact0xB(
        address tokenAddr,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 wait
    ) public {
        address sender = msg.sender;
        IERC20 targetToken = IERC20(tokenAddr);
        require(targetToken.balanceOf(sender) >= amountInMax, "SWAP: insufficient balance");
        targetToken.transferFrom(sender, address(_liqRouter), amountInMax);
        _liqRouter.swapTokenForExact0xB(sender, tokenAddr, amountOut, amountInMax, block.timestamp + wait);
    }

    function swapExactAVAXFor0xB(uint256 amountOutMin, uint256 wait) external payable {
        address sender = msg.sender;
        uint256 amountIn = msg.value;
        _liqRouter.swapExactAVAXFor0xB{ value: amountIn }(sender, amountOutMin, block.timestamp + wait);
    }

    function swapAVAXForExact0xB(
        uint256 amountOut,
        uint256 amountInMax,
        uint256 wait
    ) external payable {
        address sender = msg.sender;
        require(msg.value >= amountInMax, "SWAP: msg.value less than slippage");
        _liqRouter.swapAVAXForExact0xB{ value: msg.value }(sender, amountOut, block.timestamp + wait);
    }

    function mintConts(string[] memory names, ContType _cType) external {
        require(enableMintConts, "CONTMINT: mint conts disabled");
        require(names.length <= mintContLimit, "CONTMINT: too many conts");
        for (uint256 i = 0; i < names.length; i++) {
            require(bytes(names[i]).length > 3 && bytes(names[i]).length < 33, "CONTMINT: improper character count");
        }

        address sender = _msgSender();
        require(sender != address(0), "CONTMINT: zero address");
        require(!_isBlacklisted[sender], "CONTMINT: blacklisted address");
        require(
            sender != developmentFundPool && sender != rewardsPool && sender != treasuryPool,
            "CONTMINT: pools cannot create cont"
        );
        uint256 contCount = _crm._getContNumberOf(sender);
        require(contCount + names.length <= ownedContsLimit, "CONTMINT: reached mint limit");
        uint256 contsPrice = _crm.contPrice(_cType) * names.length;
        totalTokensPaidForMinting += contsPrice;
        require(balanceOf(sender) >= contsPrice, "CONTMINT: Balance too low for creation.");

        // DEV FUND
        uint256 developmentFundTokens = (contsPrice * developmentFee) / 100;
        if (enableAutoSwapDevFund) {
            _fund(sender, "devfund", developmentFundPool, _cType, usdcToken, developmentFundTokens);
        } else {
            _fund(sender, "devfund", developmentFundPool, _cType, address(this), developmentFundTokens);
        }

        // REWARDS POOL
        uint256 rewardsPoolTokens = (contsPrice * rewardsFee) / 100;
        _fund(sender, "rewards", rewardsPool, _cType, address(this), rewardsPoolTokens);

        // TREASURY
        uint256 treasuryPoolTokens = (contsPrice * treasuryFee) / 100;
        if (enableAutoSwapTreasury) {
            _fund(sender, "treasury", treasuryPool, _cType, usdcToken, treasuryPoolTokens);
        } else {
            _fund(sender, "treasury", treasuryPool, _cType, address(this), treasuryPoolTokens);
        }

        // LIQUIDITY
        uint256 liquidityTokens = (contsPrice * liquidityPoolFee) / 100;
        _fund(sender, "liquidity", liquidityPool, _cType, address(this), liquidityTokens);

        // EXTRA
        uint256 extraT = contsPrice - developmentFundTokens - rewardsPoolTokens - treasuryPoolTokens - liquidityTokens;
        if (extraT > 0) {
            super._transfer(sender, address(this), extraT);
        }

        _crm.createConts(sender, names, _cType);
        emit ContsMinted(sender);
    }

    function cashoutReward(uint256 _contIndex) external {
        address sender = _msgSender();
        require(enableCashout == true, "CSHT: Cashout Disabled");
        require(sender != address(0), "CSHT: zero address");
        require(!_isBlacklisted[sender], "CSHT: blacklisted");
        uint256 rewardAmount = _crm._getRewardAmountOfIndex(sender, _contIndex);
        require(rewardAmount > 0, "CSHT: reward not ready");

        uint256 feeAmount = 0;
        if (cashoutFee > 0) {
            feeAmount = (rewardAmount * (cashoutFee)) / (100);
            if (rewardsPool != cashoutTaxPool) {
                _transfer(rewardsPool, cashoutTaxPool, rewardAmount);
            }
        }
        rewardAmount -= feeAmount;
        _transfer(rewardsPool, sender, rewardAmount);
        _crm._cashoutContReward(sender, _contIndex);
        emit RewardCashoutOne(sender, _contIndex);
    }

    function cashoutAll() external {
        address sender = _msgSender();
        require(enableCashout == true, "CSHTALL: cashout disabled");
        require(sender != address(0), "CSHTALL: zero address");
        require(!_isBlacklisted[sender], "CSHTALL: blacklisted address");
        uint256 rewardAmount = _crm._getRewardAmountOf(sender);
        require(rewardAmount > 0, "CSHTALL: reward not ready");

        uint256 feeAmount = 0;
        if (cashoutFee > 0) {
            feeAmount = (rewardAmount * (cashoutFee)) / (100);
            if (rewardsPool != cashoutTaxPool) {
                _transfer(rewardsPool, cashoutTaxPool, rewardAmount);
            }
        }
        rewardAmount -= feeAmount;
        _transfer(rewardsPool, sender, rewardAmount);
        _crm._cashoutAllContsReward(sender);
        emit RewardCashoutAll(sender);
    }

    // ***** READ function for public *****
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../libraries/IterableMapping.sol";

enum ContType {
    Square,
    Cube,
    Tesseract
}

contract CONTRewardManagement is Initializable {
    using IterableMapping for IterableMapping.Map;

    // ----- Constants -----
    uint256 private constant UNIX_YEAR = 31_536_000;
    uint256 private constant HUNDRED_PERCENT = 100_000_000;

    // ----- Cont Structs -----
    struct ContEntity {
        string name;
        uint256 creationTime;
        uint256 lastUpdateTime;
        uint256 initialAPR;
        uint256 buyPrice;
        ContType cType;
    }

    // ----- Changes Structs -----
    struct APRChangesEntry {
        uint256 timestamp;
        int256 reducedPercentage;
    }

    // ----- Contract Storage -----
    IterableMapping.Map private contOwners;
    mapping(address => ContEntity[]) private _contsOfUser;

    mapping(ContType => uint256) public contPrice;
    mapping(ContType => uint256) public initRewardAPRPerCont;
    mapping(ContType => APRChangesEntry[]) private aprChangesHistory;
    uint256 public cashoutTimeout;
    uint256 public autoReduceAPRInterval;
    uint256 public autoReduceAPRRate;

    address public admin0XB;
    address public token;

    uint256 public totalContsCreated;
    mapping(ContType => uint256) private _totalContsPerContType;

    // ----- Constructor -----
    function initialize(
        uint256[] memory _contPrices,
        uint256[] memory _rewardAPRs,
        uint256 _cashoutTimeout,
        uint256 _autoReduceAPRRate
    ) public initializer {
        autoReduceAPRInterval = UNIX_YEAR;
        totalContsCreated = 0;
        uint256 initialTstamp = block.timestamp;
        for (uint256 i = 0; i < 3; i++) {
            contPrice[ContType(i)] = _contPrices[i];
            initRewardAPRPerCont[ContType(i)] = _rewardAPRs[i];
            _totalContsPerContType[ContType(i)] = 0;
            aprChangesHistory[ContType(i)];
            aprChangesHistory[ContType(i)].push(APRChangesEntry({ timestamp: initialTstamp, reducedPercentage: 0 }));
        }
        cashoutTimeout = _cashoutTimeout;
        admin0XB = msg.sender;
        autoReduceAPRRate = _autoReduceAPRRate;
    }

    // ----- Modifier (filter) -----
    modifier onlyAuthorities() {
        require(msg.sender == token || msg.sender == admin0XB, "Access Denied!");
        _;
    }

    // ----- External WRITE functions -----
    function setAdmin(address newAdmin) external onlyAuthorities {
        require(newAdmin != address(0), "zero address");
        admin0XB = newAdmin;
    }

    function setToken(address token_) external onlyAuthorities {
        require(token_ != address(0), "zero address");
        token = token_;
    }

    function createConts(
        address account,
        string[] memory contNames,
        ContType _cType
    ) external onlyAuthorities {
        _contsOfUser[account];
        uint256 currentAPR = this.currentRewardAPRPerNewCont(_cType);

        for (uint256 i = 0; i < contNames.length; i++) {
            _contsOfUser[account].push(
                ContEntity({
                    name: contNames[i],
                    creationTime: block.timestamp,
                    lastUpdateTime: block.timestamp,
                    buyPrice: contPrice[_cType],
                    initialAPR: currentAPR,
                    cType: _cType
                })
            );
        }

        contOwners.set(account, _contsOfUser[account].length);
        totalContsCreated += contNames.length;
        _totalContsPerContType[_cType] += contNames.length;
    }

    function _cashoutContReward(address account, uint256 _contIndex) external onlyAuthorities returns (uint256) {
        ContEntity[] storage conts = _contsOfUser[account];
        require(_contIndex >= 0 && _contIndex < conts.length, "CONT: Index Error");
        ContEntity storage cont = conts[_contIndex];
        require(claimable(cont.lastUpdateTime), "CASHOUT ERROR: You have to wait before claiming this cont.");
        uint256 currentTstamp = block.timestamp;
        uint256 rewardCont = contRewardInInterval(cont, cont.lastUpdateTime, currentTstamp);
        cont.lastUpdateTime = currentTstamp;
        return rewardCont;
    }

    function _cashoutAllContsReward(address account) external onlyAuthorities returns (uint256) {
        ContEntity[] storage conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        require(contsCount > 0, "CASHOUT ERROR: You don't have conts to cash-out");
        ContEntity storage _cont;
        uint256 rewardsTotal = 0;
        uint256 currentTstamp = block.timestamp;
        uint256 latestCashout = 0;
        for (uint256 i = 0; i < contsCount; i++) {
            uint256 lastUpd = conts[i].lastUpdateTime;
            if (lastUpd > latestCashout) {
                latestCashout = lastUpd;
            }
        }

        require(claimable(latestCashout), "CASHOUT ERROR: You have to wait before claiming all conts.");

        for (uint256 i = 0; i < contsCount; i++) {
            _cont = conts[i];
            rewardsTotal += contRewardInInterval(_cont, _cont.lastUpdateTime, currentTstamp);
            _cont.lastUpdateTime = currentTstamp;
        }
        return rewardsTotal;
    }

    function _changeContPrice(ContType _cType, uint256 newPrice) external onlyAuthorities {
        contPrice[_cType] = newPrice;
    }

    function _changeRewardAPRPerCont(ContType _cType, int256 reducedPercentage) external onlyAuthorities {
        require(reducedPercentage < int256(HUNDRED_PERCENT), "REDUCE_RWD: do not reduce more than 100%");
        aprChangesHistory[_cType].push(
            APRChangesEntry({ timestamp: block.timestamp, reducedPercentage: reducedPercentage })
        );
    }

    function _undoRewardAPRChange(ContType _cType) external onlyAuthorities {
        uint256 changesLength = aprChangesHistory[_cType].length;
        require(changesLength > 1, "UNDO CHANGE: No changes found for cType");
        aprChangesHistory[_cType].pop();
    }

    function _resetAllAPRChange(ContType _cType, uint256 _initialPrice) external onlyAuthorities {
        initRewardAPRPerCont[_cType] = _initialPrice;
        uint256 initialTstamp = aprChangesHistory[_cType][0].timestamp;
        delete aprChangesHistory[_cType];
        aprChangesHistory[_cType].push(APRChangesEntry({ timestamp: initialTstamp, reducedPercentage: 0 }));
    }

    function _changeCashoutTimeout(uint256 newTime) external onlyAuthorities {
        cashoutTimeout = newTime;
    }

    function _changeAutoReduceAPRInterval(uint256 newInterval) external onlyAuthorities {
        autoReduceAPRInterval = newInterval;
    }

    function _changeAutoReduceAPRRate(uint256 newRate) external onlyAuthorities {
        autoReduceAPRRate = newRate;
    }

    // ----- External READ functions -----
    function currentRewardAPRPerNewCont(ContType _cType) external view returns (uint256) {
        uint256 changesLength = aprChangesHistory[_cType].length;
        uint256 result = initRewardAPRPerCont[_cType];
        for (uint256 i = 0; i < changesLength; i++) {
            result = reduceByPercent(result, aprChangesHistory[_cType][i].reducedPercentage);
        }
        return result;
    }

    function totalContsPerContType(ContType _cType) external view returns (uint256) {
        return _totalContsPerContType[_cType];
    }

    function _isContOwner(address account) external view returns (bool) {
        return isContOwner(account);
    }

    function _getRewardAmountOf(address account) external view returns (uint256) {
        if (!isContOwner(account)) return 0;

        uint256 rewardCount = 0;

        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        uint256 currentTstamp = block.timestamp;

        for (uint256 i = 0; i < contsCount; i++) {
            ContEntity memory _cont = conts[i];
            rewardCount += contRewardInInterval(_cont, _cont.lastUpdateTime, currentTstamp);
        }

        return rewardCount;
    }

    function _getRewardAmountOfIndex(address account, uint256 _contIndex) external view returns (uint256) {
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 numberOfConts = conts.length;
        require(_contIndex >= 0 && _contIndex < numberOfConts, "CONT: Cont index is improper");
        ContEntity memory cont = conts[_contIndex];
        uint256 rewardCont = contRewardInInterval(cont, cont.lastUpdateTime, block.timestamp);
        return rewardCont;
    }

    function _getContsNames(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        ContEntity memory _cont;
        string memory names = conts[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < contsCount; i++) {
            _cont = conts[i];
            names = string(abi.encodePacked(names, separator, _cont.name));
        }
        return names;
    }

    function _getContsCreationTime(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        ContEntity memory _cont;
        string memory _creationTimes = uint2str(conts[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < contsCount; i++) {
            _cont = conts[i];
            _creationTimes = string(abi.encodePacked(_creationTimes, separator, uint2str(_cont.creationTime)));
        }
        return _creationTimes;
    }

    function _getContsTypes(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        ContEntity memory _cont;
        string memory _types = uint2str(uint256(conts[0].cType));
        string memory separator = "#";

        for (uint256 i = 1; i < contsCount; i++) {
            _cont = conts[i];
            _types = string(abi.encodePacked(_types, separator, uint2str(uint256(_cont.cType))));
        }
        return _types;
    }

    function _getContsInitialAPR(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        ContEntity memory _cont;
        string memory _types = uint2str(conts[0].initialAPR);
        string memory separator = "#";

        for (uint256 i = 1; i < contsCount; i++) {
            _cont = conts[i];
            _types = string(abi.encodePacked(_types, separator, uint2str(_cont.initialAPR)));
        }
        return _types;
    }

    function _getContsCurrentAPR(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";

        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        ContEntity memory _cont;
        string memory _types = uint2str(currentAPRSingleCont(conts[0]));
        string memory separator = "#";

        for (uint256 i = 1; i < contsCount; i++) {
            _cont = conts[i];
            _types = string(abi.encodePacked(_types, separator, uint2str(currentAPRSingleCont(_cont))));
        }
        return _types;
    }

    function _getContsRewardAvailable(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        uint256 currentTstamp = block.timestamp;
        string memory _rewardsAvailable = uint2str(
            contRewardInInterval(conts[0], conts[0].lastUpdateTime, currentTstamp)
        );
        string memory separator = "#";
        for (uint256 i = 1; i < contsCount; i++) {
            _rewardsAvailable = string(
                abi.encodePacked(_rewardsAvailable, separator, uint2str(
                    contRewardInInterval(conts[i], conts[i].lastUpdateTime, currentTstamp)
                ))
            );
        }
        return _rewardsAvailable;
    }

    function _getContsLastUpdateTime(address account) external view returns (string memory) {
        if (!isContOwner(account)) return "";
        ContEntity[] memory conts = _contsOfUser[account];
        uint256 contsCount = conts.length;
        ContEntity memory _cont;
        string memory _lastUpdateTimes = uint2str(conts[0].lastUpdateTime);
        string memory separator = "#";

        for (uint256 i = 1; i < contsCount; i++) {
            _cont = conts[i];

            _lastUpdateTimes = string(abi.encodePacked(_lastUpdateTimes, separator, uint2str(_cont.lastUpdateTime)));
        }
        return _lastUpdateTimes;
    }

    function _getContNumberOf(address account) public view returns (uint256) {
        return contOwners.get(account);
    }

    // ----- Private/Internal Helpers -----
    function historyBinarySearch(ContType _cType, uint256 timestamp) private view returns (uint256) {
        uint256 leftIndex = 0;
        uint256 rightIndex = aprChangesHistory[_cType].length;
        while (rightIndex > leftIndex) {
            uint256 mid = (leftIndex + rightIndex) / 2;
            if (aprChangesHistory[_cType][mid].timestamp < timestamp) leftIndex = mid + 1;
            else rightIndex = mid;
        }
        return leftIndex;
    }

    function currentAPRSingleCont(ContEntity memory cont) private view returns (uint256) {
        return contAPRAt(cont, block.timestamp);
    }

    function contAPRAt(ContEntity memory cont, uint256 tstamp) private view returns (uint256) {
        uint256 creatime = cont.creationTime;
        ContType cType = cont.cType;
        uint256 resultAPR = cont.initialAPR;
        uint256 startIndex = historyBinarySearch(cType, creatime);
        uint256 endIndex = historyBinarySearch(cType, tstamp);
        for (uint256 i = startIndex; i < endIndex; i++) {
            resultAPR = reduceByPercent(resultAPR, aprChangesHistory[cType][i].reducedPercentage);
        }
        uint256 intervalCount = fullIntervalCount(tstamp, creatime);
        while (intervalCount > 0) {
            intervalCount--;
            resultAPR = reduceByPercent(resultAPR, int256(autoReduceAPRRate));
        }
        return resultAPR;
    }

    function contRewardInInterval(
        ContEntity memory cont,
        uint256 leftTstamp,
        uint256 rightTstamp
    ) private view returns (uint256) {
        ContType _cType = cont.cType;

        uint256 lastUpdateIndex = historyBinarySearch(_cType, leftTstamp);

        uint256 contBuyPrice = cont.buyPrice;
        uint256 itrAPR = contAPRAt(cont, leftTstamp);
        uint256 itrTstamp = leftTstamp;
        uint256 nextTstamp = 0;
        uint256 result = 0;
        uint256 deltaTstamp;
        uint256 intervalReward;
        uint256 creatime = cont.creationTime;
        bool diffInterval;
        for (uint256 index = lastUpdateIndex; index < aprChangesHistory[_cType].length; index++) {
            nextTstamp = aprChangesHistory[_cType][index].timestamp;
            diffInterval = (fullIntervalCount(nextTstamp, creatime) != fullIntervalCount(itrTstamp, creatime));
            if (diffInterval) {
                nextTstamp = creatime + autoReduceAPRInterval * (fullIntervalCount(itrTstamp, creatime) + 1);
            }
            deltaTstamp = nextTstamp - itrTstamp;
            intervalReward = (((contBuyPrice * itrAPR) / HUNDRED_PERCENT) * deltaTstamp) / UNIX_YEAR;
            itrTstamp = nextTstamp;
            result += intervalReward;

            if (diffInterval) {
                itrAPR = reduceByPercent(itrAPR, int256(autoReduceAPRRate));
                index--;
            } else {
                itrAPR = reduceByPercent(itrAPR, aprChangesHistory[_cType][index].reducedPercentage);
            }
        }

        while (itrTstamp != rightTstamp) {
            nextTstamp = rightTstamp;
            diffInterval = (fullIntervalCount(nextTstamp, creatime) != fullIntervalCount(itrTstamp, creatime));
            if (diffInterval) {
                nextTstamp = creatime + autoReduceAPRInterval * (fullIntervalCount(itrTstamp, creatime) + 1);
            }
            deltaTstamp = nextTstamp - itrTstamp;
            intervalReward = (((contBuyPrice * itrAPR) / HUNDRED_PERCENT) * deltaTstamp) / UNIX_YEAR;
            itrTstamp = nextTstamp;
            result += intervalReward;

            if (diffInterval) {
                itrAPR = reduceByPercent(itrAPR, int256(autoReduceAPRRate));
            }
        }
        return result;
    }

    function fullIntervalCount(uint256 input, uint256 creatime) private view returns (uint256) {
        return (input - creatime) / autoReduceAPRInterval;
    }

    function claimable(uint256 lastUpdateTime) private view returns (bool) {
        return lastUpdateTime + cashoutTimeout <= block.timestamp;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function reduceByPercent(uint256 input, int256 reducePercent) internal pure returns (uint256) {
        uint256 newPercentage = uint256(int256(HUNDRED_PERCENT) - reducePercent);
        return ((input * newPercentage) / HUNDRED_PERCENT);
    }

    function isContOwner(address account) private view returns (bool) {
        return contOwners.get(account) > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IJoeRouter02.sol";
import "../interfaces/IJoeFactory.sol";

contract LiquidityRouter is Initializable, PaymentSplitterUpgradeable {
    uint256 private constant HUNDRED_PERCENT = 100_000_000;

    // ----- Router Addresses -----
    IJoeRouter02 private uniswapV2Router;
    address public routerAddress;
    address public uniswapV2Pair;

    // ----- Contract Storage -----
    address payable public admin0xB;
    IERC20 private token;
    address public tokenAddress;

    uint256 public swapTaxFee;
    address public swapTaxPool;

    // ----- Constructor -----
    function initialize(
        address _router,
        uint256 _fee,
        address _pool
    ) public initializer {
        require(_router != address(0), "ROUTER ZERO");
        address[] memory payees = new address[](1);
        payees[0] = msg.sender;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;
        __PaymentSplitter_init(payees, shares);
        routerAddress = _router;
        uniswapV2Router = IJoeRouter02(_router);
        admin0xB = payable(msg.sender);

        swapTaxFee = _fee;
        swapTaxPool = _pool;
    }

    // ----- Event -----
    event Swapped(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event SwappedNative(uint256 amountIn, address tokenOut, uint256 amountOut);

    // ----- Modifier (filter) -----
    modifier onlyAuthorities() {
        require(msg.sender == tokenAddress || msg.sender == admin0xB, "Access Denied!");
        _;
    }

    // ----- External READ functions -----
    function getOutputAmount(
        bool is0xBOut,
        address targetToken,
        uint256 inputAmount
    ) public view returns (uint256) {
        address[] memory path = getPath(targetToken, is0xBOut);
        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(inputAmount, path);
        uint256 result = amountsOut[amountsOut.length - 1];
        result = (result * (HUNDRED_PERCENT - swapTaxFee)) / HUNDRED_PERCENT;
        return result;
    }

    function getInputAmount(
        bool is0xBOut,
        address targetToken,
        uint256 outputAmount
    ) public view returns (uint256) {
        address[] memory path = getPath(targetToken, is0xBOut);
        uint256[] memory amountsIn = uniswapV2Router.getAmountsIn(outputAmount, path);
        uint256 result = amountsIn[0];
        result = (result * (HUNDRED_PERCENT + swapTaxFee)) / HUNDRED_PERCENT;
        return result;
    }

    function wrappedNative() public view returns (address) {
        return uniswapV2Router.WAVAX();
    }

    // ----- External WRITE functions -----
    function updateSwapTaxPool(address payable newPool) external onlyAuthorities {
        require(newPool != address(0), "UPD_WALL: zero addr");
        swapTaxPool = newPool;
    }

    function updateSwapFee(uint256 value) external onlyAuthorities {
        require(value <= HUNDRED_PERCENT, "FEES: swap exceeding 100%");
        swapTaxFee = value;
    }

    function setToken(address _token) external onlyAuthorities {
        require(_token != address(0), "NEW_TOKEN: zero addr");
        tokenAddress = _token;
        token = IERC20(_token);
        address _uniswapV2Pair;
        try IJoeFactory(uniswapV2Router.factory()).createPair(tokenAddress, uniswapV2Router.WAVAX()) {
            _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory()).getPair(tokenAddress, uniswapV2Router.WAVAX());
        } catch {
            _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory()).getPair(tokenAddress, uniswapV2Router.WAVAX());
        }
        uniswapV2Pair = _uniswapV2Pair;
    }

    function updateUniswapV2Router(address _newAddr) external onlyAuthorities {
        require(_newAddr != address(uniswapV2Router), "TKN: The router already has that address");
        routerAddress = _newAddr;
        uniswapV2Router = IJoeRouter02(_newAddr);
        address _uniswapV2Pair;
        try IJoeFactory(uniswapV2Router.factory()).createPair(tokenAddress, uniswapV2Router.WAVAX()) {
            _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory()).getPair(tokenAddress, uniswapV2Router.WAVAX());
        } catch {
            _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory()).getPair(tokenAddress, uniswapV2Router.WAVAX());
        }
        uniswapV2Pair = _uniswapV2Pair;
    }

    // Only use to fund wallets
    function swapExact0xBForTokenNoFee(
        address receiver,
        address outTokenAddr,
        uint256 amountIn
    ) external onlyAuthorities {
        if (token.allowance(address(this), routerAddress) < amountIn) {
            token.approve(routerAddress, uint256(2**256 - 1));
        }
        address[] memory path = getPath(outTokenAddr, false);
        uint256[] memory result;
        if (outTokenAddr == uniswapV2Router.WAVAX()) {
            result = uniswapV2Router.swapExactTokensForAVAX(amountIn, 0, path, receiver, block.timestamp);
        } else {
            result = uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, receiver, block.timestamp);
        }
    }

    function swapExact0xBForToken(
        address receiver,
        address outTokenAddr,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyAuthorities {
        if (token.allowance(address(this), routerAddress) < amountIn) {
            token.approve(routerAddress, uint256(2**256 - 1));
        }

        require(getOutputAmount(false, outTokenAddr, amountIn) >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        uint256 fee = (amountIn * swapTaxFee) / HUNDRED_PERCENT;
        token.transfer(swapTaxPool, fee);

        address[] memory path = getPath(outTokenAddr, false);
        uint256[] memory result;
        if (outTokenAddr == uniswapV2Router.WAVAX()) {
            result = uniswapV2Router.swapExactTokensForAVAX(amountIn - fee, amountOutMin, path, receiver, deadline);
        } else {
            result = uniswapV2Router.swapExactTokensForTokens(amountIn - fee, amountOutMin, path, receiver, deadline);
        }
        emit Swapped(tokenAddress, amountIn, outTokenAddr, result[result.length - 1]);
    }

    function swap0xBForExactToken(
        address receiver,
        address outTokenAddr,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 deadline
    ) external onlyAuthorities {
        if (token.allowance(address(this), routerAddress) < amountInMax) {
            token.approve(routerAddress, uint256(2**256 - 1));
        }

        require(getInputAmount(false, outTokenAddr, amountOut) <= amountInMax, "INSUFFICIENT_INPUT_AMOUNT");
        address[] memory path = getPath(outTokenAddr, false);
        uint256[] memory result;
        if (outTokenAddr == uniswapV2Router.WAVAX()) {
            result = uniswapV2Router.swapTokensForExactAVAX(amountOut, amountInMax, path, receiver, deadline);
        } else {
            result = uniswapV2Router.swapTokensForExactTokens(amountOut, amountInMax, path, receiver, deadline);
        }
        uint256 amountInActual = result[0];
        uint256 fee = (amountInActual * swapTaxFee) / HUNDRED_PERCENT;

        // return residual tokens to sender
        token.transfer(swapTaxPool, fee);
        token.transfer(receiver, amountInMax - amountInActual - fee);
        emit Swapped(tokenAddress, amountInActual, outTokenAddr, amountOut);
    }

    function swapExactTokenFor0xB(
        address receiver,
        address inTokenAddr,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyAuthorities {
        if (IERC20(inTokenAddr).allowance(address(this), routerAddress) < amountIn) {
            approveTokenAccess(inTokenAddr);
        }
        require(getOutputAmount(true, inTokenAddr, amountIn) >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        uint256 fee = (amountIn * swapTaxFee) / HUNDRED_PERCENT;
        IERC20(inTokenAddr).transfer(swapTaxPool, fee);

        address[] memory path = getPath(inTokenAddr, true);
        uint256[] memory result = uniswapV2Router.swapExactTokensForTokens(
            amountIn - fee,
            amountOutMin,
            path,
            receiver,
            deadline
        );
        emit Swapped(inTokenAddr, amountIn, tokenAddress, result[result.length - 1]);
    }

    function swapTokenForExact0xB(
        address receiver,
        address inTokenAddr,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 deadline
    ) external onlyAuthorities {
        if (IERC20(inTokenAddr).allowance(address(this), routerAddress) < amountInMax) {
            approveTokenAccess(inTokenAddr);
        }
        require(getInputAmount(true, inTokenAddr, amountOut) <= amountInMax, "INSUFFICIENT_INPUT_AMOUNT");
        address[] memory path = getPath(inTokenAddr, true);
        uint256[] memory result = uniswapV2Router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            receiver,
            deadline
        );
        uint256 amountInActual = result[0];
        uint256 fee = (amountInActual * swapTaxFee) / HUNDRED_PERCENT;

        // return residual tokens to sender
        IERC20(inTokenAddr).transfer(swapTaxPool, fee);
        IERC20(inTokenAddr).transfer(receiver, amountInMax - amountInActual - fee);
        emit Swapped(inTokenAddr, amountInActual, tokenAddress, amountOut);
    }

    function swapExactAVAXFor0xB(
        address receiver,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable onlyAuthorities {
        uint256 amountIn = msg.value;
        require(getOutputAmount(true, wrappedNative(), amountIn) >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
        uint256 fee = (amountIn * swapTaxFee) / HUNDRED_PERCENT;
        payable(swapTaxPool).transfer(fee);
        address[] memory path = getPath(wrappedNative(), true);
        uint256[] memory result = uniswapV2Router.swapExactAVAXForTokens{ value: amountIn - fee }(
            amountOutMin,
            path,
            receiver,
            deadline
        );
        emit SwappedNative(amountIn, tokenAddress, result[result.length - 1]);
    }

    function swapAVAXForExact0xB(
        address receiver,
        uint256 amountOut,
        uint256 deadline
    ) external payable onlyAuthorities {
        // uint256 amountInMax = msg.value;
        address[] memory path = getPath(wrappedNative(), true);
        uint256[] memory result = uniswapV2Router.swapAVAXForExactTokens{ value: msg.value }(
            amountOut,
            path,
            receiver,
            deadline
        );
        uint256 amountInActual = result[0];
        uint256 fee = (amountInActual * swapTaxFee) / HUNDRED_PERCENT;

        // return residual tokens to sender
        payable(swapTaxPool).transfer(fee);
        payable(receiver).transfer(msg.value - amountInActual - fee);
        emit SwappedNative(amountInActual, tokenAddress, amountOut);
    }

    // ----- Private/Internal Helpers -----
    function approveTokenAccess(address tokenAddr) internal {
        IERC20 targetToken = IERC20(tokenAddr);
        targetToken.approve(routerAddress, uint256(2**256 - 1));
    }

    function getPath(address target, bool is0xBOut) internal view returns (address[] memory) {
        if (target == uniswapV2Router.WAVAX()) {
            address[] memory result = new address[](2);

            if (is0xBOut) {
                result[0] = target;
                result[1] = tokenAddress;
            } else {
                result[0] = tokenAddress;
                result[1] = target;
            }
            return result;
        }

        address[] memory res = new address[](3);
        res[1] = uniswapV2Router.WAVAX();
        if (is0xBOut) {
            res[0] = target;
            res[2] = tokenAddress;
        } else {
            res[0] = tokenAddress;
            res[2] = target;
        }
        return res;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int256) {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}