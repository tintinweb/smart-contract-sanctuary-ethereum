// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import { Owned } from "@solmate/auth/Owned.sol";
import { UniswapV3Pool } from "src/interfaces/uniswapV3/UniswapV3Pool.sol";
import { NonFungiblePositionManager } from "src/interfaces/uniswapV3/NonFungiblePositionManager.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { IKeeperRegistrar, RegistrationParams } from "src/interfaces/chainlink/IKeeperRegistrar.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IChainlinkAggregator } from "src/interfaces/chainlink/IChainlinkAggregator.sol";

/**
 * @title Limit Order Registry
 * @notice Allows users to create decentralized limit orders.
 * @dev DO NOT PLACE LIMIT ORDERS FOR STRONGLY CORRELATED ASSETS.
 *      - If a stable coin pair were to temporarily depeg, and a user places a limit order
 *        whose tick range encompasses the normal trading tick, there is NO way to cancel the order
 *        because the order is mixed. The user would have to wait for another depeg event to happen
 *        so that the order can be fulfilled, or the order can be cancelled.
 * @author crispymangoes
 */
contract LimitOrderRegistry is Owned, AutomationCompatibleInterface, ERC721Holder, Context {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores linked list center values, and frequently used pool values.
     * @param centerHead Linked list center value closer to head of the list
     * @param centerTail Linked list center value closer to tail of the list
     * @param token0 ERC20 token0 of the pool
     * @param token1 ERC20 token1 of the pool
     * @param fee Uniswap V3 pool fee
     */
    struct PoolData {
        uint256 centerHead;
        uint256 centerTail;
        ERC20 token0;
        ERC20 token1;
        uint24 fee;
    }

    /**
     * @notice Stores information about batches of orders.
     * @dev User orders can be batched together if they share the same target price.
     * @param direction Determines what direction the tick must move in order for the order to be filled
     *        - true, pool tick must INCREASE to fill this order
     *        - false, pool tick must DECREASE to fill this order
     * @param tickUpper The upper tick of the underlying LP position
     * @param tickLower The lower tick of the underlying LP position
     * @param userCount The number of users in this batch order
     * @param batchId Unique id used to distinguish this batch order from another batch order in the past that used the same LP position
     * @param token0Amount The amount of token0 in this order
     * @param token1Amount The amount of token1 in this order
     * @param head The next node in the linked list when moving toward the head
     * @param tail The next node in the linked list when moving toward the tail
     */
    struct BatchOrder {
        bool direction;
        int24 tickUpper;
        int24 tickLower;
        uint64 userCount;
        uint128 batchId;
        uint128 token0Amount;
        uint128 token1Amount;
        uint256 head;
        uint256 tail;
    }

    /**
     * @notice Stores information needed for users to make claims.
     * @param pool The Uniswap V3 pool the batch order was in
     * @param token0Amount The amount of token0 in the order
     * @param token1Amount The amount of token1 in the order
     * @param feePerUser The native token fee that must be paid on order claiming
     * @param direction The underlying order direction, used to determine input/output token of the order
     * @param isReadyForClaim Explicit bool indicating whether or not this order is ready to be claimed
     */
    struct Claim {
        UniswapV3Pool pool;
        uint128 token0Amount; //Can either be the deposit amount or the amount got out of liquidity changing to the other token
        uint128 token1Amount;
        uint128 feePerUser; // Fee in terms of network native asset.
        bool direction; //Determines the token out
        bool isReadyForClaim;
    }

    /**
     * @notice Struct used to store variables needed during order creation.
     * @param tick The target tick of the order
     * @param upper The upper tick of the underlying LP position
     * @param lower The lower tick of the underlying LP position
     * @param userTotal The total amount of assets the user has in the order
     * @param positionId The underling LP position token id this order is adding liquidity to
     * @param amount0 Can be the amount of assets user added to the order, based off orders direction
     * @param amount1 Can be the amount of assets user added to the order, based off orders direction
     */
    struct OrderDetails {
        int24 tick;
        int24 upper;
        int24 lower;
        uint128 userTotal;
        uint256 positionId;
        uint128 amount0;
        uint128 amount1;
    }

    /*//////////////////////////////////////////////////////////////
                             GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores swap fees earned from limit order where the input token earns swap fees.
     */
    mapping(address => uint256) public tokenToSwapFees;

    /**
     * @notice Used to store claim information needed when users are claiming their orders.
     */
    mapping(uint128 => Claim) public claim;

    /**
     * @notice Stores the pools center head/tail, as well as frequently read values.
     */
    mapping(UniswapV3Pool => PoolData) public poolToData;

    /**
     * @notice Maps tick ranges to LP positions owned by this contract.
     * @dev  maps pool -> direction -> lower -> upper -> positionId
     */
    mapping(UniswapV3Pool => mapping(bool => mapping(int24 => mapping(int24 => uint256)))) public getPositionFromTicks;

    /**
     * @notice The minimum amount of assets required to create a `newOrder`.
     * @dev Changeable by owner.
     */
    mapping(ERC20 => uint256) public minimumAssets;

    /**
     * @notice Approximated amount of gas needed to fulfill 1 BatchOrder.
     * @dev Changeable by owner.
     */
    uint32 public upkeepGasLimit = 300_000;

    /**
     * @notice Approximated gas price used to fulfill orders.
     * @dev Changeable by owner.
     */
    uint32 public upkeepGasPrice = 30;

    /**
     * @notice Max number of orders that can be filled in 1 upkeep call.
     * @dev Changeable by owner.
     */
    uint16 public maxFillsPerUpkeep = 10;

    /**
     * @notice Value is incremented whenever a new BatchOrder is added to the `orderBook`.
     * @dev Zero is reserved.
     */
    uint128 public batchCount = 1;

    /**
     * @notice Mapping is used to store user deposit amounts in each BatchOrder.
     */
    mapping(uint128 => mapping(address => uint128)) public batchIdToUserDepositAmount;

    /**
     * @notice The `orderBook` maps Uniswap V3 token ids to BatchOrder information.
     * @dev Each BatchOrder contains a head and tail value which effectively,
     *      which means BatchOrders are connected using a doubly linked list.
     */
    mapping(uint256 => BatchOrder) public orderBook;

    /**
     * @notice Chainlink Automation Registrar contract.
     */
    IKeeperRegistrar public registrar;

    /**
     * @notice Whether or not the contract is shutdown in case of an emergency.
     */
    bool public isShutdown;

    /**
     * @notice Chainlink Fast Gas Feed.
     * @dev Feed for ETH Mainnet 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C.
     */
    address public fastGasFeed;

    /**
     * @notice The max possible gas the owner can set for the gas limit.
     */
    uint32 public constant MAX_GAS_LIMIT = 750_000;

    /**
     * @notice The max possible gas price the owner can set for the gas price.
     * @dev In units of gwei.
     */
    uint32 public constant MAX_GAS_PRICE = 1_000;

    /**
     * @notice The max number of orders that can be fulfilled in a single upkeep TX.
     */
    uint16 public constant MAX_FILLS_PER_UPKEEP = 20;

    /**
     * @notice The ETH Fast Gas Feed heartbeat.
     * @dev If answer is stale, owner set gas price is used.
     */
    uint256 public constant FAST_GAS_HEARTBEAT = 7200;

    /**
     * @notice Function selector used to create V1 Upkeep versions.
     */
    bytes4 private constant FUNC_SELECTOR =
        bytes4(keccak256("register(string,bytes,address,uint32,address,bytes,uint96,uint8,address)"));

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Prevent a function from being called during a shutdown.
     */
    modifier whenNotShutdown() {
        if (isShutdown) revert LimitOrderRegistry__ContractShutdown();

        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewOrder(address user, address pool, uint128 amount, uint128 userTotal, BatchOrder affectedOrder);
    event ClaimOrder(address user, uint128 batchId, uint256 amount);
    event CancelOrder(address user, uint128 amount0, uint128 amount1, BatchOrder affectedOrder);
    event OrderFilled(uint256 batchId, address pool);
    event ShutdownChanged(bool isShutdown);
    event LimitOrderSetup(address pool);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LimitOrderRegistry__OrderITM(int24 currentTick, int24 targetTick, bool direction);
    error LimitOrderRegistry__PoolAlreadySetup(address pool);
    error LimitOrderRegistry__PoolNotSetup(address pool);
    error LimitOrderRegistry__InvalidTargetTick(int24 targetTick, int24 tickSpacing);
    error LimitOrderRegistry__UserNotFound(address user, uint256 batchId);
    error LimitOrderRegistry__InvalidPositionId();
    error LimitOrderRegistry__NoLiquidityInOrder();
    error LimitOrderRegistry__NoOrdersToFulfill();
    error LimitOrderRegistry__CenterITM();
    error LimitOrderRegistry__OrderNotInList(uint256 tokenId);
    error LimitOrderRegistry__MinimumNotSet(address asset);
    error LimitOrderRegistry__MinimumNotMet(address asset, uint256 minimum, uint256 amount);
    error LimitOrderRegistry__InvalidTickRange(int24 upper, int24 lower);
    error LimitOrderRegistry__ZeroFeesToWithdraw(address token);
    error LimitOrderRegistry__ZeroNativeBalance();
    error LimitOrderRegistry__InvalidBatchId();
    error LimitOrderRegistry__OrderNotReadyToClaim(uint128 batchId);
    error LimitOrderRegistry__ContractShutdown();
    error LimitOrderRegistry__ContractNotShutdown();
    error LimitOrderRegistry__InvalidGasLimit();
    error LimitOrderRegistry__InvalidGasPrice();
    error LimitOrderRegistry__InvalidFillsPerUpkeep();
    error LimitOrderRegistry__AmountShouldBeZero();
    error LimitOrderRegistry__DirectionMisMatch();

    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum OrderStatus {
        ITM,
        OTM,
        MIXED
    }

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable WRAPPED_NATIVE; // Mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    NonFungiblePositionManager public immutable POSITION_MANAGER; // Mainnet 0xC36442b4a4522E871399CD717aBDD847Ab11FE88

    LinkTokenInterface public immutable LINK; // Mainnet 0x514910771AF9Ca656af840dff83E8264EcF986CA

    constructor(
        address _owner,
        NonFungiblePositionManager _positionManager,
        ERC20 wrappedNative,
        LinkTokenInterface link,
        IKeeperRegistrar _registrar,
        address _fastGasFeed
    ) Owned(_owner) {
        POSITION_MANAGER = _positionManager;
        WRAPPED_NATIVE = wrappedNative;
        LINK = link;
        registrar = _registrar;
        fastGasFeed = _fastGasFeed;
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice No input validation is done because it is in the owners best interest to choose a valid registrar.
     */
    function setRegistrar(IKeeperRegistrar _registrar) external onlyOwner {
        registrar = _registrar;
    }

    /**
     * @notice Allows owner to set the fills per upkeep.
     */
    function setMaxFillsPerUpkeep(uint16 newVal) external onlyOwner {
        if (newVal == 0 || newVal > MAX_FILLS_PER_UPKEEP) revert LimitOrderRegistry__InvalidFillsPerUpkeep();
        maxFillsPerUpkeep = newVal;
    }

    /**
     * @notice Allows owner to setup a new limit order for a new pool.
     * @dev New Limit orders, should have a keeper to fulfill orders.
     * @dev If `initialUpkeepFunds` is zero, upkeep creation is skipped.
     */
    function setupLimitOrder(UniswapV3Pool pool, uint256 initialUpkeepFunds) external onlyOwner {
        // Check if Limit Order is already setup for `pool`.
        if (address(poolToData[pool].token0) != address(0)) revert LimitOrderRegistry__PoolAlreadySetup(address(pool));

        // Create Upkeep.
        if (initialUpkeepFunds > 0) {
            // Owner wants to automatically create an upkeep for new pool.
            ERC20(address(LINK)).safeTransferFrom(owner, address(this), initialUpkeepFunds);
            if (bytes(registrar.typeAndVersion())[16] == bytes("1")[0]) {
                // Use V1 Upkeep Registration.
                bytes memory data = abi.encodeWithSelector(
                    FUNC_SELECTOR,
                    "Limit Order Registry",
                    abi.encode(0),
                    address(this),
                    uint32(maxFillsPerUpkeep * upkeepGasLimit),
                    owner,
                    abi.encode(pool),
                    uint96(initialUpkeepFunds),
                    77,
                    address(this)
                );
                LINK.transferAndCall(address(registrar), initialUpkeepFunds, data);
            } else {
                // Use V2 Upkeep Registration.
                ERC20(address(LINK)).safeApprove(address(registrar), initialUpkeepFunds);
                RegistrationParams memory params = RegistrationParams({
                    name: "Limit Order Registry",
                    encryptedEmail: abi.encode(0),
                    upkeepContract: address(this),
                    gasLimit: uint32(maxFillsPerUpkeep * upkeepGasLimit),
                    adminAddress: owner,
                    checkData: abi.encode(pool),
                    offchainConfig: abi.encode(0),
                    amount: uint96(initialUpkeepFunds)
                });
                registrar.registerUpkeep(params);
            }
        }

        // poolToData
        poolToData[pool] = PoolData({
            centerHead: 0,
            centerTail: 0,
            token0: ERC20(pool.token0()),
            token1: ERC20(pool.token1()),
            fee: pool.fee()
        });

        emit LimitOrderSetup(address(pool));
    }

    /**
     * @notice Allows owner to set the minimum assets used to create `newOrder`s.
     * @dev This value can be zero, but then this contract can be griefed by an attacker spamming low liquidity orders.
     */
    function setMinimumAssets(uint256 amount, ERC20 asset) external onlyOwner {
        minimumAssets[asset] = amount;
    }

    /**
     * @notice Allows owner to change the gas limit value used to determine the Native asset fee needed to claim orders.
     * @dev premium should be factored into this value.
     */
    function setUpkeepGasLimit(uint32 gasLimit) external onlyOwner {
        if (gasLimit > MAX_GAS_LIMIT) revert LimitOrderRegistry__InvalidGasLimit();
        upkeepGasLimit = gasLimit;
    }

    /**
     * @notice Allows owner to change the gas price used to determine the Native asset fee needed to claim orders.
     * @dev `gasPrice` uses units of gwei.
     */
    function setUpkeepGasPrice(uint32 gasPrice) external onlyOwner {
        if (gasPrice > MAX_GAS_PRICE) revert LimitOrderRegistry__InvalidGasPrice();
        upkeepGasPrice = gasPrice;
    }

    /**
     * @notice Allows owner to set the fast gas feed.
     */
    function setFastGasFeed(address feed) external onlyOwner {
        fastGasFeed = feed;
    }

    /**
     * @notice Allows owner to withdraw swap fees earned from the input token of orders.
     */
    function withdrawSwapFees(address tokenFeeIsIn) external onlyOwner {
        uint256 fee = tokenToSwapFees[tokenFeeIsIn];

        // Make sure there are actually fees to withdraw.
        if (fee == 0) revert LimitOrderRegistry__ZeroFeesToWithdraw(tokenFeeIsIn);

        tokenToSwapFees[tokenFeeIsIn] = 0;
        ERC20(tokenFeeIsIn).safeTransfer(owner, fee);
    }

    /**
     * @notice Allows owner to withdraw wrapped native and native assets from this contract.
     */
    function withdrawNative() external onlyOwner {
        uint256 wrappedNativeBalance = WRAPPED_NATIVE.balanceOf(address(this));
        uint256 nativeBalance = address(this).balance;
        // Make sure there is something to withdraw.
        if (wrappedNativeBalance == 0 && nativeBalance == 0) revert LimitOrderRegistry__ZeroNativeBalance();
        if (wrappedNativeBalance > 0) WRAPPED_NATIVE.safeTransfer(owner, wrappedNativeBalance);
        if (nativeBalance > 0) owner.safeTransferETH(nativeBalance);
    }

    /**
     * @notice Shutdown the registry. Used in an emergency or if the registry has been deprecated.
     */
    function initiateShutdown() external whenNotShutdown onlyOwner {
        isShutdown = true;

        emit ShutdownChanged(true);
    }

    /**
     * @notice Restart the registry.
     */
    function liftShutdown() external onlyOwner {
        if (!isShutdown) revert LimitOrderRegistry__ContractNotShutdown();
        isShutdown = false;

        emit ShutdownChanged(false);
    }

    /*//////////////////////////////////////////////////////////////
                        USER ORDER MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new limit order for a specific pool.
     * @dev Limit orders can be created to buy either token0, or token1 of the pool.
     * @param pool the Uniswap V3 pool to create a limit order on.
     * @param targetTick the tick, that when `pool`'s tick passes, the order will be completely fulfilled
     * @param amount the amount of the input token to sell for the desired token out
     * @param direction bool indicating what the desired token out is
     *                  - true  token in = token0 ; token out = token1
     *                  - false token in = token1 ; token out = token0
     * @param startingNode an NFT position id indicating where this contract should start searching for a spot in the list
     *                     - can be zero which defaults to starting the search at center of list
     * @dev reverts if
     *      - pool is not setup
     *      - targetTick is not divisible by the pools tick spacing
     *      - the new order would be ITM, or in a MIXED state
     *      - the new order does not meet minimum liquidity requirements
     *      - transferFrom fails

     * @dev Emits a `NewOrder` event which contains meta data about the order including the orders `batchId`(which is used for claiming/cancelling).
     */
    function newOrder(
        UniswapV3Pool pool,
        int24 targetTick,
        uint128 amount,
        bool direction,
        uint256 startingNode,
        uint256 deadline
    ) external whenNotShutdown returns (uint128) {
        if (address(poolToData[pool].token0) == address(0)) revert LimitOrderRegistry__PoolNotSetup(address(pool));

        address sender = _msgSender();

        // Transfer assets into contract before setting/checking any state.
        {
            ERC20 assetIn = direction ? poolToData[pool].token0 : poolToData[pool].token1;
            _enforceMinimumLiquidity(amount, assetIn);
            assetIn.safeTransferFrom(sender, address(this), amount);
        }

        OrderDetails memory details;

        (, details.tick, , , , , ) = pool.slot0();

        // Determine upper and lower ticks.
        {
            int24 tickSpacing = pool.tickSpacing();
            // Make sure targetTick is divisible by spacing.
            if (targetTick % tickSpacing != 0) revert LimitOrderRegistry__InvalidTargetTick(targetTick, tickSpacing);
            if (direction) {
                details.upper = targetTick;
                details.lower = targetTick - tickSpacing;
            } else {
                details.upper = targetTick + tickSpacing;
                details.lower = targetTick;
            }
        }
        // Validate lower, upper,and direction.
        {
            OrderStatus status = _getOrderStatus(details.tick, details.lower, details.upper, direction);
            if (status != OrderStatus.OTM) revert LimitOrderRegistry__OrderITM(details.tick, targetTick, direction);
        }

        // Get the position id.
        details.positionId = getPositionFromTicks[pool][direction][details.lower][details.upper];

        if (direction) details.amount0 = amount;
        else details.amount1 = amount;
        if (details.positionId == 0) {
            // Create new LP position(which adds liquidity)
            PoolData memory data = poolToData[pool];
            details.positionId = _mintPosition(
                data,
                details.upper,
                details.lower,
                details.amount0,
                details.amount1,
                direction,
                deadline
            );

            // Add it to the list.
            _addPositionToList(data, startingNode, targetTick, details.positionId, direction);

            // Set new orders upper and lower tick.
            orderBook[details.positionId].tickLower = details.lower;
            orderBook[details.positionId].tickUpper = details.upper;

            // Setup BatchOrder, setting batchId, direction.
            _setupOrder(direction, details.positionId);

            // Update token0Amount, token1Amount, batchIdToUserDepositAmount mapping.
            details.userTotal = _updateOrder(details.positionId, sender, amount);

            // Update the center values if need be.
            _updateCenter(pool, details.positionId, details.tick, details.upper, details.lower);

            // Update getPositionFromTicks since we have a new LP position.
            getPositionFromTicks[pool][direction][details.lower][details.upper] = details.positionId;
        } else {
            // Check if the position id is already being used in List.
            BatchOrder memory order = orderBook[details.positionId];
            if (order.token0Amount > 0 || order.token1Amount > 0) {
                // Check that supplied direction and order.direction are the same.
                if (direction != order.direction) revert LimitOrderRegistry__DirectionMisMatch();
                // Need to add liquidity.
                PoolData memory data = poolToData[pool];
                _addToPosition(data, details.positionId, details.amount0, details.amount1, direction, deadline);

                // Update token0Amount, token1Amount, batchIdToUserDepositAmount mapping.
                details.userTotal = _updateOrder(details.positionId, sender, amount);
            } else {
                // We already have an LP position with given tick ranges, but it is not in linked list.
                PoolData memory data = poolToData[pool];

                // Add it to the list.
                _addPositionToList(data, startingNode, targetTick, details.positionId, direction);

                // Setup BatchOrder, setting batchId, direction.
                _setupOrder(direction, details.positionId);

                // Need to add liquidity.
                _addToPosition(data, details.positionId, details.amount0, details.amount1, direction, deadline);

                // Update token0Amount, token1Amount, batchIdToUserDepositAmount mapping.
                details.userTotal = _updateOrder(details.positionId, sender, amount);

                // Update the center values if need be.
                _updateCenter(pool, details.positionId, details.tick, details.upper, details.lower);
            }
        }
        emit NewOrder(sender, address(pool), amount, details.userTotal, orderBook[details.positionId]);
        return orderBook[details.positionId].batchId;
    }

    /**
     * @notice Users can claim fulfilled orders by passing in the `batchId` corresponding to the order they want to claim.
     * @param batchId the batchId corresponding to a fulfilled order to claim
     * @param user the address of the user in the order to claim for
     * @dev Caller must either approve this contract to spend their Wrapped Native token, and have at least `getFeePerUser` tokens in their wallet.
     *      Or caller must send `getFeePerUser` value with this call.
     */
    function claimOrder(uint128 batchId, address user) external payable returns (ERC20, uint256) {
        Claim storage userClaim = claim[batchId];
        if (!userClaim.isReadyForClaim) revert LimitOrderRegistry__OrderNotReadyToClaim(batchId);
        uint256 depositAmount = batchIdToUserDepositAmount[batchId][user];
        if (depositAmount == 0) revert LimitOrderRegistry__UserNotFound(user, batchId);

        // Zero out user balance.
        delete batchIdToUserDepositAmount[batchId][user];

        // Calculate owed amount.
        uint256 totalTokenDeposited;
        uint256 totalTokenOut;
        ERC20 tokenOut;
        if (userClaim.direction) {
            totalTokenDeposited = userClaim.token0Amount;
            totalTokenOut = userClaim.token1Amount;
            tokenOut = poolToData[userClaim.pool].token1;
        } else {
            totalTokenDeposited = userClaim.token1Amount;
            totalTokenOut = userClaim.token0Amount;
            tokenOut = poolToData[userClaim.pool].token0;
        }

        uint256 owed = (totalTokenOut * depositAmount) / totalTokenDeposited;

        // Transfer tokens owed to user.
        tokenOut.safeTransfer(user, owed);

        // Transfer fee in.
        address sender = _msgSender();
        if (msg.value >= userClaim.feePerUser) {
            // refund if necessary.
            uint256 refund = msg.value - userClaim.feePerUser;
            if (refund > 0) sender.safeTransferETH(refund);
        } else {
            WRAPPED_NATIVE.safeTransferFrom(sender, address(this), userClaim.feePerUser);
            // If value is non zero send it back to caller.
            if (msg.value > 0) sender.safeTransferETH(msg.value);
        }
        emit ClaimOrder(user, batchId, owed);
        return (tokenOut, owed);
    }

    /**
     * @notice Allows users to cancel orders as long as they are completely OTM.
     * @param pool the Uniswap V3 pool that contains the limit order to cancel
     * @param targetTick the targetTick of the order you want to cancel
     * @param direction bool indication the direction of the order
     */
    function cancelOrder(
        UniswapV3Pool pool,
        int24 targetTick,
        bool direction,
        uint256 deadline
    ) external returns (uint128 amount0, uint128 amount1, uint128 batchId) {
        uint256 positionId;
        {
            // Make sure order is OTM.
            (, int24 tick, , , , , ) = pool.slot0();

            // Determine upper and lower ticks.
            int24 upper;
            int24 lower;
            {
                int24 tickSpacing = pool.tickSpacing();
                // Make sure targetTick is divisible by spacing.
                if (targetTick % tickSpacing != 0)
                    revert LimitOrderRegistry__InvalidTargetTick(targetTick, tickSpacing);
                if (direction) {
                    upper = targetTick;
                    lower = targetTick - tickSpacing;
                } else {
                    upper = targetTick + tickSpacing;
                    lower = targetTick;
                }
            }
            // Validate lower, upper,and direction. Make sure order is not ITM or MIXED
            {
                OrderStatus status = _getOrderStatus(tick, lower, upper, direction);
                if (status != OrderStatus.OTM) revert LimitOrderRegistry__OrderITM(tick, targetTick, direction);
            }

            // Get the position id.
            positionId = getPositionFromTicks[pool][direction][lower][upper];

            if (positionId == 0) revert LimitOrderRegistry__InvalidPositionId();
        }

        uint256 liquidityPercentToTake;

        // Get the users deposit amount in the order.
        BatchOrder storage order = orderBook[positionId];
        if (order.batchId == 0) revert LimitOrderRegistry__InvalidBatchId();
        address sender = _msgSender();
        {
            batchId = order.batchId;
            uint128 depositAmount = batchIdToUserDepositAmount[batchId][sender];
            if (depositAmount == 0) revert LimitOrderRegistry__UserNotFound(sender, batchId);

            // Remove one from the userCount.
            order.userCount--;

            // Zero out user balance.
            delete batchIdToUserDepositAmount[batchId][sender];

            uint128 orderAmount;
            if (order.direction) {
                orderAmount = order.token0Amount;
                if (orderAmount == depositAmount) {
                    liquidityPercentToTake = 1e18;
                    // Update order tokenAmount.
                    order.token0Amount = 0;
                } else {
                    liquidityPercentToTake = (1e18 * uint256(depositAmount)) / orderAmount;
                    // Update order tokenAmount.
                    order.token0Amount = orderAmount - depositAmount;
                }
            } else {
                orderAmount = order.token1Amount;
                if (orderAmount == depositAmount) {
                    liquidityPercentToTake = 1e18;
                    // Update order tokenAmount.
                    order.token1Amount = 0;
                } else {
                    liquidityPercentToTake = (1e18 * uint256(depositAmount)) / orderAmount;
                    // Update order tokenAmount.
                    order.token1Amount = orderAmount - depositAmount;
                }
            }

            (amount0, amount1) = _takeFromPosition(positionId, pool, liquidityPercentToTake, deadline);
            emit CancelOrder(sender, amount0, amount1, order);
            if (liquidityPercentToTake == 1e18) {
                _removeOrderFromList(positionId, pool, order);
                // Zero out balances for cancelled order.
                order.token0Amount = 0;
                order.token1Amount = 0;
                order.batchId = 0;
            }
        }
        if (order.direction) {
            if (amount0 > 0) poolToData[pool].token0.safeTransfer(sender, amount0);
            else revert LimitOrderRegistry__NoLiquidityInOrder();
            if (amount1 > 0) revert LimitOrderRegistry__AmountShouldBeZero();
        } else {
            if (amount1 > 0) poolToData[pool].token1.safeTransfer(sender, amount1);
            else revert LimitOrderRegistry__NoLiquidityInOrder();
            if (amount0 > 0) revert LimitOrderRegistry__AmountShouldBeZero();
        }
    }

    /*//////////////////////////////////////////////////////////////
                     CHAINLINK AUTOMATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returned `performData` simply contains a bool indicating which direction in the `orderBook` has orders that need to be fulfilled.
     */
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        UniswapV3Pool pool = abi.decode(checkData, (UniswapV3Pool));
        (, int24 currentTick, , , , , ) = pool.slot0();
        PoolData memory data = poolToData[pool];
        BatchOrder memory order;
        OrderStatus status;
        bool walkDirection;
        uint256 deadline = block.timestamp + 900;

        if (data.centerHead != 0) {
            // centerHead is set, check if it is ITM.
            order = orderBook[data.centerHead];
            status = _getOrderStatus(currentTick, order.tickLower, order.tickUpper, order.direction);
            if (status == OrderStatus.ITM) {
                walkDirection = true; // Walk towards head of list.
                upkeepNeeded = true;
                performData = abi.encode(pool, walkDirection, deadline);
                return (upkeepNeeded, performData);
            }
        }
        if (data.centerTail != 0) {
            // If walk direction has not been set, then we know, no head orders are ITM.
            // So check tail orders.
            order = orderBook[data.centerTail];
            status = _getOrderStatus(currentTick, order.tickLower, order.tickUpper, order.direction);
            if (status == OrderStatus.ITM) {
                walkDirection = false; // Walk towards tail of list.
                upkeepNeeded = true;
                performData = abi.encode(pool, walkDirection, deadline);
                return (upkeepNeeded, performData);
            }
        }
        return (false, abi.encode(0));
    }

    /**
     * @notice Callable by anyone, as long as there are orders ITM, that need to be fulfilled.
     * @dev Does not use _removeOrderFromList, so that the center head/tail
     *      value is not updated every single time and order is fulfilled, instead we just update it once at the end.
     */
    function performUpkeep(bytes calldata performData) external {
        (UniswapV3Pool pool, bool walkDirection, uint256 deadline) = abi.decode(
            performData,
            (UniswapV3Pool, bool, uint256)
        );

        if (address(poolToData[pool].token0) == address(0)) revert LimitOrderRegistry__PoolNotSetup(address(pool));

        PoolData storage data = poolToData[pool];

        // Estimate gas cost.
        uint256 estimatedFee = uint256(upkeepGasLimit * getGasPrice());

        (, int24 currentTick, , , , , ) = pool.slot0();
        bool orderFilled;

        // Fulfill orders.
        uint256 target = walkDirection ? data.centerHead : data.centerTail;
        for (uint256 i; i < maxFillsPerUpkeep; ++i) {
            if (target == 0) break;
            BatchOrder storage order = orderBook[target];
            OrderStatus status = _getOrderStatus(currentTick, order.tickLower, order.tickUpper, order.direction);
            if (status == OrderStatus.ITM) {
                _fulfillOrder(target, pool, order, estimatedFee, deadline);
                target = walkDirection ? order.head : order.tail;
                // Reconnect List and Zero out orders head and tail values removing order from the list.
                orderBook[order.tail].head = order.head;
                orderBook[order.head].tail = order.tail;
                order.head = 0;
                order.tail = 0;
                // Update bool to indicate batch order is ready to handle claims.
                claim[order.batchId].isReadyForClaim = true;
                // Zero out orders batch id.
                order.batchId = 0;
                // Reset user count.
                order.userCount = 0;
                orderFilled = true;
            } else break;
        }

        if (!orderFilled) revert LimitOrderRegistry__NoOrdersToFulfill();

        // Update appropriate center value.
        if (walkDirection) {
            data.centerHead = target;
        } else {
            data.centerTail = target;
        }
    }

    /*//////////////////////////////////////////////////////////////
                     INTERNAL ORDER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a given Uniswap V3 position is already in the `orderBook`.
     * @dev Looks at Nodes head and tail, and checks for edge case of node being the only node in the `orderBook`
     */
    function _checkThatNodeIsInList(uint256 node, BatchOrder memory order, PoolData memory data) internal pure {
        if (order.head == 0 && order.tail == 0) {
            // Possible but the order may be centerTail or centerHead.
            if (data.centerHead != node && data.centerTail != node) revert LimitOrderRegistry__OrderNotInList(node);
        }
    }

    /**
     * @notice Finds appropriate spot in `orderBook` for an order.
     */
    function _findSpot(
        PoolData memory data,
        uint256 startingNode,
        int24 targetTick,
        bool direction
    ) internal view returns (uint256 proposedHead, uint256 proposedTail) {
        BatchOrder memory node;
        if (startingNode == 0) {
            if (direction && data.centerHead != 0) {
                startingNode = data.centerHead;
                node = orderBook[startingNode];
            } else if (!direction && data.centerTail != 0) {
                startingNode = data.centerTail;
                node = orderBook[startingNode];
            } else return (0, 0);
        } else {
            node = orderBook[startingNode];
            if (node.direction != direction) revert LimitOrderRegistry__OrderNotInList(startingNode);
            _checkThatNodeIsInList(startingNode, node, data);
        }
        uint256 nodeId = startingNode;

        while (true) {
            if (direction) {
                // Go until we find an order with a tick lower GREATER or equal to targetTick, then set proposedTail equal to the tail, and proposed head to the current node.
                if (node.tickLower >= targetTick) {
                    return (nodeId, node.tail);
                } else if (node.head == 0) {
                    // Made it to head of list.
                    return (0, nodeId);
                } else {
                    nodeId = node.head;
                    node = orderBook[nodeId];
                }
            } else {
                // Go until we find tick upper that is LESS than or equal to targetTick
                if (node.tickUpper <= targetTick) {
                    return (node.head, nodeId);
                } else if (node.tail == 0) {
                    // Made it to the tail of the list.
                    return (nodeId, 0);
                } else {
                    nodeId = node.tail;
                    node = orderBook[nodeId];
                }
            }
        }
    }

    /**
     * @notice Checks if newly added order should be made the new center head/tail.
     */
    function _updateCenter(
        UniswapV3Pool pool,
        uint256 positionId,
        int24 currentTick,
        int24 upper,
        int24 lower
    ) internal {
        PoolData memory data = poolToData[pool];
        if (currentTick > upper) {
            // Check if centerTail needs to be updated.
            if (data.centerTail == 0) {
                // Currently no centerTail, so this order must become it.
                poolToData[pool].centerTail = positionId;
            } else {
                BatchOrder memory centerTail = orderBook[data.centerTail];
                if (upper > centerTail.tickUpper) {
                    // New position is closer to the current pool tick, so it becomes new centerTail.
                    poolToData[pool].centerTail = positionId;
                }
                // else nothing to do.
            }
        } else if (currentTick < lower) {
            // Check if centerHead needs to be updated.
            if (data.centerHead == 0) {
                // Currently no centerHead, so this order must become it.
                poolToData[pool].centerHead = positionId;
            } else {
                BatchOrder memory centerHead = orderBook[data.centerHead];
                if (lower < centerHead.tickLower) {
                    // New position is closer to the current pool tick, so it becomes new centerHead.
                    poolToData[pool].centerHead = positionId;
                }
                // else nothing to do.
            }
        }
    }

    /**
     * @notice Add a Uniswap V3 LP position to the `orderBook`.
     */
    function _addPositionToList(
        PoolData memory data,
        uint256 startingNode,
        int24 targetTick,
        uint256 position,
        bool direction
    ) internal {
        (uint256 head, uint256 tail) = _findSpot(data, startingNode, targetTick, direction);
        if (tail != 0) {
            orderBook[tail].head = position;
            orderBook[position].tail = tail;
        }
        if (head != 0) {
            orderBook[head].tail = position;
            orderBook[position].head = head;
        }
    }

    /**
     * @notice Setup a newly minted LP position, or one being reused.
     * @dev Sets batchId, and direction.
     */
    function _setupOrder(bool direction, uint256 position) internal {
        BatchOrder storage order = orderBook[position];
        order.batchId = batchCount++;
        order.direction = direction;
    }

    /**
     * @notice Updates a BatchOrder's token0/token1 amount, as well as associated
     *         `batchIdToUserDepositAmount` mapping value.
     * @dev If user is new to the order, increment userCount.
     */
    function _updateOrder(uint256 positionId, address user, uint128 amount) internal returns (uint128 userTotal) {
        BatchOrder storage order = orderBook[positionId];
        if (order.direction) {
            // token1
            order.token0Amount += amount;
        } else {
            // token0
            order.token1Amount += amount;
        }

        // Check if user is already in the order.
        uint128 batchId = order.batchId;
        uint128 originalDepositAmount = batchIdToUserDepositAmount[batchId][user];
        // If this is a new user in the order, add 1 to userCount.
        if (originalDepositAmount == 0) order.userCount++;
        batchIdToUserDepositAmount[batchId][user] = originalDepositAmount + amount;
        return (originalDepositAmount + amount);
    }

    /**
     * @notice Mints a new Uniswap V3 LP position.
     */
    function _mintPosition(
        PoolData memory data,
        int24 upper,
        int24 lower,
        uint128 amount0,
        uint128 amount1,
        bool direction,
        uint256 deadline
    ) internal returns (uint256) {
        if (direction) data.token0.safeApprove(address(POSITION_MANAGER), amount0);
        else data.token1.safeApprove(address(POSITION_MANAGER), amount1);

        // 0.9999e4 accounts for rounding errors in the Uniswap V3 protocol.
        uint128 amount0Min = amount0 == 0 ? 0 : (amount0 * 0.9999e4) / 1e4;
        uint128 amount1Min = amount1 == 0 ? 0 : (amount1 * 0.9999e4) / 1e4;

        // Create mint params.
        NonFungiblePositionManager.MintParams memory params = NonFungiblePositionManager.MintParams({
            token0: address(data.token0),
            token1: address(data.token1),
            fee: data.fee,
            tickLower: lower,
            tickUpper: upper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: address(this),
            deadline: deadline
        });

        // Supply liquidity to pool.
        (uint256 tokenId, , , ) = POSITION_MANAGER.mint(params);

        // Revert if tokenId received is 0 id.
        // Zero token id is reserved for NULL values in linked list.
        if (tokenId == 0) revert LimitOrderRegistry__InvalidPositionId();

        // If position manager still has allowance, zero it out.
        if (direction && data.token0.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token0.safeApprove(address(POSITION_MANAGER), 0);
        if (!direction && data.token1.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token1.safeApprove(address(POSITION_MANAGER), 0);

        return tokenId;
    }

    /**
     * @notice Adds liquidity to a given `positionId`.
     */
    function _addToPosition(
        PoolData memory data,
        uint256 positionId,
        uint128 amount0,
        uint128 amount1,
        bool direction,
        uint256 deadline
    ) internal {
        if (direction) data.token0.safeApprove(address(POSITION_MANAGER), amount0);
        else data.token1.safeApprove(address(POSITION_MANAGER), amount1);

        uint128 amount0Min = amount0 == 0 ? 0 : (amount0 * 0.9999e4) / 1e4;
        uint128 amount1Min = amount1 == 0 ? 0 : (amount1 * 0.9999e4) / 1e4;

        // Create increase liquidity params.
        NonFungiblePositionManager.IncreaseLiquidityParams memory params = NonFungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: positionId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: deadline
            });

        // Increase liquidity in pool.
        POSITION_MANAGER.increaseLiquidity(params);

        // If position manager still has allowance, zero it out.
        if (direction && data.token0.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token0.safeApprove(address(POSITION_MANAGER), 0);
        if (!direction && data.token1.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token1.safeApprove(address(POSITION_MANAGER), 0);
    }

    /**
     * @notice Enforces minimum liquidity requirements for orders.
     */
    function _enforceMinimumLiquidity(uint256 amount, ERC20 asset) internal view {
        uint256 minimum = minimumAssets[asset];
        if (minimum == 0) revert LimitOrderRegistry__MinimumNotSet(address(asset));
        if (amount < minimum) revert LimitOrderRegistry__MinimumNotMet(address(asset), minimum, amount);
    }

    /**
     * @notice Helper function to determine an orders status.
     * @dev Returns
     *      - ITM if order is ready to be filled, and is composed of wanted asset
     *      - OTM if order is not ready to be filled, but order can still be cancelled, because order is composed of asset to sell
     *      - MIXED order is composed of both wanted asset, and asset to sell, can not be fulfilled or cancelled.
     */
    function _getOrderStatus(
        int24 currentTick,
        int24 lower,
        int24 upper,
        bool direction
    ) internal pure returns (OrderStatus status) {
        if (upper == lower) revert LimitOrderRegistry__InvalidTickRange(upper, lower);
        if (direction) {
            // Indicates we want to go lower -> upper.
            if (currentTick > upper) return OrderStatus.ITM;
            if (currentTick >= lower) return OrderStatus.MIXED;
            else return OrderStatus.OTM;
        } else {
            // Indicates we want to go upper -> lower.
            if (currentTick < lower) return OrderStatus.ITM;
            if (currentTick <= upper) return OrderStatus.MIXED;
            else return OrderStatus.OTM;
        }
    }

    /**
     * @notice Called during `performUpkeep` to fulfill an ITM order.
     * @dev Sets Claim info, removes all liquidity from position, and zeroes out BatchOrder amount0 and amount1 values.
     */
    function _fulfillOrder(
        uint256 target,
        UniswapV3Pool pool,
        BatchOrder storage order,
        uint256 estimatedFee,
        uint256 deadline
    ) internal {
        // Save fee per user in Claim Struct.
        uint256 totalUsers = order.userCount;
        Claim storage newClaim = claim[order.batchId];
        newClaim.feePerUser = uint128(estimatedFee / totalUsers);
        newClaim.pool = pool;

        // Take all liquidity from the order.
        uint128 amount0;
        uint128 amount1;
        (amount0, amount1) = _takeFromPosition(target, pool, 1e18, deadline);
        if (order.direction) {
            // Copy the tokenIn amount from the order, this is the total user deposit.
            newClaim.token0Amount = order.token0Amount;
            // Total token out is amount1.
            newClaim.token1Amount = amount1;
        } else {
            // Copy the tokenIn amount from the order, this is the total user deposit.
            newClaim.token1Amount = order.token1Amount;
            // Total token out is amount0.
            newClaim.token0Amount = amount0;
        }
        newClaim.direction = order.direction;

        // Zero out order balances.
        order.token0Amount = 0;
        order.token1Amount = 0;

        emit OrderFilled(order.batchId, address(pool));
    }

    /**
     * @notice Removes liquidity from `target` Uniswap V3 LP position.
     * @dev Collects fees from `target` position, and saves them in `tokenToSwapFees`.
     */
    function _takeFromPosition(
        uint256 target,
        UniswapV3Pool pool,
        uint256 liquidityPercent,
        uint256 deadline
    ) internal returns (uint128, uint128) {
        (, , , , , , , uint128 liquidity, , , , ) = POSITION_MANAGER.positions(target);
        liquidity = uint128(uint256(liquidity * liquidityPercent) / 1e18);

        // Create decrease liquidity params.
        NonFungiblePositionManager.DecreaseLiquidityParams memory params = NonFungiblePositionManager
            .DecreaseLiquidityParams({
                tokenId: target,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: deadline
            });

        // Decrease liquidity in pool.
        uint128 amount0;
        uint128 amount1;
        {
            (uint256 a0, uint256 a1) = POSITION_MANAGER.decreaseLiquidity(params);
            amount0 = uint128(a0);
            amount1 = uint128(a1);
        }

        // If completely closing position, then collect fees as well.
        NonFungiblePositionManager.CollectParams memory collectParams;
        {
            uint128 amount0Max;
            uint128 amount1Max;
            if (liquidityPercent == 1e18) {
                amount0Max = type(uint128).max;
                amount1Max = type(uint128).max;
            } else {
                // Otherwise only collect principal.
                amount0Max = amount0;
                amount1Max = amount1;
            }
            // Create fee collection params.
            collectParams = NonFungiblePositionManager.CollectParams({
                tokenId: target,
                recipient: address(this),
                amount0Max: amount0Max,
                amount1Max: amount1Max
            });
        }

        // Save token balances.
        ERC20 token0 = poolToData[pool].token0;
        ERC20 token1 = poolToData[pool].token1;
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));

        // Collect fees.
        POSITION_MANAGER.collect(collectParams);

        // Save fees earned, take the total token amount out - the amount removed from liquidity to get the fees earned.
        uint128 token0Fees = uint128(token0.balanceOf(address(this)) - token0Balance) - amount0;
        uint128 token1Fees = uint128(token1.balanceOf(address(this)) - token1Balance) - amount1;
        // Save any swap fees.
        if (token0Fees > 0) tokenToSwapFees[address(token0)] += token0Fees;
        if (token1Fees > 0) tokenToSwapFees[address(token1)] += token1Fees;

        return (amount0, amount1);
    }

    /**
     * @notice Removes an order from the `orderBook`.
     * @dev Checks if order is one of the center values, and updates the head if need be.
     */
    function _removeOrderFromList(uint256 target, UniswapV3Pool pool, BatchOrder storage order) internal {
        // Checks if order is the center, if so then it will set it to the the center orders head(which is okay if it is zero).
        uint256 centerHead = poolToData[pool].centerHead;
        uint256 centerTail = poolToData[pool].centerTail;

        if (target == centerHead) {
            uint256 newHead = orderBook[centerHead].head;
            poolToData[pool].centerHead = newHead;
        } else if (target == centerTail) {
            uint256 newTail = orderBook[centerTail].tail;
            poolToData[pool].centerTail = newTail;
        }

        // Remove order from linked list.
        orderBook[order.tail].head = order.head;
        orderBook[order.head].tail = order.tail;
        order.head = 0;
        order.tail = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Helper function to get the gas price used for fee calculation.
     */
    function getGasPrice() public view returns (uint256) {
        // If gas feed is set use it.
        if (fastGasFeed != address(0)) {
            (, int256 _answer, , uint256 _timestamp, ) = IChainlinkAggregator(fastGasFeed).latestRoundData();
            uint256 timeSinceLastUpdate = block.timestamp - _timestamp;
            // Check answer is not stale.
            if (timeSinceLastUpdate > FAST_GAS_HEARTBEAT) {
                // If answer is stale use owner set value.
                // Multiply by 1e9 to convert gas price to gwei
                return uint256(upkeepGasPrice) * 1e9;
            } else {
                // Else use the datafeed value.
                uint256 answer = uint256(_answer);
                return answer;
            }
        }
        // Else use owner set value.
        return uint256(upkeepGasPrice) * 1e9; // Multiply by 1e9 to convert gas price to gwei
    }

    /**
     * @notice Helper function that finds the appropriate spot in the linked list for a new order.
     * @param pool the Uniswap V3 pool you want to create an order in
     * @param startingNode the UniV3 position Id to start looking
     * @param targetTick the targetTick of the order you want to place
     * @param direction the direction of the order
     * @return proposedHead , proposedTail pr the correct head and tail for the new order
     * @dev if both head and tail are zero, just pass in zero for the `startingNode`
     *      otherwise pass in either the nonzero head or nonzero tail for the `startingNode`
     */
    function findSpot(
        UniswapV3Pool pool,
        uint256 startingNode,
        int24 targetTick,
        bool direction
    ) external view returns (uint256 proposedHead, uint256 proposedTail) {
        PoolData memory data = poolToData[pool];

        int24 tickSpacing = pool.tickSpacing();
        // Make sure targetTick is divisible by spacing.
        if (targetTick % tickSpacing != 0) revert LimitOrderRegistry__InvalidTargetTick(targetTick, tickSpacing);

        (proposedHead, proposedTail) = _findSpot(data, startingNode, targetTick, direction);
    }

    /**
     * @notice Helper function to get the fee per user for a specific order.
     */
    function getFeePerUser(uint128 batchId) external view returns (uint128) {
        return claim[batchId].feePerUser;
    }

    /**
     * @notice Helper function to view if a BatchOrder is ready to claim.
     */
    function isOrderReadyForClaim(uint128 batchId) external view returns (bool) {
        return claim[batchId].isReadyForClaim;
    }

    function getOrderBook(uint256 id) external view returns (BatchOrder memory) {
        return orderBook[id];
    }

    function getClaim(uint128 batchId) external view returns (Claim memory) {
        return claim[batchId];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface UniswapV3Pool {
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );
    event Initialize(uint160 sqrtPriceX96, int24 tick);
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function factory() external view returns (address);

    function fee() external view returns (uint24);

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function flash(address recipient, uint256 amount0, uint256 amount1, bytes memory data) external;

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    function initialize(uint160 sqrtPriceX96) external;

    function liquidity() external view returns (uint128);

    function maxLiquidityPerTick() external view returns (uint128);

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes memory data
    ) external returns (uint256 amount0, uint256 amount1);

    function observations(
        uint256
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    function observe(
        uint32[] memory secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    function positions(
        bytes32
    )
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function protocolFees() external view returns (uint128 token0, uint128 token1);

    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    ) external view returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    function tickBitmap(int16) external view returns (uint256);

    function tickSpacing() external view returns (int24);

    function ticks(
        int24
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface NonFungiblePositionManager {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function WETH9() external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external pure returns (string memory);

    function burn(uint256 tokenId) external payable;

    function collect(CollectParams memory params) external payable returns (uint256 amount0, uint256 amount1);

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    function decreaseLiquidity(
        DecreaseLiquidityParams memory params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function factory() external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mint(
        MintParams memory params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

    function name() external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function refundETH() external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes memory data) external;

    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
interface IKeeperRegistrar {
    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name string of the upkeep to be registered
     * @param encryptedEmail email address of upkeep contact
     * @param upkeepContract address to perform upkeep on
     * @param gasLimit amount of gas to provide the target contract when performing upkeep
     * @param adminAddress address to cancel upkeep and withdraw remaining funds
     * @param checkData data passed to the contract when checking for upkeep
     * @param amount quantity of LINK upkeep is funded with (specified in Juels)
     * @param source application sending this request
     * @param sender address of the sender making the request
     */
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;

    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);

    function typeAndVersion() external view returns (string memory);
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
pragma solidity 0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IChainlinkAggregator is AggregatorV2V3Interface {
    function maxAnswer() external view returns (int192);

    function minAnswer() external view returns (int192);

    function aggregator() external view returns (address);
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