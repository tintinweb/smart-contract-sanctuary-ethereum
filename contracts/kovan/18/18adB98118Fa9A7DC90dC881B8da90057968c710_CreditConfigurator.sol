// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// LIBRARIES & CONSTANTS
import {DEFAULT_FEE_INTEREST, DEFAULT_FEE_LIQUIDATION, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER} from "../libraries/Constants.sol";
import {WAD} from "../libraries/WadRayMath.sol";
import {PercentageMath, PERCENTAGE_FACTOR} from "../libraries/PercentageMath.sol";

import {ACLTrait} from "../core/ACLTrait.sol";
import {CreditFacade} from "./CreditFacade.sol";
import {CreditManager} from "./CreditManager.sol";

// INTERFACES
import {ICreditConfigurator, CollateralToken, CreditManagerOpts} from "../interfaces/ICreditConfigurator.sol";
import {IAdapter} from "../interfaces/adapters/IAdapter.sol";
import {IPriceOracleV2} from "../interfaces/IPriceOracle.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

// EXCEPTIONS
import {ZeroAddressException, AddressIsNotContractException, IncorrectPriceFeedException, IncorrectTokenContractException} from "../interfaces/IErrors.sol";
import {ICreditManagerV2, ICreditManagerV2Exceptions} from "../interfaces/ICreditManagerV2.sol";

import "hardhat/console.sol";

