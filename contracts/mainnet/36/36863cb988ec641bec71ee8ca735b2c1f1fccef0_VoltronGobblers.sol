// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title GOO (Gradual Ownership Optimization) Issuance
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Implementation of the GOO Issuance mechanism.
library LibGOO {
    using FixedPointMathLib for uint256;

    /// @notice Compute goo balance based on emission multiple, last balance, and time elapsed.
    /// @param emissionMultiple The multiple on emissions to consider when computing the balance.
    /// @param lastBalanceWad The last checkpointed balance to apply the emission multiple over time to, scaled by 1e18.
    /// @param timeElapsedWad The time elapsed since the last checkpoint, scaled by 1e18.
    function computeGOOBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 timeElapsedWad
    ) internal pure returns (uint256) {
        unchecked {
            // We use wad math here because timeElapsedWad is, as the name indicates, a wad.
            uint256 timeElapsedSquaredWad = timeElapsedWad.mulWadDown(timeElapsedWad);

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * timeElapsedSquaredWad) >> 2) +

            timeElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IERC20Metadata.sol";
import "./IERC721Receiver.sol";

interface IGoober is IERC721Receiver {
    // Errors

    // Balance Errors
    error InsufficientAllowance();
    error InsufficientGoo(uint256 amount, uint256 actualK, uint256 expectedK);

    // Deposit Errors
    error InsufficientLiquidityDeposited();
    error MintBelowLimit();

    // K Calculation Errors
    error MustLeaveLiquidity(uint256 gooBalance, uint256 gobblerBalance);

    // Mint Errors
    error AuctionPriceTooHigh(uint256 auctionPrice, uint256 poolPrice);
    error InsufficientLiquidity(uint256 gooBalance, uint256 gobblerBalance);
    error MintFailed();

    // NFT Errors
    error InvalidNFT();
    error InvalidMultiplier(uint256 gobblerId);

    // Skim Errors
    error NoSkim();

    // Swap Errors
    error InsufficientInputAmount(uint256 amount0In, uint256 amount1In);
    error InsufficientOutputAmount(uint256 gooOut, uint256 gobblersOut);
    error InvalidReceiver(address receiver);
    error ExcessiveErroneousGoo(uint256 actualErroneousGoo, uint256 allowedErroneousGoo);

    // Time Errors
    error Expired(uint256 time, uint256 deadline);

    // Withdraw Errors
    error InsufficientLiquidityWithdrawn();
    error BurnAboveLimit();

    /**
     * @notice The caller doesn't have permission to access the function.
     * @param accessor The requesting address.
     * @param permissioned The address which has the requisite permissions.
     */
    error AccessControlViolation(address accessor, address permissioned);

    /**
     * @notice Invalid feeTo address.
     * @param feeTo the feeTo address.
     */
    error InvalidAddress(address feeTo);

    // Structs

    /// @dev Intermediary struct for swap calculation.
    struct SwapData {
        uint256 gooReserve;
        uint256 gobblerReserve;
        uint256 gooBalance;
        uint256 gobblerBalance;
        uint256 multOut;
        uint256 amount0In;
        uint256 amount1In;
        int256 erroneousGoo;
    }

    // Events

    event VaultMint(address indexed minter, uint256 auctionPricePerMult, uint256 poolPricePerMult, uint256 gooConsumed);

    event Deposit(
        address indexed caller, address indexed receiver, uint256[] gobblers, uint256 gooTokens, uint256 fractions
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256[] gobblers,
        uint256 gooTokens,
        uint256 fractions
    );

    event FeesAccrued(address indexed feeTo, uint256 fractions, bool performanceFee, uint256 _deltaK);

    event Swap(
        address indexed caller,
        address indexed receiver,
        uint256 gooTokensIn,
        uint256 gobblersMultIn,
        uint256 gooTokensOut,
        uint256 gobblerMultOut
    );

    event Sync(uint256 gooBalance, uint256 multBalance);

    /*//////////////////////////////////////////////////////////////
    // External: Non Mutating
    //////////////////////////////////////////////////////////////*/

    /// @return gooTokens The total amount of Goo owned.
    /// @return gobblerMult The total multiple of all Gobblers owned.
    function totalAssets() external view returns (uint256 gooTokens, uint256 gobblerMult);

    /// @param gooTokens - The amount of Goo to simulate.
    /// @param gobblerMult - The amount of Gobbler mult in to simulate.
    /// @return fractions - The fractions, without any fees assessed, which would be returned for a deposit.
    function convertToFractions(uint256 gooTokens, uint256 gobblerMult) external view returns (uint256 fractions);

    /// @param fractions The amount of fractions to simulate converting.
    /// @param gooTokens - The amount of Goo out.
    /// @param gobblerMult - The amount of Gobbler mult out.
    function convertToAssets(uint256 fractions) external view returns (uint256 gooTokens, uint256 gobblerMult);

