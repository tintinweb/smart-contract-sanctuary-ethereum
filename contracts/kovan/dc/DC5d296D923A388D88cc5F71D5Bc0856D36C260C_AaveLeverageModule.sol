// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ==================== Internal Imports ====================

import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../../lib/AddressArrayUtil.sol";

import { ModuleBase } from "../lib/ModuleBase.sol";
import { PositionUtil } from "../lib/PositionUtil.sol";

import { AaveV2 } from "../integration/lib/AaveV2.sol";

import { IAToken } from "../../interfaces/external/aave-v2/IAToken.sol";
import { ILendingPool } from "../../interfaces/external/aave-v2/ILendingPool.sol";
import { IProtocolDataProvider } from "../../interfaces/external/aave-v2/IProtocolDataProvider.sol";
import { ILendingPoolAddressesProvider } from "../../interfaces/external/aave-v2/ILendingPoolAddressesProvider.sol";

import { IController } from "../../interfaces/IController.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";
import { IExchangeAdapter } from "../../interfaces/IExchangeAdapter.sol";
import { IDebtIssuanceModule } from "../../interfaces/IDebtIssuanceModule.sol";
import { IModuleIssuanceHook } from "../../interfaces/IModuleIssuanceHook.sol";

/**
 * @title AaveLeverageModule
 *
 * @dev Smart contract that enables leverage trading using Aave as the lending protocol.
 *
 * @notice Do not use this module in conjunction with other debt modules that allow Aave debt positions
 * as it could lead to double counting of debt when borrowed assets are the same.
 */
