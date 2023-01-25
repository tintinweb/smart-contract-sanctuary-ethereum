// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/** @title IControlledToken
 * @author Asymetrix Protocol Inc Team
 * @notice ERC20 Tokens with a controller for minting & burning.
 */
interface IControlledToken is IERC20Upgradeable {
    /**
        @notice Interface to the contract responsible for controlling mint/burn
    */
    function controller() external view returns (address);

    /**
     * @notice Allows the controller to mint tokens for a user account
     * @dev    May be overridden to provide more granular control over minting
     * @param user Address of the receiver of the minted tokens
     * @param amount Amount of tokens to mint
     */
    function controllerMint(address user, uint256 amount) external;

    /**
     * @notice Allows the controller to burn tokens from a user account
     * @dev    May be overridden to provide more granular control over burning
     * @param user Address of the holder account to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function controllerBurn(address user, uint256 amount) external;

    /**
     * @notice Allows an operator via the controller to burn tokens on behalf of
     *         a user account
     * @dev    May be overridden to provide more granular control over
     *         operator-burning
     * @param operator Address of the operator performing the burn action via
     *        the controller contract
     * @param user Address of the holder account to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function controllerBurnFrom(
        address operator,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "../libraries/TwabLib.sol";

import "./IControlledToken.sol";

interface ITicket is IControlledToken {
    /**
     * @notice A struct containing details for an Account.
     * @param balance The current balance for an Account.
     * @param nextTwabIndex The next available index to store a new twab.
     * @param cardinality The number of recorded twabs (plus one!).
     */
    struct AccountDetails {
        uint224 balance;
        uint16 nextTwabIndex;
        uint16 cardinality;
    }