    /// @notice Gets the vault reserves of Goo and Gobbler mult, along with the last update time.
    /// @dev This can be used to calculate slippage on a swap of certain sizes
    /// @dev using Uni V2 style liquidity math.
    /// @return _gooReserve - The amount of Goo in the tank for the pool.
    /// @return _gobblerReserve - The total multiplier of all Gobblers in the pool.
    /// @return _blockTimestampLast - The last time that the oracles were updated.
    function getReserves()
        external
        view
        returns (uint256 _gooReserve, uint256 _gobblerReserve, uint32 _blockTimestampLast);

    /// @notice Previews a deposit of the supplied Gobblers and Goo.
    /// @param gobblers - Array of Gobbler ids.
    /// @param gooTokens - Amount of Goo to deposit.
    /// @return fractions - Amount of fractions created.
    function previewDeposit(uint256[] calldata gobblers, uint256 gooTokens) external view returns (uint256 fractions);

    /// @notice Previews a withdraw of the requested Gobblers and Goo tokens from the vault.
    /// @param gobblers - Array of Gobbler ids.
    /// @param gooTokens - Amount of Goo to withdraw.
    /// @return fractions - Amount of fractions withdrawn.
    function previewWithdraw(uint256[] calldata gobblers, uint256 gooTokens)
        external
        view
        returns (uint256 fractions);

    /// @notice Simulates a swap.
    /// @param gobblersIn - Array of Gobbler ids to swap in.
    /// @param gooIn - Amount of Goo to swap in.
    /// @param gobblersOut - Array of Gobbler ids to swap out.
    /// @param gooOut - Amount of Goo to swap out.
    /// @return erroneousGoo - The amount in wei by which to increase or decrease gooIn/Out to balance the swap.
    function previewSwap(uint256[] calldata gobblersIn, uint256 gooIn, uint256[] calldata gobblersOut, uint256 gooOut)
        external
        view
        returns (int256 erroneousGoo);

    /*//////////////////////////////////////////////////////////////
    // External: Mutating, Restricted Access
    //////////////////////////////////////////////////////////////*/

    // Access Control

    /**
     * @notice Updates the address that fees are sent to.
     * @param newFeeTo The new address to which fees will be sent.
     */
    function setFeeTo(address newFeeTo) external;

    /**
     * @notice Updates the address that can call mintGobbler.
     * @param newMinter The new address to which will be able to call mintGobbler.
     */
    function setMinter(address newMinter) external;

    // Other Privileged Functions

    /// @notice Mints Gobblers using the pool's virtual reserves of Goo
    /// @notice when specific conditions are met.
    function mintGobbler() external;

    /// @notice Restricted function for skimming any ERC20s that may have been erroneously sent to the pool.
    function skim(address erc20) external;

    /// @notice Restricted function for blocking/unblocking compromised Gobblers from the pool.
    function flagGobbler(uint256 tokenId, bool _flagged) external;