contract AaveLeverageModule is ModuleBase, ReentrancyGuard, AccessControl, IModuleIssuanceHook {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using PreciseUnitMath for int256;
    using PreciseUnitMath for uint256;
    using AddressArrayUtil for address[];
    using AaveV2 for IMatrixToken;
    using PositionUtil for IMatrixToken;

    // ==================== Constants ====================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // This module only supports borrowing in variable rate mode from Aave which is represented by 2
    uint256 internal constant BORROW_RATE_MODE = 2;

    // String identifying the DebtIssuanceModule in the IntegrationRegistry.
    // Note: Governance must add DefaultIssuanceModule as the string as the integration name
    string internal constant DEFAULT_ISSUANCE_MODULE_NAME = "DEFAULT_ISSUANCE_MODULE";

    // 0 index stores protocol fee % on the controller, charged in the _executeTrade function
    uint256 internal constant PROTOCOL_TRADE_FEE_INDEX = 0;

    // ==================== Structs ====================

    struct EnabledAssets {
        address[] collateralAssets; // Array of enabled underlying collateral assets for a MatrixToken
        address[] borrowAssets; // Array of enabled underlying borrow assets for a MatrixToken
    }

    struct ReserveTokens {
        IAToken aToken; // Reserve's aToken instance
        IERC20 variableDebtToken; // Reserve's variable debt token instance, IVariableDebtToken
    }

    struct ActionInfo {
        uint256 matrixTotalSupply; // Total supply of MatrixToken
        uint256 notionalSendQuantity; // Total notional quantity sent to exchange
        uint256 minNotionalReceiveQuantity; // Min total notional received from exchange
        uint256 preTradeReceiveTokenBalance; // Balance of pre-trade receive token balance
        IMatrixToken matrixToken; // MatrixToken instance
        ILendingPool lendingPool; // Lending pool instance, we grab this everytime since it's best practice not to store
        IExchangeAdapter exchangeAdapter; // Exchange adapter instance
        IERC20 collateralAsset; // Address of collateral asset
        IERC20 borrowAsset; // Address of borrow asset
    }

    // ==================== Variables ====================

    // Mapping to efficiently fetch reserve token addresses. Tracking Aave reserve token addresses
    // and updating them upon requirement is more efficient than fetching them each time from Aave.
    // Note: For an underlying asset to be enabled as collateral/borrow asset on MatrixToken, it must be added to this mapping first.
    mapping(IERC20 => ReserveTokens) internal _underlyingToReserveTokens;

    // Used to fetch reserves and user data from AaveV2
    IProtocolDataProvider internal immutable _protocolDataProvider;

    // Used to fetch lendingPool address. This contract is immutable and its address will never change.
    ILendingPoolAddressesProvider internal immutable _lendingPoolAddressesProvider;

    // Mapping to efficiently check if collateral asset is enabled in MatrixToken
    mapping(IMatrixToken => mapping(IERC20 => bool)) internal _isEnabledCollateralAsset;

    // Mapping to efficiently check if a borrow asset is enabled in MatrixToken
    mapping(IMatrixToken => mapping(IERC20 => bool)) internal _isEnabledBorrowAsset;

    // Internal mapping of enabled collateral and borrow tokens for syncing positions
    mapping(IMatrixToken => EnabledAssets) internal _enabledAssets;

    // Mapping of MatrixToken to boolean indicating if MatrixToken is on allow list. Updateable by governance
    mapping(IMatrixToken => bool) internal _isAllowedMatrixTokens;

    // Boolean that returns if any MatrixToken can initialize this module. If false, then subject to allow list. Updateable by governance.
    bool internal _isAnyMatrixAllowed;

    // ==================== Events ====================

    /**
     * @param matrixToken           Instance of the MatrixToken being levered
     * @param borrowAsset           Asset being borrowed for leverage
     * @param collateralAsset       Collateral asset being levered
     * @param exchangeAdapter       Exchange adapter used for trading
     * @param totalBorrowAmount     Total amount of `borrowAsset` borrowed
     * @param totalReceiveAmount    Total amount of `collateralAsset` received by selling `borrowAsset`
     * @param protocolFee           Protocol fee charged
     */
    event IncreaseLeverage(
        IMatrixToken indexed matrixToken,
        IERC20 indexed borrowAsset,
        IERC20 indexed collateralAsset,
        IExchangeAdapter exchangeAdapter,
        uint256 totalBorrowAmount,
        uint256 totalReceiveAmount,
        uint256 protocolFee
    );

    /**
     * @param matrixToken          Instance of the MatrixToken being delevered
     * @param collateralAsset      Asset sold to decrease leverage
     * @param repayAsset           Asset being bought to repay to Aave
     * @param exchangeAdapter      Exchange adapter used for trading
     * @param totalRedeemAmount    Total amount of `collateralAsset` being sold
     * @param totalRepayAmount     Total amount of `repayAsset` being repaid
     * @param protocolFee          Protocol fee charged
     */
    event DecreaseLeverage(
        IMatrixToken indexed matrixToken,
        IERC20 indexed collateralAsset,
        IERC20 indexed repayAsset,
        IExchangeAdapter exchangeAdapter,
        uint256 totalRedeemAmount,
        uint256 totalRepayAmount,
        uint256 protocolFee
    );

    /**
     * @param matrixToken    Instance of MatrixToken whose collateral assets is updated
     * @param added          true if assets are added false if removed
     * @param assets         Array of collateral assets being added/removed
     */
    event UpdateCollateralAssets(IMatrixToken indexed matrixToken, bool indexed added, IERC20[] assets);

    /**
     * @param matrixToken    Instance of MatrixToken whose borrow assets is updated
     * @param added          true if assets are added false if removed
     * @param assets         Array of borrow assets being added/removed
     */
    event UpdateBorrowAssets(IMatrixToken indexed matrixToken, bool indexed added, IERC20[] assets);

    /**
     * @param underlying           Address of the underlying asset
     * @param aToken               Updated aave reserve aToken
     * @param variableDebtToken    Updated aave reserve variable debt token
     */
    event UpdateReserveTokens(IERC20 indexed underlying, IAToken indexed aToken, IERC20 indexed variableDebtToken);

    /**
     * @param matrixToken    MatrixToken being whose allowance to initialize this module is being updated
     * @param added          true if added; false if removed
     */
    event UpdateMatrixTokenStatus(IMatrixToken indexed matrixToken, bool indexed added);

    /**
     * @param anyMatrixAllowed    true if any set is allowed to initialize this module, false otherwise
     */
    event UpdateAnyMatrixAllowed(bool indexed anyMatrixAllowed);

    // ==================== Constructor function ====================

    constructor(IController controller, ILendingPoolAddressesProvider lendingPoolAddressesProvider) ModuleBase(controller) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());

        _lendingPoolAddressesProvider = lendingPoolAddressesProvider;

        // Each market has a separate Protocol Data Provider. To get the address for a particular market, call getAddress() using the value 0x01.
        // Use the raw input vs bytes32() conversion. This is to ensure the input is an uint and not a string.
        bytes32 value01 = 0x0100000000000000000000000000000000000000000000000000000000000000;
        IProtocolDataProvider protocolDataProvider = IProtocolDataProvider(lendingPoolAddressesProvider.getAddress(value01));

        _protocolDataProvider = protocolDataProvider;
        IProtocolDataProvider.TokenData[] memory reserveTokens = protocolDataProvider.getAllReservesTokens();
        for (uint256 i = 0; i < reserveTokens.length; i++) {
            (address aToken, , address variableDebtToken) = protocolDataProvider.getReserveTokensAddresses(reserveTokens[i].tokenAddress);
            _underlyingToReserveTokens[IERC20(reserveTokens[i].tokenAddress)] = ReserveTokens({
                aToken: IAToken(aToken),
                variableDebtToken: IERC20(variableDebtToken)
            });
        }
    }

    // ==================== Modifier functions ====================

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    // ==================== External functions ====================

    function getUnderlyingToReserveTokens(IERC20 asset) external view returns (ReserveTokens memory) {
        return _underlyingToReserveTokens[asset];
    }

    function getProtocolDataProvider() external view returns (IProtocolDataProvider) {
        return _protocolDataProvider;
    }

    function getLendingPoolAddressesProvider() external view returns (ILendingPoolAddressesProvider) {
        return _lendingPoolAddressesProvider;
    }

    function isEnabledCollateralAsset(IMatrixToken matrixToken, IERC20 asset) external view returns (bool) {
        return _isEnabledCollateralAsset[matrixToken][asset];
    }

    function isEnabledBorrowAsset(IMatrixToken matrixToken, IERC20 asset) external view returns (bool) {
        return _isEnabledBorrowAsset[matrixToken][asset];
    }

    function getEnabledAssets(IMatrixToken matrixToken) external view returns (address[] memory collateralAssets, address[] memory borrowAssets) {
        EnabledAssets storage enabledAssets = _enabledAssets[matrixToken];
        collateralAssets = enabledAssets.collateralAssets;
        borrowAssets = enabledAssets.borrowAssets;
    }

    function isAllowedMatrixToken(IMatrixToken matrixToken) external view returns (bool) {
        return _isAllowedMatrixTokens[matrixToken];
    }

    function isAnyMatrixAllowed() external view returns (bool) {
        return _isAnyMatrixAllowed;
    }

    /**
     * @dev MANAGER ONLY: Increases leverage for a given collateral position using an enabled borrow asset. Borrows borrowAsset from Aave.
     * Performs a DEX trade, exchanging the borrowAsset for collateralAsset. Deposits collateralAsset to Aave and mints corresponding aToken.
     * @notice Both collateral and borrow assets need to be enabled, and they must not be the same asset.
     *
     * @param matrixToken                Instance of the MatrixToken
     * @param borrowAsset                Address of underlying asset being borrowed for leverage
     * @param collateralAsset            Address of underlying collateral asset
     * @param borrowQuantityUnits        Borrow quantity of asset in position units
     * @param minReceiveQuantityUnits    Min receive quantity of collateral asset to receive post-trade in position units
     * @param tradeAdapterName           Name of trade adapter
     * @param tradeData                  Arbitrary data for trade
     */
    function lever(
        IMatrixToken matrixToken,
        IERC20 borrowAsset,
        IERC20 collateralAsset,
        uint256 borrowQuantityUnits,
        uint256 minReceiveQuantityUnits,
        string memory tradeAdapterName,
        bytes memory tradeData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) {
        ActionInfo memory leverInfo = _createAndValidateActionInfo(
            matrixToken,
            borrowAsset, // sendToken
            collateralAsset, // receiveToken
            borrowQuantityUnits, // sendQuantityUnits
            minReceiveQuantityUnits, // minReceiveQuantityUnits
            tradeAdapterName,
            true // isLever
        );

        _borrow(leverInfo.matrixToken, leverInfo.lendingPool, leverInfo.borrowAsset, leverInfo.notionalSendQuantity);
        uint256 postTradeReceiveQuantity = _executeTrade(leverInfo, borrowAsset, collateralAsset, tradeData);
        uint256 protocolFee = _accrueProtocolFee(matrixToken, collateralAsset, postTradeReceiveQuantity);
        uint256 postTradeCollateralQuantity = postTradeReceiveQuantity - protocolFee;
        _deposit(leverInfo.matrixToken, leverInfo.lendingPool, collateralAsset, postTradeCollateralQuantity);
        _updateLeverPositions(leverInfo, borrowAsset);

        emit IncreaseLeverage(
            matrixToken,
            borrowAsset,
            collateralAsset,
            leverInfo.exchangeAdapter,
            leverInfo.notionalSendQuantity,
            postTradeCollateralQuantity,
            protocolFee
        );
    }

    /**
     * @dev MANAGER ONLY: Decrease leverage for a given collateral position using an enabled borrow asset. Withdraws collateralAsset from Aave.
     * Performs a DEX trade, exchanging the collateralAsset for repayAsset. Repays repayAsset to Aave and burns corresponding debt tokens.
     * @notice Both collateral and borrow assets need to be enabled, and they must not be the same asset.
     *
     * @param matrixToken              Instance of the MatrixToken
     * @param collateralAsset          Address of underlying collateral asset being withdrawn
     * @param repayAsset               Address of underlying borrowed asset being repaid
     * @param redeemQuantityUnits      Quantity of collateral asset to delever in position units
     * @param minRepayQuantityUnits    Minimum amount of repay asset to receive post trade in position units
     * @param tradeAdapterName         Name of trade adapter
     * @param tradeData                Arbitrary data for trade
     */
    function delever(
        IMatrixToken matrixToken,
        IERC20 collateralAsset,
        IERC20 repayAsset,
        uint256 redeemQuantityUnits,
        uint256 minRepayQuantityUnits,
        string memory tradeAdapterName,
        bytes memory tradeData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) {
        ActionInfo memory deleverInfo = _createAndValidateActionInfo(
            matrixToken,
            collateralAsset, // sendToken
            repayAsset, // receiveToken
            redeemQuantityUnits, // sendQuantityUnits
            minRepayQuantityUnits, // minReceiveQuantityUnits
            tradeAdapterName,
            false // isLever
        );

        _withdraw(deleverInfo.matrixToken, deleverInfo.lendingPool, collateralAsset, deleverInfo.notionalSendQuantity);
        uint256 postTradeReceiveQuantity = _executeTrade(deleverInfo, collateralAsset, repayAsset, tradeData);
        uint256 protocolFee = _accrueProtocolFee(matrixToken, repayAsset, postTradeReceiveQuantity);
        uint256 repayQuantity = postTradeReceiveQuantity - protocolFee;
        _repayBorrow(deleverInfo.matrixToken, deleverInfo.lendingPool, repayAsset, repayQuantity);
        _updateDeleverPositions(deleverInfo, repayAsset);

        emit DecreaseLeverage(
            matrixToken,
            collateralAsset,
            repayAsset,
            deleverInfo.exchangeAdapter,
            deleverInfo.notionalSendQuantity,
            repayQuantity,
            protocolFee
        );
    }

    /** @dev MANAGER ONLY: Pays down the borrow asset to 0 selling off a given amount of collateral asset. Withdraws collateralAsset from Aave. Performs a DEX trade,
     * exchanging the collateralAsset for repayAsset. Minimum receive amount for the DEX trade is set to the current variable debt balance of the borrow asset.
     * Repays received repayAsset to Aave which burns corresponding debt tokens. Any extra received borrow asset is updated as equity. No protocol fee is charged.
     * @notice Both collateral and borrow assets need to be enabled, and they must not be the same asset.
     * The function reverts if not enough collateral asset is redeemed to buy the required minimum amount of repayAsset.
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param collateralAsset        Address of underlying collateral asset being redeemed
     * @param repayAsset             Address of underlying asset being repaid
     * @param redeemQuantityUnits    Quantity of collateral asset to delever in position units
     * @param tradeAdapterName       Name of trade adapter
     * @param tradeData              Arbitrary data for trade
     *
     * @return uint256               Notional repay quantity
     */
    function deleverToZeroBorrowBalance(
        IMatrixToken matrixToken,
        IERC20 collateralAsset,
        IERC20 repayAsset,
        uint256 redeemQuantityUnits,
        string memory tradeAdapterName,
        bytes memory tradeData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) returns (uint256) {
        require(_isEnabledBorrowAsset[matrixToken][repayAsset], "L0a"); // "Borrow not enabled"

        uint256 notionalRepayQuantity = _underlyingToReserveTokens[repayAsset].variableDebtToken.balanceOf(address(matrixToken));
        require(notionalRepayQuantity > 0, "L0b"); // "Borrow balance is zero"

        uint256 matrixTotalSupply = matrixToken.totalSupply();
        uint256 notionalRedeemQuantity = redeemQuantityUnits.preciseMul(matrixTotalSupply);
        ActionInfo memory deleverInfo = _createAndValidateActionInfoNotional(
            matrixToken,
            collateralAsset, // sendToken
            repayAsset, // receiveToken
            notionalRedeemQuantity, // notionalSendQuantity
            notionalRepayQuantity, // minNotionalReceiveQuantity
            tradeAdapterName,
            false, // isLever
            matrixTotalSupply // matrixTotalSupply
        );

        _withdraw(deleverInfo.matrixToken, deleverInfo.lendingPool, collateralAsset, deleverInfo.notionalSendQuantity);
        _executeTrade(deleverInfo, collateralAsset, repayAsset, tradeData);
        _repayBorrow(deleverInfo.matrixToken, deleverInfo.lendingPool, repayAsset, notionalRepayQuantity);
        _updateDeleverPositions(deleverInfo, repayAsset);

        emit DecreaseLeverage(
            matrixToken,
            collateralAsset,
            repayAsset,
            deleverInfo.exchangeAdapter,
            deleverInfo.notionalSendQuantity,
            notionalRepayQuantity,
            0
        );

        return notionalRepayQuantity;
    }

    /**
     * @dev MANAGER ONLY: Initializes this module to the MatrixToken. Either the MatrixToken needs to be
     * on the allowed list or anyMatrixAllowed needs to be true. Only callable by the MatrixToken's manager.
     * @notice Managers can enable collateral and borrow assets that don't exist as positions on the MatrixToken
     *
     * @param matrixToken         Instance of the MatrixToken to initialize
     * @param collateralAssets    Underlying tokens to be enabled as collateral in the MatrixToken
     * @param borrowAssets        Underlying tokens to be enabled as borrow in the MatrixToken
     */
    function initialize(
        IMatrixToken matrixToken,
        IERC20[] memory collateralAssets,
        IERC20[] memory borrowAssets
    ) external onlyMatrixManager(matrixToken, msg.sender) onlyValidAndPendingMatrix(matrixToken) {
        require(_isAnyMatrixAllowed || _isAllowedMatrixTokens[matrixToken], "L1a"); // "Not allowed MatrixToken"

        // Initialize module before trying register
        matrixToken.initializeModule();

        // Get debt issuance module registered to this module and require that it is initialized
        require(matrixToken.isInitializedModule(getAndValidateAdapter(DEFAULT_ISSUANCE_MODULE_NAME)), "L1b"); // "Issuance not initialized"

        // Try if register exists on any of the modules including the debt issuance module
        address[] memory modules = matrixToken.getModules();
        for (uint256 i = 0; i < modules.length; i++) {
            try IDebtIssuanceModule(modules[i]).registerToIssuanceModule(matrixToken) {} catch {}
        }

        // collateralAssets and borrowAssets arrays are validated in their respective internal functions
        _addCollateralAssets(matrixToken, collateralAssets);
        _addBorrowAssets(matrixToken, borrowAssets);
    }

    /**
     * @dev MANAGER ONLY: Removes this module from the MatrixToken, via call by the MatrixToken. Any deposited collateral
     * assets are disabled to be used as collateral on Aave. Aave Settings and manager enabled assets state is deleted.
     * @notice Function will revert is there is any debt remaining on Aave
     */
    function removeModule() external override onlyValidAndInitializedMatrix(IMatrixToken(msg.sender)) {
        IMatrixToken matrixToken = IMatrixToken(msg.sender);

        // Sync Aave and MatrixToken positions prior to any removal action
        sync(matrixToken);

        address[] storage borrowAssets = _enabledAssets[matrixToken].borrowAssets;
        for (uint256 i = 0; i < borrowAssets.length; i++) {
            IERC20 borrowAsset = IERC20(borrowAssets[i]);
            require(_underlyingToReserveTokens[borrowAsset].variableDebtToken.balanceOf(address(matrixToken)) == 0, "L2"); // "Variable debt remaining"

            delete _isEnabledBorrowAsset[matrixToken][borrowAsset];
        }

        address[] storage collateralAssets = _enabledAssets[matrixToken].collateralAssets;
        for (uint256 i = 0; i < collateralAssets.length; i++) {
            IERC20 collateralAsset = IERC20(collateralAssets[i]);
            _updateUseReserveAsCollateral(matrixToken, collateralAsset, false);

            delete _isEnabledCollateralAsset[matrixToken][collateralAsset];
        }

        delete _enabledAssets[matrixToken];

        // Try if unregister exists on any of the modules
        address[] memory modules = matrixToken.getModules();
        for (uint256 i = 0; i < modules.length; i++) {
            try IDebtIssuanceModule(modules[i]).unregisterFromIssuanceModule(matrixToken) {} catch {}
        }
    }

    /**
     * @dev MANAGER ONLY: Add registration of this module on the debt issuance module for the MatrixToken.
     * @notice if the debt issuance module is not added to MatrixToken before this module is initialized, then this function
     * needs to be called if the debt issuance module is later added and initialized to prevent state inconsistencies
     * @param matrixToken           Instance of the MatrixToken
     * @param debtIssuanceModule    Debt issuance module address to register
     */
    function registerToModule(IMatrixToken matrixToken, IDebtIssuanceModule debtIssuanceModule) external onlyManagerAndValidMatrix(matrixToken) {
        require(matrixToken.isInitializedModule(address(debtIssuanceModule)), "L3"); // "Issuance not initialized"

        debtIssuanceModule.registerToIssuanceModule(matrixToken);
    }

    /**
     * @dev CALLABLE BY ANYBODY: Updates `_underlyingToReserveTokens` mappings.
     * Revert if mapping already exists or the passed underlying asset does not have a valid reserve on Aave.
     * @notice Call this function when Aave adds a new reserve.
     *
     * @param underlying    Address of underlying asset
     */
    function addUnderlyingToReserveTokensMapping(IERC20 underlying) external {
        require(address(_underlyingToReserveTokens[underlying].aToken) == address(0), "L4a"); // "Mapping already exists"

        // An active reserve is an alias for a valid reserve on Aave.
        (, , , , , , , , bool isActive, ) = _protocolDataProvider.getReserveConfigurationData(address(underlying));

        require(isActive, "L4b"); // "Invalid aave reserve"

        _addUnderlyingToReserveTokensMapping(underlying);
    }

    /**
     * @dev MANAGER ONLY: Add collateral assets. aTokens corresponding to collateral assets are tracked for syncing positions.
     * Revert if there are duplicate assets in the passed newCollateralAssets array.
     *
     * @notice All added collateral assets can be added as a position on the MatrixToken without manager's explicit permission.
     * Unwanted extra positions can break external logic, increase cost of mint/redeem of MatrixToken, among other potential unintended consequences.
     * So, please add only those collateral assets whose corresponding atokens are needed as default positions on THE MatrixToken.
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param newCollateralAssets    Addresses of new collateral underlying assets
     */
    function addCollateralAssets(IMatrixToken matrixToken, IERC20[] memory newCollateralAssets) external onlyManagerAndValidMatrix(matrixToken) {
        _addCollateralAssets(matrixToken, newCollateralAssets);
    }

    /**
     * @dev MANAGER ONLY: Remove collateral assets. Disable deposited assets to be used as collateral on Aave market.
     *
     * @param matrixToken         Instance of the MatrixToken
     * @param collateralAssets    Addresses of collateral underlying assets to remove
     */
    function removeCollateralAssets(IMatrixToken matrixToken, IERC20[] memory collateralAssets) external onlyManagerAndValidMatrix(matrixToken) {
        for (uint256 i = 0; i < collateralAssets.length; i++) {
            IERC20 collateralAsset = collateralAssets[i];
            require(_isEnabledCollateralAsset[matrixToken][collateralAsset], "L5"); // "Collateral not enabled"

            _updateUseReserveAsCollateral(matrixToken, collateralAsset, false);
            delete _isEnabledCollateralAsset[matrixToken][collateralAsset];
            _enabledAssets[matrixToken].collateralAssets.quickRemoveItem(address(collateralAsset));
        }

        emit UpdateCollateralAssets(matrixToken, false, collateralAssets);
    }

    /**
     * @dev MANAGER ONLY: Add borrow assets. Debt tokens corresponding to borrow assets are tracked for syncing positions.
     * @notice Revert if there are duplicate assets in the passed newBorrowAssets array.
     *
     * @param matrixToken        Instance of the MatrixToken
     * @param newBorrowAssets    Addresses of borrow underlying assets to add
     */
    function addBorrowAssets(IMatrixToken matrixToken, IERC20[] memory newBorrowAssets) external onlyManagerAndValidMatrix(matrixToken) {
        _addBorrowAssets(matrixToken, newBorrowAssets);
    }

    /**
     * @dev MANAGER ONLY: Remove borrow assets.
     * @notice If there is a borrow balance, borrow asset cannot be removed
     *
     * @param matrixToken     Instance of the MatrixToken
     * @param borrowAssets    Addresses of borrow underlying assets to remove
     */
    function removeBorrowAssets(IMatrixToken matrixToken, IERC20[] memory borrowAssets) external onlyManagerAndValidMatrix(matrixToken) {
        for (uint256 i = 0; i < borrowAssets.length; i++) {
            IERC20 borrowAsset = borrowAssets[i];
            require(_isEnabledBorrowAsset[matrixToken][borrowAsset], "L6a"); // "Borrow not enabled"
            require(_underlyingToReserveTokens[borrowAsset].variableDebtToken.balanceOf(address(matrixToken)) == 0, "L6b"); // "Variable debt remaining"

            delete _isEnabledBorrowAsset[matrixToken][borrowAsset];
            _enabledAssets[matrixToken].borrowAssets.quickRemoveItem(address(borrowAsset));
        }

        emit UpdateBorrowAssets(matrixToken, false, borrowAssets);
    }

    /**
     * @dev GOVERNANCE ONLY: Enable/disable ability of a MatrixToken to initialize this module. Only callable by governance.
     *
     * @param matrixToken    Instance of the MatrixToken
     * @param status         Bool indicating if matrixToken is allowed to initialize this module
     */
    function updateAllowedMatrixToken(IMatrixToken matrixToken, bool status) external onlyAdmin {
        require(_controller.isMatrix(address(matrixToken)) || _isAllowedMatrixTokens[matrixToken], "L7"); // "Invalid MatrixToken"

        _isAllowedMatrixTokens[matrixToken] = status;

        emit UpdateMatrixTokenStatus(matrixToken, status);
    }

    /**
     * @dev GOVERNANCE ONLY: Toggle whether ANY MatrixToken is allowed to initialize this module. Only callable by governance.
     *
     * @param anyMatrixAllowed    Bool indicating if ANY MatrixToken is allowed to initialize this module
     */
    function updateAnyMatrixAllowed(bool anyMatrixAllowed) external onlyAdmin {
        _isAnyMatrixAllowed = anyMatrixAllowed;

        emit UpdateAnyMatrixAllowed(anyMatrixAllowed);
    }

    /**
     * @dev MODULE ONLY: Hook called prior to issuance to sync positions on MatrixToken. Only callable by valid module.
     *
     * @param matrixToken    Instance of the MatrixToken
     */
    function moduleIssueHook(
        IMatrixToken matrixToken,
        uint256 /* matrixTokenQuantity */
    ) external override onlyModule(matrixToken) {
        sync(matrixToken);
    }

    /**
     * @dev MODULE ONLY: Hook called prior to redemption to sync positions on MatrixToken.
     * For redemption, always use current borrowed balance after interest accrual. Only callable by valid module.
     *
     * @param matrixToken             Instance of the MatrixToken
     */
    function moduleRedeemHook(
        IMatrixToken matrixToken,
        uint256 /* matrixTokenQuantity */
    ) external override onlyModule(matrixToken) {
        sync(matrixToken);
    }

    /**
     * @dev MODULE ONLY: Hook called prior to looping through each component on issuance.
     * Invokes borrow in order for module to return debt to issuer. Only callable by valid module.
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param matrixTokenQuantity    Quantity of MatrixToken
     * @param component              Address of component
     */
    function componentIssueHook(
        IMatrixToken matrixToken,
        uint256 matrixTokenQuantity,
        IERC20 component,
        bool isEquity
    ) external override onlyModule(matrixToken) {
        // Check hook not being called for an equity position. If hook is called with equity position and
        // outstanding borrow position exists the loan would be taken out twice potentially leading to liquidation
        if (!isEquity) {
            int256 componentDebt = matrixToken.getExternalPositionRealUnit(address(component), address(this));

            require(componentDebt < 0, "L8"); // "Component must be negative"

            uint256 notionalDebt = componentDebt.abs().preciseMul(matrixTokenQuantity);
            _borrowForHook(matrixToken, component, notionalDebt);
        }
    }

    /**
     * @dev MODULE ONLY: Hook called prior to looping through each component on redemption.
     * Invokes repay after the issuance module transfers debt from the issuer. Only callable by valid module.
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param matrixTokenQuantity    Quantity of MatrixToken
     * @param component              Address of component
     */
    function componentRedeemHook(
        IMatrixToken matrixToken,
        uint256 matrixTokenQuantity,
        IERC20 component,
        bool isEquity
    ) external override onlyModule(matrixToken) {
        // Check hook not being called for an equity position. If hook is called with equity position and
        // outstanding borrow position exists the loan would be paid down twice, decollateralizing the Matrix
        if (!isEquity) {
            int256 componentDebt = matrixToken.getExternalPositionRealUnit(address(component), address(this));

            require(componentDebt < 0, "L9"); // "Component must be negative"

            uint256 notionalDebt = componentDebt.abs().preciseMulCeil(matrixTokenQuantity);
            _repayBorrowForHook(matrixToken, component, notionalDebt);
        }
    }

    // ==================== Public functions ====================

    /**
     * @dev CALLABLE BY ANYBODY: Sync Matrix positions with ALL enabled Aave collateral and borrow positions.
     * For collateral assets, update aToken default position. For borrow assets, update external borrow position.
     * Collateral assets may come out of sync when interest is accrued or a position is liquidated.
     * Borrow assets may come out of sync when interest is accrued or position is liquidated and borrow is repaid.
     *
     * @notice In Aave, both collateral and borrow interest is accrued in each block by increasing the balance of
     * aTokens and debtTokens for each user, and 1 aToken = 1 variableDebtToken = 1 underlying.
     *
     * @param matrixToken    Instance of the MatrixToken
     */
    function sync(IMatrixToken matrixToken) public nonReentrant onlyValidAndInitializedMatrix(matrixToken) {
        uint256 matrixTotalSupply = matrixToken.totalSupply();

        // Only sync positions when Matrix supply is not 0. Without this check, if sync is called by someone before
        // the first issuance, then editDefaultPosition would remove the default positions from the MatrixToken
        if (matrixTotalSupply > 0) {
            address[] storage collateralAssets = _enabledAssets[matrixToken].collateralAssets;
            for (uint256 i = 0; i < collateralAssets.length; i++) {
                IAToken aToken = _underlyingToReserveTokens[IERC20(collateralAssets[i])].aToken;
                uint256 previousPositionUnit = matrixToken.getDefaultPositionRealUnit(address(aToken)).toUint256();
                uint256 newPositionUnit = _getCollateralPosition(matrixToken, aToken, matrixTotalSupply);

                // Note: Accounts for if position does not exist on MatrixToken but is tracked in _enabledAssets
                if (previousPositionUnit != newPositionUnit) {
                    _updateCollateralPosition(matrixToken, aToken, newPositionUnit);
                }
            }

            address[] storage borrowAssets = _enabledAssets[matrixToken].borrowAssets;
            for (uint256 i = 0; i < borrowAssets.length; i++) {
                IERC20 borrowAsset = IERC20(borrowAssets[i]);
                int256 previousPositionUnit = matrixToken.getExternalPositionRealUnit(address(borrowAsset), address(this));
                int256 newPositionUnit = _getBorrowPosition(matrixToken, borrowAsset, matrixTotalSupply);

                // Note: Accounts for if position does not exist on MatrixToken but is tracked in _enabledAssets
                if (newPositionUnit != previousPositionUnit) {
                    _updateBorrowPosition(matrixToken, borrowAsset, newPositionUnit);
                }
            }
        }
    }

    // ==================== Internal functions ====================

    /**
     * @dev Invoke deposit from MatrixToken using AaveV2 library. Mints aTokens for MatrixToken.
     */
    function _deposit(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 notionalQuantity
    ) internal {
        matrixToken.invokeSafeApprove(address(asset), address(lendingPool), notionalQuantity);
        matrixToken.invokeDeposit(lendingPool, address(asset), notionalQuantity);
    }

    /**
     * @dev Invoke withdraw from MatrixToken using AaveV2 library. Burns aTokens and returns underlying to MatrixToken.
     */
    function _withdraw(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 notionalQuantity
    ) internal {
        matrixToken.invokeWithdraw(lendingPool, address(asset), notionalQuantity);
    }

    /**
     * @dev Invoke repay from MatrixToken using AaveV2 library. Burns DebtTokens for MatrixToken.
     */
    function _repayBorrow(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 notionalQuantity
    ) internal {
        matrixToken.invokeSafeApprove(address(asset), address(lendingPool), notionalQuantity);
        matrixToken.invokeRepay(lendingPool, address(asset), notionalQuantity, BORROW_RATE_MODE);
    }

    /**
     * @dev Invoke borrow from the MatrixToken during issuance hook. Since we only need to interact with AAVE once we fetch the
     * lending pool in this function to optimize vs forcing a fetch twice during lever/delever.
     */
    function _repayBorrowForHook(
        IMatrixToken matrixToken,
        IERC20 asset,
        uint256 notionalQuantity
    ) internal {
        _repayBorrow(matrixToken, ILendingPool(_lendingPoolAddressesProvider.getLendingPool()), asset, notionalQuantity);
    }

    /**
     * @dev Invoke borrow from the MatrixToken using AaveV2 library. Mints DebtTokens for MatrixToken.
     */
    function _borrow(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        IERC20 asset,
        uint256 notionalQuantity
    ) internal {
        matrixToken.invokeBorrow(lendingPool, address(asset), notionalQuantity, BORROW_RATE_MODE);
    }

    /**
     * @dev Invoke borrow from the MatrixToken during issuance hook. Since we only need to interact with AAVE
     * once we fetch the lending pool in this function to optimize vs forcing a fetch twice during lever/delever.
     */
    function _borrowForHook(
        IMatrixToken matrixToken,
        IERC20 asset,
        uint256 notionalQuantity
    ) internal {
        _borrow(matrixToken, ILendingPool(_lendingPoolAddressesProvider.getLendingPool()), asset, notionalQuantity);
    }

    /**
     * @dev Invokes approvals, gets trade call data from exchange adapter and invokes trade from MatrixToken.
     *
     * @return uint256    The quantity of tokens received post-trade
     */
    function _executeTrade(
        ActionInfo memory actionInfo,
        IERC20 sendToken,
        IERC20 receiveToken,
        bytes memory data
    ) internal returns (uint256) {
        IMatrixToken matrixToken = actionInfo.matrixToken;
        uint256 notionalSendQuantity = actionInfo.notionalSendQuantity;
        matrixToken.invokeSafeApprove(address(sendToken), actionInfo.exchangeAdapter.getSpender(), notionalSendQuantity);

        (address targetExchange, uint256 callValue, bytes memory methodData) = actionInfo.exchangeAdapter.getTradeCalldata(
            address(sendToken),
            address(receiveToken),
            address(matrixToken),
            notionalSendQuantity,
            actionInfo.minNotionalReceiveQuantity,
            data
        );

        matrixToken.invoke(targetExchange, callValue, methodData);
        uint256 receiveTokenQuantity = receiveToken.balanceOf(address(matrixToken)) - actionInfo.preTradeReceiveTokenBalance;

        require(receiveTokenQuantity >= actionInfo.minNotionalReceiveQuantity, "L10"); // "Slippage too high"

        return receiveTokenQuantity;
    }

    /**
     * @dev Calculates protocol fee on module and pays protocol fee from MatrixToken
     *
     * @return uint256    Total protocol fee paid
     */
    function _accrueProtocolFee(
        IMatrixToken matrixToken,
        IERC20 receiveToken,
        uint256 exchangedQuantity
    ) internal returns (uint256) {
        uint256 protocolFeeTotal = getModuleFee(PROTOCOL_TRADE_FEE_INDEX, exchangedQuantity);
        payProtocolFeeFromMatrixToken(matrixToken, address(receiveToken), protocolFeeTotal);

        return protocolFeeTotal;
    }

    /**
     * @dev Updates the collateral (aToken held) and borrow position (variableDebtToken held) of the MatrixToken
     */
    function _updateLeverPositions(ActionInfo memory actionInfo, IERC20 borrowAsset) internal {
        IAToken aToken = _underlyingToReserveTokens[actionInfo.collateralAsset].aToken;
        _updateCollateralPosition(actionInfo.matrixToken, aToken, _getCollateralPosition(actionInfo.matrixToken, aToken, actionInfo.matrixTotalSupply));
        _updateBorrowPosition(actionInfo.matrixToken, borrowAsset, _getBorrowPosition(actionInfo.matrixToken, borrowAsset, actionInfo.matrixTotalSupply));
    }

    /**
     * @dev Updates positions as per _updateLeverPositions and updates Default position for borrow asset in case
     * MatrixToken is delevered all the way to zero any remaining borrow asset after the debt is paid can be added as a position.
     */
    function _updateDeleverPositions(ActionInfo memory actionInfo, IERC20 repayAsset) internal {
        // if amount of tokens traded for exceeds debt, update default position first to save gas on editing borrow position
        uint256 repayAssetBalance = repayAsset.balanceOf(address(actionInfo.matrixToken));

        if (repayAssetBalance != actionInfo.preTradeReceiveTokenBalance) {
            actionInfo.matrixToken.calculateAndEditDefaultPosition(address(repayAsset), actionInfo.matrixTotalSupply, actionInfo.preTradeReceiveTokenBalance);
        }

        _updateLeverPositions(actionInfo, repayAsset);
    }

    /**
     * @dev Updates default position unit for given aToken on MatrixToken
     */
    function _updateCollateralPosition(
        IMatrixToken matrixToken,
        IAToken aToken,
        uint256 newPositionUnit
    ) internal {
        matrixToken.editDefaultPosition(address(aToken), newPositionUnit);
    }

    /**
     * @dev Updates external position unit for given borrow asset on MatrixToken
     */
    function _updateBorrowPosition(
        IMatrixToken matrixToken,
        IERC20 underlyingAsset,
        int256 newPositionUnit
    ) internal {
        matrixToken.editExternalPosition(address(underlyingAsset), address(this), newPositionUnit, "");
    }

    /**
     * @dev Construct the ActionInfo struct for lever and delever
     *
     * @return ActionInfo    Instance of constructed ActionInfo struct
     */
    function _createAndValidateActionInfo(
        IMatrixToken matrixToken,
        IERC20 sendToken,
        IERC20 receiveToken,
        uint256 sendQuantityUnits,
        uint256 minReceiveQuantityUnits,
        string memory tradeAdapterName,
        bool isLever
    ) internal view returns (ActionInfo memory) {
        uint256 totalSupply = matrixToken.totalSupply();

        return
            _createAndValidateActionInfoNotional(
                matrixToken,
                sendToken,
                receiveToken,
                sendQuantityUnits.preciseMul(totalSupply),
                minReceiveQuantityUnits.preciseMul(totalSupply),
                tradeAdapterName,
                isLever,
                totalSupply
            );
    }

    /**
     * @dev Construct the ActionInfo struct for lever and delever accepting notional units
     *
     * @return ActionInfo    Instance of constructed ActionInfo struct
     */
    function _createAndValidateActionInfoNotional(
        IMatrixToken matrixToken,
        IERC20 sendToken,
        IERC20 receiveToken,
        uint256 notionalSendQuantity,
        uint256 minNotionalReceiveQuantity,
        string memory tradeAdapterName,
        bool isLever,
        uint256 matrixTotalSupply
    ) internal view returns (ActionInfo memory) {
        ActionInfo memory actionInfo = ActionInfo({
            exchangeAdapter: IExchangeAdapter(getAndValidateAdapter(tradeAdapterName)),
            lendingPool: ILendingPool(_lendingPoolAddressesProvider.getLendingPool()),
            matrixToken: matrixToken,
            collateralAsset: isLever ? receiveToken : sendToken,
            borrowAsset: isLever ? sendToken : receiveToken,
            matrixTotalSupply: matrixTotalSupply,
            notionalSendQuantity: notionalSendQuantity,
            minNotionalReceiveQuantity: minNotionalReceiveQuantity,
            preTradeReceiveTokenBalance: IERC20(receiveToken).balanceOf(address(matrixToken))
        });

        _validateCommon(actionInfo);

        return actionInfo;
    }

    /**
     * @dev Updates `_underlyingToReserveTokens` mappings for given `underlying` asset. Emits UpdateReserveTokens event.
     */
    function _addUnderlyingToReserveTokensMapping(IERC20 underlying) internal {
        (address aToken, , address variableDebtToken) = _protocolDataProvider.getReserveTokensAddresses(address(underlying));
        _underlyingToReserveTokens[underlying].aToken = IAToken(aToken);
        _underlyingToReserveTokens[underlying].variableDebtToken = IERC20(variableDebtToken);

        emit UpdateReserveTokens(underlying, IAToken(aToken), IERC20(variableDebtToken));
    }

    /**
     * @dev Add collateral assets to MatrixToken. Updates the collateralAssetsEnabled and _enabledAssets mappings. Emits UpdateCollateralAssets event.
     */
    function _addCollateralAssets(IMatrixToken matrixToken, IERC20[] memory newCollateralAssets) internal {
        for (uint256 i = 0; i < newCollateralAssets.length; i++) {
            IERC20 collateralAsset = newCollateralAssets[i];
            _validateNewCollateralAsset(matrixToken, collateralAsset);
            _updateUseReserveAsCollateral(matrixToken, collateralAsset, true);
            _isEnabledCollateralAsset[matrixToken][collateralAsset] = true;
            _enabledAssets[matrixToken].collateralAssets.push(address(collateralAsset));
        }

        emit UpdateCollateralAssets(matrixToken, true, newCollateralAssets);
    }

    /**
     * @dev Add borrow assets to MatrixToken. Updates the borrowAssetsEnabled and _enabledAssets mappings. Emits UpdateBorrowAssets event.
     */
    function _addBorrowAssets(IMatrixToken matrixToken, IERC20[] memory newBorrowAssets) internal {
        for (uint256 i = 0; i < newBorrowAssets.length; i++) {
            IERC20 borrowAsset = newBorrowAssets[i];
            _validateNewBorrowAsset(matrixToken, borrowAsset);
            _isEnabledBorrowAsset[matrixToken][borrowAsset] = true;
            _enabledAssets[matrixToken].borrowAssets.push(address(borrowAsset));
        }

        emit UpdateBorrowAssets(matrixToken, true, newBorrowAssets);
    }

    /**
     * @dev Updates MatrixToken's ability to use an asset as collateral on Aave
     * @notice Aave ENABLES an asset to be used as collateral by `to` address in an `aToken.transfer(to, amount)` call provided
     *       1. msg.sender (from address) isn't the same as `to` address
     *       2. `to` address had zero aToken balance before the transfer
     *       3. transfer `amount` is greater than 0
     *
     * @notice Aave DISABLES an asset to be used as collateral by `msg.sender`in an `aToken.transfer(to, amount)` call provided
     *       1. msg.sender (from address) isn't the same as `to` address
     *       2. msg.sender has zero balance after the transfer
     *
     *   Different states of the MatrixToken and what this function does in those states:
     *
     *       Case 1: Manager adds collateral asset to MatrixToken before first issuance
     *           - Since aToken.balanceOf(matrixToken) == 0, we do not call `matrixToken.invokeUserUseReserveAsCollateral` because Aave
     *           requires aToken balance to be greater than 0 before enabling/disabling the underlying asset to be used as collateral
     *           on Aave markets.
     *
     *       Case 2: First issuance of the MatrixToken
     *           - MatrixToken was initialized with aToken as default position
     *           - DebtIssuanceModule reads the default position and transfers corresponding aToken from the issuer to the MatrixToken
     *           - Aave enables aToken to be used as collateral by the MatrixToken
     *           - Manager calls lever() and the aToken is used as collateral to borrow other assets
     *
     *       Case 3: Manager removes collateral asset from the MatrixToken
     *           - Disable asset to be used as collateral on MatrixToken by calling `matrixToken.invokeSetUserUseReserveAsCollateral` with
     *           useAsCollateral equals false
     *           - Note: If health factor goes below 1 by removing the collateral asset, then Aave reverts on the above call, thus whole
     *           transaction reverts, and manager can't remove corresponding collateral asset
     *
     *       Case 4: Manager adds collateral asset after removing it
     *           - If aToken.balanceOf(matrixToken) > 0, we call `matrixToken.invokeUserUseReserveAsCollateral` and the corresponding aToken
     *           is re-enabled as collateral on Aave
     *
     *       Case 5: On redemption/delever/liquidated and aToken balance becomes zero
     *           - Aave disables aToken to be used as collateral by MatrixToken
     *
     *   Values of variables in below if condition and corresponding action taken:
     *
     *   ---------------------------------------------------------------------------------------------------------------------
     *   | usageAsCollateralEnabled |  useAsCollateral  |   aToken.balanceOf()  |     Action                                 |
     *   |--------------------------|-------------------|-----------------------|--------------------------------------------|
     *   |   true                   |   true            |      X                |   Skip invoke. Save gas.                   |
     *   |--------------------------|-------------------|-----------------------|--------------------------------------------|
     *   |   true                   |   false           |   greater than 0      |   Invoke and set to false.                 |
     *   |--------------------------|-------------------|-----------------------|--------------------------------------------|
     *   |   true                   |   false           |   = 0                 |   Impossible case. Aave disables usage as  |
     *   |                          |                   |                       |   collateral when aToken balance becomes 0 |
     *   |--------------------------|-------------------|-----------------------|--------------------------------------------|
     *   |   false                  |   false           |     X                 |   Skip invoke. Save gas.                   |
     *   |--------------------------|-------------------|-----------------------|--------------------------------------------|
     *   |   false                  |   true            |   greater than 0      |   Invoke and set to true.                  |
     *   |--------------------------|-------------------|-----------------------|--------------------------------------------|
     *   |   false                  |   true            |   = 0                 |   Don't invoke. Will revert.               |
     *   ---------------------------------------------------------------------------------------------------------------------
     */
    function _updateUseReserveAsCollateral(
        IMatrixToken matrixToken,
        IERC20 asset,
        bool useAsCollateral
    ) internal {
        (, , , , , , , , bool usageAsCollateralEnabled) = _protocolDataProvider.getUserReserveData(address(asset), address(matrixToken));

        if ((usageAsCollateralEnabled != useAsCollateral) && (_underlyingToReserveTokens[asset].aToken.balanceOf(address(matrixToken)) > 0)) {
            matrixToken.invokeSetUserUseReserveAsCollateral(ILendingPool(_lendingPoolAddressesProvider.getLendingPool()), address(asset), useAsCollateral);
        }
    }

    /**
     * @dev Validate common requirements for lever and delever
     */
    function _validateCommon(ActionInfo memory actionInfo) internal view {
        require(_isEnabledCollateralAsset[actionInfo.matrixToken][actionInfo.collateralAsset], "L11a"); // "Collateral not enabled"
        require(_isEnabledBorrowAsset[actionInfo.matrixToken][actionInfo.borrowAsset], "L11b"); // "Borrow not enabled"
        require(actionInfo.collateralAsset != actionInfo.borrowAsset, "L11c"); // "Collateral and borrow asset must be different"
        require(actionInfo.notionalSendQuantity > 0, "L11d"); // "Quantity is 0"
    }

    /**
     * @dev Validates if a new asset can be added as collateral asset for given MatrixToken
     */
    function _validateNewCollateralAsset(IMatrixToken matrixToken, IERC20 asset) internal view {
        require(!_isEnabledCollateralAsset[matrixToken][asset], "L12a"); // "Collateral already enabled"

        (address aToken, , ) = _protocolDataProvider.getReserveTokensAddresses(address(asset));

        require(address(_underlyingToReserveTokens[asset].aToken) == aToken, "L12b"); // "Invalid aToken address"

        (, , , , , bool usageAsCollateralEnabled, , , bool isActive, bool isFrozen) = _protocolDataProvider.getReserveConfigurationData(address(asset));

        // An active reserve is an alias for a valid reserve on Aave.
        // We are checking for the availability of the reserve directly on Aave rather than checking our internal `_underlyingToReserveTokens` mappings,
        // because our mappings can be out-of-date if a new reserve is added to Aave
        require(isActive, "L12c"); // "Invalid aave reserve"

        // A frozen reserve doesn't allow any new deposit, borrow or rate swap but allows repayments, liquidations and withdrawals
        require(!isFrozen, "L12d"); // "Frozen aave reserve"

        require(usageAsCollateralEnabled, "L12e"); // "Collateral disabled on Aave"
    }

    /**
     * @dev Validates if a new asset can be added as borrow asset for given MatrixToken
     */
    function _validateNewBorrowAsset(IMatrixToken matrixToken, IERC20 asset) internal view {
        require(!_isEnabledBorrowAsset[matrixToken][asset], "L13a"); // "Borrow already enabled"

        (, , address variableDebtToken) = _protocolDataProvider.getReserveTokensAddresses(address(asset));

        require(address(_underlyingToReserveTokens[asset].variableDebtToken) == variableDebtToken, "L13b"); // "Invalid variable debt token address")

        (, , , , , , bool borrowingEnabled, , bool isActive, bool isFrozen) = _protocolDataProvider.getReserveConfigurationData(address(asset));

        require(isActive, "L13c"); // "Invalid aave reserve"
        require(!isFrozen, "L13d"); // "Frozen aave reserve"
        require(borrowingEnabled, "L13e"); // "Borrowing disabled on Aave"
    }

    /**
     * @dev Reads aToken balance and calculates default position unit for given collateral aToken and MatrixToken
     *
     * @return uint256    default collateral position unit
     */
    function _getCollateralPosition(
        IMatrixToken matrixToken,
        IAToken aToken,
        uint256 matrixTotalSupply
    ) internal view returns (uint256) {
        uint256 collateralNotionalBalance = aToken.balanceOf(address(matrixToken));
        return collateralNotionalBalance.preciseDiv(matrixTotalSupply);
    }

    /**
     * @dev Reads variableDebtToken balance and calculates external position unit for given borrow asset and MatrixToken
     *
     * @return int256    external borrow position unit
     */
    function _getBorrowPosition(
        IMatrixToken matrixToken,
        IERC20 borrowAsset,
        uint256 matrixTotalSupply
    ) internal view returns (int256) {
        uint256 borrowNotionalBalance = _underlyingToReserveTokens[borrowAsset].variableDebtToken.balanceOf(address(matrixToken));
        int256 result = borrowNotionalBalance.preciseDivCeil(matrixTotalSupply).toInt256();

        return -result;
    }

    // ==================== Private functions ====================

    function _onlyAdmin() private view {
        require(hasRole(ADMIN_ROLE, _msgSender()), "L14");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PreciseUnitMath
 *
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision.
 */
library PreciseUnitMath {
    // ==================== Constants ====================

    // The number One in precise units
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;

    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    // ==================== Internal functions ====================

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return (product == 0) ? 0 : ((product - 1) / PRECISE_UNIT + 1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM0");

        return (a * PRECISE_UNIT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "PM1");

        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM2");

        return a > 0 ? ((a * PRECISE_UNIT - 1) / b + 1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     * return 0 when `a` is 0.reverts when `b` is 0.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM3");

        a *= PRECISE_UNIT_INT;
        result = a / b;

        if (a % b != 0) {
            (a ^ b >= 0) ? ++result : --result;
        }
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseMulFloor(int256 a, int256 b) internal pure returns (int256 result) {
        int256 product = a * b;
        result = product / PRECISE_UNIT_INT;

        if ((product < 0) && (product % PRECISE_UNIT_INT != 0)) {
            --result;
        }
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseDivFloor(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM4");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1

        if ((numerator ^ b < 0) && (numerator % b != 0)) {
            --result;
        }
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        if (a >= b) {
            return a - b <= range;
        } else {
            return b - a <= range;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title AddressArrayUtil
 *
 * @dev Utility functions to handle address arrays
 */
library AddressArrayUtil {
    // ==================== Internal functions ====================

    /**
     * @dev Returns true if there are 2 same elements in an array
     *
     * @param array The input array to search
     */
    function hasDuplicate(address[] memory array) internal pure returns (bool) {
        if (array.length > 1) {
            uint256 lastIndex = array.length - 1;
            for (uint256 i = 0; i < lastIndex; i++) {
                address value = array[i];
                for (uint256 j = i + 1; j < array.length; j++) {
                    if (value == array[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * @dev Finds the index of the first occurrence of the given element.
     *
     * @param array     The input array to search
     * @param value     The value to find
     *
     * @return index    The first occurrence starting from 0
     * @return found    True if find
     */
    function indexOf(address[] memory array, address value) internal pure returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    /**
     * @dev Check if the value is in the list.
     *
     * @param array    The input array to search
     * @param value    The value to find
     *
     * @return found   True if find
     */
    function contain(address[] memory array, address value) internal pure returns (bool found) {
        (, found) = indexOf(array, value);
    }

    /**
     * @param array    The input array to search
     * @param value    The address to remove
     *
     * @return result  the array with the object removed.
     */
    function removeValue(address[] memory array, address value) internal pure returns (address[] memory result) {
        (uint256 index, bool found) = indexOf(array, value);
        require(found, "A0");

        result = new address[](array.length - 1);

        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }

        for (uint256 i = index + 1; i < array.length; i++) {
            result[index] = array[i];
            index = i;
        }
    }

    /**
     * @param array    The input array to search
     * @param item     The address to remove
     */
    function removeItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A1");

        for (uint256 right = index + 1; right < array.length; right++) {
            array[index] = array[right];
            index = right;
        }

        array.pop();
    }

    /**
     * @param array    The input array to search
     * @param item     The address to remove
     */
    function quickRemoveItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A2");

        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @dev Returns the combination of the two arrays
     *
     * @param array1    The first array
     * @param array2    The second array
     *
     * @return result   A extended by B
     */
    function merge(address[] memory array1, address[] memory array2) internal pure returns (address[] memory result) {
        result = new address[](array1.length + array2.length);

        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        uint256 index = array1.length;
        for (uint256 j = 0; j < array2.length; j++) {
            result[index++] = array2[j];
        }
    }

    /**
     * @dev Validate that address and uint array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of uint
     */
    function validateArrayPairs(address[] memory array1, uint256[] memory array2) internal pure {
        require(array1.length == array2.length, "A3");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bool array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bool
     */
    function validateArrayPairs(address[] memory array1, bool[] memory array2) internal pure {
        require(array1.length == array2.length, "A4");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and string array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of strings
     */
    function validateArrayPairs(address[] memory array1, string[] memory array2) internal pure {
        require(array1.length == array2.length, "A5");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address array lengths match, and calling address array are not empty and contain no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of addresses
     */
    function validateArrayPairs(address[] memory array1, address[] memory array2) internal pure {
        require(array1.length == array2.length, "A6");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bytes array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bytes
     */
    function validateArrayPairs(address[] memory array1, bytes[] memory array2) internal pure {
        require(array1.length == array2.length, "A7");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate address array is not empty and contains no duplicate elements.
     *
     * @param array    Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory array) internal pure {
        require(array.length > 0, "A8a");
        require(!hasDuplicate(array), "A8b");
    }

    /**
     * @dev assume both of array1 and array2 has no duplicate items
     */
    function equal(address[] memory array1, address[] memory array2) internal pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }

        for (uint256 i = 0; i < array1.length; i++) {
            if (!contain(array2, array1[i])) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ==================== Internal Imports ====================

import { ExactSafeErc20 } from "../../lib/ExactSafeErc20.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../../lib/AddressArrayUtil.sol";

import { IModule } from "../../interfaces/IModule.sol";
import { IController } from "../../interfaces/IController.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";

import { PositionUtil } from "./PositionUtil.sol";

/**
 * @title ModuleBase
 *
 * @dev Abstract class that houses common Module-related state and functions.
 */
abstract contract ModuleBase is IModule {
    using SafeCast for int256;
    using SafeCast for uint256;
    using ExactSafeErc20 for IERC20;
    using PreciseUnitMath for uint256;
    using AddressArrayUtil for address[];
    using PositionUtil for IMatrixToken;

    // ==================== Variables ====================

    IController internal immutable _controller;

    // ==================== Constructor function ====================

    constructor(IController controller) {
        _controller = controller;
    }

    // ==================== Modifier functions ====================

    modifier onlyManagerAndValidMatrix(IMatrixToken matrixToken) {
        _onlyManagerAndValidMatrix(matrixToken);
        _;
    }

    modifier onlyMatrixManager(IMatrixToken matrixToken, address caller) {
        _onlyMatrixManager(matrixToken, caller);
        _;
    }

    modifier onlyValidAndInitializedMatrix(IMatrixToken matrixToken) {
        _onlyValidAndInitializedMatrix(matrixToken);
        _;
    }

    modifier onlyModule(IMatrixToken matrixToken) {
        _onlyModule(matrixToken);
        _;
    }

    /**
     * @dev Utilized during module initializations to check that the module is in pending state and that the MatrixToken is valid.
     */
    modifier onlyValidAndPendingMatrix(IMatrixToken matrixToken) {
        _onlyValidAndPendingMatrix(matrixToken);
        _;
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    // ==================== Internal functions ====================

    /**
     * @dev Transfers tokens from an address (that has set allowance on the module).
     *
     * @param token       The address of the ERC20 token
     * @param from        The address to transfer from
     * @param to          The address to transfer to
     * @param quantity    The number of tokens to transfer
     */
    function transferFrom(IERC20 token, address from, address to, uint256 quantity) internal {
        token.exactSafeTransferFrom(from, to, quantity);
    } // prettier-ignore

    /**
     * @dev Hashes the string and returns a bytes32 value.
     */
    function getNameHash(string memory name) internal pure returns (bytes32) {
        return keccak256(bytes(name));
    }

    /**
     * @return The integration for the module with the passed in name.
     */
    function getAndValidateAdapter(string memory integrationName) internal view returns (address) {
        bytes32 integrationHash = getNameHash(integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * @return The integration for the module with the passed in hash.
     */
    function getAndValidateAdapterWithHash(bytes32 integrationHash) internal view returns (address) {
        address adapter = _controller.getIntegrationRegistry().getIntegrationAdapterWithHash(address(this), integrationHash);

        require(adapter != address(0), "M0"); // "Must be valid adapter"

        return adapter;
    }

    /**
     * @return The total fee for this module of the passed in index (fee % * quantity).
     */
    function getModuleFee(uint256 feeIndex, uint256 quantity) internal view returns (uint256) {
        uint256 feePercentage = _controller.getModuleFee(address(this), feeIndex);
        return quantity.preciseMul(feePercentage);
    }

    /**
     * @dev Pays the feeQuantity from the matrixToken denominated in token to the protocol fee recipient.
     */
    function payProtocolFeeFromMatrixToken(IMatrixToken matrixToken, address token, uint256 feeQuantity) internal {
        if (feeQuantity > 0) {
            matrixToken.invokeExactSafeTransfer(token, _controller.getFeeRecipient(), feeQuantity);
        }
    } // prettier-ignore

    /**
     * @return Whether the module is in process of initialization on the MatrixToken.
     */
    function isMatrixPendingInitialization(IMatrixToken matrixToken) internal view returns (bool) {
        return matrixToken.isPendingModule(address(this));
    }

    /**
     * @return Whether the address is the MatrixToken's manager.
     */
    function isMatrixManager(IMatrixToken matrixToken, address addr) internal view returns (bool) {
        return matrixToken.getManager() == addr;
    }

    /**
     * @return Whether MatrixToken must be enabled on the controller and module is registered on the MatrixToken.
     */
    function isMatrixValidAndInitialized(IMatrixToken matrixToken) internal view returns (bool) {
        return _controller.isMatrix(address(matrixToken)) && matrixToken.isInitializedModule(address(this));
    }

    // ==================== Private functions ====================

    /**
     * @notice Caller must be MatrixToken manager and MatrixToken must be valid and initialized.
     */
    function _onlyManagerAndValidMatrix(IMatrixToken matrixToken) private view {
        require(isMatrixManager(matrixToken, msg.sender), "M1a"); // "Must be the MatrixToken manager"
        require(isMatrixValidAndInitialized(matrixToken), "M1b"); // "Must be a valid and initialized MatrixToken"
    }

    /**
     * @notice Caller must be MatrixToken manager.
     */
    function _onlyMatrixManager(IMatrixToken matrixToken, address caller) private view {
        require(isMatrixManager(matrixToken, caller), "M2"); // "Must be the MatrixToken manager"
    }

    /**
     * @notice MatrixToken must be valid and initialized.
     */
    function _onlyValidAndInitializedMatrix(IMatrixToken matrixToken) private view {
        require(isMatrixValidAndInitialized(matrixToken), "M3"); // "Must be a valid and initialized MatrixToken"
    }

    /**
     * @notice Caller must be initialized module and module must be enabled on the controller.
     */
    function _onlyModule(IMatrixToken matrixToken) private view {
        require(matrixToken.getModuleState(msg.sender) == IMatrixToken.ModuleState.INITIALIZED, "M4a"); // "Only the module can call"
        require(_controller.isModule(msg.sender), "M4b"); // "Module must be enabled on controller"
    }

    /**
     * @dev MatrixToken must be in a pending state and module must be in pending state.
     */
    function _onlyValidAndPendingMatrix(IMatrixToken matrixToken) private view {
        require(_controller.isMatrix(address(matrixToken)), "M5a"); // "Must be controller-enabled MatrixToken"
        require(isMatrixPendingInitialization(matrixToken), "M5b"); // "Must be pending initialization"
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ==================== Internal Imports ====================

import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";

/**
 * @title PositionUtil
 *
 * @dev Collection of helper functions for handling and updating MatrixToken Positions.
 */
library PositionUtil {
    using SafeCast for uint256;
    using SafeCast for int256;
    using PreciseUnitMath for uint256;

    // ==================== Internal functions ====================

    /**
     * @return Whether the MatrixToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(IMatrixToken matrixToken, address component) internal view returns (bool) {
        return matrixToken.getDefaultPositionRealUnit(component) > 0;
    }

    /**
     * @return Whether the MatrixToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(IMatrixToken matrixToken, address component) internal view returns (bool) {
        return matrixToken.getExternalPositionModules(component).length > 0;
    }

    /**
     * @return Whether the MatrixToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(
        IMatrixToken matrixToken,
        address component,
        uint256 unit
    ) internal view returns (bool) {
        return matrixToken.getDefaultPositionRealUnit(component) >= unit.toInt256();
    }

    /**
     * @return Whether the MatrixToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        IMatrixToken matrixToken,
        address component,
        address positionModule,
        uint256 unit
    ) internal view returns (bool) {
        return matrixToken.getExternalPositionRealUnit(component, positionModule) >= unit.toInt256();
    }

    /**
     * @dev If the position does not exist, create a new Position and add to the MatrixToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
     * components where needed (in light of potential external positions).
     *
     * @param matrixToken    Address of MatrixToken being modified
     * @param component      Address of the component
     * @param newUnit        Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(
        IMatrixToken matrixToken,
        address component,
        uint256 newUnit
    ) internal {
        bool isPositionFound = hasDefaultPosition(matrixToken, component);
        if (!isPositionFound && newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(matrixToken, component)) {
                matrixToken.addComponent(component);
            }
        } else if (isPositionFound && newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(matrixToken, component)) {
                matrixToken.removeComponent(component);
            }
        }

        matrixToken.editDefaultPositionUnit(component, newUnit.toInt256());
    }

    /**
     * @dev Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position.
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the external position.
     *
     * @param matrixToken    MatrixToken being updated
     * @param component      Component position being updated
     * @param module         Module external position is associated with
     * @param newUnit        Position units of new external position
     * @param data           Arbitrary data associated with the position
     */
    function editExternalPosition(
        IMatrixToken matrixToken,
        address component,
        address module,
        int256 newUnit,
        bytes memory data
    ) internal {
        if (newUnit != 0) {
            if (!matrixToken.isComponent(component)) {
                matrixToken.addComponent(component);
                matrixToken.addExternalPositionModule(component, module);
            } else if (!matrixToken.isExternalPositionModule(component, module)) {
                matrixToken.addExternalPositionModule(component, module);
            }

            matrixToken.editExternalPositionUnit(component, module, newUnit);
            matrixToken.editExternalPositionData(component, module, data);
        } else {
            require(data.length == 0, "P0a"); // "Passed data must be null"

            // If no default or external position remaining then remove component from components array
            if (matrixToken.getExternalPositionRealUnit(component, module) != 0) {
                address[] memory positionModules = matrixToken.getExternalPositionModules(component);

                if (matrixToken.getDefaultPositionRealUnit(component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == module, "P0b"); // "External positions must be 0 to remove component")
                    matrixToken.removeComponent(component);
                }

                matrixToken.removeExternalPositionModule(component, module);
            }
        }
    }

    /**
     * @dev Get total notional amount of Default position
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param positionUnit         Quantity of Position units
     *
     * @return uint256             Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 matrixTokenSupply, uint256 positionUnit) internal pure returns (uint256) {
        return matrixTokenSupply.preciseMul(positionUnit);
    }

    /**
     * @dev Get position unit from total notional amount
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param totalNotional        Total notional amount of component prior to
     *
     * @return uint256             Default position unit
     */
    function getDefaultPositionUnit(uint256 matrixTokenSupply, uint256 totalNotional) internal pure returns (uint256) {
        return totalNotional.preciseDiv(matrixTokenSupply);
    }

    /**
     * @dev Get the total tracked balance - total supply * position unit
     *
     * @param matrixToken    Address of the MatrixToken
     * @param component      Address of the component
     *
     * @return uint256       Notional tracked balance
     */
    function getDefaultTrackedBalance(IMatrixToken matrixToken, address component) internal view returns (uint256) {
        int256 positionUnit = matrixToken.getDefaultPositionRealUnit(component);

        return matrixToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * @dev Calculates the new default position unit and performs the edit with the new unit
     *
     * @param matrixToken                 Address of the MatrixToken
     * @param component                   Address of the component
     * @param matrixTotalSupply           Current MatrixToken supply
     * @param componentPreviousBalance    Pre-action component balance
     *
     * @return uint256                    Current component balance
     * @return uint256                    Previous position unit
     * @return uint256                    New position unit
     */
    function calculateAndEditDefaultPosition(
        IMatrixToken matrixToken,
        address component,
        uint256 matrixTotalSupply,
        uint256 componentPreviousBalance
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentBalance = IERC20(component).balanceOf(address(matrixToken));
        uint256 positionUnit = matrixToken.getDefaultPositionRealUnit(component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(matrixTotalSupply, componentPreviousBalance, currentBalance, positionUnit);
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(matrixToken, component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * @dev Calculate the new position unit given total notional values pre and post executing an action that changes MatrixToken state.
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param preTotalNotional     Total notional amount of component prior to executing action
     * @param postTotalNotional    Total notional amount of component after the executing action
     * @param prePositionUnit      Position unit of MatrixToken prior to executing action
     *
     * @return uint256             New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 matrixTokenSupply,
        uint256 preTotalNotional,
        uint256 postTotalNotional,
        uint256 prePositionUnit
    ) internal pure returns (uint256) {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = preTotalNotional - prePositionUnit.preciseMul(matrixTokenSupply);

        return (postTotalNotional - airdroppedAmount).preciseDiv(matrixTokenSupply);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ==================== Internal Imports ====================

import { ILendingPool } from "../../../interfaces/external/aave-v2/ILendingPool.sol";

import { IMatrixToken } from "../../../interfaces/IMatrixToken.sol";

/**
 * @title AaveV2
 *
 * @dev Collection of helper functions for interacting with AaveV2 integrations.
 */
library AaveV2 {
    // ==================== External functions ====================

    /**
     * @dev Get deposit calldata from MatrixToken. Deposits an `amountNotional` of underlying asset into the reserve,
     * receiving in return overlying aTokens. E.g. User deposits 100 USDC and gets in return 100 aUSDC.
     *
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to deposit
     * @param amountNotional    The amount to be deposited
     * @param onBehalfOf        The address that will receive the aTokens, same as msg.sender if the user wants to receive them on his own wallet,
     *                              or a different address if the beneficiary of aTokens is a different wallet
     * @param referralCode      Code used to register the integrator originating the operation, for potential rewards.
     *                              0 if the action is executed directly by the user, without any middle-man
     *
     * @return target          Target contract address
     * @return value           Call value
     * @return callData        Deposit calldata
     */
    function getDepositCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        address onBehalfOf,
        uint16 referralCode
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        callData = abi.encodeWithSignature("deposit(address,uint256,address,uint16)", asset, amountNotional, onBehalfOf, referralCode);
    }

    /**
     * @dev Invoke deposit on LendingPool from MatrixToken. Deposits an `amountNotional` of underlying asset into the reserve,
     * receiving in return overlying aTokens.E.g. MatrixToken deposits 100 USDC and gets in return 100 aUSDC
     *
     * @param matrixToken       Address of the MatrixToken
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to deposit
     * @param amountNotional    The amount to be deposited
     */
    function invokeDeposit(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional
    ) external {
        (address target, , bytes memory callData) = getDepositCalldata(lendingPool, asset, amountNotional, address(matrixToken), 0);

        matrixToken.invoke(target, 0, callData);
    }

    /**
     * @dev Get withdraw calldata from MatrixToken. Withdraws an `amountNotional` of underlying asset from the reserve,
     * burning the equivalent aTokens owned. E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC.
     *
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to withdraw
     * @param amountNotional    The underlying amount to be withdraw. Passing type(uint256).max will withdraw the entire aToken balance
     * @param receiver          Address that will receive the underlying, same as msg.sender if the user wants to receive it on his own wallet,
     *                              or a different address if the beneficiary is a different wallet
     *
     * @return target           Target contract address
     * @return value            Call value
     * @return callData         Withdraw calldata
     */
    function getWithdrawCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        address receiver
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // withdraw(address asset, uint256 amount, address to)
        callData = abi.encodeWithSignature("withdraw(address,uint256,address)", asset, amountNotional, receiver);
    }

    /**
     * @dev Invoke withdraw on LendingPool from MatrixToken. Withdraws an `amountNotional` of underlying asset from the reserve,
     * burning the equivalent aTokens owned. E.g. MatrixToken has 100 aUSDC, and receives 100 USDC, burning the 100 aUSDC.
     *
     * @param matrixToken       Address of the MatrixToken
     * @param lendingPool       Address of the LendingPool contract
     * @param asset             The address of the underlying asset to withdraw
     * @param amountNotional    The underlying amount to be withdraw. Passing type(uint256).max will withdraw the entire aToken balance.
     *
     * @return uint256          The final amount withdraw
     */
    function invokeWithdraw(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional
    ) external returns (uint256) {
        (address target, , bytes memory callData) = getWithdrawCalldata(lendingPool, asset, amountNotional, address(matrixToken));

        return abi.decode(matrixToken.invoke(target, 0, callData), (uint256));
    }

    /**
     * @dev Get borrow calldata from MatrixToken. Allows users to borrow a specific `amountNotional` of the reserve
     * underlying `asset`, provided that the borrower already deposited enough collateral, or he was given enough
     * allowance by a credit delegator on the corresponding debt token (StableDebtToken or VariableDebtToken).
     *
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the underlying asset to borrow
     * @param amountNotional      The amount to be borrowed
     * @param interestRateMode    The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode        Code used to register the integrator originating the operation, for potential rewards.
     *                                0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf          Address of the user who will receive the debt. Should be the address of the borrower itself calling the function if he wants to
     *                                borrow against his own collateral, or the address of the credit delegator if he has been given credit delegation allowance.
     *
     * @return target             Target contract address
     * @return value              Call value
     * @return callData           Borrow calldata
     */
    function getBorrowCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        callData = abi.encodeWithSignature("borrow(address,uint256,uint256,uint16,address)", asset, amountNotional, interestRateMode, referralCode, onBehalfOf);
    }

    /**
     * @dev Invoke borrow on LendingPool from MatrixToken. Allows MatrixToken to borrow a specific `amountNotional` of
     * the reserve underlying `asset`, provided that the MatrixToken already deposited enough collateral, or it was given
     * enough allowance by a credit delegator on the corresponding debt token (StableDebtToken or VariableDebtToken).
     *
     * @param matrixToken         Address of the MatrixToken
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the underlying asset to borrow
     * @param amountNotional      The amount to be borrowed
     * @param interestRateMode    The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     */
    function invokeBorrow(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode
    ) external {
        (address target, , bytes memory callData) = getBorrowCalldata(lendingPool, asset, amountNotional, interestRateMode, 0, address(matrixToken));

        matrixToken.invoke(target, 0, callData);
    }

    /**
     * @dev Get repay calldata from MatrixToken. Repays a borrowed `amountNotional` on a specific `asset` reserve, burning the
     * equivalent debt tokens owned. E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address.
     *
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the borrowed underlying asset previously borrowed
     * @param amountNotional      The amount to repay. Passing type(uint256).max will repay the whole debt for `asset` on the specific `interestRateMode`
     * @param interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf          Address of the user who will get his debt reduced/removed. Should be the address of the user calling the function
     *                                if he wants to reduce/remove his own debt, or the address of any other other borrower whose debt should be removed.
     *
     * @return target             Target contract address
     * @return value              Call value
     * @return callData           Repay calldata
     */
    function getRepayCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode,
        address onBehalfOf
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf)
        callData = abi.encodeWithSignature("repay(address,uint256,uint256,address)", asset, amountNotional, interestRateMode, onBehalfOf);
    }

    /**
     * @dev Invoke repay on LendingPool from MatrixToken. Repays a borrowed `amountNotional` on a specific `asset` reserve,
     * burning the equivalent debt tokens owned. E.g. MatrixToken repays 100 USDC, burning 100 variable/stable debt tokens.
     *
     * @param matrixToken         Address of the MatrixToken
     * @param lendingPool         Address of the LendingPool contract
     * @param asset               The address of the borrowed underlying asset previously borrowed
     * @param amountNotional      The amount to repay. Passing type(uint256).max will repay the whole debt for `asset` on the specific `interestRateMode`
     * @param interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     *
     * @return uint256            The final amount repaid
     */
    function invokeRepay(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 amountNotional,
        uint256 interestRateMode
    ) external returns (uint256) {
        (address target, , bytes memory callData) = getRepayCalldata(lendingPool, asset, amountNotional, interestRateMode, address(matrixToken));

        return abi.decode(matrixToken.invoke(target, 0, callData), (uint256));
    }

    /**
     * @dev Get setUserUseReserveAsCollateral calldata from MatrixToken. Allows borrower to enable/disable a specific deposited asset as collateral
     *
     * @param lendingPool        Address of the LendingPool contract
     * @param asset              The address of the underlying asset deposited
     * @param useAsCollateral    true` if the user wants to use the deposit as collateral, `false` otherwise
     *
     * @return target           Target contract address
     * @return value           Call value
     * @return callData             SetUserUseReserveAsCollateral calldata
     */
    function getSetUserUseReserveAsCollateralCalldata(
        ILendingPool lendingPool,
        address asset,
        bool useAsCollateral
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        callData = abi.encodeWithSignature("setUserUseReserveAsCollateral(address,bool)", asset, useAsCollateral);
    }

    /**
     * @dev Invoke an asset to be used as collateral on Aave from MatrixToken. Allows MatrixToken to enable/disable a specific deposited asset as collateral.
     *
     * @param matrixToken        Address of the MatrixToken
     * @param lendingPool        Address of the LendingPool contract
     * @param asset              The address of the underlying asset deposited
     * @param useAsCollateral    true` if the user wants to use the deposit as collateral, `false` otherwise
     */
    function invokeSetUserUseReserveAsCollateral(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        bool useAsCollateral
    ) external {
        (address target, , bytes memory callData) = getSetUserUseReserveAsCollateralCalldata(lendingPool, asset, useAsCollateral);

        matrixToken.invoke(target, 0, callData);
    }

    /**
     * @dev Get swapBorrowRate calldata from MatrixToken. Allows a borrower to toggle his debt between stable and variable mode.
     *
     * @param lendingPool    Address of the LendingPool contract
     * @param asset          The address of the underlying asset borrowed
     * @param rateMode       The rate mode that the user wants to swap to
     *
     * @return target        Target contract address
     * @return value         Call value
     * @return callData      SwapBorrowRate calldata
     */
    function getSwapBorrowRateModeCalldata(
        ILendingPool lendingPool,
        address asset,
        uint256 rateMode
    )
        public
        pure
        returns (
            address target,
            uint256 value,
            bytes memory callData
        )
    {
        value = 0;
        target = address(lendingPool);

        // swapBorrowRateMode(address asset, uint256 rateMode)
        callData = abi.encodeWithSignature("swapBorrowRateMode(address,uint256)", asset, rateMode);
    }

    /**
     * @dev Invoke to swap borrow rate of MatrixToken. Allows MatrixToken to toggle it's debt between stable and variable mode.
     *
     * @param matrixToken    Address of the MatrixToken
     * @param lendingPool    Address of the LendingPool contract
     * @param asset          The address of the underlying asset borrowed
     * @param rateMode       The rate mode that the user wants to swap to
     */
    function invokeSwapBorrowRateMode(
        IMatrixToken matrixToken,
        ILendingPool lendingPool,
        address asset,
        uint256 rateMode
    ) external {
        (address target, , bytes memory callData) = getSwapBorrowRateModeCalldata(lendingPool, asset, rateMode);

        matrixToken.invoke(target, 0, callData);
    }
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/IAToken.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ==================== Internal Imports ====================

import { IScaledBalanceToken } from "./IScaledBalanceToken.sol";
import { IInitializableAToken } from "./IInitializableAToken.sol";
import { IAaveIncentivesController } from "./IAaveIncentivesController.sol";

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   */
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` aTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after aTokens are burned
   * @param from The owner of the aTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   */
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   */
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the aTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   */
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   */
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   */
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Invoked to execute actions on the aToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   */
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the incentives controller contract
   */
  function getIncentivesController() external view returns (IAaveIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { DataTypes } from "../../../external/aave-v2/lib/DataTypes.sol";

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";

/**
 * @title ILendingPool
 * @author Aave
 */
interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   */
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   */
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   */
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   */
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   */
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   */
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   */
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   */
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   */
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   */
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   */
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   */
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   */
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   */
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   */
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/code-examples-protocol/blob/main/V2/Credit%20Delegation/Interfaces.sol under terms of agpl-3.0 with slight modifications

// Reference: https://github.com/aave/protocol-v2/blob/ice/mainnet-deployment-03-12-2020/contracts/misc/AaveProtocolDataProvider.sol

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";

/**
 * @title IProtocolDataProvider
 * @author Aave
 */
interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);
  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);
  function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);
  function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPoolAddressesProvider.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

/**
 * @title ILendingPoolAddressesProvider
 * @author Aave
 *
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 */

interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);
    function setMarketId(string calldata marketId) external;
    function setAddress(bytes32 id, address newAddress) external;
    function setAddressAsProxy(bytes32 id, address impl) external;
    function getAddress(bytes32 id) external view returns (address);
    function getLendingPool() external view returns (address);
    function setLendingPoolImpl(address pool) external;
    function getLendingPoolConfigurator() external view returns (address);
    function setLendingPoolConfiguratorImpl(address configurator) external;
    function getLendingPoolCollateralManager() external view returns (address);
    function setLendingPoolCollateralManager(address manager) external;
    function getPoolAdmin() external view returns (address);
    function setPoolAdmin(address admin) external;
    function getEmergencyAdmin() external view returns (address);
    function setEmergencyAdmin(address admin) external;
    function getPriceOracle() external view returns (address);
    function setPriceOracle(address priceOracle) external;
    function getLendingRateOracle() external view returns (address);
    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title IController
 */
interface IController {
    // ==================== Events ====================

    event AddFactory(address indexed factory);
    event RemoveFactory(address indexed factory);
    event AddFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFeeRecipient(address newFeeRecipient);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event AddResource(address indexed resource, uint256 id);
    event RemoveResource(address indexed resource, uint256 id);
    event AddMatrix(address indexed matrixToken, address indexed factory);
    event RemoveMatrix(address indexed matrixToken);

    // ==================== External functions ====================

    function isMatrix(address matrixToken) external view returns (bool);

    function isFactory(address addr) external view returns (bool);

    function isModule(address addr) external view returns (bool);

    function isResource(address addr) external view returns (bool);

    function isSystemContract(address contractAddress) external view returns (bool);

    function getFeeRecipient() external view returns (address);

    function getModuleFee(address module, uint256 feeType) external view returns (uint256);

    function getFactories() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getResources() external view returns (address[] memory);

    function getResource(uint256 id) external view returns (address);

    function getMatrixs() external view returns (address[] memory);

    function getIntegrationRegistry() external view returns (IIntegrationRegistry);

    function getPriceOracle() external view returns (IPriceOracle);

    function getMatrixValuer() external view returns (IMatrixValuer);

    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external;

    function addMatrix(address matrixToken) external;

    function removeMatrix(address matrixToken) external;

    function addFactory(address factory) external;

    function removeFactory(address factory) external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function addResource(address resource, uint256 id) external;

    function removeResource(uint256 id) external;

    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFeeRecipient(address newFeeRecipient) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixToken
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit    Virtual value of a component's EXTERNAL position.
     * @param data           Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and  virtual units.
     *
     * @param virtualUnit                Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units
     *                                   at once via the position multiplier. Virtual units are achieved by dividing a real value by the positionMultiplier
     * @param externalPositionModules    Eexternal modules attached to each external position. Each module maps to an external position
     * @param externalPositions          Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== Events ====================

    event Invoke(address indexed target, uint256 indexed value, bytes data, bytes returnValue);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event InitializeModule(address indexed module);
    event EditManager(address newManager, address oldManager);
    event RemovePendingModule(address indexed module);
    event EditPositionMultiplier(int256 newMultiplier);
    event AddComponent(address indexed component);
    event RemoveComponent(address indexed component);
    event EditDefaultPositionUnit(address indexed component, int256 realUnit);
    event EditExternalPositionUnit(address indexed component, address indexed positionModule, int256 realUnit);
    event EditExternalPositionData(address indexed component, address indexed positionModule, bytes data);
    event AddPositionModule(address indexed component, address indexed positionModule);
    event RemovePositionModule(address indexed component, address indexed positionModule);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(
        address component,
        address positionModule,
        int256 realUnit
    ) external;

    function editExternalPositionData(
        address component,
        address positionModule,
        bytes calldata data
    ) external;

    function invoke(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    function invokeSafeApprove(
        address token,
        address spender,
        uint256 amount
    ) external;

    function invokeSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeExactSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IExchangeAdapter
 */
interface IExchangeAdapter {
    // ==================== External functions ====================

    function getSpender() external view returns (address);

    /**
     * @param srcToken           Address of source token to be sold
     * @param destToken          Address of destination token to buy
     * @param destAddress        Address that assets should be transferred to
     * @param srcQuantity        Amount of source token to sell
     * @param minDestQuantity    Min amount of destination token to buy
     * @param data               Arbitrary bytes containing trade call data
     *
     * @return target            Target contract address
     * @return value             Call value
     * @return callData          Trade calldata
     */
    function getTradeCalldata(
        address srcToken,
        address destToken,
        address destAddress,
        uint256 srcQuantity,
        uint256 minDestQuantity,
        bytes memory data
    )
        external
        view
        returns (
            address target,
            uint256 value,
            bytes memory callData
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IMatrixToken } from "./IMatrixToken.sol";

/**
 * @title IDebtIssuanceModule
 *
 * @dev Interface for interacting with Debt Issuance module interface.
 */
interface IDebtIssuanceModule {
    // ==================== External functions ====================

    /**
     * @dev Called by another module to register itself on debt issuance module.
     * Any logic can be included in case checks need to be made or state needs to be updated.
     */
    function registerToIssuanceModule(IMatrixToken matrixToken) external;

    /**
     * @dev Called by another module to unregister itself on debt issuance module.
     * Any logic can be included in case checks need to be made or state needs to be cleared.
     */
    function unregisterFromIssuanceModule(IMatrixToken matrixToken) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ==================== Internal Imports ====================

import { IMatrixToken } from "./IMatrixToken.sol";

/**
 * @title IModuleIssuanceHook
 */
interface IModuleIssuanceHook {
    // ==================== External functions ====================

    function moduleIssueHook(IMatrixToken matrixToken, uint256 matrixTokenQuantity) external;

    function moduleRedeemHook(IMatrixToken matrixToken, uint256 matrixTokenQuantity) external;

    function componentIssueHook(IMatrixToken matrixToken, uint256 matrixTokenQuantity, IERC20 component, bool isEquity) external; // prettier-ignore

    function componentRedeemHook(IMatrixToken matrixToken, uint256 matrixTokenQuantity, IERC20 component, bool isEquity) external; // prettier-ignore
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ExactSafeErc20
 *
 * @dev Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExactSafeErc20 {
    using SafeERC20 for IERC20;

    // ==================== Internal functions ====================

    /**
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     */
    function exactSafeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransfer(to, amount);
            uint256 newBalance = token.balanceOf(to);
            require(newBalance == oldBalance + amount, "ES0"); // "Invalid post transfer balance"
        }
    }

    /**
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     */
    function exactSafeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);

            if (from != to) {
                require(token.balanceOf(to) == oldBalance + amount, "ES1"); // "Invalid post transfer balance"
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IModule
 *
 * @dev Interface for interacting with Modules.
 */
interface IModule {
    // ==================== External functions ====================

    /**
     * @dev Called by a MatrixToken to notify that this module was removed from the MatrixToken.
     * Any logic can be included in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

/**
 * @title IPriceOracle
 */
interface IPriceOracle {
    // ==================== Events ====================

    event AddPair(address indexed asset1, address indexed asset2, address indexed oracle);
    event RemovePair(address indexed asset1, address indexed asset2, address indexed oracle);
    event EditPair(address indexed asset1, address indexed asset2, address indexed newOracle);
    event AddAdapter(address indexed adapter);
    event RemoveAdapter(address indexed adapter);
    event EditMasterQuoteAsset(address indexed newMasterQuote);
    event EditSecondQuoteAsset(address indexed newSecondQuote);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getOracle(address asset1, address asset2) external view returns (address);

    function getMasterQuoteAsset() external view returns (address);

    function getSecondQuoteAsset() external view returns (address);

    function getAdapters() external view returns (address[] memory);

    function getPrice(address asset1, address asset2) external view returns (uint256);

    function addPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function editPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function removePair(address asset1, address asset2) external;

    function addAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function editMasterQuoteAsset(address newMasterQuoteAsset) external;

    function editSecondQuoteAsset(address newSecondQuoteAsset) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title IMatrixValuer
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/*
 * @title IIntegrationRegistry
 */
interface IIntegrationRegistry {
    // ==================== Events ====================

    event AddIntegration(address indexed module, address indexed adapter, string integrationName);
    event RemoveIntegration(address indexed module, address indexed adapter, string integrationName);
    event EditIntegration(address indexed module, address newAdapter, string integrationName);

    // ==================== External functions ====================

    function getIntegrationAdapter(address module, string memory id) external view returns (address);

    function getIntegrationAdapterWithHash(address module, bytes32 id) external view returns (address);

    function isValidIntegration(address module, string memory id) external view returns (bool);

    function addIntegration(address module, string memory id, address wrapper) external; // prettier-ignore

    function batchAddIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function editIntegration(address module, string memory name, address adapter) external; // prettier-ignore

    function batchEditIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function removeIntegration(address module, string memory name) external;
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/types/DataTypes.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/IScaledBalanceToken.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   */
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   */
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   */
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/IInitializableAToken.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { ILendingPool } from './ILendingPool.sol';
import { IAaveIncentivesController } from './IAaveIncentivesController.sol';

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 */
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals the decimals of the underlying
   * @param aTokenName the name of the aToken
   * @param aTokenSymbol the symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the aToken
   * @param pool The address of the lending pool where this aToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0

// Copy from https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/IAaveIncentivesController.sol under terms of agpl-3.0 with slight modifications

pragma solidity ^0.8.0;

interface IAaveIncentivesController {
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /*
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   */
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /*
   * LEGACY **************************
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   */
  function assets(address asset)
    external
    view
    returns (
      uint128,
      uint128,
      uint256
    );

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   */
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   */
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   */
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   */
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @param asset The asset to incentivize
   * @return the user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function PRECISION() external view returns (uint8);

  /**
   * @dev Gets the distribution end timestamp of the emissions
   */
  function DISTRIBUTION_END() external view returns (uint256);
}