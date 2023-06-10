// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IScaledERC20} from "../../interfaces/tokens/IScaledERC20.sol";
import {IInitializableToken} from "../../interfaces/tokens/IInitializableToken.sol";
import {ITToken} from "../../interfaces/tokens/ITToken.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IIncentivesController} from "../../interfaces/IIncentivesController.sol";
import {ScaledERC20} from "./ScaledERC20.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {InterestCalculator} from "../../libraries/math/InterestCalculator.sol";
import {Errors} from "../../libraries/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TToken
 * @author Taker, inspired by AAVE AToken implementation
 * @notice Implementation of TToken
 **/
contract TToken is ScaledERC20, ITToken {
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;

  /// @inheritdoc IInitializableToken
  function initialize(
    address pool,
    address underlyingAsset,
    address incentivesController,
    uint8 decimals,
    string calldata namePrefix,
    string calldata symbolPrefix
  ) external override initializer {
    string memory name = string.concat(namePrefix, "_TTOKEN");
    string memory symbol = string.concat(symbolPrefix, "_TTOKEN");
    __ERC20_init(name, symbol);

    LENDING_POOL = ILendingPool(pool);
    UNDERLYING_ASSET = underlyingAsset;
    INCENTIVES_CONTROLLER = IIncentivesController(incentivesController);

    emit Initialized(underlyingAsset, pool, incentivesController, decimals, name, symbol);
  }

  /// @inheritdoc IScaledERC20
  function mint(
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) external override(ScaledERC20, IScaledERC20) onlyLendingPool returns (bool) {
    return _mintWithScaling(to, amount, scaleFactor);
  }

  /// @inheritdoc ITToken
  function burn(
    address from,
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) external override onlyLendingPool {
    _burnWithScaling(from, amount, scaleFactor);
    if (to != address(this)) {
      IERC20(UNDERLYING_ASSET).safeTransfer(to, amount);
    }
  }

  /// @inheritdoc ITToken
  function transferUnderlying(address to, uint256 amount) external override onlyLendingPool {
    IERC20(UNDERLYING_ASSET).safeTransfer(to, amount);
  }

  /// @inheritdoc ITToken
  function transferOnLiquidation(
    address from,
    address to,
    uint256 amount
  ) external override onlyLendingPool {
    uint256 scaleFactor = LENDING_POOL.getReserveNormalizedLiquidityScale(UNDERLYING_ASSET);
    super._transfer(from, to, amount.rayDiv(scaleFactor));
  }

  /// @inheritdoc IScaledERC20
  function compoundedBalanceOf(address account) public view override returns (uint256) {
    return
      balanceOf(account).rayMul(LENDING_POOL.getReserveNormalizedLiquidityScale(UNDERLYING_ASSET));
  }

  /// @inheritdoc IScaledERC20
  function compoundedTotalSupply() external view override returns (uint256) {
    return
      super.totalSupply().rayMul(LENDING_POOL.getReserveNormalizedLiquidityScale(UNDERLYING_ASSET));
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    uint256 scaleFactor = LENDING_POOL.getReserveNormalizedLiquidityScale(UNDERLYING_ASSET);
    uint256 fromBalanceBefore = compoundedBalanceOf(from);

    super._transfer(from, to, amount.rayDiv(scaleFactor));

    LENDING_POOL.validateTransfer(UNDERLYING_ASSET, from, to, amount, fromBalanceBefore);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
library SafeCast {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title ITakerAddressesProvider
 * @author Taker
 * @notice Taker protocol addresses provider interface
 **/
interface ITakerAddressesProvider {
  event LendingPoolUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  /**
   *  @dev the contract has no proxy.
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   *  @dev the contract has proxy.
   */

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolConfigurator() external view returns (address);

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title IIncentivesController
 * @author Taker
 * @notice Defines the interface for incentives controller
 **/
interface IIncentivesController {
  /**
   * @notice Called when distribution of incentives is needed
   * @param asset The address of the ERC20 asset
   * @param userBalance The balance of the user of the asset in the pool
   * @param totalSupply The total supply of the asset in the pool
   **/
  function handleERC20Action(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @notice Called when distribution of incentives is needed
   * @param asset The address of the nft asset
   * @param tokenNum Number of token put into the pool by the user
   **/
  function handleNFTAction(address asset, uint256 tokenNum) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title IInterestRateCalculator
 * @dev Defines interface of interest rate calculator
 * @author Taker
 */
interface IInterestRateCalculator {
  /**
   * @notice Returns the max borrow rate
   * @return The max borrow rate, in ray
   **/
  function getMaxBorrowRate() external view returns (uint256);

  /**
   * @notice Calculates the interest rates depending on the reserve's states and configurations
   * @param totalLiquidity The current total liquidity
   * @param totalDebt The current total debt
   * @param reserveFactor The reserve factor
   * @return depositRate The deposit rate in ray
   * @return borrowRate The borrow rate in ray
   **/
  function calculateInterestRates(
    uint256 totalLiquidity,
    uint256 totalDebt,
    uint256 reserveFactor
  ) external view returns (uint256 depositRate, uint256 borrowRate);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {ITakerAddressesProvider} from "./configuration/ITakerAddressesProvider.sol";
import {ReserveConfiguration} from "../libraries/types/ReserveConfiguration.sol";
import {UserConfiguration} from "../libraries/types/UserConfiguration.sol";
import {UserNftConfiguration} from "../libraries/types/UserNftConfiguration.sol";
import {Reserve} from "../libraries/types/Reserve.sol";
import {NFTReserve} from "../libraries/types/NFTReserve.sol";
import {UserVariableCalculator} from "../libraries/core/UserVariableCalculator.sol";

/**
 * @title ILendingPool
 * @author Taker
 * @notice Defines the interface for lendingpool
 **/
interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param asset The address of the underlying asset of the reserve
   * @param user The address initiates the deposit
   * @param to The address receiving the tToken
   * @param amount The amount deposited
   **/
  event Deposited(address indexed asset, address user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on depositNFTs()
   * @param nfts The list of underlying NFTs address of the collaterals
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the tNFTs
   * @param tokenIds The list of tokenIds deposited
   * @param amounts The list of amount deposited
   **/
  event NFTsDeposited(
    address[] nfts,
    address user,
    address indexed onBehalfOf,
    uint256[] tokenIds,
    uint256[] amounts
  );

  /**
   * @dev Emitted on withdraw()
   * @param asset The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdraw
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdrawn(address indexed asset, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on withdrawNFTs()
   * @param nfts The list of underlying NFTs address of the collaterals
   * @param user The address initiating the withdrawn
   * @param to The address that will receive the underlying nfts
   * @param tokenIds The list of tokenIds withdrawn
   * @param amounts The list of amount withdrawn
   **/
  event NFTsWithdrawn(
    address[] nfts,
    address indexed user,
    address indexed to,
    uint256[] tokenIds,
    uint256[] amounts
  );

  /**
   * @dev Emitted on borrow()
   * @param asset The address of the asset to borrow
   * @param from Address that receving the debt
   * @param to Address taht receving the underlying
   * @param amount The amount to borrow
   * @param borrowRate The borrow rate after the borrow
   **/
  event Borrowed(
    address indexed asset,
    address indexed from,
    address indexed to,
    uint256 amount,
    uint256 borrowRate
  );

  /**
   * @dev Emitted on repay()
   * @param asset The address of the underlying asset
   * @param initiator The user performs the repay
   * @param to The address which debt is repaid
   * @param amount The repaid amount
   **/
  event Repaid(
    address indexed asset,
    address indexed initiator,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Emitted on liquidate()
   * @param nft The address of nft liquidated
   * @param tokenId The tokenId liquidated
   * @param amount The amount liquidated
   * @param debt The amount of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtCovered The debt repaid by the liquidator
   * @param liquidator The address of the liquidator
   * @param to The address receiving the nft/tNft
   * @param receiveTNFT Bool value to control send TNFT or underlying asset to the liquidator
   **/
  event Liquidated(
    address nft,
    uint256 tokenId,
    uint256 amount,
    address debt,
    address indexed user,
    uint256 debtCovered,
    address indexed liquidator,
    address indexed to,
    bool receiveTNFT
  );

  /**
   * @dev Emitted after interest rate is updated
   * @param asset The address of the underlying asset of the reserve
   * @param depositRate The new deposit rate
   * @param borrowRate The new borrow rate
   * @param liquidityIndex The new liquidity index
   * @param debtIndex The new debt index
   **/
  event ReserveDataUpdated(
    address indexed asset,
    uint256 depositRate,
    uint256 borrowRate,
    uint256 liquidityIndex,
    uint256 debtIndex
  );

  /**
   * @dev Emitted after when using as collateral configuration is updated
   * @param asset The address of the underlying asset of the reserve
   * @param user The user who's collateral configuration is updated
   * @param status Whether is using as collateral
   **/
  event CollateralStatusUpdated(address indexed asset, address indexed user, bool status);

  /**
   * @dev Deposits an `amount` of borrowable underlying asset into the reserve, receives overlying tTokens.
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param to The address receives the tTokens
   **/
  function deposit(address asset, uint256 amount, address to) external;

  /**
   * @dev Deposits an `amount` of NFT with certain tokenId as collateral, receiving in return overlying tNFT.
   * - E.g. User deposits 1 PUNK and gets in return 1 tPUNK
   * @param nfts The address of the NFTs to deposit
   * @param tokenIds The tokenIds to be deposited
   * @param amounts The amounts to be deposited, 1 if it's ERC721
   * @param to The address that will receive the tNFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of tNFT
   *   is a different wallet
   **/
  function depositNFTs(
    address[] calldata nfts,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address to
  ) external;

  /**
   * @dev Withdraws borrowable asset from reserve
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *        type(uint256).max if withdraw full tToken balance
   * @param to Address that will receive the underlying
   **/
  function withdraw(address asset, uint256 amount, address to) external;

  /**
   * @dev Withdraws an `amount` of NFT with certain tokenId, burning the equivalent tNFT owned
   * E.g. User has 1 tPUNK, calls withdraw() and receives 1 PUNK, burning the 1 tPUNK
   * @param nfts The addresses of the NFTs to withdraw
   * @param tokenIds The tokenIds to be withdrawn
   * @param amounts The amounts to be withdrawn, 1 if it's ERC721
   *        type(uint256).max in order to withdraw the whole tNFT balance
   * @param to Address that will receive the underlying
   **/
  function withdrawNFTs(
    address[] calldata nfts,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address to
  ) external;

  /**
   * @dev Borrows amount of asset if have enough collaterals. Receives corresponding debt tokens
   *      User can borrow from another address if credit is delegated
   * @param asset The address of the asset to borrow
   * @param amount The amount to borrow
   * @param from Address that receving the debt.
   **/
  function borrow(address asset, uint256 amount, address from) external;

  /**
   * @notice Repays amount of asset and burn corresponding debt tokens
   * @param asset The address of the asset to borrow
   * @param amount The amount to repay
   * @param to Address which debt token is burnt
   * @return The repaid amount
   **/
  function repay(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Liquidates a position if its Health Factor drops below 1
   * @notice Only allow liquidate one token in one transaction
   * @param nft The addresse of nft to be liquidated
   * @param tokenId The tokenId to be liquidated
   * @param debt The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param to The address receiving the liuquidated nft/tNft
   * @param receiveTNFT Bool value to control send TNFT or underlying asset to the liquidator
   **/
  function liquidate(
    address nft,
    uint256 tokenId,
    address debt,
    address user,
    address to,
    bool receiveTNFT
  ) external;

  /**
   * @dev Initializes a reserve, assigning an tToken, debt token and an
   * interest rate strategy
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The configuration of the asset
   * @param tTokenAddress The address of the associated tToken
   * @param debtTokenAddress The address of the associated DebtToken
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    ReserveConfiguration configuration,
    address tTokenAddress,
    address debtTokenAddress,
    address interestRateStrategyAddress,
    address treasuryAddress
  ) external;

  /**
   * @dev Initializes a NFT reserve, assigning an tToken
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The configuration of the asset
   * @param tNFTAddress The address of the associated tNFT
   **/
  function initNFTReserve(
    address asset,
    ReserveConfiguration configuration,
    address tNFTAddress
  ) external;

  /**
   * @dev Drop reserve
   * @param asset The underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Validate tToken transfer
   * @param asset The address of the underlying asset of the tToken
   * @param from The address which tToken is transferred out
   * @param to  The address receiving the tToken
   * @param amount The amount to transfer
   * @param balanceFromBefore The tToken balance of `from` address before transfer
   */
  function validateTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore
  ) external;

  /**
   * @notice Validate tNft transfer
   * @param asset The address of the underlying asset of the tNft
   * @param from The address which tNft is transferred out
   * @param to  The address receiving the tNft
   * @param amount The amount to transfer
   */
  function validateTransferNft(address asset, address from, address to, uint256 amount) external;

  /**
   * @notice Sets whether to use borrowable asset as collateral
   * @param asset The address of the underlying asset
   * @param usingAsCollateral `true` if set as collateral, `false` otherwise
   **/
  function setUserUsingAsCollateral(address asset, bool usingAsCollateral) external;

  /**
   * @notice Get the normalized income scale of the asset
   * @param asset The address of the underlying asset
   * @return The normalized income scale factor
   */
  function getReserveNormalizedLiquidityScale(address asset) external view returns (uint256);

  /**
   * @notice Get the normalized debt scale of the asset
   * @param asset The address of the underlying asset
   * @return The normalized debt scale factor
   */
  function getReserveNormalizedDebtScale(address asset) external view returns (uint256);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve data
   **/
  function getReserveData(address asset) external view returns (Reserve.ReserveData memory);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve data
   **/
  function getNftReserveData(address asset) external view returns (NFTReserve.ReserveData memory);

  /**
   * @notice Returns the total supply of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of TToken
   **/
  function getReserveTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total supply of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of TERC721
   **/
  function getNftReserveTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the reserve list (both reserve and nft reserve)
   * @return The reserve list
   * @return The nft reserve list
   **/
  function getReservesList() external view returns (address[] memory, address[] memory);

  /**
   * @notice Sets the nft reserve configuration
   * @param asset The address of the underlying asset of the reserve
   * @param isNft Whether the asset is NFT
   * @param configuration The new configuration
   **/
  function setReserveConfig(address asset, bool isNft, ReserveConfiguration configuration) external;

  /**
   * @notice Returns the reserve configuration of the asset
   * @param asset The address of the underlying asset of the reserve
   * @param isNft Whether the asset is NFT
   * @return The configuration of the reserve
   **/
  function getReserveConfig(address asset, bool isNft) external view returns (ReserveConfiguration);

  /**
   * @notice Returns the configuration of the user
   * @param user The address of the user
   * @return The configuration of the user for borrowable asset
   * @return The configuration of the user for NFTs
   **/
  function getUserConfig(
    address user
  ) external view returns (UserConfiguration, UserNftConfiguration);

  /**
   * @dev Updates the address of the treasury
   * @param asset The address of the underlying asset of the reserve
   * @param treasuryAddress The new address of the treasury
   **/
  function setReserveTreasuryAddress(
    address asset,
    address treasuryAddress
  ) external;

  /**
   * @notice Updates the address of the interest rate calculator
   * @param asset The address of the underlying asset of the reserve
   * @param interestRateCalculatorAddress The address of the interest rate calculator
   **/
  function setReserveInterestRateCalculatorAddress(
    address asset,
    address interestRateCalculatorAddress
  ) external;

  /**
   * @notice Get the pool's liquidity of all borrowable and NFT reserves and total debt
   * @return The borrowable liquidity, NFT liquidity, total debt in ETH
   */
  function getPoolValues() external view returns (uint256, uint256, uint256);

  /**
   * @notice Get liquidity and debt of given asset
   * @param asset The address of the asset
   * @return The total liquidity and debt in ETH
   */
  function getAssetValues(address asset) external view returns (uint256, uint256);

  /**
   * @notice Get the user's state variables
   * @param user The address of the user
   * @return The calculated state variables
   */
  function getUserState(
    address user
  ) external view returns (UserVariableCalculator.StateVar memory);

  /**
   * @notice Get user's liquidity, debt, and collateral in given asset
   * @param user The address of the user
   * @param asset The address of the asset
   * @return The  liquidity, debt, and collateral of asset in ETH
   */
  function getUserAssetValues(
    address user,
    address asset
  ) external view returns (uint256, uint256, uint256);

  /**
   * @notice Auto generated function to get address provider address
   * @return Address of address provider
   */
  function ADDRESS_PROVIDER() external view returns (ITakerAddressesProvider);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title PriceOracleGetter interface
 * @author Taker
 * @notice Interface for the taker price oracle
 **/

interface IPriceOracleGetter {
  /**
   * @dev Emitted when new Token Aggregator is set
   * @param asset the address of the asset
   * @param aggregator the aggregator
   **/
  event SetTokenAggregator(address asset, address aggregator);

  /**
   * @dev Emitted when new NFT price is retrieved
   * @param asset the address of the asset
   * @param price the ETH price of the asset
   **/
  event NewPrice(address indexed asset, uint256 price);

  /**
   * @dev returns the reserve asset price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getReserveAssetPrice(address asset) external view returns (uint256);

  /**
   * @dev Sets asset price
   * @param asset the address of the asset
   * @param price the price to set
   */
  function setPrice(address asset, uint256 price) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IScaledERC20} from "./IScaledERC20.sol";

/**
 * @title IDebtToken
 * @author Taker
 * @notice Defines the interface of DebtToken
 **/
interface IDebtToken is IScaledERC20 {
  /**
   * @notice Emitted after delegation
   * @param from The address of the delegator
   * @param to The address of the delegatee
   * @param asset The address asset
   * @param amount The amount delegated
   */
  event Delegated(address indexed from, address indexed to, address indexed asset, uint256 amount);

  /**
   * @notice Mint debt token with a scale factor
   * @param initiator The address initiates the loan
   * @param to The address receives the debt token
   * @param amount The amount of tokens getting minted
   * @param scaleFactor The factor of the corresponding reserve
   **/
  function mint(
    address initiator,
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) external returns (bool);

  /**
   * @notice Delegate borrowing power to the to address
   * @param to The address receives borrowing power
   * @param amount The amount delegated
   **/
  function delegate(address to, uint256 amount) external;

  /**
   * @notice Returns the delegated borrowing power
   * @param from The address of the delegator
   * @param to The address of the delegatee
   * @return The borrowing power delegated
   **/
  function delegateAllowance(address from, address to) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title IInitializableToken
 * @author Taker
 * @notice Defines the basic interface of initializable TTokens
 **/
interface IInitializableToken {
  /**
   * @dev Emitted after initialization of tNFT
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param incentivesController The address of the incentives controller
   * @param decimals  The decimals of the token
   * @param name The name of the token
   * @param symbol The symbol of the token
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 decimals,
    string name,
    string symbol
  );

  /**
   * @notice Initializes the tToken
   * @param pool The address of the associated pool
   * @param underlyingAsset The address of the underlying ERC20 asset
   * @param incentivesController The address of the incentives controller
   * @param decimals  The decimals of the token
   * @param namePrefix The name of the token
   * @param symbolPrefix The symbol of the token
   */
  function initialize(
    address pool,
    address underlyingAsset,
    address incentivesController,
    uint8 decimals,
    string calldata namePrefix,
    string calldata symbolPrefix
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IInitializableToken} from "./IInitializableToken.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IScaledERC20
 * @author Taker inspired by the AAVE ScaledBalanceToken implementation
 * @notice Defines the interface to support scale ERC20.
 **/
interface IScaledERC20 is IERC20Upgradeable, IInitializableToken {
  /**
   * @notice Mint token with a scale factor
   * @param to The address receives the minted tokens
   * @param amount The amount of tokens getting minted
   * @param scaleFactor The factor of the corresponding reserve
   **/
  function mint(
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) external returns (bool);

  /**
   * @notice Burns the token with scaling
   * @param from The address from which the debt token will be burned
   * @param amount The amount to burn
   * @param scaleFactor The factor of the corresponding reserve
   **/
  function burn(
    address from,
    uint256 amount,
    uint256 scaleFactor
  ) external;

  /**
   * @notice Return the scaled balance of the user.
   * @dev The scaled balance is balance * current scale fator
   * @param account The address to calculate balance
   * @return The scaled balance of the account
   **/
  function compoundedBalanceOf(address account) external view returns (uint256);

  /**
   * @notice Return the scaled total supply. (Current total supply of the token * current scale factor)
   * @return The scaled total supply
   **/
  function compoundedTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IInitializableToken} from "./IInitializableToken.sol";

/**
 * @title ITERC1155
 * @author Taker
 * @notice Defines the interface of TERC1155
 **/
interface ITERC1155 is IInitializableToken {
  /**
   * @notice Mints tERC1155 to `to` address
   * @param to The address receiving the minted nft
   * @param tokenId The id of the minted nft
   * @param amount The number of nft to mint
   */
  function mint(address to, uint256 tokenId, uint256 amount) external;

  /**
   * @notice Burns tERC1155 and sends underlying to the token id owner
   * @param from The address from which nft will be burnt
   * @param to The address receives the underlying
   * @param tokenId The id of the nft to burn
   * @param amount The number to burn - type(uint256).max if burn all
   **/
  function burn(address from, address to, uint256 tokenId, uint256 amount) external;

  /**
   * @notice Returns the total supply of the tNFT
   **/
  function totalSupply() external view returns (uint256);

  // @notice Returns the name of the TNft
  function name() external view returns (string memory);

  // @notice Returns the symbol of the TNft
  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IInitializableToken} from "./IInitializableToken.sol";

/**
 * @title ITERC721
 * @author Taker
 * @notice Defines the interface of TERC721
 **/
interface ITERC721 is IInitializableToken {
  /**
   * @notice Mints tERC721 to `to` address
   * @param to The address receiving the minted nft
   * @param tokenId The id of the minted nft
   */
  function mint(address to, uint256 tokenId) external;

  /**
   * @notice Burns tERC721 and sends underlying to the token id owner
   * @param from The account address from which tERC721 will be burnt
   * @param to The address receiving the underlying nft
   * @param tokenId The id of the nft to burn
   **/
  function burn(address from, address to, uint256 tokenId) external;

  /**
   * @notice Returns the total supply of the tNFT
   **/
  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IScaledERC20} from "./IScaledERC20.sol";

/**
 * @title ITToken
 * @author Taker
 * @notice Defines the interface of TToken
 **/
interface ITToken is IScaledERC20 {
  /**
   * @notice Burns TToken
   * @param from The address from which the TToken will be burned
   * @param to The receiver of underlying asset
   * @param amount The amount to burn - type(uint256).max if burn all
   * @param scaleFactor The factor of the corresponding reserve
   **/
  function burn(
    address from,
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) external;

  /**
   * @dev Transfers the underlying asset to `to` address
   * @param to The address receiving the underlying asset
   * @param amount The amount to transfer
   **/
  function transferUnderlying(address to, uint256 amount) external;

  /**
   * @dev Transfers tToken during liquidation
   * @param from The address which tToken is transferred out
   * @param to The address receiving the tToken
   * @param amount The amount to transfer
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {Reserve} from "../../libraries/types/Reserve.sol";
import {NFTReserve} from "../../libraries/types/NFTReserve.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../../libraries/math/PercentageMath.sol";
import {UserConfiguration} from "../../libraries/types/UserConfiguration.sol";
import {UserNftConfiguration} from "../../libraries/types/UserNftConfiguration.sol";
import {ReserveConfiguration} from "../../libraries/types/ReserveConfiguration.sol";

/**
 * @title UserVariableCalculator library
 * @author Taker
 * @notice Implements functions to calculate variables of the current state of the user
 */
library UserVariableCalculator {
  using Reserve for Reserve.ReserveData;
  using NFTReserve for NFTReserve.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  string public constant NAME = "UVC";

  // used to avoid stack too deep err
  struct CalculateUserStateVariableLocalVar {
    uint256 borrowableLiquidityInEth;
    uint256 nftLiquidityInEth;
    uint256 totalCollateralInEth;
    uint256 totalCollateralWithLtvInEth;
    uint256 totalCollateralWithLiqThreshInEth;
    uint256 totalDebtInEth;
    uint256 liquidityInEth;
    uint256 avgLiqThreshold;
    address underlyingAddress;
  }

  struct CalUserStateParam {
    UserConfiguration userConfig;
    UserNftConfiguration userNFTConfig;
    uint256 reserveCount;
    uint256 nftReserveCount;
    address user;
    address oracle;
  }

  struct StateVar {
    uint256 borrowableLiq;
    uint256 nftLiq;
    uint256 totalCollateralInEth;
    uint256 totalDebtInEth;
    uint256 ltv;
    uint256 liqThreshold;
    uint256 hf;
  }

  /**
   * @dev Calculates the user data across all the reserves.
   * @param reserves Data of all the normal reserves
   * @param nftReserves Data of all the nft reserves
   * @param reserveList The address of the corresponding tToken of all the normal reserves
   * @param nftReserveList The address of the corresponding tToken of all the nft reserves
   * @param params other params
   * @return state variables
   **/
  function calculateUserStateVariables(
    mapping(address => Reserve.ReserveData) storage reserves,
    mapping(address => NFTReserve.ReserveData) storage nftReserves,
    mapping(uint256 => address) storage reserveList,
    mapping(uint256 => address) storage nftReserveList,
    CalUserStateParam memory params
  ) public view returns (StateVar memory) {
    // total liquidity here only refer to collaterals
    CalculateUserStateVariableLocalVar memory vars;
    uint256 i;
    // Calculate for borrowable reserves
    for (i = 1; i < params.reserveCount + 1; i++) {
      bool isCollateral = params.userConfig.isUsingAsCollateral(i);
      bool isBorrowing = params.userConfig.isBorrowing(i);
      vars.underlyingAddress = reserveList[i];
      if (vars.underlyingAddress == address(0)) {
        continue;
      }
      Reserve.ReserveData storage currentReserve = reserves[vars.underlyingAddress];
      ReserveConfiguration config = currentReserve.configuration;
      vars.liquidityInEth = currentReserve.getUserLiquidityETH(
        vars.underlyingAddress,
        params.user,
        params.oracle
      );
      vars.borrowableLiquidityInEth += vars.liquidityInEth;
      if (isCollateral && config.getLiquidationThreshold() != 0) {
        vars.totalCollateralInEth += vars.liquidityInEth;
        vars.totalCollateralWithLtvInEth += vars.liquidityInEth * config.getLtv();
        vars.totalCollateralWithLiqThreshInEth +=
          vars.liquidityInEth *
          config.getLiquidationThreshold();
      }
      if (isBorrowing) {
        vars.totalDebtInEth += currentReserve.getUserDebtETH(
          vars.underlyingAddress,
          params.user,
          params.oracle
        );
      }
    }
    // Calculate for nft reserves
    if (params.userNFTConfig.isUsingAsCollateralAny()) {
      for (i = 1; i < params.nftReserveCount + 1; i++) {
        vars.underlyingAddress = nftReserveList[i];
        if (vars.underlyingAddress == address(0)) {
          continue;
        }
        NFTReserve.ReserveData storage currentReserve = nftReserves[vars.underlyingAddress];
        ReserveConfiguration config = currentReserve.configuration;
        vars.liquidityInEth = currentReserve.getUserLiquidityETH(
          vars.underlyingAddress,
          params.user,
          params.oracle
        );
        vars.nftLiquidityInEth += vars.liquidityInEth;
        vars.totalCollateralInEth += vars.liquidityInEth;
        vars.totalCollateralWithLtvInEth += vars.liquidityInEth * config.getLtv();
        vars.totalCollateralWithLiqThreshInEth +=
          vars.liquidityInEth *
          config.getLiquidationThreshold();
      }
    }

    vars.avgLiqThreshold = (vars.totalCollateralInEth == 0)
      ? 0
      : vars.totalCollateralWithLiqThreshInEth / vars.totalCollateralInEth;

    return
      StateVar({
        borrowableLiq: vars.borrowableLiquidityInEth,
        nftLiq: vars.nftLiquidityInEth,
        totalCollateralInEth: vars.totalCollateralInEth,
        totalDebtInEth: vars.totalDebtInEth,
        ltv: (vars.totalCollateralInEth == 0)
          ? 0
          : vars.totalCollateralWithLtvInEth / vars.totalCollateralInEth,
        liqThreshold: vars.avgLiqThreshold,
        hf: calculateHealthFactor(
          vars.totalCollateralInEth,
          vars.totalDebtInEth,
          vars.avgLiqThreshold
        )
      });
  }

  /**
   * @dev Calculates the health factor of the user
   * @param totalCollateralInETH The total collaterals in ETH
   * @param totalDebtInETH The total debts in ETH
   * @param avgLiqThreshold The avg liquidation threshold
   * @return The health factor
   **/
  function calculateHealthFactor(
    uint256 totalCollateralInETH,
    uint256 totalDebtInETH,
    uint256 avgLiqThreshold
  ) public pure returns (uint256) {
    if (totalDebtInETH == 0) return type(uint256).max;
    return (totalCollateralInETH.percentMul(avgLiqThreshold)).wadDiv(totalDebtInETH);
  }

  /**
   * @dev Calculates the user liquidity in NFT reserves.
   * @param reserves Data of all the normal reserves
   * @param nftReserves Data of all the NFT reserves
   * @param params other params
   * @return state variables
   **/
  function calculateUserAssetValues(
    mapping(address => Reserve.ReserveData) storage reserves,
    mapping(address => NFTReserve.ReserveData) storage nftReserves,
    address asset,
    CalUserStateParam memory params
  ) public view returns (uint256, uint256, uint256) {
    uint256 liquidityInEth;
    uint256 debtInEth;
    uint256 collateralInEth;
    uint256 id = reserves[asset].id;
    if (id != 0) {
      Reserve.ReserveData storage reserve = reserves[asset];
      liquidityInEth = reserve.getUserLiquidityETH(asset, params.user, params.oracle);
      debtInEth = reserve.getUserDebtETH(asset, params.user, params.oracle);
      if (params.userConfig.isUsingAsCollateral(id)) {
        collateralInEth = liquidityInEth;
      }
    } else if (nftReserves[asset].id != 0) {
      NFTReserve.ReserveData storage nftReserve = nftReserves[asset];
      liquidityInEth = collateralInEth = nftReserve.getUserLiquidityETH(
        asset,
        params.user,
        params.oracle
      );
    }
    return (liquidityInEth, debtInEth, collateralInEth);
  }

  /**
   * @dev Calculates the user total collateral across all the reserves.
   * @param reserves Data of all the normal reserves
   * @param nftReserves Data of all the nft reserves
   * @param reserveList The address of the corresponding tToken of all the normal reserves
   * @param nftReserveList The address of the corresponding tToken of all the nft reserves
   * @param params other params
   * @return state variables
   **/
  function calculateUserValues(
    mapping(address => Reserve.ReserveData) storage reserves,
    mapping(address => NFTReserve.ReserveData) storage nftReserves,
    mapping(uint256 => address) storage reserveList,
    mapping(uint256 => address) storage nftReserveList,
    CalUserStateParam memory params
  ) public view returns (uint256) {
    // total liquidity here only refer to collaterals
    address underlyingAddress;
    uint256 totalLiquidityInEth;
    uint256 liquidityInEth;
    uint256 i;
    // Calculate for borrowable reserves
    if (params.userConfig.isUsingAsCollateralAny()) {
      for (i = 1; i < params.reserveCount + 1; i++) {
        bool isCollateral = params.userConfig.isUsingAsCollateral(i);
        if (!isCollateral) {
          continue;
        }
        underlyingAddress = reserveList[i];
        if (underlyingAddress == address(0)) {
          continue;
        }
        Reserve.ReserveData storage currentReserve = reserves[underlyingAddress];
        if (isCollateral) {
          liquidityInEth = currentReserve.getUserLiquidityETH(
            underlyingAddress,
            params.user,
            params.oracle
          );
          totalLiquidityInEth += liquidityInEth;
        }
      }
    }
    // Calculate for nft reserves
    if (params.userNFTConfig.isUsingAsCollateralAny()) {
      for (i = 1; i < params.nftReserveCount + 1; i++) {
        underlyingAddress = nftReserveList[i];
        if (underlyingAddress == address(0)) {
          continue;
        }
        NFTReserve.ReserveData storage currentReserve = nftReserves[underlyingAddress];
        liquidityInEth = currentReserve.getUserLiquidityETH(
          underlyingAddress,
          params.user,
          params.oracle
        );
        totalLiquidityInEth += liquidityInEth;
      }
    }
    return totalLiquidityInEth;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title Errors library
 * @author Taker
 * @notice Error message mapping for Taker protocol
 */
library Errors {
  string public constant ONLY_POOL_ADMIN = "0";
  string public constant ONLY_LENDING_POOL = "1";
  string public constant ONLY_LENDING_POOL_CONFIGURATOR = "2";
  string public constant INVALID_MINT_AMOUNT = "3";
  string public constant INVALID_BURN_AMOUNT = "4";
  string public constant TOKEN_NOT_TRANSFERRABLE = "5";
  string public constant NOT_TTOKEN = "6";
  string public constant INVALID_LTV = "7";
  string public constant INVALID_LIQ_THRESHOLD = "8";
  string public constant INVALID_DECIMALS = "9";
  string public constant INVALID_RESERVE_FACTOR = "10";
  string public constant INVALID_AMOUNT = "11";
  string public constant INACTIVE_RESERVE = "12";
  string public constant FROZEN_RESERVE = "13";
  string public constant PAUSED_RESERVE = "14";
  string public constant RESERVE_ALREADY_INITIALIZED = "15";
  string public constant NONEXIST_RESERVE = "16";
  string public constant ZERO_ADDRESS = "17";
  string public constant NON_ZERO_TTOKEN_SUPPLY = "18";
  string public constant NON_ZERO_DEBT_TOKEN_SUPPLY = "19";
  string public constant ARRAY_LENGTH_NOT_MATCH = "20";
  string public constant ERC_1155_OR_721_MUST_HAVE_TOKEN_ID = "21";
  string public constant USER_BALANCE_NOT_ENOUGH = "22";
  string public constant INVALID_INDEX = "23";
  string public constant HEALTH_FACTOR_UNDER_THRESHOLD = "24";
  string public constant HEALTH_FACTOR_ABOVE_THRESHOLD = "25";
  string public constant COLLATERAL_NOT_ENOUGH_FOR_BORROW = "26";
  string public constant ZERO_COLLATERAL_BALANCE = "27";
  string public constant NO_DEBT_TO_REPAY = "28";
  string public constant NOT_A_CONTRACT = "29";
  string public constant NO_MORE_RESERVES_ALLOWED = "30";
  string public constant NO_MORE_NFT_RESERVES_ALLOWED = "31";
  string public constant ZERO_BALANCE = "32";
  string public constant LIQ_THRESHOLD_LESS_THAN_LTV = "33";
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = "34";
  string public constant LIQUIDATING_COLLATERAL_EXCEED_DEBT_LIMIT = "35";
  string public constant INSUFFICIENT_ETH_BALANCE = "36";
  string public constant INSUFFICIENT_REAPY_ETH_BALANCE = "37";
  string public constant SEND_ETH_FAILED = "38";
  string public constant RECEIVE_NOT_ALLOWED = "39";
  string public constant INVALID_DEPOSIT_CAP = "40";
  string public constant INVALID_BORROW_CAP = "41";
  string public constant DEPOSIT_CAP_EXCEEDED = "42";
  string public constant BORROW_CAP_EXCEEDED = "43";
  string public constant ONLY_OWNER_CAN_BURN = "44";
  string public constant DEBT_ALLOWANCE_OVERREACH = "45";
  string public constant ASSET_NOT_COLLATERIZABLE = "46";
  string public constant INSUFFICIENT_LIQUIDATE_ETH_BALANCE = "47";
  string public constant NOT_PUNK_OWNER = "48";

  /**
   * @dev Helper function to generate error messages
   * @param component The name of the component that produces the error
   * @param errCode The error code define in this library
   * @return The final error message
   **/
  function genErrMsg(
    string memory component,
    string memory errCode
  ) external pure returns (string memory) {
    return string.concat(component, "_", errCode);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {WadRayMath} from "./WadRayMath.sol";

/**
 * @title InterestCalculator library
 * @author Taker, inspired by AAVE MathUtil library
 * @notice Used to calculate linear and compound interests
 */
library InterestCalculator {
  using WadRayMath for uint256;

  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Calculate the normalized asset gain under linear interest
   * @param rate The interest rate, in ray
   * @param duration Duration for interest calculation, in timestamp uint
   * @return The scale factor (asset * scale factor = asset + accured interest)
   **/
  function getNormalizedScaleWithLinearInterest(uint256 rate, uint256 duration)
    internal
    pure
    returns (uint256)
  {
    uint256 result = rate * duration;
    unchecked {
      result = result / SECONDS_PER_YEAR;
    }

    return WadRayMath.RAY + result;
  }

  /**
   * @dev Calculate the normalized asset gain under compound interest
   * Used binomial approximation to reduce gas fee
   * @param rate The interest rate, in ray
   * @param duration Duration for interest calculation, in timestamp uint
   * @return The scale factor (asset * scale factor = asset + accured interest)
   **/
  function getNormalizedScaleWithCompoundInterest(uint256 rate, uint256 duration)
    internal
    pure
    returns (uint256)
  {
    if (duration == 0) {
      return WadRayMath.RAY;
    }

    uint256 expMinusOne;
    uint256 expMinusTwo;
    uint256 basePowerTwo;
    uint256 basePowerThree;
    unchecked {
      expMinusOne = duration - 1;
      expMinusTwo = duration > 2 ? duration - 2 : 0;

      basePowerTwo = rate.rayMul(rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
      basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
    }

    uint256 secondTerm = duration * expMinusOne * basePowerTwo;
    unchecked {
      secondTerm /= 2;
    }
    uint256 thirdTerm = duration * expMinusOne * expMinusTwo * basePowerThree;
    unchecked {
      thirdTerm /= 6;
    }

    return WadRayMath.RAY + (rate * duration) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title PercentageMath library
 * @author Taker, inspired by the AAVE WadRayMath library implementation
 * @notice Provides functions to perform percentage calculations
 * @dev The calculation has 2 decimals of precision (100.00) and is rounded up
 **/

library PercentageMath {
  //percentage with 2 decimals
  uint256 public constant PERCENT = 1e4;
  uint256 public constant HALF_PERCENT = PERCENT / 2;

  /**
   * @dev Returns value after a percentage multiplication
   * @param value Multiplier
   * @param percentage The percentage
   * @return The value multiplied percentage
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    return (value * percentage + HALF_PERCENT) / PERCENT;
  }

  /**
   * @dev Returns value after a percentage division
   * @param value Divisor
   * @param percentage The percentage
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    uint256 halfPercentage = percentage / 2;
    return (value * PERCENT + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

/**
 * @title WadRayMath library
 * @author Taker, inspired by the AAVE WadRayMath library implementation
 * @notice Provides functions to perform calculations with Wad(18 digits precision) and Ray(27 digits of precision) units
 **/
library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b + HALF_WAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    return (a * b + HALF_RAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ITERC721} from "../../interfaces/tokens/ITERC721.sol";
import {ITERC1155} from "../../interfaces/tokens/ITERC1155.sol";

import {IPriceOracleGetter} from "../../interfaces/oracle/IPriceOracleGetter.sol";

import {WadRayMath} from "../math/WadRayMath.sol";
import {ReserveConfiguration, ReserveConfigurator} from "./ReserveConfiguration.sol";
import {Errors} from "../Errors.sol";

import "hardhat/console.sol";

/**
 * @title NFTReserve library
 * @author Taker
 * @notice Defines reserve data and implements the logic to update the reserves state
 */
library NFTReserve {
  using WadRayMath for uint256;

  string public constant NAME = "NR";

  struct ReserveData {
    ReserveConfiguration configuration;
    //address for tNFT
    address tNFTAddress;
    //the id of the nft reserve.
    uint8 id;
  }

  /**
   * @dev Initializes a nft reserve
   * @param reserve The nft reserve object
   * @param configuration The configuration including ltv and threshold
   * @param tNFTAddress The address of corresponding tNFT
   **/
  function init(
    ReserveData storage reserve,
    ReserveConfiguration configuration,
    address tNFTAddress
  ) external {
    require(
      reserve.tNFTAddress == address(0),
      Errors.genErrMsg(NAME, Errors.RESERVE_ALREADY_INITIALIZED)
    );

    reserve.configuration = configuration;
    reserve.tNFTAddress = tNFTAddress;
  }

  /**
   * @dev Returns the users total liquidity in the nft reserve in ETH
   * @param nft The nft reserve object
   * @param underlying The underlying asset address of the reserve
   * @param oracle The address of the price oracle
   * @return amountInEth The total liquidity in ETH
   **/
  function getLiquidityETH(
    ReserveData storage nft,
    address underlying,
    address oracle
  ) internal view returns (uint256) {
    ReserveConfiguration configuration = nft.configuration;
    uint256 amountInEth = IPriceOracleGetter(oracle).getReserveAssetPrice(underlying) *
      IERC20(nft.tNFTAddress).totalSupply();
    unchecked {
      amountInEth /= 10 ** configuration.getDecimals();
    }
    return amountInEth;
  }

  /**
   * @dev Returns the users total liquidity in the nft reserve in ETH
   * @param nft The nft reserve object
   * @param underlying The underlying asset address of the reserve
   * @param user The user address
   * @param oracle The address of the price oracle
   * @return amountInEth The total liquidity in ETH
   **/
  function getUserLiquidityETH(
    ReserveData storage nft,
    address underlying,
    address user,
    address oracle
  ) internal view returns (uint256) {
    ReserveConfiguration configuration = nft.configuration;
    ReserveConfigurator.TokenType tokenType = configuration.getTokenType();
    uint256 amountInEth = IPriceOracleGetter(oracle).getReserveAssetPrice(underlying);
    if (tokenType == ReserveConfigurator.TokenType.ERC1155) {
      amountInEth *= IERC1155(nft.tNFTAddress).balanceOf(user, 0);
    } else {
      amountInEth *= IERC721(nft.tNFTAddress).balanceOf(user);
    }
    unchecked {
      amountInEth /= 10 ** configuration.getDecimals();
    }
    return amountInEth;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPriceOracleGetter} from "../../interfaces/oracle/IPriceOracleGetter.sol";
import {ITToken} from "../../interfaces/tokens/ITToken.sol";
import {IDebtToken} from "../../interfaces/tokens/IDebtToken.sol";
import {IInterestRateCalculator} from "../../interfaces/IInterestRateCalculator.sol";

import {InterestCalculator} from "../math/InterestCalculator.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";

import {ReserveConfiguration} from "./ReserveConfiguration.sol";
import {Errors} from "../Errors.sol";

/**
 * @title Reserve library
 * @author Taker
 * @notice Defines reserve data and implements the logic to update the reserves state
 */
library Reserve {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;

  string public constant NAME = "R";
  struct ReserveData {
    ReserveConfiguration configuration;
    //the liquidity index in ray. Liquidity = corresponding tToken balance * liquidity index
    uint128 liquidityIndex;
    //the debt index in ray. Debt = corresponding debtToken balance * debt index
    uint128 debtIndex;
    //interest rate for liquidity providers in ray
    uint128 depositRate;
    //interest rate for borrow
    uint128 borrowRate;
    //last timestamp when reserve state was updated
    uint40 lastUpdateTimestamp;
    //corresponding tToken address
    address tTokenAddress;
    // corresponding debt token address
    address debtTokenAddress;
    //address of the interest rate calculator
    address interestRateCalculatorAddress;
    //the address of the treasury
    address treasury;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  // See ILendingPool for descriptions
  event ReserveDataUpdated(
    address indexed asset,
    uint256 depositRate,
    uint256 borrowRate,
    uint256 liquidityIndex,
    uint256 borrowIndex
  );

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve
   * @param tTokenAddress The address of the overlying tToken contract
   * @param debtTokenAddress The address of the overlying debtToken contract
   * @param interestRateCalculatorAddress The address of the interest rate calculator contract
   **/
  function init(
    ReserveData storage reserve,
    ReserveConfiguration configuration,
    address tTokenAddress,
    address debtTokenAddress,
    address interestRateCalculatorAddress,
    address treasuryAddress
  ) external {
    require(
      reserve.tTokenAddress == address(0),
      Errors.genErrMsg(NAME, Errors.RESERVE_ALREADY_INITIALIZED)
    );

    reserve.configuration = configuration;
    reserve.liquidityIndex = uint128(WadRayMath.RAY);
    reserve.debtIndex = uint128(WadRayMath.RAY);
    reserve.tTokenAddress = tTokenAddress;
    reserve.debtTokenAddress = debtTokenAddress;
    reserve.interestRateCalculatorAddress = interestRateCalculatorAddress;
    reserve.treasury = treasuryAddress;
  }

  /**
   * @dev Returns the current scale factor of liquidity of the reserve
   *      total liquidity = factor * balance of tToken
   * @param reserve The reserve
   * @return the normalized scale factor of liquidity. expressed in ray
   **/
  function getNormalizedLiquidityScale(
    Reserve.ReserveData storage reserve
  ) internal view returns (uint256) {
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;
    uint256 currTimestamp = block.timestamp;
    //solium-disable-next-line
    if (lastUpdatedTimestamp == uint40(currTimestamp)) {
      // Return the index if the state has been updated
      return reserve.liquidityIndex;
    }
    uint256 incomeScale = InterestCalculator
      .getNormalizedScaleWithLinearInterest(
        reserve.depositRate,
        currTimestamp - lastUpdatedTimestamp
      )
      .rayMul(reserve.liquidityIndex);

    return incomeScale;
  }

  /**
   * @dev Returns the current scale factor of debt of the reserve
   *      total debt = factor * balance of debt token
   * @param reserve The reserve
   * @return the normalized scale factor of debt. expressed in ray
   **/
  function getNormalizedDebtScale(
    Reserve.ReserveData storage reserve
  ) internal view returns (uint256) {
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;
    uint256 currTimestamp = block.timestamp;
    //solium-disable-next-line
    if (lastUpdatedTimestamp == uint40(currTimestamp)) {
      return reserve.debtIndex;
    }

    uint256 cumulated = InterestCalculator
      .getNormalizedScaleWithCompoundInterest(
        reserve.borrowRate,
        currTimestamp - lastUpdatedTimestamp
      )
      .rayMul(reserve.debtIndex);

    return cumulated;
  }

  /**
   * @dev Updates the liquidity index and the borrow index. And mint share to treasury
   * @param reserve the reserve object
   * @return current liquidity index
   **/
  function updateState(ReserveData storage reserve) internal returns (uint256) {
    uint256 scaledDebt = IDebtToken(reserve.debtTokenAddress).compoundedTotalSupply();

    (uint256 currLiqIdx, uint256 prevDebtIdx, uint256 currDebtIdx) = _updateIndexes(
      reserve,
      scaledDebt
    );

    _mintToTreasury(reserve, scaledDebt, prevDebtIdx, currDebtIdx, currLiqIdx);

    return currLiqIdx;
  }

  /**
   * @dev Updates the reserve current borrow rate and the current liquidity rate
   * @param reserve The reserve data
   * @param asset The address of the reserve underlying ERC20
   * @param tTokenAddress The address of the reserve tToken
   **/
  function updateInterestRates(
    ReserveData storage reserve,
    address asset,
    address tTokenAddress
  ) internal {
    uint256 liquidityIndex = reserve.liquidityIndex;
    uint256 debtIndex = reserve.debtIndex;
    uint256 totalDebt = IDebtToken(reserve.debtTokenAddress).totalSupply() * reserve.debtIndex;
    uint256 totalLiquitity = ITToken(tTokenAddress).totalSupply() * reserve.liquidityIndex;

    (uint256 newDepositRate, uint256 newBorrowRate) = IInterestRateCalculator(
      reserve.interestRateCalculatorAddress
    ).calculateInterestRates(totalLiquitity, totalDebt, reserve.configuration.getReserveFactor());
    reserve.depositRate = newDepositRate.toUint128();
    reserve.borrowRate = newBorrowRate.toUint128();

    emit ReserveDataUpdated(asset, newDepositRate, newBorrowRate, liquidityIndex, debtIndex);
  }

  /**
   * @dev Returns the total liquidity in the reserve in ETH
   * @param reserve The reserve object
   * @param underlying The underlying asset address of the reserve
   * @param oracle The address of the price oracle
   * @return amountInEth The total liquidity in ETH
   **/
  function getLiquidityETH(
    ReserveData storage reserve,
    address underlying,
    address oracle
  ) internal view returns (uint256 amountInEth) {
    uint256 price = IPriceOracleGetter(oracle).getReserveAssetPrice(underlying);
    amountInEth = price * ITToken(reserve.tTokenAddress).compoundedTotalSupply();
    unchecked {
      amountInEth /= 10 ** reserve.configuration.getDecimals();
    }
  }

  /**
   * @dev Returns the total debt from the reserve in ETH
   * @param reserve The reserve object
   * @param underlying The underlying asset address of the reserve
   * @param oracle The address of the price oracle
   * @return amountInEth The total debt in ETH
   **/
  function getDebtETH(
    ReserveData storage reserve,
    address underlying,
    address oracle
  ) internal view returns (uint256 amountInEth) {
    uint256 price = IPriceOracleGetter(oracle).getReserveAssetPrice(underlying);
    amountInEth = price * IDebtToken(reserve.debtTokenAddress).compoundedTotalSupply();
    unchecked {
      amountInEth /= 10 ** reserve.configuration.getDecimals();
    }
  }

  /**
   * @dev Returns the users total liquidity in the reserve in ETH
   * @param reserve The reserve object
   * @param underlying The underlying asset address of the reserve
   * @param user The user address
   * @param oracle The address of the price oracle
   * @return amountInEth The total liquidity in ETH
   **/
  function getUserLiquidityETH(
    ReserveData storage reserve,
    address underlying,
    address user,
    address oracle
  ) internal view returns (uint256 amountInEth) {
    uint256 price = IPriceOracleGetter(oracle).getReserveAssetPrice(underlying);
    amountInEth = price * ITToken(reserve.tTokenAddress).compoundedBalanceOf(user);
    unchecked {
      amountInEth /= 10 ** reserve.configuration.getDecimals();
    }
  }

  /**
   * @dev Returns the users total debt from the reserve in ETH
   * @param reserve The reserve object
   * @param underlying The underlying asset address of the reserve
   * @param user The user address
   * @param oracle The address of the price oracle
   * @return amountInEth The total debt in ETH
   **/
  function getUserDebtETH(
    ReserveData storage reserve,
    address underlying,
    address user,
    address oracle
  ) internal view returns (uint256 amountInEth) {
    uint256 price = IPriceOracleGetter(oracle).getReserveAssetPrice(underlying);
    amountInEth = price * IDebtToken(reserve.debtTokenAddress).compoundedBalanceOf(user);
    unchecked {
      amountInEth /= 10 ** reserve.configuration.getDecimals();
    }
  }

  /**
   * @dev Updates the reserve indexes and the timestamp of the update
   * @param reserve The reserve reserve to be updated
   * @param scaledDebt The scaled debt
   **/
  function _updateIndexes(
    ReserveData storage reserve,
    uint256 scaledDebt
  ) internal returns (uint256 currLiqIdx, uint256 prevDebtIdx, uint256 currDebtIdx) {
    prevDebtIdx = currDebtIdx = reserve.debtIndex;
    uint256 prevLiqIdx = currLiqIdx = reserve.liquidityIndex;
    uint40 duration = uint40(block.timestamp - uint256(reserve.lastUpdateTimestamp));

    if (reserve.depositRate > 0) {
      uint256 cumulatedDepInterestScale = InterestCalculator.getNormalizedScaleWithLinearInterest(
        reserve.depositRate,
        duration
      );
      currLiqIdx = prevLiqIdx.rayMul(cumulatedDepInterestScale);
      reserve.liquidityIndex = currLiqIdx.toUint128();

      // we need to ensure that there is actual debt before accumulating
      if (scaledDebt != 0) {
        uint256 cumulatedBorrowInterestScale = InterestCalculator
          .getNormalizedScaleWithCompoundInterest(reserve.borrowRate, duration);
        currDebtIdx = prevDebtIdx.rayMul(cumulatedBorrowInterestScale);
        reserve.debtIndex = uint128(currDebtIdx);
      }
    }

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
  }

  /**
   * @dev Mints interest to the treasury according to the reserveFactor
   * @param reserve The reserve data
   * @param scaledDebt The scaled debt
   * @param prevDebtIdx The debt index before update
   * @param currDebtIdx The debt index after update
   * @param currLiqIdx The new liquidity index
   **/
  function _mintToTreasury(
    ReserveData storage reserve,
    uint256 scaledDebt,
    uint256 prevDebtIdx,
    uint256 currDebtIdx,
    uint256 currLiqIdx
  ) internal {
    uint256 reserveFactor = reserve.configuration.getReserveFactor();
    if (reserveFactor == 0) {
      return;
    }

    uint256 prevDebt = scaledDebt.rayMul(prevDebtIdx);
    uint256 currDebt = scaledDebt.rayMul(currDebtIdx);
    uint256 accruedDebt = currDebt - prevDebt;

    uint256 treasuryIncome = accruedDebt.percentMul(reserveFactor);

    if (treasuryIncome != 0) {
      ITToken(reserve.tTokenAddress).mint(reserve.treasury, treasuryIncome, currLiqIdx);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {Errors} from "../Errors.sol";

/**
 * @notice The configuration is shared for NFT reserve and normal reserve.
 * bit 0-15: LTV
 * bit 16-31: Liq. threshold
 * bit 32-39: Decimals
 * bit 40: Reserve is active
 * bit 41: reserve is frozen
 * bit 42: reserve is paused
 * bit 43: reserved
 * bit 44-59: reserve factor
 * bit 60-61: token type: 0->ERC20 1->ERC721 2->ERC1155 (0 for normal reserves)
 * bit 62-63: reserved
 * bit 64-99: deposit cap
 * bit 100-135: borrow cap
 */
type ReserveConfiguration is uint256;
using ReserveConfigurator for ReserveConfiguration global;

/**
 * @title ReserveConfigurator library
 * @author Taker
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfigurator {
  string internal constant COMPONENT_NAME = "RC";

  uint256 internal constant LTV_MASK =                     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; //prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; //prettier-ignore
  uint256 internal constant DECIMALS_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFF; //prettier-ignore
  uint256 internal constant ACTIVE_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFF; //prettier-ignore
  uint256 internal constant FROZEN_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFF; //prettier-ignore
  uint256 internal constant PAUSE_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFF; //prettier-ignore
  uint256 internal constant COLLATERIZABLE_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFF; //prettier-ignore
  uint256 internal constant TOKEN_TYPE_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFFFFFFFFFFFFF; //prettier-ignore
  uint256 internal constant DEPOSIT_CAP_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFF; //prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFF; //prettier-ignore

  // bit shiftings to get the start poistion for each variable
  uint256 internal constant LIQUIDATION_THRESHOLD_SHIFT = 16;  //16
  uint256 internal constant DECIMALS_SHIFT = 32;               //32
  uint256 internal constant IS_ACTIVE_SHIFT = 40;              //40
  uint256 internal constant IS_FROZEN_SHIFT = 41;              //41
  uint256 internal constant IS_PAUSE_SHIFT = 42;               //42
  uint256 internal constant IS_COLLATERIZABLE_SHIFT = 43;      //43
  uint256 internal constant RESERVE_FACTOR_SHIFT = 44;         //44
  uint256 internal constant TOKEN_TYPE_SHIFT = 60;             //60
  uint256 internal constant DEPOSIT_CAP_SHIFT = 64;            //64
  uint256 internal constant BORROW_CAP_SHIFT = 100;            //100

  uint256 internal constant MAX_LTV = 8000; // 65535
  uint256 internal constant MAX_LIQUIDATION_THRESHOLD = 65535;
  uint256 internal constant MAX_DECIMALS = 255;
  uint256 internal constant MAX_RESERVE_FACTOR = 65535;
  uint256 internal constant MAX_DEPOSIT_CAP = 68719476735;
  uint256 internal constant MAX_BORROW_CAP = 68719476735;

  uint16 internal constant MAX_NUMBER_RESERVES = 128;
  uint16 internal constant MAX_NUMBER_NFT_RESERVES = 256;

  enum TokenType {
    ERC20,
    ERC721,
    ERC1155
  }

  /**
   * @dev Returns configuration after setting new Loan to Value
   * @param configuration The reserve configuration
   * @param ltv The new ltv
   * @return The new configuration
   **/
  function setLtv(
    ReserveConfiguration configuration,
    uint256 ltv
  ) internal pure returns (ReserveConfiguration) {
    require(ltv <= MAX_LTV, Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_LTV));
    return ReserveConfiguration.wrap((ReserveConfiguration.unwrap(configuration) & LTV_MASK) | ltv);
  }

  /**
   * @dev Gets the Loan to Value of the reserve
   * @param configuration The reserve configuration
   * @return The loan to value
   **/
  function getLtv(ReserveConfiguration configuration) internal pure returns (uint256) {
    return ReserveConfiguration.unwrap(configuration) & ~LTV_MASK;
  }

  /**
   * @dev Returns configuration after setting new liquidation threshold
   * @param configuration The reserve configuration
   * @param threshold The new liquidation threshold
   * @return The new configuration
   **/
  function setLiquidationThreshold(
    ReserveConfiguration configuration,
    uint256 threshold
  ) internal pure returns (ReserveConfiguration) {
    require(
      threshold <= MAX_LIQUIDATION_THRESHOLD,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_LIQ_THRESHOLD)
    );
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & LIQUIDATION_THRESHOLD_MASK) |
          (threshold << LIQUIDATION_THRESHOLD_SHIFT)
      );
  }

  /**
   * @dev Gets the liquidation threshold of the reserve
   * @param configuration The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(
    ReserveConfiguration configuration
  ) internal pure returns (uint256) {
    return
      (ReserveConfiguration.unwrap(configuration) & ~LIQUIDATION_THRESHOLD_MASK) >>
      LIQUIDATION_THRESHOLD_SHIFT;
  }

  /**
   * @dev Returns configuration after setting new decimals
   * @param configuration The reserve configuration
   * @param decimals The new decimals
   * @return The new configuration
   **/
  function setDecimals(
    ReserveConfiguration configuration,
    uint256 decimals
  ) internal pure returns (ReserveConfiguration) {
    require(decimals <= MAX_DECIMALS, Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_DECIMALS));
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & DECIMALS_MASK) | (decimals << DECIMALS_SHIFT)
      );
  }

  /**
   * @dev Gets the decimals of the underlying asset of the reserve
   * @param configuration The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(ReserveConfiguration configuration) internal pure returns (uint256) {
    return (ReserveConfiguration.unwrap(configuration) & ~DECIMALS_MASK) >> DECIMALS_SHIFT;
  }

  /**
   * @dev Returns configuration after setting active state
   * @param configuration The reserve configuration
   * @param active The active state
   * @return The new configuration
   **/
  function setActive(
    ReserveConfiguration configuration,
    bool active
  ) internal pure returns (ReserveConfiguration) {
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & ACTIVE_MASK) |
          (uint256(active ? 1 : 0) << IS_ACTIVE_SHIFT)
      );
  }

  /**
   * @dev Gets the active state of the reserve
   * @param configuration The reserve configuration
   * @return The active state
   **/
  function getActive(ReserveConfiguration configuration) internal pure returns (bool) {
    return (ReserveConfiguration.unwrap(configuration) & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Returns configuration after setting frozen state
   * @param configuration The reserve configuration
   * @param frozen The frozen state
   * @return The new configuration
   **/
  function setFrozen(
    ReserveConfiguration configuration,
    bool frozen
  ) internal pure returns (ReserveConfiguration) {
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & FROZEN_MASK) |
          (uint256(frozen ? 1 : 0) << IS_FROZEN_SHIFT)
      );
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param configuration The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(ReserveConfiguration configuration) internal pure returns (bool) {
    return (ReserveConfiguration.unwrap(configuration) & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Returns new configuration after setting pause
   * @param configuration The reserve configuration
   * @param pause The pause state
   * @return The new configuration
   **/
  function setPause(
    ReserveConfiguration configuration,
    bool pause
  ) internal pure returns (ReserveConfiguration) {
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & PAUSE_MASK) |
          (uint256(pause ? 1 : 0) << IS_PAUSE_SHIFT)
      );
  }

  /**
   * @dev Gets the pause state of the reserve
   * @param configuration The reserve configuration
   * @return The pause state
   **/
  function getPause(ReserveConfiguration configuration) internal pure returns (bool) {
    return (ReserveConfiguration.unwrap(configuration) & ~PAUSE_MASK) != 0;
  }

  /**
   * @dev Returns new configuration after setting collaterizable
   * @param configuration The reserve configuration
   * @param collaterizable The collaterizable state
   * @return The new configuration
   **/
  function setCollaterizable(
    ReserveConfiguration configuration,
    bool collaterizable
  ) internal pure returns (ReserveConfiguration) {
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & COLLATERIZABLE_MASK) |
          (uint256(collaterizable ? 1 : 0) << IS_COLLATERIZABLE_SHIFT)
      );
  }

  /**
   * @dev Gets the collaterizable state of the reserve
   * @param configuration The reserve configuration
   * @return The collaterizable state
   **/
  function getCollaterizable(ReserveConfiguration configuration) internal pure returns (bool) {
    return (ReserveConfiguration.unwrap(configuration) & ~COLLATERIZABLE_MASK) != 0;
  }

  /**
   * @dev Returns new configuration after set reserve factor
   * @param configuration The reserve configuration
   * @param reserveFactor The reserve factor
   * @return The new configuration
   **/
  function setReserveFactor(
    ReserveConfiguration configuration,
    uint256 reserveFactor
  ) internal pure returns (ReserveConfiguration) {
    require(
      reserveFactor <= MAX_RESERVE_FACTOR,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_RESERVE_FACTOR)
    );

    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & RESERVE_FACTOR_MASK) |
          (reserveFactor << RESERVE_FACTOR_SHIFT)
      );
  }

  /**
   * @dev Gets the reserve factor of the reserve
   * @param configuration The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(ReserveConfiguration configuration) internal pure returns (uint256) {
    return
      (ReserveConfiguration.unwrap(configuration) & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_SHIFT;
  }

  /**
   * @dev Returns new configuration after set token type
   * @param configuration The reserve configuration
   * @param tokenType The type of the token
   * @return The new configuration
   **/
  function setTokenType(
    ReserveConfiguration configuration,
    TokenType tokenType
  ) internal pure returns (ReserveConfiguration) {
    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & TOKEN_TYPE_MASK) |
          (uint256(tokenType) << TOKEN_TYPE_SHIFT)
      );
  }

  /**
   * @dev Gets the token type of the reserve
   * @param configuration The reserve configuration
   * @return The token type
   **/
  function getTokenType(ReserveConfiguration configuration) internal pure returns (TokenType) {
    return
      TokenType(
        (ReserveConfiguration.unwrap(configuration) & ~TOKEN_TYPE_MASK) >> TOKEN_TYPE_SHIFT
      );
  }

  /**
   * @notice Returns new configuration after set the deposit cap
   * @param configuration The reserve configuration
   * @param depositCap The deposit cap
   **/
  function setDepositCap(
    ReserveConfiguration configuration,
    uint256 depositCap
  ) internal pure returns (ReserveConfiguration) {
    require(depositCap <= MAX_DEPOSIT_CAP, Errors.INVALID_DEPOSIT_CAP);

    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & DEPOSIT_CAP_MASK) |
          (depositCap << DEPOSIT_CAP_SHIFT)
      );
  }

  /**
   * @notice Gets the deposit cap of the reserve
   * @param configuration The reserve configuration
   * @return The deposit cap
   **/
  function getDepositCap(ReserveConfiguration configuration) internal pure returns (uint256) {
    return (ReserveConfiguration.unwrap(configuration) & ~DEPOSIT_CAP_MASK) >> DEPOSIT_CAP_SHIFT;
  }

  /**
   * @notice Returns new configuration after set the borrow cap
   * @param configuration The reserve configuration
   * @param borrowCap The borrow cap
   **/
  function setBorrowCap(
    ReserveConfiguration configuration,
    uint256 borrowCap
  ) internal pure returns (ReserveConfiguration) {
    require(borrowCap <= MAX_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    return
      ReserveConfiguration.wrap(
        (ReserveConfiguration.unwrap(configuration) & BORROW_CAP_MASK) |
          (borrowCap << BORROW_CAP_SHIFT)
      );
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param configuration The reserve configuration
   * @return The borrow cap
   **/
  function getBorrowCap(ReserveConfiguration configuration) internal pure returns (uint256) {
    return (ReserveConfiguration.unwrap(configuration) & ~BORROW_CAP_MASK) >> BORROW_CAP_SHIFT;
  }

  /**
   * @dev Gets the configuration flags of the reserve
   * @param configuration The reserve configuration
   * @return The state flags of active, frozen and pause
   **/
  function getFlags(ReserveConfiguration configuration) internal pure returns (bool, bool, bool) {
    uint256 conf = ReserveConfiguration.unwrap(configuration);

    return ((conf & ~ACTIVE_MASK) != 0, (conf & ~FROZEN_MASK) != 0, (conf & ~PAUSE_MASK) != 0);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {Errors} from "../Errors.sol";
import {ReserveConfigurator} from "../../libraries/types/ReserveConfiguration.sol";

/**
 * @notice This configuration is only for borrowable assets. Non-borrowable assets(NFTs) are always collaterals
 * bit 0, 2, 4, ..., 254: If the reserve is being borrowed
 * bit 1, 3, 5, ..., 255: If the reserve is used as collateral
 */
type UserConfiguration is uint256;
using UserConfigurator for UserConfiguration global;

/**
 * @title UserConfigurator library
 * @author Taker
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfigurator {
  string internal constant COMPONENT_NAME = "UC";

  uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;
  uint256 internal constant COLLATERAL_MASK =
    0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

  /**
   * @dev Sets borrowing status the reserve identified by reserveIndex
   * @param configuration The configuration
   * @param reserveIdx The index of the reserve in the bitmap
   * @param borrowing True if the user is borrowing from the reserve, false otherwise
   * @return New configuration after set borrowing
   **/
  function setBorrowing(
    UserConfiguration configuration,
    uint256 reserveIdx,
    bool borrowing
  ) internal pure returns (UserConfiguration) {
    require(
      0 < reserveIdx && reserveIdx < ReserveConfigurator.MAX_NUMBER_RESERVES,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_INDEX)
    );
    uint256 position = reserveIdx * 2 - 1;
    uint256 bitMask = 1 << (position - 1);
    if (borrowing) {
      return UserConfiguration.wrap(UserConfiguration.unwrap(configuration) | bitMask);
    } else {
      return UserConfiguration.wrap(UserConfiguration.unwrap(configuration) & ~bitMask);
    }
  }

  /**
   * @dev Returns if user is borrowing from the reserve
   * @param configuration The user configuration
   * @param reserveIdx The index of the reserve in the bitmap
   * @return True if the user is using the reserve to borrow, false otherwise
   **/
  function isBorrowing(
    UserConfiguration configuration,
    uint256 reserveIdx
  ) internal pure returns (bool) {
    require(
      0 < reserveIdx && reserveIdx < ReserveConfigurator.MAX_NUMBER_RESERVES,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_INDEX)
    );
    uint256 position = reserveIdx * 2 - 1;
    return (UserConfiguration.unwrap(configuration) >> (position - 1)) & 1 == 1;
  }

  /**
   * @dev Returns if user is borrowing asset from any reserve
   * @param configuration The user configuration
   * @return True if the user has borrowing from any reserve, false otherwise
   **/
  function isBorrowingAny(UserConfiguration configuration) internal pure returns (bool) {
    return UserConfiguration.unwrap(configuration) & BORROWING_MASK != 0;
  }

  /**
   * @dev Sets if the user is using the reserve as collateral
   * @param configuration The configuration
   * @param reserveIdx The index of the reserve in the bitmap
   * @param usingAsCollateral True to set using as collateral, false otherwise
   * @return New configuration after set using as collateral
   **/
  function setUsingAsCollateral(
    UserConfiguration configuration,
    uint256 reserveIdx,
    bool usingAsCollateral
  ) internal pure returns (UserConfiguration) {
    require(
      0 < reserveIdx && reserveIdx < ReserveConfigurator.MAX_NUMBER_RESERVES,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_INDEX)
    );
    uint256 position = reserveIdx * 2 - 1;
    uint256 bitMask = 1 << position;
    if (usingAsCollateral) {
      return UserConfiguration.wrap(UserConfiguration.unwrap(configuration) | bitMask);
    } else {
      return UserConfiguration.wrap(UserConfiguration.unwrap(configuration) & ~bitMask);
    }
  }

  /**
   * @dev Returns if user is using the reserve as collateral
   * @param configuration The user configuration
   * @param reserveIdx The index of the reserve in the bitmap
   * @return True if the user is using reserve as collateral, false otherwise
   **/
  function isUsingAsCollateral(
    UserConfiguration configuration,
    uint256 reserveIdx
  ) internal pure returns (bool) {
    require(
      0 < reserveIdx && reserveIdx < ReserveConfigurator.MAX_NUMBER_RESERVES,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_INDEX)
    );
    uint256 position = reserveIdx * 2 - 1;
    return (UserConfiguration.unwrap(configuration) >> position) & 1 == 1;
  }

  /**
   * @dev Returns if user has asset as collateral
   * @param configuration The user configuration
   * @return True if the user has borrowing from any reserve, false otherwise
   **/
  function isUsingAsCollateralAny(UserConfiguration configuration) internal pure returns (bool) {
    return UserConfiguration.unwrap(configuration) & COLLATERAL_MASK != 0;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import {Errors} from "../Errors.sol";
import {ReserveConfigurator} from "../../libraries/types/ReserveConfiguration.sol";

/**
 * @notice This configuration is only for Non-borrowable assets(NFTs), which are always collaterals
 */
type UserNftConfiguration is uint256;
using UserNftConfigurator for UserNftConfiguration global;

/**
 * @title UserConfigurator library
 * @author Taker
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserNftConfigurator {
  string internal constant COMPONENT_NAME = "UNC";

  uint256 internal constant COLLATERAL_MASK =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * @dev Sets if the user is depositing in this Nft reserve
   * @param configuration The configuration
   * @param reserveIdx The index of the reserve in the bitmap
   * @param usingAsCollateral True to set using as collateral, false otherwise
   * @return New Nft configuration after set using as collateral
   **/
  function setUsingAsCollateral(
    UserNftConfiguration configuration,
    uint256 reserveIdx,
    bool usingAsCollateral
  ) internal pure returns (UserNftConfiguration) {
    require(
      0 < reserveIdx && reserveIdx < ReserveConfigurator.MAX_NUMBER_NFT_RESERVES,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_INDEX)
    );
    uint256 position = reserveIdx - 1;
    uint256 bitMask = 1 << position;
    if (usingAsCollateral) {
      return UserNftConfiguration.wrap(UserNftConfiguration.unwrap(configuration) | bitMask);
    } else {
      return UserNftConfiguration.wrap(UserNftConfiguration.unwrap(configuration) & ~bitMask);
    }
  }

  /**
   * @dev Returns if user is using the reserve as collateral
   * @param configuration The user configuration
   * @param reserveIdx The index of the reserve in the bitmap
   * @return True if the user is using reserve as collateral, false otherwise
   **/
  function isUsingAsCollateral(
    UserNftConfiguration configuration,
    uint256 reserveIdx
  ) internal pure returns (bool) {
    require(
      0 < reserveIdx && reserveIdx < ReserveConfigurator.MAX_NUMBER_NFT_RESERVES,
      Errors.genErrMsg(COMPONENT_NAME, Errors.INVALID_INDEX)
    );
    uint256 position = reserveIdx - 1;
    return (UserNftConfiguration.unwrap(configuration) >> position) & 1 == 1;
  }

  /**
   * @dev Returns if user has asset as collateral
   * @param configuration The user configuration
   * @return True if the user has borrowing from any reserve, false otherwise
   **/
  function isUsingAsCollateralAny(UserNftConfiguration configuration) internal pure returns (bool) {
    return UserNftConfiguration.unwrap(configuration) & COLLATERAL_MASK != 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.14;

import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {IScaledERC20} from "../../interfaces/tokens/IScaledERC20.sol";
import {IIncentivesController} from "../../interfaces/IIncentivesController.sol";
import {Errors} from "../../libraries/Errors.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title ScaledERC20
 * @author Taker, inspired by the AAVE ScaledBalanceToken implementation
 * @notice Implementation of scaled ERC20 with incentives
 **/
abstract contract ScaledERC20 is ERC20Upgradeable, IScaledERC20 {
  using WadRayMath for uint256;

  /* solhint-disable */
  ILendingPool internal LENDING_POOL;
  IIncentivesController internal INCENTIVES_CONTROLLER;
  address internal UNDERLYING_ASSET;
  /* solhint-enable */

  /**
   * @dev Only pool can call functions marked by this modifier.
   **/
  modifier onlyLendingPool() {
    require(_msgSender() == address(LENDING_POOL), Errors.ONLY_LENDING_POOL);
    _;
  }

  /**
   * @notice Returns a reference for the incentives controller contract
   * @return The incentive controller contract
   **/
  function getIncentivesController() external view virtual returns (IIncentivesController) {
    return INCENTIVES_CONTROLLER;
  }

  /// @inheritdoc IScaledERC20
  function mint(
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) external virtual override returns (bool) {
    return _mintWithScaling(to, amount, scaleFactor);
  }

  /// @inheritdoc IScaledERC20
  function burn(
    address from,
    uint256 amount,
    uint256 scaleFactor
  ) external virtual override {
    _burnWithScaling(from, amount, scaleFactor);
  }

  /**
   * @notice Mint token with a scale factor
   * @param to The address receives the minted tokens
   * @param amount The amount of tokens getting minted
   * @param scaleFactor The factor of the corresponding reserve
   **/
  function _mintWithScaling(
    address to,
    uint256 amount,
    uint256 scaleFactor
  ) internal returns (bool) {
    uint256 balance = balanceOf(to);
    uint256 scaledTokenAmount = amount.rayDiv(scaleFactor);

    super._mint(to, scaledTokenAmount);
    return (balance == 0);
  }

  /**
   * @notice Burns Ttoken
   * @param from The address from which the debt token will be burned
   * @param amount The amount to burn
   * @param scaleFactor The factor of the corresponding reserve
   **/
  function _burnWithScaling(
    address from,
    uint256 amount,
    uint256 scaleFactor
  ) internal {
    uint256 scaledTokenAmount = amount.rayDiv(scaleFactor);
    require(scaledTokenAmount != 0, Errors.genErrMsg(name(), Errors.INVALID_BURN_AMOUNT));

    super._burn(from, scaledTokenAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}