/// @title CreditConfigurator
/// @notice This contract is designed for credit managers configuration
/// @dev All functions could be executed by Configurator role only.
/// CreditManager is desing to trust all settings done by CreditConfigurator,
/// so all sanity checks implemented here.
contract CreditConfigurator is ICreditConfigurator, ACLTrait {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    /// @dev Address provider (needed for priceOracle update)
    IAddressProvider public override addressProvider;

    /// @dev Address of credit Manager
    CreditManager public override creditManager;

    /// @dev Address of underlying token
    address public override underlying;

    // Allowed contracts array
    EnumerableSet.AddressSet private allowedContractsSet;

    // Contract version
    uint256 public constant version = 2;

    /// @dev Constructs has special role in credit management deployment
    /// It makes initial configuration for the whole bunch of contracts.
    /// The correct deployment flow is following:
    ///
    /// 1. Configures CreditManager parameters
    /// 2. Adds allowed tokens and set LT for underlying asset
    /// 3. Connects creditFacade and priceOracle with creditManager
    /// 4. Set this contract as configurator for creditManager
    ///
    /// @param _creditManager CreditManager contract instance
    /// @param _creditFacade CreditFacade contract instance
    /// @param opts Configuration parameters for CreditManager
    constructor(
        CreditManager _creditManager,
        CreditFacade _creditFacade,
        CreditManagerOpts memory opts
    )
        ACLTrait(
            address(
                IPoolService(_creditManager.poolService()).addressProvider()
            )
        )
    {
        /// Sets contract addressees
        creditManager = _creditManager; // F:[CC-1]
        underlying = creditManager.underlying(); // F:[CC-1]

        addressProvider = IPoolService(_creditManager.poolService())
        .addressProvider(); // F:[CC-1]

        /// Sets limits, fees and fastCheck parameters for credit manager
        _setParams(
            DEFAULT_FEE_INTEREST,
            DEFAULT_FEE_LIQUIDATION,
            PERCENTAGE_FACTOR - DEFAULT_LIQUIDATION_PREMIUM
        ); // F:[CC-1]

        /// Adds allowed tokens and sets their liquidation threshold
        /// collateralTokens should not have underlying in the list
        uint256 len = opts.collateralTokens.length;
        for (uint256 i = 0; i < len; ) {
            address token = opts.collateralTokens[i].token;

            _addCollateralToken(token); // F:[CC-1]

            _setLiquidationThreshold(
                token,
                opts.collateralTokens[i].liquidationThreshold
            ); // F:[CC-1]

            unchecked {
                ++i;
            }
        }

        // Connects creditFacade and sets proper priceOracle
        creditManager.upgradeContracts(
            address(_creditFacade),
            address(creditManager.priceOracle())
        ); // F:[CC-1]

        creditFacade().setLimitPerBlock(
            uint128(DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER * opts.maxBorrowedAmount)
        ); // F:[CC-1]

        _setLimits(opts.minBorrowedAmount, opts.maxBorrowedAmount); // F:[CC-1]
    }

    //
    // CONFIGURATION: TOKEN MANAGEMENT
    //

    /// @dev Adds token to the list of allowed tokens, revers if token is already added
    /// @param token Address of token to be added
    function addCollateralToken(address token, uint16 liquidationThreshold)
        external
        override
        configuratorOnly // F:[CC-2]
    {
        _addCollateralToken(token); // F:[CC-3,4]
        _setLiquidationThreshold(token, liquidationThreshold); // F:[CC-4]
    }

    /// @dev Makes all sanity checks and adds token to allowed token list
    /// @param token Address of token to be added
    function _addCollateralToken(address token) internal {
        // Checks that token != address(0)
        if (token == address(0)) revert ZeroAddressException(); // F:[CC-3]

        if (!token.isContract()) revert AddressIsNotContractException(token); // F:[CC-3]

        // Checks that contract has balanceOf method
        try IERC20(token).balanceOf(address(this)) returns (uint256) {} catch {
            revert IncorrectTokenContractException(); // F:[CC-3]
        }

        // Checks that token has priceFeed in priceOracle
        try
            IPriceOracleV2(creditManager.priceOracle()).convertToUSD(
                address(0),
                WAD,
                token
            )
        returns (uint256) {} catch {
            revert IncorrectPriceFeedException(); // F:[CC-3]
        }

        // Calls addToken in creditManager, cause all sanity checks are done
        // creditManager has additional check that the token is not added yet
        creditManager.addToken(token); // F:[CC-4]

        emit TokenAllowed(token); // F:[CC-4]
    }

    /// @dev Set Liquidation threshold for any token except underlying one
    /// @param token Token address except underlying token
    /// @param liquidationThreshold in PERCENTAGE_FORMAT (x10.000)
    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external
        configuratorOnly // F:[CC-2]
    {
        _setLiquidationThreshold(token, liquidationThreshold); // F:[CC-5]
    }

    /// @dev IMPLEMENTAION: Set Liquidation threshold for any token except underlying one
    /// @param token Token address except underlying token
    /// @param liquidationThreshold in PERCENTAGE_FORMAT (x10.000)
    function _setLiquidationThreshold(
        address token,
        uint16 liquidationThreshold
    ) internal {
        // Checks that token is not undelrying, which could not be set up directly.
        // Instead of that, it updates automatically, when creditManager parameters updated
        if (token == underlying) revert SetLTForUnderlyingException(); // F:[CC-5]

        (, uint16 ltUnderlying) = creditManager.collateralTokens(0);
        // Sanity checks for liquidation threshold. It should be >0 and less than LT for underlying token
        if (liquidationThreshold == 0 || liquidationThreshold > ltUnderlying)
            revert IncorrectLiquidationThresholdException(); // F:[CC-5]

        // It sets it in creditManager, which has additional sanity check that token exists
        creditManager.setLiquidationThreshold(token, liquidationThreshold); // F:[CC-6]
        emit TokenLiquidationThresholdUpdated(token, liquidationThreshold); // F:[CC-6]
    }

    /// @dev Allow already added token if it was forbidden before.
    /// Technically it just updates forbidmask variable which is used to detect forbidden tokens.
    /// @param token Address of allowed token
    function allowToken(address token)
        external
        configuratorOnly // F:[CC-2]
    {
        // Gets token masks. Revert if token not added or underlying one
        uint256 tokenMask = _getAndCheckTokenMaskForSettingLT(token); // F:[CC-7]

        // Gets current forbidden mask
        uint256 forbiddenTokenMask = creditManager.forbiddenTokenMask(); // F:[CC-8,9]

        // It change forbid mask in case if the token was forbidden before
        // otherwise no actions done.
        // Skipping case: F:[CC-8]
        if (forbiddenTokenMask & tokenMask != 0) {
            forbiddenTokenMask ^= tokenMask; // F:[CC-9]
            creditManager.setForbidMask(forbiddenTokenMask); // F:[CC-9]
            emit TokenAllowed(token); // F:[CC-9]
        }
    }

    /// @dev Forbids particular token. To allow token one more time use allowToken function
    /// Forbidden tokens are counted as portfolio, however, all operations which could give
    /// them as result are forbidden. Btw, it's still possible to tranfer them directly to
    /// creditAccount however, you can't swap into them directly using creditAccount funds.
    /// @param token Address of forbidden token
    function forbidToken(address token)
        external
        configuratorOnly // F:[CC-2]
    {
        // Gets token masks. Revert if token not added or underlying one
        uint256 tokenMask = _getAndCheckTokenMaskForSettingLT(token); // F:[CC-7]

        // Gets current forbidden mask
        uint256 forbiddenTokenMask = creditManager.forbiddenTokenMask();

        // It changes forbiddenTokenMask if token is allowed at the moment only
        // Skipping case: F:[CC-10]
        if (forbiddenTokenMask & tokenMask == 0) {
            forbiddenTokenMask |= tokenMask; // F:[CC-11]
            creditManager.setForbidMask(forbiddenTokenMask); // F:[CC-11]

            // It enables increase borrowing amount mode
            creditFacade().setIncreaseDebtForbidden(true); // F:[CC-11]
            emit TokenForbidden(token); // F:[CC-11]
        }
    }

    function _getAndCheckTokenMaskForSettingLT(address token)
        internal
        view
        returns (uint256 tokenMask)
    {
        // Gets tokenMask for particular token
        tokenMask = creditManager.tokenMasksMap(token); // F:[CC-7]

        // It checks that provided token is added to collateralToken list
        // It requires tokenMask !=0 && tokenMask != 1, cause underlying's mask is 1,
        // and underlying token could not be forbidden
        if (tokenMask == 0 || tokenMask == 1)
            revert ICreditManagerV2Exceptions.TokenNotAllowedException(); // F:[CC-7]
    }

    //
    // CONFIGURATION: CONTRACTS & ADAPTERS MANAGEMENT
    //

    /// @dev Adds pair [contract <-> adapter] to the list of allowed contracts
    /// or updates adapter addreess if contract already has connected adapter
    /// @param targetContract Address of allowed contract
    /// @param adapter Adapter contract address
    function allowContract(address targetContract, address adapter)
        external
        override
        configuratorOnly // F:[CC-2]
    {
        _allowContract(targetContract, adapter);
    }

    /// @dev IMPLEMENTATION: Adds pair [contract <-> adapter] to the list of allowed contracts
    /// or updates adapter addreess if contract already has connected adapter
    /// @param targetContract Address of allowed contract
    /// @param adapter Adapter contract address
    function _allowContract(address targetContract, address adapter) internal {
        // Checks that targetContract or adapter != address(0)
        if (targetContract == address(0)) revert ZeroAddressException(); // F:[CC-12]
        if (!targetContract.isContract())
            revert AddressIsNotContractException(targetContract); // F:[CC-12A]

        // Checks that adapter has the same creditManager as we'd like to connect
        _revertIfContractIncompatible(adapter); // F:[CC-12]

        // Additional check that adapter or targetContract is not
        // creditManager or creditFacade.
        // This additional check, cause call on behalf creditFacade to creditManager
        // cause it could have unexpected consequences
        if (
            targetContract == address(creditManager) ||
            targetContract == address(creditFacade()) ||
            adapter == address(creditManager) ||
            adapter == address(creditFacade())
        ) revert CreditManagerOrFacadeUsedAsAllowContractsException(); // F:[CC-13]

        // Checks that adapter or targetContract is not used in any other case
        if (
            creditManager.adapterToContract(adapter) != address(0) ||
            creditManager.contractToAdapter(targetContract) != address(0)
        ) revert AdapterUsedTwiceException(); // F:[CC-14]

        // Sets link adapter <-> targetContract to creditFacade and creditManager
        creditManager.changeContractAllowance(adapter, targetContract); // F:[CC-15]

        // add contract to the list of allowed contracts
        allowedContractsSet.add(targetContract); // F:[CC-15]

        emit ContractAllowed(targetContract, adapter); // F:[CC-15]
    }

    /// @dev Forbids contract to use with credit manager
    /// Technically it meansh, that it sets address(0) in mappings:
    /// contractToAdapter[targetContract] = address(0)
    /// adapterToContract[existingAdapter] = address(0)
    /// @param targetContract Address of contract to be forbidden
    function forbidContract(address targetContract)
        external
        override
        configuratorOnly // F:[CC-2]
    {
        // Checks that targetContract is not address(0)
        if (targetContract == address(0)) revert ZeroAddressException(); // F:[CC-12]

        // Checks that targetContract has connected adapter
        address adapter = creditManager.contractToAdapter(targetContract);
        if (adapter == address(0)) revert ContractNotInAllowedList(); // F:[CC-16]

        // Sets this map to address(0) which means that adapter / targerContract doesnt exist
        creditManager.changeContractAllowance(adapter, address(0)); // F:[CC-17]
        creditManager.changeContractAllowance(address(0), targetContract); // F:[CC-17]

        // remove contract from list of allowed contracts
        allowedContractsSet.remove(targetContract); // F:[CC-17]

        emit ContractForbidden(targetContract); // F:[CC-17]
    }

    //
    // CREDIT MANAGER MGMT
    //

    /// @dev Sets limits for borrowed amount for creditManager
    /// @param _minBorrowedAmount Minimum allowed borrowed amount for creditManager
    /// @param _maxBorrowedAmount Maximum allowed borrowed amount for creditManager
    function setLimits(uint128 _minBorrowedAmount, uint128 _maxBorrowedAmount)
        external
        configuratorOnly // F:[CC-2]
    {
        _setLimits(_minBorrowedAmount, _maxBorrowedAmount);
    }

    function _setLimits(uint128 _minBorrowedAmount, uint128 _maxBorrowedAmount)
        internal
    {
        (uint128 blockLimit, ) = creditFacade().params();
        if (
            _minBorrowedAmount > _maxBorrowedAmount ||
            _maxBorrowedAmount > blockLimit
        ) revert IncorrectLimitsException(); // F:[CC-18]

        creditFacade().setCreditAccountLimits(
            _minBorrowedAmount,
            _maxBorrowedAmount
        ); // F:[CC-19]
        emit LimitsUpdated(_minBorrowedAmount, _maxBorrowedAmount); // F:[CC-19]
    }

    /// @dev Sets fees for creditManager
    /// @param _feeInterest Percent which protocol charges additionally for interest rate
    /// @param _feeLiquidation Cut for totalValue which should be paid by Liquidator to the pool
    /// @param _liquidationPremium Discount for totalValue which becomes premium for liquidator
    function setFees(
        uint16 _feeInterest,
        uint16 _feeLiquidation,
        uint16 _liquidationPremium
    )
        external
        configuratorOnly // F:[CC-2]
    {
        // Checks that feeInterest and (liquidationPremium + feeLiquidation) in range [0..10000]
        if (
            _feeInterest >= PERCENTAGE_FACTOR ||
            (_liquidationPremium + _feeLiquidation) >= PERCENTAGE_FACTOR
        ) revert IncorrectFeesException(); // FT:[CC-23]

        _setParams(
            _feeInterest,
            _feeLiquidation,
            PERCENTAGE_FACTOR - _liquidationPremium
        ); // FT:[CC-24,25,26]

        emit FeesUpdated(_feeInterest, _feeLiquidation, _liquidationPremium); // FT:[CC-26]
    }

    /// @dev This internal function is check the need of additional sanity checks
    /// Despite on changes, these checks could be:
    /// - fastCheckParameterCoverage = maximum collateral drop could not be less than feeLiquidation
    /// - updateLiquidationThreshold = Liquidation threshold for underlying token depends on fees, so
    ///   it additionally updated all LT for other tokens if they > than new liquidation threshold
    function _setParams(
        uint16 _feeInterest,
        uint16 _feeLiquidation,
        uint16 _liquidationDiscount
    ) internal {
        uint16 newLTUnderlying = uint16(_liquidationDiscount - _feeLiquidation); // FT:[CC-25]

        (, uint16 ltUnderlying) = creditManager.collateralTokens(0);
        // Computes new liquidationThreshold and update it for undelyingToken if needed
        if (newLTUnderlying != ltUnderlying) {
            _updateLiquidationThreshold(newLTUnderlying); // F:[CC-25]
        }

        // updates params in creditManager
        creditManager.setParams(
            _feeInterest,
            _feeLiquidation,
            _liquidationDiscount
        );
    }

    /// @dev Updates Liquidation threshold for underlying asset
    ///
    function _updateLiquidationThreshold(uint16 ltUnderlying) internal {
        creditManager.setLiquidationThreshold(underlying, ltUnderlying); // F:[CC-25]

        uint256 len = creditManager.collateralTokensCount();
        for (uint256 i = 1; i < len; ) {
            (address token, uint16 lt) = creditManager.collateralTokens(i);
            if (lt > ltUnderlying) {
                creditManager.setLiquidationThreshold(token, ltUnderlying); // F:[CC-25]
            }

            unchecked {
                i++;
            }
        }
    }

    //
    // CONTRACT UPGRADES
    //

    // It upgrades priceOracle which addess is taken from addressProvider
    function upgradePriceOracle()
        external
        configuratorOnly // F:[CC-2]
    {
        address priceOracle = addressProvider.getPriceOracle();
        creditManager.upgradeContracts(address(creditFacade()), priceOracle); // F:[CC-28]
        emit PriceOracleUpgraded(priceOracle); // F:[CC-28]
    }

    /// @dev Upgrades creditFacade
    /// @param _creditFacade address of new CreditFacade
    /// @param migrateLimits Copy current limits to new CreditFacade if true
    function upgradeCreditFacade(address _creditFacade, bool migrateLimits)
        external
        configuratorOnly // F:[CC-2]
    {
        _revertIfContractIncompatible(_creditFacade); // F:[CC-29]

        (uint128 limitPerBlock, bool isIncreaseDebtFobidden) = creditFacade()
        .params();
        (uint128 minBorrowedAmount, uint128 maxBorrowedAmount) = creditFacade()
        .limits();

        creditManager.upgradeContracts(
            _creditFacade,
            address(creditManager.priceOracle())
        ); // F:[CC-30]

        if (migrateLimits) {
            _setLimitPerBlock(limitPerBlock); // F:[CC-30]
            _setLimits(minBorrowedAmount, maxBorrowedAmount); // F:[CC-30]
            _setIncreaseDebtForbidden(isIncreaseDebtFobidden); // F:[CC-30]
        }

        emit CreditFacadeUpgraded(_creditFacade); // F:[CC-30]
    }

    function upgradeCreditConfigurator(address _creditConfigurator)
        external
        configuratorOnly // F:[CC-2]
    {
        _revertIfContractIncompatible(_creditConfigurator); // F:[CC-29]

        creditManager.setConfigurator(_creditConfigurator); // F:[CC-31]
        emit CreditConfiguratorUpgraded(_creditConfigurator); // F:[CC-31]
    }

    function _revertIfContractIncompatible(address _contract) internal view {
        if (_contract == address(0)) revert ZeroAddressException(); // F:[CC-12,29]

        if (!_contract.isContract())
            revert AddressIsNotContractException(_contract); // F:[CC-12A,29]

        try CreditFacade(_contract).creditManager() returns (
            ICreditManagerV2 cm
        ) {
            if (cm != creditManager) revert IncompatibleContractException(); // F:[CC-12B,29]
        } catch {
            revert IncompatibleContractException(); // F:[CC-12B,29]
        }
    }

    function setIncreaseDebtForbidden(bool _mode)
        external
        configuratorOnly // F:[CC-2]
    {
        _setIncreaseDebtForbidden(_mode);
    }

    function _setIncreaseDebtForbidden(bool _mode) internal {
        (, bool isIncreaseDebtForbidden) = creditFacade().params(); // F:[CC-32]

        if (_mode != isIncreaseDebtForbidden) {
            creditFacade().setIncreaseDebtForbidden(_mode); // F:[CC-32]
            emit IncreaseDebtModeUpdated(_mode); // F:[CC-32]
        }
    }

    function setLimitPerBlock(uint128 newLimit)
        external
        configuratorOnly // F:[CC-2]
    {
        _setLimitPerBlock(newLimit); // F:[CC-33]
    }

    function _setLimitPerBlock(uint128 newLimit) internal {
        (uint128 maxBorrowedAmountPerBlock, ) = creditFacade().params();
        (, uint128 maxBorrowedAmount) = creditFacade().limits();

        if (newLimit < maxBorrowedAmount) revert IncorrectLimitsException(); // F:[CC-33]

        if (maxBorrowedAmountPerBlock != newLimit) {
            creditFacade().setLimitPerBlock(newLimit); // F:[CC-33]
            emit LimitPerBlockUpdated(newLimit); // F:[CC-33]
        }
    }

    //
    // GETTERS
    //

    /// @dev Returns quantity of contracts in allowed list
    function allowedContractsCount() external view override returns (uint256) {
        return allowedContractsSet.length(); // F:[CС-15]
    }

    /// @dev Returns allowed contract by index
    function allowedContracts(uint256 i)
        external
        view
        override
        returns (address)
    {
        return allowedContractsSet.at(i); // F:[CС-15]
    }

    function creditFacade() public view override returns (CreditFacade) {
        return CreditFacade(creditManager.creditFacade());
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 10%
uint16 constant DEFAULT_FEE_INTEREST = 1000; // 10%

// LIQUIDATION_FEE 2%
uint16 constant DEFAULT_FEE_LIQUIDATION = 200; // 2%

// LIQUIDATION PREMIUM
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 500; // 5%

// Default chi threshold
uint16 constant DEFAULT_CHI_THRESHOLD = 9950;

// Default full hf check interval
uint16 constant DEFAULT_HF_CHECK_INTERVAL = 4;

uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in percentage math format. 100 = 1%
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {Errors} from "./Errors.sol";

uint256 constant WAD = 1e18;
uint256 constant halfWAD = WAD / 2;
uint256 constant RAY = 1e27;
uint256 constant halfRAY = RAY / 2;
uint256 constant WAD_RAY_RATIO = 1e9;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * More info https://github.com/aave/aave-protocol/blob/master/contracts/libraries/WadRayMath.sol
 */

library WadRayMath {
    /**
     * @return One ray, 1e27
     */
    function ray() internal pure returns (uint256) {
        return RAY; // T:[WRM-1]
    }

    /**
     * @return One wad, 1e18
     */

    function wad() internal pure returns (uint256) {
        return WAD; // T:[WRM-1]
    }

    /**
     * @return Half ray, 1e27/2
     */
    function halfRay() internal pure returns (uint256) {
        return halfRAY; // T:[WRM-2]
    }

    /**
     * @return Half ray, 1e18/2
     */
    function halfWad() internal pure returns (uint256) {
        return halfWAD; // T:[WRM-2]
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0; // T:[WRM-3]
        }

        require(
            a <= (type(uint256).max - halfWAD) / b,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-3]

        return (a * b + halfWAD) / WAD; // T:[WRM-3]
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[WRM-4]
        uint256 halfB = b / 2;

        require(
            a <= (type(uint256).max - halfB) / WAD,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-4]

        return (a * WAD + halfB) / b; // T:[WRM-4]
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0; // T:[WRM-5]
        }

        require(
            a <= (type(uint256).max - halfRAY) / b,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-5]

        return (a * b + halfRAY) / RAY; // T:[WRM-5]
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[WRM-6]
        uint256 halfB = b / 2; // T:[WRM-6]

        require(
            a <= (type(uint256).max - halfB) / RAY,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-6]

        return (a * RAY + halfB) / b; // T:[WRM-6]
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2; // T:[WRM-7]
        uint256 result = halfRatio + a; // T:[WRM-7]
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW); // T:[WRM-7]

        return result / WAD_RAY_RATIO; // T:[WRM-7]
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO; // T:[WRM-8]
        require(
            result / WAD_RAY_RATIO == a,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[WRM-8]
        return result; // T:[WRM-8]
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {Errors} from "./Errors.sol";

uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0; // T:[PM-1]
        }

        //        require(
        //            value <= (type(uint256).max - HALF_PERCENT) / percentage,
        //            Errors.MATH_MULTIPLICATION_OVERFLOW
        //        ); // T:[PM-1]

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR; // T:[PM-1]
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[PM-2]
        uint256 halfPercentage = percentage / 2; // T:[PM-2]

        //        require(
        //            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
        //            Errors.MATH_MULTIPLICATION_OVERFLOW
        //        ); // T:[PM-2]

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {ACL} from "./ACL.sol";
import {ZeroAddressException, CallerNotConfiguratorException, CallerNotPausableAdminException, CallerNotUnPausableAdminException} from "../interfaces/IErrors.sol";

/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL public immutable _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        if (addressProvider == address(0)) revert ZeroAddressException(); // F:[AA-2]

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        if (!_acl.isConfigurator(msg.sender))
            revert CallerNotConfiguratorException();
        _;
    }

    ///@dev Pause contract
    function pause() external {
        if (!_acl.isPausableAdmin(msg.sender))
            revert CallerNotPausableAdminException();
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        if (!_acl.isUnpausableAdmin(msg.sender))
            revert CallerNotUnPausableAdminException();

        _unpause();
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "../interfaces/external/IWETH.sol";
import {PercentageMath, PERCENTAGE_FACTOR} from "../libraries/PercentageMath.sol";

/// INTERFACES
import {ICreditFacade, ICreditFacadeBalanceChecker, MultiCall} from "../interfaces/ICreditFacade.sol";
import {ICreditManagerV2} from "../interfaces/ICreditManagerV2.sol";
import {IPriceOracleV2} from "../interfaces/IPriceOracle.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {IDegenNFT} from "../interfaces/IDegenNFT.sol";

// CONSTANTS
import {WAD} from "../libraries/WadRayMath.sol";
import {LEVERAGE_DECIMALS} from "../libraries/Constants.sol";

// EXCEPTIONS
import {ZeroAddressException} from "../interfaces/IErrors.sol";

import "hardhat/console.sol";

struct Slot0 {
    // max borrowed amount
    uint128 maxBorrowedAmountPerBlock;
    // True if increasing debt is forbidden
    bool isIncreaseDebtForbidden;
}

struct Limits {
    // Minimal borrowed amount per credit account
    uint128 minBorrowedAmount;
    // Maximum aborrowed amount per credit account
    uint128 maxBorrowedAmount;
}

/// @title CreditFacade
/// @notice User interface for interacting with creditManager
/// @dev CreditFacade provide interface to interact with creditManager. Direct interactions
/// with creditManager are forbidden. So, there are two ways how to interact with creditManager:
/// - CreditFacade provides API for accounts management: open / close / liquidate and manage debt
/// - CreditFacade also implements multiCall feature which allows to execute bunch of orders
/// in one transaction and have only one full collateral check
/// - Adapters allow to interact with creditManager directly and implement the same API as orignial protocol
contract CreditFacade is ICreditFacade, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    Slot0 public override params;
    Limits public override limits;

    /// @dev Contracts register to check that credit manager is registered in Gearbox
    ICreditManagerV2 public immutable creditManager;

    // underlying is stored here for gas optimisation
    address public immutable underlying;

    // Allowed transfers
    mapping(address => mapping(address => bool))
        public
        override transfersAllowed;

    // Address of WETH token
    address public immutable wethAddress;

    // DegenNFT - mode, when only whitelisted users can open a credit accounts
    address public immutable override degenNFT;

    bool public immutable whitelisted;

    /// @dev Keeps both block number and total borrowed in block amount
    uint256 internal totalBorrowedInBlock;

    /// @dev Contract version
    uint256 public constant override version = 2;

    /// @dev Restricts actions for users with opened credit accounts only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditManager.creditConfigurator())
            revert CreditConfiguratorOnlyException();

        _;
    }

    /// @dev Initializes creditFacade and connects it with CreditManager
    /// @param _creditManager address of creditManager
    /// @param _degenNFT address if DegenNFT or address(0) if degen mode is not used
    constructor(address _creditManager, address _degenNFT) {
        // Additional check that _creditManager is not address(0)
        if (_creditManager == address(0)) revert ZeroAddressException(); // F:[FA-1]

        creditManager = ICreditManagerV2(_creditManager); // F:[FA-1A]
        underlying = ICreditManagerV2(_creditManager).underlying(); // F:[FA-1A]
        wethAddress = ICreditManagerV2(_creditManager).wethAddress(); // F:[FA-1A]

        degenNFT = _degenNFT; // F:[FA-1A]
        whitelisted = _degenNFT != address(0); // F:[FA-1A]
    }

    // Notice: ETH interaction
    // CreditFacade implements new flow for interacting with WETH. Despite V1, it automatically
    // wraps all provided value into WETH and immidiately sends it to msg.sender.
    // This flow requires allowance in WETH contract to creditManager, however, it makes
    // strategies more flexible, cause there is no need to compute how much ETH should be returned
    // in case it's not used in multicall for example which could be complex.

    /// @dev Opens credit account and provides credit funds as it was done in V1
    /// - Wraps ETH to WETH and sends it msg. sender is value > 0
    /// - Opens credit account (take it from account factory)
    /// - Transfers user initial funds to credit account to use them as collateral
    /// - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
    /// - Emits OpenCreditAccount event
    ///
    /// Function reverts if user has already opened position
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
    ///
    /// @param amount Borrowers own funds
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///  or a different address if the beneficiary is a different wallet
    /// @param leverageFactor Multiplier to borrowers own funds
    /// @param referralCode Referral code which is used for potential rewards. 0 if no referral code provided
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint16 leverageFactor,
        uint16 referralCode
    ) external payable override nonReentrant {
        // borrowedAmount = amount * leverageFactor
        uint256 borrowedAmount = (amount * leverageFactor) / LEVERAGE_DECIMALS; // F:[FA-5]

        _checkAndUpdateBorrowedBlockLimit(borrowedAmount); // F:[FA-11A]

        _revertIfOutOfBorrowedLimits(borrowedAmount); // F:[FA-11B]

        // Checks is it allowed to open credit account
        _revertIfOpenCreditAccountNotAllowed(onBehalfOf); // F:[FA-4A, 4B]

        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3A]

        // Gets Liquidation threshold for undelying token
        (, uint256 ltu) = creditManager.collateralTokens(0); // F:[FA-6]

        // This sanity checks come from idea that hf > 1,
        // which means (amount + borrowedAmount) * LTU > borrowedAmount
        // amount * LTU > borrowedAmount * (1 - LTU)
        if (amount * ltu <= borrowedAmount * (PERCENTAGE_FACTOR - ltu))
            revert NotEnoughCollateralException(); // F:[FA-6]

        // Opens credit accnount and gets its address
        address creditAccount = creditManager.openCreditAccount(
            borrowedAmount,
            onBehalfOf
        ); // F:[FA-5]

        // Emits openCreditAccount event before adding collateral, to make correct order
        emit OpenCreditAccount(
            onBehalfOf,
            creditAccount,
            borrowedAmount,
            referralCode
        ); // F:[FA-5]

        // Adds collateral to new credit account, if it's not revert it means that we have enough
        // collateral on credit account
        _addCollateral(onBehalfOf, creditAccount, underlying, amount); // F:[FA-5]
    }

    /// @dev Opens credit account and run a bunch of transactions for multicall
    /// - Opens credit account with desired borrowed amount
    /// - Executes multicall functions for it
    /// - Checks that the new account has enough collateral
    /// - Emits OpenCreditAccount event
    ///
    /// @param borrowedAmount Debt size
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///   or a different address if the beneficiary is a different wallet
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    /// @param referralCode Referral code which is used for potential rewards. 0 if no referral code provided
    function openCreditAccountMulticall(
        uint256 borrowedAmount,
        address onBehalfOf,
        MultiCall[] calldata calls,
        uint16 referralCode
    ) external payable override nonReentrant {
        _checkAndUpdateBorrowedBlockLimit(borrowedAmount); // F:[FA-11]

        // Checks is it allowed to open credit account
        _revertIfOpenCreditAccountNotAllowed(onBehalfOf); // F:[FA-4A, 4B]

        _revertIfOutOfBorrowedLimits(borrowedAmount); // F:[FA-11B]

        // It's forbidden to increase debt if increaseDebtForbidden mode is enabled
        if (params.isIncreaseDebtForbidden)
            revert IncreaseDebtForbiddenException(); // F:[FA-7]

        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3B]

        address creditAccount = creditManager.openCreditAccount(
            borrowedAmount,
            onBehalfOf
        ); // F:[FA-8]

        // emit new event
        emit OpenCreditAccount(
            onBehalfOf,
            creditAccount,
            borrowedAmount,
            referralCode
        ); // F:[FA-8]

        // F:[FA-10]: no free flashloans during openCreditAccount using descrease debt
        // during openCreditAccount and reverts
        if (calls.length != 0)
            _multicall(calls, onBehalfOf, creditAccount, false, true); // F:[FA-8]

        // Checks that new credit account has enough collateral to cover the debt
        creditManager.fullCollateralCheck(creditAccount); // F:[FA-8, 9]
    }

    /// @dev Run a bunch of transactions for multicall and then close credit account
    /// - Wraps ETH to WETH and sends it msg.sender is value > 0
    /// - Executes multicall functions for it (the main function is to swap all assets into undelying one)
    /// - Close credit account:
    ///    + It checks underlying token balance, if it > than funds need to be paid to pool, the debt is paid
    ///      by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from msg.sender address
    ///    + Then, if sendAllAssets is true, it transfers all non-zero balances from credit account to address "to"
    ///    + If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Emits CloseCreditAccount event
    ///
    /// @param to Address to send funds during closing contract operation
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH It true, it converts WETH token into ETH when sends it to "to" address
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        // Check for existing CA
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3C]

        // Executes multicall operations
        // [FA-13]: Checks that internal calls are forbidden during the multicall
        if (calls.length != 0)
            _multicall(calls, msg.sender, creditAccount, true, false); // F:[FA-2, 12, 13]

        // Closes credit account
        creditManager.closeCreditAccount(
            msg.sender,
            false,
            0,
            msg.sender,
            to,
            skipTokenMask,
            convertWETH
        ); // F:[FA-2, 12]

        emit CloseCreditAccount(msg.sender, to); // F:[FA-12]
    }

    /// @dev Run a bunch of transactions (multicall) and then liquidate credit account
    /// - Wraps ETH to WETH and sends it msg.sender (liquidator) is value > 0
    /// - It checks that hf < 1, otherwise it reverts
    /// - It computes the amount which should be paid back: borrowed amount + interest + fees
    /// - Executes multicall functions for it (the main function is to swap all assets into undelying one)
    /// - Close credit account:
    ///    + It checks underlying token balance, if it > than funds need to be paid to pool, the debt is paid
    ///      by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from msg.sender address
    ///    + Then, if sendAllAssets is false, it transfers all non-zero balances from credit account to address "to".
    ///      Otherwise no transfers would be made. If liquidator is confident that all assets were transffered
    ///      During multicall, this option could save gas costs.
    ///    + If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Emits LiquidateCreditAccount event
    ///
    /// @param to Address to send funds during closing contract operation
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH It true, it converts WETH token into ETH when sends it to "to" address
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    function liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable override nonReentrant {
        // Check for existing CA should be first to save gas for late liquidators
        address creditAccount = creditManager.getCreditAccountOrRevert(
            borrower
        ); // F:[FA-2]

        if (to == address(0)) revert ZeroAddressException(); // F:[FA- TODO: add check!

        (bool isLiquidatable, uint256 totalValue) = _isAccountLiquidatable(
            creditAccount
        ); // F:[FA-14]

        if (!isLiquidatable)
            revert CantLiquidateWithSuchHealthFactorException(); // F:[FA-14]

        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3D]

        if (calls.length != 0)
            _multicall(calls, borrower, creditAccount, true, false); // F:[FA-

        // Closes credit account and gets remaiingFunds which were sent to borrower
        uint256 remainingFunds = creditManager.closeCreditAccount(
            borrower,
            true,
            totalValue,
            msg.sender,
            to,
            skipTokenMask,
            convertWETH
        ); // F:[FA-

        emit LiquidateCreditAccount(borrower, msg.sender, to, remainingFunds); // F:[FA-
    }

    /// @dev Increases debt
    /// - Increase debt by tranferring funds from the pool
    /// - Updates cunulativeIndex to accrued interest rate.
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseDebt(uint256 amount) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        _increaseDebt(msg.sender, creditAccount, amount);

        // Checks that credit account has enough collater to cover new debt paramters
        creditManager.fullCollateralCheck(creditAccount); // F:[FA-17]
    }

    function _increaseDebt(
        address borrower,
        address creditAccount,
        uint256 amount
    ) internal {
        _checkAndUpdateBorrowedBlockLimit(amount); // F:[FA-18A]
        // It's forbidden to take debt by providing any collateral if increaseDebtForbidden mode is enabled
        if (params.isIncreaseDebtForbidden)
            revert IncreaseDebtForbiddenException(); // F:[FA-18C]

        uint256 newBorrowedAmount = creditManager.manageDebt(
            creditAccount,
            amount,
            true
        ); // F:[FA-17]

        _revertIfOutOfBorrowedLimits(newBorrowedAmount); // F:[FA-18B]

        emit IncreaseBorrowedAmount(borrower, amount); // F:[FA-17]
    }

    /// @dev Decrease debt
    /// - Decresase debt by paing funds back to pool
    /// - It's also include to this payment interest accrued at the moment and fees
    /// - Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param amount Amount to increase borrowed amount
    function decreaseDebt(uint256 amount) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        _decreaseDebt(msg.sender, creditAccount, amount); // F:[FA-19]

        // We need this check, cause after paying debt back, it potentially could be
        // another portfolio structure, which has lower Hf
        creditManager.fullCollateralCheck(creditAccount); // F:[FA-19]
    }

    function _decreaseDebt(
        address borrower,
        address creditAccount,
        uint256 amount
    ) internal {
        uint256 newBorrowedAmount = creditManager.manageDebt(
            creditAccount,
            amount,
            false
        ); // F:[FA-19]

        _revertIfOutOfBorrowedLimits(newBorrowedAmount); // F:[FA-20]

        emit DecreaseBorrowedAmount(borrower, amount); // F:[FA-19]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address, it should be whitelisted on CreditManagert, otherwise it reverts
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external payable override nonReentrant {
        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3E]

        address creditAccount = creditManager.getCreditAccountOrRevert(
            onBehalfOf
        ); // F:[FA-2]

        _addCollateral(onBehalfOf, creditAccount, token, amount);
    }

    function _addCollateral(
        address onBehalfOf,
        address creditAccount,
        address token,
        uint256 amount
    ) internal {
        // [FA-2]: Checks case if onBehalfOf has no account
        creditManager.addCollateral(msg.sender, creditAccount, token, amount); // F:[FA-21]
        emit AddCollateral(onBehalfOf, token, amount); // F:[FA-21]
    }

    /// @dev Executes a bunch of transactions and then make full collateral check:
    ///  - Wraps ETH and sends it back to msg.sender address, if value > 0
    ///  - Execute bunch of transactions
    ///  - Check that hf > 1 ather this bunch using fullCollateral check
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    function multicall(MultiCall[] calldata calls)
        external
        payable
        override
        nonReentrant
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );
        // Wraps ETH and sends it back to msg.sender address
        _wrapETH(); // F:[FA-3F]

        if (calls.length != 0) {
            _multicall(calls, msg.sender, creditAccount, false, false);
            creditManager.fullCollateralCheck(creditAccount);
        }
    }

    /// @dev Multicall implementation - executes bunch of transactions
    /// - Transfer ownership from borrower to this contract
    /// - Execute list of calls:
    ///   + if targetContract == address(this), it parses transaction and reroute following functions:
    ///   + addCollateral will be executed as usual. it changes borrower address to creditFacade automatically if needed
    ///   + increaseDebt works as usual
    ///   + decreaseDebt works as usual
    ///   + if targetContract == adapter (allowed, ofc), it would call this adapter. Adapter will skip additional checks
    ///     for this call
    /// @param isIncreaseDebtWasCalled - true if debt was increased during multicall. Used to prevent free freshloans
    /// it's provided as parameter, cause openCreditAccount takes debt itself.
    function _multicall(
        MultiCall[] calldata calls,
        address borrower,
        address creditAccount,
        bool isClosure,
        bool isIncreaseDebtWasCalled
    ) internal {
        // Taking ownership of contract
        creditManager.transferAccountOwnership(borrower, address(this)); // F:[FA-26]

        // Emits event for analytic purposes to track operations which are done on
        emit MultiCallStarted(borrower); // F:[FA-26]

        uint256 len = calls.length; // F:[FA-26]
        for (uint256 i = 0; i < len; ) {
            MultiCall calldata mcall = calls[i]; // F:[FA-26]

            // Reverts of calldata has less than 4 bytes
            if (mcall.callData.length < 4) revert IncorrectCallDataException(); // F:[FA-22]

            if (mcall.target == address(this)) {
                // No internal calls on closure to avoid loss manipulation
                if (isClosure) revert ForbiddenDuringClosureException(); // F:[FA-13]
                // Gets method signature to process selected method manually
                bytes4 method = bytes4(mcall.callData);

                //
                // ADD COLLATERAL
                //
                if (method == ICreditFacade.addCollateral.selector) {
                    // Parses parameters
                    (address onBehalfOf, address token, uint256 amount) = abi
                    .decode(mcall.callData[4:], (address, address, uint256)); // F:[FA-26, 27]

                    /// @notice changes onBehalf of to address(this) automatically if applicable.
                    /// It's safe, cause account trasfership were trasffered here.
                    _addCollateral(
                        onBehalfOf,
                        onBehalfOf == borrower
                            ? creditAccount
                            : creditManager.getCreditAccountOrRevert(
                                onBehalfOf
                            ),
                        token,
                        amount
                    ); // F:[FA-26, 27]
                }
                //
                // INCREASE DEBT
                //
                else if (method == ICreditFacade.increaseDebt.selector) {
                    // It's forbidden to increase debt if increaseDebtForbidden mode is enabled

                    isIncreaseDebtWasCalled = true; // F:[FA-28]

                    // Parses parameters
                    uint256 amount = abi.decode(mcall.callData[4:], (uint256)); // F:[FA-26]
                    _increaseDebt(borrower, creditAccount, amount); // F:[FA-26]
                }
                //
                // DECREASE DEBT
                //
                else if (method == ICreditFacade.decreaseDebt.selector) {
                    // it's forbidden to call descrease debt in the same multicall, where increaseDebt was called
                    if (isIncreaseDebtWasCalled)
                        revert IncreaseAndDecreaseForbiddenInOneCallException();
                    // F:[FA-28]

                    // Parses parameters
                    uint256 amount = abi.decode(mcall.callData[4:], (uint256)); // F:[FA-27]

                    // Executes manageDebt method onBehalf of address(this)
                    _decreaseDebt(borrower, creditAccount, amount); // F:[FA-27]
                } else if (
                    method ==
                    ICreditFacadeBalanceChecker.revertIfBalanceLessThan.selector
                ) {
                    (address token, uint256 minBalance) = abi.decode(
                        mcall.callData[4:],
                        (address, uint256)
                    );
                    if (IERC20(token).balanceOf(creditAccount) < minBalance)
                        revert BalanceLessThanMinimumDesired(token);
                } else if (method == ICreditFacade.enableToken.selector) {
                    address token = abi.decode(mcall.callData[4:], (address)); // TODO: CHECK
                    _enableToken(creditAccount, token); // TODO: CHECK
                } else {
                    // Reverts for unknown method
                    revert UnknownMethodException(); // F:[FA-23]
                }
            } else {
                //
                // ADAPTERS
                //

                // It double checks that target is allowed adapter and is not creditManager
                // This contract has powerfull permissons and .functionCall() to creditManager forbidden
                // Even if Configurator would add it as legal ADAPTER
                if (
                    creditManager.adapterToContract(mcall.target) ==
                    address(0) ||
                    mcall.target == address(creditManager)
                ) revert TargetContractNotAllowedExpcetion(); // F:[FA-24]

                // Checks that target is allowed adapter

                // Makes a call
                mcall.target.functionCall(mcall.callData); // F:[FA-29]
            }

            unchecked {
                i++;
            }
        }

        // Emits event for analytic that multicall is ended
        emit MultiCallFinished(); // F:[FA-27,27,29]

        // Returns transfership back
        creditManager.transferAccountOwnership(address(this), borrower); // F:[FA-27,27,29]
    }

    /// @dev Approves token of credit account for 3rd party contract
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Amount to approve
    function approve(
        address targetContract,
        address token,
        uint256 amount
    ) external override nonReentrant {
        // Checks that targetContract is allowed - it has non-zero address adapter
        if (creditManager.contractToAdapter(targetContract) == address(0))
            revert TargetContractNotAllowedExpcetion(); // F:[FA-30]

        // Checks that the token is allowed
        // [FA-2]: checks that call reverts in case if msg.sender has no credit account
        creditManager.approveCreditAccount(
            msg.sender,
            targetContract,
            token,
            amount
        ); // F:[FA-31]
    }

    /// @dev Transfers credit account to another user
    /// By default, this action is forbidden, and the user should allow sender to do that
    /// by calling approveAccountTransfer function.
    /// The logic for this approval is to eliminate sending "bad debt" to someone, who unexpect this.
    /// @param to Address which will get an account
    function transferAccountOwnership(address to)
        external
        override
        nonReentrant
    {
        if (whitelisted) revert NotAllowedInWhitelistedMode(); // F:[FA-32]

        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        // Checks that transfer is allowed
        if (!transfersAllowed[msg.sender][to])
            revert AccountTransferNotAllowedException(); // F:[FA-33]

        /// @notice It's forbidden to transfer account is they could be liquidated
        (bool isLiquidatable, ) = _isAccountLiquidatable(creditAccount); // F:[FA-34]

        if (isLiquidatable) revert CantTransferLiquidatableAccountException(); // F:[FA-34]

        // Transfer account an emits event
        creditManager.transferAccountOwnership(msg.sender, to); // F:[FA-35]
        emit TransferAccount(msg.sender, to); // F:[FA-35]
    }

    /// @dev Checks is it allowed to open credit account
    /// @param onBehalfOf Account which would own credit account
    function _revertIfOpenCreditAccountNotAllowed(address onBehalfOf) internal {
        // Check that onBehalfOf could open credit account in DegenMode
        // It takes 2K of gas to read degenMode value, comment this line
        // and in openCreditAccountMulticall if degen mode is not needed

        // F:[FA-5] covers case when degenNFT == address(0)
        if (degenNFT != address(0)) {
            // F:[FA-4B]
            if (whitelisted && msg.sender != onBehalfOf)
                revert NotAllowedInWhitelistedMode(); // F:[FA-4B]

            IDegenNFT(degenNFT).burn(onBehalfOf, 1); // F:[FA-4B]
        }

        if (
            msg.sender != onBehalfOf &&
            !transfersAllowed[msg.sender][onBehalfOf]
        ) revert AccountTransferNotAllowedException(); // F:[FA-04C]
    }

    function _checkAndUpdateBorrowedBlockLimit(uint256 amount) internal {
        if (!whitelisted) {
            // cache value cause we'll use it twice
            uint256 _limitPerBlock = params.maxBorrowedAmountPerBlock; // F:[FA-18]

            // max Limit means not params enabled
            // F:[FA-36] test case when _limitPerBlock == type(uint128).max
            if (_limitPerBlock != type(uint128).max) {
                (
                    uint64 lastBlock,
                    uint128 lastLimit
                ) = getTotalBorrowedInBlock(); // F:[FA-18, 37]

                uint256 newLimit = (lastBlock == block.number)
                    ? amount + lastLimit // F:[FA-37]
                    : amount; // F:[FA-18, 37]

                if (newLimit > _limitPerBlock)
                    revert BorrowedBlockLimitException(); // F:[FA-18]

                _updateTotalBorrowedInBlock(uint128(newLimit)); // F:[FA-37]
            }
        }
    }

    function _revertIfOutOfBorrowedLimits(uint256 borrowedAmount)
        internal
        view
    {
        // Checks that amount is in limits
        if (
            borrowedAmount < uint256(limits.minBorrowedAmount) ||
            borrowedAmount > uint256(limits.maxBorrowedAmount)
        ) revert BorrowAmountOutOfLimitsException(); // F:
    }

    function getTotalBorrowedInBlock()
        public
        view
        returns (uint64 blockLastUpdate, uint128 borrowedInBlock)
    {
        blockLastUpdate = uint64(totalBorrowedInBlock >> 128); // F:[FA-37]
        borrowedInBlock = uint128(totalBorrowedInBlock & type(uint128).max); // F:[FA-37]
    }

    function _updateTotalBorrowedInBlock(uint128 borrowedInBlock) internal {
        totalBorrowedInBlock = uint256(block.number << 128) | borrowedInBlock; // F:[FA-37]
    }

    /// @dev Approves transfer account from some particular user
    /// @param from Address which allows/forbids credit account transfer
    /// @param state True is transfer is allowed, false to be borbidden
    function approveAccountTransfer(address from, bool state)
        external
        override
        nonReentrant
    {
        transfersAllowed[from][msg.sender] = state; // F:[FA-38]
        emit TransferAccountAllowed(from, msg.sender, state); // F:[FA-38]
    }

    /// @dev Enables token in enabledTokenMask for credit account of msg.sender
    /// @param token Address of token to enable
    function enableToken(address token) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[FA-2]

        _enableToken(creditAccount, token);
    }

    function _enableToken(address creditAccount, address token) internal {
        creditManager.checkAndEnableToken(creditAccount, token); // F:[FA-39]
        emit TokenEnabled(creditAccount, token);
    }

    //
    // GETTERS
    //

    /// @dev Returns true if tokens allowed otherwise false
    function isTokenAllowed(address token)
        public
        view
        override
        returns (bool allowed)
    {
        uint256 tokenMask = creditManager.tokenMasksMap(token); // F:[FA-40]
        allowed =
            (tokenMask != 0) &&
            (creditManager.forbiddenTokenMask() & tokenMask == 0); // F:[FA-40]
    }

    /// @dev Calculates totalUSD value for provided address in underlying asset
    /// More: https://dev.gearbox.fi/developers/credit/economy#totalUSD-value
    ///
    /// @param creditAccount Token creditAccount address
    /// @return total Total value
    /// @return twv Total weighted value
    function calcTotalValue(address creditAccount)
        public
        view
        override
        returns (uint256 total, uint256 twv)
    {
        IPriceOracleV2 priceOracle = IPriceOracleV2(
            creditManager.priceOracle()
        ); // F:[FA-41]

        (uint256 totalUSD, uint256 twvUSD) = _calcTotalValueUSD(
            priceOracle,
            creditAccount
        );
        total = priceOracle.convertFromUSD(creditAccount, totalUSD, underlying); // F:[FA-41]
        twv =
            priceOracle.convertFromUSD(creditAccount, twvUSD, underlying) /
            PERCENTAGE_FACTOR; // F:[FA-41]
    }

    function _calcTotalValueUSD(
        IPriceOracleV2 priceOracle,
        address creditAccount
    ) internal view returns (uint256 totalUSD, uint256 twvUSD) {
        uint256 tokenMask = 1;
        uint256 enabledTokensMask = creditManager.enabledTokensMap(
            creditAccount
        ); // F:[FA-41]

        while (tokenMask <= enabledTokensMask) {
            if (enabledTokensMask & tokenMask != 0) {
                (address token, uint16 liquidationThreshold) = creditManager
                .collateralTokensByMask(tokenMask);
                uint256 balance = IERC20(token).balanceOf(creditAccount); // F:[FA-41]

                if (balance > 1) {
                    uint256 value = priceOracle.convertToUSD(
                        creditAccount,
                        balance,
                        token
                    ); // F:[FA-41]

                    unchecked {
                        totalUSD += value; // F:[FA-41]
                    }
                    twvUSD += value * liquidationThreshold; // F:[FA-41]
                }
            } // T:[FA-41]

            tokenMask = tokenMask << 1; // F:[FA-41]
        }
    }

    /**
     * @dev Calculates health factor for the credit account
     *
     *         sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *             borrowed amount + interest accrued
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return hf = Health factor in percents (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        public
        view
        override
        returns (uint256 hf)
    {
        (, uint256 twvUSD) = calcTotalValue(creditAccount); // F:[FA-42]
        (, uint256 borrowAmountWithInterest) = creditManager
        .calcCreditAccountAccruedInterest(creditAccount); // F:[FA-42]
        hf = (twvUSD * PERCENTAGE_FACTOR) / borrowAmountWithInterest; // F:[FA-42]
    }

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        public
        view
        override
        returns (bool)
    {
        return creditManager.creditAccounts(borrower) != address(0); // F:[FA-43]
    }

    /// @dev Wraps ETH into WETH and sends it back to msg.sender
    function _wrapETH() internal {
        if (msg.value > 0) {
            IWETH(wethAddress).deposit{value: msg.value}(); // F:[FA-3]
            IWETH(wethAddress).transfer(msg.sender, msg.value); // F:[FA-3]
        }
    }

    /// @dev Checks if account is liquidatable
    /// @param creditAccount Address of credit account to check
    /// @return isLiquidatable True if account could be liquidated
    /// @return totalValue Portfolio value
    function _isAccountLiquidatable(address creditAccount)
        internal
        view
        returns (bool isLiquidatable, uint256 totalValue)
    {
        IPriceOracleV2 priceOracle = IPriceOracleV2(
            creditManager.priceOracle()
        ); // F:[FA

        (uint256 totalUSD, uint256 twvUSD) = _calcTotalValueUSD(
            priceOracle,
            creditAccount
        );

        totalValue = priceOracle.convertFromUSD(
            creditAccount,
            totalUSD,
            underlying
        ); // F:[FA-

        (, uint256 borrowAmountWithInterest) = creditManager
        .calcCreditAccountAccruedInterest(creditAccount); // F:[FA-

        // borrowAmountPlusInterestRateUSD x 10.000 to be compared with values x LT
        uint256 borrowAmountPlusInterestRateUSD = priceOracle.convertToUSD(
            creditAccount,
            borrowAmountWithInterest,
            underlying
        ) * PERCENTAGE_FACTOR;

        // Checks that current Hf < 1
        isLiquidatable = twvUSD < borrowAmountPlusInterestRateUSD;
    }

    //
    // CONFIGURATION
    //

    function setIncreaseDebtForbidden(bool _mode)
        external
        creditConfiguratorOnly // F:[FA-44]
    {
        params.isIncreaseDebtForbidden = _mode;
    }

    function setLimitPerBlock(uint128 newLimit)
        external
        creditConfiguratorOnly // F:[FA-44]
    {
        params.maxBorrowedAmountPerBlock = newLimit;
    }

    function setCreditAccountLimits(
        uint128 _minBorrowedAmount,
        uint128 _maxBorrowedAmount
    ) external creditConfiguratorOnly {
        limits.minBorrowedAmount = _minBorrowedAmount; // F:
        limits.maxBorrowedAmount = _maxBorrowedAmount; // F:
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

// LIBRARIES
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ACLTrait} from "../core/ACLTrait.sol";

// INTERFACES
import {IAccountFactory} from "../interfaces/IAccountFactory.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ICreditManagerV2} from "../interfaces/ICreditManagerV2.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IPriceOracleV2} from "../interfaces/IPriceOracle.sol";

// CONSTANTS
import {PERCENTAGE_FACTOR} from "../libraries/PercentageMath.sol";
import {DEFAULT_FEE_INTEREST, DEFAULT_FEE_LIQUIDATION, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, LEVERAGE_DECIMALS, ALLOWANCE_THRESHOLD} from "../libraries/Constants.sol";

// EXCEPTIONS
import {ZeroAddressException} from "../interfaces/IErrors.sol";

import "hardhat/console.sol";

uint256 constant ADDR_BIT_SIZE = 160;
address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

struct Slot0 {
    // Interest fee protocol charges: fee = interest accrues * feeInterest
    uint16 feeInterest;
    // Liquidation fee protocol charges: fee = totalValue * feeLiquidation
    uint16 feeLiquidation;
    // Miltiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
    uint16 liquidationDiscount;
    // Price _priceOracle - uses in evaluation credit account
    IPriceOracleV2 priceOracle;
    // Underlying threshold
    uint16 ltUnderlying;
}

/// @title Credit Manager
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
contract CreditManager is ICreditManagerV2, ACLTrait, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @dev keeps fees & parameters commonly used together for gas savings
    Slot0 internal slot0;

    // /// @dev store min & max borrowed amount limits
    // Limits public limits;

    /// @dev maps borrowers to credit account addresses
    mapping(address => address) public override creditAccounts;

    /// @dev Account factory
    IAccountFactory public immutable _accountFactory;

    /// @dev address of underlying token
    address public immutable override underlying;

    /// @notice [DEPRICIATED]: Address of connected pool, use pool() instead!
    address public immutable override poolService;

    /// @dev address of connected pool
    address public immutable override pool;

    /// @dev address of WETH token
    address public immutable override wethAddress;

    /// @dev address of WETH Gateway
    address public immutable wethGateway;

    /// @dev address of creditFacade
    address public override creditFacade;

    /// @dev adress of creditConfigurator
    address public creditConfigurator;

    /// @dev stores address & liquidation threshold for one token in compressed way
    /// @notice use collateralTokens(uint256 i) to get uncomressed values
    mapping(uint256 => uint256) internal collateralTokensCompressed;

    uint256 public collateralTokensCount;

    /// @dev maps tokens address to their bit masks
    mapping(address => uint256) internal tokenMasksMapInternal;

    /// @dev bit mask for forbidden tokens
    uint256 public override forbiddenTokenMask;

    /// @dev maps credit account to enabled tokens bit mask
    mapping(address => uint256) public override enabledTokensMap;

    /// @dev stores cumulative drop for fast check
    mapping(address => uint256) public cumulativeDropAtFastCheck;

    /// @dev maps allowed apdaters to orginal target contracts
    mapping(address => address) public override adapterToContract;

    /// @dev Map which keeps contract to adapter (one-to-one) dependency
    mapping(address => address) public override contractToAdapter;

    /// @dev Keeps address of universal adapter which is allowed to work with many contracts
    address public universalAdapter;

    /// @dev contract version
    uint256 public constant override version = 2;

    //
    // MODIFIERS
    //

    /// @dev Restricts calls for Credit Facade or allowed adapters only
    modifier adaptersOrCreditFacadeOnly() {
        if (
            adapterToContract[msg.sender] == address(0) &&
            msg.sender != creditFacade
        ) revert AdaptersOrCreditFacadeOnlyException(); //
        _;
    }

    /// @dev Restricts calls for Credit Facade only
    modifier creditFacadeOnly() {
        if (msg.sender != creditFacade) revert CreditFacadeOnlyException();
        _;
    }

    /// @dev Restricts calls for Credit Configurator only
    modifier creditConfiguratorOnly() {
        if (msg.sender != creditConfigurator)
            revert CreditConfiguratorOnlyException();
        _;
    }

    /// @dev Constructor
    /// @param _pool Address of pool service
    constructor(address _pool)
        ACLTrait(address(IPoolService(_pool).addressProvider()))
    {
        IAddressProvider addressProvider = IPoolService(_pool)
        .addressProvider();

        pool = _pool; // F:[CM-1]
        poolService = _pool; // F:[CM-1]

        address _underlying = IPoolService(pool).underlyingToken(); // F:[CM-1]
        underlying = _underlying; // F:[CM-1]

        _addToken(_underlying); // F:[CM-1]

        wethAddress = addressProvider.getWethToken(); // F:[CM-1]
        wethGateway = addressProvider.getWETHGateway(); // F:[CM-1]
        slot0.priceOracle = IPriceOracleV2(addressProvider.getPriceOracle()); // F:[CM-1]
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory()); // F:[CM-1]
        creditConfigurator = msg.sender; // F:[CM-1]
    }

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///  @dev Opens credit account and provides credit funds.
    /// - Opens credit account (take it from account factory)
    /// - Transfers borrowed leveraged amount from pool calling lendCreditAccount() on connected Pool contract.
    /// Function reverts if user has already opened position
    ///
    /// @param borrowedAmount Margin loan amount which should be transffered to credit account
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///  or a different address if the beneficiary is a different wallet
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (address)
    {
        // Get Reusable creditAccount from account factory
        address creditAccount = _accountFactory.takeCreditAccount(
            borrowedAmount,
            IPoolService(pool).calcLinearCumulative_RAY()
        ); // F:[CM-8]

        // Transfer pool tokens to new credit account
        IPoolService(pool).lendCreditAccount(borrowedAmount, creditAccount); // F:[CM-8]

        // Checks that credit account doesn't overwrite existing one and connects it with borrower
        _safeCreditAccountSet(onBehalfOf, creditAccount); // F:[CM-7]

        // Initializes enabled tokens for credit account.
        // Enabled tokens is a bit mask which holds information which tokens were used by user
        enabledTokensMap[creditAccount] = 1; // F:[CM-8]

        return creditAccount; // F:[CM-8]
    }

    ///  @dev Closes credit account
    /// - Computes amountToPool and remaningFunds (for liquidation case only)
    /// - Checks underlying token balance:
    ///    + if it > than funds need to be paid to pool, the debt is paid by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from payer address
    /// - Then, if sendAllAssets is true, it transfers all non-zero balances from credit account to address "to"
    /// - If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Returns creditAccount to factory back
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if it's called for liquidation
    /// @param totalValue Portfolio value for liqution, 0 for ordinary closure
    /// @param payer Address which would be charged if credit account has not enough funds to cover amountToPool
    /// @param to Address to which the leftover funds will be sent
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH If true converts WETH to ETH

    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue, // 0 if not liquidated
        address payer,
        address to, // should be check != address(0)
        uint256 skipTokenMask,
        bool convertWETH
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 remainingFunds)
    {
        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6, 9, 10]

        // Makes all computations needed to close credit account
        uint256 amountToPool;
        uint256 borrowedAmount;

        {
            uint256 profit;
            uint256 loss;
            uint256 borrowedAmountWithInterest;
            (
                borrowedAmount,
                borrowedAmountWithInterest
            ) = calcCreditAccountAccruedInterest(creditAccount); // F:

            (amountToPool, remainingFunds, profit, loss) = calcClosePayments(
                totalValue,
                isLiquidated,
                borrowedAmount,
                borrowedAmountWithInterest
            ); // F:[CM-10,11,12]

            uint256 underlyingBalance = IERC20(underlying).balanceOf(
                creditAccount
            );

            // Transfers surplus in funds from credit account to "to" addrss,
            // it it has more than needed to cover all
            if (underlyingBalance > amountToPool + remainingFunds + 1) {
                unchecked {
                    _safeTokenTransfer(
                        creditAccount,
                        underlying,
                        to,
                        underlyingBalance - amountToPool - remainingFunds - 1,
                        convertWETH
                    ); // F:[CM-10,12,16]
                }
            } else {
                // Transfers money from payer account to get enough funds on credit account to
                // cover necessary payments
                unchecked {
                    IERC20(underlying).safeTransferFrom(
                        payer, // borrower or liquidator
                        creditAccount,
                        amountToPool + remainingFunds - underlyingBalance + 1
                    ); // F:F:[CM-11,13]
                }
            }

            // Transfers amountToPool to pool
            _safeTokenTransfer(
                creditAccount,
                underlying,
                pool,
                amountToPool,
                false
            ); // F:[CM-10,11,12,13]

            // Updates pool with tokens would be sent soon
            IPoolService(pool).repayCreditAccount(borrowedAmount, profit, loss); // F:[CM-10,11,12,13]
        }

        // transfer remaining funds to borrower [Liquidation case only]
        if (remainingFunds > 1) {
            _safeTokenTransfer(
                creditAccount,
                underlying,
                borrower,
                remainingFunds,
                false
            ); // F:[CM-13,18]
        }

        uint256 enabledTokensMask = enabledTokensMap[creditAccount] &
            ~skipTokenMask; // F:[CM-14]
        _transferAssetsTo(creditAccount, to, convertWETH, enabledTokensMask); // F:[CM-14,17,19]

        // Return creditAccount
        _accountFactory.returnCreditAccount(creditAccount); // F:[CM-9]

        // Release memory
        delete creditAccounts[borrower]; // F:[CM-9]
    }

    /// @dev Manages debt size for borrower:
    ///
    /// - Increase case:
    ///   + Increase debt by tranferring funds from the pool to the credit account
    ///   + Updates cunulativeIndex to accrue interest rate.
    ///
    /// - Decresase debt:
    ///   + Repay particall debt + all interest accrued at the moment + all fees accrued at the moment
    ///   + Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param creditAccount Address of credit account
    /// @param amount Amount to increase borrowed amount
    /// @param increase True fto increase debt, false to decrease
    /// @return newBorrowedAmount Updated amount
    function manageDebt(
        address creditAccount,
        uint256 amount,
        bool increase
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
        returns (uint256 newBorrowedAmount)
    {
        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen_RAY,
            uint256 cumulativeIndexNow_RAY
        ) = _getCreditAccountParameters(creditAccount);

        // Computes new amount
        newBorrowedAmount = increase
            ? borrowedAmount + amount // F:
            : borrowedAmount - amount; // F:

        uint256 newCumulativeIndex;
        if (increase) {
            // Computes new cumulative index which accrues previous debt

            newCumulativeIndex = newBorrowedAmount < (10**22)
                ? (cumulativeIndexNow_RAY *
                    cumulativeIndexAtOpen_RAY *
                    newBorrowedAmount) /
                    (cumulativeIndexNow_RAY *
                        borrowedAmount +
                        amount *
                        cumulativeIndexAtOpen_RAY)
                : (cumulativeIndexNow_RAY *
                    cumulativeIndexAtOpen_RAY *
                    (newBorrowedAmount >> 54)) /
                    (cumulativeIndexNow_RAY *
                        (borrowedAmount >> 54) +
                        (amount >> 54) *
                        cumulativeIndexAtOpen_RAY); //  F:[CM-20]

            // Lends more money from the pool
            IPoolService(pool).lendCreditAccount(amount, creditAccount); // F:[CM-20]
        } else {
            // Computes interest rate accrued at the moment
            uint256 interestAccrued = (borrowedAmount *
                cumulativeIndexNow_RAY) /
                cumulativeIndexAtOpen_RAY -
                borrowedAmount; // F:[CM-21]

            // Computes profit which comes from interest rate
            uint256 profit = (interestAccrued * slot0.feeInterest) /
                PERCENTAGE_FACTOR; // F:[CM-21]

            // Pays amount back to pool
            ICreditAccount(creditAccount).safeTransfer(
                underlying,
                pool,
                amount + interestAccrued + profit
            ); // F:[CM-21]

            // Calls repayCreditAccount to update pool values
            IPoolService(pool).repayCreditAccount(
                amount + interestAccrued,
                profit,
                0
            ); // F:[CM-21]

            // Gets updated cumulativeIndex, which could be changed after repayCreditAccount
            // to make precise calculation
            newCumulativeIndex = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-21]
        }
        //
        // Set parameters for new credit account
        ICreditAccount(creditAccount).updateParameters(
            newBorrowedAmount,
            newCumulativeIndex
        ); // F:[CM-20. 21]
    }

    /// @dev Adds collateral to borrower's credit account
    /// @param payer Address of account which will be charged to provide additional collateral
    /// @param creditAccount Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address creditAccount,
        address token,
        uint256 amount
    )
        external
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        _checkAndEnableToken(creditAccount, token); // F:[CM-22]
        IERC20(token).safeTransferFrom(payer, creditAccount, amount); // F:[CM-22]
    }

    /// @dev Transfers account ownership to another account
    /// @param from Address of previous owner
    /// @param to Address of new owner
    function transferAccountOwnership(address from, address to)
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        creditFacadeOnly // F:[CM-2]
    {
        address creditAccount = getCreditAccountOrRevert(from); // F:[CM-6]
        delete creditAccounts[from]; // F:[CM-24]

        _safeCreditAccountSet(to, creditAccount); // F:[CM-23, 24]
    }

    /// @dev Approve tokens for credit account. Restricted for adapters only
    /// @param borrower Address of borrower
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Allowanc amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
    {
        if (
            (adapterToContract[msg.sender] != targetContract &&
                msg.sender != creditFacade &&
                msg.sender != universalAdapter) || targetContract == address(0)
        ) {
            revert AdaptersOrCreditFacadeOnlyException(); // F:[CM-3,25]
        }

        // Additional check that token is connected to this CreditManager
        if (tokenMasksMap(token) == 0) revert TokenNotAllowedException(); // F:

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]

        if (!_approve(token, targetContract, creditAccount, amount, false)) {
            _approve(token, targetContract, creditAccount, 0, true); // F:
            _approve(token, targetContract, creditAccount, amount, true);
        }
    }

    function _approve(
        address token,
        address targetContract,
        address creditAccount,
        uint256 amount,
        bool revertIfFailed
    ) internal returns (bool) {
        try
            ICreditAccount(creditAccount).execute(
                token,
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    targetContract,
                    amount
                )
            )
        returns (bytes memory result) {
            if (result.length == 0 || abi.decode(result, (bool)) == true)
                return true;
        } catch {}

        if (revertIfFailed) revert AllowanceFailedExpcetion();
        return false;
    }

    /// @dev Executes filtered order on credit account which is connected with particular borrower
    /// NOTE: This function could be called by adapters only
    /// @param borrower Borrower address
    /// @param targetContract Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address targetContract,
        bytes memory data
    )
        external
        override
        whenNotPaused // F:[CM-5]
        nonReentrant
        returns (bytes memory)
    {
        // Checks that targetContract is called from allowed adapter
        if (
            adapterToContract[msg.sender] != targetContract ||
            targetContract == address(0)
        ) {
            if (msg.sender != universalAdapter)
                revert TargetContractNotAllowedExpcetion(); // F:[CM-28]
        }

        address creditAccount = getCreditAccountOrRevert(borrower); // F:[CM-6]
        emit ExecuteOrder(borrower, targetContract); // F:[CM-29]
        return ICreditAccount(creditAccount).execute(targetContract, data); // F:[CM-29]
    }

    // Checking collateral functions

    /// @dev Enables token in enableTokenMask for provided credit account,
    //  Reverts if token is not allowed (not added of forbidden)
    /// @param creditAccount Address of creditAccount (not borrower!) to check and enable
    /// @param tokenOut Address of token which would be sent to credit account
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _checkAndEnableToken(creditAccount, tokenOut); // F:[CM-30]
    }

    /// @dev Checks that token is in allowed list and updates enabledTokenMask
    /// for provided credit account if needed
    /// @param creditAccount Address of credit account
    /// @param token Address of token to be checked
    function _checkAndEnableToken(address creditAccount, address token)
        internal
    {
        uint256 tokenMask = tokenMasksMap(token); // F:[CM-30,31]

        if (tokenMask == 0 || forbiddenTokenMask & tokenMask != 0)
            revert TokenNotAllowedException(); // F:[CM-30]

        if (enabledTokensMap[creditAccount] & tokenMask == 0)
            enabledTokensMap[creditAccount] |= tokenMask; // F:[CM-31]
    }

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param balanceInBefore Balance of tokenIn before operation
    /// @param balanceOutBefore Balance of tokenOut before operation
    /// @param ltNotEqual Flag. True means we should use LT paramter for fast check
    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool ltNotEqual
    )
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _checkAndEnableToken(creditAccount, tokenOut); // [CM-32]

        uint256 balanceInAfter = IERC20(tokenIn).balanceOf(creditAccount); // F:
        uint256 balanceOutAfter = IERC20(tokenOut).balanceOf(creditAccount); // F:

        (uint256 amountInCollateral, uint256 amountOutCollateral) = slot0
        .priceOracle
        .fastCheck(
            balanceInBefore - balanceInAfter,
            tokenIn,
            balanceOutAfter - balanceOutBefore,
            tokenOut
        ); // F:[

        // Disables tokens, which has balance equals 0 (or 1)
        if (balanceInAfter <= 1) _disableToken(creditAccount, tokenIn); // F:[CM-33]

        if (ltNotEqual) {
            amountOutCollateral *= liquidationThresholds(tokenOut); // F:[CM-35]
            amountInCollateral *= liquidationThresholds(tokenIn); // F:[CM-35]
        }

        // It's okay if we got more collateral than we have before
        if (amountOutCollateral >= amountInCollateral) return; // F:[CM-34,35]

        // compute cumulative price drop in PERCENTAGE FORMAT
        uint256 cumulativeDrop = PERCENTAGE_FACTOR -
            ((amountOutCollateral * PERCENTAGE_FACTOR) / amountInCollateral) +
            cumulativeDropAtFastCheck[creditAccount]; // F:[CM-36]

        // if it drops less that feeLiquiodation - we just save it till next check
        // otherwise new fullCollateral check is required
        if (cumulativeDrop <= slot0.feeLiquidation) {
            cumulativeDropAtFastCheck[creditAccount] = cumulativeDrop; // F:[CM-36]
            return;
        }
        /// Calls for fullCollateral check if it doesn't pass fastCollaterCheck
        _fullCollateralCheck(creditAccount); // F:[CM-34,36]
        cumulativeDropAtFastCheck[creditAccount] = 1; // F:[CM-36]
    }

    /// @dev Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that twvUSD collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function fullCollateralCheck(address creditAccount)
        external
        override
        adaptersOrCreditFacadeOnly // F:[CM-3]
        nonReentrant
    {
        _fullCollateralCheck(creditAccount);
    }

    /// @dev IMPLEMENTATION: Provide full collateral check
    /// FullCollateralCheck is lazy checking that credit account has enough collateral
    /// for paying back. It stops if counts that twvUSD collateral > debt + interest rate
    /// @param creditAccount Address of credit account (not borrower!)
    function _fullCollateralCheck(address creditAccount) internal {
        (
            ,
            uint256 borrowedAmountWithInterest
        ) = calcCreditAccountAccruedInterest(creditAccount);

        IPriceOracleV2 _priceOracle = slot0.priceOracle;

        // borrowAmountPlusInterestRateUSD x 10.000 to be compared with values x LT
        uint256 borrowAmountPlusInterestRateUSD;
        unchecked {
            borrowAmountPlusInterestRateUSD = _priceOracle.convertToUSD(
                creditAccount,
                borrowedAmountWithInterest * PERCENTAGE_FACTOR,
                underlying
            );
        }

        uint256 tokenMask;
        uint256 enabledTokenMask = enabledTokensMap[creditAccount];
        uint256 len = _getMaxIndex(enabledTokenMask) + 1;

        uint256 twvUSD;

        for (uint256 i; i < len; ) {
            // we assume that farming would be used more ofthen than margin trading
            // so, the biggest funds would be allocted in LP tokens
            // which have bigger indexes
            unchecked {
                tokenMask = i == 0 ? 1 : 1 << (len - i);
            }

            // CASE enabledTokenMask & tokenMask == 0 F:[CM-38]
            if (enabledTokenMask & tokenMask != 0) {
                (
                    address token,
                    uint16 liquidationThreshold
                ) = collateralTokensByMask(tokenMask);
                uint256 balance = IERC20(token).balanceOf(creditAccount);

                // balance ==0 :
                if (balance > 1) {
                    twvUSD +=
                        _priceOracle.convertToUSD(
                            creditAccount,
                            balance,
                            token
                        ) *
                        liquidationThreshold;

                    if (twvUSD >= borrowAmountPlusInterestRateUSD) {
                        return; // F:[CM-40]
                    }
                } else {
                    _disableToken(creditAccount, token); // F:[CM-39]
                }
            }

            unchecked {
                ++i;
            }
        }

        // Require Hf > 1
        if (twvUSD < borrowAmountPlusInterestRateUSD)
            revert NotEnoughCollateralException();
    }

    /// @dev Computes all close parameters based on data
    /// @param totalValue Credit account twvUSD value
    /// @param isLiquidated True if calculations needed for liquidation
    /// @param borrowedAmount Credit account borrow amount
    /// @param borrowedAmountWithInterest Credit account borrow amount + interest rate accrued
    function calcClosePayments(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        public
        view
        override
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        amountToPool =
            borrowedAmountWithInterest +
            ((borrowedAmountWithInterest - borrowedAmount) *
                slot0.feeInterest) /
            PERCENTAGE_FACTOR; // F:[CM-43]

        if (isLiquidated) {
            // LIQUIDATION CASE
            uint256 totalFunds = (totalValue * slot0.liquidationDiscount) /
                PERCENTAGE_FACTOR; // F:[CM-43]

            amountToPool +=
                (totalValue * slot0.feeLiquidation) /
                PERCENTAGE_FACTOR; // F:[CM-43]

            unchecked {
                if (totalFunds > amountToPool) {
                    remainingFunds = totalFunds - amountToPool - 1; // F:[CM-43]
                } else {
                    amountToPool = totalFunds; // F:[CM-43]
                }

                if (totalFunds >= borrowedAmountWithInterest) {
                    profit = amountToPool - borrowedAmountWithInterest; // F:[CM-43]
                } else {
                    loss = borrowedAmountWithInterest - amountToPool; // F:[CM-43]
                }
            }
        } else {
            // CLOSURE CASE
            unchecked {
                profit = amountToPool - borrowedAmountWithInterest; // F:[CM-43]
            }
        }
    }

    /// @dev Transfers all assets from borrower credit account to "to" account and converts WETH => ETH if applicable
    /// @param creditAccount  Credit account address
    /// @param to Address to transfer all assets to
    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool convertWETH,
        uint256 enabledTokensMask
    ) internal {
        uint256 tokenMask = 2; // we start from next token that underlying one

        while (tokenMask <= enabledTokensMask) {
            if (enabledTokensMask & tokenMask != 0) {
                (address token, ) = collateralTokensByMask(tokenMask); // F:[CM-44]
                uint256 amount = IERC20(token).balanceOf(creditAccount); // F:[CM-44]
                if (amount > 2) {
                    // F:[CM-44]
                    unchecked {
                        _safeTokenTransfer(
                            creditAccount,
                            token,
                            to,
                            amount - 1, // Michael Egorov gas efficiency trick
                            convertWETH
                        ); // F:[CM-44]
                    }
                }
            }

            tokenMask = tokenMask << 1; // F:[CM-44]
        }
    }

    /// @dev Transfers token to particular address from credit account and converts WETH => ETH if applicable
    /// @param creditAccount Address of credit account
    /// @param token Token address
    /// @param to Address to transfer asset
    /// @param amount Amount to be transferred
    function _safeTokenTransfer(
        address creditAccount,
        address token,
        address to,
        uint256 amount,
        bool convertToETH
    ) internal {
        if (convertToETH && token == wethAddress) {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            ); // F:[CM-45]
            IWETHGateway(wethGateway).unwrapWETH(to, amount); // F:[CM-45]
        } else {
            ICreditAccount(creditAccount).safeTransfer(token, to, amount); // F:[CM-45]
        }
    }

    /// @dev It switching resposible bit in enableTokesMask to exclude token
    /// from collateral calculations (for gas efficiency purpose)
    function _disableToken(address creditAccount, address token) internal {
        uint256 tokenMask = tokenMasksMap(token);
        enabledTokensMap[creditAccount] &= ~tokenMask; // F:[CM-46]
    }

    //
    // GETTERS
    //

    function collateralTokens(uint256 id)
        public
        view
        returns (address token, uint16 liquidationThreshold)
    {
        return collateralTokensByMask(1 << id);
    }

    function collateralTokensByMask(uint256 tokenMask)
        public
        view
        override
        returns (address token, uint16 liquidationThreshold)
    {
        if (tokenMask == 1) {
            token = underlying; // F:[CM-47]
            liquidationThreshold = slot0.ltUnderlying;
        } else {
            uint256 collateralTokenCompressed = collateralTokensCompressed[
                tokenMask
            ]; // F:[CM-47]
            token = address(uint160(collateralTokenCompressed)); // F:[CM-47]
            liquidationThreshold = uint16(
                collateralTokenCompressed >> ADDR_BIT_SIZE
            ); // F:[CM-47]
        }
    }

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address result)
    {
        result = creditAccounts[borrower]; // F:[CM-48]
        if (result == address(0)) revert HasNoOpenedAccountException(); // F:[CM-48]
    }

    /// @dev Calculates credit account interest accrued
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        public
        view
        override
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest)
    {
        uint256 cumulativeIndexAtOpen_RAY;
        uint256 cumulativeIndexNow_RAY;
        (
            borrowedAmount,
            cumulativeIndexAtOpen_RAY,
            cumulativeIndexNow_RAY
        ) = _getCreditAccountParameters(creditAccount); // F:[CM-49]

        borrowedAmountWithInterest =
            (borrowedAmount * cumulativeIndexNow_RAY) /
            cumulativeIndexAtOpen_RAY; // F:[CM-49]
    }

    /// @dev Gets credit account generic parameters
    /// @param creditAccount Credit account address
    /// @return borrowedAmount Amount which pool lent to credit account
    /// @return cumulativeIndexAtOpen_RAY Cumulative index at open. Used for interest calculation
    function _getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen_RAY,
            uint256 cumulativeIndexNow_RAY
        )
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount(); // F:[CM-49,50]
        cumulativeIndexAtOpen_RAY = ICreditAccount(creditAccount)
        .cumulativeIndexAtOpen(); // F:[CM-49,50]
        cumulativeIndexNow_RAY = IPoolService(pool).calcLinearCumulative_RAY(); // F:[CM-49,50]
    }

    function _safeCreditAccountSet(address borrower, address creditAccount)
        internal
    {
        if (borrower == address(0) || creditAccounts[borrower] != address(0))
            revert ZeroAddressOrUserAlreadyHasAccountException(); // F:[CM-7]
        creditAccounts[borrower] = creditAccount; // F:[CM-7]
    }

    function fees()
        external
        view
        override
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount
        )
    {
        feeInterest = slot0.feeInterest; // F:[CM-51]
        feeLiquidation = slot0.feeLiquidation; // F:[CM-51]
        liquidationDiscount = slot0.liquidationDiscount; // F:[CM-51]
    }

    function priceOracle() external view override returns (IPriceOracleV2) {
        return slot0.priceOracle;
    }

    //
    // CONFIGURATION
    //
    // Foloowing functions change core credit manager parameters
    // All this functions could be called by CreditConfigurator only
    //
    function addToken(address token)
        external
        override
        creditConfiguratorOnly // F:[CM-4]
    {
        _addToken(token); // F:[CM-52]
    }

    function _addToken(address token) internal {
        if (tokenMasksMapInternal[token] > 0)
            revert TokenAlreadyAddedException(); // F:[CM-52]
        if (collateralTokensCount >= 256) revert TooMuchTokensException(); // F:[CM-52]
        uint256 tokenMask = 1 << collateralTokensCount;
        tokenMasksMapInternal[token] = tokenMask; // F:[CM-53]
        collateralTokensCompressed[tokenMask] = uint256(uint160(token)); // F:[CM-47]
        collateralTokensCount++; // F:[CM-47]
    }

    /// @dev Sets slot0. Restricted for configurator role only
    function setParams(
        uint16 _feeInterest,
        uint16 _feeLiquidation,
        uint16 _liquidationDiscount
    )
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        slot0.feeInterest = _feeInterest; // F:[CM-51]
        slot0.feeLiquidation = _feeLiquidation; // F:[CM-51]
        slot0.liquidationDiscount = _liquidationDiscount; // F:[CM-51]
    }

    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external
        override
        creditConfiguratorOnly // F:[CM-4]
    {
        if (token == underlying) {
            // F:[CM-47]
            slot0.ltUnderlying = liquidationThreshold; // F:[CM-47]
        } else {
            uint256 tokenMask = tokenMasksMap(token); // F:[CM-47, 54]
            if (tokenMask == 0) revert TokenNotAllowedException();

            collateralTokensCompressed[tokenMask] =
                (collateralTokensCompressed[tokenMask] & type(uint160).max) |
                (uint256(liquidationThreshold) << 160); // F:[CM-47]
        }
    }

    /// @dev Forbid token. To allow token one more time use allowToken function
    function setForbidMask(uint256 _forbidMask)
        external
        override
        creditConfiguratorOnly // F:[CM-4]
    {
        forbiddenTokenMask = _forbidMask; // F:[CM-55]
    }

    function changeContractAllowance(address adapter, address targetContract)
        external
        override
        creditConfiguratorOnly
    {
        if (adapter != address(0)) {
            adapterToContract[adapter] = targetContract; // F:[CM-56]
        }
        if (targetContract != address(0)) {
            contractToAdapter[targetContract] = adapter; // F:[CM-56]
        }

        if (targetContract == UNIVERSAL_CONTRACT) {
            universalAdapter = adapter; // F:[CM-56]
        }
    }

    function upgradeContracts(address _creditFacade, address _priceOracle)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditFacade = _creditFacade; // F:[CM-57]
        slot0.priceOracle = IPriceOracleV2(_priceOracle); // F:[CM-57]
    }

    function setConfigurator(address _creditConfigurator)
        external
        creditConfiguratorOnly // F:[CM-4]
    {
        creditConfigurator = _creditConfigurator; // F:[CM-58]
        emit NewConfigurator(_creditConfigurator); // F:[CM-58]
    }

    function liquidationThresholds(address token)
        public
        view
        override
        returns (uint16 lt)
    {
        if (token == underlying) return slot0.ltUnderlying; // F:[CM-47]
        uint256 tokenMask = tokenMasksMap(token);

        if (tokenMask == 0) revert TokenNotAllowedException();
        (, lt) = collateralTokensByMask(tokenMask); // F:[CM-47]
    }

    function tokenMasksMap(address token)
        public
        view
        override
        returns (uint256 mask)
    {
        mask = (token == underlying) ? 1 : tokenMasksMapInternal[token];
    }

    function _getMaxIndex(uint256 mask) internal pure returns (uint256 index) {
        if (mask == 1) return 0;

        uint256 high = 256;
        uint256 low = 1;

        while (true) {
            index = (high + low) >> 1;
            uint256 testMask = 1 << index;

            if (testMask & mask != 0 && (mask >> index == 1)) break;

            if (testMask >= mask) {
                high = index;
            } else {
                low = index;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IAddressProvider} from "./IAddressProvider.sol";
import {CreditManager} from "../credit/CreditManager.sol";
import {CreditFacade} from "../credit/CreditFacade.sol";
import {IVersion} from "./IVersion.sol";

/// @dev Struct which represents configuration for token from allowed token list
struct CollateralToken {
    address token; // Address of token
    uint16 liquidationThreshold; // LT for token in range 0..10,000 which represents 0-100%
}

/// @dev struct which represents CreditManager V2 configuration
struct CreditManagerOpts {
    uint128 minBorrowedAmount; // minimal amount for credit account
    uint128 maxBorrowedAmount; // maximum amount for credit account
    CollateralToken[] collateralTokens; // allowed tokens list
    address degenNFT; // Address of Degen NFT, address(0) for skipping degen mode
}

/// @dev CreditConfigurator Events
interface ICreditConfiguratorEvents {
    /// @dev emits each time token is allowed or liquidtion threshold changed
    event TokenLiquidationThresholdUpdated(
        address indexed token,
        uint16 liquidityThreshold
    );

    /// @dev emits each time token is allowed or liquidtion threshold changed
    event TokenAllowed(address indexed token);

    /// @dev emits each time token is allowed or liquidtion threshold changed
    event TokenForbidden(address indexed token);

    /// @dev emits each time contract is allowed or adapter changed
    event ContractAllowed(address indexed protocol, address indexed adapter);

    /// @dev emits each time contract is forbidden
    event ContractForbidden(address indexed protocol);

    /// @dev emits each time when borrowed limits are updated
    event LimitsUpdated(uint256 minBorrowedAmount, uint256 maxBorrowedAmount);

    /// @dev emits each time when fees are updated
    event FeesUpdated(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationPremium
    );

    /// @dev emits each time when priceOracle was updated
    event PriceOracleUpgraded(address indexed newPriceOracle);

    /// @dev emits each time when creditFacade was updated
    event CreditFacadeUpgraded(address indexed newCreditFacade);

    /// @dev emits each time when creditConfigurator was updated
    event CreditConfiguratorUpgraded(address indexed newCreditConfigurator);

    /// @dev emits each time DegenMode is updated
    event DegenModeUpdated(bool);

    /// @dev emits each time increase debt mode is changed
    event IncreaseDebtModeUpdated(bool);

    /// @dev emits each time borrowed limit per block is updated
    event LimitPerBlockUpdated(uint128);
}

/// @dev CreditConfigurator Exceptions
interface ICreditConfiguratorExceptions {
    /// @dev throws if configurator tries to set Liquidation Threshold directly
    error SetLTForUnderlyingException();

    /// @dev throws if liquidationThreshold is out of range (0; LT for underlying token]
    error IncorrectLiquidationThresholdException();

    /// @dev throws if feeInterest or (liquidationPremium + feeLiquidation) is out of range [0; 10.000] which means [0%; 100%]
    error IncorrectFeesException();

    /// @dev throws if potential drop during fast check more that feeLiquidation
    error FastCheckNotCoverCollateralDropException();

    /// @dev throws if minLimit > maxLimit or maxLimit > blockLimit
    error IncorrectLimitsException();

    /// @dev throws if address of CreditManager or CreditFacade was used as contract parameters in allowContract
    error CreditManagerOrFacadeUsedAsAllowContractsException();

    /// @dev throws if one contract tries to be used in 2 adapters
    error AdapterUsedTwiceException();

    /// @dev throws if adapter creditManager value != creditManager used with creditConfigurator
    error IncompatibleContractException();

    error ContractNotInAllowedList();

    /// @dev Provided chi parameters > 1
    error ChiThresholdMoreOneException();

    /// @dev throws if degenNFT is not set
    error DegenNFTnotSetException();
}

interface ICreditConfigurator is
    ICreditConfiguratorEvents,
    ICreditConfiguratorExceptions,
    IVersion
{
    //
    // STATE-CHANGING FUNCTIONS
    //

    /// @dev Adds token to the list of allowed tokens
    /// @param token Address of allowed token
    /// @param liquidationThreshold The constant showing the maximum allowable ratio of Loan-To-Value for the i-th asset.
    function addCollateralToken(address token, uint16 liquidationThreshold)
        external;

    /// @dev Adds contract to the list of allowed contracts
    /// @param targetContract Address of contract to be allowed
    /// @param adapter Adapter contract address
    function allowContract(address targetContract, address adapter) external;

    /// @dev Forbids contract and removes it from the list of allowed contracts
    /// @param targetContract Address of allowed contract
    function forbidContract(address targetContract) external;

    /// @dev Returns length of allowed contracts
    function allowedContractsCount() external view returns (uint256);

    /// @dev Returns allowed contract by index
    function allowedContracts(uint256 i) external view returns (address);

    //
    // GETTERS
    //

    /// @dev Address provider (needed for priceOracle update)
    function addressProvider() external view returns (IAddressProvider);

    /// @dev Address of creditFacade
    function creditFacade() external view returns (CreditFacade);

    /// @dev Address of credit Manager
    function creditManager() external view returns (CreditManager);

    /// @dev Address of underlying token
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {ICreditManagerV2} from "../ICreditManagerV2.sol";

enum AdapterType {
    ABSTRACT, // 0
    UNISWAP_V2, // 1
    UNISWAP_V3, // 2
    CURVE_V1_EXCHANGE_ONLY, // 3
    YEARN_V2, // 4
    CURVE_V1_2ASSETS, // 5
    CURVE_V1_3ASSETS, // 6
    CURVE_V1_4ASSETS, // 7
    CURVE_V1_STETH, // 8
    CURVE_V1_DEPOSIT, // 9
    CURVE_V1_GAUGE, // 10
    CURVE_V1_MINTER, // 11
    CONVEX_V1_BASE_REWARD_POOL, // 12
    CONVEX_V1_BOOSTER, // 13
    CONVEX_V1_CLAIM_ZAP, // 14
    LIDO_V1 // 15
}

interface IAdapterExceptions {
    error TokenIsNotInAllowedList(address);
}

interface IAdapter is IAdapterExceptions {
    /// @dev returns creditManager instance
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev returns creditFacade address
    function creditFacade() external view returns (address);

    /// @dev returns address of orignal contract
    function targetContract() external view returns (address);

    /// @dev returns type of Gearbox adapter
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @dev returns adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IPriceOracleV2Events {
    // Emits each time new configurator is set up
    event NewPriceFeed(address indexed token, address indexed priceFeed);
}

interface IPriceOracleV2Exceptions {
    /// @dev throws if returned price equals 0
    error ZeroPriceException();

    /// @dev throws if amswerInRound <  roundId
    error ChainPriceStaleException();

    /// @dev throws if there is no connected priceFeed for provided token
    error PriceOracleNotExistsException();

    /// @dev throws if procefeed depends on address however, address wasn't provided
    error PriceFeedRequiresAddressException();
}

/// @title Price oracle interface
interface IPriceOracleV2 is
    IPriceOracleV2Events,
    IPriceOracleV2Exceptions,
    IVersion
{
    /// Converts one asset into USD (decimals = 8). Reverts if priceFeed doesn't exist
    /// @param amount Amount to convert
    /// @param token Token address converts from
    /// @return Amount converted to USD
    function convertToUSD(
        address creditAccount,
        uint256 amount,
        address token
    ) external view returns (uint256);

    /// @dev Converts one asset into another using price feed rate. Reverts if price feed doesn't exist
    /// @param amount Amount to convert
    /// @param token Token address converts from
    /// @return Amount converted to tokenTo asset
    function convertFromUSD(
        address creditAccount,
        uint256 amount,
        address token
    ) external view returns (uint256);

    /// @dev Converts one asset into another using rate. Reverts if price feed doesn't exist
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Token address converts from
    /// @param tokenTo Token address - converts to
    /// @return Amount converted to tokenTo asset
    function convert(
        address creditAccount,
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    /// @dev Implements fast check, works for ERC20 tokens only
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    ) external view returns (uint256 collateralFrom, uint256 collateralTo);

    /// @dev Returns rate in USD in 8 decimals format
    /// @param creditAccount address which needs to compute price for address depended oracles
    /// @param token Token for which price is computed
    function getPrice(address creditAccount, address token)
        external
        view
        returns (uint256);

    /// @return priceFeed Address of pricefeed
    function priceFeeds(address token)
        external
        view
        returns (address priceFeed);

    /// @dev Returns pricefeed
    function priceFeedsWithFlags(address token)
        external
        view
        returns (
            address priceFeed,
            bool dependsOnAddress,
            bool skipCheck
        );
}

interface IPriceOracleV2Ext is IPriceOracleV2 {
    /// @dev Sets price feed if it doesn't exist. If price feed is already set, it changes nothing
    /// This logic is done to protect Gearbox from priceOracle attack
    /// when potential attacker can get access to price oracle, change them to fraud ones
    /// and then liquidate all funds
    /// @param token Address of token
    /// @param priceFeed Address of chainlink price feed token => Eth
    function addPriceFeed(address token, address priceFeed) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "../core/AddressProvider.sol";
import {IVersion} from "./IVersion.sol";

/// @title Pool Service Events Interface
interface IPoolServiceEvents {
    // Emits each time when LP adds liquidity to the pool
    event AddLiquidity(
        address indexed sender,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 referralCode
    );

    // Emits each time when LP removes liquidity to the pool
    event RemoveLiquidity(
        address indexed sender,
        address indexed to,
        uint256 amount
    );

    // Emits each time when Credit Manager borrows money from pool
    event Borrow(
        address indexed creditManager,
        address indexed creditAccount,
        uint256 amount
    );

    // Emits each time when Credit Manager repays money from pool
    event Repay(
        address indexed creditManager,
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    );

    // Emits each time when Interest Rate model was changed
    event NewInterestRateModel(address indexed newInterestRateModel);

    // Emits each time when new credit Manager was connected
    event NewCreditManagerConnected(address indexed creditManager);

    // Emits each time when borrow forbidden for credit manager
    event BorrowForbidden(address indexed creditManager);

    // Emits each time when uncovered (non insured) loss accrued
    event UncoveredLoss(address indexed creditManager, uint256 loss);

    // Emits after expected liquidity limit update
    event NewExpectedLiquidityLimit(uint256 newLimit);

    // Emits each time when withdraw fee is udpated
    event NewWithdrawFee(uint256 fee);

}

/// @title Pool Service Interface
/// @notice Implements business logic:
///   - Adding/removing pool liquidity
///   - Managing diesel tokens & diesel rates
///   - Lending/repaying funds to credit Manager
/// More: https://dev.gearbox.fi/developers/pool/abstractpoolservice
interface IPoolService is IPoolServiceEvents, IVersion {

    //
    // LIQUIDITY MANAGEMENT
    //

    /**
     * @dev Adds liquidity to pool
     * - transfers lp tokens to pool
     * - mint diesel (LP) tokens and provide them
     * @param amount Amount of tokens to be transfer
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external ;

    /**
     * @dev Removes liquidity from pool
     * - burns lp's diesel (LP) tokens
     * - returns underlyingToken tokens to lp
     * @param amount Amount of tokens to be transfer
     * @param to Address to transfer liquidity
     */

    function removeLiquidity(uint256 amount, address to)
        external

        returns (uint256);

    /**
     * @dev Transfers money from the pool to credit account
     * and updates the pool parameters
     * @param borrowedAmount Borrowed amount for credit account
     * @param creditAccount Credit account address
     */
    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external;

    /**
     * @dev Recalculates total borrowed & borrowRate
     * mints/burns diesel tokens
     */
    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    ) external;

    //
    // GETTERS
    //

    /**
     * @return expected pool liquidity
     */
    function expectedLiquidity() external view returns (uint256);

    /**
     * @return expected liquidity limit
     */
    function expectedLiquidityLimit() external view returns (uint256);

    /**
     * @dev Gets available liquidity in the pool (pool balance)
     * @return available pool liquidity
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @dev Calculates interest accrued from the last update using the linear model
     */
    function calcLinearCumulative_RAY() external view returns (uint256);

    /**
     * @dev Calculates borrow rate
     * @return borrow rate in RAY format
     */
    function borrowAPY_RAY() external view returns (uint256);

    /**
     * @dev Gets the amount of total borrowed funds
     * @return Amount of borrowed funds at current time
     */
    function totalBorrowed() external view returns (uint256);

    /**
     * @return Current diesel rate
     **/

    function getDieselRate_RAY() external view returns (uint256);

    /**
     * @dev underlyingToken token address getter
     * @return address of underlyingToken ERC-20 token
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Diesel(LP) token address getter
     * @return address of diesel(LP) ERC-20 token
     */
    function dieselToken() external view returns (address);

    /**
     * @dev Credit Manager address getter
     * @return address of Credit Manager contract by id
     */
    function creditManagers(uint256 id) external view returns (address);

    /**
     * @dev Credit Managers quantity
     * @return quantity of connected credit Managers
     */
    function creditManagersCount() external view returns (uint256);

    function creditManagersCanBorrow(address id) external view returns (bool);

    function toDiesel(uint256 amount) external view returns (uint256);

    function fromDiesel(uint256 amount) external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function _timestampLU() external view returns (uint256);

    function _cumulativeIndex_RAY() external view returns (uint256);

    //    function calcCumulativeIndexAtBorrowMore(
    //        uint256 amount,
    //        uint256 dAmount,
    //        uint256 cumulativeIndexAtOpen
    //    ) external view returns (uint256);

    function version() external view returns (uint256);

    function addressProvider() external view returns (AddressProvider);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";
