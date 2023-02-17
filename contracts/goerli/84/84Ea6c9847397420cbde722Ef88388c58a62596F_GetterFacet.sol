// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {PositionToken} from "../PositionToken.sol";
import {IGetter} from "../interfaces/IGetter.sol";
import {LibDIVA} from "../libraries/LibDIVA.sol";
import {LibDIVAStorage} from "../libraries/LibDIVAStorage.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";
import {LibEIP712Storage} from "../libraries/LibEIP712Storage.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";

contract GetterFacet is IGetter {
    function getLatestPoolId() external view override returns (uint256) {
        return LibDIVA._getLatestPoolId();
    }

    function getPoolParameters(uint256 _poolId)
        external
        view
        override
        returns (LibDIVAStorage.Pool memory)
    {
        return LibDIVA._poolParameters(_poolId);
    }

    function getPoolParametersByAddress(address _positionToken)
        external
        view
        override
        returns (LibDIVAStorage.Pool memory)
    {
        PositionToken positionToken = PositionToken(_positionToken);
        uint256 _poolId = positionToken.poolId();
        return LibDIVA._poolParameters(_poolId);
    }

    function getGovernanceParameters()
        external
        view
        override
        returns (
            LibDIVAStorage.Fees memory currentFees,
            LibDIVAStorage.SettlementPeriods memory currentSettlementPeriods,
            address treasury,
            address fallbackDataProvider,
            uint256 pauseReturnCollateralUntil
        )
    {
        // Get references to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        (, currentFees) = LibDIVA._getCurrentFees(gs);
        (, currentSettlementPeriods) = LibDIVA._getCurrentSettlementPeriods(gs);
        treasury = LibDIVA._getCurrentTreasury(gs);
        fallbackDataProvider = LibDIVA._getCurrentFallbackDataProvider(gs);
        pauseReturnCollateralUntil = gs.pauseReturnCollateralUntil;
    }

    function getFees(uint48 _indexFees)
        external
        view
        override
        returns (LibDIVAStorage.Fees memory)
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Get the fees applicable for the provided `_indexFees`
        LibDIVAStorage.Fees memory _fees = gs.fees[_indexFees];

        return _fees;
    }

    function getSettlementPeriods(uint48 _indexSettlementPeriods)
        external
        view
        override
        returns (LibDIVAStorage.SettlementPeriods memory)
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Get the settlement periods applicable
        // for the provided `_indexSettlementPeriods`
        LibDIVAStorage.SettlementPeriods memory _settlementPeriods = gs
            .settlementPeriods[_indexSettlementPeriods];

        return _settlementPeriods;
    }

    function getFeesHistory(uint256 _nbrLastUpdates)
        external
        view
        override
        returns (LibDIVAStorage.Fees[] memory)
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        return LibDIVA._getFeesHistory(_nbrLastUpdates, gs);
    }

    function getSettlementPeriodsHistory(uint256 _nbrLastUpdates)
        external
        view
        override
        returns (LibDIVAStorage.SettlementPeriods[] memory)
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        return LibDIVA._getSettlementPeriodsHistory(_nbrLastUpdates, gs);
    }

    function getFeesHistoryLength() external view override returns (uint256) {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        return gs.fees.length;
    }

    function getSettlementPeriodsHistoryLength()
        external
        view
        override
        returns (uint256)
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        return gs.settlementPeriods.length;
    }

    function getFallbackDataProviderInfo()
        external
        view
        override
        returns (
            address previousFallbackDataProvider,
            address fallbackDataProvider,
            uint256 startTimeFallbackDataProvider
        )
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Return values
        (
            previousFallbackDataProvider,
            fallbackDataProvider,
            startTimeFallbackDataProvider
        ) = LibDIVA._getFallbackDataProviderInfo(gs);
    }

    function getTreasuryInfo()
        external
        view
        override
        returns (
            address previousTreasury,
            address treasury,
            uint256 startTimeTreasury
        )
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Return values
        (previousTreasury, treasury, startTimeTreasury) = LibDIVA
            ._getTreasuryInfo(gs);
    }

    function getClaim(address _collateralToken, address _recipient)
        external
        view
        override
        returns (uint256)
    {
        return LibDIVA._getClaim(_collateralToken, _recipient);
    }

    function getTip(uint256 _poolId) external view override returns (uint256) {
        return LibDIVA._getTip(_poolId);
    }

    function getPoolIdByTypedCreateOfferHash(bytes32 _typedOfferHash)
        external
        view
        override
        returns (uint256)
    {
        return
            LibEIP712Storage._eip712Storage().typedOfferHashToPoolId[
                _typedOfferHash
            ];
    }

    function getTakerFilledAmount(bytes32 _typedOfferHash)
        external
        view
        override
        returns (uint256)
    {
        return LibEIP712._takerFilledAmount(_typedOfferHash);
    }

    function getChainId() external view override returns (uint256) {
        return LibEIP712._chainId();
    }

    function getOfferRelevantStateCreateContingentPool(
        LibEIP712.OfferCreateContingentPool calldata _offerCreateContingentPool,
        LibEIP712.Signature calldata _signature
    )
        external
        view
        override
        returns (
            LibEIP712.OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool isValidInputParamsCreateContingentPool
        )
    {
        (
            offerInfo,
            actualTakerFillableAmount,
            isSignatureValid,
            isValidInputParamsCreateContingentPool
        ) = LibEIP712._getOfferRelevantStateCreateContingentPool(
            _offerCreateContingentPool,
            _signature
        );
    }

    function getOfferRelevantStateAddLiquidity(
        LibEIP712.OfferAddLiquidity calldata _offerAddLiquidity,
        LibEIP712.Signature calldata _signature
    )
        external
        view
        override
        returns (
            LibEIP712.OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool poolExists
        )
    {
        (
            offerInfo,
            actualTakerFillableAmount,
            isSignatureValid,
            poolExists
        ) = LibEIP712._getOfferRelevantStateAddLiquidity(
            _offerAddLiquidity,
            _signature
        );
    }

    function getOfferRelevantStateRemoveLiquidity(
        LibEIP712.OfferRemoveLiquidity calldata _offerRemoveLiquidity,
        LibEIP712.Signature calldata _signature
    )
        external
        view
        override
        returns (
            LibEIP712.OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool poolExists
        )
    {
        (
            offerInfo,
            actualTakerFillableAmount,
            isSignatureValid,
            poolExists
        ) = LibEIP712._getOfferRelevantStateRemoveLiquidity(
            _offerRemoveLiquidity,
            _signature
        );
    }

    function getOwnershipContract()
        external
        view
        override
        returns (address ownershipContract_)
    {
        ownershipContract_ = LibOwnership._ownershipContract();
    }

    function getOwner() external view override returns (address owner_) {
        owner_ = LibOwnership._contractOwner();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IPositionToken} from "./interfaces/IPositionToken.sol";

/**
 * @dev Implementation contract for position token clones
 */
