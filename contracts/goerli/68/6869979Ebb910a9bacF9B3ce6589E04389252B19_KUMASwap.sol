// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IBlacklist {
    event AccessControllerSet(address accesController);
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    function blacklist(address account) external;

    function unBlacklist(address account) external;

    function accessController() external view returns (IAccessControl);

    function isBlacklisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IBlacklist} from "./IBlacklist.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IKUMABondToken is IERC721 {
    event AccessControllerSet(address accesController);
    event BlacklistSet(address blacklist);
    event BondIssued(uint256 id, Bond bond);
    event BondRedeemed(uint256 id);
    event MaxCouponSet(uint256 oldMaxCoupon, uint256 newMaxCoupon);
    event TokenTncUpdated(uint256 indexed tokenId, uint256 oldTermId, uint256 newTermId);
    event TncAdded(uint256 indexed termId, string url);
    event TncUrlUpdated(uint256 indexed termId, string oldUrl, string newUrl);
    event UriSet(string oldUri, string newUri);

    /**
     * @param cusip Bond CUISP number.
     * @param isin Bond ISIN number.
     * @param currency Currency of the bond - example : USD
     * @param country Treasury issuer - example : US
     * @param term Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years
     * @param issuance Bond issuance date - timestamp in seconds
     * @param maturity Date on which the principal amount becomes due - timestamp is seconds
     * @param coupon Annual interest rate paid on the bond per - rate per second
     * @param principal Bond face value ie redeemable amount
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     */
    struct Bond {
        bytes16 cusip;
        bytes16 isin;
        bytes4 currency;
        bytes4 country;
        uint64 term;
        uint64 issuance;
        uint64 maturity;
        uint256 coupon;
        uint256 principal;
        uint256 tncId;
        bytes32 riskCategory;
    }

    function issueBond(address to, Bond calldata bond) external;

    function redeem(uint256 tokenId) external;

    function setUri(string memory newUri) external;

    function setMaxCoupon(uint256 newMaxCoupon) external;

    function addTnc(string memory url) external;

    function updateTncUrl(uint256 tncId, string memory newUrl) external;

    function updateTncForToken(uint256 tokenId, uint256 tncId) external;

    function pause() external;

    function unpause() external;

    function accessController() external view returns (IAccessControl);

    function blacklist() external view returns (IBlacklist);

    function getMaxCoupon() external view returns (uint256);

    function getTncCounter() external view returns (uint256);

    function getTokenIdCounter() external view returns (uint256);

    function getBaseURI() external view returns (string memory);

    function getBond(uint256) external view returns (Bond memory);

    function getTncUrl(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface MCAGAggregatorInterface {
    event AccessControllerSet(address accesController);
    event AnswerTransmitted(address indexed transmitter, uint80 roundId, int256 answer);
    event MaxAnswerSet(int256 oldMaxAnswer, int256 newMaxAnswer);

    function transmit(int256 answer) external;

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function maxAnswer() external view returns (int256);

    function version() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/cryptography/EIP712Upgradeable.sol";
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
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

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
 *
 * @custom:storage-size 52
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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC721MetadataUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";

interface IKBCToken is IERC721MetadataUpgradeable {
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event CloneBondIssued(uint256 ghostId, CloneBond cloneBond);
    event CloneBondRedeemed(uint256 ghostId, uint256 parentId);
    event UriSet(string oldUri, string newUri);

    /**
     * @param parentId Token id of the part KUMABondToken.
     * @param issuance Timestamp of the CloneBond issuance. Overwrites the parent's issuance.
     * @param coupon Clone bond coupon overriding the parent's.
     * Is set to lowest yield of central bank rate and minCoupon at the time of issuance.
     * @param principal Clone bond principal override the parent's. Is set to the bond realized value at issuance.
     */
    struct CloneBond {
        uint256 parentId;
        uint256 issuance;
        uint256 coupon;
        uint256 principal;
    }

    function initialize(IKUMAAddressProvider KUMAAddressProvider) external;

    function issueBond(address to, CloneBond memory cBond) external returns (uint256 tokenId);

    function redeem(uint256 tokenId) external;

    function setUri(string memory newUri) external;

    function getKUMAAddressProvider() external returns (IKUMAAddressProvider);

    function getBaseURI() external view returns (string memory);

    function getBond(uint256) external view returns (CloneBond memory);

    function getTokenIdCounter() external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IERC20PermitUpgradeable} from
    "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20PermitUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20MetadataUpgradeable.sol";
import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";
import {IMCAGRateFeed} from "./IMCAGRateFeed.sol";

interface IKIBToken is IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    event CumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);
    event EpochLengthSet(uint256 previousEpochLength, uint256 newEpochLength);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event PreviousEpochCumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);
    event RiskCategorySet(bytes32 riskCategory);
    event YieldUpdated(uint256 oldYield, uint256 newYield);

    function initialize(
        string memory name,
        string memory symbol,
        uint256 epochLength,
        IKUMAAddressProvider KUMAAddressProvider,
        bytes4 currency,
        bytes4 country,
        uint64 term
    ) external;

    function setEpochLength(uint256 epochLength) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function refreshYield() external;

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider);

    function getRiskCategory() external view returns (bytes32);

    function getYield() external view returns (uint256);

    function getTotalBaseSupply() external view returns (uint256);

    function getBaseBalance(address account) external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getLastRefresh() external view returns (uint256);

    function getCumulativeYield() external view returns (uint256);

    function getUpdatedCumulativeYield() external view returns (uint256);

    function getPreviousEpochTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IKUMAAddressProvider {
    event AccessControllerSet(address accessController);
    event KBCTokenSet(address KBCToken);
    event KIBTokenSet(address KIBToken, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);
    event KUMABondTokenSet(address KUMABondToken);
    event KUMAFeeCollectorSet(
        address KUMAFeeCollector, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term
    );
    event KUMASwapSet(address KUMASwap, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);
    event RateFeedSet(address rateFeed);

    function initialize(IAccessControl accessController) external;

    function setKUMABondToken(address KUMABondToken) external;

    function setKBCToken(address KBCToken) external;

    function setRateFeed(address rateFeed) external;

    function setKIBToken(bytes4 currency, bytes4 country, uint64 term, address KIBToken) external;

    function setKUMASwap(bytes4 currency, bytes4 country, uint64 term, address KUMASwap) external;

    function setKUMAFeeCollector(bytes4 currency, bytes4 country, uint64 term, address feeCollector) external;

    function getAccessController() external view returns (IAccessControl);

    function getKUMABondToken() external view returns (address);

    function getRateFeed() external view returns (address);

    function getKBCToken() external view returns (address);

    function getKIBToken(bytes32 riskCategory) external view returns (address);

    function getKUMASwap(bytes32 riskCategory) external view returns (address);

    function getKUMAFeeCollector(bytes32 riskCategory) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";

interface IKUMAFeeCollector {
    event PayeeAdded(address indexed payee, uint256 share);
    event PayeeRemoved(address indexed payee);
    event FeeReleased(uint256 income);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event ShareUpdated(address indexed payee, uint256 newShare);
    event RiskCategorySet(bytes32 riskCategory);

    function initialize(IKUMAAddressProvider KUMAAddressProvider, bytes4 currency, bytes4 country, uint64 term)
        external;

    function release() external;

    function addPayee(address payee, uint256 share) external;

    function removePayee(address payee) external;

    function updatePayeeShare(address payee, uint256 share) external;

    function changePayees(address[] calldata newPayees, uint256[] calldata newShares) external;

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider);

    function getRiskCategory() external view returns (bytes32);

    function getPayees() external view returns (address[] memory);

    function getTotalShares() external view returns (uint256);

    function getShare(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMAAddressProvider} from "./IKUMAAddressProvider.sol";

interface IKUMASwap is IERC721Receiver {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 cloneTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event KIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);
    event KUMAAddressProviderSet(address KUMAAddressProvider);
    event MaxCouponsSet(uint256 maxCoupons);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event RiskCategorySet(bytes32 riskCategory);

    function initialize(
        IKUMAAddressProvider KUMAAddressProvider,
        IERC20 deprecationStableCoin,
        bytes4 currency,
        bytes4 country,
        uint64 term
    ) external;

    function sellBond(uint256 tokenId) external;

    function buyBond(uint256 tokenId) external;

    function buyBondForStableCoin(uint256 tokenId, address buyer, uint256 amount) external;

    function claimBond(uint256 tokenId) external;

    function redeemKIBT(uint256 amount) external;

    function pause() external;

    function unpause() external;

    function expireBond(uint256 tokenId) external;

    function setFees(uint16 variableFee, uint256 fixedFee) external;

    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin) external;

    function initializeDeprecationMode() external;

    function uninitializeDeprecationMode() external;

    function enableDeprecationMode() external;

    function getRiskCategory() external view returns (bytes32);

    function getMaxCoupons() external view returns (uint16);

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider);

    function isDeprecationInitialized() external view returns (bool);

    function getDeprecationInitializedAt() external view returns (uint56);

    function isDeprecated() external view returns (bool);

    function getVariableFee() external view returns (uint16);

    function getDeprecationStableCoin() external view returns (IERC20);

    function getFixedFee() external view returns (uint256);

    function getMinCoupon() external view returns (uint256);

    function getCoupons() external view returns (uint256[] memory);

    function getBondReserve() external view returns (uint256[] memory);

    function getExpiredBonds() external view returns (uint256[] memory);

    function getCloneBond(uint256 tokenId) external view returns (uint256);

    function getCouponInventory(uint256 coupon) external view returns (uint256);

    function isInReserve(uint256 tokenId) external view returns (bool);

    function isExpired() external view returns (bool);

    function getBondBaseValue(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "lib/mcag-contracts/src/interfaces/MCAGAggregatorInterface.sol";

interface IMCAGRateFeed {
    event AccessControllerSet(address accessController);
    event OracleSet(address oracle, bytes4 indexed currency, bytes4 indexed country, uint64 indexed term);
    event StalenessThresholdSet(uint256 stalenessThreshold);

    function initialize(IAccessControl accessController, uint256 stalenessThreshold) external;

    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle) external;

    function setStalenessThreshold(uint256 stalenessThreshold) external;

    function minRateCoupon() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getAccessController() external view returns (IAccessControl);

    function getRate(bytes32 riskCategory) external view returns (uint256);

    function getOracle(bytes32 riskCategory) external view returns (MCAGAggregatorInterface);

    function getStalenessThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {Counters} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {ERC721Upgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKUMABondToken} from "lib/mcag-contracts/src/interfaces/IKUMABondToken.sol";
import {IKBCToken} from "./interfaces/IKBCToken.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KBCToken is ERC721Upgradeable, IKBCToken, UUPSUpgradeable {
    using Counters for Counters.Counter;

    IKUMAAddressProvider private _KUMAAddressProvider;
    Counters.Counter private _tokenIdCounter;
    string private _uri;

    mapping(uint256 => CloneBond) private _bonds;

    modifier onlyKUMASwap(uint256 parentId) {
        bytes32 riskCategory = IKUMABondToken(_KUMAAddressProvider.getKUMABondToken()).getBond(parentId).riskCategory;
        if (msg.sender != _KUMAAddressProvider.getKUMASwap(riskCategory)) {
            revert Errors.CALLER_NOT_KUMASWAP();
        }
        _;
    }

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(_KUMAAddressProvider.getAccessController()).hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    constructor() initializer {}

    function initialize(IKUMAAddressProvider KUMAAddressProvider) external override initializer {
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _KUMAAddressProvider = KUMAAddressProvider;
        __ERC721_init("KUMA Bonds Clone Token", "KBCT");

        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
    }

    /**
     * @notice Mints a clone bond NFT to the specified address.
     * @dev Can only be called under specific conditions :
     *      - Caller must have MINT_ROLE
     *      - Receiver must not be blacklisted
     *      - Contract must not be paused
     * @param to Clone bond NFT receiver.
     * @param cBond Clone bond struct storing metadata.
     */
    function issueBond(address to, CloneBond calldata cBond)
        external
        override
        onlyKUMASwap(cBond.parentId)
        returns (uint256 tokenId)
    {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _bonds[tokenId] = cBond;
        _safeMint(to, tokenId);
        emit CloneBondIssued(tokenId, cBond);
    }

    /**
     * @notice Burns a clone bond NFT.
     * @dev Can only be called under specific conditions :
     *      - Caller must have BURN_ROLE
     *      - Contract must not be paused
     * @param tokenId Clone bond Id.
     */
    function redeem(uint256 tokenId) external override onlyKUMASwap(_bonds[tokenId].parentId) {
        uint256 parentId = _bonds[tokenId].parentId;
        delete _bonds[tokenId];
        _burn(tokenId);
        emit CloneBondRedeemed(tokenId, parentId);
    }

    /**
     * @notice Sets a new base uri.
     * @dev Can only be called by `MCAG_SET_URI_ROLE`.
     * @param newUri New base uri.
     */
    function setUri(string memory newUri) external override onlyRole(Roles.KUMA_SET_URI_ROLE) {
        emit UriSet(_uri, newUri);
        _uri = newUri;
    }

    function getKUMAAddressProvider() external view override returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    /**
     * @return Current base uri.
     */
    function getBaseURI() external view override returns (string memory) {
        return _uri;
    }

    /**
     * @param tokenId Clone bond id.
     * @return Bond struct storing metadata of the selected bond id.
     */
    function getBond(uint256 tokenId) external view override returns (CloneBond memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        return _bonds[tokenId];
    }

    /**
     * @return Current token id counter.
     */
    function getTokenIdCounter() external view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}

    /**
     * @dev See {IERC721-_baseUri}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {
    ERC20Upgradeable, IERC20Upgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20PermitUpgradeable,
    IERC20PermitUpgradeable
} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Errors} from "./libraries/Errors.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKIBToken} from "./interfaces/IKIBToken.sol";
import {IKUMASwap} from "./interfaces/IKUMASwap.sol";
import {IMCAGRateFeed} from "./interfaces/IMCAGRateFeed.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";

contract KIBToken is IKIBToken, ERC20PermitUpgradeable, UUPSUpgradeable {
    using Roles for bytes32;
    using WadRayMath for uint256;

    uint256 public constant MAX_EPOCH_LENGTH = 365 days;
    uint256 public constant MIN_YIELD = WadRayMath.RAY;

    IKUMAAddressProvider private _KUMAAddressProvider;
    bytes32 private _riskCategory;
    uint256 private _yield;
    uint256 private _previousEpochCumulativeYield;
    uint256 private _cumulativeYield;
    uint256 private _lastRefresh;
    uint256 private _epochLength;

    uint256 private _totalBaseSupply; // Underlying assets supply (does not include rewards)

    mapping(address => uint256) private _baseBalances; // (does not include rewards)

    modifier onlyRole(bytes32 role) {
        if (!_KUMAAddressProvider.getAccessController().hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    constructor() initializer {}

    /**
     * @notice The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     * @param name Token name.
     * @param symbol Tokne symbol.
     * @param epochLength Rebase intervals in seconds.
     * @param KUMAAddressProvider KUMAAddressProvider.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 epochLength,
        IKUMAAddressProvider KUMAAddressProvider,
        bytes4 currency,
        bytes4 country,
        uint64 term
    ) external override initializer {
        if (epochLength == 0) {
            revert Errors.EPOCH_LENGTH_CANNOT_BE_ZERO();
        }
        if (epochLength > MAX_EPOCH_LENGTH) {
            revert Errors.NEW_EPOCH_LENGTH_TOO_HIGH();
        }
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        _yield = MIN_YIELD;
        _epochLength = epochLength;
        _lastRefresh = block.timestamp % epochLength == 0
            ? block.timestamp
            : (block.timestamp / epochLength) * epochLength + epochLength;
        _cumulativeYield = MIN_YIELD;
        _previousEpochCumulativeYield = MIN_YIELD;
        _KUMAAddressProvider = KUMAAddressProvider;
        _riskCategory = keccak256(abi.encode(currency, country, term));
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);

        emit CumulativeYieldUpdated(0, MIN_YIELD);
        emit EpochLengthSet(0, epochLength);
        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
        emit PreviousEpochCumulativeYieldUpdated(0, MIN_YIELD);
        emit RiskCategorySet(_riskCategory);
        emit YieldUpdated(0, MIN_YIELD);
    }

    /**
     * @param epochLength New rebase interval.
     */
    function setEpochLength(uint256 epochLength) external override onlyRole(Roles.KUMA_SET_EPOCH_LENGTH_ROLE) {
        if (epochLength == 0) {
            revert Errors.EPOCH_LENGTH_CANNOT_BE_ZERO();
        }
        if (epochLength > MAX_EPOCH_LENGTH) {
            revert Errors.NEW_EPOCH_LENGTH_TOO_HIGH();
        }
        if (_getPreviousEpochTimestamp() >= (block.timestamp / epochLength * epochLength)) {
            _refreshCumulativeYield();
            _refreshYield();
        }
        emit EpochLengthSet(_epochLength, epochLength);
        _epochLength = epochLength;
    }

    /**
     * @notice Updates yield based on current yield and oracle reference rate.
     */
    function refreshYield() external override {
        _refreshCumulativeYield();
        _refreshYield();
    }

    /**
     * @dev See {ERC20-_mint}.
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     */
    function mint(address account, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_MINT_ROLE.toGranularRole(_riskCategory))
    {
        if (block.timestamp < _lastRefresh) {
            revert Errors.START_TIME_NOT_REACHED();
        }
        if (account == address(0)) {
            revert Errors.ERC20_MINT_TO_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 newAccountBalance = balanceOf(account) + amount;
        uint256 newBaseBalance = WadRayMath.wadToRay(newAccountBalance).rayDiv(_previousEpochCumulativeYield); // Store baseAmount in 27 decimals

        if (amount > 0) {
            _totalBaseSupply += newBaseBalance - _baseBalances[account];
            _baseBalances[account] = newBaseBalance;
        }

        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev See {ERC20-_burn}.
     * @notice Following logic has been added/updated :
     * - Cumulative yield refresh
     * - Destroy baseAmount instead of amount
     */
    function burn(address account, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_BURN_ROLE.toGranularRole(_riskCategory))
    {
        if (account == address(0)) {
            revert Errors.ERC20_BURN_FROM_THE_ZERO_ADDRESS();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 startingAccountBalance = balanceOf(account);
        if (startingAccountBalance < amount) {
            revert Errors.ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
        }

        uint256 newAccountBalance = startingAccountBalance - amount;
        uint256 newBaseBalance = WadRayMath.wadToRay(newAccountBalance).rayDiv(_previousEpochCumulativeYield);
        if (amount > 0) {
            _totalBaseSupply -= _baseBalances[account] - newBaseBalance;
            _baseBalances[account] = newBaseBalance;
        }

        emit Transfer(account, address(0), amount);
    }

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    /**
     * @return Current yield
     */
    function getYield() external view override returns (uint256) {
        return _yield;
    }

    /**
     * @return Timestamp of last rebase.
     */
    function getLastRefresh() external view override returns (uint256) {
        return _lastRefresh;
    }

    /**
     * @return Current baseTotalSupply.
     */
    function getTotalBaseSupply() external view override returns (uint256) {
        return _totalBaseSupply;
    }

    /**
     * @return User base balance
     */
    function getBaseBalance(address account) external view override returns (uint256) {
        return _baseBalances[account];
    }

    /**
     * @return Current epoch length.
     */
    function getEpochLength() external view override returns (uint256) {
        return _epochLength;
    }

    /**
     * @return Last updated cumulative yield
     */
    function getCumulativeYield() external view override returns (uint256) {
        return _cumulativeYield;
    }

    /**
     * @return Cumulative yield calculated at last epoch
     */
    function getUpdatedCumulativeYield() external view override returns (uint256) {
        return _calculatePreviousEpochCumulativeYield();
    }

    /**
     * @return Timestamp rounded down to the previous epoch length.
     */
    function getPreviousEpochTimestamp() external view returns (uint256) {
        return _getPreviousEpochTimestamp();
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return WadRayMath.rayToWad(_baseBalances[account].rayMul(_calculatePreviousEpochCumulativeYield()));
    }

    /**
     * @dev See {ERC20-symbol}.
     */
    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint256) {
        return WadRayMath.rayToWad(_totalBaseSupply.rayMul(_calculatePreviousEpochCumulativeYield()));
    }

    /**
     * @dev See {ERC20-_transfer}.
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        if (from == address(0)) {
            revert Errors.ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
        }
        if (to == address(0)) {
            revert Errors.ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
        }
        if (to == from) {
            revert Errors.CANNOT_TRANSFER_TO_SELF();
        }
        _refreshCumulativeYield();
        _refreshYield();

        uint256 startingFromBalance = balanceOf(from);
        if (startingFromBalance < amount) {
            revert Errors.ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
        }
        uint256 newFromBalance = startingFromBalance - amount;
        uint256 newToBalance = balanceOf(to) + amount;

        uint256 previousEpochCumulativeYield_ = _previousEpochCumulativeYield;
        uint256 newFromBaseBalance = WadRayMath.wadToRay(newFromBalance).rayDiv(previousEpochCumulativeYield_);
        uint256 newToBaseBalance = WadRayMath.wadToRay(newToBalance).rayDiv(previousEpochCumulativeYield_);

        if (amount > 0) {
            _totalBaseSupply -= (_baseBalances[from] - newFromBaseBalance);
            _totalBaseSupply += (newToBaseBalance - _baseBalances[to]);
            _baseBalances[from] = newFromBaseBalance;
            _baseBalances[to] = newToBaseBalance;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Updates the internal state variables after accounting for newly received tokens.
     */
    function _refreshCumulativeYield() private {
        uint256 newPreviousEpochCumulativeYield = _calculatePreviousEpochCumulativeYield();
        uint256 newCumulativeYield = _calculateCumulativeYield();

        if (newPreviousEpochCumulativeYield != _previousEpochCumulativeYield) {
            emit PreviousEpochCumulativeYieldUpdated(_previousEpochCumulativeYield, newPreviousEpochCumulativeYield);
            _previousEpochCumulativeYield = newPreviousEpochCumulativeYield;
        }
        if (newCumulativeYield != _cumulativeYield) {
            emit CumulativeYieldUpdated(_cumulativeYield, newCumulativeYield);
            _cumulativeYield = newCumulativeYield;
        }

        _lastRefresh = block.timestamp;
    }

    /**
     * @notice Updates yield based on current yield and oracle reference rate.
     */
    function _refreshYield() private {
        IKUMASwap KUMASwap = IKUMASwap(_KUMAAddressProvider.getKUMASwap(_riskCategory));
        uint256 yield_ = _yield;
        if (KUMASwap.isExpired() || KUMASwap.isDeprecated()) {
            _yield = MIN_YIELD;
            emit YieldUpdated(yield_, MIN_YIELD);
            return;
        }
        uint256 referenceRate = IMCAGRateFeed(_KUMAAddressProvider.getRateFeed()).getRate(_riskCategory);
        uint256 minCoupon = KUMASwap.getMinCoupon();
        uint256 lowestYield = referenceRate < minCoupon ? referenceRate : minCoupon;
        if (lowestYield != yield_) {
            _yield = lowestYield;
            emit YieldUpdated(yield_, lowestYield);
        }
    }

    /**
     * @return Timestamp rounded down to the previous epoch length.
     */
    function _getPreviousEpochTimestamp() private view returns (uint256) {
        uint256 epochLength = _epochLength;
        uint256 epochTimestampRemainder = block.timestamp % epochLength;
        if (epochTimestampRemainder == 0) {
            return block.timestamp;
        }
        return (block.timestamp / epochLength) * epochLength;
    }

    /**
     * @notice Helper function to calculate cumulativeYield at call timestamp.
     * @return Updated cumulative yield
     */
    function _calculateCumulativeYield() private view returns (uint256) {
        uint256 timeElapsed = block.timestamp - _lastRefresh;
        if (timeElapsed == 0) return _cumulativeYield;
        return _yield.rayPow(timeElapsed).rayMul(_cumulativeYield);
    }

    /**
     * @notice Helper function to calculate previousEpochCumulativeYield at call timestamp.
     * @return Updated previous epoch cumulative yield.
     */
    function _calculatePreviousEpochCumulativeYield() private view returns (uint256) {
        uint256 previousEpochTimestamp = _getPreviousEpochTimestamp();
        if (previousEpochTimestamp < _lastRefresh) {
            return _previousEpochCumulativeYield;
        }
        uint256 timeElapsedToEpoch = previousEpochTimestamp - _lastRefresh;
        return _yield.rayPow(timeElapsedToEpoch).rayMul(_cumulativeYield);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Roles} from "./libraries/Roles.sol";

contract KUMAAccessController is AccessControl {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Roles.KUMA_MANAGER_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKIBToken} from "./interfaces/IKIBToken.sol";
import {IKUMAFeeCollector} from "./interfaces/IKUMAFeeCollector.sol";
import {IKUMASwap} from "./interfaces/IKUMASwap.sol";
import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMAAddressProvider is IKUMAAddressProvider, UUPSUpgradeable, Initializable {
    IAccessControl private _accessController;

    address private _KBCToken;
    address private _rateFeed;
    address private _KUMABondToken;

    mapping(bytes32 => address) private _KIBToken;
    mapping(bytes32 => address) private _KUMASwap;
    mapping(bytes32 => address) private _KUMAFeeCollector;

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _;
    }

    modifier onlyManager() {
        if (!_accessController.hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
        _;
    }

    constructor() initializer {}

    function initialize(IAccessControl accessController) external override initializer {
        if (address(accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _accessController = accessController;

        emit AccessControllerSet(address(accessController));
    }

    function setKBCToken(address KBCToken) external override onlyManager onlyValidAddress(KBCToken) {
        _KBCToken = KBCToken;
        emit KBCTokenSet(KBCToken);
    }

    function setRateFeed(address rateFeed) external override onlyManager onlyValidAddress(rateFeed) {
        _rateFeed = rateFeed;
        emit RateFeedSet(rateFeed);
    }

    function setKUMABondToken(address KUMABondToken) external override onlyManager onlyValidAddress(KUMABondToken) {
        _KUMABondToken = KUMABondToken;
        emit KUMABondTokenSet(KUMABondToken);
    }

    function setKIBToken(bytes4 currency, bytes4 country, uint64 term, address KIBToken)
        external
        override
        onlyManager
        onlyValidAddress(KIBToken)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKIBToken(KIBToken).getRiskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KIBToken[riskCategory] = KIBToken;
        emit KIBTokenSet(KIBToken, currency, country, term);
    }

    function setKUMASwap(bytes4 currency, bytes4 country, uint64 term, address KUMASwap)
        external
        override
        onlyManager
        onlyValidAddress(KUMASwap)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKUMASwap(KUMASwap).getRiskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KUMASwap[riskCategory] = KUMASwap;
        emit KUMASwapSet(KUMASwap, currency, country, term);
    }

    function setKUMAFeeCollector(bytes4 currency, bytes4 country, uint64 term, address KUMAFeeCollector)
        external
        override
        onlyManager
        onlyValidAddress(KUMAFeeCollector)
    {
        bytes32 riskCategory = _checkRiskCategory(currency, country, term);
        if (IKUMAFeeCollector(KUMAFeeCollector).getRiskCategory() != riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH();
        }
        _KUMAFeeCollector[riskCategory] = KUMAFeeCollector;
        emit KUMAFeeCollectorSet(KUMAFeeCollector, currency, country, term);
    }

    function getAccessController() external view override returns (IAccessControl) {
        return _accessController;
    }

    function getKBCToken() external view override returns (address) {
        return _KBCToken;
    }

    function getRateFeed() external view override returns (address) {
        return _rateFeed;
    }

    function getKUMABondToken() external view override returns (address) {
        return _KUMABondToken;
    }

    function getKIBToken(bytes32 riskCategory) external view override returns (address) {
        return _KIBToken[riskCategory];
    }

    function getKUMASwap(bytes32 riskCategory) external view override returns (address) {
        return _KUMASwap[riskCategory];
    }

    function getKUMAFeeCollector(bytes32 riskCategory) external view override returns (address) {
        return _KUMAFeeCollector[riskCategory];
    }

    function _checkRiskCategory(bytes4 currency, bytes4 country, uint64 term) internal pure returns (bytes32) {
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.INVALID_RISK_CATEGORY();
        }
        return keccak256(abi.encode(currency, country, term));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyManager {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "./libraries/Errors.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKUMAFeeCollector} from "./interfaces/IKUMAFeeCollector.sol";
import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {Roles} from "./libraries/Roles.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMAFeeCollector is IKUMAFeeCollector, UUPSUpgradeable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    IKUMAAddressProvider private _KUMAAddressProvider;
    bytes32 private _riskCategory;
    EnumerableSet.AddressSet private _payees;
    uint256 private _totalShares;

    mapping(address => uint256) private _shares;

    modifier onlyManager() {
        if (!_KUMAAddressProvider.getAccessController().hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
        _;
    }

    constructor() initializer {}

    function initialize(IKUMAAddressProvider KUMAAddressProvider, bytes4 currency, bytes4 country, uint64 term)
        external
        override
        initializer
    {
        if (address(KUMAAddressProvider) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        _KUMAAddressProvider = KUMAAddressProvider;
        _riskCategory = keccak256(abi.encode(currency, country, term));

        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
        emit RiskCategorySet(_riskCategory);
    }

    /**
     * @notice Releases the accumulated fee income to the payees.
     * @dev Uses _totalShares to calculate correct share.
     */
    function release() external override {
        IERC20 KIBToken = IERC20(_KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 availableIncome = KIBToken.balanceOf(address(this));

        if (availableIncome == 0) {
            revert Errors.NO_AVAILABLE_INCOME();
        }
        if (_payees.length() == 0) {
            revert Errors.NO_PAYEES();
        }

        _release(KIBToken, availableIncome);
    }

    /**
     * @notice Adds a payee.
     * @dev Will update totalShares and therefore reduce the relative share of all other payees.
     * @dev Will release existing fees before the update.
     * @param payee The address of the payee to add.
     * @param share The number of shares owned by the payee.
     */
    function addPayee(address payee, uint256 share) external override onlyManager {
        if (_payees.contains(payee)) {
            revert Errors.PAYEE_ALREADY_EXISTS();
        }
        if (payee == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (share == 0) {
            revert Errors.SHARE_CANNOT_BE_ZERO();
        }

        _releaseIfAvailableIncome();

        _payees.add(payee);
        _shares[payee] = share;
        _totalShares += share;

        emit PayeeAdded(payee, share);
    }

    /**
     * @notice Removes a payee.
     * @dev Will update totalShares and therefore increase the relative share of all other payees.
     * @dev Will release existing fees before the update.
     * @param payee The address of the payee to add.
     */
    function removePayee(address payee) external override onlyManager {
        if (!_payees.contains(payee)) {
            revert Errors.PAYEE_DOES_NOT_EXIST();
        }

        _releaseIfAvailableIncome();

        _payees.remove(payee);
        _totalShares -= _shares[payee];
        delete _shares[payee];

        emit PayeeRemoved(payee);
    }

    /**
     * @notice Updates an existing payee's share.
     * @dev Will release existing fees before the update.
     * @param payee Payee's address.
     * @param share New payee's share.
     */
    function updatePayeeShare(address payee, uint256 share) external onlyManager {
        if (!_payees.contains(payee)) {
            revert Errors.PAYEE_DOES_NOT_EXIST();
        }
        if (share == 0) {
            revert Errors.SHARE_CANNOT_BE_ZERO();
        }

        _releaseIfAvailableIncome();

        uint256 currentShare = _shares[payee];

        if (currentShare < share) {
            _totalShares += share - currentShare;
        } else if (currentShare > share) {
            _totalShares -= currentShare - share;
        }

        _shares[payee] = share;

        emit ShareUpdated(payee, share);
    }

    /**
     * @notice Updates the payee configuration to a new one.
     * @dev Will release existing fees before the update.
     * @param newPayees Array of  new payees
     * @param newShares Array of shares for each new payee
     */
    function changePayees(address[] calldata newPayees, uint256[] calldata newShares) external override onlyManager {
        if (newPayees.length != newShares.length) {
            revert Errors.PAYEES_AND_SHARES_MISMATCHED(newPayees.length, newShares.length);
        }
        if (newPayees.length == 0) {
            revert Errors.NO_PAYEES();
        }

        _releaseIfAvailableIncome();

        uint256 payeesLength = _payees.length();

        if (payeesLength > 0) {
            for (uint256 i = payeesLength; i > 0; i--) {
                address payee = _payees.at(i - 1);
                _payees.remove(payee);
                delete _shares[payee];
                emit PayeeRemoved(payee);
            }
            _totalShares = 0;
        }

        uint256 newPayeesLength = newPayees.length;
        uint256 totalShares = _totalShares;

        for (uint256 i; i < newPayeesLength;) {
            if (newPayees[i] == address(0)) {
                revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
            }
            if (newShares[i] == 0) {
                revert Errors.SHARE_CANNOT_BE_ZERO();
            }

            address payee = newPayees[i];
            if (!_payees.add(payee)) {
                revert Errors.PAYEE_ALREADY_EXISTS();
            }
            _shares[payee] = newShares[i];
            totalShares += newShares[i];

            emit PayeeAdded(payee, newShares[i]);

            unchecked {
                ++i;
            }
        }

        _totalShares = totalShares;
    }

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    /**
     * @notice Internal helper function to release an available income to a all payees.
     * @dev Uses totalShares to calculate correct share
     * @param KIBToken Cached KIBToken for gas savings.
     * @param availableIncome Available income to release to payees.
     */
    function _release(IERC20 KIBToken, uint256 availableIncome) private {
        uint256 totalShares = _totalShares;

        for (uint256 i; i < _payees.length();) {
            address payee = _payees.at(i);
            KIBToken.safeTransfer(payee, availableIncome * _shares[payee] / totalShares);

            unchecked {
                ++i;
            }
        }

        emit FeeReleased(availableIncome);
    }

    /**
     * @notice Internal helper function to release an available income to a all payees if there is an availble income.
     */
    function _releaseIfAvailableIncome() private {
        IERC20 KIBToken = IERC20(_KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 availableIncome = KIBToken.balanceOf(address(this));

        if (availableIncome > 0 && _payees.length() > 0) {
            _release(KIBToken, availableIncome);
        }
    }

    /**
     * @return Array of current payees.
     */
    function getPayees() external view returns (address[] memory) {
        return _payees.values();
    }

    /**
     * @return Total shares.
     */
    function getTotalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @return Share of specific payee.
     */
    function getShare(address payee) external view returns (uint256) {
        return _shares[payee];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyManager {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMABondToken} from "lib/mcag-contracts/src/interfaces/IKUMABondToken.sol";
import {IKUMAAddressProvider} from "./interfaces/IKUMAAddressProvider.sol";
import {IKBCToken} from "./interfaces/IKBCToken.sol";
import {IKIBToken} from "./interfaces/IKIBToken.sol";
import {IKUMASwap} from "./interfaces/IKUMASwap.sol";
import {IMCAGRateFeed} from "./interfaces/IMCAGRateFeed.sol";
import {PausableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {PercentageMath} from "./libraries/PercentageMath.sol";
import {Roles} from "./libraries/Roles.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract KUMASwap is IKUMASwap, PausableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using PercentageMath for uint256;
    using Roles for bytes32;
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    uint256 public constant MIN_ALLOWED_COUPON = WadRayMath.RAY;
    uint256 public constant DEPRECATION_MODE_TIMELOCK = 2 days;

    bytes32 private _riskCategory;
    uint16 private _maxCoupons;
    IKUMAAddressProvider private _KUMAAddressProvider;
    bool private _isDeprecated;
    uint56 private _deprecationInitializedAt;
    uint16 private _variableFee;
    uint96 private _expirationDelay;
    IERC20 private _deprecationStableCoin;
    uint256 private _fixedFee;
    uint256 private _minCoupon;

    // @notice Set of unique coupons in reserve
    EnumerableSet.UintSet private _coupons;
    // @notice Set of all token ids in reserve
    EnumerableSet.UintSet private _bondReserve;
    // @notice Set of all expired token ids in the reserve;
    EnumerableSet.UintSet private _expiredBonds;

    // @notice KUMABondToken id to KBCToken id
    mapping(uint256 => uint256) private _cloneBonds;
    // @notice Quantity of each coupon in reserve
    mapping(uint256 => uint256) private _couponInventory;
    // @notive Bond id to Bond sale price discounted by KIBToken cumulative yield
    mapping(uint256 => uint256) private _bondBaseValue;

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(_KUMAAddressProvider.getAccessController()).hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    modifier whenNotDeprecated() {
        if (_isDeprecated) {
            revert Errors.DEPRECATION_MODE_ENABLED();
        }
        _;
    }

    modifier whenDeprecated() {
        if (!_isDeprecated) {
            revert Errors.DEPRECATION_MODE_NOT_ENABLED();
        }
        _;
    }

    constructor() initializer {}

    /**
     * @param KUMAAddressProvider KUMAAddressProvider.
     * @param currency Underlying bonds currency.
     * @param country Underlying bonds treasury issuer.
     * @param term Underling bonds term.
     */
    function initialize(
        IKUMAAddressProvider KUMAAddressProvider,
        IERC20 deprecationStableCoin,
        bytes4 currency,
        bytes4 country,
        uint64 term
    ) external override initializer {
        if (address(KUMAAddressProvider) == address(0) || address(deprecationStableCoin) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        _KUMAAddressProvider = KUMAAddressProvider;
        _maxCoupons = uint16(term / 30 days);
        _riskCategory = keccak256(abi.encode(currency, country, term));
        _minCoupon = MIN_ALLOWED_COUPON;
        _deprecationStableCoin = deprecationStableCoin;
        __Pausable_init();

        emit DeprecationStableCoinSet(address(0), address(deprecationStableCoin));
        emit KUMAAddressProviderSet(address(KUMAAddressProvider));
        emit RiskCategorySet(_riskCategory);
    }

    /**
     * @notice Sells a bond against KIBToken.
     * @param tokenId Sold bond tokenId.
     */
    function sellBond(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(KUMAAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);
        if (!_coupons.contains(bond.coupon) && _coupons.length() == _maxCoupons) {
            revert Errors.MAX_COUPONS_REACHED();
        }
        if (bond.riskCategory != _riskCategory) {
            revert Errors.WRONG_RISK_CATEGORY();
        }

        if (bond.maturity <= block.timestamp) {
            revert Errors.CANNOT_SELL_MATURED_BOND();
        }

        IKIBToken KIBToken = IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 referenceRate = IMCAGRateFeed(KUMAAddressProvider.getRateFeed()).getRate(_riskCategory);

        if (bond.coupon < referenceRate) {
            revert Errors.COUPON_TOO_LOW();
        }

        if (_coupons.length() == 0) {
            _minCoupon = bond.coupon;
            _coupons.add(bond.coupon);
        } else {
            if (bond.coupon < _minCoupon) {
                _minCoupon = bond.coupon;
            }
            if (!_coupons.contains(bond.coupon)) {
                _coupons.add(bond.coupon);
            }
        }

        _couponInventory[bond.coupon]++;
        _bondReserve.add(tokenId);

        uint256 bondValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);

        _bondBaseValue[tokenId] = bondValue.wadToRay().rayDiv(KIBToken.getUpdatedCumulativeYield());

        uint256 fee = _calculateFees(bondValue);

        uint256 mintAmount = bondValue;

        if (fee > 0) {
            mintAmount = bondValue - fee;
            KIBToken.mint(KUMAAddressProvider.getKUMAFeeCollector(_riskCategory), fee);
        }

        KIBToken.mint(msg.sender, mintAmount);
        KUMABondToken.safeTransferFrom(msg.sender, address(this), tokenId);

        emit FeeCharged(fee);
        emit BondSold(tokenId, mintAmount, msg.sender);
    }

    /**
     * @notice Buys a bond against KIBToken.
     * @param tokenId Bought bond tokenId.
     */
    function buyBond(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(KUMAAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        bool isBondExpired = _expiredBonds.contains(tokenId);

        if (_expiredBonds.length() > 0 && !isBondExpired) {
            revert Errors.EXPIRED_BONDS_MUST_BE_BOUGHT_FIRST();
        }

        if (_couponInventory[bond.coupon] == 1) {
            _coupons.remove(bond.coupon);
        }

        _couponInventory[bond.coupon]--;
        _bondReserve.remove(tokenId);

        if (isBondExpired) {
            _expiredBonds.remove(tokenId);
        }

        IKIBToken KIBToken = IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory));

        uint256 bondFaceValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);
        uint256 realizedBondValue = _bondBaseValue[tokenId].rayMul(KIBToken.getUpdatedCumulativeYield()).rayToWad();

        if (bondFaceValue > realizedBondValue) {
            uint256 previousEpochTimestamp = KIBToken.getPreviousEpochTimestamp();
            uint256 yield = KIBToken.getYield();
            _updateMinCoupon();
            KIBToken.burn(msg.sender, realizedBondValue);
            _cloneBonds[tokenId] = IKBCToken(KUMAAddressProvider.getKBCToken()).issueBond(
                msg.sender,
                IKBCToken.CloneBond({
                    parentId: tokenId,
                    issuance: previousEpochTimestamp,
                    coupon: yield,
                    principal: realizedBondValue
                })
            );
        } else {
            _updateMinCoupon();
            KIBToken.burn(msg.sender, realizedBondValue);
            KUMABondToken.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        delete _bondBaseValue[tokenId];

        emit BondBought(tokenId, realizedBondValue, msg.sender);
    }

    /**
     * @notice Buys a bond against _deprecationStableCoin.
     * @dev Requires an approval on amount from buyer. This will also result in some stale state for the contract on _coupons
     * and _minCoupon but this is acceptable as deprecation mode is irreversible. This function also ignores any existing clone bond
     * which is the intended bahaviour as bonds will be valued per their market rate offchain.
     * @param tokenId Bought bond tokenId.
     * @param buyer Bought bond buyer.
     * @param amount Stable coin price paid by the buyer.
     */
    function buyBondForStableCoin(uint256 tokenId, address buyer, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_MANAGER_ROLE)
        whenDeprecated
    {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }
        if (buyer == address(0)) {
            revert Errors.BUYER_CANNOT_BE_ADDRESS_ZERO();
        }
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }

        _bondReserve.remove(tokenId);

        _deprecationStableCoin.safeTransferFrom(buyer, address(this), amount);
        IKUMABondToken(_KUMAAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), buyer, tokenId);

        emit BondBought(tokenId, amount, buyer);
    }

    /**
     * @notice Claims a bond against a CloneBond.
     * @dev Can only by called by a KUMA_SWAP_CLAIM_ROLE address.
     * @param tokenId Claimed bond tokenId.
     */
    function claimBond(uint256 tokenId)
        external
        override
        onlyRole(Roles.KUMA_SWAP_CLAIM_ROLE.toGranularRole(_riskCategory))
    {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;

        if (_cloneBonds[tokenId] == 0) {
            revert Errors.BOND_NOT_AVAILABLE_FOR_CLAIM();
        }

        uint256 gBondId = _cloneBonds[tokenId];
        delete _cloneBonds[tokenId];

        IKBCToken(KUMAAddressProvider.getKBCToken()).redeem(gBondId);
        IKUMABondToken(KUMAAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), msg.sender, tokenId);

        emit BondClaimed(tokenId, gBondId);
    }

    /**
     * @notice Redeems KIBToken against deprecation mode stable coin. Redeem stable coin amount is calculated as follow :
     *                          KIBTokenAmount
     *      redeemAmount = ------------------------ * KUMASwapStableCoinBalance
     *                        KIBTokenTotalSupply
     * @dev Can only be called if deprecation mode is enabled.
     * @param amount Amount of KIBToken to redeem.
     */
    function redeemKIBT(uint256 amount) external override whenDeprecated {
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }
        if (_bondReserve.length() != 0) {
            revert Errors.BOND_RESERVE_NOT_EMPTY();
        }
        IKIBToken KIBToken = IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory));
        IERC20 deprecationStableCoin = _deprecationStableCoin;

        uint256 redeemAmount =
            amount.wadMul(_deprecationStableCoin.balanceOf(address(this))).wadDiv(KIBToken.totalSupply());
        KIBToken.burn(msg.sender, amount);
        deprecationStableCoin.safeTransfer(msg.sender, redeemAmount);

        emit KIBTRedeemed(msg.sender, redeemAmount);
    }

    /**
     * @notice Expires a bond if it has reached maturity by setting _minCoupon to MIN_ALLOWED_COUPON.
     * @param tokenId Claimed bond tokenId.
     */
    function expireBond(uint256 tokenId) external override whenNotDeprecated {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        if (_expiredBonds.contains(tokenId)) {
            revert Errors.BOND_ALREADY_EXPIRED();
        }

        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;

        if (IKUMABondToken(KUMAAddressProvider.getKUMABondToken()).getBond(tokenId).maturity > block.timestamp) {
            revert Errors.BOND_NOT_MATURED();
        }

        _expiredBonds.add(tokenId);

        IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory)).refreshYield();

        emit BondExpired(tokenId);
    }

    /**
     * @dev See {Pausable-_pause}.
     */
    function pause() external override onlyRole(Roles.KUMA_SWAP_PAUSE_ROLE.toGranularRole(_riskCategory)) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     */
    function unpause() external override onlyRole(Roles.KUMA_SWAP_UNPAUSE_ROLE.toGranularRole(_riskCategory)) {
        _unpause();
    }

    /**
     * @notice Set fees that will be charges upon bond sale per the following formula :
     * totalFee = bondValue * variableFee + fixedFee.
     * @param variableFee in basis points.
     * @param fixedFee in KIBToken decimals.
     */
    function setFees(uint16 variableFee, uint256 fixedFee) external override onlyRole(Roles.KUMA_MANAGER_ROLE) {
        _variableFee = variableFee;
        _fixedFee = fixedFee;
        emit FeeSet(variableFee, fixedFee);
    }

    /**
     * @notice Sets a new stable coin to be accepted during deprecation mode.
     * @param newDeprecationStableCoin New stable coin.
     */
    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin)
        external
        override
        onlyRole(Roles.KUMA_MANAGER_ROLE)
        whenNotDeprecated
    {
        if (address(newDeprecationStableCoin) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        emit DeprecationStableCoinSet(address(_deprecationStableCoin), address(newDeprecationStableCoin));
        _deprecationStableCoin = newDeprecationStableCoin;
    }

    /**
     * @notice Initializes deprecation mode.
     */
    function initializeDeprecationMode() external override onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt != 0) {
            revert Errors.DEPRECATION_MODE_ALREADY_INITIALIZED();
        }

        _deprecationInitializedAt = uint56(block.timestamp);

        emit DeprecationModeInitialized();
    }

    /**
     * @notice Cancel the initialization of the deprecation mode.
     */
    function uninitializeDeprecationMode() external onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        _deprecationInitializedAt = 0;

        emit DeprecationModeUninitialized();
    }

    /**
     * @notice Enables deprecation.
     * @dev Deprecation mode must have been initialized at least 2 days before through the initializeDeprecationMode function.
     */
    function enableDeprecationMode() external override onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        uint256 elapsedTime = block.timestamp - _deprecationInitializedAt;

        if (elapsedTime < DEPRECATION_MODE_TIMELOCK) {
            revert Errors.ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(
                elapsedTime, DEPRECATION_MODE_TIMELOCK
            );
        }

        _isDeprecated = true;

        IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory)).refreshYield();

        emit DeprecationModeEnabled();
    }

    /**
     * @return _riskCategory risk category of the bonds accepted by the contract.
     */
    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    /**
     * @return _maxCoupons Maximum amount of unique coupons accepted by the contract.
     */
    function getMaxCoupons() external view returns (uint16) {
        return _maxCoupons;
    }

    /**
     * @return _KUMAAddressProvider.
     */
    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    /**
     * @return True if deprecation mode has been initialized false if not.
     */
    function isDeprecationInitialized() external view override returns (bool) {
        return _deprecationInitializedAt != 0;
    }

    /**
     * @return Timestamp of deprecation mode initialization.
     */
    function getDeprecationInitializedAt() external view override returns (uint56) {
        return _deprecationInitializedAt;
    }

    /**
     * @return True if deprecation mode has been enabled false if not.
     */
    function isDeprecated() external view override returns (bool) {
        return _isDeprecated;
    }

    /**
     * @return _varibaleFee Variable fee in basis points.
     */
    function getVariableFee() external view override returns (uint16) {
        return _variableFee;
    }

    /**
     * @return _deprecationStableCoin Accepted stable coin during deprecation mode.
     */
    function getDeprecationStableCoin() external view override returns (IERC20) {
        return _deprecationStableCoin;
    }

    /**
     * @return _fixedFee Fixed fee in KIBToken decimals.
     */
    function getFixedFee() external view override returns (uint256) {
        return _fixedFee;
    }

    /**
     * @return Lowest coupon of bonds in reserve.
     */
    function getMinCoupon() external view override returns (uint256) {
        return _minCoupon;
    }

    /**
     * @return Array of all coupons in reserve.
     */
    function getCoupons() external view override returns (uint256[] memory) {
        return _coupons.values();
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getBondReserve() external view override returns (uint256[] memory) {
        return _bondReserve.values();
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getExpiredBonds() external view override returns (uint256[] memory) {
        return _expiredBonds.values();
    }

    /**
     * @return CloneBond Id of parent tokenId.
     */
    function getCloneBond(uint256 tokenId) external view override returns (uint256) {
        return _cloneBonds[tokenId];
    }

    /**
     * @return Amount of bonds with coupon value in inventory.
     */
    function getCouponInventory(uint256 coupon) external view override returns (uint256) {
        return _couponInventory[coupon];
    }

    /**
     * @return True if bond is in reserve false if not.
     */
    function isInReserve(uint256 tokenId) external view override returns (bool) {
        return _bondReserve.contains(tokenId);
    }

    /**
     * @return True if reserve has an expired bond false if not.
     */
    function isExpired() external view override returns (bool) {
        return _expiredBonds.length() > 0;
    }

    /**
     * @return Bond base value.
     */
    function getBondBaseValue(uint256 tokenId) external view override returns (uint256) {
        return _bondBaseValue[tokenId];
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}

    /**
     * @return bondValue Bond principal value + accrued interests.
     */
    function _getBondValue(uint256 issuance, uint256 term, uint256 coupon, uint256 principal)
        private
        view
        returns (uint256)
    {
        uint256 previousEpochTimestamp =
            IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory)).getPreviousEpochTimestamp();

        if (previousEpochTimestamp <= issuance) {
            return principal;
        }

        uint256 elapsedTime = previousEpochTimestamp - issuance;

        if (elapsedTime > term) {
            elapsedTime = term;
        }

        return coupon.rayPow(elapsedTime).rayMul(principal);
    }

    /**
     * @return minCoupon Lowest coupon of bonds in reserve.
     */
    function _updateMinCoupon() private returns (uint256) {
        uint256 currentMinCoupon = _minCoupon;

        if (_coupons.length() == 0) {
            _minCoupon = MIN_ALLOWED_COUPON;
            emit MinCouponUpdated(currentMinCoupon, MIN_ALLOWED_COUPON);
            return MIN_ALLOWED_COUPON;
        }

        if (_couponInventory[currentMinCoupon] != 0) {
            return currentMinCoupon;
        }

        uint256 minCoupon = _coupons.at(0);

        uint256 couponsLength = _coupons.length();

        for (uint256 i = 1; i < couponsLength;) {
            uint256 coupon = _coupons.at(i);

            if (coupon < minCoupon) {
                minCoupon = coupon;
            }

            unchecked {
                ++i;
            }
        }

        _minCoupon = minCoupon;

        emit MinCouponUpdated(currentMinCoupon, minCoupon);

        return minCoupon;
    }

    /**
     * @return fee Based on a specific amount.
     */
    function _calculateFees(uint256 amount) private view returns (uint256 fee) {
        if (_variableFee > 0) {
            fee = amount.percentMul(_variableFee);
        }
        if (_fixedFee > 0) {
            fee += _fixedFee;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library Errors {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error CANNOT_SET_TO_ZERO();
    error ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
    error ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
    error ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
    error ERC20_MINT_TO_THE_ZERO_ADDRESS();
    error ERC20_BURN_FROM_THE_ZERO_ADDRESS();
    error ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
    error START_TIME_NOT_REACHED();
    error EPOCH_LENGTH_CANNOT_BE_ZERO();
    error ERROR_YIELD_LT_RAY();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLISTABLE_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLISTABLE_ACCOUNT_IS_BLACKLISTED(address account);
    error NEW_YIELD_TOO_HIGH();
    error NEW_EPOCH_LENGTH_TOO_HIGH();
    error WRONG_RISK_CATEGORY();
    error WRONG_RISK_CONFIG();
    error INVALID_RISK_CATEGORY();
    error INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error CALLER_NOT_KUMASWAP();
    error CALLER_NOT_MIMO_BOND_TOKEN();
    error BOND_NOT_AVAILABLE_FOR_CLAIM();
    error CANNOT_SELL_MATURED_BOND();
    error NO_EXPIRED_BOND_IN_RESERVE();
    error MAX_COUPONS_REACHED();
    error COUPON_TOO_LOW();
    error CALLER_IS_NOT_MIB_TOKEN();
    error CALLER_NOT_FEE_COLLECTOR();
    error PAYEE_ALREADY_EXISTS();
    error PAYEE_DOES_NOT_EXIST();
    error PAYEES_AND_SHARES_MISMATCHED(uint256 payeeLength, uint256 shareLength);
    error NO_PAYEES();
    error NO_AVAILABLE_INCOME();
    error SHARE_CANNOT_BE_ZERO();
    error DEPRECATION_MODE_ENABLED();
    error DEPRECATION_MODE_ALREADY_INITIALIZED();
    error DEPRECATION_MODE_NOT_INITIALIZED();
    error DEPRECATION_MODE_NOT_ENABLED();
    error ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(uint256 elapsed, uint256 minElapsedTime);
    error AMOUNT_CANNOT_BE_ZERO();
    error BOND_RESERVE_NOT_EMPTY();
    error BUYER_CANNOT_BE_ADDRESS_ZERO();
    error RISK_CATEGORY_MISMATCH();
    error EXPIRED_BONDS_MUST_BE_BOUGHT_FIRST();
    error BOND_NOT_MATURED();
    error CANNOT_TRANSFER_TO_SELF();
    error BOND_ALREADY_EXPIRED();
    error ORACLE_ANSWER_IS_STALE();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     */
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     */
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage), iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
            ) { revert(0, 0) }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library Roles {
    bytes32 public constant KUMA_MANAGER_ROLE = keccak256("KUMA_MANAGER_ROLE");
    bytes32 public constant KUMA_MINT_ROLE = keccak256("KUMA_MINT_ROLE");
    bytes32 public constant KUMA_BURN_ROLE = keccak256("KUMA_BURN_ROLE");
    bytes32 public constant KUMA_SET_EPOCH_LENGTH_ROLE = keccak256("KUMA_SET_EPOCH_LENGTH_ROLE");
    bytes32 public constant KUMA_SWAP_CLAIM_ROLE = keccak256("KUMA_SWAP_CLAIM_ROLE");
    bytes32 public constant KUMA_SWAP_PAUSE_ROLE = keccak256("KUMA_SWAP_PAUSE_ROLE");
    bytes32 public constant KUMA_SWAP_UNPAUSE_ROLE = keccak256("KUMA_SWAP_UNPAUSE_ROLE");
    bytes32 public constant KUMA_SET_URI_ROLE = keccak256("KUMA_SET_URI_ROLE");

    function toGranularRole(bytes32 role, bytes32 riskCategory) internal pure returns (bytes32) {
        return keccak256(abi.encode(role, riskCategory));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 *
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     *
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     *
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) { revert(0, 0) }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     *
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     *
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) { revert(0, 0) }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     *
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) { b := add(b, 1) }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     *
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) { revert(0, 0) }
        }
    }

    /**
     * @dev calculates base^exp. The code uses the ModExp precompile
     * @return z base^exp, in ray
     *
     */
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IMCAGRateFeed} from "./interfaces/IMCAGRateFeed.sol";
import {Initializable} from "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {MCAGAggregatorInterface} from "lib/mcag-contracts/src/interfaces/MCAGAggregatorInterface.sol";
import {Roles} from "./libraries/Roles.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";

