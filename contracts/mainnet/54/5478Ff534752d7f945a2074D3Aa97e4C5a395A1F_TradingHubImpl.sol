// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./Rescuable.sol";
import "../libraries/Path.sol";
import "../interfaces/v1/IPoolGuardian.sol";
import "../interfaces/v1/ITradingHub.sol";
import "../interfaces/IStrPool.sol";
import "../interfaces/IDexCenter.sol";
import "../criteria/ChainSchema.sol";
import "../storage/AresStorage.sol";
import "../util/BoringMath.sol";

/// @notice Hub for dealing with orders, positions and traders
contract TradingHubImpl is Rescuable, ChainSchema, Pausable, AresStorage, ITradingHub {
    using BoringMath for uint256;
    using Path for bytes;

    constructor(address _SAVIOR) public Rescuable(_SAVIOR) {}

    modifier onlySwapRouter(address _swapRouter) {
        require(dexCenter.getSwapRouterWhiteList(_swapRouter), "TradingHub: Invalid SwapRouter");
        _;
    }

    modifier onlyGrabber() {
        require(msg.sender == shorterBone.getAddress(AllyLibrary.GRAB_REWARD), "TradingHub: Caller is not Grabber");
        _;
    }

    function sellShort(
        uint256 poolId,
        uint256 amount,
        uint256 amountOutMin,
        address swapRouter,
        bytes memory path
    ) external whenNotPaused onlyEOA onlySwapRouter(swapRouter) {
        PoolInfo memory pool = getPoolInfo(poolId);
        require(path.getTokenIn() == address(pool.stakedToken), "TradingHub: Invalid tokenIn");
        require(path.getTokenOut() == address(pool.stableToken), "TradingHub: Invalid tokenOut");
        require(pool.stateFlag == IPoolGuardian.PoolStatus.RUNNING && pool.endBlock > block.number, "TradingHub: Expired pool");
        uint256 estimatePrice = priceOracle.getTokenPrice(address(pool.stakedToken));
        require(estimatePrice.mul(amount).mul(9) < amountOutMin.mul(10**(uint256(19).add(pool.stakedTokenDecimals).sub(pool.stableTokenDecimals))), "TradingHub: Slippage too large");
        address position = _duplicatedOpenPosition(poolId, msg.sender);
        if (position == address(0)) {
            position = address(uint160(uint256(keccak256(abi.encode(poolId, msg.sender, block.number)))));
            userPositions[msg.sender][userPositionSize[msg.sender]++] = PositionCube({addr: position, poolId: poolId.to64()});
            poolPositions[poolId][poolPositionSize[poolId]++] = position;
            allPositions[allPositionSize++] = position;
            positionInfoMap[position] = PositionInfo({poolId: poolId.to64(), strToken: pool.strToken, positionState: PositionState.OPEN});
            positionBlocks[position].openBlock = block.number;
            emit PositionOpened(poolId, msg.sender, position, amount);
        } else {
            emit PositionIncreased(poolId, msg.sender, position, amount);
        }
        IStrPool(pool.strToken).borrow(dexCenter.isSwapRouterV3(swapRouter), address(dexCenter), swapRouter, position, msg.sender, amount, amountOutMin, path);
    }

    function buyCover(
        uint256 poolId,
        uint256 amount,
        uint256 amountInMax,
        address swapRouter,
        bytes memory path
    ) external whenNotPaused onlyEOA {
        PoolInfo memory pool = getPoolInfo(poolId);
        bool isSwapRouterV3 = dexCenter.isSwapRouterV3(swapRouter);
        if (isSwapRouterV3) {
            require(path.getTokenIn() == address(pool.stakedToken), "TradingHub: Invalid tokenIn");
            require(path.getTokenOut() == address(pool.stableToken), "TradingHub: Invalid tokenOut");
        } else {
            require(path.getTokenIn() == address(pool.stableToken), "TradingHub: Invalid tokenIn");
            require(path.getTokenOut() == address(pool.stakedToken), "TradingHub: Invalid tokenOut");
        }

        address position = _duplicatedOpenPosition(poolId, msg.sender);
        require(position != address(0), "TradingHub: Position not found");

        bool isClosed = IStrPool(pool.strToken).repay(isSwapRouterV3, shorterBone.TetherToken() == address(pool.stableToken), address(dexCenter), swapRouter, position, msg.sender, amount, amountInMax, path);

        if (isClosed) {
            _updatePositionState(position, PositionState.CLOSED);
        }

        emit PositionDecreased(poolId, msg.sender, position, amount);
    }

    function getPositionInfo(address position)
        external
        view
        override
        returns (
            uint256 poolId,
            address strToken,
            uint256 closingBlock,
            PositionState positionState
        )
    {
        PositionInfo storage positionInfo = positionInfoMap[position];
        return (uint256(positionInfo.poolId), positionInfo.strToken, uint256(positionBlocks[position].closingBlock), positionInfo.positionState);
    }

    function getPositions(address account) external view returns (address[] memory positions) {
        positions = new address[](userPositionSize[account]);
        for (uint256 i = 0; i < userPositionSize[account]; i++) {
            positions[i] = userPositions[account][i].addr;
        }
    }

    function initialize(address _shorterBone, address _poolGuardian) external isKeeper {
        require(!_initialized, "TradingHub: Already initialized");
        shorterBone = IShorterBone(_shorterBone);
        poolGuardian = IPoolGuardian(_poolGuardian);
        _initialized = true;
    }

    function getPoolInfo(uint256 poolId) internal view returns (PoolInfo memory poolInfo) {
        (, address strToken, ) = poolGuardian.getPoolInfo(poolId);
        (address creator, address stakedToken, address stableToken, , uint256 leverage, uint256 durationDays, uint256 startBlock, uint256 endBlock, uint256 id, uint256 stakedTokenDecimals, uint256 stableTokenDecimals, IPoolGuardian.PoolStatus stateFlag) = IStrPool(strToken).getInfo();
        poolInfo = PoolInfo({
            creator: creator,
            stakedToken: ISRC20(stakedToken),
            stableToken: ISRC20(stableToken),
            strToken: strToken,
            leverage: leverage,
            durationDays: durationDays,
            startBlock: startBlock,
            endBlock: endBlock,
            id: id,
            stakedTokenDecimals: stakedTokenDecimals,
            stableTokenDecimals: stableTokenDecimals,
            stateFlag: stateFlag
        });
    }

    function executePositions(address[] memory positions) external override onlyGrabber {
        for (uint256 i = 0; i < positions.length; i++) {
            PositionInfo storage positionInfo = positionInfoMap[positions[i]];
            require(positionInfo.positionState == PositionState.OPEN, "TradingHub: Not a open position");

            PositionState positionState = IStrPool(positionInfo.strToken).updatePositionToAuctionHall(positions[i]);
            if (positionState == PositionState.CLOSING || positionState == PositionState.OVERDRAWN) {
                _updatePositionState(positions[i], positionState);
            }
        }
    }

    function isPoolWithdrawable(uint256 poolId) external view override returns (bool) {
        uint256 poolPosSize = poolPositionSize[poolId];
        for (uint256 i = 0; i < poolPosSize; i++) {
            if (positionInfoMap[poolPositions[poolId][i]].positionState == PositionState.OVERDRAWN) {
                return false;
            }
        }

        return true;
    }

    function setBatchClosePositions(ITradingHub.BatchPositionInfo[] memory batchPositionInfos) external override onlyGrabber {
        for (uint256 i = 0; i < batchPositionInfos.length; i++) {
            (, address strToken, IPoolGuardian.PoolStatus poolStatus) = poolGuardian.getPoolInfo(batchPositionInfos[i].poolId);
            require(poolStatus == IPoolGuardian.PoolStatus.RUNNING, "TradingHub: Pool is not running");
            (, , , , , , , uint256 endBlock, , , , ) = IStrPool(strToken).getInfo();
            require(block.number > endBlock, "TradingHub: Pool is not Liquidating");
            for (uint256 j = 0; j < batchPositionInfos[i].positions.length; j++) {
                PositionInfo storage positionInfo = positionInfoMap[batchPositionInfos[i].positions[j]];
                require(positionInfo.positionState == PositionState.OPEN, "TradingHub: Position is not open");
                _updatePositionState(batchPositionInfos[i].positions[j], PositionState.CLOSING);
            }
            if (batchPositionInfos[i].positions.length > 0) {
                IStrPool(strToken).batchUpdateFundingFee(batchPositionInfos[i].positions);
            }
            if (existPositionState(batchPositionInfos[i].poolId, ITradingHub.PositionState.OPEN)) break;
            if (existPositionState(batchPositionInfos[i].poolId, ITradingHub.PositionState.CLOSING) || existPositionState(batchPositionInfos[i].poolId, ITradingHub.PositionState.OVERDRAWN)) {
                poolGuardian.setStateFlag(batchPositionInfos[i].poolId, IPoolGuardian.PoolStatus.LIQUIDATING);
            } else {
                poolGuardian.setStateFlag(batchPositionInfos[i].poolId, IPoolGuardian.PoolStatus.ENDED);
            }
        }
    }

    function delivery(ITradingHub.BatchPositionInfo[] memory batchPositionInfos) external override onlyGrabber {
        for (uint256 i = 0; i < batchPositionInfos.length; i++) {
            (, address strToken, IPoolGuardian.PoolStatus poolStatus) = poolGuardian.getPoolInfo(batchPositionInfos[i].poolId);
            require(poolStatus == IPoolGuardian.PoolStatus.LIQUIDATING, "TradingHub: Pool is not liquidating");
            (, , , , , , , uint256 endBlock, , , , ) = IStrPool(strToken).getInfo();
            require(block.number > endBlock.add(1000), "TradingHub: Pool is not delivery");
            for (uint256 j = 0; j < batchPositionInfos[i].positions.length; j++) {
                PositionInfo storage positionInfo = positionInfoMap[batchPositionInfos[i].positions[j]];
                require(positionInfo.positionState == PositionState.OVERDRAWN, "TradingHub: Position is not overdrawn");
                _updatePositionState(batchPositionInfos[i].positions[j], PositionState.CLOSED);
            }
            if (batchPositionInfos[i].positions.length > 0) {
                IStrPool(strToken).delivery(true);
            }
            if (existPositionState(batchPositionInfos[i].poolId, ITradingHub.PositionState.OVERDRAWN)) break;
            poolGuardian.setStateFlag(batchPositionInfos[i].poolId, IPoolGuardian.PoolStatus.ENDED);
        }
    }

    function updatePositionState(address position, PositionState positionState) external override {
        require(msg.sender == shorterBone.getAddress(AllyLibrary.AUCTION_HALL) || msg.sender == shorterBone.getAddress(AllyLibrary.VAULT_BUTLER), "TradingHub: Caller is neither auctionHall nor vaultButler");
        _updatePositionState(position, positionState);
    }

    function _duplicatedOpenPosition(uint256 poolId, address user) internal view returns (address position) {
        for (uint256 i = 0; i < userPositionSize[user]; i++) {
            PositionCube storage positionCube = userPositions[user][i];
            if (positionCube.poolId == poolId && positionInfoMap[positionCube.addr].positionState == PositionState.OPEN) {
                return positionCube.addr;
            }
        }
    }

    function _updatePositionState(address position, PositionState positionState) internal {
        if (positionState == PositionState.CLOSING) {
            positionBlocks[position].closingBlock = block.number;
            emit PositionClosing(position);
        } else if (positionState == PositionState.OVERDRAWN) {
            positionBlocks[position].overdrawnBlock = block.number;
            emit PositionOverdrawn(position);
        } else if (positionState == PositionState.CLOSED) {
            positionBlocks[position].closedBlock = block.number;
            emit PositionClosed(position);
        }

        positionInfoMap[position].positionState = positionState;
    }

    function existPositionState(uint256 poolId, ITradingHub.PositionState positionState) internal view returns (bool) {
        uint256 poolPosSize = poolPositionSize[poolId];
        for (uint256 i = 0; i < poolPosSize; i++) {
            if (positionInfoMap[poolPositions[poolId][i]].positionState == positionState) {
                return true;
            }
        }
        return false;
    }

    function getPositionsByAccount(address account, PositionState positionState) public view returns (address[] memory) {
        uint256 poolPosSize = userPositionSize[account];
        address[] memory posContainer = new address[](poolPosSize);

        uint256 resPosCount;
        for (uint256 i = 0; i < poolPosSize; i++) {
            if (positionInfoMap[userPositions[account][i].addr].positionState == positionState) {
                posContainer[resPosCount++] = userPositions[account][i].addr;
            }
        }

        address[] memory resPositions = new address[](resPosCount);
        for (uint256 i = 0; i < resPosCount; i++) {
            resPositions[i] = posContainer[i];
        }

        return resPositions;
    }

    function getPositionsByPoolId(uint256 poolId, PositionState positionState) public view override returns (address[] memory) {
        uint256 poolPosSize = poolPositionSize[poolId];
        address[] memory posContainer = new address[](poolPosSize);

        uint256 resPosCount;
        for (uint256 i = 0; i < poolPosSize; i++) {
            if (positionInfoMap[poolPositions[poolId][i]].positionState == positionState) {
                posContainer[resPosCount++] = poolPositions[poolId][i];
            }
        }

        address[] memory resPositions = new address[](resPosCount);
        for (uint256 i = 0; i < resPosCount; i++) {
            resPositions[i] = posContainer[i];
        }

        return resPositions;
    }

    function getPositionsByState(PositionState positionState) public view override returns (address[] memory) {
        address[] memory posContainer = new address[](allPositionSize);

        uint256 resPosCount;
        for (uint256 i = 0; i < allPositionSize; i++) {
            if (positionInfoMap[allPositions[i]].positionState == positionState) {
                posContainer[resPosCount++] = allPositions[i];
            }
        }

        address[] memory resPositions = new address[](resPosCount);
        for (uint256 i = 0; i < resPosCount; i++) {
            resPositions[i] = posContainer[i];
        }

        return resPositions;
    }

    function setDexCenter(address newDexCenter) public isManager {
        dexCenter = IDexCenter(newDexCenter);
    }

    function setPriceOracle(address newPriceOracle) public isManager {
        priceOracle = IPriceOracle(newPriceOracle);
    }

    function setPoolRewardModel(address newPoolRewardModel) public isManager {
        poolRewardModel = IPoolRewardModel(newPoolRewardModel);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import {SafeERC20 as SafeToken} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ISRC20.sol";
import "../criteria/Affinity.sol";

contract Rescuable is Affinity {
    constructor(address _SAVIOR) public Affinity(_SAVIOR) {}

    function killSelf() public isKeeper {
        selfdestruct(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./BytesLib.sol";

library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    function getTokenIn(bytes memory path) internal pure returns (address tokenIn) {
        tokenIn = path.toAddress(0);
        // tokenIn = abi.decode(path.slice(0, ADDR_SIZE), (address));
    }

    function getTokenOut(bytes memory path) internal pure returns (address tokenOut) {
        tokenOut = path.toAddress(path.length - ADDR_SIZE);
        // tokenOut = abi.decode(path.slice((path.length - ADDR_SIZE), path.length), (address));
    }

    function getRouter(bytes memory path) internal pure returns (address[] memory router) {
        uint256 numPools = ((path.length - ADDR_SIZE) / NEXT_OFFSET);
        router = new address[](numPools + 1);

        for (uint256 i = 0; i < numPools; i++) {
            router[i] = path.toAddress(NEXT_OFFSET * i);
        }

        router[numPools] = path.toAddress(path.length - ADDR_SIZE);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "../IShorterBone.sol";
import "../../libraries/AllyLibrary.sol";

/// @notice Interfaces of PoolGuardian
interface IPoolGuardian {
    enum PoolStatus {
        GENESIS,
        RUNNING,
        LIQUIDATING,
        RECOVER,
        ENDED
    }

    function getPoolInfo(uint256 poolId)
        external
        view
        returns (
            address stakedToken,
            address strToken,
            PoolStatus stateFlag
        );

    function addPool(
        address stakedToken,
        address stableToken,
        address creator,
        uint256 leverage,
        uint256 durationDays,
        uint256 poolId
    ) external;

    function listPool(uint256 poolId) external;

    function setStateFlag(uint256 poolId, PoolStatus status) external;

    function queryPools(address stakedToken, PoolStatus status) external view returns (uint256[] memory);

    function getPoolIds() external view returns (uint256[] memory _poolIds);

    function getStrPoolImplementations(bytes4 _sig) external view returns (address);

    function WETH() external view returns (address);

    /// @notice Emitted when this contract is deployed
    event PoolGuardianInitiated();
    /// @notice Emitted when a delisted pool go back
    event PoolListed(uint256 indexed poolId);
    /// @notice Emitted when a listing pool is delisted
    event PoolDelisted(uint256 indexed poolId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @notice Interfaces of TradingHub
interface ITradingHub {
    enum PositionState {
        GENESIS,
        OPEN, //1
        CLOSING, //2
        OVERDRAWN, // 3
        CLOSED // 4
    }

    struct BatchPositionInfo {
        uint256 poolId;
        address[] positions;
    }

    function getPositionInfo(address position)
        external
        view
        returns (
            uint256 poolId,
            address strToken,
            uint256 closingBlock,
            PositionState positionState
        );

    function getPositionsByPoolId(uint256 poolId, PositionState positionState) external view returns (address[] memory);

    function getPositionsByState(PositionState positionState) external view returns (address[] memory);

    function updatePositionState(address position, PositionState positionState) external;

    function executePositions(address[] memory positions) external;

    function isPoolWithdrawable(uint256 poolId) external view returns (bool);

    function setBatchClosePositions(BatchPositionInfo[] memory batchPositionInfos) external;

    function delivery(BatchPositionInfo[] memory batchPositionInfos) external;

    event PositionOpened(uint256 indexed poolId, address indexed trader, address indexed positionAddr, uint256 orderSize);
    event PositionIncreased(uint256 indexed poolId, address indexed trader, address indexed positionAddr, uint256 orderSize);
    event PositionDecreased(uint256 indexed poolId, address indexed trader, address indexed positionAddr, uint256 orderSize);
    event PositionClosing(address indexed positionAddr);
    event PositionOverdrawn(address indexed positionAddr);
    event PositionClosed(address indexed positionAddr);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./v1/IPoolGuardian.sol";
import "./v1/ITradingHub.sol";

interface IStrPool {
    function initialize(
        address creator,
        address stakedToken,
        address stableToken,
        address wrapRouter,
        address _tradingHub,
        address _poolRewardModel,
        uint256 poolId,
        uint256 leverage,
        uint256 durationDays,
        address _WETH
    ) external;

    function setStateFlag(IPoolGuardian.PoolStatus newStateFlag) external;

    function listPool(uint256 blocksPerDay) external;

    function getInfo()
        external
        view
        returns (
            address creator,
            address stakedToken,
            address stableToken,
            address wrappedToken,
            uint256 leverage,
            uint256 durationDays,
            uint256 startBlock,
            uint256 endBlock,
            uint256 id,
            uint256 stakedTokenDecimals,
            uint256 stableTokenDecimals,
            IPoolGuardian.PoolStatus stateFlag
        );

    function borrow(
        bool isSwapRouterV3,
        address dexCenter,
        address swapRouter,
        address position,
        address trader,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory path
    ) external returns (uint256 amountOut);

    function repay(
        bool isSwapRouterV3,
        bool isTetherToken,
        address dexCenter,
        address swapRouter,
        address position,
        address trader,
        uint256 amountOut,
        uint256 amountInMax,
        bytes memory path
    ) external returns (bool isClosed);

    function updatePositionToAuctionHall(address position) external returns (ITradingHub.PositionState positionState);

    function getPositionInfo(address position) external view returns (uint256 totalSize, uint256 unsettledCash);

    function dexCover(
        bool isSwapRouterV3,
        bool isTetherToken,
        address dexCenter,
        address swapRouter,
        uint256 amountOut,
        uint256 amountInMax,
        bytes memory path
    ) external returns (uint256 amountIn);

    function auctionClosed(
        address position,
        uint256 phase1Used,
        uint256 phase2Used,
        uint256 legacyUsed
    ) external;

    function batchUpdateFundingFee(address[] memory positions) external;

    function delivery(bool _isDelivery) external;

    function stableTillOut(address bidder, uint256 amount) external;

    function tradingFeeOf(address trader) external view returns (uint256);

    function totalTradingFee() external view returns (uint256);

    function currentRound() external view returns (uint256);

    function currentRoundTradingFeeOf(address trader) external view returns (uint256);

    function estimatePositionState(uint256 currentPrice, address position) external view returns (ITradingHub.PositionState);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface IDexCenter {
    struct SellShortParams {
        bool isSwapRouterV3;
        uint256 amountIn;
        uint256 amountOutMin;
        address swapRouter;
        address to;
        bytes path;
    }

    struct BuyCoverParams {
        bool isSwapRouterV3;
        bool isTetherToken;
        uint256 amountOut;
        uint256 amountInMax;
        address swapRouter;
        address to;
        bytes path;
    }

    function getSwapRouterWhiteList(address swapRouter) external view returns (bool);

    function isSwapRouterV3(address swapRouter) external view returns (bool);

    function getV2Price(address swapRouter, address[] memory path) external view returns (uint256 price);

    function getV3Price(
        address swapRouter,
        address[] memory path,
        uint24[] memory fees
    ) external view returns (uint256 price);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Configuration meters for various chain deployment
/// @author IPILabs
contract ChainSchema {
    bool private _initialized;

    string internal _chainShortName;
    string internal _chainFullName;
    uint256 internal _blocksPerDay;
    uint256 internal _secondsPerBlock;

    event ChainConfigured(address indexed thisAddr, string shortName, string fullName, uint256 secondsPerBlock);

    modifier chainReady() {
        require(_initialized, "ChainSchema: Waiting to be configured");
        _;
    }

    function configChain(
        string memory shortName,
        string memory fullName,
        uint256 secondsPerBlock
    ) public {
        require(!_initialized, "ChainSchema: Reconfiguration is not allowed");
        require(secondsPerBlock > 0, "ChainSchema: Invalid secondsPerBlock");

        _chainShortName = shortName;
        _chainFullName = fullName;
        _blocksPerDay = uint256(24 * 60 * 60) / secondsPerBlock;
        _secondsPerBlock = secondsPerBlock;
        _initialized = true;

        emit ChainConfigured(address(this), shortName, fullName, secondsPerBlock);
    }

    function chainShortName() public view returns (string memory) {
        return _chainShortName;
    }

    function chainFullName() public view returns (string memory) {
        return _chainFullName;
    }

    function blocksPerDay() public view returns (uint256) {
        return _blocksPerDay;
    }

    function secondsPerBlock() public view returns (uint256) {
        return _secondsPerBlock;
    }

    function getChainId() public pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./TitanCoreStorage.sol";
import "./TradingStorage.sol";

/// @notice Storage for TradingHub implementation
contract AresStorage is TitanCoreStorage, TradingStorage {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
/// Combined div and mod functions from SafeMath
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Enhanced IERC20 interface
interface ISRC20 is IERC20 {
    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ISRC20.sol";
import "../interfaces/IUSDT.sol";
import "./IAffinity.sol";

/// @notice Arch design for roles and privileges management
contract Affinity is AccessControl, IAffinity {
    address internal SAVIOR;

    /// @notice Initial bunch of roles
    bytes32 public constant ROOT_GROUP = keccak256("ROOT_GROUP");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ALLY_ROLE = keccak256("ALLY_ROLE");

    modifier isKeeper() {
        require(hasRole(KEEPER_ROLE, msg.sender), "Affinity: Caller is not keeper");
        _;
    }

    modifier isManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Affinity: Caller is not manager");
        _;
    }

    modifier isAlly() {
        require(hasRole(ALLY_ROLE, msg.sender), "Affinity: Caller is not ally");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Affinity: EOA required");
        _;
    }

    constructor(address _SAVIOR) public {
        SAVIOR = _SAVIOR;

        _setupRole(ROOT_GROUP, _SAVIOR);

        _setRoleAdmin(KEEPER_ROLE, ROOT_GROUP);
        _setRoleAdmin(MANAGER_ROLE, ROOT_GROUP);
        _setRoleAdmin(ALLY_ROLE, ROOT_GROUP);
    }

    function allow(
        address token,
        address spender,
        uint256 amount
    ) external override isKeeper {
        ISRC20(token).approve(spender, amount);
    }

    function allowTetherToken(
        address token,
        address spender,
        uint256 amount
    ) external override isKeeper {
        _allowTetherToken(token, spender, amount);
    }

    function _allowTetherToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IUSDT USDT = IUSDT(token);
        uint256 _allowance = USDT.allowance(address(this), spender);
        if (_allowance >= amount) {
            return;
        }

        if (_allowance > 0) {
            USDT.approve(spender, 0);
        }

        USDT.approve(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @dev Enhanced IERC20 interface
interface IUSDT {
    function approve(address spender, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interface of Affinity
interface IAffinity {
    function allow(
        address token,
        address spender,
        uint256 amount
    ) external;

    function allowTetherToken(
        address token,
        address spender,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface IShorterBone {
    enum IncomeType {
        TRADING_FEE,
        FUNDING_FEE,
        PROPOSAL_FEE,
        PRIORITY_FEE,
        WITHDRAW_FEE
    }

    function poolTillIn(
        uint256 poolId,
        address token,
        address user,
        uint256 amount
    ) external;

    function poolTillOut(
        uint256 poolId,
        address token,
        address user,
        uint256 amount
    ) external;

    function poolRevenue(
        uint256 poolId,
        address user,
        address token,
        uint256 amount,
        IncomeType _type
    ) external;

    function tillIn(
        address tokenAddr,
        address user,
        bytes32 toAllyId,
        uint256 amount
    ) external;

    function tillOut(
        address tokenAddr,
        bytes32 fromAllyId,
        address user,
        uint256 amount
    ) external;

    function revenue(
        bytes32 sendAllyId,
        address tokenAddr,
        address from,
        uint256 amount,
        IncomeType _type
    ) external;

    function getAddress(bytes32 _allyId) external view returns (address);

    function mintByAlly(
        bytes32 sendAllyId,
        address user,
        uint256 amount
    ) external;

    function getTokenInfo(address token)
        external
        view
        returns (
            bool inWhiteList,
            address swapRouter,
            uint256 multiplier
        );

    function TetherToken() external view returns (address);

    /// @notice Emitted when keeper reset the ally contract
    event ResetAlly(bytes32 indexed allyId, address indexed contractAddr);
    /// @notice Emitted when keeper unregister an ally contract
    event AllyKilled(bytes32 indexed allyId);
    /// @notice Emitted when transfer fund from user to an ally contract
    event TillIn(bytes32 indexed allyId, address indexed user, address indexed tokenAddr, uint256 amount);
    /// @notice Emitted when transfer fund from an ally contract to user
    event TillOut(bytes32 indexed allyId, address indexed user, address indexed tokenAddr, uint256 amount);
    /// @notice Emitted when funds reallocated between allies
    event Revenue(address indexed tokenAddr, address indexed user, uint256 amount, IncomeType indexed _type);

    event PoolTillIn(uint256 indexed poolId, address indexed user, uint256 amount);

    event PoolTillOut(uint256 indexed poolId, address indexed user, uint256 amount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "../interfaces/governance/ICommittee.sol";
import "../interfaces/IShorterBone.sol";
import "../interfaces/IShorterFactory.sol";
import "../interfaces/v1/model/IGovRewardModel.sol";
import "../interfaces/v1/IAuctionHall.sol";
import "../interfaces/v1/IVaultButler.sol";
import "../interfaces/v1/IPoolGuardian.sol";
import "../interfaces/v1/IFarming.sol";
import "../interfaces/v1/ITradingHub.sol";
import "../interfaces/v1/model/IPoolRewardModel.sol";
import "../interfaces/v1/model/IVoteRewardModel.sol";
import "../interfaces/v1/model/IFarmingRewardModel.sol";
import "../interfaces/v1/model/ITradingRewardModel.sol";
import "../interfaces/v1/model/IInterestRateModel.sol";
import "../interfaces/governance/IIpistrToken.sol";
import "../interfaces/IStateArcade.sol";
import "../oracles/IPriceOracle.sol";

library AllyLibrary {
    // Ally contracts
    bytes32 public constant AUCTION_HALL = keccak256("AUCTION_HALL");
    bytes32 public constant COMMITTEE = keccak256("COMMITTEE");
    bytes32 public constant DEX_CENTER = keccak256("DEX_CENTER");
    bytes32 public constant IPI_STR = keccak256("IPI_STR");
    bytes32 public constant PRICE_ORACLE = keccak256("PRICE_ORACLE");
    bytes32 public constant POOL_GUARDIAN = keccak256("POOL_GUARDIAN");
    bytes32 public constant SAVIOR_ADDRESS = keccak256("SAVIOR_ADDRESS");
    bytes32 public constant STATE_ARCADE = keccak256("STATE_ARCADE");
    bytes32 public constant TRADING_HUB = keccak256("TRADING_HUB");
    bytes32 public constant VAULT_BUTLER = keccak256("VAULT_BUTLER");
    bytes32 public constant TREASURY = keccak256("TREASURY");
    bytes32 public constant SHORTER_FACTORY = keccak256("SHORTER_FACTORY");
    bytes32 public constant FARMING = keccak256("FARMING");
    bytes32 public constant POSITION_OPERATOR = keccak256("POSITION_OPERATOR");
    bytes32 public constant STR_TOKEN_IMPL = keccak256("STR_TOKEN_IMPL");
    bytes32 public constant SHORTER_BONE = keccak256("SHORTER_BONE");
    bytes32 public constant BRIDGANT = keccak256("BRIDGANT");
    bytes32 public constant TRANCHE_ALLOCATOR = keccak256("TRANCHE_ALLOCATOR");

    // Models
    bytes32 public constant FARMING_REWARD = keccak256("FARMING_REWARD");
    bytes32 public constant POOL_REWARD = keccak256("POOL_REWARD");
    bytes32 public constant VOTE_REWARD = keccak256("VOTE_REWARD");
    bytes32 public constant GOV_REWARD = keccak256("GOV_REWARD");
    bytes32 public constant TRADING_REWARD = keccak256("TRADING_REWARD");
    bytes32 public constant GRAB_REWARD = keccak256("GRAB_REWARD");
    bytes32 public constant INTEREST_RATE = keccak256("INTEREST_RATE");

    function getShorterFactory(IShorterBone shorterBone) internal view returns (IShorterFactory shorterFactory) {
        shorterFactory = IShorterFactory(shorterBone.getAddress(SHORTER_FACTORY));
    }

    function getAuctionHall(IShorterBone shorterBone) internal view returns (IAuctionHall auctionHall) {
        auctionHall = IAuctionHall(shorterBone.getAddress(AUCTION_HALL));
    }

    function getIpistrToken(IShorterBone shorterBone) internal view returns (IIpistrToken ipistrToken) {
        ipistrToken = IIpistrToken(shorterBone.getAddress(IPI_STR));
    }

    function getVaultButler(IShorterBone shorterBone) internal view returns (IVaultButler vaultButler) {
        vaultButler = IVaultButler(shorterBone.getAddress(VAULT_BUTLER));
    }

    function getPoolGuardian(IShorterBone shorterBone) internal view returns (IPoolGuardian poolGuardian) {
        poolGuardian = IPoolGuardian(shorterBone.getAddress(POOL_GUARDIAN));
    }

    function getPriceOracle(IShorterBone shorterBone) internal view returns (IPriceOracle priceOracle) {
        priceOracle = IPriceOracle(shorterBone.getAddress(PRICE_ORACLE));
    }

    function getCommittee(IShorterBone shorterBone) internal view returns (ICommittee committee) {
        committee = ICommittee(shorterBone.getAddress(COMMITTEE));
    }

    function getStateArcade(IShorterBone shorterBone) internal view returns (IStateArcade stateArcade) {
        stateArcade = IStateArcade(shorterBone.getAddress(STATE_ARCADE));
    }

    function getGovRewardModel(IShorterBone shorterBone) internal view returns (IGovRewardModel govRewardModel) {
        govRewardModel = IGovRewardModel(shorterBone.getAddress(GOV_REWARD));
    }

    function getPoolRewardModel(IShorterBone shorterBone) internal view returns (IPoolRewardModel poolRewardModel) {
        poolRewardModel = IPoolRewardModel(shorterBone.getAddress(POOL_REWARD));
    }

    function getTradingHub(IShorterBone shorterBone) internal view returns (ITradingHub tradingHub) {
        tradingHub = ITradingHub(shorterBone.getAddress(TRADING_HUB));
    }

    function getVoteRewardModel(IShorterBone shorterBone) internal view returns (IVoteRewardModel voteRewardModel) {
        voteRewardModel = IVoteRewardModel(shorterBone.getAddress(VOTE_REWARD));
    }

    function getFarming(IShorterBone shorterBone) internal view returns (IFarming farming) {
        farming = IFarming(shorterBone.getAddress(FARMING));
    }

    function getFarmingRewardModel(IShorterBone shorterBone) internal view returns (IFarmingRewardModel farmingRewardModel) {
        farmingRewardModel = IFarmingRewardModel(shorterBone.getAddress(FARMING_REWARD));
    }

    function getTradingRewardModel(IShorterBone shorterBone) internal view returns (ITradingRewardModel tradingRewardModel) {
        tradingRewardModel = ITradingRewardModel(shorterBone.getAddress(TRADING_REWARD));
    }

    function getInterestRateModel(IShorterBone shorterBone) internal view returns (IInterestRateModel interestRateModel) {
        interestRateModel = IInterestRateModel(shorterBone.getAddress(INTEREST_RATE));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface ICommittee {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getQueuedProposals() external view returns (uint256[] memory _queuedProposals, uint256[] memory _failedProposals);

    function isRuler(address account) external view returns (bool);

    function getUserShares(address account) external view returns (uint256 totalShare, uint256 lockedShare);

    function executedProposals(uint256[] memory proposalIds, uint256[] memory failedProposals) external;

    function getVoteProposals(address account, uint256 catagory) external view returns (uint256[] memory _forProposals, uint256[] memory _againstProposals);

    function getForShares(address account, uint256 proposalId) external view returns (uint256 voteShare, uint256 totalShare);

    function getAgainstShares(address account, uint256 proposalId) external view returns (uint256 voteShare, uint256 totalShare);

    /// @notice Emitted when a new proposal was created
    event PoolProposalCreated(uint256 indexed proposalId, address indexed proposer);
    /// @notice Emitted when a community proposal was created
    event CommunityProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, string title);
    /// @notice Emitted when one Ruler vote a specified proposal
    event ProposalVoted(uint256 indexed proposalId, address indexed user, bool direction, uint256 voteShare);
    /// @notice Emitted when a proposal was canceled
    event ProposalStatusChanged(uint256 indexed proposalId, uint256 ps);
    /// @notice Emitted when admin tweak the voting period
    event VotingMaxDaysSet(uint256 maxVotingDays);
    /// @notice Emitted when admin tweak ruler threshold parameter
    event RulerThresholdSet(uint256 oldRulerThreshold, uint256 newRulerThreshold);
    /// @notice Emitted when user deposit IPISTRs to Committee vault
    event DepositCommittee(address indexed user, uint256 depositAmount, uint256 totalAmount);
    /// @notice Emitted when user withdraw IPISTRs from Committee vault
    event WithdrawCommittee(address indexed user, uint256 withdrawAmount, uint256 totalAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface IShorterFactory {
    function createStrPool(uint256 poolId, address _poolGuardian) external returns (address strToken);

    function createOthers(bytes memory code, uint256 salt) external returns (address _contractAddr);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./IRewardModel.sol";

/// @notice Interfaces of GovRewardModel
interface IGovRewardModel is IRewardModel {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IAuctionHall {
    enum AuctionPhase {
        GENESIS,
        PHASE_1,
        PHASE_2,
        LEGACY,
        FINISHED
    }

    function inquire()
        external
        view
        returns (
            address[] memory closedPositions,
            address[] memory legacyPositions,
            bytes[] memory _phase1Ranks
        );

    function executePositions(
        address[] memory closedPositions,
        address[] memory legacyPositions,
        bytes[] memory _phase1Ranks
    ) external;

    // Events
    event AuctionInitiated(address indexed positionAddr);
    event BidTanto(address indexed positionAddr, address indexed ruler, uint256 bidSize, uint256 priorityFee);
    event BidKatana(address indexed positionAddr, address indexed ruler, uint256 debtSize, uint256 usedCash, uint256 dexCoverReward);
    event AuctionFinished(address indexed positionAddr, address indexed trader, uint256 indexed phase);
    event Phase1Finished(address indexed positionAddr);
    event Phase1Rollback(address indexed positionAddr);
    event Retrieve(address indexed positionAddr, uint256 stableTokenSize, uint256 debtTokenSize, uint256 priorityFee);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interfaces of VaultButler
interface IVaultButler {
    event ExecuteNaginata(address indexed positionAddr, address indexed ruler, uint256 bidSize, uint256 receiveSize);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interfaces of Farming
interface IFarming {
    function getUserStakedAmount(address user) external view returns (uint256 userStakedAmount);

    function harvest(uint256 tokenId, address user) external;

    function getTokenId() external view returns (uint256);

    event Stake(address indexed user, uint256 indexed tokenId, uint256 liquidity, uint256 amount0, uint256 amount1);
    event UnStake(address indexed user, uint256 indexed tokenId, uint256 liquidity, uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "../../IShorterBone.sol";
import "./IRewardModel.sol";
import "../../../libraries/AllyLibrary.sol";

/// @notice Interfaces of PoolRewardModel
interface IPoolRewardModel {
    function harvest(
        address user,
        uint256[] memory stakedPools,
        uint256[] memory createPools,
        uint256[] memory votePools
    ) external returns (uint256 rewards);

    function pendingReward(address user)
        external
        view
        returns (
            uint256 stakedRewards,
            uint256 creatorRewards,
            uint256 voteRewards,
            uint256[] memory stakedPools,
            uint256[] memory createPools,
            uint256[] memory votePools
        );

    function harvestByStrToken(
        uint256 poolId,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./IRewardModel.sol";

/// @notice Interfaces of VoteRewardModel
interface IVoteRewardModel is IRewardModel {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./IRewardModel.sol";

/// @notice Interfaces of FarmingRewardModel
interface IFarmingRewardModel {
    function harvest(address user) external returns (uint256 rewards);

    function pendingReward(address user) external view returns (uint256 unLockRewards, uint256 rewards);

    function harvestByPool(address user) external returns (uint256 rewards);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./IRewardModel.sol";

/// @notice Interfaces of TradingRewardModel
interface ITradingRewardModel {
    function pendingReward(address trader) external view returns (uint256 rewards, uint256[] memory poolIds);

    function harvest(address trader, uint256[] memory poolIds) external returns (uint256 rewards);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface IInterestRateModel {
    function getBorrowRate(uint256 poolId, uint256 userBorrowCash) external view returns (uint256 fundingFeePerBlock);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface IIpistrToken {
    function mint(address to, uint256 amount) external;

    function setLocked(address user, uint256 amount) external;

    function spendableBalanceOf(address account) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function unlockBalance(address account, uint256 amount) external;

    event Unlock(address indexed staker, uint256 claimedAmount);
    event Burn(address indexed blackHoleAddr, uint256 burnAmount);
    event Mint(address indexed account, uint256 mintAmount);
    event SetLocked(address user, uint256 amount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interfaces of StateArcade
interface IStateArcade {
    function fetchPoolUsers(uint256 poolId, uint256 flag) external view returns (address[] memory);

    function notifyUserDepositPool(
        address _account,
        uint256 _poolId,
        uint256 _changeAmount
    ) external;

    function notifyUserWithdrawPool(
        address _account,
        uint256 _poolId,
        uint256 _changeAmount
    ) external;

    function notifyUserBorrowPool(
        address _account,
        uint256 _poolId,
        uint256 _changeAmount
    ) external;

    function notifyUserRepayPool(
        address _account,
        uint256 _poolId,
        uint256 _changeAmount
    ) external;

    function notifyUserTradingFee(
        address positionAddr,
        address account,
        uint256 tradingFee
    ) external;

    function getUsersInSingleRound(uint256 _NoIndex) external view returns (address[] memory _NoUsers);

    function getUserActivePoolIds(address _account) external view returns (uint256[] memory);

    function getTokenTVL(address _tokenAddr) external view returns (uint256 _amount, uint256 _borrowAmount);

    function getUserTradingFee(uint256 _NoIndex, address _account) external view returns (uint256 _userFee);

    function getTotalFeeInfo(uint256 _NoIndex) external view returns (uint256 _totalFee, uint256 _ipistrTokenPrice);

    function getNo1Index() external view returns (uint256 _No1Index);

    function updateLegacyTokenData(
        uint256 poolId,
        uint256 amount,
        address tokenAddr
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interface of PriceOracle
interface IPriceOracle {
    enum PriceOracleMode {
        DEX_MODE,
        CHAINLINK_MODE,
        FEED_NODE
    }

    function getLatestMixinPrice(address tokenAddr) external view returns (uint256 tokenPrice, uint256 decimals);

    function getTokenPrice(address tokenAddr) external view returns (uint256 tokenPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interfaces of BaseReward model
interface IRewardModel {
    function pendingReward(address user) external view returns (uint256 _reward);

    function harvest(address user) external returns (uint256 rewards);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "../interfaces/IShorterBone.sol";

/// @notice Storage for TitanProxy with update information
contract TitanCoreStorage {
    IShorterBone internal shorterBone;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../interfaces/uniswapv2/IUniswapV2Router02.sol";
import "../interfaces/IDexCenter.sol";
import "../interfaces/ISRC20.sol";
import "../interfaces/v1/IPoolGuardian.sol";
import "../interfaces/v1/ITradingHub.sol";
import "../interfaces/v1/model/IPoolRewardModel.sol";
import "../oracles/IPriceOracle.sol";
import "./TitanCoreStorage.sol";
import "../util/EnumerableMap.sol";

contract TradingStorage is TitanCoreStorage {
    /// @notice Info of each pool, occupies 4 slots
    struct PoolInfo {
        address creator;
        // Staked single token contract
        ISRC20 stakedToken;
        ISRC20 stableToken;
        address strToken;
        // Allowed max leverage
        uint256 leverage;
        // Optional if the pool is marked as never expires(perputual)
        uint256 durationDays;
        // Pool creation block number
        uint256 startBlock;
        // Pool expired block number
        uint256 endBlock;
        uint256 id;
        uint256 stakedTokenDecimals;
        uint256 stableTokenDecimals;
        // Determining whether or not this pool is listed and present
        IPoolGuardian.PoolStatus stateFlag;
    }

    struct PositionCube {
        address addr;
        uint64 poolId;
    }

    struct PositionBlock {
        uint256 openBlock;
        uint256 closingBlock;
        uint256 overdrawnBlock;
        uint256 closedBlock;
    }

    struct PositionInfo {
        uint64 poolId;
        address strToken;
        ITradingHub.PositionState positionState;
    }

    bool internal _initialized;
    uint256 public allPositionSize;
    IDexCenter public dexCenter;
    IPoolGuardian public poolGuardian;
    IPriceOracle public priceOracle;
    IPoolRewardModel public poolRewardModel;

    mapping(uint256 => address) public allPositions;
    mapping(address => mapping(uint256 => PositionCube)) public userPositions;
    mapping(address => uint256) public userPositionSize;

    mapping(uint256 => mapping(uint256 => address)) public poolPositions;
    mapping(uint256 => uint256) public poolPositionSize;

    mapping(address => PositionInfo) public positionInfoMap;
    mapping(address => PositionBlock) public positionBlocks;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap internal myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 * Amended: Juu17 on 2020/05/03
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses internal functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) internal view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) internal view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }

    // AddressToUintMap   - added on 20200830
    struct AddressToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(key)), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint256(key)), uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(uint256(key)), errorMessage));
    }

    // UintToUintMap   - added  20200919
    struct UintToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(_get(map._inner, bytes32(key), errorMessage));
    }

    // AddressToBytes8Map   - added  202010/26
    struct AddressToBytes8Map {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToBytes8Map storage map,
        address key,
        bytes8 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(key)), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToBytes8Map storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToBytes8Map storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToBytes8Map storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToBytes8Map storage map, uint256 index) internal view returns (address, bytes8) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint256(key)), bytes8(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToBytes8Map storage map, address key) internal view returns (bytes8) {
        return bytes8(_get(map._inner, bytes32(uint256(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        AddressToBytes8Map storage map,
        address key,
        string memory errorMessage
    ) internal view returns (bytes8) {
        return bytes8(_get(map._inner, bytes32(uint256(key)), errorMessage));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}