    /*//////////////////////////////////////////////////////////////
    // External: Mutating, Unrestricted
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits the supplied Gobblers/Goo from the owner and sends fractions to the receiver.
    /// @param gobblers - Array of Gobbler ids.
    /// @param gooTokens - Amount of Goo to deposit.
    /// @param receiver - Address to receive fractions.
    /// @return fractions - Amount of fractions created.
    function deposit(uint256[] calldata gobblers, uint256 gooTokens, address receiver)
        external
        returns (uint256 fractions);

    /// @notice Deposits the supplied Gobblers/Goo from the owner and sends fractions to the
    /// @notice receiver whilst ensuring a deadline is met, and a minimum amount of fractions are created.
    /// @param gobblers - Array of Gobbler ids to deposit.
    /// @param gooTokens - Amount of Goo to deposit.
    /// @param receiver - Address to receive fractions.
    /// @param minFractionsOut - Minimum amount of fractions to be sent.
    /// @param deadline - Unix timestamp by which the transaction must execute.
    /// @return fractions - Amount of fractions created.
    function safeDeposit(
        uint256[] calldata gobblers,
        uint256 gooTokens,
        address receiver,
        uint256 minFractionsOut,
        uint256 deadline
    ) external returns (uint256 fractions);

    /// @notice Withdraws the requested Gobblers and Goo from the vault.
    /// @param gobblers - Array of Gobbler ids to withdraw
    /// @param gooTokens - Amount of Goo to withdraw.
    /// @param receiver - Address to receive the Goo and Gobblers.
    /// @param owner - Owner of the fractions to be destroyed.
    /// @return fractions - Amount of fractions destroyed.
    function withdraw(uint256[] calldata gobblers, uint256 gooTokens, address receiver, address owner)
        external
        returns (uint256 fractions);

    /// @notice Withdraws the requested Gobblers/Goo from the vault to the receiver and destroys fractions
    /// @notice from the owner whilst ensuring a deadline is met, and a maximimum amount of fractions are destroyed.
    /// @param gobblers - Array of Gobbler ids to withdraw.
    /// @param gooTokens - Amount of Goo to withdraw.
    /// @param receiver - Address to receive the Goo and Gobblers.
    /// @param owner - Owner of the fractions to be destroyed.
    /// @param maxFractionsIn - Maximum amount of fractions to be destroyed.
    /// @param deadline - Unix timestamp by which the transaction must execute.
    /// @return fractions - Aamount of fractions destroyed.
    function safeWithdraw(
        uint256[] calldata gobblers,
        uint256 gooTokens,
        address receiver,
        address owner,
        uint256 maxFractionsIn,
        uint256 deadline
    ) external returns (uint256 fractions);

    /// @notice Swaps supplied Gobblers/Goo for Gobblers/Goo in the pool.
    function swap(
        uint256[] calldata gobblersIn,
        uint256 gooIn,
        uint256[] calldata gobblersOut,
        uint256 gooOut,
        address receiver,
        bytes calldata data
    ) external returns (int256 erroneousGoo);

    /// @notice Swaps supplied Gobblers/Goo for Gobblers/Goo in the pool, with slippage and deadline control.
    function safeSwap(
        uint256 erroneousGooAbs,
        uint256 deadline,
        uint256[] calldata gobblersIn,
        uint256 gooIn,
        uint256[] calldata gobblersOut,
        uint256 gooOut,
        address receiver,
        bytes calldata data
    ) external returns (int256 erroneousGoo);
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract VoltronGobblerStorageV1 {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public artGobblers;
    address public goo;
    address public goober;

    /*//////////////////////////////////////////////////////////////
                                USER DATA
    //////////////////////////////////////////////////////////////*/

    // gobblerId => user
    mapping(uint256 => address) public getUserByGobblerId;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of gobblers currently owned by the user.
        uint32 gobblersOwned;
        // The sum of the multiples of all gobblers the user holds.
        uint32 emissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 virtualBalance;
        // claimed pool's gobbler number
        uint16 claimedNum;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
        // Timestamp of the last goo deposit.
        uint48 lastGooDepositedTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    /*//////////////////////////////////////////////////////////////
                                POOL DATA
    //////////////////////////////////////////////////////////////*/

    struct GlobalData {
        // The total number of gobblers currently deposited by the user.
        uint32 totalGobblersDeposited;
        // The sum of the multiples of all gobblers the user holds.
        uint32 totalEmissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 totalVirtualBalance;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
    }

    GlobalData public globalData;

    /// @notice Maps gobbler IDs to claimable
    mapping(uint256 => bool) public gobblerClaimable;
    uint256[] public claimableGobblers;
    uint256 public claimableGobblersNum;

    /*//////////////////////////////////////////////////////////////
                                admin
    //////////////////////////////////////////////////////////////*/

    bool public mintLock;
    bool public claimGobblerLock;

    // must stake timeLockDuration time to withdraw
    // Avoid directly claiming the cheaper gobbler after the user deposits goo
    uint256 public timeLockDuration;

    // a privileged address with the ability to mint gobblers
    address public minter;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*