interface IAddressProviderEvents {
    // Emits each time when new address is set
    event AddressSet(bytes32 indexed service, address indexed newAddress);
}

/// @title Optimised for front-end Address Provider interface
interface IAddressProvider is IAddressProviderEvents, IVersion {
    /// @return Address of ACL contract
    function getACL() external view returns (address);

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address);

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address);

    /// @return Address of DataCompressor
    function getDataCompressor() external view returns (address);

    /// @return Address of GEAR token
    function getGearToken() external view returns (address);

    /// @return Address of WETH token
    function getWethToken() external view returns (address);

    /// @return Address of WETH Gateway
    function getWETHGateway() external view returns (address);

    /// @return Address of PriceOracle
    function getPriceOracle() external view returns (address);

    /// @return Address of DAO Treasury Multisig
    function getTreasuryContract() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev throws if zero address is provided
error ZeroAddressException();

/// @dev throws if non implemented method was called
error NotImplementedException();

/// @dev throws if expected contract but provided non-contract address
error AddressIsNotContractException(address);

/// @dev throws if token has no balanceOf(address) method, or this method reverts
error IncorrectTokenContractException();

/// @dev throws if token has no priceFeed in PriceOracle
error IncorrectPriceFeedException();

/// @dev throw if caller is not CONFIGURATOR
error CallerNotConfiguratorException();

