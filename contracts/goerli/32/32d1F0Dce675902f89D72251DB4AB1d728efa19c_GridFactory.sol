// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGridFactory.sol";
import "./GridDeployer.sol";
import "./PriceOracle.sol";

/// @title The implementation of a Gridex grid factory
contract GridFactory is IGridFactory, Context, GridDeployer, Ownable {
    address public immutable override priceOracle;
    address public immutable weth9;
    mapping(int24 => int24) public override resolutions;
    /// @notice The first key and the second key are token addresses, and the third key is the resolution,
    /// and the value is the grid address
    /// @dev For tokenA/tokenB and the specified resolution, both the combination of tokenA/tokenB
    /// and the combination of tokenB/tokenA with resolution will be stored in the mapping
    mapping(address => mapping(address => mapping(int24 => address))) public override grids;

    constructor(address _weth9, bytes memory _gridPrefixCreationCode) {
        // GF_NC: not contract
        require(Address.isContract(_weth9), "GF_NC");

        priceOracle = address(new PriceOracle());
        weth9 = _weth9;

        _enableResolutions();

        _setGridPrefixCreationCode(_gridPrefixCreationCode);
    }

    function _enableResolutions() internal {
        resolutions[1] = 100;
        emit ResolutionEnabled(1, 100);

        resolutions[5] = 500;
        emit ResolutionEnabled(5, 500);

        resolutions[30] = 3000;
        emit ResolutionEnabled(30, 3000);
    }

    /// @inheritdoc IGridFactory
    function concatGridSuffixCreationCode(bytes memory gridSuffixCreationCode) external override onlyOwner {
        _concatGridSuffixCreationCode(gridSuffixCreationCode);
        renounceOwnership();
    }

    /// @inheritdoc IGridFactory
    function createGrid(address tokenA, address tokenB, int24 resolution) external override returns (address grid) {
        // GF_NI: not initialized
        require(owner() == address(0), "GF_NI");

        // GF_NC: not contract
        require(Address.isContract(tokenA), "GF_NC");
        require(Address.isContract(tokenB), "GF_NC");

        // GF_TAD: token address must be different
        require(tokenA != tokenB, "GF_TAD");
        // GF_PAE: grid already exists
        require(grids[tokenA][tokenB][resolution] == address(0), "GF_PAE");

        int24 takerFee = resolutions[resolution];
        // GF_RNE: resolution not enabled
        require(takerFee > 0, "GF_RNE");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        grid = deploy(token0, token1, resolution, takerFee, priceOracle, weth9);
        grids[tokenA][tokenB][resolution] = grid;
        grids[tokenB][tokenA][resolution] = grid;
        emit GridCreated(token0, token1, resolution, grid);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;

import "./interfaces/IGrid.sol";
import "./interfaces/IPriceOracle.sol";
import "./libraries/CallbackValidator.sol";
import "./libraries/GridAddress.sol";

contract PriceOracle is IPriceOracle {
    address public immutable gridFactory;

    mapping(address => GridOracleState) public override gridOracleStates;
    mapping(address => GridPriceData[65535]) public override gridPriceData;

    constructor() {
        gridFactory = msg.sender;
    }

    /// @inheritdoc IPriceOracle
    function register(address tokenA, address tokenB, int24 resolution) external override {
        address grid = GridAddress.computeAddress(gridFactory, GridAddress.gridKey(tokenA, tokenB, resolution));
        // PO_IC: invalid caller
        require(grid == msg.sender, "PO_IC");

        _register(grid);
    }

    function _register(address grid) internal {
        // PO_AR: already registered
        require(gridOracleStates[grid].capacity == 0, "PO_AR");

        gridOracleStates[grid].capacity = 1;
        gridOracleStates[grid].capacityNext = 1;
        gridPriceData[grid][0] = GridPriceData({
            blockTimestamp: uint32(block.timestamp),
            boundaryCumulative: 0,
            initialized: true
        });
    }

    /// @inheritdoc IPriceOracle
    function update(int24 boundary, uint32 blockTimestamp) external override {
        _update(msg.sender, boundary, blockTimestamp);
    }

    function _update(address grid, int24 boundary, uint32 blockTimestamp) internal {
        GridOracleState memory stateCache = gridOracleStates[grid];
        // PO_UR: unregistered grid
        require(stateCache.capacity >= 1, "PO_UR");

        GridPriceData storage lastData = gridPriceData[grid][stateCache.index];

        // safe for 0 or 1 overflows
        unchecked {
            uint32 delta = blockTimestamp - lastData.blockTimestamp;

            uint16 indexNext = (stateCache.index + 1) % stateCache.capacityNext;
            gridPriceData[grid][indexNext] = GridPriceData({
                blockTimestamp: blockTimestamp,
                boundaryCumulative: lastData.boundaryCumulative + int56(boundary) * int56(uint56(delta)),
                initialized: true
            });

            // In the interest of gas-efficiency, the capacity is set to be the same as capacityNext
            if (indexNext == stateCache.capacity) gridOracleStates[grid].capacity = stateCache.capacityNext;

            gridOracleStates[grid].index = indexNext;
        }
    }

    /// @inheritdoc IPriceOracle
    function increaseCapacity(address grid, uint16 capacityNext) external override {
        GridOracleState storage state = gridOracleStates[grid];
        // PO_UR: unregistered grid
        require(state.capacity >= 1, "PO_UR");

        uint16 capacityOld = state.capacityNext;
        if (capacityOld >= capacityNext) return;

        for (uint16 i = capacityOld; i < capacityNext; i++) {
            // In the interest of gas-efficiency the array is initialized at the specified index here
            // when updating the oracle price
            // Note: this data will not be used, because the initialized property is still false
            gridPriceData[grid][i].blockTimestamp = 1;
        }

        state.capacityNext = capacityNext;

        emit IncreaseCapacity(grid, capacityOld, capacityNext);
    }

    /// @inheritdoc IPriceOracle
    function getBoundaryCumulative(
        address grid,
        uint32 secondsAgo
    ) external view override returns (int56 boundaryCumulative) {
        GridOracleState memory state = gridOracleStates[grid];
        // PO_UR: unregistered grid
        require(state.capacity >= 1, "PO_UR");

        (, int24 boundary, , ) = IGrid(grid).slot0();

        return _getBoundaryCumulative(state, gridPriceData[grid], boundary, uint32(block.timestamp), secondsAgo);
    }

    /// @inheritdoc IPriceOracle
    function getBoundaryCumulatives(
        address grid,
        uint32[] calldata secondsAgos
    ) external view override returns (int56[] memory boundaryCumulatives) {
        GridOracleState memory state = gridOracleStates[grid];
        // PO_UR: unregistered grid
        require(state.capacity >= 1, "PO_UR");

        boundaryCumulatives = new int56[](secondsAgos.length);
        (, int24 boundary, , ) = IGrid(grid).slot0();
        uint32 blockTimestamp = uint32(block.timestamp);
        GridPriceData[65535] storage targetGridPriceData = gridPriceData[grid];
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            boundaryCumulatives[i] = _getBoundaryCumulative(
                state,
                targetGridPriceData,
                boundary,
                blockTimestamp,
                secondsAgos[i]
            );
        }
    }

    /// @notice Get the time-cumulative boundary at a given time in the past
    /// @param blockTimestamp The timestamp of the current block
    /// @param secondsAgo The time elapsed (in seconds) in the past to get the price for
    /// @return boundaryCumulative The time-cumulative boundary at the given time
    function _getBoundaryCumulative(
        GridOracleState memory state,
        GridPriceData[65535] storage priceData,
        int24 boundary,
        uint32 blockTimestamp,
        uint32 secondsAgo
    ) internal view returns (int56 boundaryCumulative) {
        if (secondsAgo == 0) {
            GridPriceData memory last = priceData[state.index];
            if (last.blockTimestamp == blockTimestamp) return last.boundaryCumulative;

            unchecked {
                return last.boundaryCumulative + int56(boundary) * int56(uint56(blockTimestamp - last.blockTimestamp));
            }
        }

        uint32 targetTimestamp;
        unchecked {
            targetTimestamp = blockTimestamp - secondsAgo;
        }

        (GridPriceData memory beforePriceData, GridPriceData memory afterPriceData) = _getSurroundingPriceData(
            state,
            priceData,
            boundary,
            blockTimestamp,
            targetTimestamp
        );

        if (targetTimestamp == beforePriceData.blockTimestamp) {
            return beforePriceData.boundaryCumulative;
        } else if (targetTimestamp == afterPriceData.blockTimestamp) {
            return afterPriceData.boundaryCumulative;
        } else {
            // p = p_b + (p_a - p_b) / (t_a - t_b) * (t - t_b)
            unchecked {
                uint32 timestampDelta = targetTimestamp - beforePriceData.blockTimestamp;
                int88 boundaryCumulativeDelta = (int88(uint88(timestampDelta)) *
                    (afterPriceData.boundaryCumulative - beforePriceData.boundaryCumulative)) /
                    int32(afterPriceData.blockTimestamp - beforePriceData.blockTimestamp);
                return beforePriceData.boundaryCumulative + int56(boundaryCumulativeDelta);
            }
        }
    }

    /// @notice Get the surrounding price data for a given timestamp
    /// @param boundary The boundary of the grid at the current block
    /// @param blockTimestamp The timestamp of the current block
    /// @param targetTimestamp The timestamp to search for
    /// @return beforeOrAtPriceData The price data with the largest timestamp
    /// less than or equal to the target timestamp
    /// @return afterOrAtPriceData The price data with the smallest timestamp
    /// greater than or equal to the target timestamp
    function _getSurroundingPriceData(
        GridOracleState memory state,
        GridPriceData[65535] storage priceData,
        int24 boundary,
        uint32 blockTimestamp,
        uint32 targetTimestamp
    ) private view returns (GridPriceData memory beforeOrAtPriceData, GridPriceData memory afterOrAtPriceData) {
        beforeOrAtPriceData = priceData[state.index];

        if (_overflowSafeLTE(blockTimestamp, beforeOrAtPriceData.blockTimestamp, targetTimestamp)) {
            if (beforeOrAtPriceData.blockTimestamp != targetTimestamp) {
                // When the target time is greater than or equal to the last update time, it only needs to
                // calculate the time-cumulative price for the given time
                unchecked {
                    beforeOrAtPriceData = GridPriceData({
                        blockTimestamp: targetTimestamp,
                        boundaryCumulative: beforeOrAtPriceData.boundaryCumulative +
                            int56(boundary) *
                            (int56(uint56(targetTimestamp - beforeOrAtPriceData.blockTimestamp))),
                        initialized: false
                    });
                }
            }
            return (beforeOrAtPriceData, afterOrAtPriceData);
        }

        GridPriceData storage oldestPriceData = priceData[(state.index + 1) % state.capacity];
        if (!oldestPriceData.initialized) oldestPriceData = priceData[0];

        // PO_STL: secondsAgo is too large
        require(_overflowSafeLTE(blockTimestamp, oldestPriceData.blockTimestamp, targetTimestamp), "PO_STL");

        return _binarySearch(state, priceData, blockTimestamp, targetTimestamp);
    }

    /// @notice Binary search for the surrounding price data for a given timestamp
    /// @param blockTimestamp The timestamp of the current block
    /// @param targetTimestamp The timestamp to search for
    /// @return beforeOrAtPriceData The price data with the largest timestamp
    /// less than or equal to the target timestamp
    /// @return afterOrAtPriceData The price data with the smallest timestamp
    /// greater than or equal to the target timestamp
    function _binarySearch(
        GridOracleState memory state,
        GridPriceData[65535] storage priceData,
        uint32 blockTimestamp,
        uint32 targetTimestamp
    ) private view returns (GridPriceData memory beforeOrAtPriceData, GridPriceData memory afterOrAtPriceData) {
        uint256 left = (state.index + 1) % state.capacity;
        uint256 right = left + state.capacity - 1;
        uint256 mid;
        while (true) {
            mid = (left + right) / 2;

            beforeOrAtPriceData = priceData[mid % state.capacity];
            if (!beforeOrAtPriceData.initialized) {
                left = mid + 1;
                continue;
            }

            afterOrAtPriceData = priceData[(mid + 1) % state.capacity];

            bool targetAfterOrAt = _overflowSafeLTE(
                blockTimestamp,
                beforeOrAtPriceData.blockTimestamp,
                targetTimestamp
            );
            if (
                targetAfterOrAt && _overflowSafeLTE(blockTimestamp, targetTimestamp, afterOrAtPriceData.blockTimestamp)
            ) {
                return (beforeOrAtPriceData, afterOrAtPriceData);
            }

            if (!targetAfterOrAt) right = mid - 1;
            else left = mid + 1;
        }
    }

    /// @notice Compare the order of timestamps
    /// @dev blockTimestamp The timestamp of the current block
    /// @dev a First timestamp (in the past) to check
    /// @dev b Second timestamp (in the past) to check
    /// @return lte Result of a <= b
    function _overflowSafeLTE(uint32 blockTimestamp, uint32 a, uint32 b) private pure returns (bool lte) {
        if (a <= blockTimestamp && b <= blockTimestamp) return a <= b;
        unchecked {
            uint256 aAdjusted = a > blockTimestamp ? a : a + 2 ** 32;
            uint256 bAdjusted = b > blockTimestamp ? b : b + 2 ** 32;
            return aAdjusted <= bAdjusted;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for Gridex grid factory
interface IGridFactory {
    /// @notice Emitted when a new resolution is enabled for grid creation via the grid factory
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @param takerFee The taker fee, denominated in hundredths of a bip (i.e. 1e-6)
    event ResolutionEnabled(int24 indexed resolution, int24 indexed takerFee);

    /// @notice Emitted upon grid creation
    /// @param token0 The first token in the grid, after sorting by address
    /// @param token1 The first token in the grid, after sorting by address
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @param grid The address of the deployed grid
    event GridCreated(address indexed token0, address indexed token1, int24 indexed resolution, address grid);

    /// @notice Returns the taker fee for the given resolution if enabled. Else, returns 0.
    /// @dev A resolution can never be removed, so this value should be hard coded or cached in the calling context
    /// @param resolution The enabled resolution
    /// @return takerFee The taker fee, denominated in hundredths of a bip (i.e. 1e-6)
    function resolutions(int24 resolution) external view returns (int24 takerFee);

    /// @notice The implementation address of the price oracle
    function priceOracle() external view returns (address);

    /// @notice Returns the grid address for a given token pair and a resolution. Returns 0 if the pair does not exist.
    /// @dev tokenA and tokenB may be passed in, in the order of either token0/token1 or token1/token0
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return grid The grid address
    function grids(address tokenA, address tokenB, int24 resolution) external view returns (address grid);

    /// @notice Concat grid creation code bytes
    /// @dev Split the creationCode of the Grid contract into two parts, so that the Gas Limit of particular networks can be met when deploying.
    /// @param gridSuffixCreationCode This parameter is the second half of the creationCode of the Grid contract.
    function concatGridSuffixCreationCode(bytes memory gridSuffixCreationCode) external;

    /// @notice Creates a grid for a given pair of tokens and resolution
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0.
    /// @param tokenA One token of the grid token pair
    /// @param tokenB The other token of the grid token pair
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return grid The address of the deployed grid
    function createGrid(address tokenA, address tokenB, int24 resolution) external returns (address grid);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IGridDeployer.sol";

contract GridDeployer is IGridDeployer {
    bytes public override gridCreationCode;
    Parameters public override parameters;

    /// @dev Split the creationCode of the Grid contract into two parts, so that the Gas Limit of particular networks can be met when deploying.
    /// @param _gridPrefixCreationCode This parameter is the first half of the creationCode of the Grid contract.
    function _setGridPrefixCreationCode(bytes memory _gridPrefixCreationCode) internal {
        gridCreationCode = _gridPrefixCreationCode;
    }

    /// @dev Split the creationCode of the Grid contract into two parts, so that the Gas Limit of particular networks can be met when deploying.
    /// @param _gridSuffixCreationCode This parameter is the second half of the creationCode of the Grid contract.
    function _concatGridSuffixCreationCode(bytes memory _gridSuffixCreationCode) internal {
        gridCreationCode = bytes.concat(gridCreationCode, _gridSuffixCreationCode);
    }

    /// @dev Deploys a grid with desired parameters and clears these parameters after the deployment is complete
    /// @param token0 The first token in the grid, after sorting by address
    /// @param token1 The second token in the grid, after sorting by address
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @param takerFee The taker fee, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param priceOracle The address of the price oracle contract
    /// @param weth9 The address of the WETH9 contract
    /// @return grid The address of the deployed grid
    function deploy(
        address token0,
        address token1,
        int24 resolution,
        int24 takerFee,
        address priceOracle,
        address weth9
    ) internal returns (address grid) {
        parameters = Parameters(token0, token1, resolution, takerFee, priceOracle, weth9);
        grid = Create2.deploy(0, keccak256(abi.encode(token0, token1, resolution)), gridCreationCode);
        delete parameters;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for the price oracle
interface IPriceOracle {
    /// @notice Emitted when the capacity of the array in which the oracle can store prices has increased.
    /// @param grid The grid address whose capacity has been increased
    /// @param capacityOld Array capacity before the increase in capacity
    /// @param capacityNew Array capacity after the increase in capacity
    event IncreaseCapacity(address indexed grid, uint16 capacityOld, uint16 capacityNew);

    struct GridPriceData {
        /// @dev The block timestamp of the price data
        uint32 blockTimestamp;
        /// @dev The time-cumulative boundary
        int56 boundaryCumulative;
        /// @dev Whether or not the price data is initialized
        bool initialized;
    }

    struct GridOracleState {
        /// @dev The index of the last updated price
        uint16 index;
        /// @dev The array capacity used by the oracle
        uint16 capacity;
        /// @dev The capacity of the array that the oracle can use
        uint16 capacityNext;
    }

    /// @notice Returns the state of the oracle for a given grid
    /// @param grid The grid to retrieve the state of
    /// @return index The index of the last updated price
    /// @return capacity The array capacity used by the oracle
    /// @return capacityNext The capacity of the array that the oracle can use
    function gridOracleStates(address grid) external view returns (uint16 index, uint16 capacity, uint16 capacityNext);

    /// @notice Returns the price data of the oracle for a given grid and index
    /// @param grid The grid to get the price data of
    /// @param index The index of the price data to get
    /// @return blockTimestamp The block timestamp of the price data
    /// @return boundaryCumulative The time-cumulative boundary
    /// @return initialized Whether or not the price data is initialized
    function gridPriceData(
        address grid,
        uint256 index
    ) external view returns (uint32 blockTimestamp, int56 boundaryCumulative, bool initialized);

    /// @notice Register a grid to the oracle using a given token pair and resolution
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    function register(address tokenA, address tokenB, int24 resolution) external;

    /// @notice Update the oracle price
    /// @param boundary The new boundary to write to the oracle
    /// @param blockTimestamp The timestamp of the oracle price to write
    function update(int24 boundary, uint32 blockTimestamp) external;

    /// @notice Increase the storage capacity of the oracle
    /// @param grid The grid whose capacity is to be increased
    /// @param capacityNext Array capacity after increase in capacity
    function increaseCapacity(address grid, uint16 capacityNext) external;

    /// @notice Get the time-cumulative price for a given time
    /// @param grid Get the price of a grid address
    /// @param secondsAgo The time elapsed (in seconds) to get the boundary for
    /// @return boundaryCumulative The time-cumulative boundary for the given time
    function getBoundaryCumulative(address grid, uint32 secondsAgo) external view returns (int56 boundaryCumulative);

    /// @notice Get a list of time-cumulative boundaries for given times
    /// @param grid The grid address to get the boundaries of
    /// @param secondsAgos A list of times elapsed (in seconds) to get the boundaries for
    /// @return boundaryCumulatives The list of time-cumulative boundaries for the given times
    function getBoundaryCumulatives(
        address grid,
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory boundaryCumulatives);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

library GridAddress {
    bytes32 internal constant GRID_BYTES_CODE_HASH = 0x884a6891a166f885bf6f0a3b330a25e41d1761a5aa091110a229d9a0e34b2c36;

    struct GridKey {
        address token0;
        address token1;
        int24 resolution;
    }

    /// @notice Constructs the grid key for the given parameters
    /// @dev tokenA and tokenB may be passed in, in the order of either token0/token1 or token1/token0
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return key The grid key to compute the canonical address for the grid
    function gridKey(address tokenA, address tokenB, int24 resolution) internal pure returns (GridKey memory key) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        return GridKey(tokenA, tokenB, resolution);
    }

    /// @dev Computes the CREATE2 address for a grid with the given parameters
    /// @param gridFactory The address of the grid factory
    /// @param key The grid key to compute the canonical address for the grid
    /// @return grid The computed address
    function computeAddress(address gridFactory, GridKey memory key) internal pure returns (address grid) {
        require(key.token0 < key.token1);
        return
            Create2.computeAddress(
                keccak256(abi.encode(key.token0, key.token1, key.resolution)),
                GRID_BYTES_CODE_HASH,
                gridFactory
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IGridStructs.sol";
import "./IGridParameters.sol";

/// @title The interface for Gridex grid
interface IGrid {
    ///==================================== Grid States  ====================================

    /// @notice The first token in the grid, after sorting by address
    function token0() external view returns (address);

    /// @notice The second token in the grid, after sorting by address
    function token1() external view returns (address);

    /// @notice The step size in initialized boundaries for a grid created with a given fee
    function resolution() external view returns (int24);

    /// @notice The fee paid to the grid denominated in hundredths of a bip, i.e. 1e-6
    function takerFee() external view returns (int24);

    /// @notice The 0th slot of the grid holds a lot of values that can be gas-efficiently accessed
    /// externally as a single method
    /// @return priceX96 The current price of the grid, as a Q64.96
    /// @return boundary The current boundary of the grid
    /// @return blockTimestamp The time the oracle was last updated
    /// @return unlocked Whether the grid is unlocked or not
    function slot0() external view returns (uint160 priceX96, int24 boundary, uint32 blockTimestamp, bool unlocked);

    /// @notice Returns the boundary information of token0
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token0 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries0(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns the boundary information of token1
    /// @param boundary The boundary of the grid
    /// @return bundle0Id The unique identifier of bundle0
    /// @return bundle1Id The unique identifier of bundle1
    /// @return makerAmountRemaining The remaining amount of token1 that can be swapped out,
    /// which is the sum of bundle0 and bundle1
    function boundaries1(
        int24 boundary
    ) external view returns (uint64 bundle0Id, uint64 bundle1Id, uint128 makerAmountRemaining);

    /// @notice Returns 256 packed boundary initialized boolean values for token0
    function boundaryBitmaps0(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns 256 packed boundary initialized boolean values for token1
    function boundaryBitmaps1(int16 wordPos) external view returns (uint256 word);

    /// @notice Returns the amount owed for token0 and token1
    /// @param owner The address of owner
    /// @return token0 The amount of token0 owed
    /// @return token1 The amount of token1 owed
    function tokensOweds(address owner) external view returns (uint128 token0, uint128 token1);

    /// @notice Returns the information of a given bundle
    /// @param bundleId The unique identifier of the bundle
    /// @return boundaryLower The lower boundary of the bundle
    /// @return zero When zero is true, it represents token0, otherwise it represents token1
    /// @return makerAmountTotal The total amount of token0 or token1 that the maker added
    /// @return makerAmountRemaining The remaining amount of token0 or token1 that can be swapped out from the makers
    /// @return takerAmountRemaining The remaining amount of token0 or token1 that have been swapped in from the takers
    /// @return takerFeeAmountRemaining The remaining amount of fees that takers have paid in
    function bundles(
        uint64 bundleId
    )
        external
        view
        returns (
            int24 boundaryLower,
            bool zero,
            uint128 makerAmountTotal,
            uint128 makerAmountRemaining,
            uint128 takerAmountRemaining,
            uint128 takerFeeAmountRemaining
        );

    /// @notice Returns the information of a given order
    /// @param orderId The unique identifier of the order
    /// @return bundleId The unique identifier of the bundle -- represents which bundle this order belongs to
    /// @return owner The address of the owner of the order
    /// @return amount The amount of token0 or token1 to add
    function orders(uint256 orderId) external view returns (uint64 bundleId, address owner, uint128 amount);

    ///==================================== Grid Actions ====================================

    /// @notice Initializes the grid with the given parameters
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback.
    /// When initializing the grid, token0 and token1's liquidity must be added simultaneously.
    /// @param parameters The parameters used to initialize the grid
    /// @param data Any data to be passed through to the callback
    /// @return orderIds0 The unique identifiers of the orders for token0
    /// @return orderIds1 The unique identifiers of the orders for token1
    function initialize(
        IGridParameters.InitializeParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds0, uint256[] memory orderIds1);

    /// @notice Swaps token0 for token1, or vice versa
    /// @dev The caller of this method receives a callback in the form of IGridSwapCallback#gridexSwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The swap direction, true for token0 to token1 and false otherwise
    /// @param amountSpecified The amount of the swap, configured as an exactInput (positive)
    /// or an exactOutput (negative)
    /// @param priceLimitX96 Swap price limit: if zeroForOne, the price will not be less than this value after swap,
    /// if oneForZero, it will not be greater than this value after swap, as a Q64.96
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The balance change of the grid's token0. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount
    /// @return amount1 The balance change of the grid's token1. When negative, it will reduce the balance
    /// by the exact amount. When positive, it will increase by at least this amount.
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 priceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Places a maker order on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker order
    /// @param data Any data to be passed through to the callback
    /// @return orderId The unique identifier of the order
    function placeMakerOrder(
        IGridParameters.PlaceOrderParameters memory parameters,
        bytes calldata data
    ) external returns (uint256 orderId);

    /// @notice Places maker orders on the grid
    /// @dev The caller of this method receives a callback in the form of
    /// IGridPlaceMakerOrderCallback#gridexPlaceMakerOrderCallback
    /// @param parameters The parameters used to place the maker orders
    /// @param data Any data to be passed through to the callback
    /// @return orderIds The unique identifiers of the orders
    function placeMakerOrderInBatch(
        IGridParameters.PlaceOrderInBatchParameters memory parameters,
        bytes calldata data
    ) external returns (uint256[] memory orderIds);

    /// @notice Settles a maker order
    /// @param orderId The unique identifier of the order
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrder(uint256 orderId) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settle maker order and collect
    /// @param recipient The address to receive the output of the settlement
    /// @param orderId The unique identifier of the order
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0 The amount of token0 that the maker received
    /// @return amount1 The amount of token1 that the maker received
    function settleMakerOrderAndCollect(
        address recipient,
        uint256 orderId,
        bool unwrapWETH9
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Settles maker orders and collects in a batch
    /// @param recipient The address to receive the output of the settlement
    /// @param orderIds The unique identifiers of the orders
    /// @param unwrapWETH9 Whether to unwrap WETH9 to ETH
    /// @return amount0Total The total amount of token0 that the maker received
    /// @return amount1Total The total amount of token1 that the maker received
    function settleMakerOrderAndCollectInBatch(
        address recipient,
        uint256[] memory orderIds,
        bool unwrapWETH9
    ) external returns (uint128 amount0Total, uint128 amount1Total);

    /// @notice For flash swaps. The caller borrows assets and returns them in the callback of the function,
    /// in addition to a fee
    /// @dev The caller of this function receives a callback in the form of IGridFlashCallback#gridexFlashCallback
    /// @param recipient The address which will receive the token0 and token1
    /// @param amount0 The amount of token0 to receive
    /// @param amount1 The amount of token1 to receive
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Collects tokens owed
    /// @param recipient The address to receive the collected fees
    /// @param amount0Requested The maximum amount of token0 to send.
    /// Set to 0 if fees should only be collected in token1.
    /// @param amount1Requested The maximum amount of token1 to send.
    /// Set to 0 if fees should only be collected in token0.
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./GridAddress.sol";

library CallbackValidator {
    /// @dev Validates the `msg.sender` is the canonical grid address for the given parameters
    /// @param gridFactory The address of the grid factory
    /// @param gridKey The grid key to compute the canonical address for the grid
    function validate(address gridFactory, GridAddress.GridKey memory gridKey) internal view {
        // CV_IC: invalid caller
        require(GridAddress.computeAddress(gridFactory, gridKey) == msg.sender, "CV_IC");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridParameters {
    /// @dev Parameters for initializing the grid
    struct InitializeParameters {
        /// @dev The initial price of the grid, as a Q64.96.
        /// Price is represented as an amountToken1/amountToken0 Q64.96 value.
        uint160 priceX96;
        /// @dev The address to receive orders
        address recipient;
        /// @dev Represents the order parameters for token0
        BoundaryLowerWithAmountParameters[] orders0;
        /// @dev Represents the order parameters for token1
        BoundaryLowerWithAmountParameters[] orders1;
    }

    /// @dev Parameters for placing an order
    struct PlaceOrderParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    struct PlaceOrderInBatchParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        BoundaryLowerWithAmountParameters[] orders;
    }

    struct BoundaryLowerWithAmountParameters {
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    /// @dev Status during swap
    struct SwapState {
        /// @dev When true, token0 is swapped for token1, otherwise token1 is swapped for token0
        bool zeroForOne;
        /// @dev The remaining amount of the swap, which implicitly configures
        /// the swap as exact input (positive), or exact output (negative)
        int256 amountSpecifiedRemaining;
        /// @dev The calculated amount to be inputted
        uint256 amountInputCalculated;
        /// @dev The calculated amount of fee to be inputted
        uint256 feeAmountInputCalculated;
        /// @dev The calculated amount to be outputted
        uint256 amountOutputCalculated;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
        uint160 priceLimitX96;
        /// @dev The boundary of the grid
        int24 boundary;
        /// @dev The lower boundary of the grid
        int24 boundaryLower;
        uint160 initializedBoundaryLowerPriceX96;
        uint160 initializedBoundaryUpperPriceX96;
        /// @dev Whether the swap has been completed
        bool stopSwap;
    }

    struct SwapForBoundaryState {
        /// @dev The price indicated by the lower boundary, as a Q64.96
        uint160 boundaryLowerPriceX96;
        /// @dev The price indicated by the upper boundary, as a Q64.96
        uint160 boundaryUpperPriceX96;
        /// @dev The price indicated by the lower or upper boundary, as a Q64.96.
        /// When using token0 to exchange token1, it is equal to boundaryLowerPriceX96,
        /// otherwise it is equal to boundaryUpperPriceX96
        uint160 boundaryPriceX96;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
    }

    struct UpdateBundleForTakerParameters {
        /// @dev The amount to be swapped in to bundle0
        uint256 amountInUsed;
        /// @dev The remaining amount to be swapped in to bundle1
        uint256 amountInRemaining;
        /// @dev The amount to be swapped out to bundle0
        uint128 amountOutUsed;
        /// @dev The remaining amount to be swapped out to bundle1
        uint128 amountOutRemaining;
        /// @dev The amount to be paid to bundle0
        uint128 takerFeeForMakerAmountUsed;
        /// @dev The amount to be paid to bundle1
        uint128 takerFeeForMakerAmountRemaining;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridStructs {
    struct Bundle {
        int24 boundaryLower;
        bool zero;
        uint128 makerAmountTotal;
        uint128 makerAmountRemaining;
        uint128 takerAmountRemaining;
        uint128 takerFeeAmountRemaining;
    }

    struct Boundary {
        uint64 bundle0Id;
        uint64 bundle1Id;
        uint128 makerAmountRemaining;
    }

    struct Order {
        uint64 bundleId;
        address owner;
        uint128 amount;
    }

    struct TokensOwed {
        uint128 token0;
        uint128 token1;
    }

    struct Slot0 {
        uint160 priceX96;
        int24 boundary;
        uint32 blockTimestamp;
        bool unlocked;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title A contract interface for deploying grids
/// @notice A grid constructor must use the interface to pass arguments to the grid
/// @dev This is necessary to ensure there are no constructor arguments in the grid contract.
/// This keeps the grid init code hash constant, allowing a CREATE2 address to be computed on-chain gas-efficiently.
interface IGridDeployer {
    struct Parameters {
        address token0;
        address token1;
        int24 resolution;
        int24 takerFee;
        address priceOracle;
        address weth9;
    }

    /// @notice Returns the grid creation code
    function gridCreationCode() external view returns (bytes memory);

    /// @notice Getter for the arguments used in constructing the grid. These are set locally during grid creation
    /// @dev Retrieves grid parameters, after being called by the grid constructor
    /// @return token0 The first token in the grid, after sorting by address
    /// @return token1 The second token in the grid, after sorting by address
    /// @return resolution The step size in initialized boundaries for a grid created with a given fee
    /// @return takerFee The taker fee, denominated in hundredths of a bip (i.e. 1e-6)
    /// @return priceOracle The address of the price oracle contract
    /// @return weth9 The address of the WETH9 contract
    function parameters()
        external
        view
        returns (
            address token0,
            address token1,
            int24 resolution,
            int24 takerFee,
            address priceOracle,
            address weth9
        );
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