// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

abstract contract CoverPoolManagerEvents {
    event FactoryChanged(address indexed previousFactory, address indexed newFactory);
    event SpreadTierEnabled(uint16 feeTier, int16 tickSpread, uint16 twapLength, uint16 auctionLength);
    event FeeToTransfer(address indexed previousFeeTo, address indexed newFeeTo);
    event OwnerTransfer(address indexed previousOwner, address indexed newOwner);
    event ProtocolFeeUpdated(uint16 oldProtocolFee, uint16 newProtocolFee);
    event ProtocolFeeCollected(address indexed pool, uint128 token0Fees, uint128 token1Fees);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract CoverPoolFactoryStorage {
    address public owner;
    address public rangePoolFactory;
    mapping(bytes32 => address) public coverPools;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICoverPoolStructs.sol';

//TODO: combine everything into one interface
interface ICoverPool is ICoverPoolStructs {
    function mint(
        MintParams memory mintParams
    ) external;

    function burn(
        BurnParams calldata burnParams
    ) external;

    function swap(
        address recipient,
        bool zeroForOne,
        uint128 amountIn,
        uint160 priceLimit
    )
    external
    returns (
        // bytes calldata data
        uint256 amountOut
    );

    function collectFees() external returns (
        uint128 token0Fees,
        uint128 token1Fees
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import '../base/storage/CoverPoolFactoryStorage.sol';

abstract contract ICoverPoolFactory is CoverPoolFactoryStorage {

    function createCoverPool(
        address fromToken,
        address destToken,
        uint16 fee,
        int16  tickSpread,
        uint16 twapLength
    ) external virtual returns (address book);

    function getCoverPool(
        address fromToken,
        address destToken,
        uint16 fee,
        int16 tickSpread,
        uint16 twapLength
    ) external view virtual returns (address);

    function collectProtocolFees(
        address collectPool
    ) external virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @notice Range Pool Interface
interface ICoverPoolManager {
    function owner() external view returns (address);
    function feeTo() external view returns (address);
    function protocolFee() external view returns (uint16);
    function spreadTiers(
        uint16 feeTier,
        int16  tickSpread,
        uint16 twapLength
    ) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./IRangePool.sol";

interface ICoverPoolStructs {
    struct GlobalState {
        uint8    unlocked;
        int16    tickSpread; /// @dev this is a integer multiple of the inputPool tickSpacing
        uint16   twapLength; /// @dev number of blocks used for TWAP sampling
        uint16   auctionLength; /// @dev number of blocks to improve price by tickSpread
        int24    latestTick; /// @dev latest updated inputPool price tick
        uint32   genesisBlock; /// @dev reference block for which auctionStart is an offset of
        uint32   lastBlock;    /// @dev last block checked
        uint32   auctionStart; /// @dev last block price reference was updated
        uint32   accumEpoch;
        uint128  liquidityGlobal;
        uint160  latestPrice; /// @dev price of latestTick
        IRangePool inputPool;
        ProtocolFees protocolFees;
    }

    //TODO: adjust nearestTick if someone burns all liquidity from current nearestTick
    struct PoolState {
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 amountInDelta; /// @dev Delta for the current tick auction
        uint128 amountInDeltaMaxClaimed;  /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint128 amountOutDeltaMaxClaimed; /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint160 price; /// @dev Starting price current
    }

    struct TickNode {
        int24   previousTick;
        int24   nextTick;
        uint32  accumEpochLast; // Used to check for claim updates
    }

    struct Tick {
        int128  liquidityDelta;
        uint128 liquidityDeltaMinus;
        uint128 amountInDeltaMaxStashed;
        uint128 amountOutDeltaMaxStashed;
        Deltas deltas;
    }

    struct Deltas {
        uint128 amountInDelta;     // amt unfilled
        uint128 amountInDeltaMax;  // max unfilled
        uint128 amountOutDelta;    // amt unfilled
        uint128 amountOutDeltaMax; // max unfilled
    }

    // balance needs to be immediately transferred to the position owner
    struct Position {
        uint8   claimCheckpoint; // used to dictate claim state
        uint32  accumEpochLast; // last epoch this position was updated at
        uint128 liquidity; // expected amount to be used not actual
        uint128 liquidityStashed; // what percent of this position is stashed liquidity
        uint128 amountIn; // token amount already claimed; balance
        uint128 amountOut; // necessary for non-custodial positions
        uint160 claimPriceLast; // highest price claimed at
    }

    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }

    struct MintParams {
        address to;
        int24 lowerOld;
        int24 lower;
        int24 claim;
        int24 upper;
        int24 upperOld;
        uint128 amount;
        bool zeroForOne;
    }

    struct BurnParams {
        address to;
        int24 lower;
        int24 claim;
        int24 upper;
        bool zeroForOne;
        uint128 amount;
        bool collect;
    }

    //TODO: should we have a recipient field here?
    struct AddParams {
        address owner;
        int24 lowerOld;
        int24 lower;
        int24 upper;
        int24 upperOld;
        bool zeroForOne;
        uint128 amount;
    }

    struct RemoveParams {
        address owner;
        int24 lower;
        int24 upper;
        bool zeroForOne;
        uint128 amount;
    }

    struct UpdateParams {
        address owner;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
        uint128 amount;
    }

    struct ValidateParams {
        int24 lowerOld;
        int24 lower;
        int24 upper;
        int24 upperOld;
        bool zeroForOne;
        uint128 amount;
        GlobalState state;
    }

    //TODO: optimize this struct
    struct SwapCache {
        uint256 price;
        uint256 liquidity;
        uint256 amountIn;
        uint256 input;
        uint256 inputBoosted;
        uint256 auctionDepth;
        uint256 auctionBoost;
        uint256 amountInDelta;
    }

    struct PositionCache {
        uint160 priceLower;
        uint160 priceUpper;
        Position position;
    }

    struct UpdatePositionCache {
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint160 priceSpread;
        bool removeLower;
        bool removeUpper;
        uint256 amountInFilledMax;    // considers the range covered by each update
        uint256 amountOutUnfilledMax; // considers the range covered by each update
        Tick claimTick;
        TickNode claimTickNode;
        Position position;
        Deltas deltas;
        Deltas finalDeltas;
    }

    struct AccumulateCache {
        int24 nextTickToCross0;
        int24 nextTickToCross1;
        int24 nextTickToAccum0;
        int24 nextTickToAccum1;
        int24 stopTick0;
        int24 stopTick1;
        Deltas deltas0;
        Deltas deltas1;
    }

    struct AccumulateOutputs {
        Deltas deltas;
        TickNode accumTickNode;
        TickNode crossTickNode;
        Tick crossTick;
        Tick accumTick;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface IRangePool {
    /// @notice This is to be used at hedge pool initialization in case the cardinality is too low for the hedge pool.
    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function tickSpacing() external view returns (int24);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
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

    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../interfaces/ICoverPool.sol';
import '../interfaces/ICoverPoolFactory.sol';
import '../interfaces/ICoverPoolManager.sol';
import '../base/events/CoverPoolManagerEvents.sol';

/**
 * @dev Defines the actions which can be executed by the factory admin.
 */
contract CoverPoolManager is ICoverPoolManager, CoverPoolManagerEvents {
    address public _owner;
    address private _feeTo;
    address public _factory;

    /// @dev - feeTier => tickSpread => twapLength => auctionLength
    mapping(uint16 => mapping(int16 => mapping(uint16 => uint16))) public spreadTiers;
    uint16 public protocolFee;

    error OwnerOnly();
    error FeeToOnly();
    error SpreadTierAlreadyEnabled();
    error TransferredToZeroAddress();
    
    constructor() {
        _owner = msg.sender;
        _feeTo = msg.sender;
        emit OwnerTransfer(address(0), msg.sender);

        spreadTiers[500][20][5] = 20;
        emit SpreadTierEnabled(500, 20, 5, 20);

        spreadTiers[500][40][40] = 40;
        emit SpreadTierEnabled(500, 40, 40, 40);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyFeeTo() {
        _checkFeeTo();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function feeTo() public view virtual returns (address) {
        return _feeTo;
    }

    function factory() public view virtual returns (address) {
        return _factory;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) revert OwnerOnly();
    }

    /**
     * @dev Throws if the sender is not the feeTo.
     */
    function _checkFeeTo() internal view virtual {
        if (feeTo() != msg.sender) revert FeeToOnly();
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwner(address newOwner) public virtual onlyOwner {
        if(newOwner == address(0)) revert TransferredToZeroAddress();
        _transferOwner(newOwner);
    }

    function transferFeeTo(address newFeeTo) public virtual onlyFeeTo {
        if(newFeeTo == address(0)) revert TransferredToZeroAddress();
        _transferFeeTo(newFeeTo);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwner(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnerTransfer(oldOwner, newOwner);
    }

    /**
     * @dev Transfers fee collection to a new account (`newFeeTo`).
     * Internal function without access restriction.
     */
    function _transferFeeTo(address newFeeTo) internal virtual {
        address oldFeeTo = _feeTo;
        _feeTo = newFeeTo;
        emit OwnerTransfer(oldFeeTo, newFeeTo);
    }

    function enableSpreadTier(
        uint16 feeTier,
        int16 tickSpread,
        uint16 twapLength,
        uint16 auctionLength
    ) external onlyOwner {
        if (spreadTiers[feeTier][tickSpread][twapLength] != 0) {
            revert SpreadTierAlreadyEnabled();
        }
        spreadTiers[feeTier][tickSpread][twapLength] = auctionLength;
        emit SpreadTierEnabled(feeTier, tickSpread, twapLength, auctionLength);
    }

    function setFactory(
        address factory_
    ) external onlyOwner {
        emit FactoryChanged(_factory, factory_);
        _factory = factory_;
    }

    function setProtocolFee(
        uint16 protocolFee_
    ) external onlyOwner {
        emit ProtocolFeeUpdated(protocolFee, protocolFee_);
        protocolFee = protocolFee_;
    }

    function collectProtocolFees(
        address[] calldata collectPools
    ) external {
        for (uint i; i < collectPools.length; i++) {
            ICoverPoolFactory(factory()).collectProtocolFees(collectPools[i]);
        }
    }
}