contract PositionToken is IPositionToken, ERC20Upgradeable {

    uint256 private _poolId;
    address private _owner;
    uint8 private _decimals;

    constructor() {
        /* @dev To prevent the implementation contract from being used, invoke the {_disableInitializers}
         * function in the constructor to automatically lock it when it is deployed.
         * For more information, refer to @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol
         */
        _disableInitializers();
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "PositionToken: caller is not owner"
            );
        _;
    }

    function mint(
        address _recipient,
        uint256 _amount
        ) external override onlyOwner {
        _mint(_recipient, _amount);
    }

    function burn(
        address _redeemer,
        uint256 _amount
        ) external override onlyOwner {
        _burn(_redeemer, _amount);
    }

    function poolId() external view override returns (uint256) {
        return _poolId;
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function initialize(
        string memory symbol_,
        uint256 poolId_,
        uint8 decimals_,
        address owner_
    ) external override initializer {

        __ERC20_init(symbol_, symbol_);

        _owner = owner_;
        _poolId = poolId_;
        _decimals = decimals_;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {LibDIVAStorage} from "../libraries/LibDIVAStorage.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";

interface IGetter {
    /**
     * @notice Returns the latest pool Id.
     * @return Pool Id.
     */
    function getLatestPoolId() external view returns (uint256);

    /**
     * @notice Returns the pool parameters for a given pool Id. To
     * obtain the fees and settlement periods applicable for the pool,
     * use the `getFees` and `getSettlementPeriods` functions
     * respectively, passing in the returend `indexFees` and
     * `indexSettlementPeriods` as arguments.
     * @param _poolId Id of the pool.
     * @return Pool struct.
     */
    function getPoolParameters(uint256 _poolId)
        external
        view
        returns (LibDIVAStorage.Pool memory);

    /**
     * @notice Same as `getPoolParameters` but using the position token
     * address as input.
     * @param _positionToken Position token address.
     * @return Pool struct.
     */
    function getPoolParametersByAddress(address _positionToken)
        external
        view
        returns (LibDIVAStorage.Pool memory);

    /**
     * @notice Returns the currently applicable governance parameters; ignores
     * parameters pending activation.
     * @return currentFees The current applicable fees.
     * @return currentSettlementPeriods The current applicable settlement periods.
     * @return treasury Current treasury address.
     * @return fallbackDataProvider Current fallback data provider address.
     * @return pauseReturnCollateralUntil Return of collateral paused until in seconds.
     */
    function getGovernanceParameters()
        external
        view
        returns (
            LibDIVAStorage.Fees memory currentFees,
            LibDIVAStorage.SettlementPeriods memory currentSettlementPeriods,
            address treasury,
            address fallbackDataProvider,
            uint256 pauseReturnCollateralUntil
        );

    /**
     * @notice Returns the protocol and settlement fees applicable for
     * a given `_indexFees`.
     * @param _indexFees The index of fees.
     * @return Fees struct.
     */
    function getFees(uint48 _indexFees)
        external
        view
        returns (LibDIVAStorage.Fees memory);

    /**
     * @notice Returns the settlement related periods applicable to
     * a given `_indexSettlementPeriods`.
     * @param _indexSettlementPeriods The index of settlement periods.
     * @return SettlementPeriods struct.
     */
    function getSettlementPeriods(uint48 _indexSettlementPeriods)
        external
        view
        returns (LibDIVAStorage.SettlementPeriods memory);

    /**
     * @notice Returns the last `_nbrLastUpdates` updates of the fees,
     * including any pending updates.
     * @dev `_nbrLastUpdates = 1` returns the most recent update, which
     * may be active or still pending. If the specified number of `_nbrLastUpdates`
     * exceeds the number of available updates, the maximum history will be
     * returned without any error. Returns an empty array if `_nbrLastUpdates = 0`.
     * @param _nbrLastUpdates Number of most recent updates to return.
     * @return Fees struct array.
     */
    function getFeesHistory(uint256 _nbrLastUpdates)
        external
        view
        returns (LibDIVAStorage.Fees[] memory);

    /**
     * @notice Returns the last `_nbrLastUpdates` updates of the settlement periods,
     * including any pending updates.
     * @dev `_nbrLastUpdates = 1` returns the most recent update, which may
     * be active or still pending. If the specified number of `_nbrLastUpdates`
     * exceeds the number of available updates, the maximum history will be
     * returned without any error. Returns an empty array if `_nbrLastUpdates = 0`.
     * @param _nbrLastUpdates Number of most recent updates to return.
     * @return Settlement periods struct array.
     */
    function getSettlementPeriodsHistory(uint256 _nbrLastUpdates)
        external
        view
        returns (LibDIVAStorage.SettlementPeriods[] memory);

    /**
     * @notice Returns the total number of fee updates. At least 1 as the initial
     * fees are set at contract deployment.
     */
    function getFeesHistoryLength() external view returns (uint256);

    /**
     * @notice Returns the total number of settlement period updates. At least 1 as
     * the initial settlement periods are set at contract deployment.
     */
    function getSettlementPeriodsHistoryLength()
        external
        view
        returns (uint256);

    /**
     * @notice Returns the latest update of the fallback data provider, including
     * the activation time and the previous data provider. Since the fallback data
     * provider applies to all pools globally, only the previous data provider
     * is stored for historical reference.
     * @return previousFallbackDataProvider Previous fallback data provider address.
     * @return fallbackDataProvider Latest update of the fallback data provider address.
     * @return startTimeFallbackDataProvider Timestamp in seconds since epoch at which
     * `fallbackDataProvider` is activated.
     */
    function getFallbackDataProviderInfo()
        external
        view
        returns (
            address previousFallbackDataProvider,
            address fallbackDataProvider,
            uint256 startTimeFallbackDataProvider
        );

    /**
     * @notice Returns the latest update of the treasury address, including
     * the activation time and the previous treasury address. Only the
     * previous data address is stored for historical reference.
     * @return previousTreasury Previous treasury address.
     * @return treasury Latest update of the treasury address.
     * @return startTimeTreasury Timestamp in seconds since epoch at which
     * `treasury` is activated.
     */
    function getTreasuryInfo()
        external
        view
        returns (
            address previousTreasury,
            address treasury,
            uint256 startTimeTreasury
        );

    /**
     * @notice Returns the claims by collateral tokens for a given account.
     * @param _recipient Recipient address.
     * @param _collateralToken Collateral token address.
     * @return Fee claim amount.
     */
    function getClaim(address _collateralToken, address _recipient)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the collateral token tip amount for a given
     * pool. Returns zero after a pool has been confirmed and tip has been
     * credited to the `claimableFeeAmount`, which can be retrieved using
     * the `getClaim` function.
     * @param _poolId Id of pool.
     * @return Tip amount expressed as an integer in collateral token decimals.
     */
    function getTip(uint256 _poolId) external view returns (uint256);

    /**
     * @notice Returns the poolId for a given `_typedOfferHash` derived from a
     * create contingent pool offer (EIP712 specific). Note that for an
     * add liquidity offer, the function will return 0 as the `poolId`
     * is part of the offer terms and not stored inside the contract.
     * @param _typedOfferHash Typed offer hash.
     * @return Pool Id linked to the offer.
     */
    function getPoolIdByTypedCreateOfferHash(bytes32 _typedOfferHash)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the filled amount for a given `_typedOfferHash` (EIP712 specific).
     * @param _typedOfferHash Typed offer hash.
     * @return PoolId linked to the offer.
     */
    function getTakerFilledAmount(bytes32 _typedOfferHash)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the chain Id.
     */
    function getChainId() external view returns (uint256);

    /**
     * @notice Function to get state of create contingent pool offer.
     * @param _offerCreateContingentPool Struct containing the create pool offer details
     * @param _signature Signature of signed message with `_offerCreateContingentPool` by `maker`
     * @return offerInfo Struct of offer info:
     * - typedOfferHash: Typed hash value of offer.
     * - status: Status of offer.
     * - takerFilledAmount: Already filled amount by taker.
     * @return actualTakerFillableAmount Actual fillable amount for taker.
     * @return isSignatureValid True if signature is valid, false otherwise.
     * @return isValidInputParamsCreateContingentPool True if input parameters specifying the
     * create contingent pool are valid, false otherwise.
     */
    function getOfferRelevantStateCreateContingentPool(
        LibEIP712.OfferCreateContingentPool calldata _offerCreateContingentPool,
        LibEIP712.Signature calldata _signature
    )
        external
        view
        returns (
            LibEIP712.OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool isValidInputParamsCreateContingentPool
        );

    /**
     * @notice Function to get state of add liquidity offer.
     * @param _offerAddLiquidity Struct containing the add liquidity offer details.
     * @param _signature Signature of signed message with `_offerAddLiquidity` by `maker`.
     * @return offerInfo Struct of offer info.
     * @return actualTakerFillableAmount Actual fillable amount for taker.
     * @return isSignatureValid Flag indicating whether the signature is valid or not.
     * @return poolExists Flag indicating whether a pool exists or not.
     */
    function getOfferRelevantStateAddLiquidity(
        LibEIP712.OfferAddLiquidity calldata _offerAddLiquidity,
        LibEIP712.Signature calldata _signature
    )
        external
        view
        returns (
            LibEIP712.OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool poolExists
        );

    /**
     * @notice Function to get state of remove liquidity offer.
     * @param _offerRemoveLiquidity Struct containing the remove liquidity offer details.
     * @param _signature Signature of signed message with `_offerRemoveLiquidity` by `maker`.
     * @return offerInfo Struct of offer info.
     * @return actualTakerFillableAmount Actual fillable amount for taker.
     * @return isSignatureValid Flag indicating whether the signature is valid or not.
     * @return poolExists Flag indicating whether a pool exists or not.
     */
    function getOfferRelevantStateRemoveLiquidity(
        LibEIP712.OfferRemoveLiquidity calldata _offerRemoveLiquidity,
        LibEIP712.Signature calldata _signature
    )
        external
        view
        returns (
            LibEIP712.OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool poolExists
        );

    /**
     * @notice Get the address of the ownership contract.
     * @return ownershipContract_ The address of the ownership contract.
     */
    function getOwnershipContract()
        external
        view
        returns (address ownershipContract_);

    /**
     * @notice Function to return the owner stored in ownership contract.
     * @return owner_ The address of the owner.
     */
    function getOwner() external view returns (address owner_);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {PositionToken} from "../PositionToken.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {IPositionTokenFactory} from "../interfaces/IPositionTokenFactory.sol";
import {SafeDecimalMath} from "./SafeDecimalMath.sol";
import {LibDIVAStorage} from "./LibDIVAStorage.sol";

// Thrown in `removeLiquidity` or `redeemPositionToken` if collateral amount
// to be returned to user during exceeds the pool's collateral balance
error AmountExceedsPoolCollateralBalance();

// Thrown in `removeLiquidity` if the fee amount to be allocated exceeds the
// pool's current collateral balance
error FeeAmountExceedsPoolCollateralBalance();

// Thrown in `addLiquidity` if the pool is already expired
error PoolExpired();

// Thrown in `createContingentPool` if the input parameters are invalid
error InvalidInputParamsCreateContingentPool();

// Thrown in `addLiquidity` if adding additional collateral would
// result in the pool capacity being exceeded
error PoolCapacityExceeded();

// Thrown in `removeLiquidity` if return collateral is paused
error ReturnCollateralPaused();

// Thrown in `removeLiquidity` if status of `finalReferenceValue`
// is already "Confirmed"
error FinalValueAlreadyConfirmed();

// Thrown in `removeLiquidity` if a user's short or long position
// token balance is smaller than the indicated amount
error InsufficientShortOrLongBalance();

// Thrown in `removeLiquidity` if `_amount` provided by user results
// in a zero protocol fee amount; user should increase their `_amount`
error ZeroProtocolFee();

// Thrown in `removeLiquidity` if `_amount` provided by user results
// in zero settlement fee amount; user should increase `_amount`
error ZeroSettlementFee();

library LibDIVA {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // Argument for `createContingentPool` function
    struct PoolParams {
        string referenceAsset;
        uint96 expiryTime;
        uint256 floor;
        uint256 inflection;
        uint256 cap;
        uint256 gradient;
        uint256 collateralAmount;
        address collateralToken;
        address dataProvider;
        uint256 capacity;
        address longRecipient;
        address shortRecipient;
        address permissionedERC721Token;
    }

    // Argument for `_createContingentPoolLib` function
    struct CreatePoolParams {
        PoolParams poolParams;
        uint256 collateralAmountMsgSender;
        uint256 collateralAmountMaker;
        address maker;
    }

    // Argument for `_addLiquidityLib` to avoid stack-too-deep error
    struct AddLiquidityParams {
        uint256 poolId;
        uint256 collateralAmountMsgSender;
        uint256 collateralAmountMaker;
        address maker;
        address longRecipient;
        address shortRecipient;
    }

    // Argument for `_removeLiquidityLib` to avoid stack-too-deep error
    struct RemoveLiquidityParams {
        uint256 poolId;
        uint256 amount;
        address longTokenHolder;
        address shortTokenHolder;
    }

    /**
     * @notice Emitted when fees are allocated.
     * @dev Collateral token can be looked up via the `getPoolParameters`
     * function using the emitted `poolId`.
     * @param poolId The Id of the pool that the fee applies to.
     * @param recipient Address that is allocated the fees.
     * @param amount Fee amount allocated.
     */
    event FeeClaimAllocated(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when a new pool is created.
     * @param poolId The Id of the newly created contingent pool.
     * @param longRecipient The address that received the long position tokens.
     * @param shortRecipient The address that received the short position tokens.
     * @param collateralAmount The collateral amount deposited into the pool.
     * @param permissionedERC721Token Address of ERC721 token that the transfer
     * restrictions apply to.
     */
    event PoolIssued(
        uint256 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount,
        address permissionedERC721Token
    );

    /**
     * @notice Emitted when new collateral is added to an existing pool.
     * @param poolId The Id of the pool that collateral was added to.
     * @param longRecipient The address that received the long position token.
     * @param shortRecipient The address that received the short position token.
     * @param collateralAmount The collateral amount added.
     */
    event LiquidityAdded(
        uint256 indexed poolId,
        address indexed longRecipient,
        address indexed shortRecipient,
        uint256 collateralAmount
    );

    /**
     * @notice Emitted when collateral is removed from an existing pool.
     * @param poolId The Id of the pool that collateral was removed from.
     * @param longTokenHolder The address of the user that contributed the long token.
     * @param shortTokenHolder The address of the user that contributed the short token.
     * @param collateralAmount The collateral amount removed from the pool.
     */
    event LiquidityRemoved(
        uint256 indexed poolId,
        address indexed longTokenHolder,
        address indexed shortTokenHolder,
        uint256 collateralAmount
    );

    /**
     * @notice Emitted when a tip has been credited to the data provider after
     * the final value is confirmed.
     * @param poolId Id of the pool for which the tip is credited
     * @param recipient Address of the tip recipient, typically the data provider
     * @param amount Tip amount allocated (in collateral token)
     */
    event TipAllocated(
        uint256 indexed poolId,
        address indexed recipient,
        uint256 amount
    );

    function _poolParameters(uint256 _poolId)
        internal
        view
        returns (LibDIVAStorage.Pool memory)
    {
        return LibDIVAStorage._poolStorage().pools[_poolId];
    }

    function _getLatestPoolId() internal view returns (uint256) {
        return LibDIVAStorage._poolStorage().poolId;
    }

    function _getClaim(address _collateralToken, address _recipient)
        internal
        view
        returns (uint256)
    {
        return
            LibDIVAStorage._feeClaimStorage().claimableFeeAmount[
                _collateralToken
            ][_recipient];
    }

    function _getTip(uint256 _poolId) internal view returns (uint256) {
        return LibDIVAStorage._feeClaimStorage().poolIdToTip[_poolId];
    }

    /**
     * @dev Internal function to transfer the collateral to the user.
     * Openzeppelin's `safeTransfer` method is used to handle different
     * implementations of the ERC20 standard.
     * @param _pool Pool struct.
     * @param _receiver Recipient address.
     * @param _amount Collateral amount to return.
     */
    function _returnCollateral(
        LibDIVAStorage.Pool storage _pool,
        address _receiver,
        uint256 _amount
    ) internal {
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        // That case shouldn't happen, but if it happens unexpectedly, then
        // it will throw here.
        if (_amount > _pool.collateralBalance)
            revert AmountExceedsPoolCollateralBalance();

        _pool.collateralBalance -= _amount;

        collateralToken.safeTransfer(_receiver, _amount);
    }

    /**
     * @notice Internal function to calculate the payoff per long and short token,
     * net of fees, and store it in `payoutLong` and `payoutShort` inside pool
     * parameters.
     * @dev Called inside `redeemPositionToken` and `setFinalReferenceValue`
     * functions after status of final reference value has been confirmed.
     * @param _pool Pool struct.
     * @param _fees Fees struct.
     * @param _collateralTokenDecimals Collateral token decimals. Passed as
     * argument to avoid reading from storage again.
     */
    function _setPayoutAmount(
        LibDIVAStorage.Pool storage _pool,
        LibDIVAStorage.Fees memory _fees,
        uint8 _collateralTokenDecimals
    ) internal {
        // Calculate payoff per short and long token. Output is in collateral
        // token decimals.
        (_pool.payoutShort, _pool.payoutLong) = _calcPayoffs(
            _pool.floor,
            _pool.inflection,
            _pool.cap,
            _pool.gradient,
            _pool.finalReferenceValue,
            _collateralTokenDecimals,
            _fees.protocolFee + _fees.settlementFee
        );
    }

    /**
     * @notice Internal function used within `setFinalReferenceValue` and
     * `redeemPositionToken` to calculate and allocate fee claims to recipient
     * (DIVA Treasury or data provider). Fee is applied to the overall
     * collateral remaining in the pool and allocated in full the first time
     * the respective function is triggered.
     * @dev Fees can be claimed via the `claimFee` function.
     * @param _poolId Pool Id.
     * @param _pool Pool struct.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * @param _recipient Fee recipient address.
     * @param _collateralBalance Current pool collateral balance expressed as
     * an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     */
    function _calcAndAllocateFeeClaim(
        uint256 _poolId,
        LibDIVAStorage.Pool storage _pool,
        uint96 _fee,
        address _recipient,
        uint256 _collateralBalance,
        uint8 _collateralTokenDecimals
    ) internal {
        uint256 _feeAmount = _calcFee(
            _fee,
            _collateralBalance,
            _collateralTokenDecimals
        );

        _allocateFeeClaim(_poolId, _pool, _recipient, _feeAmount);
    }

    /**
     * @notice Internal function to allocate fees to `recipient`.
     * @dev The balance of the recipient is tracked inside the contract and
     * can be claimed via `claimFee` function.
     * @param _poolId Pool Id that the fee applies to.
     * @param _pool Pool struct.
     * @param _recipient Address of the fee recipient.
     * @param _feeAmount Total fee amount expressed as an integer with
     * collateral token decimals.
     */
    function _allocateFeeClaim(
        uint256 _poolId,
        LibDIVAStorage.Pool storage _pool,
        address _recipient,
        uint256 _feeAmount
    ) internal {
        // Get reference to the relevant storage slot
        LibDIVAStorage.FeeClaimStorage storage fs = LibDIVAStorage
            ._feeClaimStorage();

        // Check that fee amount to be allocated doesn't exceed the pool's
        // current `collateralBalance`. This check should never trigger, but
        // kept for safety.
        if (_feeAmount > _pool.collateralBalance)
            revert FeeAmountExceedsPoolCollateralBalance();

        // Reduce `collateralBalance` in pool parameters and increase fee claim
        _pool.collateralBalance -= _feeAmount;
        fs.claimableFeeAmount[_pool.collateralToken][_recipient] += _feeAmount;

        // Log poolId, recipient and fee amount
        emit FeeClaimAllocated(_poolId, _recipient, _feeAmount);
    }

    /**
     * @notice Internal function to transfer the tip to the data provider when the
     * final reference value is confirmed.
     * @dev `poolIdToTip` is set to zero and credited to the fee claim in that process.
     * @param _poolId Id of pool.
     * @param _recipient Tip recipient.
     */
    function _allocateTip(uint256 _poolId, address _recipient) internal {
        // Get references to relevant storage slots
        LibDIVAStorage.FeeClaimStorage storage fs = LibDIVAStorage
            ._feeClaimStorage();
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[_poolId];

        // Get tip for pool
        uint256 _tip = fs.poolIdToTip[_poolId];

        // Credit tip to the claimable fee amount
        fs.poolIdToTip[_poolId] = 0;
        fs.claimableFeeAmount[_pool.collateralToken][_recipient] += _tip;

        // Log event
        emit TipAllocated(_poolId, _recipient, _tip);
    }

    /**
     * @notice Function to calculate the fee amount for a given collateral amount.
     * @dev Output is an integer expressed with collateral token decimals.
     * As fee parameter has 18 decimals but collateral tokens may have
     * less, scaling needs to be applied when using `SafeDecimalMath` library.
     * @param _fee Percentage fee expressed as an integer with 18 decimals
     * (e.g., 0.25% is 2500000000000000).
     * @param _collateralAmount Collateral amount that is used as the basis for
     * the fee calculation expressed as an integer with collateral token decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @return The fee amount expressed as an integer with collateral token decimals.
     */
    function _calcFee(
        uint96 _fee,
        uint256 _collateralAmount,
        uint8 _collateralTokenDecimals
    ) internal pure returns (uint256) {
        uint256 _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));

        uint256 _feeAmount = uint256(_fee).multiplyDecimal(
            _collateralAmount * _SCALINGFACTOR
        ) / _SCALINGFACTOR;

        return _feeAmount;
    }

    /**
     * @notice Function to calculate the payoffs per long and short token,
     * net of fees.
     * @dev Scaling applied during calculations to handle different decimals.
     * @param _floor Value of underlying at or below which the short token
     * will pay out the max amount and the long token zero. Expressed as an
     * integer with 18 decimals.
     * @param _inflection Value of underlying at which the long token will
     * payout out `_gradient` and the short token `1-_gradient`. Expressed
     * as an integer with 18 decimals.
     * @param _cap Value of underlying at or above which the long token will
     * pay out the max amount and short token zero. Expressed as an integer
     * with 18 decimals.
     * @param _gradient Long token payout at inflection (0 <= _gradient <= 1).
     * Expressed as an integer with collateral token decimals.
     * @param _finalReferenceValue Final value submitted by data provider
     * expressed as an integer with 18 decimals.
     * @param _collateralTokenDecimals Collateral token decimals.
     * @param _fee Fee in percent expressed as an integer with 18 decimals.
     * @return payoffShortNet Payoff per short token (net of fees) expressed
     * as an integer with collateral token decimals.
     * @return payoffLongNet Payoff per long token (net of fees) expressed
     * as an integer with collateral token decimals.
     */
    function _calcPayoffs(
        uint256 _floor,
        uint256 _inflection,
        uint256 _cap,
        uint256 _gradient,
        uint256 _finalReferenceValue,
        uint256 _collateralTokenDecimals,
        uint96 _fee // max value: 5% <= 2^96
    ) internal pure returns (uint96 payoffShortNet, uint96 payoffLongNet) {
        uint256 _SCALINGFACTOR = uint256(10**(18 - _collateralTokenDecimals));
        uint256 _UNIT = SafeDecimalMath.UNIT;
        uint256 _payoffLong;
        uint256 _payoffShort;
        // Note: _gradient * _SCALINGFACTOR not stored in memory for calculations
        // as it would result in a stack-too-deep error

        if (_finalReferenceValue == _inflection) {
            _payoffLong = _gradient * _SCALINGFACTOR;
        } else if (_finalReferenceValue <= _floor) {
            _payoffLong = 0;
        } else if (_finalReferenceValue >= _cap) {
            _payoffLong = _UNIT;
        } else if (_finalReferenceValue < _inflection) {
            _payoffLong = (
                (_gradient * _SCALINGFACTOR).multiplyDecimal(
                    _finalReferenceValue - _floor
                )
            ).divideDecimal(_inflection - _floor);
        } else if (_finalReferenceValue > _inflection) {
            _payoffLong =
                _gradient *
                _SCALINGFACTOR +
                (
                    (_UNIT - _gradient * _SCALINGFACTOR).multiplyDecimal(
                        _finalReferenceValue - _inflection
                    )
                ).divideDecimal(_cap - _inflection);
        }

        _payoffShort = _UNIT - _payoffLong;

        payoffShortNet = uint96(
            _payoffShort.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
        );
        payoffLongNet = uint96(
            _payoffLong.multiplyDecimal(_UNIT - _fee) / _SCALINGFACTOR
        );

        return (payoffShortNet, payoffLongNet); // collateral token decimals
    }

    function _createContingentPoolLib(CreatePoolParams memory _createPoolParams)
        internal
        returns (uint256)
    {
        // Get reference to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Create reference to collateral token corresponding to the provided pool Id
        IERC20Metadata collateralToken = IERC20Metadata(
            _createPoolParams.poolParams.collateralToken
        );

        uint8 _collateralTokenDecimals = collateralToken.decimals();

        // Check validity of input parameters
        if (
            !_validateInputParamsCreateContingentPool(
                _createPoolParams.poolParams,
                _collateralTokenDecimals
            )
        ) revert InvalidInputParamsCreateContingentPool();

        // Increment `poolId` every time a new pool is created. Index
        // starts at 1. No overflow risk when using compiler version >= 0.8.0.
        ++ps.poolId;

        // Cache new poolId to avoid reading from storage
        uint256 _poolId = ps.poolId;

        // Transfer approved collateral tokens from `msg.sender` to `this`.
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            _createPoolParams.collateralAmountMsgSender
        );

        // Transfer approved collateral tokens from maker. Applies only for `fillOfferCreateContingentPool`
        // when makerFillAmount > 0. Requires prior approval from `maker` to execute this transaction.
        if (_createPoolParams.collateralAmountMaker != 0) {
            collateralToken.safeTransferFrom(
                _createPoolParams.maker,
                address(this),
                _createPoolParams.collateralAmountMaker
            );
        }

        // Deploy two `PositionToken` contract clones, one that represents shares in the short
        // and one that represents shares in the long position.
        // Naming convention for short/long token: S13/L13 where 13 is the poolId
        // Diamond contract (address(this) due to delegatecall) is set as the
        // owner of the position tokens and is the only account that is
        // authorized to call the `mint` and `burn` function therein.
        // Note that position tokens have same number of decimals as collateral token.
        address _shortToken = IPositionTokenFactory(ps.positionTokenFactory)
            .createPositionToken(
                string(abi.encodePacked("S", Strings.toString(_poolId))), // name is equal to symbol
                _poolId,
                _collateralTokenDecimals,
                address(this),
                _createPoolParams.poolParams.permissionedERC721Token
            );

        address _longToken = IPositionTokenFactory(ps.positionTokenFactory)
            .createPositionToken(
                string(abi.encodePacked("L", Strings.toString(_poolId))), // name is equal to symbol
                _poolId,
                _collateralTokenDecimals,
                address(this),
                _createPoolParams.poolParams.permissionedERC721Token
            );

        (uint48 _indexFees, ) = _getCurrentFees(gs);
        (uint48 _indexSettlementPeriods, ) = _getCurrentSettlementPeriods(gs);

        // Store `Pool` struct in `pools` mapping for the newly generated `poolId`
        ps.pools[_poolId] = LibDIVAStorage.Pool(
            _createPoolParams.poolParams.floor,
            _createPoolParams.poolParams.inflection,
            _createPoolParams.poolParams.cap,
            _createPoolParams.poolParams.gradient,
            _createPoolParams.poolParams.collateralAmount,
            0, // finalReferenceValue
            _createPoolParams.poolParams.capacity,
            block.timestamp,
            _shortToken,
            0, // payoutShort
            _longToken,
            0, // payoutLong
            _createPoolParams.poolParams.collateralToken,
            _createPoolParams.poolParams.expiryTime,
            address(_createPoolParams.poolParams.dataProvider),
            _indexFees,
            _indexSettlementPeriods,
            LibDIVAStorage.Status.Open,
            _createPoolParams.poolParams.referenceAsset
        );

        // Number of position tokens is set equal to the total collateral to
        // standardize the max payout at 1.0. Position tokens are sent to the recipients
        // provided as part of the input parameters.
        IPositionToken(_shortToken).mint(
            _createPoolParams.poolParams.shortRecipient,
            _createPoolParams.poolParams.collateralAmount
        );
        IPositionToken(_longToken).mint(
            _createPoolParams.poolParams.longRecipient,
            _createPoolParams.poolParams.collateralAmount
        );

        // Log pool creation
        emit PoolIssued(
            _poolId,
            _createPoolParams.poolParams.longRecipient,
            _createPoolParams.poolParams.shortRecipient,
            _createPoolParams.poolParams.collateralAmount,
            _createPoolParams.poolParams.permissionedERC721Token
        );

        return _poolId;
    }

    function _validateInputParamsCreateContingentPool(
        PoolParams memory _poolParams,
        uint8 _collateralTokenDecimals
    ) internal view returns (bool) {
        // Expiry time should not be equal to or smaller than `block.timestamp`
        if (_poolParams.expiryTime <= block.timestamp) {
            return false;
        }

        // Reference asset should not be empty string
        if (bytes(_poolParams.referenceAsset).length == 0) {
            return false;
        }

        // Floor should not be greater than inflection
        if (_poolParams.floor > _poolParams.inflection) {
            return false;
        }

        // Cap should not be smaller than inflection
        if (_poolParams.cap < _poolParams.inflection) {
            return false;
        }

        // Data provider should not be zero address
        if (_poolParams.dataProvider == address(0)) {
            return false;
        }

        // Gradient should not be greater than 1 (integer in collateral token decimals)
        if (_poolParams.gradient > uint256(10**_collateralTokenDecimals)) {
            return false;
        }

        // Collateral amount should not be smaller than 1e6
        if (_poolParams.collateralAmount < 10**6) {
            return false;
        }

        // Collateral amount should not be greater than pool capacity
        if (_poolParams.collateralAmount > _poolParams.capacity) {
            return false;
        }

        // Collateral token should not have decimals larger than 18 or smaller than 6
        if ((_collateralTokenDecimals > 18) || (_collateralTokenDecimals < 6)) {
            return false;
        }

        // `longRecipient` and `shortRecipient` should not be both zero address
        if (
            _poolParams.longRecipient == address(0) &&
            _poolParams.shortRecipient == address(0)
        ) {
            return false;
        }

        return true;

        // Note: Conscious decision to allow either `longRecipient` or `shortRecipient` to
        // to be equal to the zero address to enable conditional burn use cases.
    }

    // Function to transfer collateral from msg.sender/maker to `this` and mint position token
    function _addLiquidityLib(AddLiquidityParams memory addLiquidityParams)
        internal
    {
        // Get reference to relevant storage slot
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[addLiquidityParams.poolId];

        // Connect to collateral token contract of the given pool Id
        IERC20Metadata collateralToken = IERC20Metadata(_pool.collateralToken);

        // Transfer approved collateral tokens from `msg.sender` (taker in `fillOfferAddLiquidity`) to `this`.
        // Requires prior approval from `msg.sender` to execute this transaction.
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            addLiquidityParams.collateralAmountMsgSender
        );

        // Transfer approved collateral tokens from maker. Applies only for `fillOfferAddLiquidity`
        // when makerFillAmount > 0. Requires prior approval from `maker` to execute this transaction.
        if (addLiquidityParams.collateralAmountMaker != 0) {
            collateralToken.safeTransferFrom(
                addLiquidityParams.maker,
                address(this),
                addLiquidityParams.collateralAmountMaker
            );
        }

        uint256 _collateralAmountIncr = addLiquidityParams
            .collateralAmountMsgSender +
            addLiquidityParams.collateralAmountMaker;

        // Increase `collateralBalance`
        _pool.collateralBalance += _collateralAmountIncr;

        // Mint long and short position tokens and send to `shortRecipient` and
        // `_longRecipient`, respectively (additional supply equals `_collateralAmountIncr`)
        IPositionToken(_pool.shortToken).mint(
            addLiquidityParams.shortRecipient,
            _collateralAmountIncr
        );
        IPositionToken(_pool.longToken).mint(
            addLiquidityParams.longRecipient,
            _collateralAmountIncr
        );

        // Log addition of collateral
        emit LiquidityAdded(
            addLiquidityParams.poolId,
            addLiquidityParams.longRecipient,
            addLiquidityParams.shortRecipient,
            _collateralAmountIncr
        );
    }

    function _checkAddLiquidityAllowed(
        LibDIVAStorage.Pool storage _pool,
        uint256 _collateralAmountIncr
    ) internal view {
        // Check that pool has not expired yet
        if (block.timestamp >= _pool.expiryTime) revert PoolExpired();

        // Check that new total pool collateral does not exceed the maximum
        // capacity of the pool
        if ((_pool.collateralBalance + _collateralAmountIncr) > _pool.capacity)
            revert PoolCapacityExceeded();
    }

    function _removeLiquidityLib(
        RemoveLiquidityParams memory _removeLiquidityParams
    ) internal returns (uint256 collateralAmountRemovedNet) {
        // Get references to relevant storage slots
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.GovernanceStorage storage gs = LibDIVAStorage
            ._governanceStorage();

        // Confirm that functionality is not paused
        if (block.timestamp < gs.pauseReturnCollateralUntil)
            revert ReturnCollateralPaused();

        // Initialize Pool struct
        LibDIVAStorage.Pool storage _pool = ps.pools[
            _removeLiquidityParams.poolId
        ];

        // If status is Confirmed, users should use `redeemPositionToken` function
        // to withdraw collateral
        if (_pool.statusFinalReferenceValue == LibDIVAStorage.Status.Confirmed)
            revert FinalValueAlreadyConfirmed();

        // Create reference to short and long position tokens for the given pool
        IPositionToken shortToken = IPositionToken(_pool.shortToken);
        IPositionToken longToken = IPositionToken(_pool.longToken);

        // Check that `shortTokenHolder` and `longTokenHolder` own the corresponding
        // `_amount` of short and long position tokens. In particular, this check will
        // revert when a user tries to remove an amount that exceeds the overall position token
        // supply which is the maximum amount that a user can own.
        if (
            shortToken.balanceOf(_removeLiquidityParams.shortTokenHolder) <
            _removeLiquidityParams.amount ||
            longToken.balanceOf(_removeLiquidityParams.longTokenHolder) <
            _removeLiquidityParams.amount
        ) revert InsufficientShortOrLongBalance();

        // Get fee parameters applicable for given `_poolId`
        LibDIVAStorage.Fees memory _fees = gs.fees[_pool.indexFees];

        uint256 _protocolFee;
        uint256 _settlementFee;

        if (_fees.protocolFee > 0) {
            // Calculate protocol fees to charge (note that collateral amount
            // to return is equal to `_amount`)
            _protocolFee = _calcFee(
                _fees.protocolFee,
                _removeLiquidityParams.amount,
                IERC20Metadata(_pool.collateralToken).decimals()
            );
            // User has to increase `_amount` if fee is 0
            if (_protocolFee == 0) revert ZeroProtocolFee();
        } // else _protocolFee = 0 (default value for uint256)

        if (_fees.settlementFee > 0) {
            // Calculate settlement fees to charge
            _settlementFee = _calcFee(
                _fees.settlementFee,
                _removeLiquidityParams.amount,
                IERC20Metadata(_pool.collateralToken).decimals()
            );
            // User has to increase `_amount` if fee is 0
            if (_settlementFee == 0) revert ZeroSettlementFee();
        } // else _settlementFee = 0 (default value for uint256)

        // Burn short and long position tokens
        shortToken.burn(
            _removeLiquidityParams.shortTokenHolder,
            _removeLiquidityParams.amount
        );
        longToken.burn(
            _removeLiquidityParams.longTokenHolder,
            _removeLiquidityParams.amount
        );

        // Allocate protocol fee to DIVA treasury. Fee is held within this
        // contract and can be claimed via `claimFee` function.
        // `collateralBalance` is reduced inside `_allocateFeeClaim`.
        _allocateFeeClaim(
            _removeLiquidityParams.poolId,
            _pool,
            LibDIVAStorage._governanceStorage().treasury,
            _protocolFee
        );

        // Allocate settlement fee to data provider. Fee is held within this
        // contract and can be claimed via `claimFee` function.
        _allocateFeeClaim(
            _removeLiquidityParams.poolId,
            _pool,
            _pool.dataProvider,
            _settlementFee
        );

        // Collateral amount to return net of fees
        collateralAmountRemovedNet =
            _removeLiquidityParams.amount -
            _protocolFee -
            _settlementFee;

        // Log removal of liquidity
        emit LiquidityRemoved(
            _removeLiquidityParams.poolId,
            _removeLiquidityParams.longTokenHolder,
            _removeLiquidityParams.shortTokenHolder,
            _removeLiquidityParams.amount
        );
    }

    function _getFeesHistory(
        uint256 _nbrLastUpdates,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) internal view returns (LibDIVAStorage.Fees[] memory) {
        if (_nbrLastUpdates > 0) {
            // Cache length to avoid reading from storage on every loop
            uint256 _len = _gs.fees.length;

            // Cap `_nbrLastUpdates` at max history rather than throwing an error
            _nbrLastUpdates = _nbrLastUpdates > _len ? _len : _nbrLastUpdates;

            // Define the size of the array to be returned
            LibDIVAStorage.Fees[] memory _fees = new LibDIVAStorage.Fees[](
                _nbrLastUpdates
            );

            // Iterate through the fees array starting from the latest item
            for (uint256 i = _len; i > _len - _nbrLastUpdates; ) {
                _fees[_len - i] = _gs.fees[i - 1]; // first element of _fees represents latest fees
                unchecked {
                    --i;
                }
            }
            return _fees;
        } else {
            return new LibDIVAStorage.Fees[](0);
        }
    }

    function _getSettlementPeriodsHistory(
        uint256 _nbrLastUpdates,
        LibDIVAStorage.GovernanceStorage storage _gs
    ) internal view returns (LibDIVAStorage.SettlementPeriods[] memory) {
        if (_nbrLastUpdates > 0) {
            // Cache length to avoid reading from storage on every loop
            uint256 _len = _gs.settlementPeriods.length;

            // Cap `_nbrLastUpdates` at max history rather than throwing an error
            _nbrLastUpdates = _nbrLastUpdates > _len ? _len : _nbrLastUpdates;

            // Define the size of the array to be returned
            LibDIVAStorage.SettlementPeriods[]
                memory _settlementPeriods = new LibDIVAStorage.SettlementPeriods[](
                    _nbrLastUpdates
                );

            // Iterate through the settlement periods array starting from the latest item
            for (uint256 i = _len; i > _len - _nbrLastUpdates; ) {
                _settlementPeriods[_len - i] = _gs.settlementPeriods[i - 1]; // first element of _fees represents latest fees
                unchecked {
                    --i;
                }
            }
            return _settlementPeriods;
        } else {
            return new LibDIVAStorage.SettlementPeriods[](0);
        }
    }

    function _getCurrentFees(LibDIVAStorage.GovernanceStorage storage _gs)
        internal
        view
        returns (uint48 index, LibDIVAStorage.Fees memory fees)
    {
        // Get length of `fees` array
        uint256 _len = _gs.fees.length;

        // Load latest fee regime
        LibDIVAStorage.Fees memory _fees = _gs.fees[_len - 1];

        // Return the latest array entry & index if already past activation time,
        // otherwise return the second last entry
        if (_fees.startTime > block.timestamp) {
            index = uint48(_len - 2);
        } else {
            index = uint48(_len - 1);
        }
        fees = _gs.fees[index];
    }

    function _getCurrentSettlementPeriods(
        LibDIVAStorage.GovernanceStorage storage _gs
    )
        internal
        view
        returns (
            uint48 index,
            LibDIVAStorage.SettlementPeriods memory settlementPeriods
        )
    {
        // Get length of `settlementPeriods` array
        uint256 _len = _gs.settlementPeriods.length;

        // Load latest settlement periods regime
        LibDIVAStorage.SettlementPeriods memory _settlementPeriods = _gs
            .settlementPeriods[_len - 1];

        // Return the latest array entry & index if already past activation time,
        // otherwise return the second last entry
        if (_settlementPeriods.startTime > block.timestamp) {
            index = uint48(_len - 2);
        } else {
            index = uint48(_len - 1);
        }
        settlementPeriods = _gs.settlementPeriods[index];
    }

    function _getCurrentFallbackDataProvider(
        LibDIVAStorage.GovernanceStorage storage _gs
    ) internal view returns (address) {
        // Return the new fallback data provider if `block.timestamp` is at or past
        // the activation time, else return the current fallback data provider
        return
            block.timestamp < _gs.startTimeFallbackDataProvider
                ? _gs.previousFallbackDataProvider
                : _gs.fallbackDataProvider;
    }

    function _getCurrentTreasury(LibDIVAStorage.GovernanceStorage storage _gs)
        internal
        view
        returns (address)
    {
        // Return the new treasury address if `block.timestamp` is at or past
        // the activation time, else return the current treasury address
        return
            block.timestamp < _gs.startTimeTreasury
                ? _gs.previousTreasury
                : _gs.treasury;
    }

    function _getFallbackDataProviderInfo(
        LibDIVAStorage.GovernanceStorage storage _gs
    )
        internal
        view
        returns (
            address previousFallbackDataProvider,
            address fallbackDataProvider,
            uint256 startTimeFallbackDataProvider
        )
    {
        // Return values
        previousFallbackDataProvider = _gs.previousFallbackDataProvider;
        fallbackDataProvider = _gs.fallbackDataProvider;
        startTimeFallbackDataProvider = _gs.startTimeFallbackDataProvider;
    }

    function _getTreasuryInfo(LibDIVAStorage.GovernanceStorage storage _gs)
        internal
        view
        returns (
            address previousTreasury,
            address treasury,
            uint256 startTimeTreasury
        )
    {
        // Return values
        previousTreasury = _gs.previousTreasury;
        treasury = _gs.treasury;
        startTimeTreasury = _gs.startTimeTreasury;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {PositionToken} from "../PositionToken.sol";
import {IPositionToken} from "../interfaces/IPositionToken.sol";
import {IEIP712Create} from "../interfaces/IEIP712Create.sol";
import {LibEIP712Storage} from "./LibEIP712Storage.sol";
import {LibDIVA} from "./LibDIVA.sol";
import {LibDIVAStorage} from "./LibDIVAStorage.sol";

// Thrown in `fillOfferCreateContingentPool` /  `fillOfferAddLiquidity` / `fillOfferRemoveLiquidity`
// if user tries to fill an amount smaller than the minimum provided in the offer
error TakerFillAmountSmallerMinimum();

// Thrown in `fillOfferCreateContingentPool` /  `fillOfferAddLiquidity` / `fillOfferRemoveLiquidity`
// if the provided `takerFillAmount` exceeds the remaining fillable amount
error TakerFillAmountExceedsFillableAmount();

// Thrown in `cancelOfferCreateContingentPool` / `cancelOfferAddLiquidity` / `cancelOfferRemoveLiquidity`
// if `msg.sender` is not equal to maker
error MsgSenderNotMaker();

// Thrown in `fillOfferCreateContingentPool` /  `fillOfferAddLiquidity` / `fillOfferRemoveLiquidity`
// if the signed offer and the provided signature do not match
error InvalidSignature();

// Thrown in `fillOfferCreateContingentPool` / `fillOfferAddLiquidity` / `fillOfferRemoveLiquidity`
// if offer is not fillable due to being invalid, cancelled, already filled or expired
error OfferInvalidCancelledFilledOrExpired();

// Thrown in `fillOfferCreateContingentPool` / `fillOfferAddLiquidity` / `fillOfferRemoveLiquidity`
// if offer is reserved for a different taker
error UnauthorizedTaker();

library LibEIP712 {
    using SafeERC20 for IERC20Metadata;

    // Enum for offer status
    enum OfferStatus {
        INVALID,
        CANCELLED,
        FILLED,
        EXPIRED,
        FILLABLE
    }

    // Signature structure
    struct Signature {
        uint8 v; // EC Signature data
        bytes32 r; // EC Signature data
        bytes32 s; // EC Signature data
    }

    // Argument for `fillOfferCreateContingentPool` function.
    struct OfferCreateContingentPool {
        address maker; // Signer/creator address of the offer
        address taker; // Address that is allowed to fill the offer; if zero address, then everyone can fill the offer
        uint256 makerCollateralAmount; // Collateral amount to be contributed to the contingent pool by maker
        uint256 takerCollateralAmount; // Collateral amount to be contributed to the contingent pool by taker
        bool makerIsLong; // 1 [0] if maker shall receive the long [short] position
        uint256 offerExpiry; // Offer expiration time
        uint256 minimumTakerFillAmount; // Minimum taker fill amount on first fill
        string referenceAsset; // Parameter for `createContingentPool`
        uint96 expiryTime; // Parameter for `createContingentPool`
        uint256 floor; // Parameter for `createContingentPool`
        uint256 inflection; // Parameter for `createContingentPool`
        uint256 cap; // Parameter for `createContingentPool`
        uint256 gradient; // Parameter for `createContingentPool`
        address collateralToken; // Parameter for `createContingentPool`
        address dataProvider; // Parameter for `createContingentPool`
        uint256 capacity; // Parameter for `createContingentPool`
        address permissionedERC721Token; // // Parameter for `createContingentPool`
        uint256 salt; // Arbitrary number to enforce uniqueness of the offer hash
    }

    // Argument for `fillOfferAddLiquidity` function.
    struct OfferAddLiquidity {
        address maker; // Signer/creator address of the offer
        address taker; // Address that is allowed to fill the offer; if zero address, then everyone can fill the offer
        uint256 makerCollateralAmount; // Collateral amount to be contributed to the contingent pool by maker
        uint256 takerCollateralAmount; // Collateral amount to be contributed to the contingent pool by taker
        bool makerIsLong; // 1 [0] if maker shall receive the long [short] position
        uint256 offerExpiry; // Offer expiration time
        uint256 minimumTakerFillAmount; // Minimum taker fill amount on first fill
        uint256 poolId; // Id of an existing pool
        uint256 salt; // Arbitrary number to enforce uniqueness of the offer hash
    }

    // Argument for `fillOfferRemoveLiquidity` function
    struct OfferRemoveLiquidity {
        address maker;
        address taker;
        uint256 positionTokenAmount; // Position token amount returned by taker and maker is equal
        uint256 makerCollateralAmount; // Collateral amount to be returned to maker. Amount returned to taker is positionTokenAmount - makerCollateralAmount
        bool makerIsLong; // 1 [0] if maker returns long [short] position token
        uint256 offerExpiry; // Offer expiration time
        uint256 minimumTakerFillAmount; // Minimum position token fill amount on first fill
        uint256 poolId; // Id of an existing pool
        uint256 salt; // Arbitrary number to enforce uniqueness of the offer hash
    }

    // Offer info structure
    struct OfferInfo {
        bytes32 typedOfferHash; // Offer hash
        OfferStatus status; // Offer status: 0: INVALID, 1: CANCELLED, 2: FILLED, 3: EXPIRED, 4: FILLABLE
        uint256 takerFilledAmount; // Already filled taker amount
    }

    // The type hash for eip712 domain is:
    // keccak256(
    //     abi.encodePacked(
    //         "EIP712Domain(",
    //         "string name,",
    //         "string version,",
    //         "uint256 chainId,",
    //         "address verifyingContract",
    //         ")"
    //     )
    // )
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // The type hash for create pool offer is:
    // keccak256(
    //     abi.encodePacked(
    //         "OfferCreateContingentPool(",
    //         "address maker,"
    //         "address taker,"
    //         "uint256 makerCollateralAmount,"
    //         "uint256 takerCollateralAmount,"
    //         "bool makerIsLong,"
    //         "uint256 offerExpiry,"
    //         "uint256 minimumTakerFillAmount,"
    //         "string referenceAsset,"
    //         "uint96 expiryTime,"
    //         "uint256 floor,"
    //         "uint256 inflection,"
    //         "uint256 cap,"
    //         "uint256 gradient,"
    //         "address collateralToken,"
    //         "address dataProvider,"
    //         "uint256 capacity,"
    //         "address permissionedERC721Token,"
    //         "uint256 salt)"
    //     )
    // )
    bytes32 internal constant CREATE_POOL_OFFER_TYPEHASH =
        0xc628170201b0ce3a1a2f5407dc30d69b6cc12028198419cc3aa66a1ccbdabf96;

    // The type hash for add liquidity offer is:
    // keccak256(
    //     abi.encodePacked(
    //         "OfferAddLiquidity(",
    //         "address maker,"
    //         "address taker,"
    //         "uint256 makerCollateralAmount,"
    //         "uint256 takerCollateralAmount,"
    //         "bool makerIsLong,"
    //         "uint256 offerExpiry,"
    //         "uint256 minimumTakerFillAmount,"
    //         "uint256 poolId,"
    //         "uint256 salt)"
    //     )
    // )
    bytes32 internal constant ADD_LIQUIDITY_OFFER_TYPEHASH =
        0x975f3968a81decadba63b6466e62ce2251375eafc0c1a7533833ca65c7fd37d9;

    // The type hash for remove liquidity offer is:
    // keccak256(
    //     abi.encodePacked(
    //         "OfferRemoveLiquidity(",
    //         "address maker,"
    //         "address taker,"
    //         "uint256 positionTokenAmount,"
    //         "uint256 makerCollateralAmount,"
    //         "bool makerIsLong,"
    //         "uint256 offerExpiry,"
    //         "uint256 minimumTakerFillAmount,"
    //         "uint256 poolId,"
    //         "uint256 salt)"
    //     )
    // )
    bytes32 internal constant REMOVE_LIQUIDITY_OFFER_TYPEHASH =
        0xac00f11325081eb117c866f34ac4e3a902bed956f41d8fbfbf42418bdc02af16;

    // Max int value of a uint256, used to flag cancelled offers.
    uint256 internal constant MAX_INT = ~uint256(0);

    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;
    uint256 private constant UINT_96_MASK = (1 << 96) - 1;
    uint256 private constant UINT_8_MASK = (1 << 8) - 1;

    function _chainId() internal view returns (uint256 chainId) {
        chainId = block.chainid;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function _toTypedMessageHash(bytes32 _messageHash)
        internal
        view
        returns (bytes32 typedMessageHash)
    {
        // Get domain separator to use in assembly
        bytes32 _EIP712_DOMAIN_SEPARATOR = _getDomainSeparator();

        // Assembly for more efficient computing:
        // Inspired by https://github.com/0xProject/protocol/blob/1fa093be6490cac52dfc17c31cd9fe9ff47ccc5e/contracts/utils/contracts/src/LibEIP712.sol#L87
        // keccak256(
        //     abi.encodePacked(
        //         "\x19\x01",
        //         LibEIP712Storage._eip712Storage().EIP712_DOMAIN_SEPARATOR,
        //         _messageHash
        //     )
        // );
        assembly {
            // Load free memory pointer
            let mem := mload(0x40)

            mstore(
                mem,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(mem, 0x02), _EIP712_DOMAIN_SEPARATOR) // EIP712 domain hash
            mstore(add(mem, 0x22), _messageHash) // Hash of struct

            // Compute hash
            typedMessageHash := keccak256(mem, 0x42)
        }
    }

    // Returns the domain separator for the current chain.
    function _getDomainSeparator() internal view returns (bytes32) {
        LibEIP712Storage.EIP712Storage storage es = LibEIP712Storage
            ._eip712Storage();
        if (_chainId() == es.CACHED_CHAIN_ID) {
            return es.EIP712_DOMAIN_SEPARATOR;
        } else {
            return _getDomainHash();
        }
    }

    function _getDomainHash() internal view returns (bytes32 domainHash) {
        string memory name = "DIVA Protocol";
        string memory version = "1";
        uint256 chainId = _chainId();
        address verifyingContract = address(this);

        // Assembly for more efficient computing:
        // Inspired by https://github.com/0xProject/protocol/blob/1fa093be6490cac52dfc17c31cd9fe9ff47ccc5e/contracts/utils/contracts/src/LibEIP712.sol#L61
        // keccak256(
        //     abi.encode(
        //         EIP712_DOMAIN_TYPEHASH,
        //         keccak256(bytes(name)),
        //         keccak256(bytes(version)),
        //         chainId,
        //         verifyingContract
        //     )
        // )

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 0x20), mload(name))
            let versionHash := keccak256(add(version, 0x20), mload(version))

            // Load free memory pointer
            let mem := mload(0x40)

            // Store params in memory
            mstore(mem, EIP712_DOMAIN_TYPEHASH)
            mstore(add(mem, 0x20), nameHash)
            mstore(add(mem, 0x40), versionHash)
            mstore(add(mem, 0x60), chainId)
            mstore(add(mem, 0x80), and(ADDRESS_MASK, verifyingContract))

            // Compute hash
            domainHash := keccak256(mem, 0xA0)
        }
    }

    function _takerFilledAmount(bytes32 _typedOfferHash)
        internal
        view
        returns (uint256)
    {
        return
            LibEIP712Storage._eip712Storage().typedOfferHashToTakerFilledAmount[
                _typedOfferHash
            ];
    }

    function _min256(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256 min256)
    {
        min256 = _a < _b ? _a : _b;
    }

    /**
     * @notice Function to get info of create contingent pool offer.
     * @param _offerCreateContingentPool Struct containing the create pool offer details
     * @return offerInfo Struct of offer info
     */
    function _getOfferInfoCreateContingentPool(
        OfferCreateContingentPool calldata _offerCreateContingentPool
    ) internal view returns (OfferInfo memory offerInfo) {
        // Get typed offer hash with `_offerCreateContingentPool`
        offerInfo.typedOfferHash = _toTypedMessageHash(
            _getOfferHashCreateContingentPool(_offerCreateContingentPool)
        );

        // Get offer status and takerFilledAmount
        _populateCommonOfferInfoFields(
            offerInfo,
            _offerCreateContingentPool.takerCollateralAmount,
            _offerCreateContingentPool.offerExpiry
        );
    }

    // Return hash of create pool offer details
    function _getOfferHashCreateContingentPool(
        OfferCreateContingentPool memory _offerCreateContingentPool
    ) internal pure returns (bytes32 offerHashCreateContingentPool) {
        // Assembly for more efficient computing:
        // Inspired by https://github.com/0xProject/protocol/blob/1fa093be6490cac52dfc17c31cd9fe9ff47ccc5e/contracts/zero-ex/contracts/src/features/libs/LibNativeOrder.sol#L179
        // keccak256(
        //     abi.encode(
        //         CREATE_POOL_OFFER_TYPEHASH,
        //         _offerCreateContingentPool.maker,
        //         _offerCreateContingentPool.taker,
        //         _offerCreateContingentPool.makerCollateralAmount,
        //         _offerCreateContingentPool.takerCollateralAmount,
        //         _offerCreateContingentPool.makerIsLong,
        //         _offerCreateContingentPool.offerExpiry,
        //         _offerCreateContingentPool.minimumTakerFillAmount,
        //         keccak256(bytes(_offerCreateContingentPool.referenceAsset)),
        //         _offerCreateContingentPool.expiryTime,
        //         _offerCreateContingentPool.floor,
        //         _offerCreateContingentPool.inflection,
        //         _offerCreateContingentPool.cap,
        //         _offerCreateContingentPool.gradient,
        //         _offerCreateContingentPool.collateralToken,
        //         _offerCreateContingentPool.dataProvider,
        //         _offerCreateContingentPool.capacity,
        //         _offerCreateContingentPool.permissionedERC721Token,
        //         _offerCreateContingentPool.salt
        //     )
        // )
        assembly {
            let mem := mload(0x40)
            mstore(mem, CREATE_POOL_OFFER_TYPEHASH)
            // _offerCreateContingentPool.maker;
            mstore(
                add(mem, 0x20),
                and(ADDRESS_MASK, mload(_offerCreateContingentPool))
            )
            // _offerCreateContingentPool.taker;
            mstore(
                add(mem, 0x40),
                and(ADDRESS_MASK, mload(add(_offerCreateContingentPool, 0x20)))
            )
            // _offerCreateContingentPool.makerCollateralAmount;
            mstore(add(mem, 0x60), mload(add(_offerCreateContingentPool, 0x40)))
            // _offerCreateContingentPool.takerCollateralAmount;
            mstore(add(mem, 0x80), mload(add(_offerCreateContingentPool, 0x60)))
            // _offerCreateContingentPool.makerIsLong;
            mstore(
                add(mem, 0xA0),
                and(UINT_8_MASK, mload(add(_offerCreateContingentPool, 0x80)))
            )
            // _offerCreateContingentPool.offerExpiry;
            mstore(add(mem, 0xC0), mload(add(_offerCreateContingentPool, 0xA0)))
            // _offerCreateContingentPool.minimumTakerFillAmount;
            mstore(add(mem, 0xE0), mload(add(_offerCreateContingentPool, 0xC0)))
            // _offerCreateContingentPool.referenceAsset;
            let referenceAsset := mload(add(_offerCreateContingentPool, 0xE0))
            mstore(
                add(mem, 0x100),
                keccak256(add(referenceAsset, 0x20), mload(referenceAsset))
            )
            // _offerCreateContingentPool.expiryTime;
            mstore(
                add(mem, 0x120),
                and(UINT_96_MASK, mload(add(_offerCreateContingentPool, 0x100)))
            )
            // _offerCreateContingentPool.floor;
            mstore(
                add(mem, 0x140),
                mload(add(_offerCreateContingentPool, 0x120))
            )
            // _offerCreateContingentPool.inflection;
            mstore(
                add(mem, 0x160),
                mload(add(_offerCreateContingentPool, 0x140))
            )
            // _offerCreateContingentPool.cap;
            mstore(
                add(mem, 0x180),
                mload(add(_offerCreateContingentPool, 0x160))
            )
            // _offerCreateContingentPool.gradient;
            mstore(
                add(mem, 0x1A0),
                mload(add(_offerCreateContingentPool, 0x180))
            )
            // _offerCreateContingentPool.collateralToken;
            mstore(
                add(mem, 0x1C0),
                and(ADDRESS_MASK, mload(add(_offerCreateContingentPool, 0x1A0)))
            )
            // _offerCreateContingentPool.dataProvider;
            mstore(
                add(mem, 0x1E0),
                and(ADDRESS_MASK, mload(add(_offerCreateContingentPool, 0x1C0)))
            )
            // _offerCreateContingentPool.capacity;
            mstore(
                add(mem, 0x200),
                mload(add(_offerCreateContingentPool, 0x1E0))
            )
            // _offerCreateContingentPool.permissionedERC721Token;
            mstore(
                add(mem, 0x220),
                and(ADDRESS_MASK, mload(add(_offerCreateContingentPool, 0x200)))
            )
            // _offerCreateContingentPool.salt;
            mstore(
                add(mem, 0x240),
                mload(add(_offerCreateContingentPool, 0x220))
            )
            offerHashCreateContingentPool := keccak256(mem, 0x260)
        }
    }

    /**
     * @dev Function to get offer status and taker filled amount for offerInfo.
     * @param _offerInfo Offer info struct pre-populated with offer hash.
     * @param _takerAmount` Taker collateral amount in `fillOfferCreateContingentPool`
     * and `fillOfferAddLiquidity` and position token amount in `fillOfferRemoveLiquidity`.
     * @param _offerExpiry Offer expiry.
     */
    function _populateCommonOfferInfoFields(
        OfferInfo memory _offerInfo,
        uint256 _takerAmount,
        uint256 _offerExpiry
    ) internal view {
        // Get the already filled taker amount for the given offer hash
        _offerInfo.takerFilledAmount = _takerFilledAmount(
            _offerInfo.typedOfferHash
        );

        // Check whether offer has non-zero value for positionTokenAmount (in remove) / takerCollateralAmount
        // (in add/create). An offer with takerCollateralAmount = 0, i.e. a donation offered by maker, can be
        // implemented via `createContingentPool`/`addLiquidity` directly by setting the donee as
        // the `longRecipient` or `shortRecipient`.
        if (_takerAmount == 0) {
            _offerInfo.status = OfferStatus.INVALID;
            return;
        }

        // Check whether offer is cancelled (taker filled amount is
        // set at MAX_INT if an offer is cancelled). It is acknowledged that
        // status will show CANCELLED if takerCollateralAmount = MAX_INT and
        // takerFilledAmount = MAX_INT. This mislabelling is not an issue
        // as all status checks reference FILLABLE status.
        if (_offerInfo.takerFilledAmount == MAX_INT) {
            _offerInfo.status = OfferStatus.CANCELLED;
            return;
        }

        // Check whether offer has already been filled
        if (_offerInfo.takerFilledAmount >= _takerAmount) {
            _offerInfo.status = OfferStatus.FILLED;
            return;
        }

        // Check for expiration
        if (_offerExpiry <= block.timestamp) {
            _offerInfo.status = OfferStatus.EXPIRED;
            return;
        }

        // Set offer status to fillable if none of the above is true
        _offerInfo.status = OfferStatus.FILLABLE;
    }

    /**
     * @dev Function to calculate maker fill amount given `_takerFillAmount`
     * @param _makerCollateralAmount Maker collateral amount as specified in the offer
     * @param _takerCollateralAmount taker collateral amount as specified in the offer
     * @param _takerFillAmount Taker collateral amount that the user attempts to fill
     * @return makerFillAmount Collateral amount to be contributed by the maker
     */
    function _calcMakerFillAmountAndPoolFillAmount(
        uint256 _makerCollateralAmount,
        uint256 _takerCollateralAmount,
        uint256 _takerFillAmount
    ) internal pure returns (uint256 makerFillAmount) {
        // Calc maker fill amount. An offer with `_takerCollateralAmount = 0`
        // is considered invalid and throws before it gets here (see `_checkFillableAndSignature`)
        makerFillAmount =
            (_takerFillAmount * _makerCollateralAmount) /
            _takerCollateralAmount;
    }

    /**
     * @dev Function to validate that a given signature belongs to a given offer hash
     * @param _typedOfferHash Offer hash
     * @param _signature Offer signature
     * @param _maker Maker address as specified in the offer
     */
    function _isSignatureValid(
        bytes32 _typedOfferHash,
        Signature memory _signature,
        address _maker
    ) internal pure returns (bool isSignatureValid) {
        // Recover offerMaker address with `_typedOfferHash` and `_signature` using tryRecover function from ECDSA library
        address recoveredOfferMaker = ECDSA.recover(
            _typedOfferHash,
            _signature.v,
            _signature.r,
            _signature.s
        );

        // Check that recoveredOfferMaker is not zero address
        if (recoveredOfferMaker == address(0)) {
            isSignatureValid = false;
        }
        // Check that maker address is equal to recoveredOfferMaker
        else {
            isSignatureValid = _maker == recoveredOfferMaker;
        }
    }

    /**
     * @dev Function to calculate actual taker fillable amount taking into account
     * a makers collateral token allowance and balance. Used inside
     * `getOfferRelevantStateCreateContingentPool` and `getOfferRelevantStateAddLiquidity`.
     * @param _maker Maker address as specified in the offer
     * @param _collateralToken Collateral token address as specified in the offer
     * @param _makerCollateralAmount Collateral amount to be contributed by maker
     * as specified in the offer
     * @param _takerCollateralAmount Collateral amount to be contributed by taker
     * as specified in the offer
     * @param _offerInfo Struct containing the offer hash, status and taker filled amount
     * @return actualTakerFillableAmount Actual fillable taker amount
     */
    function _getActualTakerFillableAmount(
        address _maker,
        address _collateralToken,
        uint256 _makerCollateralAmount,
        uint256 _takerCollateralAmount,
        OfferInfo memory _offerInfo
    ) internal view returns (uint256 actualTakerFillableAmount) {
        if (_makerCollateralAmount == 0) {
            // Use case: donation request by maker
            return (_takerCollateralAmount - _offerInfo.takerFilledAmount);
        }

        if (_offerInfo.status != OfferStatus.FILLABLE) {
            // Not fillable. This also includes the case where `_takerCollateralAmount` = 0
            return 0;
        }

        // Get the fillable maker amount based on the offer quantities and
        // previously filled amount
        uint256 makerFillableAmount = ((_takerCollateralAmount -
            _offerInfo.takerFilledAmount) * _makerCollateralAmount) /
            _takerCollateralAmount;

        // Clamp it to the maker fillable amount we can spend on behalf of the
        // maker
        makerFillableAmount = _min256(
            makerFillableAmount,
            _min256(
                IERC20(_collateralToken).allowance(_maker, address(this)),
                IERC20(_collateralToken).balanceOf(_maker)
            )
        );

        // Convert to taker fillable amount.
        // Division computes `floor(a / b)`. We use the identity (a, b integer):
        // ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        actualTakerFillableAmount =
            (makerFillableAmount *
                _takerCollateralAmount +
                _makerCollateralAmount -
                1) /
            _makerCollateralAmount;
    }

    /**
     * @dev Function to validate that `msg.sender` is equal to the maker
     * specified in the offer
     * @param _offerMaker Offer maker address
     */
    function _validateMessageSenderIsOfferMaker(address _offerMaker)
        internal
        view
    {
        // Check that `msg.sender` is `_offerMaker`
        if (msg.sender != _offerMaker) revert MsgSenderNotMaker();
    }

    /**
     * @dev Function to check offer fillability and signature validity
     * @param _signature Offer signature
     * @param _offerMaker Offer maker address
     * @param _offerTaker Offer taker address
     * @param _offerInfo Struct containing the offer hash, status and taker filled amount
     */
    function _checkFillableAndSignature(
        Signature calldata _signature,
        address _offerMaker,
        address _offerTaker,
        OfferInfo memory _offerInfo
    ) internal view {
        // Check that signature is valid
        if (
            !_isSignatureValid(
                _offerInfo.typedOfferHash,
                _signature,
                _offerMaker
            )
        ) revert InvalidSignature();

        // Must be fillable.
        if (_offerInfo.status != OfferStatus.FILLABLE)
            revert OfferInvalidCancelledFilledOrExpired();

        // Check that `msg.sender` is equal to `_offerTaker` or zero address in offer
        if (msg.sender != _offerTaker && _offerTaker != address(0))
            revert UnauthorizedTaker();
    }

    /**
     * @dev Function to validate that `_takerFillAmount` is greater than the minimum
     * and the implied overall taker filled amount does not exceed taker amount.
     * Increases `takerFilledAmount` after successfully passing the checks.
     * @param _takerAmount Taker amount as specified in the offer (collateral amount
     * in `fillOfferCreateContingentPool` and `fillOfferAddLiquidity` and position token amount
     * in `fillOfferRemoveLiquidity`).
     * @param _minimumTakerFillAmount Minimum taker fill amount as specified in the offer
     * @param _takerFillAmount Taker collateral amount that the user attempts to fill
     * @param _typedOfferHash Offer hash
     */
    function _validateTakerFillAmountAndIncreaseTakerFilledAmount(
        uint256 _takerAmount,
        uint256 _minimumTakerFillAmount,
        uint256 _takerFillAmount,
        bytes32 _typedOfferHash
    ) internal {
        // Get reference to relevant storage slot
        LibEIP712Storage.EIP712Storage storage es = LibEIP712Storage
            ._eip712Storage();

        // Check that `_takerFillAmount` is not smaller than `_minimumTakerFillAmount`.
        // This check is only relevant on first fill.
        if (
            _takerFillAmount +
                es.typedOfferHashToTakerFilledAmount[_typedOfferHash] <
            _minimumTakerFillAmount
        ) revert TakerFillAmountSmallerMinimum();

        // Check that `_takerFillAmount` is not higher than remaining fillable taker amount
        if (
            _takerFillAmount >
            _takerAmount - es.typedOfferHashToTakerFilledAmount[_typedOfferHash]
        ) revert TakerFillAmountExceedsFillableAmount();

        // Increase taker filled amount and store it in a mapping under the corresponding
        // offer hash
        es.typedOfferHashToTakerFilledAmount[
            _typedOfferHash
        ] += _takerFillAmount;
    }

    /**
     * @dev Function to fill an add liquidity offer. Signature validation is done
     * in the main function (`fillAddLiquidityOffer` and `fillOfferCreateContingentPool`)
     * prior to calling this function.
     * In `fillOfferCreateContingentPool`, the original create contingent pool offer
     * is used for signature validation.
     * @param _offerAddLiquidity Struct containing the add liquidity offer details
     * @param _takerFillAmount Taker collateral amount that the taker attempts to fill
     * @param _typedOfferHash Offer hash
     */
    function _fillOfferAddLiquidityLib(
        OfferAddLiquidity memory _offerAddLiquidity,
        uint256 _takerFillAmount,
        bytes32 _typedOfferHash
    ) internal {
        // Validate taker fill amount and increase taker filled amount
        _validateTakerFillAmountAndIncreaseTakerFilledAmount(
            _offerAddLiquidity.takerCollateralAmount,
            _offerAddLiquidity.minimumTakerFillAmount,
            _takerFillAmount,
            _typedOfferHash
        );

        // Calc maker fill amount
        uint256 _makerFillAmount = _calcMakerFillAmountAndPoolFillAmount(
            _offerAddLiquidity.makerCollateralAmount,
            _offerAddLiquidity.takerCollateralAmount,
            _takerFillAmount
        );

        // Get pool params using `poolId` specified in `_offerAddLiquidity`
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.Pool storage _pool = ps.pools[_offerAddLiquidity.poolId];

        // Check whether addition of liquidity is still possible. Reverts if pool expired
        // or new collateral balance exceeds pool capacity
        LibDIVA._checkAddLiquidityAllowed(
            _pool,
            _makerFillAmount + _takerFillAmount
        );

        // Transfer approved collateral token from maker and taker and mint position tokens to them
        LibDIVA._addLiquidityLib(
            LibDIVA.AddLiquidityParams({
                poolId: _offerAddLiquidity.poolId,
                collateralAmountMsgSender: _takerFillAmount,
                collateralAmountMaker: _makerFillAmount,
                maker: _offerAddLiquidity.maker,
                longRecipient: _offerAddLiquidity.makerIsLong
                    ? _offerAddLiquidity.maker
                    : msg.sender,
                shortRecipient: _offerAddLiquidity.makerIsLong
                    ? msg.sender
                    : _offerAddLiquidity.maker
            })
        );
    }

    /**
     * @notice Function to get info of add liquidity offer.
     * @param _offerAddLiquidity Struct containing the add liquidity offer details
     * @return offerInfo Struct of offer info
     */
    function _getOfferInfoAddLiquidity(
        OfferAddLiquidity calldata _offerAddLiquidity
    ) internal view returns (OfferInfo memory offerInfo) {
        // Get typed offer hash with `_offerAddLiquidity`
        offerInfo.typedOfferHash = _toTypedMessageHash(
            _getOfferHashAddLiquidity(_offerAddLiquidity)
        );

        // Get offer status and takerFilledAmount
        _populateCommonOfferInfoFields(
            offerInfo,
            _offerAddLiquidity.takerCollateralAmount,
            _offerAddLiquidity.offerExpiry
        );
    }

    // Return hash of add liquidity offer details
    function _getOfferHashAddLiquidity(
        OfferAddLiquidity memory _offerAddLiquidity
    ) internal pure returns (bytes32 offerHashAddLiquidity) {
        // Assembly for more efficient computing:
        // Inspired by https://github.com/0xProject/protocol/blob/1fa093be6490cac52dfc17c31cd9fe9ff47ccc5e/contracts/zero-ex/contracts/src/features/libs/LibNativeOrder.sol#L179
        // keccak256(
        //     abi.encode(
        //         ADD_LIQUIDITY_OFFER_TYPEHASH,
        //         _offerAddLiquidity.maker,
        //         _offerAddLiquidity.taker,
        //         _offerAddLiquidity.makerCollateralAmount,
        //         _offerAddLiquidity.takerCollateralAmount,
        //         _offerAddLiquidity.makerIsLong,
        //         _offerAddLiquidity.offerExpiry,
        //         _offerAddLiquidity.minimumTakerFillAmount,
        //         _offerAddLiquidity.poolId,
        //         _offerAddLiquidity.salt
        //     )
        // )
        assembly {
            let mem := mload(0x40)
            mstore(mem, ADD_LIQUIDITY_OFFER_TYPEHASH)
            // _offerAddLiquidity.maker;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(_offerAddLiquidity)))
            // _offerAddLiquidity.taker;
            mstore(
                add(mem, 0x40),
                and(ADDRESS_MASK, mload(add(_offerAddLiquidity, 0x20)))
            )
            // _offerAddLiquidity.makerCollateralAmount;
            mstore(add(mem, 0x60), mload(add(_offerAddLiquidity, 0x40)))
            // _offerAddLiquidity.takerCollateralAmount;
            mstore(add(mem, 0x80), mload(add(_offerAddLiquidity, 0x60)))
            // _offerAddLiquidity.makerIsLong;
            mstore(
                add(mem, 0xA0),
                and(UINT_8_MASK, mload(add(_offerAddLiquidity, 0x80)))
            )
            // _offerAddLiquidity.offerExpiry;
            mstore(add(mem, 0xC0), mload(add(_offerAddLiquidity, 0xA0)))
            // _offerAddLiquidity.minimumTakerFillAmount;
            mstore(add(mem, 0xE0), mload(add(_offerAddLiquidity, 0xC0)))
            // _offerAddLiquidity.poolId;
            mstore(add(mem, 0x100), mload(add(_offerAddLiquidity, 0xE0)))
            // _offerAddLiquidity.salt;
            mstore(add(mem, 0x120), mload(add(_offerAddLiquidity, 0x100)))
            offerHashAddLiquidity := keccak256(mem, 0x140)
        }
    }

    /**
     * @dev Function to fill a remove liquidity offer. Signature validation is done
     * in the main function (`fillRemoveLiquidityOffer`) prior to calling this function.
     * @param _offerRemoveLiquidity Struct containing the remove liquidity offer details
     * @param _takerFillAmount Position token amount that the taker attempts to fill
     * @param _typedOfferHash Offer hash
     */
    function _fillOfferRemoveLiquidityLib(
        OfferRemoveLiquidity memory _offerRemoveLiquidity,
        uint256 _takerFillAmount,
        bytes32 _typedOfferHash
    ) internal {
        // Validate taker fill amount and increase taker filled amount
        _validateTakerFillAmountAndIncreaseTakerFilledAmount(
            _offerRemoveLiquidity.positionTokenAmount,
            _offerRemoveLiquidity.minimumTakerFillAmount,
            _takerFillAmount,
            _typedOfferHash
        );

        // Get pool params using `poolId` specified in `_offerRemoveLiquidity`
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.Pool storage _pool = ps.pools[
            _offerRemoveLiquidity.poolId
        ];

        uint256 _collateralAmountRemovedNet = LibDIVA._removeLiquidityLib(
            LibDIVA.RemoveLiquidityParams({
                poolId: _offerRemoveLiquidity.poolId,
                amount: _takerFillAmount,
                longTokenHolder: _offerRemoveLiquidity.makerIsLong
                    ? _offerRemoveLiquidity.maker
                    : msg.sender,
                shortTokenHolder: _offerRemoveLiquidity.makerIsLong
                    ? msg.sender
                    : _offerRemoveLiquidity.maker
            })
        );

        uint256 _collateralAmountRemovedNetMaker = (_collateralAmountRemovedNet *
                (_offerRemoveLiquidity.makerCollateralAmount)) /
                (_offerRemoveLiquidity.positionTokenAmount);

        LibDIVA._returnCollateral(
            _pool,
            _offerRemoveLiquidity.maker,
            _collateralAmountRemovedNetMaker
        );

        LibDIVA._returnCollateral(
            _pool,
            msg.sender,
            _collateralAmountRemovedNet - _collateralAmountRemovedNetMaker
        );
    }

    /**
     * @notice Function to get info of remove liquidity offer.
     * @param _offerRemoveLiquidity Struct containing the remove liquidity offer details
     * @return offerInfo Struct of offer info
     */
    function _getOfferInfoRemoveLiquidity(
        OfferRemoveLiquidity calldata _offerRemoveLiquidity
    ) internal view returns (OfferInfo memory offerInfo) {
        // Get typed offer hash with `_offerRemoveLiquidity`
        offerInfo.typedOfferHash = _toTypedMessageHash(
            _getOfferHashRemoveLiquidity(_offerRemoveLiquidity)
        );

        // Invalidate remove liquidity offers where makerCollateralAmount > positionTokenAmount
        if (
            _offerRemoveLiquidity.makerCollateralAmount >
            _offerRemoveLiquidity.positionTokenAmount
        ) {
            offerInfo.status = OfferStatus.INVALID;
            // offerInfo.takerFilledAmount = 0; Not necesssary to set explicitly as it's automatically initialized to zero
            return offerInfo;
        }

        // Get offer status and takerFilledAmount
        _populateCommonOfferInfoFields(
            offerInfo,
            _offerRemoveLiquidity.positionTokenAmount,
            _offerRemoveLiquidity.offerExpiry
        );
    }

    // Return hash of remove liquidity offer details
    function _getOfferHashRemoveLiquidity(
        OfferRemoveLiquidity memory _offerRemoveLiquidity
    ) internal pure returns (bytes32 offerHashRemoveLiquidity) {
        // Assembly for more efficient computing:
        // Inspired by https://github.com/0xProject/protocol/blob/1fa093be6490cac52dfc17c31cd9fe9ff47ccc5e/contracts/zero-ex/contracts/src/features/libs/LibNativeOrder.sol#L179
        // keccak256(
        //     abi.encode(
        //         REMOVE_LIQUIDITY_OFFER_TYPEHASH,
        //         _offerRemoveLiquidity.maker,
        //         _offerRemoveLiquidity.taker,
        //         _offerRemoveLiquidity.positionTokenAmount,
        //         _offerRemoveLiquidity.makerCollateralAmount,
        //         _offerRemoveLiquidity.makerIsLong,
        //         _offerRemoveLiquidity.offerExpiry,
        //         _offerRemoveLiquidity.minimumTakerFillAmount,
        //         _offerRemoveLiquidity.poolId,
        //         _offerRemoveLiquidity.salt
        //     )
        // )
        assembly {
            let mem := mload(0x40)
            mstore(mem, REMOVE_LIQUIDITY_OFFER_TYPEHASH)
            // _offerRemoveLiquidity.maker;
            mstore(
                add(mem, 0x20),
                and(ADDRESS_MASK, mload(_offerRemoveLiquidity))
            )
            // _offerRemoveLiquidity.taker;
            mstore(
                add(mem, 0x40),
                and(ADDRESS_MASK, mload(add(_offerRemoveLiquidity, 0x20)))
            )
            // _offerRemoveLiquidity.positionTokenAmount;
            mstore(add(mem, 0x60), mload(add(_offerRemoveLiquidity, 0x40)))
            // _offerRemoveLiquidity.makerCollateralAmount;
            mstore(add(mem, 0x80), mload(add(_offerRemoveLiquidity, 0x60)))
            // _offerRemoveLiquidity.makerIsLong;
            mstore(
                add(mem, 0xA0),
                and(UINT_8_MASK, mload(add(_offerRemoveLiquidity, 0x80)))
            )
            // _offerRemoveLiquidity.offerExpiry;
            mstore(add(mem, 0xC0), mload(add(_offerRemoveLiquidity, 0xA0)))
            // _offerRemoveLiquidity.minimumTakerFillAmount;
            mstore(add(mem, 0xE0), mload(add(_offerRemoveLiquidity, 0xC0)))
            // _offerRemoveLiquidity.poolId;
            mstore(add(mem, 0x100), mload(add(_offerRemoveLiquidity, 0xE0)))
            // _offerRemoveLiquidity.salt;
            mstore(add(mem, 0x120), mload(add(_offerRemoveLiquidity, 0x100)))
            offerHashRemoveLiquidity := keccak256(mem, 0x140)
        }
    }

    /**
     * @dev Function to receive information on the fillability of a create contingent
     * pool offer and its validity in terms of signature and input parameters
     * for `createContingentPool` function
     * @param _offerCreateContingentPool Struct containing the create contingent pool
     * offer details
     * @param _signature Offer signature
     */
    function _getOfferRelevantStateCreateContingentPool(
        OfferCreateContingentPool calldata _offerCreateContingentPool,
        Signature calldata _signature
    )
        internal
        view
        returns (
            OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool isValidInputParamsCreateContingentPool
        )
    {
        // Get offer info
        offerInfo = _getOfferInfoCreateContingentPool(
            _offerCreateContingentPool
        );

        // Calc actual taker fillable amount
        actualTakerFillableAmount = _getActualTakerFillableAmount(
            _offerCreateContingentPool.maker,
            _offerCreateContingentPool.collateralToken,
            _offerCreateContingentPool.makerCollateralAmount,
            _offerCreateContingentPool.takerCollateralAmount,
            offerInfo
        );

        // Check if signature is valid
        isSignatureValid = _isSignatureValid(
            offerInfo.typedOfferHash,
            _signature,
            _offerCreateContingentPool.maker
        );

        // Check validity of input parameters for `createContingentPool` function
        isValidInputParamsCreateContingentPool = LibDIVA
            ._validateInputParamsCreateContingentPool(
                LibDIVA.PoolParams({
                    referenceAsset: _offerCreateContingentPool.referenceAsset,
                    expiryTime: _offerCreateContingentPool.expiryTime,
                    floor: _offerCreateContingentPool.floor,
                    inflection: _offerCreateContingentPool.inflection,
                    cap: _offerCreateContingentPool.cap,
                    gradient: _offerCreateContingentPool.gradient,
                    collateralAmount: _offerCreateContingentPool
                        .makerCollateralAmount +
                        _offerCreateContingentPool.takerCollateralAmount,
                    collateralToken: _offerCreateContingentPool.collateralToken,
                    dataProvider: _offerCreateContingentPool.dataProvider,
                    capacity: _offerCreateContingentPool.capacity,
                    longRecipient: _offerCreateContingentPool.makerIsLong
                        ? _offerCreateContingentPool.maker
                        : msg.sender,
                    shortRecipient: _offerCreateContingentPool.makerIsLong
                        ? msg.sender
                        : _offerCreateContingentPool.maker,
                    permissionedERC721Token: _offerCreateContingentPool
                        .permissionedERC721Token
                }),
                IERC20Metadata(_offerCreateContingentPool.collateralToken)
                    .decimals()
            );
    }

    /**
     * @dev Function to receive information on the fillability of an add liquidity
     * pool offer and its signature validity
     * @param _offerAddLiquidity Struct containing the add liquidity offer details
     * @param _signature Offer signature
     * @return offerInfo Struct of offer info
     * @return actualTakerFillableAmount Actual fillable amount for taker
     * @return isSignatureValid Flag indicating whether the signature is valid or not
     * @return poolExists Flag indicating whether a pool exists or not
     */
    function _getOfferRelevantStateAddLiquidity(
        OfferAddLiquidity calldata _offerAddLiquidity,
        Signature calldata _signature
    )
        internal
        view
        returns (
            OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool poolExists
        )
    {
        // Get offer info
        offerInfo = _getOfferInfoAddLiquidity(_offerAddLiquidity);

        // Get pool params using the `poolId` specified in `_offerAddLiquidity`
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.Pool storage _pool = ps.pools[_offerAddLiquidity.poolId];

        // Using collateralToken != address(0) to determine the existence of a pool. This works
        // because this case is excluded when creating a contingent pool as the zero address
        // doesn't implement the required functions (e.g., `transferFrom`) required to create
        // a contingent pool.
        if (_pool.collateralToken != address(0)) {
            // Calc actual taker fillable amount
            actualTakerFillableAmount = _getActualTakerFillableAmount(
                _offerAddLiquidity.maker,
                _pool.collateralToken,
                _offerAddLiquidity.makerCollateralAmount,
                _offerAddLiquidity.takerCollateralAmount,
                offerInfo
            );

            poolExists = true;
        } else {
            actualTakerFillableAmount = 0;
            poolExists = false;
        }

        // Check if signature is valid
        isSignatureValid = _isSignatureValid(
            offerInfo.typedOfferHash,
            _signature,
            _offerAddLiquidity.maker
        );
    }

    /**
     * @dev Function to receive information on the fillability of a remove liquidity
     * pool offer and its signature validity
     * @param _offerRemoveLiquidity Struct containing the remove liquidity offer details
     * @param _signature Offer signature
     * @return offerInfo Struct of offer info
     * @return actualTakerFillableAmount Actual fillable position token amount for taker
     * @return isSignatureValid Flag indicating whether the signature is valid or not
     * @return poolExists Flag indicating whether a pool exists or not
     */
    function _getOfferRelevantStateRemoveLiquidity(
        OfferRemoveLiquidity calldata _offerRemoveLiquidity,
        Signature calldata _signature
    )
        internal
        view
        returns (
            OfferInfo memory offerInfo,
            uint256 actualTakerFillableAmount,
            bool isSignatureValid,
            bool poolExists
        )
    {
        // Get offer info
        offerInfo = _getOfferInfoRemoveLiquidity(_offerRemoveLiquidity);

        // Get pool params using the `poolId` specified in `_offerRemoveLiquidity`
        LibDIVAStorage.PoolStorage storage ps = LibDIVAStorage._poolStorage();
        LibDIVAStorage.Pool storage _pool = ps.pools[
            _offerRemoveLiquidity.poolId
        ];

        // Using collateralToken != address(0) to determine the existence of a pool. This works
        // because this case is excluded when creating a contingent pool as the zero address
        // doesn't implement the required functions (e.g., `transferFrom`) required to create
        // a contingent pool.
        if (_pool.collateralToken != address(0)) {
            // Calc actual taker fillable amount
            if (offerInfo.status != OfferStatus.FILLABLE) {
                actualTakerFillableAmount = 0;
            } else {
                uint256 _makerPositionTokenBalance;
                if (_offerRemoveLiquidity.makerIsLong) {
                    _makerPositionTokenBalance = IERC20(_pool.longToken)
                        .balanceOf(_offerRemoveLiquidity.maker);
                } else {
                    _makerPositionTokenBalance = IERC20(_pool.shortToken)
                        .balanceOf(_offerRemoveLiquidity.maker);
                }

                actualTakerFillableAmount = _min256(
                    _offerRemoveLiquidity.positionTokenAmount -
                        offerInfo.takerFilledAmount,
                    _makerPositionTokenBalance
                );
            }

            poolExists = true;
        } else {
            actualTakerFillableAmount = 0;
            poolExists = false;
        }

        // Check if signature is valid
        isSignatureValid = _isSignatureValid(
            offerInfo.typedOfferHash,
            _signature,
            _offerRemoveLiquidity.maker
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

library LibDIVAStorage {
    // The hash for pool storage position, which is:
    // keccak256("diamond.standard.pool.storage")
    bytes32 constant POOL_STORAGE_POSITION =
        0x57b54c9a1067e6ab879c66c176c4e86e41fe1dcf5187b31dc2b93365087c7afb;

    // The hash for governance storage position, which is:
    // keccak256("diamond.standard.governance.storage")
    bytes32 constant GOVERNANCE_STORAGE_POSITION =
        0x898b136e888260ec0628fb6c3ad8f54cb15908878595b2abfc8c9ecda73a4daf;

    // The hash for fee claim storage position, which is:
    // keccak256("diamond.standard.fee.claim.storage")
    bytes32 constant FEE_CLAIM_STORAGE_POSITION =
        0x16b3e63c02e4dfaf74f59b1b7e9e81770bf30c0ed3fd4434b199357859900313;

    // Settlement status
    enum Status {
        Open,
        Submitted,
        Challenged,
        Confirmed
    }

    // Collection of pool related parameters; order was optimized to reduce storage costs
    struct Pool {
        uint256 floor; // Reference asset value at or below which the long token pays out 0 and the short token 1 (max payout) (18 decimals)
        uint256 inflection; // Reference asset value at which the long token pays out `gradient` and the short token `1-gradient` (18 decimals)
        uint256 cap; // Reference asset value at or above which the long token pays out 1 (max payout) and the short token 0 (18 decimals)
        uint256 gradient; // Long token payout at inflection (value between 0 and 1) (collateral token decimals)
        uint256 collateralBalance; // Current collateral balance of pool (collateral token decimals)
        uint256 finalReferenceValue; // Reference asset value at the time of expiration (18 decimals) - set to 0 at pool creation
        uint256 capacity; // Maximum collateral that the pool can accept (collateral token decimals)
        uint256 statusTimestamp; // Timestamp of status change - set to block.timestamp at pool creation
        address shortToken; // Short position token address
        uint96 payoutShort; // Payout amount per short position token net of fees (collateral token decimals) - set to 0 at pool creation
        address longToken; // Long position token address
        uint96 payoutLong; // Payout amount per long position token net of fees (collateral token decimals) - set to 0 at pool creation
        address collateralToken; // Address of the ERC20 collateral token
        uint96 expiryTime; // Expiration time of the pool (expressed as a unix timestamp in seconds)
        address dataProvider; // Address of data provider
        uint48 indexFees; // Index pointer to the applicable fees inside the Fees struct array
        uint48 indexSettlementPeriods; // Index pointer to the applicable periods inside the SettlementPeriods struct array
        Status statusFinalReferenceValue; // Status of final reference price (0 = Open, 1 = Submitted, 2 = Challenged, 3 = Confirmed) - set to 0 at pool creation
        string referenceAsset; // Reference asset string
    }

    // Collection of settlement related periods
    struct SettlementPeriods {
        uint256 startTime; // Timestamp at which the new set of settlement periods becomes applicable
        uint24 submissionPeriod; // Submission period length in seconds; max value: 15 days <= 2^24
        uint24 challengePeriod; // Challenge period length in seconds; max value: 15 days <= 2^24
        uint24 reviewPeriod; // Review period length in seconds; max value: 15 days <= 2^24
        uint24 fallbackSubmissionPeriod; // Fallback submission period length in seconds; max value: 15 days <= 2^24
    }

    // Collection of fee related parameters
    struct Fees {
        uint256 startTime; // timestamp at which the new set of fees becomes applicable
        uint96 protocolFee; // max value: 15000000000000000 = 1.5% <= 2^56
        uint96 settlementFee; // max value: 15000000000000000 = 1.5% <= 2^56
    }

    // Collection of governance related parameters
    struct GovernanceStorage {
        address previousTreasury; // Previous treasury address
        address treasury; // Pending/current treasury address
        uint256 startTimeTreasury; // Unix timestamp when the new treasury address is activated
        address previousFallbackDataProvider; // Previous fallback data provider address
        address fallbackDataProvider; // Pending/current fallback data provider
        uint256 startTimeFallbackDataProvider; // Unix timestamp when the new fallback provider is activated
        uint256 pauseReturnCollateralUntil; // Unix timestamp until when withdrawals are paused
        Fees[] fees; // Array including the fee regimes set over time
        SettlementPeriods[] settlementPeriods; // Array including the settlement period regimes set over time
    }

    struct FeeClaimStorage {
        mapping(address => mapping(address => uint256)) claimableFeeAmount; // collateralTokenAddress -> RecipientAddress -> amount
        mapping(uint256 => uint256) poolIdToTip; // poolId -> tip amount
    }

    struct PoolStorage {
        uint256 poolId;
        mapping(uint256 => Pool) pools;
        address positionTokenFactory;
    }

    function _poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function _governanceStorage()
        internal
        pure
        returns (GovernanceStorage storage gs)
    {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }

    function _feeClaimStorage()
        internal
        pure
        returns (FeeClaimStorage storage fs)
    {
        bytes32 position = FEE_CLAIM_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

library LibEIP712Storage {
    // The hash for eip712 storage position, which is:
    // keccak256("diamond.standard.eip712.storage")
    bytes32 constant EIP712_STORAGE_POSITION =
        0x8605704e9bc6b9116b88d76d80e5d463ac2b851042de18aae713a2e1c43f2fe5;

    struct EIP712Storage {
        // EIP712 domain separator (set in constructor in Diamond.sol)
        bytes32 EIP712_DOMAIN_SEPARATOR;
        // Chain id (set in constructor in Diamond.sol)
        uint256 CACHED_CHAIN_ID;
        // Mapping to store created poolId with typedOfferHash
        mapping(bytes32 => uint256) typedOfferHashToPoolId;
        // Mapping to store takerFilled amount with typedOfferHash
        mapping(bytes32 => uint256) typedOfferHashToTakerFilledAmount;
    }

    function _eip712Storage() internal pure returns (EIP712Storage storage es) {
        bytes32 position = EIP712_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IDIVAOwnershipShared} from "../interfaces/IDIVAOwnershipShared.sol";
import {LibDiamondStorage} from "./LibDiamondStorage.sol";

// Thrown if `msg.sender` is not contract owner
error NotContractOwner(address _user, address _contractOwner);

library LibOwnership {
    function _contractOwner() internal view returns (address contractOwner_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        contractOwner_ = IDIVAOwnershipShared(ds.ownershipContract)
            .getCurrentOwner();
    }

    function _ownershipContract()
        internal
        view
        returns (address ownershipContract_)
    {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        ownershipContract_ = ds.ownershipContract;
    }

    function _enforceIsContractOwner() internal view {
        address _owner = _contractOwner();
        if (msg.sender != _owner) revert NotContractOwner(msg.sender, _owner);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice Position token contract
 * @dev The `PositionToken` contract inherits from ERC20 contract and stores
 * the Id of the pool that the position token is linked to. It implements a
 * `mint` and a `burn` function which can only be called by the `PositionToken`
 * contract owner.
 *
 * Two `PositionToken` contracts are deployed during pool creation process
 * (`createContingentPool`) with Diamond contract being set as the owner.
 * The `mint` function is used during pool creation (`createContingentPool`)
 * and addition of liquidity (`addLiquidity`). Position tokens are burnt
 * during token redemption (`redeemPositionToken`) and removal of liquidity
 * (`removeLiquidity`). The address of the position tokens is stored in the
 * pool parameters within Diamond contract and used to verify the tokens that
 * a user sends back to withdraw collateral.
 *
 * Position tokens have the same number of decimals as the underlying
 * collateral token.
 */
interface IPositionToken is IERC20Upgradeable {
    /**
     * @notice Function to initialize the position token instance
     */
    function initialize(
        string memory symbol_, // name is set equal to symbol
        uint256 poolId_,
        uint8 decimals_,
        address owner_
    ) external;

    /**
     * @notice Function to mint ERC20 position tokens.
     * @dev Called during  `createContingentPool` and `addLiquidity`.
     * Can only be called by the owner of the position token which
     * is the Diamond contract in the context of DIVA.
     * @param _recipient The account receiving the position tokens.
     * @param _amount The number of position tokens to mint.
     */
    function mint(address _recipient, uint256 _amount) external;

    /**
     * @notice Function to burn position tokens.
     * @dev Called within `redeemPositionToken` and `removeLiquidity`.
     * Can only be called by the owner of the position token which
     * is the Diamond contract in the context of DIVA.
     * @param _redeemer Address redeeming positions tokens in return for
     * collateral.
     * @param _amount The number of position tokens to burn.
     */
    function burn(address _redeemer, uint256 _amount) external;

    /**
     * @notice Returns the Id of the contingent pool that the position token is
     * linked to in the context of DIVA.
     */
    function poolId() external view returns (uint256);

    /**
     * @notice Returns the owner of the position token (Diamond contract in the
     * context of DIVA).
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
pragma solidity 0.8.17;

import {LibEIP712} from "../libraries/LibEIP712.sol";

interface IEIP712Create {
    // Struct for `batchFillOfferCreateContingentPool` function input
    struct ArgsBatchFillOfferCreateContingentPool {
        LibEIP712.OfferCreateContingentPool offerCreateContingentPool;
        LibEIP712.Signature signature;
        uint256 takerFillAmount;
    }

    /**
     * @dev Emitted whenever an offer is filled
     * @param typedOfferHash Offer hash
     * @param maker Offer maker address
     * @param taker Offer taker address
     * @param takerFilledAmount Incremental taker filled amount
     */
    event OfferFilled(
        bytes32 indexed typedOfferHash,
        address indexed maker,
        address indexed taker,
        uint256 takerFilledAmount
    );

    /**
     * @notice Function to fill an EIP712 based offer to a create contingent pool.
     * @dev As opposed to `createContingentPool`, the collateral is contributed by
     * both `maker` and `taker` instead of `msg.sender` only according to the
     * ratios implied by `makerCollateralAmount` and `takerCollateralAmount` defined in
     * the offer details.
     * As a result, both `maker` and `taker` need to have a sufficient
     * collateral token balance as well as sufficient allowance to `this` contract
     * to transfer the collateral token from their accounts.
     * The fillability and validity of an offer can be checked via
     * `getOfferRelevantStateCreateContingentPool` prior to execution.
     * @param _offerCreateContingentPool Struct containing the create pool offer details
     * @param _signature Offer signature
     * @param _takerFillAmount Taker collateral amount that the user attempts to fill
     */
    function fillOfferCreateContingentPool(
        LibEIP712.OfferCreateContingentPool calldata _offerCreateContingentPool,
        LibEIP712.Signature calldata _signature,
        uint256 _takerFillAmount
    ) external;

    /**
     * @notice Batch version of `fillOfferCreateContingentPool`
     * @param _argsBatchFillOfferCreateContingentPool Struct array containing
     * offerCreateContingentPool, signature and taker fill amount
     */
    function batchFillOfferCreateContingentPool(
        ArgsBatchFillOfferCreateContingentPool[]
            calldata _argsBatchFillOfferCreateContingentPool
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IPositionTokenFactory {
    /**
     * @notice Creates a clone of the permissionless position token contract.
     * @param _symbol Symbol string of the position token. Name is set equal to symbol.
     * @param _poolId The Id of the contingent pool that the position token belongs to.
     * @param _decimals Decimals of position token (same as collateral token).
     * @param _owner Owner of the position token. Should always be DIVA Protocol address.
     * @param _permissionedERC721Token Address of permissioned ERC721 token.
     * @return clone Returns the address of the clone contract.
     */
    function createPositionToken(
        string memory _symbol,
        uint256 _poolId,
        uint8 _decimals,
        address _owner,
        address _permissionedERC721Token
    ) external returns (address clone);

    /**
     * @notice Address where the position token implementation contract is stored.
     * @dev This is needed since we are using a clone proxy.
     * @return The implementation address.
     */
    function positionTokenImplementation() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

/**
 * @notice Reduced version of Synthetix' SafeDecimalMath library for decimal
 * calculations:
 * https://github.com/Synthetixio/synthetix/blob/master/contracts/SafeDecimalMath.sol
 * Note that the code was adjusted for solidity 0.8.17 where SafeMath is no
 * longer required to handle overflows
 */

library SafeDecimalMath {
    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands
     * as fixed-point decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is
     * evaluated, so that product must be less than 2**256. As this is an
     * integer division, the internal division always rounds down. This helps
     * save on gas. Rounding is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // Divide by UNIT to remove the extra factor introduced by the product
        return (x * y) / UNIT;
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // Reintroduce the UNIT factor that will be divided out by y
        return (x * UNIT) / y;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

library LibDiamondStorage {
    // The hash for diamond storage position, which is:
    // keccak256("diamond.standard.diamond.storage")
    bytes32 constant DIAMOND_STORAGE_POSITION =
        0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // Maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // Maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // Facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Address of contract that stores the owner and implements the ownership
        // transfer mechanism
        address ownershipContract;
    }

    function _diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}