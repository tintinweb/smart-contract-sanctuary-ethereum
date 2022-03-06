// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/unstructured/UInitializable.sol";
import "@equilibria/root/unstructured/UReentrancyGuard.sol";
import "../interfaces/ICollateral.sol";
import "./types/OptimisticLedger.sol";
import "../factory/UFactoryProvider.sol";

/**
 * @title Collateral
 * @notice Manages logic and state for all collateral accounts in the protocol.
 */
contract Collateral is ICollateral, UInitializable, UFactoryProvider, UReentrancyGuard {
    using UFixed18Lib for UFixed18;
    using Token18Lib for Token18;
    using OptimisticLedgerLib for OptimisticLedger;

    /// @dev ERC20 stablecoin for collateral
    Token18 public token;

    /// @dev Fee on maintenance for liquidation
    UFixed18 public liquidationFee;

    /// @dev Per product collateral state
    mapping(IProduct => OptimisticLedger) private _products;

    /// @dev Protocol and product fees collected, but not yet claimed
    mapping(address => UFixed18) public fees;

    /**
     * @notice Initializes the contract state
     * @dev Must be called atomically as part of the upgradeable proxy deployment to
     *      avoid front-running
     * @param factory_ Factory contract address
     * @param token_ Collateral ERC20 stablecoin address
     */
    function initialize(IFactory factory_, Token18 token_) external initializer {
        __UFactoryProvider__initialize(factory_);
        __UReentrancyGuard__initialize();

        token = token_;
        liquidationFee = UFixed18Lib.ratio(50, 100);
    }

    /**
     * @notice Deposits `amount` collateral from `msg.sender` to `account`'s `product`
     *         account
     * @param account Account to deposit the collateral for
     * @param product Product to credit the collateral to
     * @param amount Amount of collateral to deposit
     */
    function depositTo(address account, IProduct product, UFixed18 amount)
    external
    notPaused
    nonReentrant
    notZeroAddress(account)
    isProduct(product)
    collateralInvariant(account, product)
    {
        _products[product].creditAccount(account, amount);
        token.pull(msg.sender, amount);

        emit Deposit(account, product, amount);
    }

    /**
     * @notice Withdraws `amount` collateral from `msg.sender`'s `product` account
     *         and sends it to `account`
     * @param account Account to withdraw the collateral to
     * @param product Product to withdraw the collateral from
     * @param amount Amount of collateral to withdraw
     */
    function withdrawTo(address account, IProduct product, UFixed18 amount)
    external
    notPaused
    nonReentrant
    notZeroAddress(account)
    isProduct(product)
    settleForAccount(msg.sender, product)
    collateralInvariant(msg.sender, product)
    maintenanceInvariant(msg.sender, product)
    {
        _products[product].debitAccount(msg.sender, amount);
        token.push(account, amount);

        emit Withdrawal(msg.sender, product, amount);
    }

    /**
     * @notice Liquidates `account`'s `product` collateral account
     * @dev Account must be under-collateralized, fee returned immediately to `msg.sender`
     * @param account Account to liquidate
     * @param product Product to liquidate for
     */
    function liquidate(address account, IProduct product)
    external
    notPaused
    nonReentrant
    isProduct(product)
    settleForAccount(account, product)
    {
        UFixed18 totalMaintenance = product.maintenance(account);
        UFixed18 totalCollateral = collateral(account, product);

        if (!totalMaintenance.gt(totalCollateral))
            revert CollateralCantLiquidate(totalMaintenance, totalCollateral);

        product.closeAll(account);

        // claim fee
        UFixed18 fee = UFixed18Lib.min(totalCollateral, totalMaintenance.mul(liquidationFee));

        _products[product].debitAccount(account, fee);
        token.push(msg.sender, fee);

        emit Liquidation(account, product, msg.sender, fee);
    }

    /**
     * @notice Credits `amount` to `account`'s collateral account
     * @dev Callable only by the corresponding product as part of the settlement flywheel.
     *      Moves collateral within a product, any collateral leaving the product due to
     *      fees has already been accounted for in the settleProduct flywheel.
     *      Debits in excess of the account balance get recorded as shortfall, and can be
     *      resolved by the product owner as needed.
     * @param account Account to credit
     * @param amount Amount to credit the account (can be negative)
     */
    function settleAccount(address account, Fixed18 amount) external onlyProduct {
        IProduct product = IProduct(msg.sender);

        UFixed18 newShortfall = _products[product].settleAccount(account, amount);

        emit AccountSettle(product, account, amount, newShortfall);
    }

    /**
     * @notice Debits `amount` from product's total collateral account
     * @dev Callable only by the corresponding product as part of the settlement flywheel
     *      Removes collateral from the product as fees.
     * @param amount Amount to debit from the account
     */
    function settleProduct(UFixed18 amount) external onlyProduct {
        (IProduct product, IFactory factory) = (IProduct(msg.sender), factory());

        address protocolTreasury = factory.treasury();
        address productTreasury = factory.treasury(product);

        UFixed18 protocolFee = amount.mul(factory.fee());
        UFixed18 productFee = amount.sub(protocolFee);

        _products[product].debit(amount);
        fees[protocolTreasury] = fees[protocolTreasury].add(protocolFee);
        fees[productTreasury] = fees[productTreasury].add(productFee);

        emit ProductSettle(product, protocolFee, productFee);
    }

    /**
     * @notice Returns the balance of `account`'s `product` collateral account
     * @param account Account to return for
     * @param product Product to return for
     * @return The balance of the collateral account
     */
    function collateral(address account, IProduct product) public view returns (UFixed18) {
        return _products[product].balances[account];
    }

    /**
     * @notice Returns the total balance of `product`'s collateral
     * @param product Product to return for
     * @return The total balance of collateral in the product
     */
    function collateral(IProduct product) external view returns (UFixed18) {
        return _products[product].total;
    }

    /**
     * @notice Returns the current shortfall of `product`'s collateral
     * @param product Product to return for
     * @return The current shortfall of the product
     */
    function shortfall(IProduct product) external view returns (UFixed18) {
        return _products[product].shortfall;
    }

    /**
     * @notice Returns whether `account`'s `product` collateral account can be liquidated
     * @param account Account to return for
     * @param product Product to return for
     * @return Whether the account can be liquidated
     */
    function liquidatable(address account, IProduct product) external view returns (bool) {
        return product.maintenance(account).gt(collateral(account, product));
    }

    /**
     * @notice Returns whether `account`'s `product` collateral account can be liquidated
     *         after the next oracle version settlement
     * @dev Takes into account the current pre-position on the account
     * @param account Account to return for
     * @param product Product to return for
     * @return Whether the account can be liquidated
     */
    function liquidatableNext(address account, IProduct product) external view returns (bool) {
        return product.maintenanceNext(account).gt(collateral(account, product));
    }

    /**
     * @notice Injects additional collateral into a product to resolve shortfall
     * @dev Shortfall is a measure of settled insolvency in the market
     *      This hook can be used by the product owner or an insurance fund to re-capitalize an insolvent market
     * @param product Product to resolve shortfall for
     * @param amount Amount of shortfall to resolve
     */
    function resolveShortfall(IProduct product, UFixed18 amount) external notPaused {
        _products[product].resolve(amount);
        token.pull(msg.sender, amount);

        emit ShortfallResolution(product, amount);
    }

    /**
     * @notice Claims all of `msg.sender`'s fees
     */
    function claimFee() external notPaused {
        UFixed18 amount = fees[msg.sender];

        fees[msg.sender] = UFixed18Lib.ZERO;
        token.push(msg.sender, amount);

        emit FeeClaim(msg.sender, amount);
    }

    /**
     * @notice Updates the liquidation fee
     * @param newLiquidationFee New liquidation fee
     */
    function updateLiquidationFee(UFixed18 newLiquidationFee) external onlyOwner {
        if (newLiquidationFee.gt(UFixed18Lib.ONE)) revert CollateralInvalidLiquidationFeeError();

        liquidationFee = newLiquidationFee;
        emit LiquidationFeeUpdated(newLiquidationFee);
    }

    /// @dev Ensure that the address is non-zero
    modifier notZeroAddress(address account) {
        if (account == address(0)) revert CollateralZeroAddressError();

        _;
    }

    /// @dev Ensure that the user has sufficient margin for both current and next maintenance
    modifier maintenanceInvariant(address account, IProduct product) {
        _;

        UFixed18 maintenance = product.maintenance(account);
        UFixed18 maintenanceNext = product.maintenanceNext(account);

        if (UFixed18Lib.max(maintenance, maintenanceNext).gt(collateral(account, product)))
            revert CollateralInsufficientCollateralError();
    }

    /// @dev Ensure that the account is either empty or above the collateral minimum
    modifier collateralInvariant(address account, IProduct product) {
        _;

        UFixed18 accountCollateral = collateral(account, product);
        if (!accountCollateral.isZero() && accountCollateral.lt(factory().minCollateral()))
            revert CollateralUnderLimitError();
    }

    /// @dev Helper to fully settle an account's state
    modifier settleForAccount(address account, IProduct product) {
        product.settle();
        product.settleAccount(account);

        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title UInitializable
 * @notice Library to manage the initialization lifecycle of upgradeable contracts
 * @dev `UInitializable` allows the creation of pseudo-constructors for upgradeable contracts. One
 *      `initializer` should be declared per top-level contract. Child contracts can use the `onlyInitializer`
 *      modifier to tag their internal initialization functions to ensure that they can only be called
 *      from a top-level `initializer` or a constructor.
 */
abstract contract UInitializable {
    error UInitializableCalledFromConstructorError();
    error UInitializableAlreadyInitializedError();
    error UInitializableNotInitializingError();

    /// @dev Unstructured storage slot for the initialized flag
    bytes32 private constant INITIALIZED_SLOT = keccak256("equilibria.utils.UInitializable.initialized");

    /// @dev Unstructured storage slot for the initializing flag
    bytes32 private constant INITIALIZING_SLOT = keccak256("equilibria.utils.UInitializable.initializing");

    /// @dev Can only be called once, and cannot be called from another initializer or constructor
    modifier initializer() {
        if (_constructing()) revert UInitializableCalledFromConstructorError();
        if (_initialized()) revert UInitializableAlreadyInitializedError();

        _setInitializing(true);
        _setInitialized(true);

        _;

        _setInitializing(false);
    }

    /// @dev Can only be called from an initializer or constructor
    modifier onlyInitializer() {
        if (!_constructing() && !_initializing())
            revert UInitializableNotInitializingError();
        _;
    }

    /**
     * @notice Returns whether the contract has been initialized
     * @return result Initialized flag
     */
    function _initialized() private view returns (bool result) {
        bytes32 slot = INITIALIZED_SLOT;
        assembly {
            result := sload(slot)
        }
    }

    /**
     * @notice Returns whether the contract is currently being initialized
     * @return result Initializing flag
     */
    function _initializing() private view returns (bool result) {
        bytes32 slot = INITIALIZING_SLOT;
        assembly {
            result := sload(slot)
        }
    }

    /**
     * @notice Sets the initialized flag in unstructured storage
     * @param newInitialized New initialized flag to store
     */
    function _setInitialized(bool newInitialized) private {
        bytes32 slot = INITIALIZED_SLOT;
        assembly {
            sstore(slot, newInitialized)
        }
    }

    /**
     * @notice Sets the initializing flag in unstructured storage
     * @param newInitializing New initializing flag to store
     */
    function _setInitializing(bool newInitializing) private {
        bytes32 slot = INITIALIZING_SLOT;
        assembly {
            sstore(slot, newInitializing)
        }
    }

    /**
     * @notice Returns whether the contract is currently being constructed
     * @dev {Address.isContract} returns false for contracts currently in the process of being constructed
     * @return Whether the contract is currently being constructed
     */
    function _constructing() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./UInitializable.sol";

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
 *
 * NOTE: This contract has been extended from the Open Zeppelin library to include an
 *       unstructured storage pattern, so that it can be safely mixed in with upgradeable
 *       contracts without affecting their storage patterns through inheritance.
 */
abstract contract UReentrancyGuard is UInitializable {
    error UReentrancyGuardReentrantCallError();

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

    /**
     * @dev unstructured storage slot for the reentrancy status
     */
    bytes32 private constant STATUS_SLOT = keccak256("equilibria.utils.UReentrancyGuard.status");

    /**
     * @dev Initializes the contract setting the status to _NOT_ENTERED.
     */
    function __UReentrancyGuard__initialize() internal onlyInitializer {
        _setStatus(_NOT_ENTERED);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function _status() private view returns (uint256 result) {
        bytes32 slot = STATUS_SLOT;
        assembly {
            result := sload(slot)
        }
    }

    function _setStatus(uint256 newStatus) private {
        bytes32 slot = STATUS_SLOT;
        assembly {
            sstore(slot, newStatus)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status() == _ENTERED) revert UReentrancyGuardReentrantCallError();

        // Any calls to nonReentrant after this point will fail
        _setStatus(_ENTERED);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setStatus(_NOT_ENTERED);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/UFixed18.sol";
import "@equilibria/root/types/Fixed18.sol";
import "@equilibria/root/types/Token.sol";
import "@equilibria/root/types/Token18.sol";
import "./IProduct.sol";

interface ICollateral {
    event Deposit(address indexed user, IProduct indexed product, UFixed18 amount);
    event Withdrawal(address indexed user, IProduct indexed product, UFixed18 amount);
    event AccountSettle(IProduct indexed product, address indexed account, Fixed18 amount, UFixed18 newShortfall);
    event ProductSettle(IProduct indexed product, UFixed18 protocolFee, UFixed18 productFee);
    event Liquidation(address indexed user, IProduct indexed product, address liquidator, UFixed18 fee);
    event ShortfallResolution(IProduct indexed product, UFixed18 amount);
    event LiquidationFeeUpdated(UFixed18 newLiquidationFeeUpdated);
    event FeeClaim(address indexed account, UFixed18 amount);

    error CollateralCantLiquidate(UFixed18 totalMaintenance, UFixed18 totalCollateral);
    error CollateralInsufficientCollateralError();
    error CollateralUnderLimitError();
    error CollateralInvalidLiquidationFeeError();
    error CollateralZeroAddressError();

    function token() external view returns (Token18);
    function liquidationFee() external view returns (UFixed18);
    function fees(address account) external view returns (UFixed18);
    function initialize(IFactory factory_, Token18 token_) external;
    function depositTo(address account, IProduct product, UFixed18 amount) external;
    function withdrawTo(address account, IProduct product, UFixed18 amount) external;
    function liquidate(address account, IProduct product) external;
    function settleAccount(address account, Fixed18 amount) external;
    function settleProduct(UFixed18 amount) external;
    function collateral(address account, IProduct product) external view returns (UFixed18);
    function collateral(IProduct product) external view returns (UFixed18);
    function shortfall(IProduct product) external view returns (UFixed18);
    function liquidatable(address account, IProduct product) external view returns (bool);
    function liquidatableNext(address account, IProduct product) external view returns (bool);
    function resolveShortfall(IProduct product, UFixed18 amount) external;
    function claimFee() external;
    function updateLiquidationFee(UFixed18 newLiquidationFee) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/UFixed18.sol";

/// @dev OptimisticLedger type
struct OptimisticLedger {
    /// @dev Individual account collateral balances
    mapping(address => UFixed18) balances;

    /// @dev Total ledger collateral balance
    UFixed18 total;

    /// @dev Total ledger collateral shortfall
    UFixed18 shortfall;
}

/**
 * @title OptimisticLedgerLib
 * @notice Library that manages a global vs account ledger where the global ledger is settled separately,
 *         and ahead of, the user-level accounts.
 * @dev    Ensures that no more collateral leaves the ledger than goes it, while allowing user-level accounts
 *         to settle as a follow up step. Overdrafts on the user-level are accounted as "shortall". Shortfall
 *         in the system is the quantity of insolvency that can be optionally resolved by the ledger owner.
 *         Until the shortfall is resolved, collateral may be withdrawn from the ledger on a FCFS basis. However
 *         once the ledger total has been depleted, users will not be able to withdraw even if they have non-zero
 *         user level balances until the shortfall is resolved, recapitalizing the ledger.
 */
library OptimisticLedgerLib {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;

    /**
     * @notice Credits `account` with `amount` collateral
     * @param self The struct to operate on
     * @param account Account to credit collateral to
     * @param amount Amount of collateral to credit
     */
    function creditAccount(OptimisticLedger storage self, address account, UFixed18 amount) internal {
        self.balances[account] = self.balances[account].add(amount);
        self.total = self.total.add(amount);
    }

    /**
     * @notice Debits `account` `amount` collateral
     * @param self The struct to operate on
     * @param account Account to debit collateral from
     * @param amount Amount of collateral to debit
     */
    function debitAccount(OptimisticLedger storage self, address account, UFixed18 amount) internal {
        self.balances[account] = self.balances[account].sub(amount);
        self.total = self.total.sub(amount);
    }

    /**
     * @notice Credits `account` with `amount` collateral
     * @dev Funds come from inside the product, not totals are updated
     *      Shortfall is created if more funds are debited from an account than exist
     * @param self The struct to operate on
     * @param account Account to credit collateral to
     * @param amount Amount of collateral to credit
     * @return newShortfall Any new shortfall incurred during this settlement
     */
    function settleAccount(OptimisticLedger storage self, address account, Fixed18 amount)
    internal returns (UFixed18 newShortfall) {
        Fixed18 newBalance = Fixed18Lib.from(self.balances[account]).add(amount);

        if (newBalance.sign() == -1) {
            newShortfall = newBalance.abs();
            newBalance = Fixed18Lib.ZERO;
        }

        self.balances[account] = newBalance.abs();
        self.shortfall = self.shortfall.add(newShortfall);
    }

    /**
     * @notice Debits ledger globally `amount` collateral
     * @dev Removes balance from total that is accounted for elsewhere (e.g. product-level accumulators)
     * @param self The struct to operate on
     * @param amount Amount of collateral to debit
     */
    function debit(OptimisticLedger storage self, UFixed18 amount) internal {
        self.total = self.total.sub(amount);
    }

    /**
     * @notice Reduces the amount of collateral shortfall in the ledger
     * @param self The struct to operate on
     * @param amount Amount of shortfall to resolve
     */
    function resolve(OptimisticLedger storage self, UFixed18 amount) internal {
        self.shortfall = self.shortfall.sub(amount);
        self.total = self.total.add(amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/unstructured/UInitializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IProduct.sol";

/**
 * @title UFactoryProvider
 * @notice Mix-in that manages a factory pointer and associated permissioning modifiers.
 * @dev Uses unstructured storage so that it is safe to mix-in to upgreadable contracts without modifying
 *      their storage layout.
 */
abstract contract UFactoryProvider is UInitializable {
    error AlreadyInitializedError();
    error NotOwnerError(address sender);
    error NotProductError(address sender);
    error NotCollateralError(address sender);
    error NotProductOwnerError(address sender, IProduct product);
    error PausedError();
    error InvalidFactoryError();

    /// @dev unstructured storage slot for the factory address
    bytes32 private constant FACTORY_SLOT = keccak256("equilibria.perennial.UFactoryProvider.factory");

    /**
     * @notice Initializes the contract state
     * @param factory_ Protocol Factory contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __UFactoryProvider__initialize(IFactory factory_) internal onlyInitializer {
        if (!Address.isContract(address(factory_))) revert InvalidFactoryError();

        _setFactory(factory_);
    }

    /**
     * @notice Reads the protocol Factory contract address from unstructured state
     * @return result Protocol Factory contract address
     */
    function factory() public view virtual returns (IFactory result) {
        bytes32 slot = FACTORY_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := sload(slot)
        }
    }

    /**
     * @notice Sets the protocol Factory contract address in unstructured state
     * @dev Internal helper
     */
    function _setFactory(IFactory newFactory) private {
        bytes32 slot = FACTORY_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newFactory)
        }
    }

    /// @dev Only allow a valid product contract to call
    modifier onlyProduct {
        if (!factory().isProduct(IProduct(msg.sender))) revert NotProductError(msg.sender);

        _;
    }

    /// @dev Verify that `product` is a valid product contract
    modifier isProduct(IProduct product) {
        if (!factory().isProduct(product)) revert NotProductError(address(product));

        _;
    }

    /// @dev Only allow the Collateral contract to call
    modifier onlyCollateral {
        if (msg.sender != address(factory().collateral())) revert NotCollateralError(msg.sender);

        _;
    }

    /// @dev Only allow the protocol owner contract to call
    modifier onlyOwner() {
        if (msg.sender != factory().owner()) revert NotOwnerError(msg.sender);

        _;
    }

    /// @dev Only allow if the the protocol is currently unpaused
    modifier notPaused() {
        if (factory().isPaused()) revert PausedError();

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Fixed18.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        return UFixed18.wrap(au < bu ? au : bu);
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        return UFixed18.wrap(au > bu ? au : bu);
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./UFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) return Fixed18.wrap(-1 * Fixed18.unwrap(from(m)));
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting subtracted signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        return Fixed18.wrap(au < bu ? au : bu);
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        return Fixed18.wrap(au > bu ? au : bu);
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        if (Fixed18.unwrap(a) < 0) return UFixed18.wrap(uint256(-1 * Fixed18.unwrap(a)));
        return UFixed18.wrap(uint256(Fixed18.unwrap(a)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./UFixed18.sol";

/// @dev Token
type Token is address;

/**
 * @title TokenLib
 * @notice Library to manage Ether and ERC20s that is compliant with the fixed-decimal types.
 * @dev Normalizes token operations with Ether operations (using a magic Ether address)
 *      Automatically converts from token decimal-Base amounts to Base-18 UFixed18 amounts, with optional rounding
 */
library TokenLib {
    using UFixed18Lib for UFixed18;
    using Address for address;
    using SafeERC20 for IERC20;

    error TokenPullEtherError();
    error TokenApproveEtherError();

    uint256 private constant BASE = 1e18;
    Token public constant ETHER = Token.wrap(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));

    /**
     * @notice Returns whether a token is the Ether address
     * @param self Token to check for
     * @return Whether the token is Ether
     */
    function isEther(Token self) internal pure returns (bool) {
        return Token.unwrap(self) == Token.unwrap(ETHER);
    }

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     */
    function approve(Token self, address grantee) internal {
        if (isEther(self)) revert TokenApproveEtherError();
        IERC20(Token.unwrap(self)).safeApprove(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token self, address grantee, UFixed18 amount) internal {
        if (isEther(self)) revert TokenApproveEtherError();
        IERC20(Token.unwrap(self)).safeApprove(grantee, toTokenAmount(self, amount, false));
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function approve(Token self, address grantee, UFixed18 amount, bool roundUp) internal {
        if (isEther(self)) revert TokenApproveEtherError();
        IERC20(Token.unwrap(self)).safeApprove(grantee, toTokenAmount(self, amount, roundUp));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token self, address recipient, UFixed18 amount) internal {
        isEther(self)
            ? Address.sendValue(payable(recipient), UFixed18.unwrap(amount))
            : IERC20(Token.unwrap(self)).safeTransfer(recipient, toTokenAmount(self, amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function push(Token self, address recipient, UFixed18 amount, bool roundUp) internal {
        isEther(self)
            ? Address.sendValue(payable(recipient), UFixed18.unwrap(amount))
            : IERC20(Token.unwrap(self)).safeTransfer(recipient, toTokenAmount(self, amount, roundUp));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token self, address benefactor, UFixed18 amount) internal {
        if (isEther(self)) revert TokenPullEtherError();
        IERC20(Token.unwrap(self)).safeTransferFrom(benefactor, address(this), toTokenAmount(self, amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function pull(Token self, address benefactor, UFixed18 amount, bool roundUp) internal {
        if (isEther(self)) revert TokenPullEtherError();
        IERC20(Token.unwrap(self)).safeTransferFrom(benefactor, address(this), toTokenAmount(self, amount, roundUp));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token self, address benefactor, address recipient, UFixed18 amount) internal {
        if (isEther(self)) revert TokenPullEtherError();
        IERC20(Token.unwrap(self)).safeTransferFrom(benefactor, recipient, toTokenAmount(self, amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function pullTo(Token self, address benefactor, address recipient, UFixed18 amount, bool roundUp) internal {
        if (isEther(self)) revert TokenPullEtherError();
        IERC20(Token.unwrap(self)).safeTransferFrom(benefactor, recipient, toTokenAmount(self, amount, roundUp));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token self) internal view returns (string memory) {
        return isEther(self) ? "Ether" : IERC20Metadata(Token.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token self) internal view returns (string memory) {
        return isEther(self) ? "ETH" : IERC20Metadata(Token.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the decimals of the token
     * @param self Token to check for
     * @return Token decimals
     */
    function decimals(Token self) internal view returns (uint256) {
        return isEther(self) ? 18 : uint256(IERC20Metadata(Token.unwrap(self)).decimals());
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token self, address account) internal view returns (UFixed18) {
        return isEther(self) ?
            UFixed18.wrap(account.balance) :
            fromTokenAmount(self, IERC20(Token.unwrap(self)).balanceOf(account));
    }

    /**
     * @notice Converts the unsigned fixed-decimal amount into the token amount according to
     *         it's defined decimals
     * @param self Token to check for
     * @param amount Amount to convert
     * @return Normalized token amount
     */
    function toTokenAmount(Token self, UFixed18 amount, bool roundUp) private view returns (uint256) {
        uint256 tokenDecimals = decimals(self);

        if (tokenDecimals < 18) {
            uint256 offset = 10 ** (18 - tokenDecimals);
            return roundUp ? Math.ceilDiv(UFixed18.unwrap(amount), offset) : UFixed18.unwrap(amount) / offset;
        } else {
            uint256 offset = 10 ** (tokenDecimals - 18);
            return UFixed18.unwrap(amount) * offset;
        }
    }

    /**
     * @notice Converts the token amount into the unsigned fixed-decimal amount according to
     *         it's defined decimals
     * @param self Token to check for
     * @param amount Token amount to convert
     * @return Normalized unsigned fixed-decimal amount
     */
    function fromTokenAmount(Token self, uint256 amount) private view returns (UFixed18) {
        UFixed18 conversion = UFixed18Lib.ratio(BASE, 10 ** uint256(decimals(self)));
        return UFixed18.wrap(amount).mul(conversion);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UFixed18.sol";

/// @dev Token18
type Token18 is address;

/**
 * @title Token18Lib
 * @notice Library to manage 18-decimal ERC20s that is compliant with the fixed-decimal types.
 * @dev Maintains significant gas savings over other Token implementations since no conversion take place
 */
library Token18Lib {
    using UFixed18Lib for UFixed18;
    using SafeERC20 for IERC20;

    uint256 private constant DECIMALS = 18;

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     */
    function approve(Token18 self, address grantee) internal {
        IERC20(Token18.unwrap(self)).safeApprove(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token18 self, address grantee, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeApprove(grantee, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token18 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token18 self, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransfer(recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token18 self, address benefactor, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, address(this), UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token18 self, address benefactor, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the decimals of the token
     * @return Token decimals
     */
    function decimals(Token18) internal pure returns (uint256) {
        return DECIMALS;
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token18 self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token18 self, address account) internal view returns (UFixed18) {
        return UFixed18.wrap(IERC20(Token18.unwrap(self)).balanceOf(account));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/UFixed18.sol";
import "../product/types/position/Position.sol";
import "../product/types/position/PrePosition.sol";
import "../product/types/accumulator/Accumulator.sol";

interface IProduct {
    event Settle(uint256 preVersion, uint256 toVersion);
    event AccountSettle(address indexed account, uint256 preVersion, uint256 toVersion);
    event MakeOpened(address indexed account, UFixed18 amount);
    event TakeOpened(address indexed account, UFixed18 amount);
    event MakeClosed(address indexed account, UFixed18 amount);
    event TakeClosed(address indexed account, UFixed18 amount);

    error ProductInsufficientLiquidityError(UFixed18 socializationFactor);
    error ProductDoubleSidedError();
    error ProductOverClosedError();
    error ProductInsufficientCollateralError();
    error ProductInLiquidationError();
    error ProductMakerOverLimitError();
    error ProductOracleBootstrappingError();

    function provider() external view returns (IProductProvider);
    function initialize(IProductProvider provider_) external;
    function settle() external;
    function settleAccount(address account) external;
    function openTake(UFixed18 amount) external;
    function closeTake(UFixed18 amount) external;
    function openMake(UFixed18 amount) external;
    function closeMake(UFixed18 amount) external;
    function closeAll(address account) external;
    function maintenance(address account) external view returns (UFixed18);
    function maintenanceNext(address account) external view returns (UFixed18);
    function isClosed(address account) external view returns (bool);
    function isLiquidating(address account) external view returns (bool);
    function position(address account) external view returns (Position memory);
    function pre(address account) external view returns (PrePosition memory);
    function latestVersion() external view returns (uint256);
    function positionAtVersion(uint256 oracleVersion) external view returns (Position memory);
    function pre() external view returns (PrePosition memory);
    function valueAtVersion(uint256 oracleVersion) external view returns (Accumulator memory);
    function shareAtVersion(uint256 oracleVersion) external view returns (Accumulator memory);
    function latestVersion(address account) external view returns (uint256);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@equilibria/root/types/UFixed18.sol";
import "../accumulator/Accumulator.sol";
import "./PrePosition.sol";

/// @dev Position type
struct Position {
    /// @dev Quantity of the maker position
    UFixed18 maker;
    /// @dev Quantity of the taker position
    UFixed18 taker;
}

/**
 * @title PositionLib
 * @notice Library that surfaces math and settlement computations for the Position type.
 * @dev Positions track the current quantity of the account's maker and taker positions respectively
 *      denominated as a unit of the product's payoff function.
 */
library PositionLib {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;
    using PrePositionLib for PrePosition;

    function isEmpty(Position memory self) internal pure returns (bool) {
        return self.maker.isZero() && self.taker.isZero();
    }

    /**
     * @notice Adds position `a` and `b` together, returning the result
     * @param a The first position to sum
     * @param b The second position to sum
     * @return Resulting summed position
     */
    function add(Position memory a, Position memory b) internal pure returns (Position memory) {
        return Position({maker: a.maker.add(b.maker), taker: a.taker.add(b.taker)});
    }

    /**
     * @notice Subtracts position `b` from `a`, returning the result
     * @param a The position to subtract from
     * @param b The position to subtract
     * @return Resulting subtracted position
     */
    function sub(Position memory a, Position memory b) internal pure returns (Position memory) {
        return Position({maker: a.maker.sub(b.maker), taker: a.taker.sub(b.taker)});
    }

    /**
     * @notice Multiplies position `self` by accumulator `accumulator` and returns the resulting accumulator
     * @param self The Position to operate on
     * @param accumulator The accumulator to multiply by
     * @return Resulting multiplied accumulator
     */
    function mul(Position memory self, Accumulator memory accumulator) internal pure returns (Accumulator memory) {
        return Accumulator({
            maker: Fixed18Lib.from(self.maker).mul(accumulator.maker),
            taker: Fixed18Lib.from(self.taker).mul(accumulator.taker)
        });
    }

    /**
     * @notice Scales position `self` by fixed-decimal `scale` and returns the resulting position
     * @param self The Position to operate on
     * @param scale The Fixed-decimal to scale by
     * @return Resulting scaled position
     */
    function mul(Position memory self, UFixed18 scale) internal pure returns (Position memory) {
        return Position({maker: self.maker.mul(scale), taker: self.taker.mul(scale)});
    }

    /**
     * @notice Divides position `self` by `b` and returns the resulting accumulator
     * @param self The Position to operate on
     * @param b The number to divide by
     * @return Resulting divided accumulator
     */
    function div(Position memory self, uint256 b) internal pure returns (Accumulator memory) {
        return Accumulator({
            maker: Fixed18Lib.from(self.maker).div(Fixed18Lib.from(UFixed18Lib.from(b))),
            taker: Fixed18Lib.from(self.taker).div(Fixed18Lib.from(UFixed18Lib.from(b)))
        });
    }

    /**
     * @notice Returns the maximum of `self`'s maker and taker values
     * @param self The struct to operate on
     * @return Resulting maximum value
     */
    function max(Position memory self) internal pure returns (UFixed18) {
        return UFixed18Lib.max(self.maker, self.taker);
    }

    /**
     * @notice Sums the maker and taker together from a single position
     * @param self The struct to operate on
     * @return The sum of its maker and taker
     */
    function sum(Position memory self) internal pure returns (UFixed18) {
        return self.maker.add(self.taker);
    }

    /**
     * @notice Computes the next position after the pending-settlement position delta is included
     * @param self The current Position
     * @param pre The pending-settlement position delta
     * @return Next Position
     */
    function next(Position memory self, PrePosition memory pre) internal pure returns (Position memory) {
        return sub(add(self, pre.openPosition), pre.closePosition);
    }

    /**
     * @notice Returns the settled position at oracle version `toOracleVersion`
     * @dev Checks if a new position is ready to be settled based on the provided `toOracleVersion`
     *      and `pre` and returns accordingly
     * @param self The current Position
     * @param pre The pending-settlement position delta
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to settle to
     * @return Settled position at oracle version
     * @return Fee accrued from opening or closing the position
     * @return Whether a new position was settled
     */
    function settled(Position memory self, PrePosition memory pre, IProductProvider provider, uint256 toOracleVersion) internal view returns (Position memory, UFixed18, bool) {
        return pre.canSettle(toOracleVersion) ? (next(self, pre), pre.computeFee(provider, toOracleVersion), true) : (self, UFixed18Lib.ZERO, false);
    }

    /**
     * @notice Returns the socialization factor for the current position
     * @dev Socialization account for the case where `taker` > `maker` temporarily due to a liquidation
     *      on the maker side. This dampens the taker's exposure pro-rata to ensure that the maker side
     *      is never exposed over 1 x short.
     * @param self The Position to operate on
     * @return Socialization factor
     */
    function socializationFactor(Position memory self) internal pure returns (UFixed18) {
        return self.taker.isZero() ? UFixed18Lib.ONE : UFixed18Lib.min(UFixed18Lib.ONE, self.maker.div(self.taker));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./Position.sol";
import "../ProductProvider.sol";

/// @dev PrePosition type
struct PrePosition {
    /// @dev Oracle version at which the new position delta was recorded
    uint256 oracleVersion;

    /// @dev Size of position to open at oracle version
    Position openPosition;

    /// @dev Size of position to close at oracle version
    Position closePosition;
}

/**
 * @title PrePositionLib
 * @notice Library that manages a pre-settlement position delta.
 * @dev PrePositions track the currently awaiting-settlement deltas to a settled Position. These are
 *      Primarily necessary to introduce lag into the settlement system such that oracle lag cannot be
 *      gamed to a user's advantage. When a user opens or closes a new position, it sits as a PrePosition
 *      for one oracle version until it's settle into the Position, making it then effective. PrePositions
 *      are automatically settled at the correct oracle version even if a flywheel call doesn't happen until
 *      several version into the future by using the historical version lookups in the corresponding "Versioned"
 *      global state types.
 */
library PrePositionLib {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;
    using PositionLib for Position;
    using ProductProviderLib for IProductProvider;

    /**
     * @notice Returns whether there is no pending-settlement position delta
     * @dev Can be "empty" even with a non-zero oracleVersion if a position is opened and
     *      closed in the same version netting out to a zero position delta
     * @param self The struct to operate on
     * @return Whether the pending-settlement position delta is empty
     */
    function isEmpty(PrePosition memory self) internal pure returns (bool) {
        return self.openPosition.isEmpty() && self.closePosition.isEmpty();
    }

    /**
     * @notice Increments the maker side of the open position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The position amount to open
     */
    function openMake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.openPosition.maker = self.openPosition.maker.add(amount);
        self.oracleVersion = currentVersion;
        netMake(self);
    }

    /**
     * @notice Increments the maker side of the close position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The maker position amount to close
     */
    function closeMake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.closePosition.maker = self.closePosition.maker.add(amount);
        self.oracleVersion = currentVersion;
        netMake(self);
    }

    /**
     * @notice Increments the taker side of the open position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The taker position amount to open
     */
    function openTake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.openPosition.taker = self.openPosition.taker.add(amount);
        self.oracleVersion = currentVersion;
        netTake(self);
    }

    /**
     * @notice Increments the taker side of the close position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The taker position amount to close
     */
    function closeTake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.closePosition.taker = self.closePosition.taker.add(amount);
        self.oracleVersion = currentVersion;
        netTake(self);
    }

    /**
     * @notice Nets out the open and close on the maker side of the position delta
     * @param self The struct to operate on
     */
    function netMake(PrePosition storage self) private {
        if (self.openPosition.maker.gt(self.closePosition.maker)) {
            self.openPosition.maker = self.openPosition.maker.sub(self.closePosition.maker);
            self.closePosition.maker = UFixed18Lib.ZERO;
        } else {
            self.closePosition.maker = self.closePosition.maker.sub(self.openPosition.maker);
            self.openPosition.maker = UFixed18Lib.ZERO;
        }
    }

    /**
     * @notice Nets out the open and close on the taker side of the position delta
     * @param self The struct to operate on
     */
    function netTake(PrePosition storage self) private {
        if (self.openPosition.taker.gt(self.closePosition.taker)) {
            self.openPosition.taker = self.openPosition.taker.sub(self.closePosition.taker);
            self.closePosition.taker = UFixed18Lib.ZERO;
        } else {
            self.closePosition.taker = self.closePosition.taker.sub(self.openPosition.taker);
            self.openPosition.taker = UFixed18Lib.ZERO;
        }
    }

    /**
     * @notice Returns whether the the pending position delta can be settled at version `toOracleVersion`
     * @dev Pending-settlement positions deltas can be settled (1) oracle version after they are recorded
     * @param self The struct to operate on
     * @param toOracleVersion The potential oracle version to settle
     * @return Whether the position delta can be settled
     */
    function canSettle(PrePosition memory self, uint256 toOracleVersion) internal pure returns (bool) {
        return !isEmpty(self) && toOracleVersion > self.oracleVersion;
    }

    /**
     * @notice Computes the fee incurred for opening or closing the pending-settlement position
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version at which settlement takes place
     * @return positionFee The maker / taker fee incurred
     */
    function computeFee(PrePosition memory self, IProductProvider provider, uint256 toOracleVersion) internal view returns (UFixed18) {
        Fixed18 oraclePrice = provider.atVersion(toOracleVersion).price;
        Position memory positionDelta = self.openPosition.add(self.closePosition);

        (UFixed18 makerNotional, UFixed18 takerNotional) = (
            Fixed18Lib.from(positionDelta.maker).mul(oraclePrice).abs(),
            Fixed18Lib.from(positionDelta.taker).mul(oraclePrice).abs()
        );

        return makerNotional.mul(provider.safeMakerFee()).add(takerNotional.mul(provider.safeTakerFee()));
    }

    /**
     * @notice Computes the next oracle version to settle
     * @dev - If there is no pending-settlement position delta, returns the current oracle version
     *      - If the pending-settlement position delta is not yet ready to be settled, returns the current oracle version
     *      - Otherwise returns the oracle version at which the pending-settlement position delta can be first settled
     *
     *      Corresponds to point (b) in the Position settlement flow
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @return Next oracle version to settle
     */
    function oracleVersionToSettle(PrePosition storage self, uint256 currentVersion) internal view returns (uint256) {
        uint256 next = self.oracleVersion + 1;

        if (next == 1) return currentVersion;             // no pre position
        if (next > currentVersion) return currentVersion; // pre in future
        return next;                                      // settle pre
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/Fixed18.sol";

/// @dev Accumulator type
struct Accumulator {
    /// @dev maker accumulator per share
    Fixed18 maker;
    /// @dev taker accumulator per share
    Fixed18 taker;
}

/**
 * @title AccountAccumulatorLib
 * @notice Library that surfaces math operations for the Accumulator type.
 * @dev Accumulators track the cumulative change in position value over time for the maker and taker positions
 *      respectively. Account-level accumulators can then use two of these values `a` and `a'` to compute the
 *      change in position value since last sync. This change in value is then used to compute P&L and fees.
 */
library AccumulatorLib {
    using Fixed18Lib for Fixed18;

    /**
     * @notice Adds two accumulators together
     * @param a The first accumulator to sum
     * @param b The second accumulator to sum
     * @return The resulting summed accumulator
     */
    function add(Accumulator memory a, Accumulator memory b) internal pure returns (Accumulator memory) {
        return Accumulator({maker: a.maker.add(b.maker), taker: a.taker.add(b.taker)});
    }

    /**
     * @notice Subtracts accumulator `b` from `a`
     * @param a The accumulator to subtract from
     * @param b The accumulator to subtract
     * @return The resulting subtracted accumulator
     */
    function sub(Accumulator memory a, Accumulator memory b) internal pure returns (Accumulator memory) {
        return Accumulator({maker: a.maker.sub(b.maker), taker: a.taker.sub(b.taker)});
    }

    /**
     * @notice Multiplies two accumulators together
     * @param a The first accumulator to multiply
     * @param b The second accumulator to multiply
     * @return The resulting multiplied accumulator
     */
    function mul(Accumulator memory a, Accumulator memory b) internal pure returns (Accumulator memory) {
        return Accumulator({maker: a.maker.mul(b.maker), taker: a.taker.mul(b.taker)});
    }

    /**
     * @notice Sums the maker and taker together from a single accumulator
     * @param self The struct to operate on
     * @return The sum of its maker and taker
     */
    function sum(Accumulator memory self) internal pure returns (Fixed18) {
        return self.maker.add(self.taker);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/UFixed18.sol";
import "../../interfaces/IProductProvider.sol";
import "../../interfaces/IFactory.sol";

/**
 * @title ProductProviderLib
 * @notice Library that adds a safeguard wrapper to certain product parameters.
 * @dev Product providers are semi-untrusted as they contain custom code from the product owners. Owners
 *      have full control over this parameter-setting code, however there are some "known ranges" that
 *      a parameter cannot be outside of (i.e. a fee being over 100%).
 */
library ProductProviderLib {
    using UFixed18Lib for UFixed18;

    /**
     * @notice Returns the minimum funding fee parameter with a capped range for safety
     * @dev Caps factory.minFundingFee() <= self.minFundingFee() <= 1
     * @param self The parameter provider to operate on
     * @param factory The protocol Factory contract
     * @return Safe minimum funding fee parameter
     */
    function safeFundingFee(IProductProvider self, IFactory factory) internal view returns (UFixed18) {
        return self.fundingFee().max(factory.minFundingFee()).min(UFixed18Lib.ONE);
    }

    /**
     * @notice Returns the maker fee parameter with a capped range for safety
     * @dev Caps self.makerFee() <= 1
     * @param self The parameter provider to operate on
     * @return Safe maker fee parameter
     */
    function safeMakerFee(IProductProvider self) internal view returns (UFixed18) {
        return self.makerFee().min(UFixed18Lib.ONE);
    }

    /**
     * @notice Returns the taker fee parameter with a capped range for safety
     * @dev Caps self.takerFee() <= 1
     * @param self The parameter provider to operate on
     * @return Safe taker fee parameter
     */
    function safeTakerFee(IProductProvider self) internal view returns (UFixed18) {
        return self.takerFee().min(UFixed18Lib.ONE);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/UFixed18.sol";
import "@equilibria/root/types/Fixed18.sol";
import "./IOracle.sol";
import "../product/types/position/Position.sol";

interface IProductProvider is IOracle {
    function name() external view returns (string memory);
    function rate(Position memory position) external view returns (Fixed18);
    function payoff(OracleVersion memory oracleVersion) external view returns (OracleVersion memory);
    function maintenance() external view returns (UFixed18);
    function fundingFee() external view returns (UFixed18);
    function makerFee() external view returns (UFixed18);
    function takerFee() external view returns (UFixed18);
    function makerLimit() external view returns (UFixed18);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/UFixed18.sol";
import "./ICollateral.sol";
import "./IIncentivizer.sol";
import "./IProduct.sol";
import "./IProductProvider.sol";

interface IFactory {
    /// @dev Controller of a one or many products
    struct Controller {
        /// @dev Pending owner of the product, can accept ownership
        address pendingOwner;

        /// @dev Owner of the product, allowed to update select parameters
        address owner;

        /// @dev Treasury of the product, collects fees
        address treasury;
    }

    event CollateralUpdated(ICollateral newCollateral);
    event IncentivizerUpdated(IIncentivizer newIncentivizer);
    event ProductBaseUpdated(IProduct newProductBase);
    event FeeUpdated(UFixed18 newFee);
    event MinFundingFeeUpdated(UFixed18 newMinFundingFee);
    event MinCollateralUpdated(UFixed18 newMinCollateral);
    event ControllerTreasuryUpdated(uint256 indexed controllerId, address newTreasury);
    event ControllerPendingOwnerUpdated(uint256 indexed controllerId, address newPendingOwner);
    event ControllerOwnerUpdated(uint256 indexed controllerId, address newOwner);
    event AllowedUpdated(uint256 indexed controllerId, bool allowed);
    event PauserUpdated(address pauser);
    event IsPausedUpdated(bool isPaused);
    event ControllerCreated(uint256 indexed controllerId, address owner, address treasury);
    event ProductCreated(IProduct indexed product, IProductProvider provider);

    error FactoryAlreadyInitializedError();
    error FactoryNoZeroControllerError();
    error FactoryNotAllowedError();
    error FactoryNotPauserError(address sender);
    error FactoryNotOwnerError(uint256 controllerId);
    error FactoryNotPendingOwnerError(uint256 controllerId);
    error FactoryInvalidFeeError();
    error FactoryInvalidMinFundingFeeError();

    function pauser() external view returns (address);
    function isPaused() external view returns (bool);
    function collateral() external view returns (ICollateral);
    function incentivizer() external view returns (IIncentivizer);
    function productBase() external view returns (IProduct);
    function controllers(uint256 collateralId) external view returns (Controller memory);
    function controllerFor(IProduct product) external view returns (uint256);
    function allowed(uint256 collateralId) external view returns (bool);
    function fee() external view returns (UFixed18);
    function minFundingFee() external view returns (UFixed18);
    function minCollateral() external view returns (UFixed18);
    function initialize(ICollateral collateral_, IIncentivizer incentivizer_, IProduct productBase_, address treasury_) external;
    function createController(address controllerTreasury) external returns (uint256);
    function updateControllerTreasury(uint256 controllerId, address newTreasury) external;
    function updateControllerPendingOwner(uint256 controllerId, address newPendingOwner) external;
    function acceptControllerOwner(uint256 controllerId) external;
    function createProduct(uint256 controllerId, IProductProvider provider) external returns (IProduct);
    function updateCollateral(ICollateral newCollateral) external;
    function updateIncentivizer(IIncentivizer newIncentivizer) external;
    function updateProductBase(IProduct newProductBase) external;
    function updateFee(UFixed18 newFee) external;
    function updateMinFundingFee(UFixed18 newMinFundingFee) external;
    function updateMinCollateral(UFixed18 newMinCollateral) external;
    function updatePauser(address newPauser) external;
    function updateIsPaused(bool newIsPaused) external;
    function updateAllowed(uint256 controllerId, bool newAllowed) external;
    function isProduct(IProduct product) external view returns (bool);
    function owner() external view returns (address);
    function owner(uint256 controllerId) external view returns (address);
    function owner(IProduct product) external view returns (address);
    function treasury() external view returns (address);
    function treasury(uint256 controllerId) external view returns (address);
    function treasury(IProduct product) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/Fixed18.sol";

interface IOracle {
    //TODO: finalize location
    struct OracleVersion {
        uint256 version;
        uint256 timestamp;
        Fixed18 price;
    }

    function sync() external returns (OracleVersion memory);
    function currentVersion() external view returns (OracleVersion memory);
    function atVersion(uint256 oracleVersion) external view returns (OracleVersion memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/Token.sol";
import "@equilibria/root/types/UFixed18.sol";
import "@equilibria/root/types/Fixed18.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IProduct.sol";
import "../incentivizer/types/ProgramInfo.sol";

interface IIncentivizer {
    event ProgramsPerProductUpdated(uint256 newProgramsPerProduct);
    event FeeUpdated(UFixed18 newFee);
    event ProgramCompleted(uint256 indexed programId, uint256 versionComplete);
    event ProgramClosed(uint256 indexed programId, UFixed18 amount);
    event ProgramCreated(uint256 indexed programId, IProduct product, Token token, UFixed18 amountMaker, UFixed18 amountTaker, uint256 start, uint256 duration, uint256 grace, UFixed18 fee);
    event Claim(address indexed account, uint256 indexed programId, UFixed18 amount);
    event FeeClaim(Token indexed token, UFixed18 amount);

    error IncentivizerProgramNotClosableError();
    error IncentivizerTooManyProgramsError();
    error IncentivizerNotProgramOwnerError(address sender, uint256 programId);
    error IncentivizerInvalidProgramError(uint256 programId);
    error IncentivizerInvalidFeeError();

    function programsPerProduct() external view returns (uint256);
    function fee() external view returns (UFixed18);
    function programInfos(uint256 programId) external view returns (ProgramInfo memory);
    function fees(Token token) external view returns (UFixed18);
    function initialize(IFactory factory_) external;
    function create(ProgramInfo calldata info) external returns (uint256);
    function end(uint256 programId) external;
    function close(uint256 programId) external;
    function sync() external;
    function syncAccount(address account) external;
    function claim(IProduct product) external;
    function claim(uint256 programId) external;
    function claimFee(Token[] calldata tokens) external;
    function unclaimed(address account, uint256 programId) external view returns (UFixed18);
    function latestVersion(address account, uint256 programId) external view returns (uint256);
    function settled(address account, uint256 programId) external view returns (UFixed18);
    function available(uint256 programId) external view returns (UFixed18);
    function versionComplete(uint256 programId) external view returns (uint256);
    function closed(uint256 programId) external view returns (bool);
    function programsForLength(IProduct product) external view returns (uint256);
    function programsForAt(IProduct product, uint256 index) external view returns (uint256);
    function owner(uint256 programId) external view returns (address);
    function treasury(uint256 programId) external view returns (address);
    function updateProgramsPerProduct(uint256 newProgramsPerProduct) external;
    function updateFee(UFixed18 newFee) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/types/Token.sol";
import "../../interfaces/IProduct.sol";
import "../../product/types/position/Position.sol";
import "../../product/types/accumulator/Accumulator.sol";

struct ProgramInfo {
    /// @dev Amount of total maker and taker rewards
    Position amount;

    /// @dev start timestamp of the program
    uint256 start;

    /// @dev duration of the program (in seconds)
    uint256 duration;

    /// @dev grace period the program where funds can still be claimed (in seconds)
    uint256 grace;

    /// @dev Product market contract to be incentivized
    IProduct product;

    /// @dev Reward ERC20 token contract
    Token token;
}

library ProgramInfoLib {
    using UFixed18Lib for UFixed18;
    using PositionLib for Position;

    uint256 private constant MIN_DURATION = 1 days;
    uint256 private constant MAX_DURATION = 2 * 365 days;
    uint256 private constant MIN_GRACE = 7 days;
    uint256 private constant MAX_GRACE = 30 days;

    error ProgramAlreadyStartedError();
    error ProgramInvalidDurationError();
    error ProgramInvalidGraceError();

    /**
     * @notice Validates and creates a new Program
     * @param fee Global Incentivizer fee
     * @param info Un-sanitized static program information
     * @return programInfo Validated static program information with fee excluded
     * @return programFee Fee amount for the program
     */
    function create(UFixed18 fee, ProgramInfo memory info)
    internal view returns (ProgramInfo memory programInfo, UFixed18 programFee) {
        if (isStarted(info, block.timestamp)) revert ProgramAlreadyStartedError();
        if (info.duration < MIN_DURATION || info.duration > MAX_DURATION) revert ProgramInvalidDurationError();
        if (info.grace < MIN_GRACE || info.grace > MAX_GRACE) revert ProgramInvalidGraceError();

        Position memory amountAfterFee = info.amount.mul(UFixed18Lib.ONE.sub(fee));

        programInfo = ProgramInfo({
            start: info.start,
            duration: info.duration,
            grace: info.grace,

            product: info.product,
            token: info.token,
            amount: amountAfterFee
        });
        programFee = info.amount.sub(amountAfterFee).sum();
    }

    /**
     * @notice Returns the maker and taker amounts per position share
     * @param self The ProgramInfo to operate on
     * @return programFee Amounts per share
     */
    function amountPerShare(ProgramInfo memory self) internal pure returns (Accumulator memory) {
        return self.amount.div(self.duration);
    }

    /**
     * @notice Returns whether the program has started by timestamp `timestamp`
     * @param self The ProgramInfo to operate on
     * @param timestamp Timestamp to check for
     * @return Whether the program has started
     */
    function isStarted(ProgramInfo memory self, uint256 timestamp) internal pure returns (bool) {
        return timestamp >= self.start;
    }

    /**
     * @notice Returns whether the program is completed by timestamp `timestamp`
     * @param self The ProgramInfo to operate on
     * @param timestamp Timestamp to check for
     * @return Whether the program is completed
     */
    function isComplete(ProgramInfo memory self, uint256 timestamp) internal pure returns (bool) {
        return timestamp >= (self.start + self.duration);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/unstructured/UInitializable.sol";
import "@equilibria/root/unstructured/UReentrancyGuard.sol";
import "../interfaces/IProduct.sol";
import "../interfaces/IProductProvider.sol";
import "./types/position/AccountPosition.sol";
import "./types/accumulator/AccountAccumulator.sol";
import "../factory/UFactoryProvider.sol";

/**
 * @title Product
 * @notice Manages logic and state for a single product market.
 * @dev Cloned by the Factory contract to launch new product markets.
 */
contract Product is IProduct, UInitializable, UFactoryProvider, UReentrancyGuard {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;
    using AccumulatorLib for Accumulator;
    using PositionLib for Position;
    using PrePositionLib for PrePosition;
    using AccountAccumulatorLib for AccountAccumulator;
    using VersionedAccumulatorLib for VersionedAccumulator;
    using AccountPositionLib for AccountPosition;
    using VersionedPositionLib for VersionedPosition;

    /// @dev The parameter provider of the product market
    IProductProvider public provider;

    /// @dev The individual position state for each account
    mapping(address => AccountPosition) private _positions;

    /// @dev The global position state for the product
    VersionedPosition private _position;

    /// @dev The individual accumulator state for each account
    mapping(address => AccountAccumulator) private _accumulators;

    /// @dev The global accumulator state for the product
    VersionedAccumulator private _accumulator;

    /**
     * @notice Initializes the contract state
     * @param provider_ Product provider contract address
     */
    function initialize(IProductProvider provider_) external initializer {
        __UFactoryProvider__initialize(IFactory(msg.sender));
        __UReentrancyGuard__initialize();

        provider = provider_;
    }

    /**
     * @notice Surfaces global settlement externally
     */
    function settle() external nonReentrant notPaused {
        settleInternal();
    }

    /**
     * @notice Core global settlement flywheel
     * @dev
     *  a) last settle oracle version
     *  b) latest pre position oracle version
     *  c) current oracle version
     *
     *  Settles from a->b then from b->c if either interval is non-zero to account for a change
     *  in position quantity at (b).
     *
     *  Syncs each to instantaneously after the oracle update.
     */
    function settleInternal() internal {
        (IProductProvider _provider, IFactory _factory) = (provider, factory());

        IOracle.OracleVersion memory currentVersion = _provider.sync();
        _factory.incentivizer().sync();

        uint256 oracleVersionPreSettle = _position.pre.oracleVersionToSettle(currentVersion.version);
        uint256 oracleVersionCurrent = currentVersion.version;
        if (latestVersion() == oracleVersionCurrent) return; // short circuit entirety if a == c

        UFixed18 accumulatedFee;

        // value a->b
        accumulatedFee = accumulatedFee.add(_accumulator.accumulate(_position, _factory, _provider, oracleVersionPreSettle));

        // position a->b
        accumulatedFee = accumulatedFee.add(_position.settle(_provider, oracleVersionPreSettle));

        // short-circuit from a->c if b == c
        if (oracleVersionPreSettle != oracleVersionCurrent) {

            // value b->c
            accumulatedFee = accumulatedFee.add(_accumulator.accumulate(_position, _factory, _provider, oracleVersionCurrent));

            // position b->c (stamp c, does not settle pre position)
            _position.settle(_provider, oracleVersionCurrent);
        }

        // settle collateral
        _factory.collateral().settleProduct(accumulatedFee);

        emit Settle(oracleVersionPreSettle, oracleVersionCurrent);
    }

    /**
     * @notice Surfaces account settlement externally
     * @param account Account to settle
     */
    function settleAccount(address account) external notPaused nonReentrant {
        settleAccountInternal(account);
    }

    /**
     * @notice Core account settlement flywheel
     * @param account Account to settle
     * @dev
     *  a) last settle oracle version
     *  b) latest pre position oracle version
     *  c) current oracle version
     *
     *  Settles from a->b then from b->c if either interval is non-zero to account for a change
     *  in position quantity at (b).
     *
     *  Syncs each to instantaneously after the oracle update.
     */
    function settleAccountInternal(address account) internal {
        (IProductProvider _provider, IFactory _factory) = (provider, factory());

        IOracle.OracleVersion memory currentVersion = _provider.currentVersion();
        uint256 oracleVersionPreSettle = _positions[account].pre.oracleVersionToSettle(currentVersion.version);
        uint256 oracleVersionCurrent = currentVersion.version;
        Fixed18 accumulated;

        // value a->b
        accumulated = accumulated.add(_accumulators[account].syncTo(_accumulator, _positions[account], oracleVersionPreSettle).sum());

        // sync incentivizer before position update
        _factory.incentivizer().syncAccount(account);

        // position a->b
        accumulated = accumulated.sub(Fixed18Lib.from(_positions[account].settle(_provider, oracleVersionPreSettle)));

        // short-circuit if a->c
        if (oracleVersionPreSettle != oracleVersionCurrent) {

            // value b->c
            accumulated = accumulated.add(_accumulators[account].syncTo(_accumulator, _positions[account], oracleVersionCurrent).sum());
        }

        // settle collateral
        _factory.collateral().settleAccount(account, accumulated);

        emit AccountSettle(account, oracleVersionPreSettle, oracleVersionCurrent);
    }

    /**
     * @notice Opens a taker position for `msg.sender`
     * @param amount Amount of the position to open
     */
    function openTake(UFixed18 amount)
    external
    notPaused
    nonReentrant
    settleForAccount(msg.sender)
    takerInvariant
    positionInvariant
    liquidationInvariant
    maintenanceInvariant
    {
        IOracle.OracleVersion memory currentVersion = provider.currentVersion();

        _positions[msg.sender].pre.openTake(currentVersion.version, amount);
        _position.pre.openTake(currentVersion.version, amount);

        emit TakeOpened(msg.sender, amount);
    }

    /**
     * @notice Closes a taker position for `msg.sender`
     * @param amount Amount of the position to close
     */
    function closeTake(UFixed18 amount)
    external
    notPaused
    nonReentrant
    settleForAccount(msg.sender)
    closeInvariant
    liquidationInvariant
    {
        closeTakeInternal(msg.sender, amount);
    }

    function closeTakeInternal(address account, UFixed18 amount) internal {
        IOracle.OracleVersion memory currentVersion = provider.currentVersion();

        _positions[account].pre.closeTake(currentVersion.version, amount);
        _position.pre.closeTake(currentVersion.version, amount);

        emit TakeClosed(account, amount);
    }

    /**
     * @notice Opens a maker position for `msg.sender`
     * @param amount Amount of the position to open
     */
    function openMake(UFixed18 amount)
    external
    notPaused
    nonReentrant
    settleForAccount(msg.sender)
    nonZeroVersionInvariant
    makerInvariant
    positionInvariant
    liquidationInvariant
    maintenanceInvariant
    {
        IOracle.OracleVersion memory currentVersion = provider.currentVersion();

        _positions[msg.sender].pre.openMake(currentVersion.version, amount);
        _position.pre.openMake(currentVersion.version, amount);

        emit MakeOpened(msg.sender, amount);
    }

    /**
     * @notice Closes a maker position for `msg.sender`
     * @param amount Amount of the position to close
     */
    function closeMake(UFixed18 amount)
    external
    notPaused
    nonReentrant
    settleForAccount(msg.sender)
    takerInvariant
    closeInvariant
    liquidationInvariant
    {
        closeMakeInternal(msg.sender, amount);
    }

    function closeMakeInternal(address account, UFixed18 amount) internal {
        IOracle.OracleVersion memory currentVersion = provider.currentVersion();

        _positions[account].pre.closeMake(currentVersion.version, amount);
        _position.pre.closeMake(currentVersion.version, amount);

        emit MakeClosed(account, amount);
    }

    /**
     * @notice Closes all open and pending positions, locking for liquidation
     * @dev Only callable by the Collateral contract as part of the liquidation flow
     * @param account Account to close out
     */
    function closeAll(address account) external onlyCollateral settleForAccount(account) {
        AccountPosition storage accountPosition = _positions[account];
        Position memory p = accountPosition.position.next(_positions[account].pre);

        // Close all positions
        closeMakeInternal(account, p.maker);
        closeTakeInternal(account, p.taker);

        // Mark liquidation to lock position
        accountPosition.liquidation = true;
    }

    /**
     * @notice Returns the maintenance requirement for `account`
     * @param account Account to return for
     * @return The current maintenance requirement
     */
    function maintenance(address account) external view returns (UFixed18) {
        return _positions[account].maintenance(provider);
    }

    /**
     * @notice Returns the maintenance requirement for `account` after next settlement
     * @dev Assumes no price change and no funding, used to protect user from over-opening
     * @param account Account to return for
     * @return The next maintenance requirement
     */
    function maintenanceNext(address account) external view returns (UFixed18) {
        return _positions[account].maintenanceNext(provider);
    }

    /**
     * @notice Returns whether `account` has a completely zero'd position
     * @param account Account to return for
     * @return The the account is closed
     */
    function isClosed(address account) external view returns (bool) {
        return _positions[account].isClosed();
    }

    /**
     * @notice Returns whether `account` is currently locked for an in-progress liquidation
     * @param account Account to return for
     * @return Whether the account is in liquidation
     */
    function isLiquidating(address account) external view returns (bool) {
        return _positions[account].liquidation;
    }

    /**
     * @notice Returns `account`'s current position
     * @param account Account to return for
     * @return Current position of the account
     */
    function position(address account) external view returns (Position memory) {
        return _positions[account].position;
    }

    /**
     * @notice Returns `account`'s current pending-settlement position
     * @param account Account to return for
     * @return Current pre-position of the account
     */
    function pre(address account) external view returns (PrePosition memory) {
        return _positions[account].pre;
    }

    /**
     * @notice Returns the global latest settled oracle version
     * @return Latest settled oracle version of the product
     */
    function latestVersion() public view returns (uint256) {
        return _position.latestVersion;
    }

    /**
     * @notice Returns the global position at oracleVersion `oracleVersion`
     * @dev Only valid for the version at which a global settlement occurred
     * @param oracleVersion Oracle version to return for
     * @return Global position at oracle version
     */
    function positionAtVersion(uint256 oracleVersion) external view returns (Position memory) {
        return _position.positionAtVersion[oracleVersion];
    }

    /**
     * @notice Returns the current global pending-settlement position
     * @return Global pending-settlement position
     */
    function pre() external view returns (PrePosition memory) {
        return _position.pre;
    }

    /**
     * @notice Returns the global accumulator value at oracleVersion `oracleVersion`
     * @dev Only valid for the version at which a global settlement occurred
     * @param oracleVersion Oracle version to return for
     * @return Global accumulator value at oracle version
     */
    function valueAtVersion(uint256 oracleVersion) external view returns (Accumulator memory) {
        return _accumulator.valueAtVersion[oracleVersion];
    }

    /**
     * @notice Returns the global accumulator share at oracleVersion `oracleVersion`
     * @dev Only valid for the version at which a global settlement occurred
     * @param oracleVersion Oracle version to return for
     * @return Global accumulator share at oracle version
     */
    function shareAtVersion(uint256 oracleVersion) external view returns (Accumulator memory) {
        return _accumulator.shareAtVersion[oracleVersion];
    }

    /**
     * @notice Returns `account`'s latest settled oracle version
     * @param account Account to return for
     * @return Latest settled oracle version of the account
     */
    function latestVersion(address account) external view returns (uint256) {
        return _accumulators[account].latestVersion;
    }

    /// @dev Limit total maker for guarded rollouts
    modifier makerInvariant {
        _;

        Position memory next = _position.position().next(_position.pre);

        if (next.maker.gt(provider.makerLimit())) revert ProductMakerOverLimitError();
    }

    /// @dev Limit maker short exposure to the range 0.0-1.0x of their position
    modifier takerInvariant {
        _;

        Position memory next = _position.position().next(_position.pre);
        UFixed18 socializationFactor = next.socializationFactor();

        if (socializationFactor.lt(UFixed18Lib.ONE)) revert ProductInsufficientLiquidityError(socializationFactor);
    }

    /// @dev Ensure that the user has only taken a maker or taker position, but not both
    modifier positionInvariant {
        _;

        if (_positions[msg.sender].isDoubleSided()) revert ProductDoubleSidedError();
    }

    /// @dev Ensure that the user hasn't closed more than is open
    modifier closeInvariant {
        _;

        if (_positions[msg.sender].isOverClosed()) revert ProductOverClosedError();
    }

    /// @dev Ensure that the user will have sufficient margin for maintenance after next settlement
    modifier maintenanceInvariant {
        _;

        if (factory().collateral().liquidatableNext(msg.sender, IProduct(this)))
            revert ProductInsufficientCollateralError();
    }

    /// @dev Ensure that the user is not currently being liquidated
    modifier liquidationInvariant {
        if (_positions[msg.sender].liquidation) revert ProductInLiquidationError();

        _;
    }

    /// @dev Helper to fully settle an account's state
    modifier settleForAccount(address account) {
        settleInternal();
        settleAccountInternal(account);

        _;
    }

    /// @dev Ensure we have bootstraped the oracle before creating positions
    modifier nonZeroVersionInvariant {
        if (latestVersion() == 0) revert ProductOracleBootstrappingError();

        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./PrePosition.sol";

/// @dev AccountPosition type
struct AccountPosition {
    /// @dev The current settled position of the account
    Position position;

    /// @dev The current position delta pending-settlement
    PrePosition pre;

    /// @dev Whether the account is currently locked for liquidation
    bool liquidation;
}

/**
 * @title AccountPositionLib
 * @notice Library that manages an account-level position.
 */
library AccountPositionLib {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;
    using PositionLib for Position;
    using PrePositionLib for PrePosition;

    /**
     * @notice Settled the account's position to oracle version `toOracleVersion`
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return positionFee The fee accrued from opening or closing a new position
     */
    function settle(AccountPosition storage self, IProductProvider provider, uint256 toOracleVersion) internal returns (UFixed18 positionFee) {
        bool settled;
        (self.position, positionFee, settled) = self.position.settled(self.pre, provider, toOracleVersion);
        if (settled) delete self.pre;
    }

    /**
     * @notice Returns the current maintenance requirement for the account
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @return Current maintenance requirement for the account
     */
    function maintenance(AccountPosition storage self, IProductProvider provider) internal view returns (UFixed18) {
        if (self.liquidation) return UFixed18Lib.ZERO;
        return maintenanceInternal(self.position, provider);
    }

    /**
     * @notice Returns the maintenance requirement after the next oracle version settlement
     * @dev Includes the current pending-settlement position delta, assumes no price change
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @return Next maintenance requirement for the account
     */
    function maintenanceNext(AccountPosition storage self, IProductProvider provider) internal view returns (UFixed18) {
        return maintenanceInternal(self.position.next(self.pre), provider);
    }

    /**
      @notice Returns the maintenance requirement for a given `position`
     * @dev Internal helper
     * @param position The position to compete the maintenance requirement for
     * @param provider The parameter provider of the product
     * @return Next maintenance requirement for the account
     */
    function maintenanceInternal(Position memory position, IProductProvider provider) private view returns (UFixed18) {
        Fixed18 oraclePrice = provider.currentVersion().price;
        UFixed18 notionalMax = Fixed18Lib.from(position.max()).mul(oraclePrice).abs();
        return notionalMax.mul(provider.maintenance());
    }

    /**
     * @notice Returns whether an account is completely closed, i.e. no position or pre-position
     * @param self The struct to operate on
     * @return Whether the account is closed
     */
    function isClosed(AccountPosition memory self) internal pure returns (bool) {
        return self.pre.isEmpty() && self.position.isEmpty();
    }

    /**
     * @notice Returns whether an account has opened position on both sides of the market (maker vs taker)
     * @dev Used to verify the invariant that a single account can only have a position on one side of the
     *      market at a time
     * @param self The struct to operate on
     * @return Whether the account is currently doubled sided
     */
    function isDoubleSided(AccountPosition storage self) internal view returns (bool) {
        bool makerEmpty = self.position.maker.isZero() && self.pre.openPosition.maker.isZero() && self.pre.closePosition.maker.isZero();
        bool takerEmpty = self.position.taker.isZero() && self.pre.openPosition.taker.isZero() && self.pre.closePosition.taker.isZero();

        return !makerEmpty && !takerEmpty;
    }

    /**
     * @notice Returns whether the account's pending-settlement delta closes more position than is open
     * @dev Used to verify the invariant that an account cannot settle into having a negative position
     * @param self The struct to operate on
     * @return Whether the account is currently over closed
     */
    function isOverClosed(AccountPosition storage self) internal view returns (bool) {
        Position memory nextOpen = self.position.add(self.pre.openPosition);

        return  self.pre.closePosition.maker.gt(nextOpen.maker) || self.pre.closePosition.taker.gt(nextOpen.taker);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./Accumulator.sol";
import "./VersionedAccumulator.sol";
import "../position/AccountPosition.sol";

/// @dev AccountAccumulator type
struct AccountAccumulator {
    /// @dev latest version that the account was synced too
    uint256 latestVersion;
}

/**
 * @title AccountAccumulatorLib
 * @notice Library that manages syncing an account-level accumulator.
 */
library AccountAccumulatorLib {
    using PositionLib for Position;
    using AccumulatorLib for Accumulator;

    /**
     * @notice Syncs the account to oracle version `versionTo`
     * @param self The struct to operate on
     * @param global Pointer to global accumulator
     * @param position Pointer to global position
     * @param versionTo Oracle version to sync account to
     * @return value The value accumulated sync last sync
     */
    function syncTo(
        AccountAccumulator storage self,
        VersionedAccumulator storage global,
        AccountPosition storage position,
        uint256 versionTo
    ) internal returns (Accumulator memory value) {
        Accumulator memory valueAccumulated =
            global.valueAtVersion[versionTo].sub(global.valueAtVersion[self.latestVersion]);
        value = position.position.mul(valueAccumulated);
        self.latestVersion = versionTo;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./Accumulator.sol";
import "../position/VersionedPosition.sol";
import "../ProductProvider.sol";

/// @dev VersionedAccumulator type
struct VersionedAccumulator {
    /// @dev Latest synced oracle version
    uint256 latestVersion;

    /// @dev Mapping of accumulator value at each settled oracle version
    mapping(uint256 => Accumulator) valueAtVersion;

    /// @dev Mapping of accumulator share at each settled oracle version
    mapping(uint256 => Accumulator) shareAtVersion;
}

/**
 * @title VersionedAccumulatorLib
 * @notice Library that manages global versioned accumulator state.
 * @dev Manages two accumulators: value and share. The value accumulator measures the change in position value
 *      over time. The share accumulator measures the change in liquidity ownership over time (for tracking
 *      incentivization rewards).
 *
 *      Both accumulators are stamped for historical lookup anytime there is a global settlement, which services
 *      the delayed-position accounting. It is not guaranteed that every version will have a value stamped, but
 *      only versions when a settlement occurred are needed for this historical computation.
 */
library VersionedAccumulatorLib {
    using Fixed18Lib for Fixed18;
    using UFixed18Lib for UFixed18;
    using PositionLib for Position;
    using VersionedPositionLib for VersionedPosition;
    using AccumulatorLib for Accumulator;
    using ProductProviderLib for IProductProvider;

    /**
     * @notice Globally accumulates all value (position + funding) and share since last oracle update
     * @param self The struct to operate on
     * @param position Pointer to global position
     * @param factory The Factory contract of the protocol
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedFee The total fee accrued from accumulation
     */
    function accumulate(
        VersionedAccumulator storage self,
        VersionedPosition storage position,
        IFactory factory,
        IProductProvider provider,
        uint256 toOracleVersion
    ) internal returns (UFixed18 accumulatedFee) {
        // accumulate funding
        Accumulator memory accumulatedFunding;
        (accumulatedFunding, accumulatedFee) =
            accumulateFunding(self, position, factory, provider, toOracleVersion);

        // accumulate position
        Accumulator memory accumulatedPosition =
            accumulatePosition(self, position, provider, toOracleVersion);

        // accumulate share
        Accumulator memory accumulatedShare =
            accumulateShare(self, position, provider, toOracleVersion);

        // save update
        self.valueAtVersion[toOracleVersion] = self.valueAtVersion[self.latestVersion]
            .add(accumulatedFunding)
            .add(accumulatedPosition);
        self.shareAtVersion[toOracleVersion] = self.shareAtVersion[self.latestVersion].add(accumulatedShare);
        self.latestVersion = toOracleVersion;
    }

    /**
     * @notice Globally accumulates all funding since last oracle update
     * @dev If an oracle version is skipped due to no pre positions, funding will continue to be
     *      pegged to the price of the last snapshotted oracleVersion until a new one is accumulated.
     *      This is an acceptable approximation.
     * @param self The struct to operate on
     * @param position Pointer to global position
     * @param factory The Factory contract of the protocol
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedFunding The total amount accumulated from funding
     * @return accumulatedFee The total fee accrued from funding accumulation
     */
    function accumulateFunding(
        VersionedAccumulator storage self,
        VersionedPosition storage position,
        IFactory factory,
        IProductProvider provider,
        uint256 toOracleVersion
    ) private view returns (Accumulator memory accumulatedFunding, UFixed18 accumulatedFee) {
        Position memory p = position.position();
        if (p.taker.isZero()) return (Accumulator({maker: Fixed18Lib.ZERO, taker: Fixed18Lib.ZERO}), UFixed18Lib.ZERO);
        if (p.maker.isZero()) return (Accumulator({maker: Fixed18Lib.ZERO, taker: Fixed18Lib.ZERO}), UFixed18Lib.ZERO);

        IOracle.OracleVersion memory latestOracleVersion = provider.atVersion(self.latestVersion);
        uint256 elapsed = provider.atVersion(toOracleVersion).timestamp - latestOracleVersion.timestamp;

        UFixed18 takerNotional = Fixed18Lib.from(p.taker).mul(latestOracleVersion.price).abs();
        UFixed18 socializedNotional = takerNotional.mul(p.socializationFactor());

        Fixed18 rateAccumulated = provider.rate(p).mul(Fixed18Lib.from(UFixed18Lib.from(elapsed)));
        Fixed18 fundingAccumulated = rateAccumulated.mul(Fixed18Lib.from(socializedNotional));
        accumulatedFee = fundingAccumulated.abs().mul(provider.safeFundingFee(factory));

        Fixed18 fundingIncludingFee = Fixed18Lib.from(
            fundingAccumulated.sign(),
            fundingAccumulated.abs().sub(accumulatedFee)
        );

        accumulatedFunding.maker = fundingIncludingFee.div(Fixed18Lib.from(p.maker));
        accumulatedFunding.taker = fundingIncludingFee.div(Fixed18Lib.from(p.taker)).mul(Fixed18Lib.NEG_ONE);
    }

    /**
     * @notice Globally accumulates position PNL since last oracle update
     * @param self The struct to operate on
     * @param position Pointer to global position
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedPosition The total amount accumulated from position PNL
     */
    function accumulatePosition(
        VersionedAccumulator storage self,
        VersionedPosition storage position,
        IProductProvider provider,
        uint256 toOracleVersion
    ) private view returns (Accumulator memory accumulatedPosition) {
        Position memory p = position.position();
        if (p.taker.isZero()) return Accumulator({maker: Fixed18Lib.ZERO, taker: Fixed18Lib.ZERO});
        if (p.maker.isZero()) return Accumulator({maker: Fixed18Lib.ZERO, taker: Fixed18Lib.ZERO});

        Fixed18 oracleDelta = provider.atVersion(toOracleVersion).price.sub(provider.atVersion(self.latestVersion).price);
        Fixed18 totalTakerDelta = oracleDelta.mul(Fixed18Lib.from(p.taker));
        Fixed18 socializedTakerDelta = totalTakerDelta.mul(Fixed18Lib.from(p.socializationFactor()));

        accumulatedPosition.maker = socializedTakerDelta.div(Fixed18Lib.from(p.maker)).mul(Fixed18Lib.NEG_ONE);
        accumulatedPosition.taker = socializedTakerDelta.div(Fixed18Lib.from(p.taker));
    }

    /**
     * @notice Globally accumulates position's share of the total market since last oracle update
     * @dev This is used to compute incentivization rewards based on market participation
     * @param self The struct to operate on
     * @param position Pointer to global position
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedShare The total share amount accumulated per position
     */
    function accumulateShare(
        VersionedAccumulator storage self,
        VersionedPosition storage position,
        IProductProvider provider,
        uint256 toOracleVersion
    ) private view returns (Accumulator memory accumulatedShare) {
        Position memory p = position.position();
        uint256 elapsed = provider.atVersion(toOracleVersion).timestamp - provider.atVersion(self.latestVersion).timestamp;

        accumulatedShare.maker = p.maker.isZero() ? Fixed18Lib.ZERO : Fixed18Lib.from(UFixed18Lib.from(elapsed).div(p.maker));
        accumulatedShare.taker = p.taker.isZero() ? Fixed18Lib.ZERO : Fixed18Lib.from(UFixed18Lib.from(elapsed).div(p.taker));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./PrePosition.sol";

//// @dev VersionedPosition type
struct VersionedPosition {
    /// @dev Latest synced oracle version
    uint256 latestVersion;

    /// @dev Mapping of global position at each version
    mapping(uint256 => Position) positionAtVersion;

    /// @dev Current global pending-settlement position delta
    PrePosition pre;
}

/**
 * @title VersionedPositionLib
 * @notice Library that manages global position state.
 * @dev Global position state is used to compute utilization rate and socialization, and to account for and
 *      distribute fees globally.
 *
 *      Positions are stamped for historical lookup anytime there is a global settlement, which services
 *      the delayed-position accounting. It is not guaranteed that every version will have a value stamped, but
 *      only versions when a settlement occurred are needed for this historical computation.
 */
library VersionedPositionLib {
    using PositionLib for Position;
    using PrePositionLib for PrePosition;

    /**
     * @notice Returns the current global position
     * @return Current global position
     */
    function position(VersionedPosition storage self) internal view returns (Position memory) {
        return self.positionAtVersion[self.latestVersion];
    }

    /**
     * @notice Settled the global position to oracle version `toOracleVersion`
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return positionFee The fee accrued from opening or closing a new position
     */
    function settle(VersionedPosition storage self, IProductProvider provider, uint256 toOracleVersion) internal returns (UFixed18 positionFee) {
        bool settled;
        (self.positionAtVersion[toOracleVersion], positionFee, settled) = position(self).settled(self.pre, provider, toOracleVersion);
        if (settled) delete self.pre;

        self.latestVersion = toOracleVersion;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/unstructured/UInitializable.sol";
import "@equilibria/root/unstructured/UReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IIncentivizer.sol";
import "../interfaces/IFactory.sol";
import "./types/Program.sol";
import "../product/types/position/Position.sol";
import "../product/types/accumulator/Accumulator.sol";
import "../factory/UFactoryProvider.sol";

contract Incentivizer is IIncentivizer, UInitializable, UFactoryProvider, UReentrancyGuard {
    using UFixed18Lib for UFixed18;
    using EnumerableSet for EnumerableSet.UintSet;
    using TokenLib for Token;
    using PositionLib for Position;
    using AccumulatorLib for Accumulator;
    using ProgramInfoLib for ProgramInfo;
    using ProgramLib for Program;

    /// @dev Maximum programs per product allowed
    uint256 public programsPerProduct;

    /// @dev Fee taken from total program amount
    UFixed18 public fee;

    /// @dev Static program state
    ProgramInfo[] private _programInfos;

    /// @dev Dynamic program state
    mapping(uint256 => Program) private _programs;

    /// @dev Mapping of all programs for each product
    mapping(IProduct => EnumerableSet.UintSet) private _registry;

    /// @dev Fees that have been collected, but remain unclaimed
    mapping(Token => UFixed18) public fees;

    /**
     * @notice Initializes the contract state
     * @dev Must be called atomically as part of the upgradeable proxy deployment to
     *      avoid front-running
     * @param factory_ Factory contract address
     */
    function initialize(IFactory factory_) external initializer {
        __UFactoryProvider__initialize(factory_);
        __UReentrancyGuard__initialize();

        programsPerProduct = 2;
    }

    /**
     * @notice Creates a new incentive program
     * @dev Must be called as the product or protocol owner
     * @param info Parameters for the new program
     * @return new program's ID
     */
    function create(ProgramInfo calldata info)
    external
    nonReentrant
    isProduct(info.product)
    notPaused
    returns (uint256) {
        bool protocolOwned = msg.sender == factory().owner();

        if (programsForLength(info.product) >= programsPerProduct) revert IncentivizerTooManyProgramsError();
        if (!protocolOwned && msg.sender != factory().owner(info.product))
            revert NotProductOwnerError(msg.sender, info.product);

        uint256 programId = _programInfos.length;
        (ProgramInfo memory programInfo, UFixed18 programFee) = ProgramInfoLib.create(fee, info);

        _programInfos.push(programInfo);
        _programs[programId].initialize(programInfo, protocolOwned);
        _registry[info.product].add(programId);
        fees[info.token] = fees[info.token].add(programFee);

        info.token.pull(msg.sender, info.amount.sum(), true);

        emit ProgramCreated(
            programId,
            programInfo.product,
            programInfo.token,
            programInfo.amount.maker,
            programInfo.amount.taker,
            programInfo.start,
            programInfo.duration,
            programInfo.grace,
            programFee
        );

        return programId;
    }

    /**
     * @notice Completes an in-progress program early
     * @dev Must be called as the program owner
     * @param programId Program to end
     */
    function end(uint256 programId)
    external
    notPaused
    validProgram(programId)
    onlyProgramOwner(programId)
    {
        completeInternal(programId);
    }

    /**
     * @notice Closes a program, returning all unclaimed rewards
     * @param programId Program to end
     */
    function close(uint256 programId)
    external
    notPaused
    validProgram(programId)
    {
        Program storage program = _programs[programId];
        ProgramInfo storage programInfo = _programInfos[programId];

        if (!program.canClose(programInfo, block.timestamp)) revert IncentivizerProgramNotClosableError();

        // complete if not yet completed
        if (program.versionComplete == 0) {
            completeInternal(programId);
        }

        // close
        UFixed18 amountToReturn = _programs[programId].close();
        programInfo.token.push(treasury(programId), amountToReturn);
        _registry[programInfo.product].remove(programId);

        emit ProgramClosed(programId, amountToReturn);
    }

    /**
     * @notice Completes any in-progress programs that newly completable
     * @dev Called every settle() from each product
     */
    function sync() external onlyProduct {
        IProduct product = IProduct(msg.sender);
        IProductProvider provider = product.provider();

        uint256 currentTimestamp = provider.currentVersion().timestamp;
        uint256 programCount = programsForLength(product);

        for (uint256 i; i < programCount; i++) {
            uint256 programId = programsForAt(product, i);

            if (_programs[programId].versionComplete != 0) continue;
            if (!_programInfos[programId].isComplete(currentTimestamp)) continue;

            completeInternal(programId);
        }
    }

    /**
     * @notice Completes a program
     * @dev Internal helper
     * @param programId Program to complete
     */
    function completeInternal(uint256 programId) private {
        uint256 version = _programInfos[programId].product.latestVersion();
        _programs[programId].complete(version);

        emit ProgramCompleted(programId, version);
    }

    /**
     * @notice Settles unsettled balance for `account`
     * @dev Called immediately proceeding a position update in the corresponding product
     * @param account Account to sync
     */
    function syncAccount(address account) external onlyProduct {
        IProduct product = IProduct(msg.sender);

        uint256 programCount = programsForLength(product);

        for (uint256 i; i < programCount; i++) {
            uint256 programId = programsForAt(product, i);
            _programs[programId].settle(_programInfos[programId], account);
        }
    }

    /**
     * @notice Claims all of `msg.sender`'s rewards for `product` programs
     * @param product Product to claim rewards for
     */
    function claim(IProduct product) external notPaused nonReentrant isProduct(product) {
        // settle product markets
        product.settle();
        product.settleAccount(msg.sender);

        // claim
        uint256 programCount = programsForLength(product);
        for (uint256 i; i < programCount; i++) {
            claimInternal(msg.sender, programsForAt(product, i));
        }
    }

    /**
     * @notice Claims all of `msg.sender`'s rewards for a specific program
     * @param programId Program to claim rewards for
     */
    function claim(uint256 programId) external notPaused nonReentrant validProgram(programId) {
        IProduct product = _programInfos[programId].product;

        // settle product markets
        product.settle();
        product.settleAccount(msg.sender);

        // claim
        claimInternal(msg.sender, programId);
    }

    /**
     * @notice Claims all of `account`'s rewards for a specific program
     * @dev Internal helper, assumes account has already been product-settled prior to calling
     * @param account Account to claim rewards for
     * @param programId Program to claim rewards for
     */
    function claimInternal(address account, uint256 programId) private {
        Program storage program = _programs[programId];
        ProgramInfo memory programInfo = _programInfos[programId];

        program.settle(programInfo, account);
        UFixed18 claimedAmount = program.claim(account);

        programInfo.token.push(account, claimedAmount);

        emit Claim(account, programId, claimedAmount);
    }

    /**
     * @notice Claims all `tokens` fees to the protocol treasury
     * @param tokens Tokens to claim fees for
     */
    function claimFee(Token[] calldata tokens) external notPaused {
        for(uint256 i; i < tokens.length; i++) {
            Token token = tokens[i];
            UFixed18 amount = fees[token];
            if (amount.isZero()) continue;

            fees[token] = UFixed18Lib.ZERO;
            token.push(factory().treasury(), amount);

            emit FeeClaim(token, amount);
        }
    }

    /**
     * @notice Returns program info for program `programId`
     * @param programId Program to return for
     * @return Program info
     */
    function programInfos(uint256 programId) external view returns (ProgramInfo memory) {
        return _programInfos[programId];
    }

    /**
     * @notice Returns `account`'s total unclaimed rewards for a specific program
     * @param account Account to return for
     * @param programId Program to return for
     * @return `account`'s total unclaimed rewards for `programId`
     */
    function unclaimed(address account, uint256 programId) external view returns (UFixed18) {
        if (programId >= _programInfos.length) return (UFixed18Lib.ZERO);

        ProgramInfo memory programInfo = _programInfos[programId];
        return _programs[programId].unclaimed(programInfo, account);
    }

    /**
     * @notice Returns `account`'s latest synced version for a specific program
     * @param account Account to return for
     * @param programId Program to return for
     * @return `account`'s latest synced version for `programId`
     */
    function latestVersion(address account, uint256 programId) external view returns (uint256) {
        return _programs[programId].latestVersion[account];
    }

    /**
     * @notice Returns `account`'s settled rewards for a specific program
     * @param account Account to return for
     * @param programId Program to return for
     * @return `account`'s settled rewards for `programId`
     */
    function settled(address account, uint256 programId) external view returns (UFixed18) {
        return _programs[programId].settled[account];
    }

    /**
     * @notice Returns available rewards for a specific program
     * @param programId Program to return for
     * @return Available rewards for `programId`
     */
    function available(uint256 programId) external view returns (UFixed18) {
        return _programs[programId].available;
    }

    /**
     * @notice Returns the version completed for a specific program
     * @param programId Program to return for
     * @return The version completed for `programId`
     */
    function versionComplete(uint256 programId) external view returns (uint256) {
        return _programs[programId].versionComplete;
    }

    /**
     * @notice Returns whether closed for a specific program
     * @param programId Program to return for
     * @return whether closed for `programId`
     */
    function closed(uint256 programId) external view returns (bool) {
        return _programs[programId].closed;
    }

    /**
     * @notice Returns quantity of programs for a specific product
     * @param product Product to return for
     * @return Quantity of programs for `product`
     */
    function programsForLength(IProduct product) public view returns (uint256) {
        return _registry[product].length();
    }

    /**
     * @notice Returns the program at index `index` for a specific product
     * @param product Product to return for
     * @param index Index to return for
     * @return The program at index `index` for `product`
     */
    function programsForAt(IProduct product, uint256 index) public view returns (uint256) {
        return _registry[product].at(index);
    }

    /**
     * @notice Returns the owner of a specific program
     * @param programId Program to return for
     * @return The owner of `programId`
     */
    function owner(uint256 programId) public view returns (address) {
        Program storage program = _programs[programId];
        ProgramInfo storage programInfo = _programInfos[programId];
        return program.protocolOwned ? factory().owner() : factory().owner(programInfo.product);
    }

    /**
     * @notice Returns the treasury of a specific program
     * @param programId Program to return for
     * @return The treasury of `programId`
     */
    function treasury(uint256 programId) public view returns (address) {
        Program storage program = _programs[programId];
        ProgramInfo storage programInfo = _programInfos[programId];
        return program.protocolOwned ? factory().treasury() : factory().treasury(programInfo.product);
    }

    /**
     * @notice Updates the maximum programs per product
     * @param newProgramsPerProduct New maximum programs per product value
     */
    function updateProgramsPerProduct(uint256 newProgramsPerProduct) external onlyOwner {
        programsPerProduct = newProgramsPerProduct;

        emit ProgramsPerProductUpdated(newProgramsPerProduct);
    }

    /**
     * @notice Updates the fee
     * @param newFee New fee value
     */
    function updateFee(UFixed18 newFee) external onlyOwner {
        if (newFee.gt(UFixed18Lib.ONE)) revert IncentivizerInvalidFeeError();

        fee = newFee;
        emit FeeUpdated(newFee);
    }

    /// @dev Only allow the owner of `programId` to call
    modifier onlyProgramOwner(uint256 programId) {
        if (msg.sender != owner(programId)) revert IncentivizerNotProgramOwnerError(msg.sender, programId);

        _;
    }

    /// @dev Only allow a valid `programId`
    modifier validProgram(uint256 programId) {
        if (programId >= _programInfos.length) revert IncentivizerInvalidProgramError(programId);

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "../../product/types/position/Position.sol";
import "./ProgramInfo.sol";

struct Program {
    /// @dev Mapping of latest synced oracle version for each account
    mapping(address => uint256) latestVersion;

    /// @dev Mapping of latest rewards settled for each account
    mapping(address => UFixed18) settled;

    /// @dev Total amount of rewards yet to be claimed
    UFixed18 available;

    /// @dev Oracle version that the program completed, 0 is still ongoing
    uint256 versionComplete;

    /// @dev Whether the program is closed
    bool closed;

    /// @dev Whether the program is owned by the protocol (true) or by the product owner (false)
    bool protocolOwned;
}

library ProgramLib {
    using UFixed18Lib for UFixed18;
    using PositionLib for Position;
    using AccumulatorLib for Accumulator;
    using ProgramInfoLib for ProgramInfo;

    /**
     * @notice Initializes the program state
     * @param self Static The Program to operate on
     * @param programInfo Static program information
     * @param protocolOwned Whether the program is protocol owned
     */
    function initialize(Program storage self, ProgramInfo memory programInfo, bool protocolOwned) internal {
        self.available = programInfo.amount.sum();
        self.protocolOwned = protocolOwned;
    }

    /**
     * @notice Returns whether a program can be closed
     * @dev Programs must wait to be closed until after their grace period has concluded whether
     *      or not it was completed early
     * @param self Static The Program to operate on
     * @param programInfo Static program information
     * @param timestamp The effective timestamp to check
     * @return Whether the program can be closed
     */
    function canClose(Program storage self, ProgramInfo memory programInfo, uint256 timestamp) internal view returns (bool) {
        uint256 end = self.versionComplete == 0 ?
            programInfo.start + programInfo.duration :
            programInfo.product.provider().atVersion(self.versionComplete).timestamp;
        return timestamp >= (end + programInfo.grace);
    }

    /**
     * @notice Closes the program
     * @param self Static The Program to operate on
     * @return amountToReturn Amount of remaining unclaimed reward tokens to be returned
     */
    function close(Program storage self) internal returns (UFixed18 amountToReturn) {
        amountToReturn = self.available;
        self.available = UFixed18Lib.ZERO;
        self.closed = true;
    }

    /**
     * @notice Completes the program
     * @dev Completion prevents anymore rewards from accruing, but users may still claim during the
     *      grace period until a program is closed
     * @param self Static The Program to operate on
     * @param oracleVersion The effective oracle version of completion
     */
    function complete(Program storage self, uint256 oracleVersion) internal {
        self.versionComplete = oracleVersion;
    }

    /**
     * @notice Settles unclaimed rewards for account `account`
     * @param self Static The Program to operate on
     * @param programInfo Static program information
     * @param account The account to settle for
     */
    function settle(Program storage self, ProgramInfo memory programInfo, address account) internal {
        (UFixed18 unsettledAmount, uint256 unsettledVersion) = unsettled(self, programInfo, account);

        self.settled[account] = self.settled[account].add(unsettledAmount);
        self.available = self.available.sub(unsettledAmount);
        self.latestVersion[account] = unsettledVersion;
    }

    /**
     * @notice Claims settled rewards for account `account`
     * @param self Static The Program to operate on
     * @param account The account to claim for
     */
    function claim(Program storage self, address account)
    internal returns (UFixed18 claimedAmount) {
        claimedAmount = self.settled[account];
        self.settled[account] = UFixed18Lib.ZERO;
    }

    /**
     * @notice Returns the total amount of unclaimed rewards for account `account`
     * @dev This includes both settled and unsettled unclaimed rewards
     * @param self Static The Program to operate on
     * @param programInfo Static program information
     * @param account The account to claim for
     * @return Total amount of unclaimed rewards for account
     */
    function unclaimed(Program storage self, ProgramInfo memory programInfo, address account)
    internal view returns (UFixed18) {
        (UFixed18 unsettledAmount, ) = unsettled(self, programInfo, account);
        return unsettledAmount.add(self.settled[account]);
    }

    /**
     * @notice Returns the unsettled amount of unclaimed rewards for account `account`
     * @dev Clears when a program is closed
     *      Assumes that position is unchanged since last settlement, must be settled prior to user position update
     * @param self Static The Program to operate on
     * @param programInfo Static program information
     * @param account The account to claim for
     * @return amount Amount of unsettled rewards for account
     * @return latestVersion Effective oracle version for computation
     */
    function unsettled(Program storage self, ProgramInfo memory programInfo, address account)
    private view returns (UFixed18 amount, uint256 latestVersion) {
        IProduct product = programInfo.product;

        uint256 userLatestVersion = self.latestVersion[account];
        Position memory userPosition = product.position(account);
        uint256 userSyncedTo = product.latestVersion(account);

        // compute version to sync to
        latestVersion = self.versionComplete == 0 ? userSyncedTo : Math.min(userSyncedTo, self.versionComplete);
        uint256 latestTimestamp = product.provider().atVersion(latestVersion).timestamp;

        // check initialization conditions
        if (!programInfo.isStarted(latestTimestamp)) return (UFixed18Lib.ZERO, 0); // program hasn't started
        if (self.closed) return (UFixed18Lib.ZERO, latestVersion);                 // program has closed
        if (userLatestVersion == 0) return (UFixed18Lib.ZERO, latestVersion);      // user has not been initialized

        // compute unsettled amount
        Accumulator memory userShareDelta =
            userPosition.mul(product.shareAtVersion(latestVersion).sub(product.shareAtVersion(userLatestVersion)));
        amount = UFixed18Lib.from(programInfo.amountPerShare().mul(userShareDelta).sum());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "../interfaces/IProductProvider.sol";
import "../interfaces/IOracle.sol";

/**
 * @title ProductProviderBase
 * @notice Abstract contract that implements the oracle and payoff function portion of the product provider.
 * @dev Should be extended when implemented a new product.
 */
abstract contract ProductProviderBase is IProductProvider {
    address public immutable oracle;

    /**
     * @notice Initializes the contract state
     * @param oracle_ Oracle price provider contract address
     */
    constructor(IOracle oracle_) {
        oracle = address(oracle_);
    }

    /**
     * @notice Returns The transformed oracle version
     * @param oracleVersion Oracle version to transform
     * @return Transformed oracle version
     */
    function payoff(OracleVersion memory oracleVersion) public view virtual override returns (OracleVersion memory);

    /**
     * @notice Pass-through hook to call sync() on the oracle provider
     */
    function sync() external override returns (OracleVersion memory) {
        return IOracle(oracle).sync();
    }

    /**
     * @notice Returns the current oracle version
     * @return Current oracle version
     */
    function currentVersion() external override view returns (OracleVersion memory) {
        return payoff(IOracle(oracle).currentVersion());
    }

    /**
     * @notice Returns the oracle version at `oracleVersion`
     * @param oracleVersion Oracle version to return for
     * @return Oracle version at `oracleVersion` with price transformed by payoff function
     */
    function atVersion(uint256 oracleVersion) external override view returns (OracleVersion memory) {
        return payoff(IOracle(oracle).atVersion(oracleVersion));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "../product/ProductProviderBase.sol";

contract Squeeth is ProductProviderBase {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;

    // solhint-disable-next-line no-empty-blocks
    constructor(IOracle oracle) ProductProviderBase(oracle) { }

    // Implementation

    function name() external pure override returns (string memory) {
        return "Squeeth";
    }

    function rate(Position memory position) external pure override returns (Fixed18) {
        if (position.maker.isZero()) return Fixed18Lib.ZERO;

        UFixed18 utilization = position.taker.div(position.maker);
        UFixed18 capped = UFixed18Lib.min(utilization, UFixed18Lib.ONE);
        Fixed18 centered = (Fixed18Lib.from(capped).sub(Fixed18Lib.ratio(1, 2))).mul(Fixed18Lib.from(2));

        return centered.div(Fixed18Lib.from(365 days));
    }

    function payoff(OracleVersion memory oracleVersion) public pure override returns (OracleVersion memory) {
        return OracleVersion({
            version: oracleVersion.version,
            timestamp: oracleVersion.timestamp,
            price: oracleVersion.price.mul(oracleVersion.price)
        });
    }

    function maintenance() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(30, 100);
    }

    function fundingFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(10, 100);
    }

    function makerFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ZERO;
    }

    function takerFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ZERO;
    }

    function makerLimit() external pure override returns (UFixed18) {
        return UFixed18Lib.from(1);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "../product/ProductProviderBase.sol";

contract ShortEther is ProductProviderBase {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;

    // solhint-disable-next-line no-empty-blocks
    constructor(IOracle oracle) ProductProviderBase(oracle) { }

    // Implementation

    function name() external pure override returns (string memory) {
        return "Short Ether";
    }

    function rate(Position memory position) external pure override returns (Fixed18) {
        if (position.maker.isZero()) return Fixed18Lib.ZERO;

        UFixed18 utilization = position.taker.div(position.maker);
        UFixed18 capped = UFixed18Lib.min(utilization, UFixed18Lib.ONE);
        Fixed18 centered = (Fixed18Lib.from(capped).sub(Fixed18Lib.ratio(1, 2))).mul(Fixed18Lib.from(2));

        return centered.div(Fixed18Lib.from(365 days));
    }

    function payoff(OracleVersion memory oracleVersion) public pure override returns (OracleVersion memory) {
        return OracleVersion({
            version: oracleVersion.version,
            timestamp: oracleVersion.timestamp,
            price: Fixed18Lib.from(-1).mul(oracleVersion.price)
        });
    }

    function maintenance() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(30, 100);
    }

    function fundingFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(10, 100);
    }

    function makerFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ZERO;
    }

    function takerFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ZERO;
    }

    function makerLimit() external pure override returns (UFixed18) {
        return UFixed18Lib.from(1000);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@equilibria/root/unstructured/UOwnable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IOracle.sol";
import "./types/ChainlinkRegistry.sol";

/**
 * @title ChainlinkOracle
 * @notice Chainlink implementation of the IOracle interface.
 * @dev One instance per Chainlink price feed should be deployed. Multiple products may use the same
 *      ChainlinkOracle instance if their payoff functions are based on the same underlying oracle.
 *      This implementation only support non-negative prices.
 */
contract ChainlinkOracle is IOracle, UOwnable {
    using ChainlinkRegistryLib for ChainlinkRegistry;
    using ChainlinkRoundLib for ChainlinkRound;

    /// @dev Chainlink registry feed address
    ChainlinkRegistry public immutable registry;

    /// @dev Base token address for the Chainlink oracle
    address public immutable base;

    /// @dev Quote token address for the Chainlink oracle
    address public immutable quote;

    /// @dev Decimal offset used to normalize chainlink price to 18 decimals
    int256 private immutable _decimalOffset;

    /// @dev Mapping of the first oracle version for each underlying phase ID
    uint256[] private _startingVersionForPhaseId;

    /**
     * @notice Initializes the contract state
     * @param registry_ Chainlink price feed registry
     * @param base_ base currency for feed
     * @param quote_ quote currency for feed
     */
    constructor(ChainlinkRegistry registry_, address base_, address quote_) {
        registry = registry_;
        base = base_;
        quote = quote_;

        _startingVersionForPhaseId.push(0); // phaseId is 1-indexed, skip index 0
        _startingVersionForPhaseId.push(0); // phaseId is 1-indexed, first phase starts as version 0
        _decimalOffset = SafeCast.toInt256(10 ** registry_.decimals(base, quote));
    }

    /**
     * @notice Checks for a new price and updates the internal phase annotation state accordingly
     * @return The current oracle version after sync
     */
    function sync() external returns (OracleVersion memory) {
        // Fetch latest round
        ChainlinkRound memory round = registry.getLatestRound(base, quote);

        // Update phase annotation when new phase detected
        while (round.phaseId() > _latestPhaseId()) {
            uint256 roundCount = registry.getRoundCount(base, quote, _latestPhaseId());
            _startingVersionForPhaseId.push(roundCount);
        }

        // Return packaged oracle version
        return _buildOracleVersion(round);
    }

    /**
     * @notice Returns the current oracle version
     * @return oracleVersion Current oracle version
     */
    function currentVersion() public view returns (OracleVersion memory oracleVersion) {
        return _buildOracleVersion(registry.getLatestRound(base, quote));
    }

    /**
     * @notice Returns the current oracle version
     * @param version The version of which to lookup
     * @return oracleVersion Oracle version at version `version`
     */
    function atVersion(uint256 version) public view returns (OracleVersion memory oracleVersion) {
        return _buildOracleVersion(registry.getRound(base, quote, _versionToRoundId(version)));
    }

    /**
     * @notice Builds an oracle version object from a Chainlink round object
     * @dev Falls back to previous versions price and timestamp if the current round is invalid
     * @param round Chainlink round to build from
     * @return Built oracle version
     */
    function _buildOracleVersion(ChainlinkRound memory round)
    private view returns (OracleVersion memory) {
        uint256 version = _startingVersionForPhaseId[round.phaseId()] +
            uint256(round.roundId - registry.getStartingRoundId(base, quote, round.phaseId()));

        if (round.valid) {
            return OracleVersion({
                version: version,
                timestamp: round.timestamp,
                price: Fixed18Lib.ratio(round.answer, _decimalOffset)
            });
        } else { // fallback to previous oracle if invalid
            OracleVersion memory oracleVersion = atVersion(version - 1);
            oracleVersion.version = version;
            return oracleVersion;
        }
    }

    /**
     * @notice Computes the chainlink round ID from a version
     * @notice version Version to compute from
     * @return Chainlink round ID
     */
    function _versionToRoundId(uint256 version) private view returns (uint80) {
        uint16 phaseId = _versionToPhaseId(version);
        return registry.getStartingRoundId(base, quote, phaseId) +
            uint80(version - _startingVersionForPhaseId[phaseId]);
    }

    /**
     * @notice Computes the chainlink phase ID from a version
     * @param version Version to compute from
     * @return phaseId Chainlink phase ID
     */
    function _versionToPhaseId(uint256 version) private view returns (uint16 phaseId) {
        phaseId = _latestPhaseId();
        while (_startingVersionForPhaseId[phaseId] > version) {
            phaseId--;
        }
    }

    /**
     * @notice Returns the latest phase ID that this contract has seen via `sync()`
     * @return Latest seen phase ID
     */
    function _latestPhaseId() private view returns (uint16) {
        return uint16(_startingVersionForPhaseId.length - 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./UInitializable.sol";

/**
 * @title UOwnable
 * @notice Library to manage the ownership lifecycle of upgradeable contracts.
 * @dev This contract has been extended from the Open Zeppelin library to include an
 *      unstructured storage pattern so that it can be safely mixed in with upgradeable
 *      contracts without affecting their storage patterns through inheritance.
 */
abstract contract UOwnable is UInitializable {
    /// @dev unstructured storage slot for the owner address
    bytes32 private constant OWNER_SLOT = keccak256("equilibria.utils.UOwnable.owner");

    /// @dev unstructured storage slot for the pending owner address
    bytes32 private constant PENDING_OWNER_SLOT = keccak256("equilibria.utils.UOwnable.pendingOwner");

    event OwnerUpdated(address indexed newOwner);
    event PendingOwnerUpdated(address indexed newPendingOwner);

    error UOwnableNotOwnerError(address sender);
    error UOwnableNotPendingOwnerError(address sender);

    /**
     * @notice Initializes the contract setting `msg.sender` as the initial owner
     */
    function __UOwnable__initialize() internal onlyInitializer {
        _setOwner(msg.sender);
    }

    /**
     * @notice Returns the address of the current owner
     * @return result Current owner
     */
    function owner() public view returns (address result) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            result := sload(slot)
        }
    }

    /**
     * @notice Returns the address of the pending owner
     * @return result Pending owner
     */
    function pendingOwner() public view returns (address result) {
        bytes32 slot = PENDING_OWNER_SLOT;
        assembly {
            result := sload(slot)
        }
    }

    /**
     * @notice Sets a new pending owner
     * @dev Can only be called by the current owner
     *      New owner does not take affect until that address calls `acceptOwner()`
     * @param newPendingOwner New pending owner address
     */
    function setPendingOwner(address newPendingOwner) external onlyOwner {
        _setPendingOwner(newPendingOwner);
    }

    /**
     * @notice Accepts and transfers the ownership of the contract to the pending owner
     * @dev Can only be called by the pending owner to ensure correctness
     */
    function acceptOwner() external {
        if (msg.sender != pendingOwner()) revert UOwnableNotPendingOwnerError(msg.sender);

        _setOwner(pendingOwner());
        _setPendingOwner(address(0));
    }

    /**
     * @notice Sets the new owner address in unstructured storage
     * @dev Internal helper
     * @param newOwner New owner address to store
     */
    function _setOwner(address newOwner) private {
        bytes32 slot = OWNER_SLOT;
        assembly {
            sstore(slot, newOwner)
        }

        emit OwnerUpdated(newOwner);
    }

    /**
     * @notice Sets the new pending owner address in unstructured storage
     * @dev Internal helper
     * @param newPendingOwner New pending owner address to store
     */
    function _setPendingOwner(address newPendingOwner) private {
        bytes32 slot = PENDING_OWNER_SLOT;
        assembly {
            sstore(slot, newPendingOwner)
        }

        emit PendingOwnerUpdated(newPendingOwner);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        if (owner() != msg.sender) revert UOwnableNotOwnerError(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "./ChainlinkRound.sol";

/// @dev ChainlinkRegistry type
type ChainlinkRegistry is address;

/**
 * @title ChainlinkRegistryLib
 * @notice Library that manages interfacing with the Chainlink Feed Registry
 */
library ChainlinkRegistryLib {
    using ChainlinkRoundLib for ChainlinkRound;

    /**
     * @notice Returns the decimal amount for a specific feed
     * @param self Chainlink Feed Registry to operate on
     * @param base Base currency token address
     * @param quote Quote currency token address
     * @return Decimal amount
     */
    function decimals(ChainlinkRegistry self, address base, address quote) internal view returns (uint8) {
        return FeedRegistryInterface(ChainlinkRegistry.unwrap(self)).decimals(base, quote);
    }

    /**
     * @notice Returns the latest round data for a specific feed
     * @param self Chainlink Feed Registry to operate on
     * @param base Base currency token address
     * @param quote Quote currency token address
     * @return Latest round data
     */
    function getLatestRound(ChainlinkRegistry self, address base, address quote) internal view returns (ChainlinkRound memory) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) =
            FeedRegistryInterface(ChainlinkRegistry.unwrap(self)).latestRoundData(base, quote);
        return _buildRound(roundId, answer, updatedAt, answeredInRound);
    }

    /**
     * @notice Returns a specific round's data for a specific feed
     * @param self Chainlink Feed Registry to operate on
     * @param base Base currency token address
     * @param quote Quote currency token address
     * @param roundId The specific round to fetch data for
     * @return Specific round's data
     */
    function getRound(ChainlinkRegistry self, address base, address quote, uint80 roundId) internal view returns (ChainlinkRound memory) {
        (, int256 answer, , uint256 updatedAt, uint80 answeredInRound) =
            FeedRegistryInterface(ChainlinkRegistry.unwrap(self)).getRoundData(base, quote, roundId);
        return _buildRound(roundId, answer, updatedAt, answeredInRound);
    }


    /**
     * @notice Returns the first round ID for a specific phase ID
     * @param self Chainlink Feed Registry to operate on
     * @param base Base currency token address
     * @param quote Quote currency token address
     * @param phaseId The specific phase to fetch data for
     * @return startingRoundId The starting round ID for the phase
     */
    function getStartingRoundId(ChainlinkRegistry self, address base, address quote, uint16 phaseId)
    internal view returns (uint80 startingRoundId) {
        (startingRoundId, ) =
            FeedRegistryInterface(ChainlinkRegistry.unwrap(self)).getPhaseRange(base, quote, phaseId);
    }

    /**
     * @notice Returns the quantity of rounds for a specific phase ID
     * @param self Chainlink Feed Registry to operate on
     * @param base Base currency token address
     * @param quote Quote currency token address
     * @param phaseId The specific phase to fetch data for
     * @return The quantity of rounds for the phase
     */
    function getRoundCount(ChainlinkRegistry self, address base, address quote, uint16 phaseId)
    internal view returns (uint80) {
        (uint80 startingRoundId, uint80 endingRoundId) =
            FeedRegistryInterface(ChainlinkRegistry.unwrap(self)).getPhaseRange(base, quote, phaseId);
        return endingRoundId - startingRoundId + 1;
    }

    /**
     * @notice Builds and validates a ChainlinkRound object from the result of a raw Chainlink call
     * @param roundId round ID from call
     * @param answer Answer from call
     * @param updatedAt Update at timestamp from call
     * @param answeredInRound answered-in round ID from call
     * @return round The constructed ChainlinkRound object
     */
    function _buildRound(uint80 roundId, int256 answer, uint256 updatedAt, uint80 answeredInRound)
    private pure returns (ChainlinkRound memory round)
    {
        (round.timestamp, round.answer, round.roundId) = (updatedAt, answer, roundId);

        if (answer < 0) return round;                   // negative price
        if (updatedAt == 0) return round;               // round not complete
        if (answeredInRound < roundId) return round;    // stale price

        round.valid = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @dev ChainlinkRound type
struct ChainlinkRound {
    uint256 timestamp;
    int256 answer;
    uint80 roundId;
    bool valid;
}

/**
 * @title ChainlinkRoundLib
 * @notice Library that manages Chainlink round parsing
 */
library ChainlinkRoundLib {
    /// @dev Phase ID offset location in the round ID
    uint256 constant private PHASE_OFFSET = 64;

    /**
     * @notice Computes the chainlink phase ID from a round
     * @param self Round to compute from
     * @return Chainlink phase ID
     */
    function phaseId(ChainlinkRound memory self) internal pure returns (uint16) {
        return uint16(self.roundId >> PHASE_OFFSET);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";

contract PassthroughChainlinkFeed {
    error TestnetChainlinkFeedNoDataError();

    FeedRegistryInterface private underlying;

    constructor(FeedRegistryInterface _underlying) {
        underlying = _underlying;
    }

    function decimals(address base, address quote) external view returns (uint8) {
        return underlying.decimals(base, quote);
    }

    function getRoundData(address base, address quote, uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80) {
        return underlying.getRoundData(base, quote, roundId);
    }

    function getPhaseRange(address base, address quote, uint16 phaseId) external view returns (uint80, uint80) {
        return underlying.getPhaseRange(base, quote, phaseId);
    }

    function latestRoundData(address base, address quote) external view returns (uint80, int256, uint256, uint256, uint80) {
        return underlying.latestRoundData(base, quote);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@equilibria/root/unstructured/UInitializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/ICollateral.sol";
import "../interfaces/IIncentivizer.sol";
import "../interfaces/IProduct.sol";

/**
 * @title Factory
 * @notice Manages creating new products and global protocol parameters.
 */
contract Factory is IFactory, UInitializable {
    using UFixed18Lib for UFixed18;

    /// @dev Secondary pauser address (not owner, but has permission to update isPaused)
    address public pauser;

    /// @dev Whether the protocol is currently paused
    bool public isPaused;

    /// @dev Collateral contract address for the protocol
    ICollateral public collateral;

    /// @dev Incentivizer contract address for the protocol
    IIncentivizer public incentivizer;

    /// @dev Base Product implementation contract address for the protocol
    IProduct public productBase;

    /// @dev List of product controllers
    Controller[] private _controllers;

    /// @dev Mapping of the controller for each  product
    mapping(IProduct => uint256) public controllerFor;

    /// @dev Whether a specific controller is allowed to create a new product
    mapping(uint256 => bool) public allowed;

    /// @dev Percent of the fee that goes to the protocol treasury vs the product treasury
    UFixed18 public fee;

    /// @dev Minimum allowable funding fee for a product
    UFixed18 public minFundingFee;

    /// @dev Minimum allowable collateral amount per user account
    UFixed18 public minCollateral;

    /**
     * @notice Initializes the contract state
     * @dev Must be called atomically as part of the upgradeable proxy deployment to
     *      avoid front-running
     * @param collateral_ Collateral contract address
     * @param incentivizer_ Incentivizer contract address
     * @param productBase_ Base Product implementation contract address
     * @param treasury_ Protocol treasury address
     */
    function initialize(
        ICollateral collateral_,
        IIncentivizer incentivizer_,
        IProduct productBase_,
        address treasury_
    ) external initializer {
        createController(treasury_);

        updatePauser(msg.sender);
        updateCollateral(collateral_);
        updateIncentivizer(incentivizer_);
        updateProductBase(productBase_);
        updateFee(UFixed18Lib.ratio(50, 100));
        updateMinFundingFee(UFixed18Lib.ratio(10, 100));
    }

    /**
     * @notice Creates a new controller with `msg.sender` as the owner
     * @param controllerTreasury Treasury address for the controller
     * @return New controller ID
     */
    function createController(address controllerTreasury) public returns (uint256) {
        uint256 controllerId = _controllers.length;

        _controllers.push(Controller({
            pendingOwner: address(0),
            owner: msg.sender,
            treasury: controllerTreasury
        }));

        emit ControllerCreated(controllerId, msg.sender, controllerTreasury);

        return controllerId;
    }

    /**
     * @notice Updates the treasury of an existing controller
     * @dev Must be called by the controller's current owner
     * @param controllerId Controller to update
     * @param newTreasury New treasury address
     */
    function updateControllerTreasury(uint256 controllerId, address newTreasury) external onlyOwner(controllerId) {
        _controllers[controllerId].treasury = newTreasury;
        emit ControllerTreasuryUpdated(controllerId, newTreasury);
    }

    /**
     * @notice Updates the pending owner of an existing controller
     * @dev Must be called by the controller's current owner
     * @param controllerId Controller to update
     * @param newPendingOwner New pending owner address
     */
    function updateControllerPendingOwner(uint256 controllerId, address newPendingOwner) external onlyOwner(controllerId) {
        _controllers[controllerId].pendingOwner = newPendingOwner;
        emit ControllerPendingOwnerUpdated(controllerId, newPendingOwner);
    }

    /**
     * @notice Accepts ownership over an existing controller
     * @dev Must be called by the controller's pending owner
     * @param controllerId Controller to update
     */
    function acceptControllerOwner(uint256 controllerId) external {
        Controller storage controller = _controllers[controllerId];
        address newPendingOwner = controller.pendingOwner;

        if (msg.sender != newPendingOwner) revert FactoryNotPendingOwnerError(controllerId);

        controller.pendingOwner = address(0);
        controller.owner = newPendingOwner;
        emit ControllerOwnerUpdated(controllerId, newPendingOwner);
    }

    /**
     * @notice Creates a new product market with `provider`
     * @dev Controller caller must be allowed
     * @param controllerId Controller that will own the product
     * @param provider Provider that will service the market
     * @return New product contract address
     */
    function createProduct(uint256 controllerId, IProductProvider provider) external onlyOwner(controllerId) returns (IProduct) {
        if (controllerId == 0) revert FactoryNoZeroControllerError();
        if (!allowed[0] && !allowed[controllerId]) revert FactoryNotAllowedError();

        IProduct newProduct = IProduct(Clones.clone(address(productBase)));
        newProduct.initialize(provider);
        controllerFor[newProduct] = controllerId;
        emit ProductCreated(newProduct, provider);

        return newProduct;
    }

    /**
     * @notice Updates the Collateral contract address
     * @param newCollateral New Collateral contract address
     */
    function updateCollateral(ICollateral newCollateral) public onlyOwner(0) {
        collateral = newCollateral;
        emit CollateralUpdated(newCollateral);
    }

    /**
     * @notice Updates the Incentivizer contract address
     * @param newIncentivizer New Incentivizer contract address
     */
    function updateIncentivizer(IIncentivizer newIncentivizer) public onlyOwner(0) {
        incentivizer = newIncentivizer;
        emit IncentivizerUpdated(newIncentivizer);
    }

    /**
     * @notice Updates the base Product contract address
     * @param newProductBase New base Product contract address
     */
    function updateProductBase(IProduct newProductBase) public onlyOwner(0) {
        productBase = newProductBase;
        emit ProductBaseUpdated(newProductBase);
    }

    /**
     * @notice Updates the protocol-product fee split
     * @param newFee New protocol-product fee split
     */
    function updateFee(UFixed18 newFee) public onlyOwner(0) {
        if (newFee.gt(UFixed18Lib.ONE)) revert FactoryInvalidFeeError();

        fee = newFee;
        emit FeeUpdated(newFee);
    }

    /**
     * @notice Updates the minimum allowed funding fee
     * @param newMinFundingFee New minimum allowed funding fee
     */
    function updateMinFundingFee(UFixed18 newMinFundingFee) public onlyOwner(0) {
        if (newMinFundingFee.gt(UFixed18Lib.ONE)) revert FactoryInvalidMinFundingFeeError();

        minFundingFee = newMinFundingFee;
        emit MinFundingFeeUpdated(newMinFundingFee);
    }

    /**
     * @notice Updates the minimum allowed collateral amount per user account
     * @param newMinCollateral New minimum allowed collateral amount
     */
    function updateMinCollateral(UFixed18 newMinCollateral) public onlyOwner(0) {
        minCollateral = newMinCollateral;
        emit MinCollateralUpdated(newMinCollateral);
    }

    /**
     * @notice Updates the secondary pauser address
     * @param newPauser New secondary pauser address
     */
    function updatePauser(address newPauser) public onlyOwner(0) {
        pauser = newPauser;
        emit PauserUpdated(newPauser);
    }

    /**
     * @notice Updates the protocol pause status
     * @param newIsPaused New protocol pause status
     */
    function updateIsPaused(bool newIsPaused) external {
        if (msg.sender != owner() && msg.sender != pauser) revert FactoryNotPauserError(msg.sender);

        isPaused = newIsPaused;
        emit IsPausedUpdated(newIsPaused);
    }

    /**
     * @notice Updates whether `controllerId` is allowed to create new products
     * @param controllerId Controller to update
     * @param newAllowed New allowed status for `controllerId`
     */
    function updateAllowed(uint256 controllerId, bool newAllowed) external onlyOwner(0) {
        allowed[controllerId] = newAllowed;
        emit AllowedUpdated(controllerId, newAllowed);
    }

    /**
     * @notice Returns whether a contract is a product
     * @param product Contract address to check
     * @return Whether a contract is a product
     */
    function isProduct(IProduct product) external view returns (bool) {
        return controllerFor[product] != 0;
    }

    /**
     * @notice Returns controller state for controller `controllerId`
     * @param controllerId Controller to return for
     * @return Controller state
     */
    function controllers(uint256 controllerId) external view returns (Controller memory) {
        return _controllers[controllerId];
    }

    /**
     * @notice Returns the pending owner of the protocol
     * @return Owner of the protocol
     */
    function pendingOwner() public view returns (address) {
        return pendingOwner(0);
    }

    /**
     * @notice Returns the pending owner of the controller `controllerId`
     * @param controllerId Controller to return for
     * @return Pending owner of the controller
     */
    function pendingOwner(uint256 controllerId) public view returns (address) {
        return _controllers[controllerId].pendingOwner;
    }

    /**
     * @notice Returns the owner of the protocol
     * @return Owner of the protocol
     */
    function owner() public view returns (address) {
        return owner(0);
    }

    /**
     * @notice Returns the owner of the controller `controllerId`
     * @param controllerId Controller to return for
     * @return Owner of the controller
     */
    function owner(uint256 controllerId) public view returns (address) {
        return _controllers[controllerId].owner;
    }

    /**
     * @notice Returns the owner of the product `product`
     * @param product Product to return for
     * @return Owner of the product
     */
    function owner(IProduct product) external view returns (address) {
        return owner(controllerFor[product]);
    }

    /**
     * @notice Returns the treasury of the protocol
     * @return Treasury of the protocol
     */
    function treasury() external view returns (address) {
        return treasury(0);
    }

    /**
     * @notice Returns the treasury of the controller `controllerId`
     * @param controllerId Controller to return for
     * @return Treasury of the controller
     */
    function treasury(uint256 controllerId) public view returns (address) {
        return _controllers[controllerId].treasury;
    }

    /**
     * @notice Returns the treasury of the product `product`
     * @param product Product to return for
     * @return Treasury of the product
     */
    function treasury(IProduct product) external view returns (address) {
        return treasury(controllerFor[product]);
    }

    // @dev Only allow owner of `controllerId` to call
    modifier onlyOwner(uint256 controllerId) {
        if (msg.sender != owner(controllerId)) revert FactoryNotOwnerError(controllerId);

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TestnetDSU is ERC20, ERC20Burnable {
    uint256 private constant LIMIT = 1_000_000e18;

    error TestnetDSUOverLimitError();

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Digital Standard Unit", "DSU") { }

    function mint(address account, uint256 amount) external {
        if (amount > LIMIT) revert TestnetDSUOverLimitError();

        _mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "../product/ProductProviderBase.sol";

contract LeveragedEther is ProductProviderBase {
    using UFixed18Lib for UFixed18;
    using Fixed18Lib for Fixed18;

    // solhint-disable-next-line no-empty-blocks
    constructor(IOracle oracle) ProductProviderBase(oracle) { }

    // Implementation

    function name() external pure override returns (string memory) {
        return "3x Ether";
    }

    function rate(Position memory position) external pure override returns (Fixed18) {
        if (position.maker.isZero()) return Fixed18Lib.ZERO;

        UFixed18 utilization = position.taker.div(position.maker);
        UFixed18 capped = UFixed18Lib.min(utilization, UFixed18Lib.ONE);
        Fixed18 centered = (Fixed18Lib.from(capped).sub(Fixed18Lib.ratio(1, 2))).mul(Fixed18Lib.from(2));

        return centered.div(Fixed18Lib.from(365 days));
    }

    function payoff(OracleVersion memory oracleVersion) public pure override returns (OracleVersion memory) {
        return OracleVersion({
            version: oracleVersion.version,
            timestamp: oracleVersion.timestamp,
            price: Fixed18Lib.from(3).mul(oracleVersion.price)
        });
    }

    function maintenance() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(100, 100);
    }

    function fundingFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(10, 100);
    }

    function makerFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(1, 10000);
    }

    function takerFee() external pure override returns (UFixed18) {
        return UFixed18Lib.ratio(1, 10000);
    }

    function makerLimit() external pure override returns (UFixed18) {
        return UFixed18Lib.from(1000);
    }
}