// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ICurvePool {
    function balances(uint256 i) external returns (uint256);

    function A() external returns (uint256);

    function gamma() external returns (uint256);

    function D() external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IPrincipalToken is IERC20Upgradeable, IERC4626Upgradeable {
    /**
     * @notice Returns the amount of shares that the Vault would exchange for the amount of assets provided
     * @param assets the amount of assets to convert
     * @param _ptRate the rate to convert at
     * @return shares the resulting amount of shares
     */
    function convertToSharesWithRate(
        uint256 assets,
        uint256 _ptRate
    ) external view returns (uint256 shares);

    /**
     * @notice Returns the amount of assets that the Vault would exchange for the amount of shares provided
     * @param shares the amount of shares to convert
     * @param _ptRate the rate to convert at
     * @return assets the resulting amount of assets
     */
    function convertToAssetsWithRate(
        uint256 shares,
        uint256 _ptRate
    ) external view returns (uint256 assets);

    /**
     * @notice Returns the equivalent amount of IBT tokens to an amount of assets
     * @param assets the amount of assets to convert
     * @param _ibtRate the rate to convert at
     * @return the corresponding amount of ibts
     */
    function convertAssetsToIBTWithRate(
        uint256 assets,
        uint256 _ibtRate
    ) external view returns (uint256);

    /**
     * @notice Returns the equivalent amount of Assets to an amount of IBT tokens
     * @param ibtAmount the amount of ibt tokens to convert
     * @param _ibtRate the rate to convert at
     * @return the corresponding amount of assets
     */
    function convertIBTToAssetsWithRate(
        uint256 ibtAmount,
        uint256 _ibtRate
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of underlying assets that the Vault would exchange for the amount of principal tokens provided
     *      Equivalent function to convertToAssets
     * @param principalAmount amount of principal to convert
     */
    function convertToUnderlying(
        uint256 principalAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of Principal tokens that the Vault would exchange for the amount of underlying assets
     *      Equivalent function to convertToShares
     * @param underlyingAmount amount of underlying to convert
     */
    function convertToPrincipal(
        uint256 underlyingAmount
    ) external view returns (uint256);

    /**
     * @dev Return the address of the underlying token used by the Principal
     * Token for accounting, and redeeming
     */
    function underlying() external view returns (address);

    /**
     * @dev Return the unix timestamp (uint256) at or after which Principal
     * Tokens can be redeemed for their underlying deposit
     */
    function maturity() external view returns (uint256);

    /**
     * @dev Allows the owner to redeem his PT and claim his yield after expiry
     * and send it to the receiver
     *
     * @param receiver the address to which the yield and pt redeem will be sent
     * @param owner the owner of the PT
     * @return the amount of underlying withdrawn
     */
    function withdrawAfterExpiry(
        address receiver,
        address owner
    ) external returns (uint256);

    /**
     * @dev Stores PT and IBT rates at expiry. Ideally, this function should be called
     * the day of expiry
     * @return the IBT and PT rates at expiry
     */
    function storeRatesAtExpiry() external returns (uint256, uint256);

    /**
     * @dev Returns the IBT rate at expiry
     */
    function getIBTRateAtExpiry() external view returns (uint256);

    /**
     * @dev Returns the PT rate at expiry
     */
    function getPTRateAtExpiry() external view returns (uint256);

    /**
     * @notice Claims pending tokens for both sender and receiver and sets
       correct ibt balances
     * @param _from the sender of yt tokens
     * @param _to the receiver of yt tokens
     */
    function beforeYtTransfer(address _from, address _to) external;

    /**
     * @notice Calculates and transfers the yield generated in form of ibt
     * @return returns the yield that is tranferred or will be transferred
     */
    function claimYield() external returns (uint256);

    /**
     * @notice Toggle Pause
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function pause() external;

    /**
     * @notice Toggle UnPause
     * @dev should only be called in extraordinary situations by the admin of the contract
     */
    function unPause() external;

    /**
     * @notice Setter for the fee collector address
     * @param _feeCollector the address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external;

    /**
     * @notice Setter for the new maxProtocolFee
     * @param newMaxFee the new MaxFee to update
     */
    function setMaxProtocolFee(uint256 newMaxFee) external;

    /**
     * @notice Getter for the fee collector address
     * @return the address of the fee collector
     */
    function getFeeCollectorAddress() external view returns (address);

    /**
     * @notice get the address of zap depositor
     */
    function getZapDepositorAddress() external view returns (address);

    /**
     * @notice get the address of registry.
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Updates the yield till now for the _user address
     * @param _user the user whose yield will be updated
     * @return the yield of the user
     */
    function updateYield(address _user) external returns (uint256);

    /** @dev Deposits amount of assets into the pt contract and mints atleast minShares to user.
     * @param assets the amount of assets being deposited
     * @param receiver the receiver of the shares
     * @param minShares The minimum expected shares from this deposit
     * @return shares the amount of shares minted to the receiver
     */
    function deposit(
        uint256 assets,
        address receiver,
        uint256 minShares
    ) external returns (uint256);

    /** @dev Deposits amount of ibt into the pt contract and mints expected shares to users
     * @param ibtAmount the amount of ibt being deposited
     * @param receiver the receiver of the shares
     * @return shares the amount of shares minted to the receiver
     */
    function depositWithIBT(
        uint256 ibtAmount,
        address receiver
    ) external returns (uint256 shares);

    /** @dev Deposits amount of ibt into the pt contract and mints at least minShares to users
     * @param ibtAmount the amount of ibt being deposited
     * @param receiver the receiver of the shares
     * @param minShares The minimum expected shares from this deposit
     * @return shares the amount of shares minted to the receiver
     */
    function depositWithIBT(
        uint256 ibtAmount,
        address receiver,
        uint256 minShares
    ) external returns (uint256);

    /** @dev Takes assets(Maximum maxAssets) and mints exactly shares to user
     * @param shares the amount of shares to be minted
     * @param receiver the receiver of the shares
     * @param maxAssets The maximum assets that can be taken from the user
     * @return assets The actual amount of assets taken by pt contract for minting the shares.
     */
    function mint(
        uint256 shares,
        address receiver,
        uint256 maxAssets
    ) external returns (uint256);

    /** @dev Burns the exact shares of users and return the assets to user
     * @param shares the amount of shares to be burnt
     * @param receiver the receiver of the assets
     * @param owner the owner of the shares
     * @param minAssets The minimum assets that should be returned to user
     * @return assets The actual amount of assets returned by pt contract for burning the shares.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssets
    ) external returns (uint256);

    /** @dev Burns the shares of users and return the exact assets to user
     * @param assets the amount of exact assets to be returned
     * @param receiver the receiver of the assets
     * @param owner the owner of the shares
     * @param maxShares The maximum shares that can be burnt by the pt contract
     * @return shares The actual amount of shares burnt by pt contract for returning the assets.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxShares
    ) external returns (uint256);

    /** @dev Converts the amount of ibt to its equivalent value in assets
     * @param ibtAmount The amount of ibt to convert to assets
     */
    function convertToAssetsOfIBT(
        uint256 ibtAmount
    ) external view returns (uint256);

    /** @dev Converts the amount of assets tokens to its equivalent value in ibt
     * @param assets The amount of assets to convert to ibt
     */
    function convertToSharesOfIBT(
        uint256 assets
    ) external view returns (uint256);

    /** @dev Returns the ibt address of the pt contract
     * @return ibt the address of the ibt token
     */
    function getIBT() external returns (address ibt);

    /** @dev Returns the ibtRate at the time of calling */
    function getIBTRate() external view returns (uint256);

    /** @dev Returns the ptRate at the time of calling */
    function getPTRate() external view returns (uint256);

    /** @dev Returns value equal to 1 unit of ibt */
    function getIBTUnit() external view returns (uint256);

    /** @dev Returns value equal to 1 unit of asset */
    function getAssetUnit() external view returns (uint256);

    /** @dev Returns max fee that can be set for the pt contract */
    function getMaxProtocolFee() external view returns (uint256);

    /** @dev Returns the yt address of the pt contract
     * @return yt the address of the yt token
     */
    function getYT() external returns (address yt);

    /** @dev Returns the registry address set in the pt contract */
    function getRegistry() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "../util/lib/StructUtil.sol";

interface IPrincipalTokenFactory {
    /**
     * @notice Deploys the PrincipalToken contract implementation.
     * @param name_ Name of the PrincipalToken.
     * @param symbol_ Symbol of the PrincipalToken.
     * @param ibt_ Address of the ibt of the PrincipalToken.
     * @param maturity_ The maturity time of the PrincipalToken.
     * @param max_fees_ Maximum fees of the PrincipalToken.
     * @param registry_ Address of the Registry contract of the PrincipalToken.
     * @return principalToken The address of the principalToken deployed.
     * @return curvePoolAddress The address of the curve Pool deployed for ibt/pt.
     */
    function deployPrincipalToken(
        string memory name_,
        string memory symbol_,
        address ibt_,
        uint256 maturity_,
        uint256 max_fees_,
        address registry_,
        address principalTokenAdmin_
    ) external returns (address principalToken, address curvePoolAddress);

    /**
    * @notice Function which sets the curveAddressProvider address used in
      getting the curve factory address. Can only be called by owner.
    * @param curveAddressProvider The address of the curveAddressProvider.
     */
    function setCurveAddressProvider(address curveAddressProvider) external;

    /**
     * @notice Setter for the registry address, Can only be called by the owner.
     * @param _newRegistry the address of the token factory
     */
    function setRegistry(address _newRegistry) external;

    /**
     * @notice Getter for the curve factory address
     * @return the address of the curve factory
     */
    function getCurveFactoryAddress() external view returns (address);

    /**
     * @notice Getter for the pool registered with this future.
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Getter for the pool registered with this principalToken.
     * @param _principalToken the address of the principalToken.
     */
    function getPool(
        address _principalToken,
        uint256 poolIndex
    ) external view returns (StructUtil.PoolData calldata pool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface IRegistry {
    /**
     * @notice Setter for the tokens factory addres
     * @param _newPrincipalTokenFactory the address of the token factory
     */
    function setPrincipalTokenFactory(
        address _newPrincipalTokenFactory
    ) external;

    /**
     * @notice Getter for the token factory address
     * @return the token factory address
     */
    function getPrincipalTokenFactoryAddress() external view returns (address);

    /* Futures
     *****************************************************************************************************************/

    /**
     * @notice Add a principalToken to the registry
     * @param _principalToken the address of the principalToken to add to the registry
     */
    function addPrincipalToken(address _principalToken) external;

    /**
     * @notice Remove a principalToken from the registry
     * @param _principalToken the address of the principalToken to remove from the registry
     */
    function removePrincipalToken(address _principalToken) external;

    /**
     * @notice set zap depositor
     * @param _zap address of zap depositor
     */
    function setZapDepositor(address _zap) external;

    /**
     * @notice Getter to check if a principalToken is registered
     * @param _principalToken the address of the principalToken to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredPrincipalToken(
        address _principalToken
    ) external view returns (bool);

    /**
     * @notice Getter for the principalToken registered at an index
     * @param _index the index of the principalToken to return
     * @return the address of the corresponding principalToken
     */
    function getPrincipalTokenAt(
        uint256 _index
    ) external view returns (address);

    /**
     * @notice Getter for number of principalToken registered
     * @return the number of principalToken registered
     */
    function principalTokenCount() external view returns (uint256);

    /**
     * @notice get the address of zap depositor
     */
    function getZapDepositor() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "openzeppelin-contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface ISpectraZap {
    /**
     * @notice Zap:
     * - deposits a defined asset amount in the depositor
     * - calculates the amount of ibt and pt to be deposited in curve's ibt/pt pool for max lp tokens with the help of _calcIbtToDepositInCurvePool
     * - deposits into curve pool
     * @param _principalToken the _principalToken to interact with
     * @param poolIndex the index of pool to fetch from factory
     * @param _amount the amount of underlying to deposit
     * @param underlying The address of the asset(underlying token).
     * @param minLpAmount The minimum expected lp token amount after deposit.
     * @param receiver The receiver of the lp tokens after deposit.
     * @return lpAmount the amount of LP after adding liquidity to pool
     */
    function zapInToCurvePoolWithAsset(
        address _principalToken,
        uint256 poolIndex,
        uint256 _amount,
        IERC20Upgradeable underlying,
        uint256 minLpAmount,
        address receiver
    ) external returns (uint256 lpAmount);

    /**
     * @notice Zap:
     * - deposits a defined ibt amount in the depositor which gets deposited in principalToken for pt.
     * - calculates the amount of ibt and pt to be deposited in curve's ibt/pt pool for max lp tokens with the help of _calcIbtToDepositInCurvePool
     * - deposits into curve pool
     * @param _principalToken the _principalToken to interact with
     * @param _amount the amount of ibt to deposit
     * @param minLpAmount The minimum expected lp token amount after deposit.
     * @param receiver The receiver of the lp tokens after deposit.
     * @return lpAmount the amount of LP after adding liquidity to pool
     */
    function zapInToCurvePoolWithIBT(
        address _principalToken,
        uint256 poolIndex,
        uint256 _amount,
        uint256 minLpAmount,
        address receiver
    ) external returns (uint256 lpAmount);

    /**
     * @notice Getter for the registry address
     * @return the address of the APW registry
     */
    function getRegistryAddress() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "../../interfaces/ICurvePool.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/IPrincipalToken.sol";
import "openzeppelin-erc20-extensions/IERC20MetadataUpgradeable.sol";

error CurvePoolUtilError(string reason);

library CurvePoolUtil {
    uint256 private constant A_MULTIPLIER = 10000;
    struct StrategyVars {
        uint256 poolBalanceRatio;
        uint256 A;
        uint256 gamma;
        uint256 D;
        uint256 exchangeRate;
        uint256 D1;
        uint256 ibtStrategy1;
        uint256 D2;
        uint256 ibtStrategy2;
    }
    struct Args {
        uint256 ANN;
        uint256 gamma;
        uint256 _ibt;
        uint256 _pt;
    }

    /**
     * @notice Function for calculating the amount of ibt to deposit in the curve pool
     * @param _amount total amount of ibt available for deposit.
     * @param _curvePool the address of the pool to deposit the amounts.
     * @param _pt the address of the pt token.
     * @return the amount of the ibt which will be deposited in the curve pool
     */
    function _calcIbtToDepositInCurvePool(
        uint256 _amount,
        address _curvePool,
        address _pt
    ) internal returns (uint256) {
        StrategyVars memory sv;
        (uint256 ibtBalance, uint256 ptBalance) = _calcCurrentBalances(
            _curvePool
        );
        sv.poolBalanceRatio = ibtBalance / ptBalance;
        /*Depositing with ratios identical (or very close) to the pool's,
         will give you a reasonable amount of LP tokens without swap fees.
         Depositing with more of the scarcer coin should give you more tokens, but you also get charged fees.*/
        (sv.A, sv.gamma, sv.D) = _getPoolInfo(_curvePool);

        /*strategy 1 :
        Providing ibt/pt in identical ratio to pool's ratio*/
        uint256 IBT_UNIT = 10 **
            IERC20MetadataUpgradeable(IPrincipalToken(_pt).getIBT()).decimals();
        sv.exchangeRate = _getExchangeRate(_pt);
        /*
        (ibt - x) / (x* exchangeRate) = poolBalanceRatio
        solving for ibt below
        TODO : check for scaling to handle ratios
        */
        sv.ibtStrategy1 =
            _amount -
            (1 / ((sv.exchangeRate * sv.poolBalanceRatio) / IBT_UNIT + 1)) *
            _amount;
        uint256 newIbtBalance = ibtBalance + sv.ibtStrategy1;
        uint256 newPtBalance = ptBalance + (_amount - sv.ibtStrategy1);
        Args memory args;
        args.ANN = sv.A;
        args.gamma = sv.gamma;
        args._ibt = newIbtBalance;
        args._pt = newPtBalance;
        sv.D1 = _newtonD(args); // D invariant calculation with added balances
        /*Strategy 2 :
        Providing scarce token completely to get more LP token , but swap fee will be charged , we have to account for this
        */
        if (ptBalance > ibtBalance) {
            newIbtBalance = ibtBalance + _amount;
            sv.ibtStrategy2 = _amount;
            args._ibt = newIbtBalance;
            args._pt = ptBalance;
            sv.D2 = _newtonD(args);
        } else {
            newPtBalance = ptBalance + (sv.exchangeRate * _amount) / IBT_UNIT;
            sv.ibtStrategy2 = 0;
            args._ibt = ibtBalance;
            args._pt = newPtBalance;
            sv.D2 = _newtonD(args);
        }
        if(!(sv.D1 > sv.D || sv.D2 > sv.D)) {
            revert CurvePoolUtilError("Deposit strategies failed");
        }
        if (sv.D2 > sv.D1) {
            return sv.ibtStrategy2;
        }
        return sv.ibtStrategy1;
    }

    /**
     * @notice Getter for some properties of the deployed curve pool.
     * @param _curvePool the address of the pool you want to know properties of.
     * @return A The property A of the pool.
     * @return gamma The property gamma of the pool.
     * @return D The properties D(current invariant) of the pool.
     */
    function _getPoolInfo(
        address _curvePool
    ) internal returns (uint256 A, uint256 gamma, uint256 D) {
        A = ICurvePool(_curvePool).A();
        gamma = ICurvePool(_curvePool).gamma();
        D = ICurvePool(_curvePool).D();
    }

    /**
     * @notice Function for calculating the D invariant calculation.
     * @param args A struct of type Args having the required values for the D calculation.
     * @return The D invariant after calculation and reverts if solution is not converging.
     */
    function _newtonD(Args memory args) internal pure returns (uint256) {
        /**
        D invariant calculation in non-overflowing integer operations
        iteratively
        A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
        Converging solution:
        D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
        **/

        uint256[2] memory x;
        if (args._ibt < args._pt) {
            x[0] = args._pt;
            x[1] = args._ibt;
        } else {
            x[0] = args._ibt;
            x[1] = args._pt;
        }
        //safety checks for x[0] && x[1]
        if(!(x[0] > 1e9 - 1 && x[0] < 1e15 * 1e18 + 1)) {
            revert CurvePoolUtilError("Unsafe value for x[0]");
        }
        if(!((x[1] * 1e18) / x[0] > 1e14 - 1)) {
            revert CurvePoolUtilError("Unsafe value for x[1]");
        }
        //Initial value of invariant D is that for constant-product invariant
        uint256 D = 2 * _geometricMean(x);
        uint256 S = x[0] + x[1];

        for (uint256 i = 0; i < 255; i++) {
            uint256 D_prev = D;
            /**
            K0 = 1e18
            for each _x in x:
                K0 = K0*_x*N_COINS/2
            **/
            uint256 K0 = ((((1e18 * 4) * x[0]) / D) * x[1]) / D;
            uint256 _g1k0 = args.gamma + 1e18;
            if (_g1k0 > K0) {
                _g1k0 = _g1k0 - K0 + 1;
            } else {
                _g1k0 = K0 - _g1k0 + 1;
            }
            // D / (A * N**N) * _g1k0**2 / gamma**2
            uint256 mul1 = (((((1e18 * D) / args.gamma) * _g1k0) / args.gamma) *
                _g1k0 *
                A_MULTIPLIER) / args.ANN;

            // 2*N*K0 / _g1k0
            uint256 mul2 = ((2 * 1e18) * 2 * K0) / _g1k0;

            uint256 negFPrime = (S + (S * mul2) / 1e18) +
                (mul1 * 2) /
                K0 -
                (mul2 * D) /
                1e18;

            //D -= f / FPrime
            uint256 D_plus = (D * (negFPrime + S)) / negFPrime;
            uint256 D_minus = (D * D) / negFPrime;
            if (1e18 > K0) {
                D_minus =
                    D_minus +
                    (((D * (mul1 / negFPrime)) / 1e18) * (1e18 - K0)) /
                    K0;
            } else {
                D_minus =
                    D_minus -
                    (((D * (mul1 / negFPrime)) / 1e18) * (K0 - 1e18)) /
                    K0;
            }

            if (D_plus > D_minus) {
                D = D_plus - D_minus;
            } else {
                D = (D_minus - D_plus) / 2;
            }

            uint256 diff = 0;
            if (D > D_prev) {
                diff = D - D_prev;
            } else {
                diff = D_prev - D;
            }

            if (diff * 10 ** 14 < max(10 ** 16, D)) {
                for (i = 0; i < 2; i++) {
                    uint256 frac = (x[i] * 1e18) / D;
                    if(!((frac > 1e16 - 1) && (frac < 1e20 + 1))) {
                        revert CurvePoolUtilError("Unsafe values of deposits");
                    }
                }

                return D;
            }
        }
        revert CurvePoolUtilError("Did not converge");
    }

    /**
     * @notice A getter for the balances of the two tokens curve pool is made up of.
     * @param _curvePool address of the curve pool whose coin balances you want to check.
     * @return ibtBalance uint256 value denoting the ibt balance in the respective pool.
     * @return ptBalance uint256 value denoting the pt balance in the respective pool.
     */
    function _calcCurrentBalances(
        address _curvePool
    ) internal returns (uint256 ibtBalance, uint256 ptBalance) {
        // always ibt/pt pool is deployed , 0 index -> ibt , 1 index -> pt
        ibtBalance = ICurvePool(_curvePool).balances(0);
        ptBalance = ICurvePool(_curvePool).balances(1);
    }

    /**
     * @notice Function for calculating the geometric mean.
     * @param x uint256[2] array for calculating the geometric mean.
     * @return The geometric mean value, and reverts if not converging.
     */
    function _geometricMean(
        uint256[2] memory x
    ) internal pure returns (uint256) {
        uint256 D = x[0];
        uint256 diff = 0;
        for (uint256 i = 0; i < 255; i++) {
            uint256 D_prev = D;
            /**tmp = 1e18
            for each _x in x:
                tmp = tmp *_x /D
            D = D*((N_COINS-1)*10**18+tmp)/(N_COINS*10**18)
            **/
            D = (D + (x[0] * x[1]) / D) / 2; //for 2 coins
            if (D > D_prev) {
                diff = D - D_prev;
            } else {
                diff = D_prev - D;
            }

            if (diff <= 1 || diff * 1e18 < D) {
                return D;
            }
        }
        revert CurvePoolUtilError("Did not converge");
    }

    /**
     * @notice Function for getting the rate of pt/ibt
     * @param pt address of the pt token.
     * @return the exchange rate from pt->ibt.
     */
    function _getExchangeRate(address pt) internal returns (uint256) {
        uint256 IBT_UNIT = 10 **
            IERC20MetadataUpgradeable(IPrincipalToken(pt).getIBT()).decimals();
        return IPrincipalToken(pt).convertToAssetsOfIBT(IBT_UNIT);
    }

    /**
     * @notice Function for calculating the bigger uint256 value from the 2 values.
     * @param a the first uint256 value.
     * @param b the second uint256 value.
     * @return the bigger one from the 2 uint256 values.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

library StructUtil {
    struct PoolData {
        address pool;
        string poolProtocolName;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

import "./../util/lib/CurvePoolUtil.sol";

import "./../interfaces/ISpectraZap.sol";
import "./../interfaces/IPrincipalToken.sol";
import "./../interfaces/IRegistry.sol";
import "./../interfaces/IPrincipalTokenFactory.sol";

contract SpectraZap is ISpectraZap, Initializable {
    error SpectraZapError(string reason);

    address private registry;

    event ZappedInToCurvePoolWithAsset(
        address indexed _principalToken,
        address indexed _sender,
        uint256 _amount,
        uint256 totalPTAmount,
        uint256 lpTokenAmount
    );
    event ZappedInToCurvePoolWithIBT(
        address indexed _principalToken,
        address indexed _sender,
        uint256 _amount,
        uint256 totalPTAmount,
        uint256 lpTokenAmount
    );
    event AddedLiquidityToCurve(
        address indexed _receiver,
        uint256 _amountIbt,
        uint256 _amountPt
    );

    /**
     * @notice Constructor of the contract
     */
    constructor() {
        _disableInitializers(); // using this so that the deployed logic contract later cannot be initialized.
    }

    /**
     * @notice Initializer of the contract.
     * @param _registry the address of the registry contract.
     */
    function initialize(address _registry) external initializer {
        if ((_registry == address(0))) {
            revert SpectraZapError("Cannot set registry to zero address");
        }
        registry = _registry;
    }

    /**
     * @notice Zap:
     * - deposits a defined asset amount in the depositor
     * - calculates the amount of ibt and pt to be deposited in curve's ibt/pt pool for max lp tokens with the help of _calcIbtToDepositInCurvePool
     * - deposits into curve pool
     * @param _principalToken the _principalToken to interact with
     * @param poolIndex the index of pool to fetch from factory
     * @param _amount the amount of underlying to deposit
     * @param underlying The address of the asset(underlying token).
     * @param minLpAmount The minimum expected lp token amount after deposit.
     * @param receiver The receiver of the lp tokens after deposit.
     * @return lpAmount the amount of LP after adding liquidity to pool
     */
    function zapInToCurvePoolWithAsset(
        address _principalToken,
        uint256 poolIndex,
        uint256 _amount,
        IERC20Upgradeable underlying,
        uint256 minLpAmount,
        address receiver
    ) public returns (uint256 lpAmount) {
        SafeERC20Upgradeable.safeTransferFrom(
            underlying,
            msg.sender,
            address(this),
            _amount
        );
        address factory = IRegistry(registry).getPrincipalTokenFactoryAddress();
        if ((factory == address(0))) {
            revert SpectraZapError(
                "PrincipalTokenFactory address is not set in registry"
            );
        }
        StructUtil.PoolData memory poolData = IPrincipalTokenFactory(factory)
            .getPool(_principalToken, poolIndex);
        address ibt = IPrincipalToken(_principalToken).getIBT();
        uint256 totalAmountOfIbt = IPrincipalToken(ibt).convertToShares(
            _amount
        );
        uint256 ibtToDepositInPool = _calcIbtToDepositInCurvePool(
            totalAmountOfIbt,
            poolData.pool,
            _principalToken
        );
        uint256 assetToDeposit = IPrincipalToken(ibt).convertToAssets(
            totalAmountOfIbt - ibtToDepositInPool
        );

        SafeERC20Upgradeable.safeIncreaseAllowance(
            underlying,
            _principalToken,
            assetToDeposit
        );
        uint256 ptReceived = IPrincipalToken(_principalToken).deposit(
            assetToDeposit,
            receiver
        );

        SafeERC20Upgradeable.safeIncreaseAllowance(
            underlying,
            ibt,
            _amount - assetToDeposit
        );
        uint256 ibtReceived = IPrincipalToken(ibt).deposit(
            _amount - assetToDeposit,
            address(this)
        );

        SafeERC20Upgradeable.safeIncreaseAllowance(
            IERC4626Upgradeable(ibt),
            poolData.pool,
            ibtReceived
        );
        SafeERC20Upgradeable.safeIncreaseAllowance(
            IPrincipalToken(_principalToken),
            poolData.pool,
            ptReceived
        );
        lpAmount = _addLiquidityToCurvePool(
            poolData.pool,
            ibtToDepositInPool,
            ptReceived,
            receiver
        );
        if (lpAmount < minLpAmount) {
            revert SpectraZapError(
                "Actual lp token amount is less than the minimum expected value"
            );
        }

        emit ZappedInToCurvePoolWithAsset(
            _principalToken,
            receiver,
            _amount,
            ptReceived,
            lpAmount
        );
    }

    /**
     * @notice Zap:
     * - deposits a defined ibt amount in the depositor which gets deposited in principalToken for pt.
     * - calculates the amount of ibt and pt to be deposited in curve's ibt/pt pool for max lp tokens with the help of _calcIbtToDepositInCurvePool
     * - deposits into curve pool
     * @param _principalToken the _principalToken to interact with
     * @param _amount the amount of ibt to deposit
     * @param minLpAmount The minimum expected lp token amount after deposit.
     * @param receiver The receiver of the lp tokens after deposit.
     * @return lpAmount the amount of LP after adding liquidity to pool
     */
    function zapInToCurvePoolWithIBT(
        address _principalToken,
        uint256 poolIndex,
        uint256 _amount,
        uint256 minLpAmount,
        address receiver
    ) public returns (uint256 lpAmount) {
        address ibt = IPrincipalToken(_principalToken).getIBT();
        address factory = IRegistry(registry).getPrincipalTokenFactoryAddress();
        if ((factory == address(0))) {
            revert SpectraZapError(
                "PrincipalTokenFactory address is not set in registry"
            );
        }
        StructUtil.PoolData memory poolData = IPrincipalTokenFactory(factory)
            .getPool(_principalToken, poolIndex);
        SafeERC20Upgradeable.safeTransferFrom(
            IERC4626Upgradeable(ibt),
            msg.sender,
            address(this),
            _amount
        );
        uint256 ibtToDepositInPool = _calcIbtToDepositInCurvePool(
            _amount,
            poolData.pool,
            _principalToken
        );

        SafeERC20Upgradeable.safeIncreaseAllowance(
            IERC4626Upgradeable(ibt),
            _principalToken,
            _amount - ibtToDepositInPool
        );

        uint256 ptReceived = IPrincipalToken(_principalToken).depositWithIBT(
            _amount - ibtToDepositInPool,
            receiver
        );

        SafeERC20Upgradeable.safeIncreaseAllowance(
            IERC4626Upgradeable(ibt),
            poolData.pool,
            ibtToDepositInPool
        );
        SafeERC20Upgradeable.safeIncreaseAllowance(
            IPrincipalToken(_principalToken),
            poolData.pool,
            ptReceived
        );

        lpAmount = _addLiquidityToCurvePool(
            poolData.pool,
            ibtToDepositInPool,
            ptReceived,
            receiver
        );
        if (lpAmount < minLpAmount) {
            revert SpectraZapError(
                "Actual lp token amount is less than the minimum expected value"
            );
        }

        emit ZappedInToCurvePoolWithIBT(
            _principalToken,
            receiver,
            _amount,
            ptReceived,
            lpAmount
        );
    }

    /**
     * @notice Getter for the registry address
     * @return the address of the APW registry
     */
    function getRegistryAddress() external view returns (address) {
        return registry;
    }

    /**
     * @notice Function for adding liquidity in the curve pool.
     * @param _curvePoolAddress the address of the curve pool to add the liquidity.
     * @param _amountIbtToDeposit the amount of ibt to deposit in the pool.
     * @param _amountPtToDeposit the amount of pt to deposit in the pool.
     * @param receiver The receiver of the lp tokens after deposit.
     * @return the amount of lp token received in adding the liquidity to the pool.
     */
    function _addLiquidityToCurvePool(
        address _curvePoolAddress,
        uint256 _amountIbtToDeposit,
        uint256 _amountPtToDeposit,
        address receiver
    ) internal returns (uint256) {
        uint256[2] memory amounts;
        amounts[0] = _amountIbtToDeposit;
        amounts[1] = _amountPtToDeposit;
        uint256 _minMintAmount = _calcExpectedLpTokenAmount(
            _curvePoolAddress,
            amounts
        );

        /**
            The following call makes a call to curve pool's
            def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256,use_eth: bool = False, receiver: address = msg.sender) -> uint256
            (https://github.com/curvefi/curve-factory-crypto/blob/7ed1011055682cef75ac2fa95d50407db33e7dfb/contracts/CurveCryptoSwap2ETH.vy#L890)
        **/
        (bool success, bytes memory responseData) = _curvePoolAddress.call(
            abi.encodeWithSelector(
                0x7328333b,
                amounts,
                _minMintAmount,
                false,
                receiver
            )
        );
        if (!success) {
            revert SpectraZapError("Failed to add liquidity to curve pool");
        }
        emit AddedLiquidityToCurve(
            receiver,
            _amountIbtToDeposit,
            _amountPtToDeposit
        );
        return uint256(bytes32(responseData));
    }

    /**
     * @notice Function for getting the expected lp token amount given the ibt and pt to deposit
     * @param _curvePoolAddress the address of the curve pool in which amount will be deposited.
     * @param amounts a uint256[2] array containing the amounts of ibt and pt to deposit in the pool.
     * @return the amount of expected lp token that will be received on adding the liquidity to the pool.
     */
    function _calcExpectedLpTokenAmount(
        address _curvePoolAddress,
        uint256[2] memory amounts
    ) internal returns (uint256) {
        // keccack of getter calc_token_amount(uint256[2]) of curve pool is 8d8ea727adc16bc9a63f30de52c828f43fcd0f5b5f00f7b0b009cd5a72dc2d03
        // The function selector is first 4bytes of it, so 0x8d8ea727
        (bool success, bytes memory responseData) = _curvePoolAddress.call(
            abi.encodeWithSelector(0x8d8ea727, amounts)
        );
        if (!success) {
            revert SpectraZapError(
                "Could not fetch expected LP token for the curve pool"
            );
        }
        return abi.decode(responseData, (uint256));
    }

    /**
     * @notice Function for calculating the amount of ibt to add in the pool which internally
       calls a lib function for the calculation.
     * @param _amount the max amount of ibt available for deposit.
     * @param _curvePool the address of the curve pool in which to deposit the ibt.
     * @param _principalToken the address of the principalToken associated with the pool.
     * @return the amount of ibt to add into the pool.
     */
    function _calcIbtToDepositInCurvePool(
        uint256 _amount,
        address _curvePool,
        address _principalToken
    ) internal returns (uint256) {
        return
            CurvePoolUtil._calcIbtToDepositInCurvePool(
                _amount,
                _curvePool,
                _principalToken
            );
    }
}