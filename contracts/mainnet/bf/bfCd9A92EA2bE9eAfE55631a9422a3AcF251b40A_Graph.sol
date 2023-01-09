// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param _token The address of the token spent
    /// @param _value The amount that can be spent of token
    /// @param _deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param _token The address of the token spent
    /// @param _value The amount that can be spent of token
    /// @param _deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param _v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param _r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param _s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;
}

abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable override {
        IERC20Permit(_token).permit(msg.sender, address(this), _value, _deadline, _v, _r, _s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address _token,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable override {
        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        if (allowance < _value) selfPermit(_token, _value - allowance, _deadline, _v, _r, _s);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library MathUtils {
    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 10**21;

    /**
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(
        uint256 _amount,
        uint256 _fracNum,
        uint256 _fracDenom
    ) internal pure returns (uint256) {
        return (_amount * percPoints(_fracNum, _fracDenom)) / PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return (_amount * _fracNum) / PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return (_fracNum * PERC_DIVISOR) / _fracDenom;
    }

    /**
     * @notice Compares a and b and returns true if the difference between a and b
     *         is less than 1 or equal to each other.
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return True if the difference between a and b is less than 1 or equal,
     *         otherwise return false
     */
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        return (difference(a, b) <= 1);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        }
        return b - a;
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ITenderToken.sol";
import "../tenderizer/ITenderizer.sol";

/**
 * @title TenderFarm
 * @notice TenderFarm is responsible for incetivizing liquidity providers, by accepting LP Tokens
 * and a proportionaly rewarding them with TenderTokens over time.
 */
interface ITenderFarm {
    /**
     * @notice Farm gets emitted when an account stakes LP tokens.
     * @param account the account for which LP tokens were staked
     * @param amount the amount of LP tokens staked
     */
    event Farm(address indexed account, uint256 amount);

    /**
     * @notice Unfarm gets emitted when an account unstakes LP tokens.
     * @param account the account for which LP tokens were unstaked
     * @param amount the amount of LP tokens unstaked
     */
    event Unfarm(address indexed account, uint256 amount);

    /**
     * @notice Harvest gets emitted when an accounts harvests outstanding
     * rewards.
     * @param account the account which harvested rewards
     * @param amount the amount of rewards harvested
     */
    event Harvest(address indexed account, uint256 amount);

    /**
     * @notice RewardsAdded gets emitted when new rewards are added
     * and a new epoch begins
     * @param amount amount of rewards that were addedd
     */
    event RewardsAdded(uint256 amount);

    function initialize(
        IERC20 _stakeToken,
        ITenderToken _rewardToken,
        ITenderizer _tenderizer
    ) external returns (bool);

    /**
     * @notice stake liquidity pool tokens to receive rewards
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev harvests current rewards before accounting updates are made.
     * @param _amount amount of liquidity pool tokens to stake
     */
    function farm(uint256 _amount) external;

    /**
     * @notice allow spending token and stake liquidity pool tokens to receive rewards
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev harvests current rewards before accounting updates are made.
     * @dev calls permit on LP Token.
     * @param _amount amount of liquidity pool tokens to stake
     * @param _deadline deadline of the permit
     * @param _v v of signed Permit message
     * @param _r r of signed Permit message
     * @param _s s of signed Permit message
     */
    function farmWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice stake liquidity pool tokens for a specific account so that it receives rewards
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev staked tokens will belong to the account they are staked for.
     * @dev harvests current rewards before accounting updates are made.
     * @param _for account to stake for
     * @param _amount amount of liquidity pool tokens to stake
     */
    function farmFor(address _for, uint256 _amount) external;

    /**
     * @notice unstake liquidity pool tokens
     * @dev '_amount' needs to be approved for the 'TenderFarm' to transfer.
     * @dev harvests current rewards before accounting updates are made.
     * @param amount amount of liquidity pool tokens to stake
     */
    function unfarm(uint256 amount) external;

    /**
     * @notice harvest outstanding rewards
     * @dev reverts when trying to harvest multiple times if no new rewards have been added.
     * @dev emits an event with how many reward tokens have been harvested.
     */
    function harvest() external;

    /**
     * @notice add new rewards
     * @dev will 'start' a new 'epoch'.
     * @dev only callable by owner.
     * @param _amount amount of reward tokens to add
     */
    function addRewards(uint256 _amount) external;

    /**
     * @notice Check available rewards for an account.
     * @param _for address address of the account to check rewards for.
     * @return amount rewards for the provided account address.
     */
    function availableRewards(address _for) external view returns (uint256 amount);

    /**
     * @notice Check stake for an account.
     * @param _of address address of the account to check stake for.
     * @return amount LP tokens deposited for address
     */
    function stakeOf(address _of) external view returns (uint256 amount);

    /**
     * @notice Return the total amount of LP tokens staked in this farm.
     * @return stake total amount of LP tokens staked
     */
    function totalStake() external view returns (uint256 stake);

    /**
     * @notice Return the total amount of LP tokens staked
     * for the next reward epoch.
     * @return nextStake LP Tokens staked for next round
     */
    function nextTotalStake() external view returns (uint256 nextStake);

    /**
     * @notice Changes the tenderizer of the contract
     * @param _tenderizer address of the new tenderizer
     */
    function setTenderizer(ITenderizer _tenderizer) external;
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ITenderFarm.sol";
import "../token/ITenderToken.sol";
import "../tenderizer/ITenderizer.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract TenderFarmFactory {
    ITenderFarm immutable farmTarget;

    constructor(ITenderFarm _farm) {
        farmTarget = _farm;
    }

    event NewTenderFarm(ITenderFarm farm, IERC20 stakeToken, ITenderToken rewardToken, ITenderizer tenderizer);

    function deploy(
        IERC20 _stakeToken,
        ITenderToken _rewardToken,
        ITenderizer _tenderizer
    ) external returns (ITenderFarm farm) {
        farm = ITenderFarm(Clones.clone(address(farmTarget)));

        require(farm.initialize(_stakeToken, _rewardToken, _tenderizer), "FAIL_INIT_TENDERFARM");

        emit NewTenderFarm(farm, _stakeToken, _rewardToken, _tenderizer);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../libs/MathUtils.sol";

import "../../Tenderizer.sol";
import "../../WithdrawalPools.sol";
import "./IGraph.sol";

import { ITenderSwapFactory } from "../../../tenderswap/TenderSwapFactory.sol";

contract Graph is Tenderizer {
    using WithdrawalPools for WithdrawalPools.Pool;
    using SafeERC20 for IERC20;

    // Eventws for WithdrawalPool
    event ProcessUnstakes(address indexed from, address indexed node, uint256 amount);
    event ProcessWithdraws(address indexed from, uint256 amount);

    // 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    IGraph graph;

    WithdrawalPools.Pool withdrawPool;

    uint256 pendingMigration;

    address newNode;

    function initialize(
        IERC20 _steak,
        string calldata _symbol,
        IGraph _graph,
        address _node,
        uint256 _protocolFee,
        uint256 _liquidityFee,
        ITenderToken _tenderTokenTarget,
        TenderFarmFactory _tenderFarmFactory,
        ITenderSwapFactory _tenderSwapFactory
    ) external {
        Tenderizer._initialize(
            _steak,
            _symbol,
            _node,
            _protocolFee,
            _liquidityFee,
            _tenderTokenTarget,
            _tenderFarmFactory,
            _tenderSwapFactory
        );
        graph = _graph;
    }

    function migrateUnlock(address _newNode) external virtual onlyGov returns (uint256 lockID) {
        uint256 amount = _tokensToMigrate(node);

        // Check that there's no pending migration
        require(pendingMigration == 0, "PENDING_MIGRATION");

        // store penging migration amount & new node
        pendingMigration = amount;
        newNode = _newNode;

        // set new node
        lockID = _unstake(address(this), node, amount);
    }

    function migrateWithdraw(uint256 _unstakeLockID) external virtual onlyGov {
        // reset pending migration amount
        pendingMigration = 0;
        _withdraw(address(this), _unstakeLockID);
        _claimRewards();
    }

    function _calcDepositOut(uint256 _amountIn) internal view override returns (uint256) {
        return _amountIn - ((uint256(graph.delegationTaxPercentage()) * _amountIn) / MAX_PPM);
    }

    function _deposit(address _from, uint256 _amount) internal override {
        currentPrincipal += _calcDepositOut(_amount);

        emit Deposit(_from, _amount);
    }

    function _stake(uint256 _amount) internal override {
        // Only stake available tokens that are not pending withdrawal
        uint256 amount = _amount;
        uint256 pendingWithdrawals = withdrawPool.getAmount();

        // This check also validates 'amount - pendingWithdrawals' > 0
        if (amount <= pendingWithdrawals) {
            return;
        }

        amount -= pendingWithdrawals;

        // approve amount to Graph protocol
        steak.safeIncreaseAllowance(address(graph), amount);

        // stake tokens
        uint256 delegatedShares = graph.delegate(node, amount);
        assert(delegatedShares > 0);

        emit Stake(node, amount);
    }

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal override returns (uint256 unstakeLockID) {
        uint256 amount = _amount;
        unstakeLockID = withdrawPool.unlock(_account, amount);
        emit Unstake(_account, _node, amount, unstakeLockID);
    }

    function processUnstake() external onlyGov {
        uint256 amount = withdrawPool.processUnlocks();

        // Calculate the amount of shares to undelegate
        IGraph.DelegationPool memory delPool = graph.delegationPools(node);
        uint256 totalShares = delPool.shares;
        uint256 totalTokens = delPool.tokens;

        uint256 shares = (amount * totalShares) / totalTokens;

        // Check that calculated shares doesn't exceed actual shares owned
        // account of round-off error resulting in calculating 1 share less
        IGraph.Delegation memory delegation = graph.getDelegation(node, address(this));
        if (shares >= delegation.shares - 1) {
            shares = delegation.shares;
        }

        // Shares =  amount * totalShares / totalTokens
        // undelegate shares
        graph.undelegate(node, shares);

        emit ProcessUnstakes(msg.sender, node, amount);

        if(newNode != address(0)){
            node = newNode;
            newNode = address(0);
        }
    }

    function _withdraw(address _account, uint256 _withdrawalID) internal override {
        uint256 amount = withdrawPool.withdraw(_withdrawalID, _account);

        // Transfer amount from unbondingLock to _account
        try steak.transfer(_account, amount) {} catch {
            // Account for roundoff errors in shares calculations
            uint256 steakBal = steak.balanceOf(address(this));
            if (amount > steakBal) {
                steak.safeTransfer(_account, steakBal);
            }
        }

        emit Withdraw(_account, amount, _withdrawalID);
    }

    function processWithdraw(address _node) external onlyGov {
        uint256 balBefore = steak.balanceOf(address(this));

        graph.withdrawDelegated(_node, address(0));

        uint256 balAfter = steak.balanceOf(address(this));
        uint256 amount = balAfter - balBefore;

        withdrawPool.processWihdrawal(amount);

        emit ProcessWithdraws(msg.sender, amount);
    }

    function _claimSecondaryRewards() internal override {}

    function _processNewStake() internal override returns (int256 rewards) {
        uint256 stake = _tokensDelegated(node);

        uint256 currentPrincipal_ = currentPrincipal;

        // exclude tokens to be withdrawn from balance
        // add pendingMigration amount
        uint256 stakeRemainder = _calcDepositOut(
            steak.balanceOf(address(this)) - withdrawPool.amount + pendingMigration
        );

        // calculate what the new currentPrinciple would be
        // exclude pendingUnlocks from stake
        stake = (stake - withdrawPool.pendingUnlock) + stakeRemainder;

        rewards = int256(stake) - int256(currentPrincipal_);

        // Difference is negative, slash withdrawalpool
        if (rewards < 0) {
            // calculate amount to subtract relative to current principal
            uint256 unstakePoolTokens = withdrawPool.totalTokens();
            uint256 totalTokens = unstakePoolTokens + currentPrincipal_;
            if (totalTokens > 0) {
                uint256 unstakePoolSlash = ((currentPrincipal_ - stake) * unstakePoolTokens) / totalTokens;
                withdrawPool.updateTotalTokens(unstakePoolTokens - unstakePoolSlash);
            }
        }

        emit RewardsClaimed(rewards, stake, currentPrincipal_);
    }

    function _tokensDelegated(address _node) internal view returns (uint256) {
        IGraph.Delegation memory delegation = graph.getDelegation(_node, address(this));
        IGraph.DelegationPool memory delPool = graph.delegationPools(_node);

        uint256 delShares = delegation.shares;
        uint256 totalShares = delPool.shares;
        uint256 totalTokens = delPool.tokens;

        if (totalShares == 0) return 0;

        return (delShares * totalTokens) / totalShares;
    }

    function _tokensToMigrate(address _node) internal view override returns (uint256) {
        return _tokensDelegated(_node) - withdrawPool.pendingUnlock;
    }

    function _setStakingContract(address _stakingContract) internal override {
        emit GovernanceUpdate(GovernanceParameter.STAKING_CONTRACT, abi.encode(graph), abi.encode(_stakingContract));
        graph = IGraph(_stakingContract);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IGraph {
    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        // mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    function getDelegation(address _indexer, address _delegator) external view returns (Delegation memory);

    function delegationPools(address _indexer) external view returns (DelegationPool memory);

    function getWithdraweableDelegatedTokens(Delegation memory _delegation) external view returns (uint256);

    function thawingPeriod() external view returns (uint256);

    function delegationTaxPercentage() external view returns (uint32);
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../tenderfarm/ITenderFarm.sol";

enum GovernanceParameter {
    GOV,
    NODE,
    STEAK,
    PROTOCOL_FEE,
    LIQUIDITY_FEE,
    TENDERFARM,
    STAKING_CONTRACT
}

/**
 * @title Tenderizer is the base contract to be implemented.
 * @notice Tenderizer is responsible for all Protocol interactions (staking, unstaking, claiming rewards)
 * while also keeping track of user depsotis/withdrawals and protocol fees.
 * @dev New implementations are required to inherit this contract and override any required internal functions.
 */
interface ITenderizer {
    // Events

    /**
     * @notice Deposit gets emitted when an accounts deposits underlying tokens.
     * @param from the account that deposited
     * @param amount the amount of tokens deposited
     */
    event Deposit(address indexed from, uint256 amount);

    /**
     * @notice Stake gets emitted when funds are staked/delegated from the Tenderizer contract
     * into the underlying protocol.
     * @param node the address the funds are staked to
     * @param amount the amount staked
     */
    event Stake(address indexed node, uint256 amount);

    /**
     * @notice Unstake gets emitted when an account burns TenderTokens to unlock
     * tokens staked through the Tenderizer
     * @param from the account that unstaked
     * @param node the node in the underlying token from which tokens are unstaked
     * @param amount the amount unstaked
     */
    event Unstake(address indexed from, address indexed node, uint256 amount, uint256 unstakeLockID);

    /**
     * @notice Withdraw gets emitted when an account withdraws tokens that have been
     * succesfully unstaked and thus unlocked for withdrawal.
     * @param from the account withdrawing tokens
     * @param amount the amount being withdrawn
     * @param unstakeLockID the unstake lock ID being consumed
     */
    event Withdraw(address indexed from, uint256 amount, uint256 unstakeLockID);

    /**
     * @notice RewardsClaimed gets emitted when the Tenderizer processes staking rewards (or slashing)
     * from the underlying protocol.
     * @param stakeDiff the stake difference since the last event, can be negative in case slashing occured
     * @param currentPrincipal TVL after claiming rewards
     * @param oldPrincipal TVL before claiming rewards
     */
    event RewardsClaimed(int256 stakeDiff, uint256 currentPrincipal, uint256 oldPrincipal);

    /**
     * @notice ProtocolFeeCollected gets emitted when the treasury claims its outstanding
     * protocol fees.
     * @param amount the amount of fees claimed (in TenderTokens)
     */
    event ProtocolFeeCollected(uint256 amount);

    /**
     * @notice LiquidityFeeCollected gets emitted when liquidity provider fees are moved to the TenderFarm.
     * @param amount the amount of fees moved for farming
     */
    event LiquidityFeeCollected(uint256 amount);

    /**
     * @notice GovernanceUpdate gets emitted when a parameter on the Tenderizer gets updated.
     * @param param the parameter that got updated
     * @param oldValue oldValue of the parameter
      @param newValue newValue of the parameter
     */
    event GovernanceUpdate(GovernanceParameter param, bytes oldValue, bytes newValue);

    /**
     * @notice Deposit tokens in Tenderizer.
     * @param _amount amount deposited
     * @dev doesn't actually stakes the tokens but aggregates the balance in the tenderizer
     * awaiting to be staked.
     * @dev requires '_amount' to be approved by '_from'.
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice Deposit tokens in Tenderizer with permit.
     * @param _amount amount deposited
     * @param _deadline deadline for the permit
     * @param _v from ECDSA signature
     * @param _r from ECDSA signature
     * @param _s from ECDSA signature
     * @dev doesn't actually stakes the tokens but aggregates the balance in the tenderizer
     * awaiting to be staked.
     * @dev requires '_amount' to be approved by '_from'.
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Stake '_amount' of tokens.
     * @param _amount amount to stake
     * @dev Only callable by Gov.
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Unstake '_amount' of tokens from '_account'.
     * @param _amount amount to unstake
     * @return unstakeLockID unstake lockID generated for unstake
     * @dev unstake from the default address.
     * @dev If '_amount' is 0, unstake the entire amount staked towards _account.
     */
    function unstake(uint256 _amount) external returns (uint256 unstakeLockID);

    /**
     * @notice RescueUnstake unstakes all tokens from underlying protocol
     * @return unstakeLockID unstake lockID generated for unstake
     * @dev Used to rescue all staked funds.
     */
    function rescueUnlock() external returns (uint256 unstakeLockID);

    /**
     * @notice Withdraw '_amount' of tokens previously unstaked by '_account'.
     * @param _unstakeLockID ID for the lock to request the withdraw for
     * @dev If '_amount' isn't specified all unstake tokens by '_account' will be withdrawn.
     * @dev Requires '_account' to have unstaked prior to calling withdraw.
     */
    function withdraw(uint256 _unstakeLockID) external;

    /**
     * @notice RescueWithdraw withdraws all tokens into the Tenderizer from the underlying protocol
     * after the unlock period ends
     * @dev To be called after rescueUnlock() with the unstakeLockID returned there.
     * @dev Process unlocks/withdrawals before rescueWithdraw for integrations with WithdrawPools.
     */
    function rescueWithdraw(uint256 _unstakeLockID) external;

    /**
     * @notice Compound all the rewards and new deposits.
     * Claim staking rewards and earned fees for the underlying protocol and stake
     * any leftover token balance. Process Tender protocol fees if revenue is positive.
     */
    function claimRewards() external;

    /**
     * @notice Total Staked Tokens returns the total amount of underlying tokens staked by this Tenderizer.
     * @return totalStaked total amount staked by this Tenderizer
     */
    function totalStakedTokens() external view returns (uint256 totalStaked);

    /**
     * @notice Returns the number of tenderTokens to be minted for amountIn deposit.
     * @return depositOut number of tokens staked for `amountIn`.
     * @dev used by controller to calculate tokens to be minted before depositing.
     * @dev to be used when there a delegation tax is deducted, for eg. in Graph.
     */
    function calcDepositOut(uint256 _amountIn) external returns (uint256 depositOut);

    // Governance setter funtions

    function setGov(address _gov) external;

    function setNode(address _node) external;

    function setSteak(IERC20 _steak) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setLiquidityFee(uint256 _liquidityFee) external;

    function setStakingContract(address _stakingContract) external;

    function setTenderFarm(ITenderFarm _tenderFarm) external;
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITotalStakedReader {
    /**
     * @notice Total Staked Tokens returns the total amount of underlying tokens staked by this Tenderizer.
     * @return _totalStakedTokens total amount staked by this Tenderizer
     */
    function totalStakedTokens() external view returns (uint256 _totalStakedTokens);
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { GovernanceParameter, ITenderizer } from "./ITenderizer.sol";
import "../token/ITenderToken.sol";
import { ITenderSwapFactory, ITenderSwap } from "../tenderswap/TenderSwapFactory.sol";
import "../tenderfarm/TenderFarmFactory.sol";
import "../libs/MathUtils.sol";
import "../helpers/SelfPermit.sol";

/**
 * @title Tenderizer is the base contract to be implemented.
 * @notice Tenderizer is responsible for all Protocol interactions (staking, unstaking, claiming rewards)
 * while also keeping track of user depsotis/withdrawals and protocol fees.
 * @dev New implementations are required to inherit this contract and override any required internal functions.
 */
abstract contract Tenderizer is Initializable, ITenderizer, SelfPermit {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_FEE = 5 * 10**20;

    IERC20 public steak;
    ITenderToken public tenderToken;
    ITenderFarm public tenderFarm;
    ITenderSwap public tenderSwap;

    address public node;

    uint256 public protocolFee;
    uint256 public liquidityFee;
    uint256 public currentPrincipal; // Principal since last claiming earnings

    address public gov;

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    function _initialize(
        IERC20 _steak,
        string memory _symbol,
        address _node,
        uint256 _protocolFee,
        uint256 _liquidityFee,
        ITenderToken _tenderTokenTarget,
        TenderFarmFactory _tenderFarmFactory,
        ITenderSwapFactory _tenderSwapFactory
    ) internal initializer {
        steak = _steak;
        node = _node;
        protocolFee = _protocolFee;
        liquidityFee = _liquidityFee;

        gov = msg.sender;

        // Clone TenderToken
        ITenderToken tenderToken_ = ITenderToken(Clones.clone(address(_tenderTokenTarget)));
        string memory tenderTokenSymbol = string(abi.encodePacked("t", _symbol));
        require(tenderToken_.initialize(_symbol, _symbol, ITotalStakedReader(address(this))), "FAIL_INIT_TENDERTOKEN");
        tenderToken = tenderToken_;

        tenderSwap = _tenderSwapFactory.deploy(
            ITenderSwapFactory.Config({
                token0: IERC20(address(tenderToken_)),
                token1: _steak,
                lpTokenName: string(abi.encodePacked(tenderTokenSymbol, "-", _symbol, " Swap Token")),
                lpTokenSymbol: string(abi.encodePacked(tenderTokenSymbol, "-", _symbol, "-SWAP"))
            })
        );

        // Transfer ownership from tenderizer to deployer so params an be changed directly
        // and no additional functions are needed on the tenderizer
        tenderSwap.transferOwnership(msg.sender);

        tenderFarm = _tenderFarmFactory.deploy(
            IERC20(address(tenderSwap.lpToken())),
            tenderToken_,
            ITenderizer(address(this))
        );
    }

    /// @inheritdoc ITenderizer
    function deposit(uint256 _amount) external override {
        _depositHook(msg.sender, _amount);
    }

    /// @inheritdoc ITenderizer
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        selfPermit(address(steak), _amount, _deadline, _v, _r, _s);

        _depositHook(msg.sender, _amount);
    }

    /// @inheritdoc ITenderizer
    function unstake(uint256 _amount) external override returns (uint256) {
        require(_amount > 0, "ZERO_AMOUNT");

        require(tenderToken.burn(msg.sender, _amount), "TENDER_BURN_FAILED");
        // Execute state updates to pending withdrawals
        // Unstake tokens
        uint256 id = _unstake(msg.sender, node, _amount);
        currentPrincipal -= _amount;
        return id;
    }

    /// @inheritdoc ITenderizer
    function rescueUnlock() external override onlyGov returns (uint256) {
        return _unstake(address(this), node, _tokensToMigrate(node));
    }

    /// @inheritdoc ITenderizer
    function withdraw(uint256 _unstakeLockID) external override {
        // Execute state updates to pending withdrawals
        // Transfer tokens to _account
        _withdraw(msg.sender, _unstakeLockID);
    }

    /// @inheritdoc ITenderizer
    function rescueWithdraw(uint256 _unstakeLockID) external override onlyGov {
        _withdraw(address(this), _unstakeLockID);
    }

    /// @inheritdoc ITenderizer
    function claimRewards() external override {
        _claimRewards();
    }

    /// @inheritdoc ITenderizer
    function totalStakedTokens() external view override returns (uint256) {
        return _totalStakedTokens();
    }

    function _tokensToMigrate(
        address /*_node*/
    ) internal view virtual returns (uint256) {
        return currentPrincipal;
    }

    /// @inheritdoc ITenderizer
    function stake(uint256 _amount) external override onlyGov {
        // Execute state updates
        // approve pendingTokens for staking
        // Stake tokens
        _stake(_amount);
    }

    function setGov(address _gov) external virtual override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.GOV, abi.encode(gov), abi.encode(_gov));
        gov = _gov;
    }

    function setNode(address _node) external virtual override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.NODE, abi.encode(node), abi.encode(_node));
        node = _node;
    }

    function setSteak(IERC20 _steak) external virtual override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.STEAK, abi.encode(steak), abi.encode(_steak));
        steak = _steak;
    }

    function setProtocolFee(uint256 _protocolFee) external virtual override onlyGov {
        require(_protocolFee <= MAX_FEE, "FEE_EXCEEDS_MAX");
        emit GovernanceUpdate(GovernanceParameter.PROTOCOL_FEE, abi.encode(protocolFee), abi.encode(_protocolFee));
        protocolFee = _protocolFee;
    }

    function setLiquidityFee(uint256 _liquidityFee) external virtual override onlyGov {
        require(_liquidityFee <= MAX_FEE, "FEE_EXCEEDS_MAX");
        emit GovernanceUpdate(GovernanceParameter.LIQUIDITY_FEE, abi.encode(liquidityFee), abi.encode(_liquidityFee));
        liquidityFee = _liquidityFee;
    }

    function setStakingContract(address _stakingContract) external override onlyGov {
        _setStakingContract(_stakingContract);
    }

    function setTenderFarm(ITenderFarm _tenderFarm) external override onlyGov {
        emit GovernanceUpdate(GovernanceParameter.TENDERFARM, abi.encode(tenderFarm), abi.encode(_tenderFarm));
        tenderFarm = _tenderFarm;
    }

    /// @inheritdoc ITenderizer
    function calcDepositOut(uint256 _amountIn) external view override returns (uint256) {
        return _calcDepositOut(_amountIn);
    }

    // Internal functions

    function _depositHook(address _for, uint256 _amount) internal {
        require(_amount > 0, "ZERO_AMOUNT");

        // Calculate tenderTokens to be minted
        uint256 amountOut = _calcDepositOut(_amount);

        // mint tenderTokens
        require(tenderToken.mint(_for, amountOut), "TENDER_MINT_FAILED");

        // Transfer tokens to tenderizer
        steak.safeTransferFrom(_for, address(this), _amount);

        _deposit(_for, _amount);
    }

    function _calcDepositOut(uint256 _amountIn) internal view virtual returns (uint256) {
        return _amountIn;
    }

    function _deposit(address _account, uint256 _amount) internal virtual;

    function _stake(uint256 _amount) internal virtual;

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal virtual returns (uint256 unstakeLockID);

    function _withdraw(address _account, uint256 _unstakeLockID) internal virtual;

    function _claimRewards() internal virtual {
        _claimSecondaryRewards();

        int256 rewards = _processNewStake();

        if (rewards > 0) {
            uint256 rewards_ = uint256(rewards);
            uint256 pFees = _calculateFees(rewards_, protocolFee);
            uint256 lFees = _calculateFees(rewards_, liquidityFee);
            currentPrincipal += (rewards_ - pFees - lFees);

            _collectFees(pFees);
            _collectLiquidityFees(lFees);
        } else if (rewards < 0) {
            uint256 rewards_ = uint256(-rewards);
            currentPrincipal -= rewards_;
        }

        _stake(steak.balanceOf(address(this)));
    }

    function _claimSecondaryRewards() internal virtual;

    function _processNewStake() internal virtual returns (int256 rewards);

    function _collectFees(uint256 fees) internal virtual {
        tenderToken.mint(gov, fees);
        currentPrincipal += fees;
        emit ProtocolFeeCollected(fees);
    }

    function _collectLiquidityFees(uint256 liquidityFees) internal virtual {
        // Don't transfer liquidity provider fees if there is no liquidity being farmed
        if (tenderFarm.nextTotalStake() <= 0) return;

        uint256 balBefore = tenderToken.balanceOf(address(this));
        tenderToken.mint(address(this), liquidityFees);
        currentPrincipal += liquidityFees;
        uint256 balAfter = tenderToken.balanceOf(address(this));
        uint256 stakeDiff = balAfter - balBefore;
        // minting sometimes generates a little less, due to share calculation
        // hence using the balance to transfer here
        tenderToken.approve(address(tenderFarm), stakeDiff);
        tenderFarm.addRewards(stakeDiff);
        emit LiquidityFeeCollected(stakeDiff);
    }

    function _calculateFees(uint256 _rewards, uint256 _feePerc) internal pure returns (uint256 fees) {
        return MathUtils.percOf(_rewards, _feePerc);
    }

    function _totalStakedTokens() internal view virtual returns (uint256) {
        return currentPrincipal;
    }

    function _setStakingContract(address _stakingContract) internal virtual;

    function _onlyGov() internal view {
        require(msg.sender == gov);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

import "../libs/MathUtils.sol";
pragma solidity 0.8.4;

/**
 * @title WithdrawalPools are used to batch user unlocks/withdrawals together
 * @notice These are used for protocols that do not support simultaneous unlocks
 */
library WithdrawalPools {
    struct Withdrawal {
        uint256 shares; // shares
        address receiver; // address of the receiver of this withdrawal, usually the caller of unlock
        uint256 epoch; // epoch at time of unlock
    }

    struct Pool {
        mapping(uint256 => Withdrawal) withdrawals; // key,value to keep track of withdrawals
        uint256 withdrawalID; // incrementor to keep track of the key for the 'withdrawals' mapping
        uint256 shares; // total outstanding shares of the unstake pool
        uint256 amount; // total amount of available tokens
        uint256 pendingUnlock; // amount of tokens to unlock
        uint256 pendingWithdrawal; // amount of tokens unlocked, pending withdrawal
        uint256 epoch; // current epoch start (e.g. incrementor or block number)
        uint256 lastEpoch; // last completed epoch (withdrawal completed)
    }

    function unlock(
        Pool storage _pool,
        address _receiver,
        uint256 _amount
    ) internal returns (uint256 withdrawalID) {
        withdrawalID = _pool.withdrawalID;

        uint256 shares = calcShares(_pool, _amount);

        _pool.withdrawals[withdrawalID] = Withdrawal({ shares: shares, receiver: _receiver, epoch: _pool.epoch });

        _pool.pendingUnlock += _amount;

        _pool.shares += shares;

        _pool.withdrawalID++;
    }

    function withdraw(
        Pool storage _pool,
        uint256 _withdrawalID,
        address _account
    ) internal returns (uint256 withdrawAmount) {
        Withdrawal memory withdrawal = _pool.withdrawals[_withdrawalID];

        require(withdrawal.epoch < _pool.lastEpoch, "ONGOING_UNLOCK");
        require(_account == withdrawal.receiver, "ACCOUNT_MISTMATCH");

        withdrawAmount = calcAmount(_pool, withdrawal.shares);

        _pool.amount -= withdrawAmount;

        _pool.shares -= withdrawal.shares;

        delete _pool.withdrawals[_withdrawalID];
    }

    function processUnlocks(Pool storage _pool) internal returns (uint256 pendingUnlock_) {
        require(_pool.epoch == _pool.lastEpoch, "ONGOING_UNLOCK");
        _pool.pendingWithdrawal += _pool.pendingUnlock;
        pendingUnlock_ = _pool.pendingUnlock;
        _pool.pendingUnlock = 0;
        _pool.epoch = block.number;
    }

    function processWihdrawal(Pool storage _pool, uint256 _received) internal {
        require(_pool.epoch > _pool.lastEpoch, "ONGOING_UNLOCK");
        _pool.amount += _received;
        _pool.pendingWithdrawal = 0;
        _pool.lastEpoch = _pool.epoch;
    }

    function updateTotalTokens(Pool storage _pool, uint256 _newAmount) internal {
        // calculate relative amounts to subtract from 'amount' and 'pendingUnlock'
        uint256 amount_ = _pool.amount;
        uint256 pendingUnlock_ = _pool.pendingUnlock;
        uint256 total = amount_ + pendingUnlock_;
        if (total > 0) {
            _pool.amount = (_newAmount * amount_) / total;
            _pool.pendingUnlock = (_newAmount * pendingUnlock_) / total;
        }
    }

    function totalTokens(Pool storage _pool) internal view returns (uint256) {
        return _pool.amount + _pool.pendingUnlock + _pool.pendingWithdrawal;
    }

    function getAmount(Pool storage _pool) internal view returns (uint256) {
        return _pool.amount;
    }

    function epoch(Pool storage _pool) internal view returns (uint256) {
        return _pool.epoch;
    }

    function lastEpoch(Pool storage _pool) internal view returns (uint256) {
        return _pool.lastEpoch;
    }

    function getWithdrawal(Pool storage _pool, uint256 _withdrawalID) internal view returns (Withdrawal memory) {
        return _pool.withdrawals[_withdrawalID];
    }

    function calcShares(Pool storage _pool, uint256 _amount) internal view returns (uint256 shares) {
        uint256 totalTokens_ = totalTokens(_pool);
        uint256 totalShares = _pool.shares;

        if (totalTokens_ == 0) return _amount;

        if (totalShares == 0) return _amount;

        return MathUtils.percOf(_amount, totalShares, totalTokens_);
    }

    function calcAmount(Pool storage _pool, uint256 _shares) internal view returns (uint256) {
        uint256 totalShares = _pool.shares;
        if (totalShares == 0) return 0;

        return MathUtils.percOf(_shares, totalTokens(_pool), totalShares);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LiquidityPoolToken.sol";

pragma solidity 0.8.4;

/**
 * @title TenderSwap
 * @dev TenderSwap is a light-weight StableSwap implementation for two assets.
 * See the Curve StableSwap paper for more details (https://curve.fi/files/stableswap-paper.pdf).
 * that trade 1:1 with eachother (e.g. USD stablecoins or tenderToken derivatives vs their underlying assets).
 * It supports Elastic Supply ERC20 tokens, which are tokens of which the balances can change
 * as the total supply of the token 'rebases'.
 */

interface ITenderSwap {
    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients

    /**
     * @notice Swap gets emitted when an accounts exchanges tokens.
     * @param buyer address of the account initiating the swap
     * @param tokenSold address of the swapped token
     * @param amountSold amount of tokens swapped
     * @param amountReceived amount of tokens received in exchange
     */
    event Swap(address indexed buyer, IERC20 tokenSold, uint256 amountSold, uint256 amountReceived);

    /**
     * @notice AddLiquidity gets emitted when liquidity is added to the pool.
     * @param provider address of the account providing liquidity
     * @param tokenAmounts array of token amounts provided corresponding to pool cardinality of [token0, token1]
     * @param fees fees deducted for each of the tokens added corresponding to pool cardinality of [token0, token1]
     * @param invariant pool invariant after adding liquidity
     * @param lpTokenSupply the lpToken supply after minting
     */
    event AddLiquidity(
        address indexed provider,
        uint256[2] tokenAmounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    /**
     * @notice RemoveLiquidity gets emitted when liquidity for both tokens
     * is removed from the pool.
     * @param provider address of the account removing liquidity
     * @param tokenAmounts array of token amounts removed corresponding to pool cardinality of [token0, token1]
     * @param lpTokenSupply total supply of liquidity pool token after removing liquidity
     */
    event RemoveLiquidity(address indexed provider, uint256[2] tokenAmounts, uint256 lpTokenSupply);

    /**
     * @notice RemoveLiquidityOne gets emitted when single-sided liquidity is removed 
     * @param provider address of the account removing liquidity
     * @param lpTokenAmount amount of liquidity pool tokens burnt
     * @param lpTokenSupply total supply of liquidity pool token after removing liquidity

     * @param tokenReceived address of the token for which liquidity was removed
     * @param receivedAmount amount of tokens received
     */
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        IERC20 tokenReceived,
        uint256 receivedAmount
    );

    /**
     * @notice RemoveLiquidityImbalance gets emitted when liquidity is removed weighted differently than the
     * pool's current balances.
     * with different weights than that of the pool.
     * @param provider address of the the account removing liquidity imbalanced
     * @param tokenAmounts array of amounts of tokens being removed corresponding
     * to pool cardinality of [token0, token1]
     * @param fees fees for each of the tokens removed corresponding to pool cardinality of [token0, token1]
     * @param invariant pool invariant after removing liquidity
     * @param lpTokenSupply total supply of liquidity pool token after removing liquidity
     */
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] tokenAmounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    /**
     * @notice NewAdminFee gets emitted when the admin fee is updated.
     * @param newAdminFee admin fee after update
     */
    event NewAdminFee(uint256 newAdminFee);

    /**
     * @notice NewSwapFee gets emitted when the swap fee is updated.
     * @param newSwapFee swap fee after update
     */
    event NewSwapFee(uint256 newSwapFee);

    /**
     * @notice RampA gets emitted when A has started ramping up.
     * @param oldA initial A value
     * @param newA target value of A to ramp up to
     * @param initialTime ramp start timestamp
     * @param futureTime ramp end timestamp
     */
    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    /**
     * @notice StopRampA gets emitted when ramping A is stopped manually
     * @param currentA current value of A
     * @param time timestamp of when ramp is stopped
     */
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _token0 First token in the pool
     * @param _token1 Second token in the pool
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param lpTokenTargetAddress the address of an existing LiquidityPoolToken contract to use as a target
     * @return success true is successfully initialized
     */
    function initialize(
        IERC20 _token0,
        IERC20 _token1,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        LiquidityPoolToken lpTokenTargetAddress
    ) external returns (bool success);

    /*** VIEW FUNCTIONS ***/
    /**
     * @notice Returns the liquidity pool token contract.
     * @return lpTokenContract Liquidity pool token contract.
     */
    function lpToken() external view returns (LiquidityPoolToken lpTokenContract);

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @return a the amplifaction coefficient
     */
    function getA() external view returns (uint256 a);

    /**
     * @notice Return A in its raw precision form
     * @dev See the StableSwap paper for details
     * @return aPrecise A parameter in its raw precision form
     */
    function getAPrecise() external view returns (uint256 aPrecise);

    /**
     * @notice Returns the contract address for token0
     * @dev EVM return type is IERC20
     * @return token0 contract address
     */
    function getToken0() external view returns (IERC20 token0);

    /**
     * @notice Returns the contract address for token1
     * @dev EVM return type is IERC20
     * @return token1 contract address
     */
    function getToken1() external view returns (IERC20 token1);

    /**
     * @notice Return current balance of token0 (tender) in the pool
     * @return token0Balance current balance of the pooled tendertoken
     */
    function getToken0Balance() external view returns (uint256 token0Balance);

    /**
     * @notice Return current balance of token1 (underlying) in the pool
     * @return token1Balance current balance of the pooled underlying token
     */
    function getToken1Balance() external view returns (uint256 token1Balance);

    /**
     * @notice Get the override price, to help calculate profit
     * @return virtualPrice the override price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice() external view returns (uint256 virtualPrice);

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param _tokenFrom the token the user wants to sell
     * @param _dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return tokensToReceive amount of tokens the user will receive
     */
    function calculateSwap(IERC20 _tokenFrom, uint256 _dx) external view returns (uint256 tokensToReceive);

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param amount the amount of LP tokens that would be burned on withdrawal
     * @return tokensToReceive array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[2] memory tokensToReceive);

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param tokenAmount the amount of LP token to burn
     * @param tokenReceive the token to receive
     * @return tokensToReceive calculated amount of underlying token to be received.
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(uint256 tokenAmount, IERC20 tokenReceive)
        external
        view
        returns (uint256 tokensToReceive);

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pool cardinality of [token0, token1]. The amount should be in each
     * pooled token's native precision.
     * @param deposit whether this is a deposit or a withdrawal
     * @return tokensToReceive token amount the user will receive
     */
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256 tokensToReceive);

    /*** POOL FUNCTIONALITY ***/

    /**
     * @notice Swap two tokens using this pool
     * @dev revert is token being sold is not in the pool.
     * @param _tokenFrom the token the user wants to sell
     * @param _dx the amount of tokens the user wants to swap from
     * @param _minDy the min amount the user would like to receive, or revert
     * @param _deadline latest timestamp to accept this transaction
     * @return _dy amount of tokens received
     */
    function swap(
        IERC20 _tokenFrom,
        uint256 _dx,
        uint256 _minDy,
        uint256 _deadline
    ) external returns (uint256 _dy);

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param _amounts the amounts of each token to add, in their native precision
     *          according to the cardinality of the pool [token0, token1]
     * @param _minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param _deadline latest timestamp to accept this transaction
     * @return lpMinted amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[2] calldata _amounts,
        uint256 _minToMint,
        uint256 _deadline
    ) external returns (uint256 lpMinted);

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     *        according to the cardinality of the pool [token0, token1]
     * @param deadline latest timestamp to accept this transaction
     * @return tokensReceived is the amounts of tokens user received
     */
    function removeLiquidity(
        uint256 amount,
        uint256[2] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[2] memory tokensReceived);

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param _tokenAmount the amount of the token you want to receive
     * @param _tokenReceive the  token you want to receive
     * @param _minAmount the minimum amount to withdraw, otherwise revert
     * @param _deadline latest timestamp to accept this transaction
     * @return tokensReceived amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 _tokenAmount,
        IERC20 _tokenReceive,
        uint256 _minAmount,
        uint256 _deadline
    ) external returns (uint256 tokensReceived);

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     * @param _amounts how much of each token to withdraw
     * @param _maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param _deadline latest timestamp to accept this transaction
     * @return lpBurned amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[2] calldata _amounts,
        uint256 _maxBurnAmount,
        uint256 _deadline
    ) external returns (uint256 lpBurned);

    /*** ADMIN FUNCTIONALITY ***/
    /**
     * @notice Update the admin fee. Admin fee takes portion of the swap fee.
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(uint256 newAdminFee) external;

    /**
     * @notice Update the swap fee to be applied on swaps
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(uint256 newSwapFee) external;

    /**
     * @notice Start ramping up or down A parameter towards given futureA and futureTime
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param futureA the new A to ramp towards
     * @param futureTime timestamp when the new A should be reached
     */
    function rampA(uint256 futureA, uint256 futureTime) external;

    /**
     * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
     */
    function stopRampA() external;

    /**
     * @notice Changes the owner of the contract
     * @param _newOwner address of the new owner
     */
    function transferOwnership(address _newOwner) external;
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

contract LiquidityPoolToken is OwnableUpgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable {
    /**
     * @notice Initializes this LPToken contract with the given name and symbol
     * @dev The caller of this function will become the owner. A Swap contract should call this
     * in its initializer function.
     * @param name name of this token
     * @param symbol symbol of this token
     */
    function initialize(string memory name, string memory symbol) external initializer returns (bool) {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
        __Ownable_init_unchained();
        return true;
    }

    /**
     * @notice Mints the given amount of LPToken to the recipient.
     * @dev only owner can call this mint function.
     * @param recipient address of account to receive the tokens
     * @param amount amount of tokens to mint
     */

    function mint(address recipient, uint256 amount) external onlyOwner {
        require(amount != 0, "LPToken: cannot mint 0");
        _mint(recipient, amount);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ITenderSwap.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface ITenderSwapFactory {
    struct Config {
        IERC20 token0;
        IERC20 token1;
        string lpTokenName;
        string lpTokenSymbol; // e.g. tLPT-LPT-SWAP
    }

    function deploy(Config calldata _config) external returns (ITenderSwap);
}

contract TenderSwapFactoryV1 is ITenderSwapFactory {
    event NewTenderSwap(
        ITenderSwap tenderSwap,
        string lpTokenName,
        string lpTokenSymbol,
        uint256 amplifier,
        uint256 fee,
        uint256 adminFee
    );

    ITenderSwap immutable tenderSwapTarget;
    LiquidityPoolToken immutable lpTokenTarget;
    uint256 immutable amplifier;
    uint256 immutable fee;
    uint256 immutable adminFee;

    constructor(
        ITenderSwap _tenderSwapTarget,
        LiquidityPoolToken _lpTokenTarget,
        uint256 _amplifier,
        uint256 _fee,
        uint256 _adminFee
    ) {
        tenderSwapTarget = _tenderSwapTarget;
        lpTokenTarget = _lpTokenTarget;
        amplifier = _amplifier;
        fee = _fee;
        adminFee = _adminFee;
    }

    function deploy(Config calldata _config) external override returns (ITenderSwap tenderSwap) {
        tenderSwap = ITenderSwap(Clones.clone(address(tenderSwapTarget)));

        require(
            tenderSwap.initialize(
                _config.token0,
                _config.token1,
                _config.lpTokenName,
                _config.lpTokenSymbol,
                amplifier,
                fee,
                adminFee,
                lpTokenTarget
            ),
            "FAIL_INIT_TENDERSWAP"
        );

        tenderSwap.transferOwnership(msg.sender);

        emit NewTenderSwap(tenderSwap, _config.lpTokenName, _config.lpTokenSymbol, amplifier, fee, adminFee);
    }
}

// SPDX-FileCopyrightText: 2021 Tenderize <[email protected]>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../tenderizer/ITotalStakedReader.sol";

/**
 * @title Interest-bearing ERC20-like token for Tenderize protocol.
 * @author Tenderize <[email protected]>
 * @dev TenderToken balances are dynamic and are calculated based on the accounts' shares
 * and the total amount of Tokens controlled by the protocol. Account shares aren't
 * normalized, so the contract also stores the sum of all shares to calculate
 * each account's token balance which equals to:
 *
 * shares[account] * _getTotalPooledTokens() / _getTotalShares()
 */
interface ITenderToken {
    /**
     * @notice Initilize the TenderToken Contract
     * @param _name name of the token (steak)
     * @param _symbol symbol of the token (steak)
     * @param _stakedReader contract address implementing the ITotalStakedReader interface
     * @return a boolean value indicating whether the init succeeded.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        ITotalStakedReader _stakedReader
    ) external returns (bool);

    /**
     * @notice The number of decimals the TenderToken uses.
     * @return decimals the number of decimals for getting user representation of a token amount.
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice The total supply of tender tokens in existence.
     * @dev Always equals to `_getTotalPooledTokens()` since token amount
     * is pegged to the total amount of Tokens controlled by the protocol.
     * @return totalSupply total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Total amount of underlying tokens controlled by the Tenderizer.
     * @dev The sum of all Tokens balances in the protocol, equals to the total supply of TenderToken.
     * @return totalPooledTokens total amount of pooled tokens
     */
    function getTotalPooledTokens() external view returns (uint256);

    /**
     * @notice The total amount of shares in existence.
     * @dev The sum of all accounts' shares can be an arbitrary number, therefore
     * it is necessary to store it in order to calculate each account's relative share.
     * @return totalShares total amount of shares
     */
    function getTotalShares() external view returns (uint256);

    /**
     * @notice the amount of tokens owned by the `_account`.
     * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
        total Tokens controlled by the protocol. See `sharesOf`.
     * @param _account address of the account to check the balance for
     * @return balance token balance of `_account`
     */
    function balanceOf(address _account) external view returns (uint256);

    /**
     * @notice The amount of shares owned by an account
     * @param _account address of the account
     * @return shares the amount of shares owned by `_account`.
     */
    function sharesOf(address _account) external view returns (uint256);

    /**
     * @notice The remaining number of tokens that `_spender` is allowed to spend
     * behalf of `_owner` through `transferFrom`. This is zero by default.
     * @dev This value changes when `approve` or `transferFrom` is called.
     * @param _owner address that approved the allowance
     * @param _spender address that is allowed to spend the allowance
     * @return allowance amount '_spender' is allowed to spend from '_owner'
     */
    function allowance(address _owner, address _spender) external view returns (uint256);

    /**
     * @notice The amount of shares that corresponds to `_tokens` protocol-controlled Tokens.
     * @param _tokens amount of tokens to calculate shares for
     * @return shares nominal amount of shares the tokens represent
     */
    function tokensToShares(uint256 _tokens) external view returns (uint256);

    /**
     * @notice The amount of tokens that corresponds to `_shares` token shares.
     * @param _shares the amount of shares to calculate the amount of tokens for
     * @return tokens the amount of tokens represented by the shares
     */
    function sharesToTokens(uint256 _shares) external view returns (uint256);

    /**
     * @notice Transfers `_amount` tokens from the caller's account to the `_recipient` account.
     * @param _recipient address of the recipient
     * @param _amount amount of tokens to transfer
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Emits a `Transfer` event.
     * @dev Requirements:
     * - `_recipient` cannot be the zero address.
     * - the caller must have a balance of at least `_amount`.
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
     * @param _spender address of the spender allowed to approve tokens from caller
     * @param _amount amount of tokens to allow '_spender' to spend
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Emits an `Approval` event.
     * @dev Requirements:
     * - `_spender` cannot be the zero address.
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function approve(address _spender, uint256 _amount) external returns (bool);

    /**
     * @notice Transfers `_amount` tokens from `_sender` to `_recipient` using the
     * allowance mechanism. `_amount` is then deducted from the caller's allowance.
     * @param _sender address of the account to transfer tokens from
     * @param _recipient address of the recipient
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Emits a `Transfer` event.
     * @dev Emits an `Approval` event indicating the updated allowance.
     * @dev Requirements:
     * - `_sender` and `_recipient` cannot be the zero addresses.
     * - `_sender` must have a balance of at least `_amount`.
     * - the caller must have allowance for `_sender`'s tokens of at least `_amount`.
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice Atomically increases the allowance granted to `_spender` by the caller by `_addedValue`.
     * @param _spender address of the spender allowed to approve tokens from caller
     * @param _addedValue amount to add to allowance
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev This is an alternative to `approve` that can be used as a mitigation for problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * @dev Emits an `Approval` event indicating the updated allowance.
     * @dev Requirements:
     * - `_spender` cannot be the the zero address.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `_spender` by the caller by `_subtractedValue`.
     * @param _spender address of the spender allowed to approve tokens from caller
     * @param _subtractedValue amount to subtract from current allowance
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev This is an alternative to `approve` that can be used as a mitigation for problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * @dev Emits an `Approval` event indicating the updated allowance.
     * @dev Requirements:
     * - `_spender` cannot be the zero address.
     * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);

    /**
     * @notice Mints '_amount' of tokens for '_recipient'
     * @param _recipient address to mint tokens for
     * @param _amount amount to mint
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Only callable by contract owner
     * @dev Calculates the amount of shares to create based on the specified '_amount'
     * and creates new shares rather than minting actual tokens
     * @dev '_recipient' should also deposit into Tenderizer
     * atomically to prevent diluation of existing particpants
     */
    function mint(address _recipient, uint256 _amount) external returns (bool);

    /**
     * @notice Burns '_amount' of tokens from '_recipient'
     * @param _account address to burn the tokens from
     * @param _amount amount to burn
     * @return success a boolean value indicating whether the operation succeeded.
     * @dev Only callable by contract owner
     * @dev Calculates the amount of shares to destroy based on the specified '_amount'
     * and destroy shares rather than burning tokens
     * @dev '_recipient' should also withdraw from Tenderizer atomically
     */
    function burn(address _account, uint256 _amount) external returns (bool);

    /**
     * @notice sets a TotalStakedReader to read the total staked tokens from
     * @param _stakedReader contract address implementing the ITotalStakedReader interface
     * @dev Only callable by contract owner.
     * @dev Used to determine TenderToken total supply.
     */
    function setTotalStakedReader(ITotalStakedReader _stakedReader) external;
}