contract MCAGRateFeed is IMCAGRateFeed, UUPSUpgradeable, Initializable {
    uint8 private constant _DECIMALS = 27;
    uint256 private constant _MIN_RATE_COUPON = WadRayMath.RAY;

    uint256 private _stalenessThreshold;
    IAccessControl private _accessController;

    mapping(bytes32 => MCAGAggregatorInterface) private _oracles;

    modifier onlyManager() {
        if (!_accessController.hasRole(Roles.KUMA_MANAGER_ROLE, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, Roles.KUMA_MANAGER_ROLE);
        }
        _;
    }

    constructor() initializer {}

    /**
     * @param accessController KUMA DAO AccessController.
     */
    function initialize(IAccessControl accessController, uint256 stalenessThreshold) external override initializer {
        if (address(accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (stalenessThreshold == 0) {
            revert Errors.CANNOT_SET_TO_ZERO();
        }
        _accessController = accessController;
        _stalenessThreshold = stalenessThreshold;

        emit AccessControllerSet(address(accessController));
        emit StalenessThresholdSet(stalenessThreshold);
    }

    /**
     * @notice Set an MCAGAggregator for a specific risk category.
     * @param currency Currency of the bond - example : USD
     * @param country Treasury issuer - example : US
     * @param term Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years
     */
    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle)
        external
        override
        onlyManager
    {
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        if (address(oracle) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }

        bytes32 riskCategory = keccak256(abi.encode(currency, country, term));
        _oracles[riskCategory] = oracle;

        emit OracleSet(address(oracle), currency, country, term);
    }

    /**
     * @notice Sets a new staleness threshold.
     * @param stalenessThreshold New staleness threshold in seconds.
     */
    function setStalenessThreshold(uint256 stalenessThreshold) external override onlyManager {
        if (stalenessThreshold == 0) {
            revert Errors.CANNOT_SET_TO_ZERO();
        }
        _stalenessThreshold = stalenessThreshold;

        emit StalenessThresholdSet(stalenessThreshold);
    }

    /**
     * @return KUMA DAO AccessController.
     */
    function getAccessController() external view override returns (IAccessControl) {
        return _accessController;
    }

    /**
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     * @return rate Oracle rate in 27 decimals.
     */
    function getRate(bytes32 riskCategory) external view override returns (uint256) {
        MCAGAggregatorInterface oracle = _oracles[riskCategory];
        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();

        if (block.timestamp - updatedAt > _stalenessThreshold) {
            revert Errors.ORACLE_ANSWER_IS_STALE();
        }

        if (answer < 0) {
            return _MIN_RATE_COUPON;
        }

        uint256 rate = uint256(answer);
        uint8 oracleDecimal = oracle.decimals();

        if (_DECIMALS < oracleDecimal) {
            rate = uint256(answer) / (10 ** (oracleDecimal - _DECIMALS));
        } else if (_DECIMALS > oracleDecimal) {
            rate = uint256(answer) * 10 ** (_DECIMALS - oracleDecimal);
        }

        if (rate < _MIN_RATE_COUPON) {
            return _MIN_RATE_COUPON;
        }

        return rate;
    }

    /**
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     * @return MCAGAggregator for a specific risk category.
     */
    function getOracle(bytes32 riskCategory) external view override returns (MCAGAggregatorInterface) {
        return _oracles[riskCategory];
    }

    /**
     * @return Current staleness threshold.
     */
    function getStalenessThreshold() external view override returns (uint256) {
        return _stalenessThreshold;
    }

    /**
     * @return Minimum acceptable rate.
     */
    function minRateCoupon() external pure override returns (uint256) {
        return _MIN_RATE_COUPON;
    }

    /**
     * @return Number of decimals used to get its user representation.
     */
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyManager {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMAAddressProvider} from "../../interfaces/IKUMAAddressProvider.sol";

interface IMockKUMASwapV2 is IERC721Receiver {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 cloneTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event KIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);

    function reinitialize() external;

    function sellAsset(uint256 tokenId) external;

    function buyAsset(uint256 tokenId) external;

    function buyAssetForStableCoin(uint256 tokenId, address buyer, uint256 amount) external;

    function claimAsset(uint256 tokenId) external;

    function redeemKIBT(uint256 amount) external;

    function pause() external;

    function unpause() external;

    function expireBond(uint256 tokenId) external;

    function setFees(uint16 variableFee, uint256 fixedFee) external;

    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin) external;

    function initializeDeprecationMode() external;

    function uninitializeDeprecationMode() external;

    function enableDeprecationMode() external;

    function getRiskCategory() external view returns (bytes32);

    function getMaxCoupons() external view returns (uint16);

    function getKUMAAddressProvider() external returns (IKUMAAddressProvider);

    function isDeprecationInitialized() external view returns (bool);

    function getDeprecationInitializedAt() external view returns (uint56);

    function isDeprecated() external view returns (bool);

    function getVariableFee() external view returns (uint16);

    function getDeprecationStableCoin() external view returns (IERC20);

    function getFixedFee() external view returns (uint256);

    function getMinCoupon() external view returns (uint256);

    function getCoupons() external view returns (uint256[] memory);

    function getCouponIndex(uint256 coupon) external view returns (uint256);

    function getBondReserve() external view returns (uint256[] memory);

    function getExpiredBonds() external view returns (uint256[] memory);

    function getBondIndex(uint256 tokenId) external view returns (uint256);

    function getCloneBond(uint256 tokenId) external view returns (uint256);

    function getCouponInventory(uint256 coupon) external view returns (uint256);

    function isInReserve(uint256 tokenId) external view returns (bool);

    function isExpired() external view returns (bool);

    function getBondBaseValue(uint256 tokenId) external view returns (uint256);

    function getDummyVar0() external view returns (uint256);

    function version() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20("MockERC20", "MERC20") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "../libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMABondToken} from "lib/mcag-contracts/src/interfaces/IKUMABondToken.sol";
import {IKUMAAddressProvider} from "../interfaces/IKUMAAddressProvider.sol";
import {IKBCToken} from "../interfaces/IKBCToken.sol";
import {IKIBToken} from "../interfaces/IKIBToken.sol";
import {IMockKUMASwapV2} from "./interfaces/IMockKUMASwapV2.sol";
import {IMCAGRateFeed} from "../interfaces/IMCAGRateFeed.sol";
import {PausableUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {Roles} from "../libraries/Roles.sol";
import {WadRayMath} from "../libraries/WadRayMath.sol";
import {UUPSUpgradeable} from "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MockKUMASwapV2 is IMockKUMASwapV2, PausableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using PercentageMath for uint256;
    using Roles for bytes32;
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    uint256 public constant MIN_ALLOWED_COUPON = WadRayMath.RAY;
    uint256 public constant DEPRECATION_MODE_TIMELOCK = 2 days;

    uint8 private constant _VERSION = 2;

    bytes32 private _riskCategory;
    uint16 private _maxCoupons;
    IKUMAAddressProvider private _KUMAAddressProvider;
    bool private _isDeprecated;
    uint56 private _deprecationInitializedAt;
    uint16 private _variableFee;
    uint96 private _expirationDelay;
    IERC20 private _deprecationStableCoin;
    uint256 private _fixedFee;
    uint256 private _minCoupon;

    // @notice Set of unique coupons in reserve
    EnumerableSet.UintSet private _coupons;
    // @notice Set of all token ids in reserve
    EnumerableSet.UintSet private _bondReserve;
    // @notice Set of all expired token ids in the reserve;
    EnumerableSet.UintSet private _expiredBonds;

    // @notice KUMABondToken id to KBCToken id
    mapping(uint256 => uint256) private _cloneBonds;
    // @notice Quantity of each coupon in reserve
    mapping(uint256 => uint256) private _couponInventory;
    // @notive Bond id to Bond sale price discounted by KIBToken cumulative yield
    mapping(uint256 => uint256) private _bondBaseValue;

    // New non dynamic state variables should be stored here
    uint256 private _dummyVar0;

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(_KUMAAddressProvider.getAccessController()).hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    modifier whenNotDeprecated() {
        if (_isDeprecated) {
            revert Errors.DEPRECATION_MODE_ENABLED();
        }
        _;
    }

    modifier whenDeprecated() {
        if (!_isDeprecated) {
            revert Errors.DEPRECATION_MODE_NOT_ENABLED();
        }
        _;
    }

    function reinitialize() external override reinitializer(_VERSION) {
        _dummyVar0 = 123;
    }

    /**
     * @notice Sells a bond against KIBToken.
     * @param tokenId Sold bond tokenId.
     */
    function sellAsset(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        if (_coupons.length() == _maxCoupons) {
            revert Errors.MAX_COUPONS_REACHED();
        }
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(KUMAAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (bond.riskCategory != _riskCategory) {
            revert Errors.WRONG_RISK_CATEGORY();
        }

        if (bond.maturity <= block.timestamp) {
            revert Errors.CANNOT_SELL_MATURED_BOND();
        }

        IKIBToken KIBToken = IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory));
        uint256 referenceRate = IMCAGRateFeed(KUMAAddressProvider.getRateFeed()).getRate(_riskCategory);

        if (bond.coupon < referenceRate) {
            revert Errors.COUPON_TOO_LOW();
        }

        if (_coupons.length() == 0) {
            _minCoupon = bond.coupon;
            _coupons.add(bond.coupon);
        } else {
            if (bond.coupon < _minCoupon) {
                _minCoupon = bond.coupon;
            }
            if (!_coupons.contains(bond.coupon)) {
                _coupons.add(bond.coupon);
            }
        }

        _couponInventory[bond.coupon]++;
        _bondReserve.add(tokenId);

        uint256 bondValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);

        _bondBaseValue[tokenId] = bondValue.wadToRay().rayDiv(KIBToken.getUpdatedCumulativeYield());

        uint256 fee = _calculateFees(bondValue);

        uint256 mintAmount = bondValue;

        if (fee > 0) {
            mintAmount = bondValue - fee;
            KIBToken.mint(KUMAAddressProvider.getKUMAFeeCollector(_riskCategory), fee);
        }

        KIBToken.mint(msg.sender, mintAmount);
        KUMABondToken.safeTransferFrom(msg.sender, address(this), tokenId);

        emit FeeCharged(fee);
        emit BondSold(tokenId, mintAmount, msg.sender);
    }

    /**
     * @notice Buys a bond against KIBToken.
     * @param tokenId Bought bond tokenId.
     */
    function buyAsset(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(KUMAAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        bool isBondExpired = _expiredBonds.contains(tokenId);

        if (_expiredBonds.length() > 0 && !isBondExpired) {
            revert Errors.EXPIRED_BONDS_MUST_BE_BOUGHT_FIRST();
        }

        if (_couponInventory[bond.coupon] == 1) {
            _coupons.remove(bond.coupon);
        }

        _couponInventory[bond.coupon]--;
        _bondReserve.remove(tokenId);

        if (isBondExpired) {
            _expiredBonds.remove(tokenId);
        }

        IKIBToken KIBToken = IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory));

        uint256 bondFaceValue = _getBondValue(bond.issuance, bond.term, bond.coupon, bond.principal);
        uint256 realizedBondValue = _bondBaseValue[tokenId].rayMul(KIBToken.getUpdatedCumulativeYield()).rayToWad();

        bool requireClone = bondFaceValue > realizedBondValue;

        if (requireClone) {
            _cloneBonds[tokenId] = IKBCToken(_KUMAAddressProvider.getKBCToken()).issueBond(
                msg.sender,
                IKBCToken.CloneBond({
                    parentId: tokenId,
                    issuance: KIBToken.getPreviousEpochTimestamp(),
                    coupon: KIBToken.getYield(),
                    principal: realizedBondValue
                })
            );
        }

        _updateMinCoupon();

        KIBToken.burn(msg.sender, realizedBondValue);

        if (!requireClone) {
            KUMABondToken.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit BondBought(tokenId, realizedBondValue, msg.sender);
    }

    /**
     * @notice Buys a bond against _deprecationStableCoin.
     * @dev Requires an approval on amount from buyer. This will also result in some stale state for the contract on _coupons
     * and _minCoupon but this is acceptable as deprecation mode is irreversible. This function also ignores any existing clone bond
     * which is the intended bahaviour as bonds will be valued per their market rate offchain.
     * @param tokenId Bought bond tokenId.
     * @param buyer Bought bond buyer.
     * @param amount Stable coin price paid by the buyer.
     */
    function buyAssetForStableCoin(uint256 tokenId, address buyer, uint256 amount)
        external
        override
        onlyRole(Roles.KUMA_MANAGER_ROLE)
        whenDeprecated
    {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }
        if (buyer == address(0)) {
            revert Errors.BUYER_CANNOT_BE_ADDRESS_ZERO();
        }
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }

        _bondReserve.remove(tokenId);

        _deprecationStableCoin.safeTransferFrom(buyer, address(this), amount);
        IKUMABondToken(_KUMAAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), buyer, tokenId);

        emit BondBought(tokenId, amount, buyer);
    }

    /**
     * @notice Claims a bond against a CloneBond.
     * @dev Can only by called by a KUMA_SWAP_CLAIM_ROLE address.
     * @param tokenId Claimed bond tokenId.
     */
    function claimAsset(uint256 tokenId)
        external
        override
        onlyRole(Roles.KUMA_SWAP_CLAIM_ROLE.toGranularRole(_riskCategory))
    {
        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;

        if (_cloneBonds[tokenId] == 0) {
            revert Errors.BOND_NOT_AVAILABLE_FOR_CLAIM();
        }

        uint256 gBondId = _cloneBonds[tokenId];
        delete _cloneBonds[tokenId];

        IKBCToken(KUMAAddressProvider.getKBCToken()).redeem(gBondId);
        IKUMABondToken(KUMAAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), msg.sender, tokenId);

        emit BondClaimed(tokenId, gBondId);
    }

    /**
     * @notice Redeems KIBToken against deprecation mode stable coin. Redeem stable coin amount is calculated as follow :
     *                          KIBTokenAmount
     *      redeemAmount = ------------------------ * KUMASwapStableCoinBalance
     *                        KIBTokenTotalSupply
     * @dev Can only be called if deprecation mode is enabled.
     * @param amount Amount of KIBToken to redeem.
     */
    function redeemKIBT(uint256 amount) external override whenDeprecated {
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }
        if (_bondReserve.length() != 0) {
            revert Errors.BOND_RESERVE_NOT_EMPTY();
        }
        IKIBToken KIBToken = IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory));
        IERC20 deprecationStableCoin = _deprecationStableCoin;

        uint256 redeemAmount =
            amount.wadMul(_deprecationStableCoin.balanceOf(address(this))).wadDiv(KIBToken.totalSupply());
        KIBToken.burn(msg.sender, amount);
        deprecationStableCoin.safeTransfer(msg.sender, redeemAmount);

        emit KIBTRedeemed(msg.sender, redeemAmount);
    }

    /**
     * @notice Expires a bond if it has reached maturity by setting _minCoupon to MIN_ALLOWED_COUPON.
     * @param tokenId Claimed bond tokenId.
     */
    function expireBond(uint256 tokenId) external override whenNotDeprecated {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        IKUMAAddressProvider KUMAAddressProvider = _KUMAAddressProvider;

        if (IKUMABondToken(KUMAAddressProvider.getKUMABondToken()).getBond(tokenId).maturity <= block.timestamp) {
            _expiredBonds.add(tokenId);

            IKIBToken(KUMAAddressProvider.getKIBToken(_riskCategory)).refreshYield();

            emit BondExpired(tokenId);
        }
    }

    /**
     * @dev See {Pausable-_pause}.
     */
    function pause() external override onlyRole(Roles.KUMA_SWAP_PAUSE_ROLE.toGranularRole(_riskCategory)) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     */
    function unpause() external override onlyRole(Roles.KUMA_SWAP_UNPAUSE_ROLE.toGranularRole(_riskCategory)) {
        _unpause();
    }

    /**
     * @notice Set fees that will be charges upon bond sale per the following formula :
     * totalFee = bondValue * variableFee + fixedFee.
     * @param variableFee in basis points.
     * @param fixedFee in KIBToken decimals.
     */
    function setFees(uint16 variableFee, uint256 fixedFee) external override onlyRole(Roles.KUMA_MANAGER_ROLE) {
        _variableFee = variableFee;
        _fixedFee = fixedFee;
        emit FeeSet(variableFee, fixedFee);
    }

    /**
     * @notice Sets a new stable coin to be accepted during deprecation mode.
     * @param newDeprecationStableCoin New stable coin.
     */
    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin)
        external
        override
        onlyRole(Roles.KUMA_MANAGER_ROLE)
        whenNotDeprecated
    {
        if (address(newDeprecationStableCoin) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        emit DeprecationStableCoinSet(address(_deprecationStableCoin), address(newDeprecationStableCoin));
        _deprecationStableCoin = newDeprecationStableCoin;
    }

    /**
     * @notice Initializes deprecation mode.
     */
    function initializeDeprecationMode() external override onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt != 0) {
            revert Errors.DEPRECATION_MODE_ALREADY_INITIALIZED();
        }

        _deprecationInitializedAt = uint56(block.timestamp);

        emit DeprecationModeInitialized();
    }

    /**
     * @notice Cancel the initialization of the deprecation mode.
     */
    function uninitializeDeprecationMode() external onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        _deprecationInitializedAt = 0;

        emit DeprecationModeUninitialized();
    }

    /**
     * @notice Enables deprecation.
     * @dev Deprecation mode must have been initialized at least 2 days before through the initializeDeprecationMode function.
     */
    function enableDeprecationMode() external override onlyRole(Roles.KUMA_MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        uint256 elapsedTime = block.timestamp - _deprecationInitializedAt;

        if (elapsedTime < DEPRECATION_MODE_TIMELOCK) {
            revert Errors.ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(
                elapsedTime, DEPRECATION_MODE_TIMELOCK
            );
        }

        _isDeprecated = true;

        IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory)).refreshYield();

        emit DeprecationModeEnabled();
    }

    function getRiskCategory() external view returns (bytes32) {
        return _riskCategory;
    }

    function getMaxCoupons() external view returns (uint16) {
        return _maxCoupons;
    }

    function getKUMAAddressProvider() external view returns (IKUMAAddressProvider) {
        return _KUMAAddressProvider;
    }

    /**
     * @return True if deprecation mode has been initialized false if not.
     */
    function isDeprecationInitialized() external view override returns (bool) {
        return _deprecationInitializedAt != 0;
    }

    /**
     * @return Timestamp of deprecation mode initialization.
     */
    function getDeprecationInitializedAt() external view override returns (uint56) {
        return _deprecationInitializedAt;
    }

    /**
     * @return True if deprecation mode has been enabled false if not.
     */
    function isDeprecated() external view override returns (bool) {
        return _isDeprecated;
    }

    /**
     * @return _varibaleFee Variable fee in basis points.
     */
    function getVariableFee() external view override returns (uint16) {
        return _variableFee;
    }

    /**
     * @return _deprecationStableCoin Accepted stable coin during deprecation mode.
     */
    function getDeprecationStableCoin() external view override returns (IERC20) {
        return _deprecationStableCoin;
    }

    /**
     * @return _fixedFee Fixed fee in KIBToken decimals.
     */
    function getFixedFee() external view override returns (uint256) {
        return _fixedFee;
    }

    /**
     * @return Lowest coupon of bonds in reserve.
     */
    function getMinCoupon() external view override returns (uint256) {
        return _minCoupon;
    }

    /**
     * @return Array of all coupons in reserve.
     */
    function getCoupons() external view override returns (uint256[] memory) {
        return _coupons.values();
    }

    /**
     * @return Index of coupon in the _coupons Set.
     */
    function getCouponIndex(uint256 coupon) external view override returns (uint256) {
        return _coupons._inner._indexes[bytes32(coupon)];
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getBondReserve() external view override returns (uint256[] memory) {
        return _bondReserve.values();
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getExpiredBonds() external view override returns (uint256[] memory) {
        return _expiredBonds.values();
    }

    /**
     * @return Index of tokenId in the _bondReserve Array.
     */
    function getBondIndex(uint256 tokenId) external view override returns (uint256) {
        return _bondReserve._inner._indexes[bytes32(tokenId)];
    }

    /**
     * @return CloneBond Id of parent tokenId.
     */
    function getCloneBond(uint256 tokenId) external view override returns (uint256) {
        return _cloneBonds[tokenId];
    }

    /**
     * @return Amount of bonds with coupon value in inventory.
     */
    function getCouponInventory(uint256 coupon) external view override returns (uint256) {
        return _couponInventory[coupon];
    }

    /**
     * @return True if bond is in reserve false if not.
     */
    function isInReserve(uint256 tokenId) external view override returns (bool) {
        return _bondReserve.contains(tokenId);
    }

    /**
     * @return True if reserve has an expired bond false if not.
     */
    function isExpired() external view override returns (bool) {
        return _expiredBonds.length() > 0;
    }

    /**
     * @return Bond base value.
     */
    function getBondBaseValue(uint256 tokenId) external view override returns (uint256) {
        return _bondBaseValue[tokenId];
    }

    function getDummyVar0() external view returns (uint256) {
        return _dummyVar0;
    }

    function version() public pure override returns (uint8) {
        return _VERSION;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(Roles.KUMA_MANAGER_ROLE) {}

    /**
     * @return bondValue Bond principal value + accrued interests.
     */
    function _getBondValue(uint256 issuance, uint256 term, uint256 coupon, uint256 principal)
        private
        view
        returns (uint256)
    {
        uint256 previousEpochTimestamp =
            IKIBToken(_KUMAAddressProvider.getKIBToken(_riskCategory)).getPreviousEpochTimestamp();

        if (previousEpochTimestamp <= issuance) {
            return principal;
        }

        uint256 elapsedTime = previousEpochTimestamp - issuance;

        if (elapsedTime > term) {
            elapsedTime = term;
        }

        return coupon.rayPow(elapsedTime).rayMul(principal);
    }

    /**
     * @return minCoupon Lowest coupon of bonds in reserve.
     */
    function _updateMinCoupon() private returns (uint256) {
        uint256 currentMinCoupon = _minCoupon;

        if (_coupons.length() == 0) {
            _minCoupon = MIN_ALLOWED_COUPON;
            emit MinCouponUpdated(currentMinCoupon, MIN_ALLOWED_COUPON);
            return MIN_ALLOWED_COUPON;
        }

        if (_couponInventory[currentMinCoupon] != 0) {
            return currentMinCoupon;
        }

        uint256 minCoupon = _coupons.at(0);

        for (uint256 i = 1; i < _coupons.length();) {
            uint256 coupon = _coupons.at(i);

            if (coupon < minCoupon) {
                minCoupon = coupon;
            }

            unchecked {
                ++i;
            }
        }

        _minCoupon = minCoupon;

        emit MinCouponUpdated(currentMinCoupon, minCoupon);

        return minCoupon;
    }

    /**
     * @return fee Based on a specific amount.
     */
    function _calculateFees(uint256 amount) private view returns (uint256 fee) {
        if (_variableFee > 0) {
            fee = amount.percentMul(_variableFee);
        }
        if (_fixedFee > 0) {
            fee += _fixedFee;
        }
    }
}