                                                                                                     /=O
                                                                                                   \ =
                                                                                                 O  /
                                                                                                /  \  [[/
                                                                                              /  ,\\       [O
                                                                                            O   =/   /OooO   //
                                                                                          O       ]OoooO/  ,\
                                                                                        O^     ,OoooooO   /
                                                                                       /  ,    =OoooooO  =
                                                                                     O  ,/  //   OooooO  =
                                                                                   \   /^  /  ^  OooooO  =
                                                                                 O   / ^  O   ^  OooooO  =
                                                                               //  ,OO  ,=    ^  OooooO  =
                                                                              /  ,OOO  ,O     ^  OooooO  =
                                                                            O   OOOO  =O/[[[[[   OooooO  =O
                                                                          O   /OoO/  /\          Oooooo        O
                                                                         /  =OooO^  /\   oooooooooooooooooooo^  /
                                                                       /  ,O ++O   \/  , ++++++++++++++++++++,\  \
                                                                     O   O ++,O  ,O/  ,++++++++++++++++++++++++\  =
                                                                   \   //+++,O  ,O^  ,++++++  =O++++++=O[\^+++++\  ,
                                                                 O^  =/+++.=/  =O    ++++.,   =/++++++=O  =^.++++=  ,O                                                        OO  OOO
                                                                /  ,O ....=/  =\              O^......=O   =\]]]]]/  ,O                                                       ^     =
                                                              /   O ...../^  /O]]]]]]]]       O^......=O               O                                                     O  O=^ =
     \                            O                         \   //......O   o        \    =^ ,O.......=O^[\    [/                                                              =^=^ =
      O    ]]]]]]]]]]]]]]]]]]]]]   O                      O   =/......,O   \        O  =^ =  =O.......=O^...,\]   ,\/                                 OO                    /  O.=^ =
        \   \\..................=^ ,                    O/  ,O ......,O  ,\        O  =O\    =^.......=O^.......[\    ,O                 \\O            =\                 O  =^.=^ =
         O^   O^.................=  =                  /  ,O .......=/  ,         \  =/.O    O^.......=O^..........,\\    \/           O    /            ,O                ^  O..=^ =
           /   ,O ................O  \               \   //........//  =         /  =/..O    O^.......=O^..............[O    ,\       /  ,\  =O            \              O  = ..=^ =
             \   \\................\  O            O   //.........O^  /         /  =/...=^  ,O........=O^.................,\\    [O /   / .\   /         ,  \             ^ ,/...=^ =
              O^  ,O^..............=^  O         O^  ,O ........,O   /         /  =/....=^  =O........=O^.....................[O      //....,\  \        =O  ,O          O  / ...=^ =
                O   ,O .............=  ,        /  ,O .........,O   \         /  =/......O  =^........=O^........OOO\ ............\\]/........\  ,/      =^=^  /           ,^....=  =
                  \   \\.............O  =     /   //..........=O  ,O         /  //.......O  O^........=O^........OOOO[.........../OO ..........=^  \     =^..\  \       /  O.....=  =
                   O   =^.           .\  \  \   //.         ./O^  =         /  //.       =^ O         =O^        O/.           ,OO              ,O  ,/   =^  .\  =O    O  =^     =  =
                     \  =^            =^  O   ,O            // =\  =O      /  //         =^,O         =O^                    .OO/                 \   \  =^    =^ ,O   ^  O      =  =
                      ^  =^            =    ,O             O/   ,\  ,O    /  //           O=O         =O^                   /O/          ]         ,\    =^      \  \ O  =^      =  =
                       ^  \             O  //            ,O      ,O  ,   /  //            OO^         =O^                 ,OO          =OOO          \   =^       \  =^  /       =  =
                       O^  \             O/             ,O         O  ,O^  /O            OOO^         =O^               ,OO           OO  OO          =\ =^        ,    =        =  =
                        /   O                          =O           \     /O           =OOOO          =O^              /O/          /OOOOO  O\          O=^          \ ,^        =  =
                         O   O                        //      O      \   /O          ,OOOOOO          =O^               OO        ,OOOO     OOO          O^           \/         =  =
                          O   O                      O^      OOO^     \^/O          /OOO OO/          =O^                OO^       ,OO  O    O/        ,O\^                      =  =
                           O  ,O                   ,O      ,OO O \     =O         ,OOOOO  O^          =O^       =         \O\        \O    OO         /^ =^                      =  =
                            \  ,\                 , =\     =OOOOO^    ,O         /O       O^          =O^       ,O.        \OO        ,O  O/        =O   =^     /                =  =
                             ^  =\               =   ,O     ,OOO     ,O.       ,OOOOOOOOOOO.          =O^       .OO.        =OO\.      .OO.       .O^    =^    = \               =  =
                              ^  =\............./  ,   O ....,O ....=O ......./OOO/[[[...,O...........=O^........OOO.........=OOO .............../O  ,O  =^...=^  =^............./  =
                               ^  =\..........,/  / O   \\.........=O .................../O...........=O^........OOO\.........,OOO\............,O^  / O  =^..,^    ,\............O  =
                                   \\++++++++,^  O    ^  =O+++++++=O +++++++++++++++++++=O/+++++++++++=O^++++++++OOOO\+++++++++,OOOO^+++++++++/O  ,O  O  =^+,/  / ^  O+++++++++++O  =
                                O   \\++++++/  ,O      \  ,O ++++/O^++++++++++++++++++++OO^+++++++++++=O^++++++++OOOOO^+++++++++,OOOOO++++++,O^  /    O  =^+O  =   \  \ +++++++++O  =
                                 O   O\++++O  ,O        O   O\++/O^++++++++++++++++++++=OO^+++++++++++/O\++++++++OOOOOO^++++++++++OO  O\+++O/  ,O     O  =oO  ,O    O  =\++++++++O  =
                                  O   OoooO  ,           O   \OoOOOOOOOOOOOOOOOOOOOOOOOOOOooooooooooooOOOooooooooOO    OoooooooooooOO  OOoO   /       O  =O^ ,O      O  ,Ooooooooo  =
                                   \   OO/  /              ^  =/                         OooooooooooooO[[[[[[[[[[[[[[[[   ,  [[[[[[[[[[ ,   ,\        O      O            Ooooooo/  =
                                    \  ,^  \                \                           =OooooooooooooO   ,]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]//         OOOOOO\           \  \ooooo^  =
                                     ^   ,O                  O  =                       =OooooooooooooO   =                                                              ^  =Oooo^  =
                                     \^ ,O                    O/                     \   \OoooOOOOOOOOO   =                                                               O  ,OoO^  =
                                       //                                             /   =OOOOOOOOOOOO   =                                                                    OO^  =
                                                                                       O   ,OOOOOOOOOOO   /                                                                  ^  \^  =
                                                                                        \^  ,OOOOOOOOO   /                                                                    \     =
                                                                                          \   OOOOOOO   O                                                                      O    =
                                                                                           O   \OOOO   O                                                                        O   =
                                                                                            O   =OO  ,O                                                                          \^ =
                                                                                              ^  ,  ,O                                                                             \=
                                                                                               \   ,
                                                                                                / =/*/

import { LibGOO } from "goo-issuance/LibGOO.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { toDaysWadUnsafe } from "solmate/utils/SignedWadMath.sol";
import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { VoltronGobblerStorageV1 } from "./VoltronGobblerStorage.sol";

import { IGoober } from "goobervault/interfaces/IGoober.sol";
import { IArtGobblers } from "./utils/IArtGobblers.sol";
import { IGOO } from "./utils/IGOO.sol";

contract VoltronGobblers is ReentrancyGuardUpgradeable, OwnableUpgradeable, VoltronGobblerStorageV1 {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    /// @notice A scalar for scaling up and down to basis points.
    uint16 private constant BPS_SCALAR = 1e4;
    /// @notice The average multiplier of a newly minted gobbler.
    /// @notice 7.3294 = weighted avg. multiplier from mint probabilities,
    /// @notice derived from: ((6*3057) + (7*2621) + (8*2293) + (9*2029)) / 10000.
    uint32 private constant AVERAGE_MULT_BPS = 73294;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event GobblerDeposited(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblerWithdrawn(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event GobblerMinted(uint256 indexed num, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblersClaimed(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GooClaimed(address indexed to, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier canMint() {
        require(!mintLock, "MINT_LOCK");
        _;
    }

    modifier canClaimGobbler() {
        require(!claimGobblerLock, "CLAIM_GOBBLER_LOCK");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "ONLY_MINTER");
        _;
    }

    function initialize(address admin_, address minter_, address artGobblers_, address goo_, address goober_, uint256 timeLockDuration_)
        public
        initializer
    {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(admin_);
        minter = minter_;
        artGobblers = artGobblers_;
        goo = goo_;
        goober = goober_;
        timeLockDuration = timeLockDuration_;
        mintLock = true;
    }

    function depositGobblers(uint256[] calldata gobblerIds, uint256 gooAmount) external nonReentrant {
        if (gooAmount > 0) _addGoo(gooAmount);

        // update user virtual balance of GOO
        _updateGlobalBalance(gooAmount);
        _updateUserGooBalance(msg.sender, gooAmount);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 deltaEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(holder == msg.sender, "WRONG_OWNER");
            require(emissionMultiple > 0, "GOBBLER_MUST_BE_REVEALED");

            deltaEmissionMultiple += emissionMultiple;

            getUserByGobblerId[id] = msg.sender;

            IArtGobblers(artGobblers).transferFrom(msg.sender, address(this), id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned += totalNumber;
        getUserData[msg.sender].emissionMultiple += deltaEmissionMultiple;

        // update global data
        globalData.totalGobblersDeposited += totalNumber;
        globalData.totalEmissionMultiple += deltaEmissionMultiple;

        emit GobblerDeposited(msg.sender, gobblerIds, gobblerIds);
    }

    function withdrawGobblers(uint256[] calldata gobblerIds) external nonReentrant {
        // update user virtual balance of GOO
        _updateGlobalBalance(0);
        _updateUserGooBalance(msg.sender, 0);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 deltaEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(getUserByGobblerId[id] == msg.sender, "WRONG_OWNER");

            deltaEmissionMultiple += emissionMultiple;

            delete getUserByGobblerId[id];

            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned -= totalNumber;
        getUserData[msg.sender].emissionMultiple -= deltaEmissionMultiple;

        // update global data
        globalData.totalGobblersDeposited -= totalNumber;
        globalData.totalEmissionMultiple -= deltaEmissionMultiple;

        emit GobblerWithdrawn(msg.sender, gobblerIds, gobblerIds);
    }

    function _mintGobblers(uint256 maxPrice, uint256 num) internal returns (uint256[] memory gobblerIds) {
        gobblerIds = new uint256[](num);
        claimableGobblersNum += num;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = IArtGobblers(artGobblers).mintFromGoo(maxPrice, true);
            gobblerIds[i] = id;
            _addClaimableGobbler(id);
        }
        emit GobblerMinted(num, gobblerIds, gobblerIds);
        return gobblerIds;
    }

    function _addClaimableGobbler(uint256 id) internal {
        claimableGobblers.push(id);
        gobblerClaimable[id] = true;
    }

    function _removeClaimableGobbler(uint256 id) internal {
        uint256 len = claimableGobblers.length;
        for (uint256 idx = 0; idx < len; idx++) {
            if (claimableGobblers[idx] == id) {
                // found the existing gobbler ID
                // remove it from the array efficiently by re-ordering and deleting the last element
                if (idx != len - 1) {
                    claimableGobblers[idx] = claimableGobblers[len - 1];
                }
                claimableGobblers.pop();
                delete gobblerClaimable[id];
                break;
            }
        }
    }

    function mintGobblers(uint256 maxPrice, uint256 num) external nonReentrant canMint returns (uint256[] memory) {
        return _mintGobblers(maxPrice, num);
    }

    function claimGobblers(uint256[] calldata gobblerIds) external nonReentrant canClaimGobbler {
        // Avoid directly claiming the cheaper gobbler after the user deposits goo
        require(getUserData[msg.sender].lastGooDepositedTimestamp + timeLockDuration <= block.timestamp, "CANT_CLAIM_NOW");

        uint256 globalBalance = _updateGlobalBalance(0);
        uint256 userVirtualBalance = _updateUserGooBalance(msg.sender, 0);

        // (user's virtual goo / global virtual goo) * total claimable num - claimed num
        uint256 claimableNum =
            userVirtualBalance.divWadDown(globalBalance).mulWadDown(claimableGobblers.length) - uint256(getUserData[msg.sender].claimedNum);

        uint256 claimNum = gobblerIds.length;
        require(claimableNum >= claimNum, "CLAIM_TOO_MUCH");

        getUserData[msg.sender].claimedNum += uint16(claimNum);
        claimableGobblersNum -= claimNum;

        // claim gobblers
        uint256 id;
        for (uint256 i = 0; i < claimNum; i++) {
            id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        emit GobblersClaimed(msg.sender, gobblerIds, gobblerIds);
    }

    function addGoo(uint256 amount) external nonReentrant {
        require(amount > 0, "INVALID_AMOUNT");
        _addGoo(amount);
        _updateGlobalBalance(amount);
        _updateUserGooBalance(msg.sender, amount);
    }

    function _addGoo(uint256 amount) internal {
        uint256 poolBalanceBefore = IArtGobblers(artGobblers).gooBalance(address(this));
        IGOO(goo).transferFrom(msg.sender, address(this), amount);
        IArtGobblers(artGobblers).addGoo(amount);
        require(IArtGobblers(artGobblers).gooBalance(address(this)) - poolBalanceBefore >= amount, "ADDGOO_FAILD");
    }

    function swapFromGoober(uint256 maxGooIn, uint256[] memory gobblersOut) external nonReentrant canMint {
        uint256[] memory gobblersIn;
        _swapFromGoober(gobblersIn, maxGooIn, gobblersOut, 0);
    }

    function _swapFromGoober(uint256[] memory gobblersIn, uint256 maxGooIn, uint256[] memory gobblersOut, uint256 gooOut) internal {
        int256 erroneousGoo = IGoober(goober).previewSwap(gobblersIn, maxGooIn, gobblersOut, gooOut);
        require(erroneousGoo <= 0, "MAX_GOO_IN_EXCEEDED");

        uint256 gooIn = maxGooIn - uint256(-erroneousGoo);
        IArtGobblers(artGobblers).removeGoo(gooIn);
        IGOO(goo).approve(goober, gooIn);

        for (uint256 i = 0; i < gobblersIn.length; i++) {
            uint256 id = gobblersIn[i];
            require(gobblerClaimable[id], "CAN_NOT_SWAP_UNCLAIMABLE_GOBBLER");
            IArtGobblers(artGobblers).approve(goober, id);
            _removeClaimableGobbler(id);
        }
        IGoober(goober).swap(gobblersIn, gooIn, gobblersOut, gooOut, address(this), "");

        if (gooOut > 0) {
            uint256 _gooBalance = IGOO(goo).balanceOf(address(this));
            // check GOO received in case of misbehaviour of goober
            require(_gooBalance >= gooOut);
            // add all GOOs into tank
            IArtGobblers(artGobblers).addGoo(_gooBalance);
        }

        uint256 num = gobblersOut.length;
        claimableGobblersNum += num;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = gobblersOut[i];
            require(IArtGobblers(artGobblers).ownerOf(id) == address(this));
            _addClaimableGobbler(id);
        }
        emit GobblerMinted(num, gobblersOut, gobblersOut);
    }

    /// @notice Arbitrage between `goober` market and mint auction
    /// Used when sell price on `goober` is higher than mint price on the auction
    /// @param gobblersIn The gobbler IDs to sell to `goober` market, can only use unclaimed gobblers
    function arbitrageFromGoober(uint256[] memory gobblersIn) external nonReentrant returns (uint256[] memory newGobblerIds) {
        uint256[] memory gobblersOut;
        // simulate swap to get how much GOO we can received for this swap
        int256 erroneousGoo = IGoober(goober).previewSwap(gobblersIn, 0, gobblersOut, 0);
        require(erroneousGoo < 0, "GOOBER_NOT_PAYING_ANY_GOO");
        uint256 gooReceived = uint256(-erroneousGoo);

        uint256 num = gobblersIn.length;
        uint256 deltaEmissionMultiple;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = gobblersIn[i];
            (,, uint256 emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(emissionMultiple > 0, "UNREVEALED_GOBBLER");
            deltaEmissionMultiple += emissionMultiple;
        }
        // no need to use scaler here since GOO is a 18 decimals token
        uint256 avgSellPricePerMult = gooReceived.divWadDown(deltaEmissionMultiple);
        uint256 gooBalanceBefore = IArtGobblers(artGobblers).gooBalance(address(this));

        _swapFromGoober(gobblersIn, 0, gobblersOut, gooReceived);
        newGobblerIds = _mintGobblers(type(uint256).max, num);

        uint256 gooBalanceAfter = IArtGobblers(artGobblers).gooBalance(address(this));
        require(gooBalanceAfter > gooBalanceBefore, "GOO_REDUCED");

        uint256 gooConsumedForMinting = gooBalanceBefore + gooReceived - gooBalanceAfter;
        // use 7.3 as expected multiplier of newly minted gobbler to calc mint price per multiplier
        uint256 avgMintPricePerMult = gooConsumedForMinting.mulWadDown(BPS_SCALAR).divWadDown(AVERAGE_MULT_BPS * num);
        require(avgSellPricePerMult > avgMintPricePerMult, "MINT_PRICE_GRATER_THAN_SELL_PRICE");
        return newGobblerIds;
    }

    /*//////////////////////////////////////////////////////////////
                            UTILS FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _updateGlobalBalance(uint256 gooAmount) internal returns (uint256) {
        uint256 updatedBalance = globalGooBalance() + gooAmount;
        // update global balance
        globalData.totalVirtualBalance = uint128(updatedBalance);
        globalData.lastTimestamp = uint48(block.timestamp);
        return updatedBalance;
    }

    /// @notice Calculate global virtual goo balance.
    function globalGooBalance() public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            globalData.totalEmissionMultiple,
            globalData.totalVirtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - globalData.lastTimestamp))
        );
    }

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to add the user's virtual balance by.
    function _updateUserGooBalance(address user, uint256 gooAmount) internal returns (uint256) {
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = gooBalance(user) + gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].virtualBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint48(block.timestamp);
        if (gooAmount != 0) getUserData[user].lastGooDepositedTimestamp = uint48(block.timestamp);

        emit GooBalanceUpdated(user, updatedBalance);
        return updatedBalance;
    }

    /// @notice Calculate a user's virtual goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].virtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTION
    //////////////////////////////////////////////////////////////*/

    function mintGobblersByMinter(uint256 maxPrice, uint256 num) external onlyMinter nonReentrant returns (uint256[] memory) {
        return _mintGobblers(maxPrice, num);
    }

    function swapFromGooberByMinter(uint256 maxGooIn, uint256[] memory gobblersOut) external onlyMinter nonReentrant {
        uint256[] memory gobblersIn;
        _swapFromGoober(gobblersIn, maxGooIn, gobblersOut, 0);
    }

    /// @notice admin claim gobblers and goo remained in pool, only used when all user withdrawn their gobblers
    function adminClaimGobblersAndGoo(uint256[] calldata gobblerIds) external nonReentrant {
        _updateGlobalBalance(0);

        // require all user has withdraw their gobblers
        require(globalData.totalGobblersDeposited == 0, "ADMIN_CANT_CLAIM");

        // goo in gobblers
        IArtGobblers(artGobblers).removeGoo(IArtGobblers(artGobblers).gooBalance(address(this)));

        uint256 claimableGoo = IGOO(goo).balanceOf(address(this));
        address owner_ = owner();
        IGOO(goo).transfer(owner_, claimableGoo);

        emit GooClaimed(owner_, claimableGoo);

        // claim gobblers
        uint256 claimNum = gobblerIds.length;
        claimableGobblersNum -= claimNum;
        for (uint256 i = 0; i < claimNum; i++) {
            uint256 id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), owner_, id);
        }

        emit GobblersClaimed(owner_, gobblerIds, gobblerIds);
    }

    function setMintLock(bool isLock) external onlyOwner {
        mintLock = isLock;
    }

    function setClaimGobblerLock(bool isLock) external onlyOwner {
        claimGobblerLock = isLock;
    }

    function setTimeLockDuration(uint256 timeLockDuration_) external onlyOwner {
        timeLockDuration = timeLockDuration_;
    }

    function setGoober(address goober_) external onlyOwner {
        goober = goober_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IArtGobblers {
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ArtGobbled(address indexed user, uint256 indexed gobblerId, address indexed nft, uint256 id);
    event GobblerClaimed(address indexed user, uint256 indexed gobblerId);
    event GobblerPurchased(address indexed user, uint256 indexed gobblerId, uint256 price);
    event GobblersRevealed(address indexed user, uint256 numGobblers, uint256 lastRevealedId);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event LegendaryGobblerMinted(address indexed user, uint256 indexed gobblerId, uint256[] burnedGobblerIds);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event RandProviderUpgraded(address indexed user, address indexed newRandProvider);
    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event ReservedGobblersMinted(address indexed user, uint256 lastMintedGobblerId, uint256 numGobblersEach);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function BASE_URI() external view returns (string memory);
    function FIRST_LEGENDARY_GOBBLER_ID() external view returns (uint256);
    function LEGENDARY_AUCTION_INTERVAL() external view returns (uint256);
    function LEGENDARY_GOBBLER_INITIAL_START_PRICE() external view returns (uint256);
    function LEGENDARY_SUPPLY() external view returns (uint256);
    function MAX_MINTABLE() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
    function MINTLIST_SUPPLY() external view returns (uint256);
    function PROVENANCE_HASH() external view returns (bytes32);
    function RESERVED_SUPPLY() external view returns (uint256);
    function UNREVEALED_URI() external view returns (string memory);
    function acceptRandomSeed(bytes32, uint256 randomness) external;
    function addGoo(uint256 gooAmount) external;
    function approve(address spender, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function burnGooForPages(address user, uint256 gooAmount) external;
    function claimGobbler(bytes32[] memory proof) external returns (uint256 gobblerId);
    function community() external view returns (address);
    function currentNonLegendaryId() external view returns (uint128);
    function getApproved(uint256) external view returns (address);
    function getCopiesOfArtGobbledByGobbler(uint256, address, uint256) external view returns (uint256);
    function getGobblerData(uint256) external view returns (address owner, uint64 idx, uint32 emissionMultiple);
    function getGobblerEmissionMultiple(uint256 gobblerId) external view returns (uint256);
    function getTargetSaleTime(int256 sold) external view returns (int256);
    function getUserData(address)
        external
        view
        returns (uint32 gobblersOwned, uint32 emissionMultiple, uint128 lastBalance, uint64 lastTimestamp);
    function getUserEmissionMultiple(address user) external view returns (uint256);
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) external view returns (uint256);
    function gobble(uint256 gobblerId, address nft, uint256 id, bool isERC1155) external;
    function gobblerPrice() external view returns (uint256);
    function gobblerRevealsData()
        external
        view
        returns (uint64 randomSeed, uint64 nextRevealTimestamp, uint64 lastRevealedId, uint56 toBeRevealed, bool waitingForSeed);
    function goo() external view returns (address);
    function gooBalance(address user) external view returns (uint256);
    function hasClaimedMintlistGobbler(address) external view returns (bool);
    function isApprovedForAll(address, address) external view returns (bool);
    function legendaryGobblerAuctionData() external view returns (uint128 startPrice, uint128 numSold);
    function legendaryGobblerPrice() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 gobblerId);
    function mintLegendaryGobbler(uint256[] memory gobblerIds) external returns (uint256 gobblerId);
    function mintReservedGobblers(uint256 numGobblersEach) external returns (uint256 lastMintedGobblerId);
    function mintStart() external view returns (uint256);
    function name() external view returns (string memory);
    function numMintedForReserves() external view returns (uint256);
    function numMintedFromGoo() external view returns (uint128);
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    function owner() external view returns (address);
    function ownerOf(uint256 id) external view returns (address owner);
    function pages() external view returns (address);
    function randProvider() external view returns (address);
    function removeGoo(uint256 gooAmount) external;
    function requestRandomSeed() external returns (bytes32);
    function revealGobblers(uint256 numGobblers) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
    function symbol() external view returns (string memory);
    function targetPrice() external view returns (int256);
    function team() external view returns (address);
    function tokenURI(uint256 gobblerId) external view returns (string memory);
    function transferFrom(address from, address to, uint256 id) external;
    function transferOwnership(address newOwner) external;
    function upgradeRandProvider(address newRandProvider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGOO {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function allowance(address, address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function artGobblers() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function burnForGobblers(address from, uint256 amount) external;
    function burnForPages(address from, uint256 amount) external;
    function decimals() external view returns (uint8);
    function mintForGobblers(address to, uint256 amount) external;
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function pages() external view returns (address);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}