/// @dev throw if caller is not PAUSABLE ADMIN
error CallerNotPausableAdminException();

/// @dev throw if caller is not UNPAUSABLE ADMIN
error CallerNotUnPausableAdminException();

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IPriceOracleV2} from "./IPriceOracle.sol";
import {IVersion} from "./IVersion.sol";

interface ICreditManagerV2Events {
    /// @dev emits each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);

    /// @dev emits each time when credit configurator was updated
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    /// @dev throws if called by non-creditFacade or adapter
    error AdaptersOrCreditFacadeOnlyException();

    /// @dev throws if called by non-creditFacade
    error CreditFacadeOnlyException();

    /// @dev throws if called by non-creditConfigurator
    error CreditConfiguratorOnlyException();

    /// @dev throws if called by non-creditConfigurator
    error ZeroAddressOrUserAlreadyHasAccountException();

    /// @dev throws if target contract is now allowed
    error TargetContractNotAllowedExpcetion();

    /// @dev throws if after operation hf would be < 1
    error NotEnoughCollateralException();

    /// @dev throws if tokens is not in collateral list or forbidden
    error TokenNotAllowedException();

    /// @dev throws if allowance is failed
    error AllowanceFailedExpcetion();

    /// @dev throws if borrower has no opened credit account
    error HasNoOpenedAccountException();