    /**
     * @notice Combines account details with their twab history.
     * @param details The account details.
     * @param twabs The history of twabs for this account.
     */
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[65535] twabs;
    }

    /**
     * @notice Emitted when TWAB balance has been delegated to another user.
     * @param delegator Address of the delegator.
     * @param delegate Address of the delegate.
     */
    event Delegated(address indexed delegator, address indexed delegate);

    /**
     * @notice Emitted when ticket is initialized.
     * @param name Ticket name (eg: Asymetrix Protocol Dai Ticket (Compound)).
     * @param symbol Ticket symbol (eg: AsxDAI).
     * @param decimals Ticket decimals.
     * @param controller Token controller address.
     */
    event TicketInitialized(
        string name,
        string symbol,
        uint8 decimals,
        address indexed controller
    );

    /**
     * @notice Emitted when a new TWAB has been recorded.
     * @param delegate The recipient of the ticket power (may be the same as the
     *                 user).
     * @param newTwab Updated TWAB of a ticket holder after a successful TWAB
     *                recording.
     */
    event NewUserTwab(
        address indexed delegate,
        ObservationLib.Observation newTwab
    );

    /**
     * @notice Emitted when a new total supply TWAB has been recorded.
     * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a
     *                           successful total supply TWAB recording.
     */
    event NewTotalSupplyTwab(ObservationLib.Observation newTotalSupplyTwab);

    /**
     * @notice Retrieves the address of the delegate to whom `user` has
     *         delegated their tickets.
     * @dev Address of the delegate will be the zero address if `user` has not
     *      delegated their tickets.
     * @param user Address of the delegator.
     * @return Address of the delegate.
     */
    function delegateOf(address user) external view returns (address);

    /**
     * @notice Delegate time-weighted average balances to an alternative address.
     * @dev    Transfers (including mints) trigger the storage of a TWAB in
     *         delegate(s) account, instead of the targetted sender and/or
     *         recipient address(s).
     * @dev    To reset the delegate, pass the zero address (0x000.000) as `to`
     *         parameter.
     * @dev    Current delegate address should be different from the new
     *         delegate address `to`.
     * @param  to Recipient of delegated TWAB.
     */
    function delegate(address to) external;

    /**
     * @notice Allows the controller to delegate on a users behalf.
     * @param user The user for whom to delegate
     * @param delegate The new delegate
     */
    function controllerDelegateFor(address user, address delegate) external;

    /**
     * @notice Allows a user to delegate via signature
     * @param user The user who is delegating
     * @param delegate The new delegate
     * @param deadline The timestamp by which this must be submitted
     * @param v The v portion of the ECDSA sig
     * @param r The r portion of the ECDSA sig
     * @param s The s portion of the ECDSA sig
     */
    function delegateWithSignature(
        address user,
        address delegate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Gets a users twab context.  This is a struct with their balance,
     *         next twab index, and cardinality.
     * @param user The user for whom to fetch the TWAB context.
     * @return The TWAB context, which includes { balance, nextTwabIndex,
     *         cardinality }
     */
    function getAccountDetails(
        address user
    ) external view returns (TwabLib.AccountDetails memory);

    /**
     * @notice Gets the TWAB at a specific index for a user.
     * @param user The user for whom to fetch the TWAB.
     * @param index The index of the TWAB to fetch.
     * @return The TWAB, which includes the twab amount and the timestamp.
     */
    function getTwab(
        address user,
        uint16 index
    ) external view returns (ObservationLib.Observation memory);

    /**
     * @notice Retrieves `user` TWAB balance.
     * @param user Address of the user whose TWAB is being fetched.
     * @param timestamp Timestamp at which we want to retrieve the TWAB balance.
     * @return The TWAB balance at the given timestamp.
     */
    function getBalanceAt(
        address user,
        uint64 timestamp
    ) external view returns (uint256);

    /**
     * @notice Retrieves `user` TWAB balances.
     * @param user Address of the user whose TWABs are being fetched.
     * @param timestamps Timestamps range at which we want to retrieve the
     *                   TWAB balances.
     * @return `user` TWAB balances.
     */
    function getBalancesAt(
        address user,
        uint64[] calldata timestamps
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the average balance held by a user for a given time
     *         frame.
     * @param user The user whose balance is checked.
     * @param startTime The start time of the time frame.
     * @param endTime The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalanceBetween(
        address user,
        uint64 startTime,
        uint64 endTime
    ) external view returns (uint256);

    /**
     * @notice Retrieves the average balances held by a user for a given time
     *         frame.
     * @param user The user whose balance is checked.
     * @param startTimes The start time of the time frame.
     * @param endTimes The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalancesBetween(
        address user,
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the total supply TWAB balance at the given timestamp.
     * @param timestamp Timestamp at which we want to retrieve the total supply
     *                  TWAB balance.
     * @return The total supply TWAB balance at the given timestamp.
     */
    function getTotalSupplyAt(uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves the total supply TWAB balance between the given
     *         timestamps range.
     * @param timestamps Timestamps range at which we want to retrieve the total
     *                   supply TWAB balance.
     * @return Total supply TWAB balances.
     */
    function getTotalSuppliesAt(
        uint64[] calldata timestamps
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the average total supply balance for a set of given
     *         time frames.
     * @param startTimes Array of start times.
     * @param endTimes Array of end times.
     * @return The average total supplies held during the time frame.
     */
    function getAverageTotalSuppliesBetween(
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added
 * overflow checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This
 * can easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller
 * types, by performing all math on `uint256` and `int256` and then downcasting.
 */
library ExtendedSafeCastLib {
    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 _value) internal pure returns (uint104) {
        require(
            _value <= type(uint104).max,
            "SafeCast: value doesn't fit in 104 bits"
        );
        return uint104(_value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 _value) internal pure returns (uint208) {
        require(
            _value <= type(uint208).max,
            "SafeCast: value doesn't fit in 208 bits"
        );
        return uint208(_value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 _value) internal pure returns (uint224) {
        require(
            _value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(_value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";

/**
 * @title Observation Library
 * @notice This library allows one to store an array of timestamped values and
 *         efficiently binary search them.
 * @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
 * @author Asymetrix Protocol Inc.
 */
library ObservationLib {
    using OverflowSafeComparatorLib for uint32;
    using SafeCastUpgradeable for uint256;

    /// @notice The maximum number of observations
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /**
     * @notice Observation, which includes an amount and timestamp.
     * @param amount `amount` at `timestamp`.
     * @param timestamp Recorded `timestamp`.
     */
    struct Observation {
        uint224 amount;
        uint32 timestamp;
    }

    /**
     * @notice Fetches Observations `beforeOrAt` and `atOrAfter` a `_target`, eg: where [`beforeOrAt`, `atOrAfter`] is satisfied.
     * The result may be the same Observation, or adjacent Observations.
     * @dev The answer must be contained in the array used when the target is located within the stored Observation.
     * boundaries: older than the most recent Observation and younger, or the same age as, the oldest Observation.
     * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
     *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
     * @param _observations List of Observations to search through.
     * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
     * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
     * @param _target Timestamp at which we are searching the Observation.
     * @param _cardinality Cardinality of the circular buffer we are searching through.
     * @param _time Timestamp at which we perform the binary search.
     * @return beforeOrAt Observation recorded before, or at, the target.
     * @return atOrAfter Observation recorded at, or after, the target.
     */
    function binarySearch(
        Observation[MAX_CARDINALITY] storage _observations,
        uint24 _newestObservationIndex,
        uint24 _oldestObservationIndex,
        uint32 _target,
        uint24 _cardinality,
        uint32 _time
    )
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint256 leftSide = _oldestObservationIndex;
        uint256 rightSide = _newestObservationIndex < leftSide
            ? leftSide + _cardinality - 1
            : _newestObservationIndex;
        uint256 currentIndex;

        while (true) {
            // We start our search in the middle of the `leftSide` and `rightSide`.
            // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
            currentIndex = (leftSide + rightSide) / 2;

            beforeOrAt = _observations[
                uint24(RingBufferLib.wrap(currentIndex, _cardinality))
            ];
            uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

            // We've landed on an uninitialized timestamp, keep searching higher (more recently).
            if (beforeOrAtTimestamp == 0) {
                leftSide = currentIndex + 1;
                continue;
            }

            atOrAfter = _observations[
                uint24(RingBufferLib.nextIndex(currentIndex, _cardinality))
            ];

            bool targetAtOrAfter = beforeOrAtTimestamp.lte(_target, _time);

            // Check if we've found the corresponding Observation.
            if (targetAtOrAfter && _target.lte(atOrAfter.timestamp, _time)) {
                break;
            }

            // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
            if (!targetAtOrAfter) {
                rightSide = currentIndex - 1;
            } else {
                // Otherwise, we keep searching higher. To the left of the current index.
                leftSide = currentIndex + 1;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title OverflowSafeComparatorLib library to share comparator functions between contracts
/// @dev Code taken from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/3e88af408132fc957e3e406f65a0ce2b1ca06c3d/contracts/libraries/Oracle.sol
/// @author Asymetrix Protocol Inc.
library OverflowSafeComparatorLib {
    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically < `_b`.
    function lt(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a < _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2 ** 32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2 ** 32;

        return aAdjusted < bAdjusted;
    }

    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically <= `_b`.
    function lte(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a <= _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2 ** 32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2 ** 32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice 32-bit timestamp subtractor
    /// @dev safe for 0 or 1 overflows, where `_a` and `_b` must be chronologically before or equal to time
    /// @param _a The subtraction left operand
    /// @param _b The subtraction right operand
    /// @param _timestamp The current time.  Expected to be chronologically after both.
    /// @return The difference between a and b, adjusted for overflow
    function checkedSub(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (uint32) {
        // No need to adjust if there hasn't been an overflow

        if (_a <= _timestamp && _b <= _timestamp) return _a - _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2 ** 32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2 ** 32;

        return uint32(aAdjusted - bAdjusted);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

library RingBufferLib {
    /**
     * @notice Returns wrapped TWAB index.
     * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
     * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
     *       it will return 0 and will point to the first element of the array.
     * @param _index Index used to navigate through the TWAB circular buffer.
     * @param _cardinality TWAB buffer cardinality.
     * @return TWAB index.
     */
    function wrap(
        uint256 _index,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
     * @notice Computes the negative offset from the given index, wrapped by the cardinality.
     * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
     * @param _index The index from which to offset
     * @param _amount The number of indices to offset.  This is subtracted from the given index.
     * @param _cardinality The number of elements in the ring buffer
     * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        return wrap(_index + _cardinality - _amount, _cardinality);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _cardinality The cardinality of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(
        uint256 _nextIndex,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        if (_cardinality == 0) {
            return 0;
        }

        return wrap(_nextIndex + _cardinality - 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(
        uint256 _index,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        return wrap(_index + 1, _cardinality);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./ExtendedSafeCastLib.sol";
import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";
import "./ObservationLib.sol";

/**
  * @title  Asymetrix Protocol V1 TwabLib (Library)
  * @author Asymetrix Protocol Inc Team
  * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
  * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
            Each user is mapped to an Account struct containing the TWAB history (ring buffer) and
            ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new TWAB
            checkpoint is stored in the circular ring buffer, as either a new checkpoint or rewriting
            a previous checkpoint with new parameters. The TwabLib (using existing blocktimes of 1block/15sec)
            guarantees minimum 7.4 years of search history.
 */
library TwabLib {
    using OverflowSafeComparatorLib for uint32;
    using ExtendedSafeCastLib for uint256;

    /**
      * @notice Sets max ring buffer length in the Account.twabs Observation list.
                As users transfer/mint/burn tickets new Observation checkpoints are
                recorded. The current max cardinality guarantees a seven year minimum,
                of accurate historical lookups with current estimates of 1 new block
                every 15 seconds - assuming each block contains a transfer to trigger an
                observation write to storage.
      * @dev    The user Account.AccountDetails.cardinality parameter can NOT exceed
                the max cardinality variable. Preventing "corrupted" ring buffer lookup
                pointers and new observation checkpoints.

                The MAX_CARDINALITY in fact guarantees at least 7.4 years of records:
                If 14 = block time in seconds
                (2**24) * 14 = 234881024 seconds of history
                234881024 / (365 * 24 * 60 * 60) ~= 7.44 years
    */
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /** @notice Struct ring buffer parameters for single user Account
      * @param balance       Current balance for an Account
      * @param nextTwabIndex Next uninitialized or updatable ring buffer checkpoint storage slot
      * @param cardinality   Current total "initialized" ring buffer checkpoints for single user AccountDetails.
                             Used to set initial boundary conditions for an efficient binary search.
    */
    struct AccountDetails {
        uint208 balance;
        uint24 nextTwabIndex;
        uint24 cardinality;
    }

    /// @notice Combines account details with their twab history
    /// @param details The account details
    /// @param twabs The history of twabs for this account
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[MAX_CARDINALITY] twabs;
    }

    /// @notice Increases an account's balance and records a new twab.
    /// @param _account The account whose balance will be increased
    /// @param _amount The amount to increase the balance by
    /// @param _currentTime The current time
    /// @return accountDetails The new AccountDetails
    /// @return twab The user's latest TWAB
    /// @return isNew Whether the TWAB is new
    function increaseBalance(
        Account storage _account,
        uint208 _amount,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;
        (accountDetails, twab, isNew) = _nextTwab(
            _account.twabs,
            _accountDetails,
            _currentTime
        );
        accountDetails.balance = _accountDetails.balance + _amount;
    }

    /** @notice Calculates the next TWAB checkpoint for an account with a decreasing balance.
     * @dev    With Account struct and amount decreasing calculates the next TWAB observable checkpoint.
     * @param _account        Account whose balance will be decreased
     * @param _amount         Amount to decrease the balance by
     * @param _revertMessage  Revert message for insufficient balance
     * @return accountDetails Updated Account.details struct
     * @return twab           TWAB observation (with decreasing average)
     * @return isNew          Whether TWAB is new or calling twice in the same block
     */
    function decreaseBalance(
        Account storage _account,
        uint208 _amount,
        string memory _revertMessage,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;

        require(_accountDetails.balance >= _amount, _revertMessage);

        (accountDetails, twab, isNew) = _nextTwab(
            _account.twabs,
            _accountDetails,
            _currentTime
        );
        unchecked {
            accountDetails.balance -= _amount;
        }
    }

    /** @notice Calculates the average balance held by a user for a given time frame.
      * @dev    Finds the average balance between start and end timestamp epochs.
                Validates the supplied end time is within the range of elapsed time i.e. less then timestamp of now.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _startTime      Start of timestamp range as an epoch
      * @param _endTime        End of timestamp range as an epoch
      * @param _currentTime    Block.timestamp
      * @return Average balance of user held between epoch timestamps start and end
    */
    function getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 endTime = _endTime > _currentTime ? _currentTime : _endTime;

        return
            _getAverageBalanceBetween(
                _twabs,
                _accountDetails,
                _startTime,
                endTime,
                _currentTime
            );
    }

    /// @notice Retrieves the oldest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the oldest TWAB in the twabs array
    /// @return twab The oldest TWAB
    function oldestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    )
        internal
        view
        returns (uint24 index, ObservationLib.Observation memory twab)
    {
        index = _accountDetails.nextTwabIndex;
        twab = _twabs[index];

        // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
        if (twab.timestamp == 0) {
            index = 0;
            twab = _twabs[0];
        }
    }

    /// @notice Retrieves the newest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the newest TWAB in the twabs array
    /// @return twab The newest TWAB
    function newestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    )
        internal
        view
        returns (uint24 index, ObservationLib.Observation memory twab)
    {
        index = uint24(
            RingBufferLib.newestIndex(
                _accountDetails.nextTwabIndex,
                MAX_CARDINALITY
            )
        );
        twab = _twabs[index];
    }

    /// @notice Retrieves amount at `_targetTime` timestamp
    /// @param _twabs List of TWABs to search through.
    /// @param _accountDetails Accounts details
    /// @param _targetTime Timestamp at which the reserved TWAB should be for.
    /// @return uint256 TWAB amount at `_targetTime`.
    function getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 timeToTarget = _targetTime > _currentTime
            ? _currentTime
            : _targetTime;
        return
            _getBalanceAt(_twabs, _accountDetails, timeToTarget, _currentTime);
    }

    /// @notice Calculates the average balance held by a user for a given time frame.
    /// @param _startTime The start time of the time frame.
    /// @param _endTime The end time of the time frame.
    /// @return The average balance that the user held during the time frame.
    function _getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        (
            uint24 oldestTwabIndex,
            ObservationLib.Observation memory oldTwab
        ) = oldestTwab(_twabs, _accountDetails);

        (
            uint24 newestTwabIndex,
            ObservationLib.Observation memory newTwab
        ) = newestTwab(_twabs, _accountDetails);

        ObservationLib.Observation memory startTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _startTime,
            _currentTime
        );

        ObservationLib.Observation memory endTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _endTime,
            _currentTime
        );

        // Difference in amount / time
        return
            (endTwab.amount - startTwab.amount) /
            OverflowSafeComparatorLib.checkedSub(
                endTwab.timestamp,
                startTwab.timestamp,
                _currentTime
            );
    }

    /** @notice Searches TWAB history and calculate the difference between amount(s)/timestamp(s) to return average balance
                between the Observations closes to the supplied targetTime.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _targetTime     Target timestamp to filter Observations in the ring buffer binary search
      * @param _currentTime    Block.timestamp
      * @return uint256 Time-weighted average amount between two closest observations.
    */
    function _getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        uint24 newestTwabIndex;
        ObservationLib.Observation memory afterOrAt;
        ObservationLib.Observation memory beforeOrAt;
        (newestTwabIndex, beforeOrAt) = newestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically after the newest TWAB, we can simply return the current balance
        if (beforeOrAt.timestamp.lte(_targetTime, _currentTime)) {
            return _accountDetails.balance;
        }

        uint24 oldestTwabIndex;
        // Now, set before to the oldest TWAB
        (oldestTwabIndex, beforeOrAt) = oldestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically before the oldest TWAB, we can early return
        if (_targetTime.lt(beforeOrAt.timestamp, _currentTime)) {
            return 0;
        }

        // Otherwise, we perform the `binarySearch`
        (beforeOrAt, afterOrAt) = ObservationLib.binarySearch(
            _twabs,
            newestTwabIndex,
            oldestTwabIndex,
            _targetTime,
            _accountDetails.cardinality,
            _currentTime
        );

        // Sum the difference in amounts and divide by the difference in timestamps.
        // The time-weighted average balance uses time measured between two epoch timestamps as
        // a constaint on the measurement when calculating the time weighted average balance.
        return
            (afterOrAt.amount - beforeOrAt.amount) /
            OverflowSafeComparatorLib.checkedSub(
                afterOrAt.timestamp,
                beforeOrAt.timestamp,
                _currentTime
            );
    }

    /** @notice Calculates a user TWAB for a target timestamp using the historical TWAB records.
                The balance is linearly interpolated: amount differences / timestamp differences
                using the simple (after.amount - before.amount / end.timestamp - start.timestamp) formula.
    /** @dev    Binary search in _calculateTwab fails when searching out of bounds. Thus, before
                searching we exclude target timestamps out of range of newest/oldest TWAB(s).
                IF a search is before or after the range we "extrapolate" a Observation from the expected state.
      * @param _twabs           Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails  User AccountDetails struct loaded in memory
      * @param _newestTwab      Newest TWAB in history (end of ring buffer)
      * @param _oldestTwab      Olderst TWAB in history (end of ring buffer)
      * @param _newestTwabIndex Pointer in ring buffer to newest TWAB
      * @param _oldestTwabIndex Pointer in ring buffer to oldest TWAB
      * @param _targetTimestamp Epoch timestamp to calculate for time (T) in the TWAB
      * @param _time            Block.timestamp
      * @return accountDetails Updated Account.details struct
    */
    function _calculateTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        ObservationLib.Observation memory _newestTwab,
        ObservationLib.Observation memory _oldestTwab,
        uint24 _newestTwabIndex,
        uint24 _oldestTwabIndex,
        uint32 _targetTimestamp,
        uint32 _time
    ) private view returns (ObservationLib.Observation memory) {
        // If `_targetTimestamp` is chronologically after the newest TWAB, we extrapolate a new one
        if (_newestTwab.timestamp.lt(_targetTimestamp, _time)) {
            return
                _computeNextTwab(
                    _newestTwab,
                    _accountDetails.balance,
                    _targetTimestamp
                );
        }

        if (_newestTwab.timestamp == _targetTimestamp) {
            return _newestTwab;
        }

        if (_oldestTwab.timestamp == _targetTimestamp) {
            return _oldestTwab;
        }

        // If `_targetTimestamp` is chronologically before the oldest TWAB, we create a zero twab
        if (_targetTimestamp.lt(_oldestTwab.timestamp, _time)) {
            return
                ObservationLib.Observation({
                    amount: 0,
                    timestamp: _targetTimestamp
                });
        }

        // Otherwise, both timestamps must be surrounded by twabs.
        (
            ObservationLib.Observation memory beforeOrAtStart,
            ObservationLib.Observation memory afterOrAtStart
        ) = ObservationLib.binarySearch(
                _twabs,
                _newestTwabIndex,
                _oldestTwabIndex,
                _targetTimestamp,
                _accountDetails.cardinality,
                _time
            );

        uint224 heldBalance = (afterOrAtStart.amount - beforeOrAtStart.amount) /
            OverflowSafeComparatorLib.checkedSub(
                afterOrAtStart.timestamp,
                beforeOrAtStart.timestamp,
                _time
            );

        return _computeNextTwab(beforeOrAtStart, heldBalance, _targetTimestamp);
    }

    /**
     * @notice Calculates the next TWAB using the newestTwab and updated balance.
     * @dev    Storage of the TWAB obersation is managed by the calling function and not _computeNextTwab.
     * @param _currentTwab    Newest Observation in the Account.twabs list
     * @param _currentBalance User balance at time of most recent (newest) checkpoint write
     * @param _time           Current block.timestamp
     * @return TWAB Observation
     */
    function _computeNextTwab(
        ObservationLib.Observation memory _currentTwab,
        uint224 _currentBalance,
        uint32 _time
    ) private pure returns (ObservationLib.Observation memory) {
        // New twab amount = last twab amount (or zero) + (current amount * elapsed seconds)
        return
            ObservationLib.Observation({
                amount: _currentTwab.amount +
                    _currentBalance *
                    (_time.checkedSub(_currentTwab.timestamp, _time)),
                timestamp: _time
            });
    }

    /// @notice Sets a new TWAB Observation at the next available index and returns the new account details.
    /// @dev Note that if _currentTime is before the last observation timestamp, it appears as an overflow
    /// @param _twabs The twabs array to insert into
    /// @param _accountDetails The current account details
    /// @param _currentTime The current time
    /// @return accountDetails The new account details
    /// @return twab The newest twab (may or may not be brand-new)
    /// @return isNew Whether the newest twab was created by this call
    function _nextTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _currentTime
    )
        private
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        (, ObservationLib.Observation memory _newestTwab) = newestTwab(
            _twabs,
            _accountDetails
        );

        // if we're in the same block, return
        if (_newestTwab.timestamp == _currentTime) {
            return (_accountDetails, _newestTwab, false);
        }

        ObservationLib.Observation memory newTwab = _computeNextTwab(
            _newestTwab,
            _accountDetails.balance,
            _currentTime
        );

        _twabs[_accountDetails.nextTwabIndex] = newTwab;

        AccountDetails memory nextAccountDetails = push(_accountDetails);

        return (nextAccountDetails, newTwab, true);
    }

    /// @notice "Pushes" a new element on the AccountDetails ring buffer, and returns the new AccountDetails
    /// @param _accountDetails The account details from which to pull the cardinality and next index
    /// @return The new AccountDetails
    function push(
        AccountDetails memory _accountDetails
    ) internal pure returns (AccountDetails memory) {
        _accountDetails.nextTwabIndex = uint24(
            RingBufferLib.nextIndex(
                _accountDetails.nextTwabIndex,
                MAX_CARDINALITY
            )
        );

        // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
        // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
        // exceeds the max cardinality, new observations would be incorrectly set or the
        // observation would be out of "bounds" of the ring buffer. Once reached the
        // AccountDetails.cardinality will continue to be equal to max cardinality.
        if (_accountDetails.cardinality < MAX_CARDINALITY) {
            _accountDetails.cardinality += 1;
        }

        return _accountDetails;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Contract instantiated via CREATE2 to handle a Delegation by a delegator to a delegatee.
 * @notice A Delegation allows his owner to execute calls on behalf of the contract.
 * @dev This contract is intended to be counterfactually instantiated via CREATE2 through the LowLevelDelegator contract.
 * @dev This contract will hold tickets that will be delegated to a chosen delegatee.
 */
contract Delegation is Initializable {
    /**
     * @notice A structure to define arbitrary contract calls.
     * @param to The address to call
     * @param data The call data
     */
    struct Call {
        address to;
        bytes data;
    }

    /// @notice Contract owner.
    address private _owner;

    /// @notice Timestamp until which the delegation is locked.
    uint96 public lockUntil;

    /**
     * @notice Initializes the delegation.
     * @param _lockUntil Timestamp until which the delegation is locked
     */
    function initialize(uint96 _lockUntil) public initializer {
        require(_owner == address(0), "Delegation/already-init");
        _owner = msg.sender;
        lockUntil = _lockUntil;
    }

    /**
     * @notice Executes calls on behalf of this contract.
     * @param calls The array of calls to be executed
     * @return An array of the return values for each of the calls
     */
    function executeCalls(
        Call[] calldata calls
    ) external onlyOwner returns (bytes[] memory) {
        uint256 _callsLength = calls.length;
        bytes[] memory response = new bytes[](_callsLength);
        Call memory call;

        for (uint256 i; i < _callsLength; i++) {
            call = calls[i];
            response[i] = _executeCall(call.to, call.data);
        }

        return response;
    }

    /**
     * @notice Set the timestamp until which the delegation is locked.
     * @param _lockUntil The timestamp until which the delegation is locked
     */
    function setLockUntil(uint96 _lockUntil) external onlyOwner {
        lockUntil = _lockUntil;
    }

    /**
     * @notice Executes a call to another contract.
     * @param to The address to call
     * @param data The call data
     * @return The return data from the call
     */
    function _executeCall(
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool succeeded, bytes memory returnValue) = to.call{ value: 0 }(data);
        require(succeeded, string(returnValue));
        return returnValue;
    }

    /// @notice Modifier to only allow the contract owner to call a function
    modifier onlyOwner() {
        require(msg.sender == _owner, "Delegation/only-owner");
        _;
    }

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./Delegation.sol";

/// @title The LowLevelDelegator allows users to create delegations very cheaply.
contract LowLevelDelegator is Initializable {
    using ClonesUpgradeable for address;

    /// @notice The instance to which all proxies will point.
    Delegation public delegationInstance;

    function __LowLevelDelegator_init_unchained() internal onlyInitializing {
        delegationInstance = new Delegation();
        delegationInstance.initialize(uint96(0));
    }

    /**
     * @notice Creates a clone of the delegation.
     * @param _salt Random number used to deterministically deploy the clone
     * @param _lockUntil Timestamp until which the delegation is locked
     * @return The newly created delegation
     */
    function _createDelegation(
        bytes32 _salt,
        uint96 _lockUntil
    ) internal returns (Delegation) {
        Delegation _delegation = Delegation(
            address(delegationInstance).cloneDeterministic(_salt)
        );
        _delegation.initialize(_lockUntil);
        return _delegation;
    }

    /**
     * @notice Computes the address of a clone, also known as minimal proxy contract.
     * @param _salt Random number used to compute the address
     * @return Address at which the clone will be deployed
     */
    function _computeAddress(bytes32 _salt) internal view returns (address) {
        return
            address(delegationInstance).predictDeterministicAddress(
                _salt,
                address(this)
            );
    }

    /**
     * @notice Computes salt used to deterministically deploy a clone.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @return Salt used to deterministically deploy a clone.
     */
    function _computeSalt(
        address _delegator,
        bytes32 _slot
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_delegator, _slot));
    }

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice Allows a user to permit token spend and then call multiple functions
 *         on a contract.
 */
contract PermitAndMulticall is Initializable {
    /**
     * @notice Secp256k1 signature values.
     * @param deadline Timestamp at which the signature expires
     * @param v `v` portion of the signature
     * @param r `r` portion of the signature
     * @param s `s` portion of the signature
     */
    struct Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function __PermitAndMulticall_init_unchained() internal onlyInitializing {}

    /**
     * @notice Allows a user to call multiple functions on the same contract.
     *         Useful for EOA who want to batch transactions.
     * @dev Obtained from @openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol
     * @param _data An array of encoded function calls. The calls must be
     *              abi-encoded calls to this contract.
     * @return The results from each function call
     */
    function _multicall(
        bytes[] calldata _data
    ) internal virtual returns (bytes[] memory) {
        uint256 _dataLength = _data.length;
        bytes[] memory results = new bytes[](_dataLength);

        for (uint256 i; i < _dataLength; i++) {
            results[i] = _functionDelegateCall(address(this), _data[i]);
        }

        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     * @dev Obtained from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol"
     * _Available since v3.4._
     */
    function _functionDelegateCall(
        address target,
        bytes memory data
    ) private returns (bytes memory) {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @notice Allow a user to approve an ERC20 token and run various calls in one transaction.
     * @param _permitToken Address of the ERC20 token
     * @param _amount Amount of tickets to approve
     * @param _permitSignature Permit signature
     * @param _data Datas to call with `functionDelegateCall`
     */
    function _permitAndMulticall(
        IERC20PermitUpgradeable _permitToken,
        uint256 _amount,
        Signature calldata _permitSignature,
        bytes[] calldata _data
    ) internal {
        _permitToken.permit(
            msg.sender,
            address(this),
            _amount,
            _permitSignature.deadline,
            _permitSignature.v,
            _permitSignature.r,
            _permitSignature.s
        );

        _multicall(_data);
    }

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "../core/interfaces/ITicket.sol";

import "./PermitAndMulticall.sol";
import "./LowLevelDelegator.sol";

/**
 * @title Delegate chances to win to multiple accounts.
 * @notice This contract allows accounts to easily delegate a portion of their
 *         tickets to multiple delegatees. The delegatees chance of winning
 *         prizes is increased by the delegated amount.
 */
contract TWABDelegator is
    LowLevelDelegator,
    PermitAndMulticall,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using ClonesUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ============ Events ============ */

    /**
     * @notice Emitted when ticket associated with this contract has been set.
     * @param ticket Address of the ticket
     */
    event TicketSet(ITicket indexed ticket);

    /**
     * @notice Emitted when min lock duration has been set.
     * @param minLockDuration Min lock duration in seconds
     */
    event MinLockDurationSet(uint96 minLockDuration);

    /**
     * @notice Emitted when max lock duration has been set.
     * @param maxLockDuration Max lock duration in seconds
     */
    event MaxLockDurationSet(uint96 maxLockDuration);

    /**
     * @notice Emitted when a new delegation is created.
     * @param delegator Delegator of the delegation
     * @param slot Slot of the delegation
     * @param lockUntil Timestamp until which the delegation is locked
     * @param delegatee Address of the delegatee
     * @param delegation Address of the delegation that was created
     * @param user Address of the user who created the delegation
     */
    event DelegationCreated(
        address indexed delegator,
        uint256 indexed slot,
        uint96 lockUntil,
        address indexed delegatee,
        Delegation delegation,
        address user
    );

    /**
     * @notice Emitted when a delegatee is updated.
     * @param delegator Address of the delegator
     * @param slot Slot of the delegation
     * @param delegatee Address of the delegatee
     * @param lockUntil Timestamp until which the delegation is locked
     * @param user Address of the user who updated the delegatee
     */
    event DelegateeUpdated(
        address indexed delegator,
        uint256 indexed slot,
        address indexed delegatee,
        uint96 lockUntil,
        address user
    );

    /**
     * @notice Emitted when a delegation is funded.
     * @param delegator Address of the delegator
     * @param slot Slot of the delegation
     * @param amount Amount of tickets that were sent to the delegation
     * @param user Address of the user who funded the delegation
     */
    event DelegationFunded(
        address indexed delegator,
        uint256 indexed slot,
        uint256 amount,
        address indexed user
    );

    /**
     * @notice Emitted when an amount of tickets has been withdrawn from a
     *         delegation.
     * @param delegator Address of the delegator
     * @param slot Slot of the delegation
     * @param amount Amount of tickets withdrawn
     * @param user Address of the user who withdrew the tickets
     */
    event WithdrewDelegation(
        address indexed delegator,
        uint256 indexed slot,
        uint256 amount,
        address indexed user
    );

    /**
     * @notice Emitted when a delegator withdraws an amount of tickets from a
     *         delegation to a specified wallet.
     * @param delegator Address of the delegator
     * @param slot  Slot of the delegation
     * @param amount Amount of tickets withdrawn
     * @param to Recipient address of withdrawn tickets
     */
    event TransferredDelegation(
        address indexed delegator,
        uint256 indexed slot,
        uint256 amount,
        address indexed to
    );

    /* ============ Variables ============ */

    /// @notice Prize pool ticket to which this contract is tied to.
    ITicket public ticket;

    /// @notice Min lock time during which a delegation cannot be updated.
    uint96 public minLockDuration;

    /// @notice Max lock time during which a delegation cannot be updated.
    uint96 public maxLockDuration;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Creates a new TWAB Delegator that is bound to the given ticket
     *         contract.
     * @param _ticket Address of the ticket contract
     * @param _minLockDuration minimum lock duration
     * @param _maxLockDuration maximum lock duration
     */
    function initialize(
        ITicket _ticket,
        uint96 _minLockDuration,
        uint96 _maxLockDuration
    ) public virtual initializer {
        __TWABDelegator_init_unchained(
            _ticket,
            _minLockDuration,
            _maxLockDuration
        );
    }

    function __TWABDelegator_init_unchained(
        ITicket _ticket,
        uint96 _minLockDuration,
        uint96 _maxLockDuration
    ) internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __LowLevelDelegator_init_unchained();
        __PermitAndMulticall_init_unchained();
        _setTicket(_ticket);
        _setMinLockDuration(_minLockDuration);
        _setMaxLockDuration(_maxLockDuration);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Creates a new delegation. This will create a new Delegation
     *         contract for the given slot and have it delegate its tickets to
     *         the given delegatee. If a non-zero lock duration is passed, then
     *         the delegatee cannot be changed, nor funding withdrawn, until the
     *         lock has expired.
     * @dev    The `_delegator` and `_slot` params are used to compute the salt
     *         of the delegation
     * @param _delegator Address of the delegator that will be able to handle
     *                   the delegation
     * @param _slot Slot of the delegation
     * @param _delegatee Address of the delegatee
     * @param _lockDuration Duration of time for which the delegation is locked.
     *                      Must be less than the max duration.
     * @return Returns the address of the Delegation contract that will hold the
     *         tickets
     */
    function createDelegation(
        address _delegator,
        uint256 _slot,
        address _delegatee,
        uint96 _lockDuration
    ) external returns (Delegation) {
        _requireDelegateeNotZeroAddress(_delegatee);
        _requireDelegator(_delegator);
        _requireLockDuration(_lockDuration);

        uint96 _lockUntil = _computeLockUntil(_lockDuration);

        Delegation _delegation = _createDelegation(
            _computeSalt(_delegator, bytes32(_slot)),
            _lockUntil
        );

        _setDelegateeCall(_delegation, _delegatee);

        emit DelegationCreated(
            _delegator,
            _slot,
            _lockUntil,
            _delegatee,
            _delegation,
            msg.sender
        );

        return _delegation;
    }

    /**
     * @notice Updates the delegatee and lock duration for a delegation slot.
     * @dev Only callable by the `_delegator`.
     * @dev Will revert if delegation is still locked.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @param _delegatee Address of the delegatee
     * @param _lockDuration Duration of time during which the delegatee cannot
     *                      be changed nor withdrawn
     * @return The address of the Delegation
     */
    function updateDelegatee(
        address _delegator,
        uint256 _slot,
        address _delegatee,
        uint96 _lockDuration
    ) external returns (Delegation) {
        _requireDelegateeNotZeroAddress(_delegatee);
        _requireDelegator(_delegator);
        _requireLockDuration(_lockDuration);

        Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
        _requireDelegationUnlocked(_delegation);

        uint96 _lockUntil = _computeLockUntil(_lockDuration);

        if (_lockDuration > 0) {
            _delegation.setLockUntil(_lockUntil);
        }

        _setDelegateeCall(_delegation, _delegatee);

        emit DelegateeUpdated(
            _delegator,
            _slot,
            _delegatee,
            _lockUntil,
            msg.sender
        );

        return _delegation;
    }

    /**
     * @notice Fund a delegation by transferring tickets from the caller to the
     *         delegation.
     * @dev Callable by anyone.
     * @dev Will revert if delegation does not exist.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @param _amount Amount of tickets to transfer
     * @return The address of the Delegation
     */
    function fundDelegation(
        address _delegator,
        uint256 _slot,
        uint256 _amount
    ) external returns (Delegation) {
        require(_delegator != address(0), "TWABDelegator/dlgtr-not-zero-adr");
        _requireAmountGtZero(_amount);

        Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
        IERC20Upgradeable(ticket).safeTransferFrom(
            msg.sender,
            address(_delegation),
            _amount
        );

        emit DelegationFunded(_delegator, _slot, _amount, msg.sender);

        return _delegation;
    }

    /**
     * @notice Withdraw tickets from a delegation.
     * @dev Only callable by the `_delegator`.
     * @dev Will send the tickets to this contract and increase the `_delegator`
     *      staked amount.
     * @dev Will revert if delegation is still locked.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @param _amount Amount of tickets to withdraw
     * @return The address of the Delegation
     */
    function withdrawDelegation(
        address _delegator,
        uint256 _slot,
        uint256 _amount
    ) external returns (Delegation) {
        _requireDelegator(_delegator);

        Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

        _transfer(_delegation, _delegator, _amount);

        emit WithdrewDelegation(_delegator, _slot, _amount, msg.sender);

        return _delegation;
    }

    /**
     * @notice Withdraw an `_amount` of tickets from a delegation. The delegator
     *         is assumed to be the caller.
     * @dev Tickets are sent directly to the passed `_to` address.
     * @dev Will revert if delegation is still locked.
     * @param _slot Slot of the delegation
     * @param _amount Amount to withdraw
     * @param _to Account to transfer the withdrawn tickets to
     * @return The address of the Delegation
     */
    function transferDelegationTo(
        uint256 _slot,
        uint256 _amount,
        address _to
    ) external returns (Delegation) {
        _requireRecipientNotZeroAddress(_to);

        Delegation _delegation = Delegation(_computeAddress(msg.sender, _slot));
        _transfer(_delegation, _to, _amount);

        emit TransferredDelegation(msg.sender, _slot, _amount, _to);

        return _delegation;
    }

    /**
     * @notice Allows a user to call multiple functions on the same contract.
     *         Useful for EOA who wants to batch transactions.
     * @param _data An array of encoded function calls.  The calls must be
     *              abi-encoded calls to this contract.
     * @return The results from each function call
     */
    function multicall(
        bytes[] calldata _data
    ) external returns (bytes[] memory) {
        return _multicall(_data);
    }

    /**
     * @notice Allow a user to approve ticket and run various calls in one
     *         transaction.
     * @param _amount Amount of tickets to approve
     * @param _permitSignature Permit signature
     * @param _data Datas to call with `functionDelegateCall`
     */
    function permitAndMulticall(
        uint256 _amount,
        Signature calldata _permitSignature,
        bytes[] calldata _data
    ) external {
        _permitAndMulticall(
            IERC20PermitUpgradeable(address(ticket)),
            _amount,
            _permitSignature,
            _data
        );
    }

    /**
     * @notice Allows the caller to easily get the details for a delegation.
     * @param _delegator The delegator address
     * @param _slot The delegation slot they are using
     * @return delegation The address that holds tickets for the delegation
     * @return delegatee The address that tickets are being delegated to
     * @return balance The balance of tickets in the delegation
     * @return lockUntil The timestamp at which the delegation unlocks
     * @return wasCreated Whether or not the delegation has been created
     */
    function getDelegation(
        address _delegator,
        uint256 _slot
    )
        external
        view
        returns (
            Delegation delegation,
            address delegatee,
            uint256 balance,
            uint256 lockUntil,
            bool wasCreated
        )
    {
        delegation = Delegation(_computeAddress(_delegator, _slot));
        wasCreated = address(delegation).isContract();
        delegatee = ticket.delegateOf(address(delegation));
        balance = ticket.balanceOf(address(delegation));

        if (wasCreated) {
            lockUntil = delegation.lockUntil();
        }
    }

    /**
     * @notice Computes the address of the delegation for the delegator + slot
     *         combination.
     * @param _delegator The user who is delegating tickets
     * @param _slot The delegation slot
     * @return The address of the delegation.  This is the address that holds
     *         the balance of tickets.
     */
    function computeDelegationAddress(
        address _delegator,
        uint256 _slot
    ) external view returns (address) {
        return _computeAddress(_delegator, _slot);
    }

    /**
     * @notice Sets a new min lock duration. Only callable by the owner.
     * @param _minLockDuration New min lock duration in seconds
     */
    function setMinLockDuration(uint96 _minLockDuration) external onlyOwner {
        _setMinLockDuration(_minLockDuration);
    }

    /**
     * @notice Sets a new max lock duration. Only callable by the owner.
     * @param _maxLockDuration New max lock duration in seconds
     */
    function setMaxLockDuration(uint96 _maxLockDuration) external onlyOwner {
        _setMaxLockDuration(_maxLockDuration);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Computes the address of a delegation contract using the delegator
     *         and slot as a salt. The contract is a clone, also known as
     *         minimal proxy contract.
     * @param _delegator Address of the delegator
     * @param _slot Slot of the delegation
     * @return Address at which the delegation contract will be deployed
     */
    function _computeAddress(
        address _delegator,
        uint256 _slot
    ) internal view returns (address) {
        return _computeAddress(_computeSalt(_delegator, bytes32(_slot)));
    }

    /**
     * @notice Computes the timestamp at which the delegation unlocks, after
     *         which the delegatee can be changed and tickets withdrawn.
     * @param _lockDuration The duration of the lock
     * @return The lock expiration timestamp
     */
    function _computeLockUntil(
        uint96 _lockDuration
    ) internal view returns (uint96) {
        unchecked {
            return uint96(block.timestamp) + _lockDuration;
        }
    }

    /**
     * @notice Delegates tickets from the `_delegation` contract to the
     *         `_delegatee` address.
     * @param _delegation Address of the delegation contract
     * @param _delegatee Address of the delegatee
     */
    function _setDelegateeCall(
        Delegation _delegation,
        address _delegatee
    ) internal {
        bytes4 _selector = ticket.delegate.selector;
        bytes memory _data = abi.encodeWithSelector(_selector, _delegatee);

        _executeCall(_delegation, _data);
    }

    /**
     * @notice Tranfers tickets from the Delegation contract to the `_to`
     *         address.
     * @param _delegation Address of the delegation contract
     * @param _to Address of the recipient
     * @param _amount Amount of tickets to transfer
     */
    function _transferCall(
        Delegation _delegation,
        address _to,
        uint256 _amount
    ) internal {
        bytes4 _selector = ticket.transfer.selector;
        bytes memory _data = abi.encodeWithSelector(_selector, _to, _amount);

        _executeCall(_delegation, _data);
    }

    /**
     * @notice Execute a function call on the delegation contract.
     * @param _delegation Address of the delegation contract
     * @param _data The call data that will be executed
     * @return The return datas from the calls
     */
    function _executeCall(
        Delegation _delegation,
        bytes memory _data
    ) internal returns (bytes[] memory) {
        Delegation.Call[] memory _calls = new Delegation.Call[](1);
        _calls[0] = Delegation.Call({ to: address(ticket), data: _data });

        return _delegation.executeCalls(_calls);
    }

    /**
     * @notice Transfers tickets from a delegation contract to `_to`.
     * @param _delegation Address of the delegation contract
     * @param _to Address of the recipient
     * @param _amount Amount of tickets to transfer
     */
    function _transfer(
        Delegation _delegation,
        address _to,
        uint256 _amount
    ) internal {
        _requireAmountGtZero(_amount);
        _requireDelegationUnlocked(_delegation);

        _transferCall(_delegation, _to, _amount);
    }

    /**
     * @notice Sets a new min lock duration.
     * @param _minLockDuration New min lock duration in seconds
     */
    function _setMinLockDuration(uint96 _minLockDuration) internal {
        minLockDuration = _minLockDuration;

        emit MinLockDurationSet(_minLockDuration);
    }

    /**
     * @notice Sets a new max lock duration.
     * @param _maxLockDuration New max lock duration in seconds
     */
    function _setMaxLockDuration(uint96 _maxLockDuration) internal {
        maxLockDuration = _maxLockDuration;

        emit MaxLockDurationSet(_maxLockDuration);
    }

    /**
     * @notice Sets a prize pool ticket to which this contract is tied to.
     * @param _ticket A ticket contract address
     */
    function _setTicket(ITicket _ticket) internal {
        require(
            address(_ticket) != address(0),
            "TWABDelegator/tick-not-zero-addr"
        );

        ticket = _ticket;

        emit TicketSet(_ticket);
    }

    /* ============ Modifier/Require Functions ============ */

    /**
     * @notice Require to only allow the delegator to call a function.
     * @param _delegator Address of the delegator
     */
    function _requireDelegator(address _delegator) internal view {
        require(_delegator == msg.sender, "TWABDelegator/not-dlgtr");
    }

    /**
     * @notice Require to verify that `_delegatee` is not address zero.
     * @param _delegatee Address of the delegatee
     */
    function _requireDelegateeNotZeroAddress(address _delegatee) internal pure {
        require(_delegatee != address(0), "TWABDelegator/dlgt-not-zero-addr");
    }

    /**
     * @notice Require to verify that `_amount` is greater than 0.
     * @param _amount Amount to check
     */
    function _requireAmountGtZero(uint256 _amount) internal pure {
        require(_amount > 0, "TWABDelegator/amount-gt-zero");
    }

    /**
     * @notice Require to verify that `_to` is not address zero.
     * @param _to Address to check
     */
    function _requireRecipientNotZeroAddress(address _to) internal pure {
        require(_to != address(0), "TWABDelegator/to-not-zero-addr");
    }

    /**
     * @notice Require to verify if a `_delegation` is locked.
     * @param _delegation Delegation to check
     */
    function _requireDelegationUnlocked(Delegation _delegation) internal view {
        require(
            block.timestamp >= _delegation.lockUntil(),
            "TWABDelegator/delegation-locked"
        );
    }

    /**
     * @notice Require to verify that a `_lockDuration` is zero or is between
     *         min and max lock duration.
     * @param _lockDuration Lock duration to check
     */
    function _requireLockDuration(uint96 _lockDuration) internal view {
        if (_lockDuration != 0) {
            require(
                _lockDuration >= minLockDuration,
                "TWABDelegator/lock-too-short"
            );
            require(
                _lockDuration <= maxLockDuration,
                "TWABDelegator/lock-too-long"
            );
        }
    }
}