    /// @dev throws if token is already in Collateral tokens list
    error TokenAlreadyAddedException();

    /// @dev throws if configurator tried to add more than 256 tokens
    error TooMuchTokensException();
}

/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///
    /// @dev Opens credit account and provides credit funds
    /// @notice This low-level function could be called by CreditFacade only!
    /// - Opens credit account (take it from account factory)
    /// - Transfers borrowed amount from pool
    /// Reverts if onBehalfOf account has already opened position
    ///
    /// @param borrowedAmount Borrowers own funds
    /// @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    ///   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    ///   is a different wallet
    ///
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    ///
    /// @dev Closes credit account (during closure or liquidation flow)
    /// @notice This low-level function could be called by CreditFacade only!
    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue,
        address caller,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function manageDebt(
        address borrower,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function version() external view returns (uint256);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approve tokens for credit account. Restricted for adapters only
    /// @param borrower Address of borrower
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Allowanc amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    function transferAccountOwnership(address from, address to) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    /// @dev Returns creditManager fees
    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount
        );

    /// @return Address of creditFacade
    function creditFacade() external view returns (address);

    /// @return Address of priceOracle
    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    // function liquidationThresholds(address token)
    //     external
    //     view
    //     returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function collateralTokens(uint256 id)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    function collateralTokensByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    /// @dev Checks that token is allowed to be used as collateral and enable it token mask.
    /// Reverts if token not allowed to be used as collateral
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external;

    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore,
        bool ltCheck
    ) external;

    function fullCollateralCheck(address creditAccount) external;

    /// @dev Returns quantity of tokens in allowed list
    function collateralTokensCount() external view returns (uint256);

    /// @dev Returns debt and debt + interest for particular credit account
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest);

    // map token address to its mask
    function tokenMasksMap(address token) external view returns (uint256);

    // Mask for forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @return Contract address connected with provided adapter
    function adapterToContract(address adapter) external view returns (address);

    /// @return Adapter address connected with particular contract
    function contractToAdapter(address adapter) external view returns (address);

    /// @dev Returns underlying token address
    function underlying() external view returns (address);

    /// @dev Returns address of connected pool, please use pool instead
    function pool() external view returns (address);

    /// @dev [DEPRICIATED]: Returns address of connected pool, please use pool instead
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Returns address of connected pool
    function creditConfigurator() external view returns (address);

    /// @dev Returns address of weth address
    function wethAddress() external view returns (address);

    /// @dev Computes close / liquidation payments
    function calcClosePayments(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        external
        view
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        );

    /// @dev Adds token to allowed tokens list
    function addToken(address token) external;

    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external;

    function setForbidMask(uint256 _forbidMask) external;

    function changeContractAllowance(address adapter, address targetContract)
        external;

    function liquidationThresholds(address) external returns (uint16);
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

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
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

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
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

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
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

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
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

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
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

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
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

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
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

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
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

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
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

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
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

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
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

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
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

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @title Errors library
library Errors {
    //
    // COMMON
    //
    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //
    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //
    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "PS3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // ACCOUNT FACTORY
    //
    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //
    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //
    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT ACCOUNT
    //
    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // ACL
    //
    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //
    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/Errors.sol";

// Repositories & services
bytes32 constant CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant ACL = "ACL";
bytes32 constant PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant TREASURY_CONTRACT = "TREASURY_CONTRACT";
bytes32 constant GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant WETH_TOKEN = "WETH_TOKEN";
bytes32 constant WETH_GATEWAY = "WETH_GATEWAY";

/// @title AddressRepository
/// @notice Stores addresses of deployed contracts
contract AddressProvider is Ownable, IAddressProvider {
    // Mapping which keeps all addresses
    mapping(bytes32 => address) public addresses;

    // Contract version
    uint256 public constant version = 2;

    constructor() {
        // @dev Emits first event for contract discovery
        emit AddressSet("ADDRESS_PROVIDER", address(this));
    }

    /// @return Address of ACL contract
    function getACL() external view returns (address) {
        return _getAddress(ACL); // F:[AP-3]
    }

    /// @dev Sets address of ACL contract
    /// @param _address Address of ACL contract
    function setACL(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(ACL, _address); // F:[AP-3]
    }

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address) {
        return _getAddress(CONTRACTS_REGISTER); // F:[AP-4]
    }

    /// @dev Sets address of ContractsRegister
    /// @param _address Address of ContractsRegister
    function setContractsRegister(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(CONTRACTS_REGISTER, _address); // F:[AP-4]
    }

    /// @return Address of PriceOracle
    function getPriceOracle() external view override returns (address) {
        return _getAddress(PRICE_ORACLE); // F:[AP-5]
    }

    /// @dev Sets address of PriceOracle
    /// @param _address Address of PriceOracle
    function setPriceOracle(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(PRICE_ORACLE, _address); // F:[AP-5]
    }

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address) {
        return _getAddress(ACCOUNT_FACTORY); // F:[AP-6]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setAccountFactory(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(ACCOUNT_FACTORY, _address); // F:[AP-6]
    }

    /// @return Address of DataCompressor
    function getDataCompressor() external view override returns (address) {
        return _getAddress(DATA_COMPRESSOR); // F:[AP-7]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setDataCompressor(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(DATA_COMPRESSOR, _address); // F:[AP-7]
    }

    /// @return Address of Treasury contract
    function getTreasuryContract() external view returns (address) {
        return _getAddress(TREASURY_CONTRACT); // F:[AP-8]
    }

    /// @dev Sets address of Treasury Contract
    /// @param _address Address of Treasury Contract
    function setTreasuryContract(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(TREASURY_CONTRACT, _address); // F:[AP-8]
    }

    /// @return Address of GEAR token
    function getGearToken() external view override returns (address) {
        return _getAddress(GEAR_TOKEN); // F:[AP-9]
    }

    /// @dev Sets address of GEAR token
    /// @param _address Address of GEAR token
    function setGearToken(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(GEAR_TOKEN, _address); // F:[AP-9]
    }

    /// @return Address of WETH token
    function getWethToken() external view override returns (address) {
        return _getAddress(WETH_TOKEN); // F:[AP-10]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWethToken(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(WETH_TOKEN, _address); // F:[AP-10]
    }

    /// @return Address of WETH token
    function getWETHGateway() external view override returns (address) {
        return _getAddress(WETH_GATEWAY); // F:[AP-11]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWETHGateway(address _address)
        external
        onlyOwner // F:[AP-12]
    {
        _setAddress(WETH_GATEWAY, _address); // F:[AP-11]
    }

    /// @return Address of key, reverts if key doesn't exist
    function _getAddress(bytes32 key) internal view returns (address) {
        address result = addresses[key];
        require(result != address(0), Errors.AS_ADDRESS_NOT_FOUND); // F:[AP-1]
        return result; // F:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11]
    }

    /// @dev Sets address to map by its key
    /// @param key Key in string format
    /// @param value Address
    function _setAddress(bytes32 key, address value) internal {
        addresses[key] = value; // F:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11]
        emit AddressSet(key, value); // F:[AP-2]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/Errors.sol";
import {IACL} from "../interfaces/IACL.sol";

/// @title ACL keeps admins addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is Ownable, IACL {
    mapping(address => bool) public pausableAdminSet;
    mapping(address => bool) public unpausableAdminSet;

    // Contract version
    uint256 public constant version = 1;

    /// @dev Adds pausable admin address
    /// @param newAdmin Address of new pausable admin
    function addPausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[newAdmin] = true; // T:[ACL-2]
        emit PausableAdminAdded(newAdmin); // T:[ACL-2]
    }

    /// @dev Removes pausable admin
    /// @param admin Address of admin which should be removed
    function removePausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[admin] = false; // T:[ACL-3]
        emit PausableAdminRemoved(admin); // T:[ACL-3]
    }

    /// @dev Returns true if the address is pausable admin and false if not
    function isPausableAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return pausableAdminSet[addr]; // T:[ACL-2,3]
    }

    /// @dev Adds unpausable admin address to the list
    /// @param newAdmin Address of new unpausable admin
    function addUnpausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[newAdmin] = true; // T:[ACL-4]
        emit UnpausableAdminAdded(newAdmin); // T:[ACL-4]
    }

    /// @dev Removes unpausable admin
    /// @param admin Address of admin to be removed
    function removeUnpausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[admin] = false; // T:[ACL-5]
        emit UnpausableAdminRemoved(admin); // T:[ACL-5]
    }

    /// @dev Returns true if the address is unpausable admin and false if not
    function isUnpausableAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if addr has configurator rights
    function isConfigurator(address account)
        external
        view
        override
        returns (bool)
    {
        return account == owner(); // T:[ACL-6]
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title IVersion
/// @dev Declare version function which returns contract version
interface IVersion {
    /// @dev Returns contract version
    function version() external view returns (uint256);
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IACLEvents {
  // emits each time when new pausable admin added
  event PausableAdminAdded(address indexed newAdmin);

  // emits each time when pausable admin removed
  event PausableAdminRemoved(address indexed admin);

  // emits each time when new unpausable admin added
  event UnpausableAdminAdded(address indexed newAdmin);

  // emits each times when unpausable admin removed
  event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IVersion {

  function isPausableAdmin(address addr) external view returns (bool);

  function isUnpausableAdmin(address addr) external view returns (bool);

  function isConfigurator(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ICreditManagerV2, ICreditManagerV2Exceptions} from "./ICreditManagerV2.sol";
import {IVersion} from "./IVersion.sol";

struct MultiCall {
    address target;
    bytes callData;
}

interface ICreditFacadeBalanceChecker {
    function revertIfBalanceLessThan(address token, uint256 minBalance)
        external;
}

interface ICreditFacadeEvents {
    /// @dev emits each time when the credit account is opened
    event OpenCreditAccount(
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 borrowAmount,
        uint16 referralCode
    );

    /// @dev emits each time when the credit account is repaid
    event CloseCreditAccount(address indexed owner, address indexed to);

    /// @dev emits each time when the credit account is liquidated
    event LiquidateCreditAccount(
        address indexed owner,
        address indexed liquidator,
        address indexed to,
        uint256 remainingFunds
    );

    /// @dev emits each time when borrower increases borrowed amount
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    /// @dev emits each time when borrower increases borrowed amount
    event DecreaseBorrowedAmount(address indexed borrower, uint256 amount);

    /// @dev emits each time when borrower adds collateral
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    /// @dev emits each time when multicall is started
    event MultiCallStarted(address indexed borrower);

    /// @dev emits each time when multicall is finished
    event MultiCallFinished();

    /// @dev emits each time when credit account is transfered
    event TransferAccount(address indexed oldOwner, address indexed newOwner);

    /// @dev emits each time when user allows to transfer Credit Account to his address
    event TransferAccountAllowed(
        address indexed from,
        address indexed to,
        bool state
    );

    /// @dev emits each time user calls enableToken
    event TokenEnabled(address creditAccount, address token);
}

interface ICreditFacadeExceptions is ICreditManagerV2Exceptions {
    /// @dev throws if action is now allowed in DegenMode
    error NotAllowedInWhitelistedMode();

    /// @dev throws id Credit Account transfer is not allowed
    error AccountTransferNotAllowedException();

    /// @dev throws if try to liquidate credit account with Hf > 1
    error CantLiquidateWithSuchHealthFactorException();

    /// @dev throws if callData length in multicall shorter than 4 bytes
    error IncorrectCallDataException();

    /// @dev throws if internal call (to CreditFacade) is in multicall
    error ForbiddenDuringClosureException();

    error IncreaseAndDecreaseForbiddenInOneCallException();

    /// @dev throws if unknown method for CreditFacade was called in multicall
    error UnknownMethodException();

    /// @dev throws if user runs openCredeitAccountMulticall or tries to increase borrowed amount when it's forbidden
    error IncreaseDebtForbiddenException();

    /// @dev throws if user thies to transfer credit account with hf < 1;
    error CantTransferLiquidatableAccountException();

    /// @dev throws if borrowed per block more than allowed
    error BorrowedBlockLimitException();

    /// @dev throws if borrowed amount is out of credit account limits
    error BorrowAmountOutOfLimitsException();

    /// @dev throws if CA has less tokens that set in Multicall
    error BalanceLessThanMinimumDesired(address);
}

/// @title Credit Facade interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditFacade is
    ICreditFacadeEvents,
    ICreditFacadeExceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    ///
    /// @dev Opens credit account and provides credit funds.
    /// - Opens credit account (take it from account factory)
    /// - Transfers trader /farmers initial funds to credit account
    /// - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
    /// - Emits OpenCreditAccount event
    /// Function reverts if user has already opened position
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
    ///
    /// @param amount Borrowers own funds
    /// @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    ///   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    ///   is a different wallet
    /// @param leverageFactor Multiplier to borrowers own funds in x100 format
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    ///   0 if the action is executed directly by the user, without any middle-man
    ///
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint16 leverageFactor,
        uint16 referralCode
    ) external payable;

    /// @dev Opens credit account and run a bunch of transactions for multicall
    /// - Opens credit account with desired borrowed amount
    /// - Executes multicall functions for it
    /// - Checks that the new account has enough collateral
    /// - Emits OpenCreditAccount event
    ///
    /// @param borrowedAmount Debt size
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///   or a different address if the beneficiary is a different wallet
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    /// @param referralCode Referral code which is used for potential rewards. 0 if no referral code provided

    function openCreditAccountMulticall(
        uint256 borrowedAmount,
        address onBehalfOf,
        MultiCall[] calldata calls,
        uint16 referralCode
    ) external payable;

    /// @dev Run a bunch of transactions for multicall and then close credit account
    /// - Wraps ETH to WETH and sends it msg.sender is value > 0
    /// - Executes multicall functions for it (the main function is to swap all assets into undelying one)
    /// - Close credit account:
    ///    + It checks underlying token balance, if it > than funds need to be paid to pool, the debt is paid
    ///      by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from msg.sender address
    ///    + Then, if sendAllAssets is true, it transfers all non-zero balances from credit account to address "to"
    ///    + If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Emits CloseCreditAccount event
    ///
    /// @param to Address to send funds during closing contract operation
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH It true, it converts WETH token into ETH when sends it to "to" address
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    function closeCreditAccount(
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Run a bunch of transactions (multicall) and then liquidate credit account
    /// - Wraps ETH to WETH and sends it msg.sender (liquidator) is value > 0
    /// - It checks that hf < 1, otherwise it reverts
    /// - It computes the amount which should be paid back: borrowed amount + interest + fees
    /// - Executes multicall functions for it (the main function is to swap all assets into undelying one)
    /// - Close credit account:
    ///    + It checks underlying token balance, if it > than funds need to be paid to pool, the debt is paid
    ///      by funds from creditAccount
    ///    + if there is no enough funds in credit Account, it withdraws all funds from credit account, and then
    ///      transfers the diff from msg.sender address
    ///    + Then, if sendAllAssets is false, it transfers all non-zero balances from credit account to address "to".
    ///      Otherwise no transfers would be made. If liquidator is confident that all assets were transffered
    ///      During multicall, this option could save gas costs.
    ///    + If convertWETH is true, the function converts WETH into ETH on the fly
    /// - Emits LiquidateCreditAccount event
    ///
    /// @param to Address to send funds during closing contract operation
    /// @param skipTokenMask Tokenmask contains 1 for tokens which needed to be skipped for sending
    /// @param convertWETH It true, it converts WETH token into ETH when sends it to "to" address
    /// @param calls Multicall structure for calls. Basic usage is to place addCollateral calls to provide collateral in
    ///   assets that differ than undelyring one
    function liquidateCreditAccount(
        address borrower,
        address to,
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] calldata calls
    ) external payable;

    /// @dev Increases debt
    /// - Increase debt by tranferring funds from the pool
    /// - Updates cunulativeIndex to accrued interest rate.
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseDebt(uint256 amount) external;

    /// @dev Decrease debt
    /// - Decresase debt by paing funds back to pool
    /// - It's also include to this payment interest accrued at the moment and fees
    /// - Updates cunulativeIndex to cumulativeIndex now
    ///
    /// @param amount Amount to increase borrowed amount
    function decreaseDebt(uint256 amount) external;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external payable;

    function multicall(MultiCall[] calldata calls) external payable;

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    /// @dev Approves token of credit account for 3rd party contract
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Amount to approve
    function approve(
        address targetContract,
        address token,
        uint256 amount
    ) external;

    function approveAccountTransfer(address from, bool state) external;

    function enableToken(address token) external;

    /// @dev Transfers credit account to another user
    /// By default, this action is forbidden, and the user should allow sender to do that
    /// by calling approveAccountTransfer function.
    /// The logic for this approval is to eliminate sending "bad debt" to someone, who unexpect this.
    /// @param to Address which will get an account
    function transferAccountOwnership(address to) external;

    //
    // GETTERS
    //

    /// @dev Calculates total value for provided address in underlying asset
    ///
    /// @param creditAccount Token creditAccount address
    /// @return total Total value
    /// @return twv Total weighted value
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total, uint256 twv);

    /// @return hf Health factor for particular credit account
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256 hf);

    /// @return True if tokens allowed otherwise false
    function isTokenAllowed(address token) external view returns (bool);

    /// @return CreditManager connected wit Facade
    function creditManager() external view returns (ICreditManagerV2);

    // @return True if 'from' account is allowed to transfer credit account to 'to' address
    function transfersAllowed(address from, address to)
        external
        view
        returns (bool);

    /// @return maxBorrowedAmountPerBlock Maximum amopunt which could be borrowed in one block
    /// @return isIncreaseDebtForbidden if increasing debt is forbidden
    function params()
        external
        view
        returns (
            uint128 maxBorrowedAmountPerBlock,
            bool isIncreaseDebtForbidden
        );

    /// @return  minBorrowedAmount minimal borrowed amount per credit account
    /// @return maxBorrowedAmount maximum borrowed amount per credit account
    function limits()
        external
        view
        returns (uint128 minBorrowedAmount, uint128 maxBorrowedAmount);

    // Address of Degen NFT. Each account with balance > 1 has access to degen mode
    function degenNFT() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IDegenNFTExceptions {
    /// @dev throws if an access-restricted function was called by non-CreditFacade
    error CreditFacadeOrConfiguratorOnlyException();

    /// @dev throws if an access-restricted function was called by non-minter
    error MinterOnlyException();

    /// @dev throws if trying to add a burner address that is not a correct CreditFacade
    error InvalidCreditFacadeException();

    /// @dev throws if the account's balance is not sufficient for an action (usually a burn)
    error InsufficientBalanceException();
}

interface IDegenNFT is IDegenNFTExceptions, IVersion {
    function minter() external view returns (address);

    function totalSupply() external view returns (uint256);

    function baseURI() external view returns (string memory);

    function mint(address, uint256) external;

    function burn(address, uint256) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";
interface IAccountFactoryEvents {
    // emits if new account miner was changed
    event AccountMinerChanged(address indexed miner);

    // emits each time when creditManager takes credit account
    event NewCreditAccount(address indexed account);

    // emits each time when creditManager takes credit account
    event InitializeCreditAccount(
        address indexed account,
        address indexed creditManager
    );

    // emits each time when pool returns credit account
    event ReturnCreditAccount(address indexed account);

    // emits each time when DAO takes account from account factory forever
    event TakeForever(address indexed creditAccount, address indexed to);
}

interface IAccountFactoryGetters {
    /// @dev Returns address of next available creditAccount
    function getNext(address creditAccount) external view returns (address);

    /// @dev Returns head of list of unused credit accounts
    function head() external view returns (address);

    /// @dev Returns tail of list of unused credit accounts
    function tail() external view returns (address);

    /// @dev Returns quantity of unused credit accounts in the stock
    function countCreditAccountsInStock() external view returns (uint256);

    /// @dev Returns credit account address by its id
    function creditAccounts(uint256 id) external view returns (address);

    /// @dev Quantity of credit accounts
    function countCreditAccounts() external view returns (uint256);
}

interface IAccountFactory is IAccountFactoryGetters, IAccountFactoryEvents, IVersion {
    /// @dev Provide new creditAccount to pool. Creates a new one, if needed
    /// @return Address of creditAccount
    function takeCreditAccount(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external returns (address);

    /// @dev Takes credit account back and stay in tn the queue
    /// @param usedAccount Address of used credit account
    function returnCreditAccount(address usedAccount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

/// @title Reusable Credit Account interface
/// @notice Implements general credit account:
///   - Keeps token balances
///   - Keeps token balances
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/creditManager/vanillacreditAccount

interface ICrediAccountExceptions {
    /// @dev throws if caller is not CreditManager
    error CallerNotCreditManagerException();

    /// @dev throws if caller is not Factory
    error CallerNotFactoryException();
}

interface ICreditAccount is  ICrediAccountExceptions, IVersion {
    /// @dev Initializes clone contract
    function initialize() external;

    /// @dev Connects credit account to credit manager
    /// @param _creditManager Credit manager address
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    //    /// @dev Set general credit account parameters. Restricted to credit managers only
    //    /// @param _borrowedAmount Amount which pool lent to credit account
    //    /// @param _cumulativeIndexAtOpen Cumulative index at open. Uses for interest calculation
    //    function setGenericParameters(
    //
    //    ) external;

    /// @dev Updates borrowed amount. Restricted to credit managers only
    /// @param _borrowedAmount Amount which pool lent to credit account
    function updateParameters(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    // /// @dev Approves particular token for swap contract
    // /// @param token ERC20 token for allowance
    // /// @param swapContract Swap contract address
    // function approveToken(address token, address swapContract) external;

    /// @dev Cancels allowance for particular contract
    /// @param token Address of token for allowance
    /// @param targetContract Address of contract to cancel allowance
    function cancelAllowance(address token, address targetContract) external;

    /// Transfers tokens from credit account to provided address. Restricted for pool calls only
    /// @param token Token which should be tranferred from credit account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @dev Returns borrowed amount
    function borrowedAmount() external view returns (uint256);

    /// @dev Returns cumulative index at time of opening credit account
    function cumulativeIndexAtOpen() external view returns (uint256);

    /// @dev Returns Block number when it was initialised last time
    function since() external view returns (uint256);

    /// @dev Address of last connected credit manager
    function creditManager() external view returns (address);

    /// @dev Address of last connected credit manager
    function factory() external view returns (address);

    /// @dev Executed financial order on 3rd party service. Restricted for pool calls only
    /// @param destination Contract address which should be called
    /// @param data Call data which should be sent
    function execute(address destination, bytes memory data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;


interface IWETHGateway {
    /// @dev convert ETH to WETH and add liqudity to pool
    /// @param pool Address of PoolService contract which where user wants to add liquidity. This pool should has WETH as underlying asset
    /// @param onBehalfOf The address that will receive the diesel tokens, same as msg.sender if the user  wants to receive them on his
    ///                   own wallet, or a different address if the beneficiary of diesel tokens is a different wallet
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    function addLiquidityETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /// @dev Removes liquidity from pool and convert WETH to ETH
    ///       - burns lp's diesel (LP) tokens
    ///       - returns underlying tokens to lp
    /// @param pool Address of PoolService contract which where user wants to withdraw liquidity. This pool should has WETH as underlying asset
    /// @param amount Amount of tokens to be transfer
    /// @param to Address to transfer liquidity
    function removeLiquidityETH(
        address pool,
        uint256 amount,
        address payable to
    ) external;

    /// @dev Opens credit account in ETH
    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
    /// @param onBehalfOf The address that we open credit account. Same as msg.sender if the user wants to open it for  his own wallet,
    ///                   or a different address if the beneficiary is a different wallet
    /// @param leverageFactor Multiplier to borrowers own funds
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    ///                     0 if the action is executed directly by the user, without any middle-man
    // function openCreditAccountETH(
    //     address creditManager,
    //     address payable onBehalfOf,
    //     uint256 leverageFactor,
    //     uint256 referralCode
    // ) external payable;

//    /// @dev Repays credit account in ETH
//    ///       - transfer borrowed money with interest + fee from borrower account to pool
//    ///       - transfer all assets to "to" account
//    /// @param creditManager Address of credit Manager. Should used WETH as underlying asset
//    /// @param to Address to send credit account assets
//    function repayCreditAccountETH(address creditManager, address to)
//        external
//        payable;
//
//    function addCollateralETH(address creditManager, address onBehalfOf)
//        external
//        payable;

    /// @dev Unwrap WETH => ETH
    /// @param to Address to send eth
    /// @param amount Amount of WETH was transferred
    function unwrapWETH(address to, uint256 amount) external;
}