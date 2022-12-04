//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AccessError {
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ParameterError {
    /**
     * @notice Thrown when an invalid parameter is used in a function.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    error InsufficientAllowance(uint required, uint existing);
    error InsufficientBalance(uint required, uint existing);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    struct Data {
        bool initialized;
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Ownable"));
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

library ERC20Helper {
    error FailedTransfer(address from, address to, uint value);

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(address(this), to, value);
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert FailedTransfer(from, to, value);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint x, uint factor) internal pure returns (uint) {
        return x * 10**factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint x, uint factor) internal pure returns (uint) {
        return x / 10**factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x * uint128(10**factor);
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint factor) internal pure returns (uint128) {
        return x / uint128(10**factor);
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int x, uint factor) internal pure returns (int) {
        return x * int(10**factor);
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int x, uint factor) internal pure returns (int) {
        return x / int(10**factor);
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x * int128(int(10**factor));
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint factor) internal pure returns (int128) {
        return x / int128(int(10**factor));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Eth Heap
// Author: Zac Mitton
// License: MIT

library HeapUtil {
    // default max-heap

    uint private constant _ROOT_INDEX = 1;

    struct Data {
        uint128 idCount;
        Node[] nodes; // root is index 1; index 0 not used
        mapping(uint128 => uint) indices; // unique id => node index
    }
    struct Node {
        uint128 id; //use with another mapping to store arbitrary object types
        int128 priority;
    }

    //call init before anything else
    function init(Data storage self) internal {
        if (self.nodes.length == 0) self.nodes.push(Node(0, 0));
    }

    function insert(
        Data storage self,
        uint128 id,
        int128 priority
    ) internal returns (Node memory) {
        //√
        if (self.nodes.length == 0) {
            init(self);
        } // test on-the-fly-init

        Node memory n;

        // MODIFIED: support updates
        extractById(self, id);

        self.idCount++;
        self.nodes.push();
        n = Node(id, priority);
        _bubbleUp(self, n, self.nodes.length - 1);

        return n;
    }

    function extractMax(Data storage self) internal returns (Node memory) {
        //√
        return _extract(self, _ROOT_INDEX);
    }

    function extractById(Data storage self, uint128 id) internal returns (Node memory) {
        //√
        return _extract(self, self.indices[id]);
    }

    //view
    function dump(Data storage self) internal view returns (Node[] memory) {
        //note: Empty set will return `[Node(0,0)]`. uninitialized will return `[]`.
        return self.nodes;
    }

    function getById(Data storage self, uint128 id) internal view returns (Node memory) {
        return getByIndex(self, self.indices[id]); //test that all these return the emptyNode
    }

    function getByIndex(Data storage self, uint i) internal view returns (Node memory) {
        return self.nodes.length > i ? self.nodes[i] : Node(0, 0);
    }

    function getMax(Data storage self) internal view returns (Node memory) {
        return getByIndex(self, _ROOT_INDEX);
    }

    function size(Data storage self) internal view returns (uint) {
        return self.nodes.length > 0 ? self.nodes.length - 1 : 0;
    }

    function isNode(Node memory n) internal pure returns (bool) {
        return n.id > 0;
    }

    //private
    function _extract(Data storage self, uint i) private returns (Node memory) {
        //√
        if (self.nodes.length <= i || i <= 0) {
            return Node(0, 0);
        }

        Node memory extractedNode = self.nodes[i];
        delete self.indices[extractedNode.id];

        Node memory tailNode = self.nodes[self.nodes.length - 1];
        self.nodes.pop();

        if (i < self.nodes.length) {
            // if extracted node was not tail
            _bubbleUp(self, tailNode, i);
            _bubbleDown(self, self.nodes[i], i); // then try bubbling down
        }
        return extractedNode;
    }

    function _bubbleUp(
        Data storage self,
        Node memory n,
        uint i
    ) private {
        //√
        if (i == _ROOT_INDEX || n.priority <= self.nodes[i / 2].priority) {
            _insert(self, n, i);
        } else {
            _insert(self, self.nodes[i / 2], i);
            _bubbleUp(self, n, i / 2);
        }
    }

    function _bubbleDown(
        Data storage self,
        Node memory n,
        uint i
    ) private {
        //
        uint length = self.nodes.length;
        uint cIndex = i * 2; // left child index

        if (length <= cIndex) {
            _insert(self, n, i);
        } else {
            Node memory largestChild = self.nodes[cIndex];

            if (length > cIndex + 1 && self.nodes[cIndex + 1].priority > largestChild.priority) {
                largestChild = self.nodes[++cIndex]; // TEST ++ gets executed first here
            }

            if (largestChild.priority <= n.priority) {
                //TEST: priority 0 is valid! negative ints work
                _insert(self, n, i);
            } else {
                _insert(self, largestChild, i);
                _bubbleDown(self, n, cIndex);
            }
        }
    }

    function _insert(
        Data storage self,
        Node memory n,
        uint i
    ) private {
        //√
        self.nodes[i] = n;
        self.indices[n.id] = i;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU256.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Utility that avoids silent overflow errors.
 *
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SetUtil {
    // ----------------------------------------
    // Uint support
    // ----------------------------------------

    struct UintSet {
        Bytes32Set raw;
    }

    function add(UintSet storage set, uint value) internal {
        add(set.raw, bytes32(value));
    }

    function remove(UintSet storage set, uint value) internal {
        remove(set.raw, bytes32(value));
    }

    function replace(
        UintSet storage set,
        uint value,
        uint newValue
    ) internal {
        replace(set.raw, bytes32(value), bytes32(newValue));
    }

    function contains(UintSet storage set, uint value) internal view returns (bool) {
        return contains(set.raw, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(UintSet storage set, uint position) internal view returns (uint) {
        return uint(valueAt(set.raw, position));
    }

    function positionOf(UintSet storage set, uint value) internal view returns (uint) {
        return positionOf(set.raw, bytes32(value));
    }

    function values(UintSet storage set) internal view returns (uint[] memory) {
        bytes32[] memory store = values(set.raw);
        uint[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Address support
    // ----------------------------------------

    struct AddressSet {
        Bytes32Set raw;
    }

    function add(AddressSet storage set, address value) internal {
        add(set.raw, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal {
        remove(set.raw, bytes32(uint256(uint160(value))));
    }

    function replace(
        AddressSet storage set,
        address value,
        address newValue
    ) internal {
        replace(set.raw, bytes32(uint256(uint160(value))), bytes32(uint256(uint160(newValue))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return contains(set.raw, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint) {
        return length(set.raw);
    }

    function valueAt(AddressSet storage set, uint position) internal view returns (address) {
        return address(uint160(uint256(valueAt(set.raw, position))));
    }

    function positionOf(AddressSet storage set, address value) internal view returns (uint) {
        return positionOf(set.raw, bytes32(uint256(uint160(value))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = values(set.raw);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // ----------------------------------------
    // Core bytes32 support
    // ----------------------------------------

    error PositionOutOfBounds();
    error ValueNotInSet();
    error ValueAlreadyInSet();

    struct Bytes32Set {
        bytes32[] _values;
        mapping(bytes32 => uint) _positions; // Position zero is never used.
    }

    function add(Bytes32Set storage set, bytes32 value) internal {
        if (contains(set, value)) {
            revert ValueAlreadyInSet();
        }

        set._values.push(value);
        set._positions[value] = set._values.length;
    }

    function remove(Bytes32Set storage set, bytes32 value) internal {
        uint position = set._positions[value];
        if (position == 0) {
            revert ValueNotInSet();
        }

        uint index = position - 1;
        uint lastIndex = set._values.length - 1;

        // If the element being deleted is not the last in the values,
        // move the last element to its position.
        if (index != lastIndex) {
            bytes32 lastValue = set._values[lastIndex];

            set._values[index] = lastValue;
            set._positions[lastValue] = position;
        }

        // Remove the last element in the values.
        set._values.pop();
        delete set._positions[value];
    }

    function replace(
        Bytes32Set storage set,
        bytes32 value,
        bytes32 newValue
    ) internal {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        if (contains(set, newValue)) {
            revert ValueAlreadyInSet();
        }

        uint position = set._positions[value];
        uint index = position - 1;

        set._values[index] = newValue;
        set._positions[newValue] = position;
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return set._positions[value] != 0;
    }

    function length(Bytes32Set storage set) internal view returns (uint) {
        return set._values.length;
    }

    function valueAt(Bytes32Set storage set, uint position) internal view returns (bytes32) {
        if (position == 0 || position > set._values.length) {
            revert PositionOutOfBounds();
        }

        uint index = position - 1;

        return set._values[index];
    }

    function positionOf(Bytes32Set storage set, bytes32 value) internal view returns (uint) {
        if (!contains(set, value)) {
            revert ValueNotInSet();
        }

        return set._positions[value];
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return set._values;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/Node.sol";
import "../storage/NodeDefinition.sol";

/// @title Module for managing nodes
interface IOracleManagerModule {
    function registerNode(
        bytes32[] memory parents,
        NodeDefinition.NodeType nodeType,
        bytes memory parameters
    ) external returns (bytes32);

    function getNodeId(
        bytes32[] memory parents,
        NodeDefinition.NodeType nodeType,
        bytes memory parameters
    ) external returns (bytes32);

    function getNode(bytes32 nodeId) external view returns (NodeDefinition.Data memory);

    function process(bytes32 nodeId) external view returns (Node.Data memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Node {
    struct Data {
        int256 price;
        uint timestamp;
        uint volatilityScore;
        uint liquidityScore;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library NodeDefinition {
    enum NodeType {
        NONE,
        REDUCER,
        EXTERNAL,
        CHAINLINK,
        PYTH
    }

    struct Data {
        bytes32[] parents;
        NodeType nodeType;
        bytes parameters;
    }

    function load(bytes32 id) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("Node", id));
        assembly {
            data.slot := s
        }
    }

    function create(Data memory nodeDefinition) internal returns (NodeDefinition.Data storage self, bytes32 id) {
        id = getId(nodeDefinition);

        self = load(id);

        self.parents = nodeDefinition.parents;
        self.nodeType = nodeDefinition.nodeType;
        self.parameters = nodeDefinition.parameters;
    }

    function getId(Data memory nodeDefinition) internal pure returns (bytes32) {
        return keccak256(abi.encode(nodeDefinition.parents, nodeDefinition.nodeType, nodeDefinition.parameters));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface an aggregator needs to adhere.
interface IAggregatorV3Interface {
    /// @notice decimals used by the aggregator
    function decimals() external view returns (uint8);

    /// @notice aggregator's description
    function description() external view returns (string memory);

    /// @notice aggregator's version
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    /// @notice get's round data for requested id
    function getRoundData(uint80 id)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    /// @notice get's latest round data
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC165.sol";

/// @title Interface a Market needs to adhere.
interface IMarket is IERC165 {
    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice returns amount of USD that the market would try to mint if everything was withdrawn
    function reportedDebt(uint128 marketId) external view returns (uint);

    /// @notice returns the amount of collateral which should (in addition to `reportedDebt`) be prevented from withdrawing from this market
    /// if your market does not require locking, set this to `0`
    function locked(uint128 marketId) external view returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Module for allowing markets to directly increase their credit capacity by providing their own collateral.
 */
interface IMarketCollateralModule {
    /**
     * @notice Allows a market to deposit collateral.
     */
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint amount
    ) external;

    /**
     * @notice Allows a market to withdraw collateral that it has previously deposited.
     */
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint amount
    ) external;

    /**
     * @notice Allow the system owner to configure the maximum amount of a given collateral type that a specified market is allowed to deposit.
     */
    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint amount
    ) external;

    /**
     * @notice Return the total maximum amount of a given collateral type that a specified market is allowed to deposit.
     */
    function getMaximumMarketCollateral(uint128 marketId, address collateralType) external returns (uint);

    /**
     * @notice Return the total amount of a given collateral type that a specified market has deposited.
     */
    function getMarketCollateralAmount(uint128 marketId, address collateralType) external returns (uint);

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is deposited to market `marketId` by `sender`.
     */
    event MarketCollateralDeposited(
        uint128 indexed marketId,
        address indexed collateralType,
        uint tokenAmount,
        address indexed sender
    );

    /**
     * @notice Emitted when `amount` of collateral of type `collateralType` is withdrawn from market `marketId` by `sender`.
     */
    event MarketCollateralWithdrawn(
        uint128 indexed marketId,
        address indexed collateralType,
        uint tokenAmount,
        address indexed sender
    );

    event MaximumMarketCollateralConfigured(
        uint128 indexed marketId,
        address indexed collateralType,
        uint systemAmount,
        address indexed sender
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/token/ERC20Helper.sol";

import "../../interfaces/IMarketCollateralModule.sol";
import "../../storage/Market.sol";

/**
 * @title Module for allowing markets to directly increase their credit capacity by providing their own collateral.
 * @dev See IMarketCollateralModule.
 */
contract MarketCollateralModule is IMarketCollateralModule {
    using ERC20Helper for address;
    using CollateralConfiguration for CollateralConfiguration.Data;

    error InsufficientMarketCollateralDepositable(uint128 marketId, address collateralType, uint tokenAmountToDeposit);
    error InsufficientMarketCollateralWithdrawable(uint128 marketId, address collateralType, uint tokenAmountToWithdraw);

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function depositMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint tokenAmount
    ) public override {
        Market.Data storage marketData = Market.load(marketId);

        uint systemAmount = CollateralConfiguration.load(collateralType).convertTokenToSystemAmount(tokenAmount);

        // Ensure the sender is the market address associated with the specified marketId
        if (msg.sender != marketData.marketAddress) revert AccessError.Unauthorized(msg.sender);

        uint maxDepositable = marketData.maximumDepositableD18[collateralType];
        uint depositedCollateralEntryIndex = _findOrCreateDepositEntryIndex(marketData, collateralType);
        Market.DepositedCollateral storage collateralEntry = marketData.depositedCollateral[depositedCollateralEntryIndex];

        // Ensure that depositing this amount will not exceed the maximum amount allowed for the market
        if (collateralEntry.amountD18 + systemAmount > maxDepositable)
            revert InsufficientMarketCollateralDepositable(marketId, collateralType, tokenAmount);

        // Transfer the collateral into the system and account for it
        collateralType.safeTransferFrom(marketData.marketAddress, address(this), tokenAmount);
        collateralEntry.amountD18 += systemAmount;

        emit MarketCollateralDeposited(marketId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function withdrawMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint tokenAmount
    ) public override {
        Market.Data storage marketData = Market.load(marketId);

        uint systemAmount = CollateralConfiguration.load(collateralType).convertTokenToSystemAmount(tokenAmount);

        // Ensure the sender is the market address associated with the specified marketId
        if (msg.sender != marketData.marketAddress) revert AccessError.Unauthorized(msg.sender);

        uint depositedCollateralEntryIndex = _findOrCreateDepositEntryIndex(marketData, collateralType);
        Market.DepositedCollateral storage collateralEntry = marketData.depositedCollateral[depositedCollateralEntryIndex];

        // Ensure that the market is not withdrawing more collateral than it has deposited
        if (systemAmount > collateralEntry.amountD18) {
            revert InsufficientMarketCollateralWithdrawable(marketId, collateralType, tokenAmount);
        }

        // Transfer the collateral out of the system and account for it
        collateralEntry.amountD18 -= systemAmount;
        collateralType.safeTransfer(marketData.marketAddress, tokenAmount);

        emit MarketCollateralWithdrawn(marketId, collateralType, tokenAmount, msg.sender);
    }

    /**
     * @dev Returns the index of the relevant deposited collateral entry for the given market and collateral type.
     */
    function _findOrCreateDepositEntryIndex(Market.Data storage marketData, address collateralType)
        internal
        returns (uint depositedCollateralEntryIndex)
    {
        Market.DepositedCollateral[] storage depositedCollateral = marketData.depositedCollateral;
        for (uint i = 0; i < depositedCollateral.length; i++) {
            Market.DepositedCollateral storage depositedCollateralEntry = depositedCollateral[i];
            if (depositedCollateralEntry.collateralType == collateralType) {
                return i;
            }
        }

        // If this function hasn't returned an index yet, create a new deposited collateral entry and return its index.
        marketData.depositedCollateral.push(Market.DepositedCollateral(collateralType, 0));
        return marketData.depositedCollateral.length - 1;
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function configureMaximumMarketCollateral(
        uint128 marketId,
        address collateralType,
        uint amount
    ) external override {
        OwnableStorage.onlyOwner();

        Market.Data storage marketData = Market.load(marketId);
        marketData.maximumDepositableD18[collateralType] = amount;

        emit MaximumMarketCollateralConfigured(marketId, collateralType, amount, msg.sender);
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function getMarketCollateralAmount(uint128 marketId, address collateralType)
        external
        view
        override
        returns (uint collateralAmountD18)
    {
        Market.Data storage marketData = Market.load(marketId);
        Market.DepositedCollateral[] storage depositedCollateral = marketData.depositedCollateral;
        for (uint i = 0; i < depositedCollateral.length; i++) {
            Market.DepositedCollateral storage depositedCollateralEntry = depositedCollateral[i];
            if (depositedCollateralEntry.collateralType == collateralType) {
                return depositedCollateralEntry.amountD18;
            }
        }
    }

    /**
     * @inheritdoc IMarketCollateralModule
     */
    function getMaximumMarketCollateral(uint128 marketId, address collateralType) external view override returns (uint) {
        Market.Data storage marketData = Market.load(marketId);
        return marketData.maximumDepositableD18[collateralType];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";
import "@synthetixio/oracle-manager/contracts/interfaces/IOracleManagerModule.sol";
import "@synthetixio/oracle-manager/contracts/storage/Node.sol";
import "@synthetixio/core-contracts/contracts/interfaces/IERC20.sol";

import "./OracleManager.sol";

import "../interfaces/external/IAggregatorV3Interface.sol";

library CollateralConfiguration {
    using SetUtil for SetUtil.AddressSet;
    using DecimalMath for uint256;

    error CollateralNotFound();
    error CollateralDepositDisabled(address collateralType);
    error InsufficientCollateralRatio(uint collateralValue, uint debt, uint ratio, uint minRatio);
    error InsufficientDelegation(uint minDelegation);

    struct Data {
        /// must be true for staking or collateral delegation
        bool depositingEnabled;
        /// accounts cannot mint sUSD if their debt brings their cratio below this value
        uint issuanceRatioD18;
        /// accounts below the ratio specified here are immediately liquidated
        uint liquidationRatioD18;
        /// amount of token to award when an account is liquidated with this collateral type
        uint liquidationRewardD18;
        /// address which reports the current price of the collateral
        bytes32 oracleNodeId;
        /// address which should be used for transferring this collateral
        address tokenAddress;
        /// minimum delegation amount (other than 0), to prevent sybil/attacks on the system due to new entries.
        uint minDelegationD18;
    }

    function load(address token) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("CollateralConfiguration", token));
        assembly {
            data.slot := s
        }
    }

    function loadAvailableCollaterals() internal pure returns (SetUtil.AddressSet storage data) {
        bytes32 s = keccak256(abi.encode("CollateralConfiguration_availableCollaterals"));
        assembly {
            data.slot := s
        }
    }

    function set(Data memory config) internal {
        SetUtil.AddressSet storage collateralTypes = loadAvailableCollaterals();

        if (!collateralTypes.contains(config.tokenAddress)) {
            collateralTypes.add(config.tokenAddress);
        }

        if (config.minDelegationD18 < config.liquidationRewardD18) {
            revert ParameterError.InvalidParameter("minDelegation", "must be greater than liquidationReward");
        }

        Data storage storedConfig = load(config.tokenAddress);

        storedConfig.tokenAddress = config.tokenAddress;
        storedConfig.issuanceRatioD18 = config.issuanceRatioD18;
        storedConfig.liquidationRatioD18 = config.liquidationRatioD18;
        storedConfig.oracleNodeId = config.oracleNodeId;
        storedConfig.liquidationRewardD18 = config.liquidationRewardD18;
        storedConfig.minDelegationD18 = config.minDelegationD18;
        storedConfig.depositingEnabled = config.depositingEnabled;
    }

    function collateralEnabled(address token) internal view {
        if (!load(token).depositingEnabled) {
            revert CollateralDepositDisabled(token);
        }
    }

    function requireSufficientDelegation(address token, uint amountD18) internal view {
        CollateralConfiguration.Data storage config = load(token);

        uint minDelegationD18 = config.minDelegationD18;

        if (minDelegationD18 == 0) {
            minDelegationD18 = config.liquidationRewardD18;
        }

        if (amountD18 < minDelegationD18) {
            revert InsufficientDelegation(minDelegationD18);
        }
    }

    function getCollateralPrice(Data storage self) internal view returns (uint) {
        OracleManager.Data memory oracleManager = OracleManager.load();
        Node.Data memory node = IOracleManagerModule(oracleManager.oracleManagerAddress).process(self.oracleNodeId);

        return uint(node.price);
    }

    function verifyIssuanceRatio(
        Data storage self,
        uint debtD18,
        uint collateralValueD18
    ) internal view {
        if (debtD18 != 0 && collateralValueD18.divDecimal(debtD18) < self.issuanceRatioD18) {
            revert InsufficientCollateralRatio(
                collateralValueD18,
                debtD18,
                collateralValueD18.divDecimal(debtD18),
                self.issuanceRatioD18
            );
        }
    }

    function convertTokenToSystemAmount(Data storage self, uint tokenAmount) internal view returns (uint) {
        // this extra condition is to prevent potentially malicious untrusted code from being executed on the next statement
        if (self.tokenAddress == address(0)) {
            revert CollateralNotFound();
        }

        return (tokenAmount * DecimalMath.UNIT) / (10**IERC20(self.tokenAddress).decimals());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";
import "@synthetixio/core-contracts/contracts/errors/ParameterError.sol";

import "./DistributionActor.sol";

/**
 * @title Data structure that allows you to track some global value, distributed amongst a set of actors.
 *
 * The total value can be scaled with a valuePerShare multiplier, and individual actor shares can be calculated as their amount of shares times this multiplier.
 *
 * Furthermore, changes in the value of individual actors can be tracked since their last update, by keeping track of the value of the multiplier, per user, upon each interaction. See DistributionActor.lastValuePerShare.
 *
 * A distribution is similar to a ScalableMapping, but it has the added functionality of being able to remember the previous value of the scalar multiplier for each actor.
 *
 * Whenever the shares of an actor of the distribution is updated, you get information about how the actor's total value changed since it was last updated.
 */
library Distribution {
    using SafeCastU128 for uint128;
    using SafeCastU256 for uint256;
    using SafeCastI128 for int128;
    using SafeCastI256 for int256;
    using DecimalMath for int256;

    /**
     * @dev Thrown when an attempt is made to distribute value to a distribution
     * with no shares.
     */
    error EmptyDistribution();

    struct Data {
        /**
         * @dev The total number of shares in the distribution.
         */
        uint128 totalSharesD18;
        /**
         * @dev The value per share of the distribution, represented as a high precision decimal.
         */
        int128 valuePerShareD27;
        /**
         * @dev Tracks individual actor information, such as how many shares an actor has, their lastValuePerShare, etc.
         */
        mapping(bytes32 => DistributionActor.Data) actorInfo;
    }

    /**
     * @dev Inflates or deflates the total value of the distribution by the given value.
     *
     * The value being distributed ultimately modifies the distribution's valuePerShare.
     */
    function distributeValue(Data storage dist, int valueD18) internal {
        if (valueD18 == 0) {
            return;
        }

        uint totalSharesD18 = dist.totalSharesD18;

        if (totalSharesD18 == 0) {
            revert EmptyDistribution();
        }

        int valueD45 = valueD18 * DecimalMath.UNIT_PRECISE_INT;
        int deltaValuePerShareD27 = valueD45 / totalSharesD18.toInt();

        dist.valuePerShareD27 += deltaValuePerShareD27.to128();
    }

    /**
     * @dev Updates an actor's number of shares in the distribution to the specified amount.
     *
     * Whenever an actor's shares are changed in this way, we record the distribution's current valuePerShare into the actor's lastValuePerShare record.
     *
     * Returns the the amount by which the actors value changed since the last update.
     */
    function setActorShares(
        Data storage dist,
        bytes32 actorId,
        uint newActorSharesD18
    ) internal returns (int valueChangeD18) {
        valueChangeD18 = _getActorValueChange(dist, actorId);

        DistributionActor.Data storage actor = dist.actorInfo[actorId];

        uint128 sharesUint128D18 = newActorSharesD18.to128();
        dist.totalSharesD18 = dist.totalSharesD18 + sharesUint128D18 - actor.sharesD18;

        actor.sharesD18 = sharesUint128D18;

        actor.lastValuePerShareD27 = newActorSharesD18 == 0 ? int128(0) : dist.valuePerShareD27;
    }

    /**
     * @dev Updates an actor's lastValuePerShare to the distribution's current valuePerShare, and
     * returns the change in value for the actor, since their last update.
     */
    function accumulateActor(Data storage dist, bytes32 actorId) internal returns (int valueChangeD18) {
        return setActorShares(dist, actorId, getActorShares(dist, actorId));
    }

    /**
     * @dev Calculates how much an actor's value has changed since its shares were last updated.
     *
     * This change is calculated as:
     * Since `value = valuePerShare * shares`,
     * then `delta_value = valuePerShare_now * shares - valuePerShare_then * shares`,
     * which is `(valuePerShare_now - valuePerShare_then) * shares`,
     * or just `delta_valuePerShare * shares`.
     */
    function _getActorValueChange(Data storage dist, bytes32 actorId) private view returns (int valueChangeD18) {
        DistributionActor.Data storage actor = dist.actorInfo[actorId];
        int deltaValuePerShareD27 = dist.valuePerShareD27 - actor.lastValuePerShareD27;

        int changedValueD45 = deltaValuePerShareD27 * actor.sharesD18.toInt();
        valueChangeD18 = changedValueD45 / DecimalMath.UNIT_PRECISE_INT;
    }

    /**
     * @dev Returns the number of shares owned by an actor in the distribution.
     */
    function getActorShares(Data storage dist, bytes32 actorId) internal view returns (uint sharesD18) {
        return dist.actorInfo[actorId].sharesD18;
    }

    function getValuePerShare(Data storage self) internal view returns (int) {
        return int(self.valuePerShareD27).downscale(DecimalMath.PRECISION_FACTOR);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library DistributionActor {
    struct Data {
        /**
         * @dev The actor's current number of shares in the associated distribution.
         */
        uint128 sharesD18;
        /**
         * @dev The value per share that the associated distribution had at the time that the actor's number of shares was last modified.
         *
         * Note: This is also a high precision decimal. See Distribution.valuePerShare.
         */
        int128 lastValuePerShareD27;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@synthetixio/core-contracts/contracts/utils/SetUtil.sol";
import "@synthetixio/core-contracts/contracts/utils/HeapUtil.sol";

import "./Distribution.sol";
import "./CollateralConfiguration.sol";
import "./MarketPoolInfo.sol";

import "../interfaces/external/IMarket.sol";

/**
 * @title Connects external contracts that implement the `IMarket` interface to the system.
 *
 * Pools provide credit capacity (collateral) to the markets, and are reciprocally exposed to the associated market's debt.
 *
 * The Market object's main responsibility is to track collateral provided by the pools that support it, and to trace their debt back to such pools.
 */
library Market {
    using Distribution for Distribution.Data;
    using HeapUtil for HeapUtil.Data;
    using DecimalMath for uint256;
    using DecimalMath for uint128;
    using DecimalMath for int256;
    using DecimalMath for int128;

    using SafeCastU256 for uint256;
    using SafeCastU128 for uint128;
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;

    error MarketNotFound(uint128 marketId);

    struct Data {
        /**
         * @dev Numeric identifier for the market. Must be unique.
         * @dev There cannot be a market with id zero (See MarketCreator.create()). Id zero is used as a null market reference.
         */
        uint128 id;
        /**
         * @dev Address for the external contract that implements the `IMarket` interface, which this Market objects connects to.
         *
         * Note: This object is how the system tracks the market. The actual market is external to the system, i.e. its own contract.
         */
        address marketAddress;
        /**
         * @dev Issuance can be seen as how much USD the Market "has issued", printed, or has asked the system to mint on its behalf.
         *
         * More precisely it can be seen as the net difference between the USD burnt and the USD minted by the market.
         *
         * More issuance means that the market owes more USD to the system.
         *
         * A market burns USD when users deposit it in exchange for some asset that the market offers.
         * The Market object calls `MarketManager.depositUSD()`, which burns the USD, and decreases its issuance.
         *
         * A market mints USD when users return the asset that the market offered and thus withdraw their USD.
         * The Market object calls `MarketManager.withdrawUSD()`, which mints the USD, and increases its issuance.
         *
         * Instead of burning, the Market object could transfer USD to and from the MarketManager, but minting and burning takes the USD out of circulation, which doesn't affect `totalSupply`, thus simplifying accounting.
         *
         * How much USD a market can mint depends on how much credit capacity is given to the market by the pools that support it, and reflected in `Market.capacity`.
         *
         */
        int128 netIssuanceD18;
        /**
         * @dev The total amount of USD that the market could withdraw if it were to immediately unwrap all its positions.
         *
         * The Market's credit capacity increases when the market burns USD, i.e. when it deposits USD in the MarketManager.
         *
         * It decreases when the market mints USD, i.e. when it withdraws USD from the MarketManager.
         *
         * The Market's credit capacity also depends on how much credit is given to it by the pools that support it.
         *
         * The Market's credit capacity also has a dependency on the external market reported debt as it will respond to that debt (and hence change the credit capacity if it increases or decreases)
         *
         */
        uint128 creditCapacityD18;
        /**
         * @dev The total balance that the market had the last time that its debt was distributed.
         *
         * A Market's debt is distributed when the reported debt of its associated external market is rolled into the pools that provide credit capacity to it.
         */
        int128 lastDistributedMarketBalanceD18;
        /**
         * @dev A heap of pools for which the market has not yet hit its maximum credit capacity.
         *
         * The heap is ordered according to this market's max value per share setting in the pools that provide credit capacity to it. See `MarketConfiguration.maxDebtShareValue`.
         *
         * The heap's getMax() and extractMax() functions allow us to retrieve the pool with the lowest `maxDebtShareValue`, since its elements are inserted and prioritized by negating their `maxDebtShareValue`.
         *
         * Lower max values per share are on the top of the heap. I.e. the heap could look like this:
         *  .    -1
         *      / \
         *     /   \
         *    -2    \
         *   / \    -3
         * -4   -5
         *
         * TL;DR: This data structure allows us to easily find the pool with the lowest or "most vulnerable" max value per share and process it if its actual value per share goes beyond this limit.
         */
        HeapUtil.Data inRangePools;
        /**
         * @dev A heap of pools for which the market has hit its maximum credit capacity.
         *
         * Used to reconnect pools to the market, when it falls back below its maximum credit capacity.
         *
         * See inRangePools for why a heap is used here.
         */
        HeapUtil.Data outRangePools;
        /**
         * @dev A market's debt distribution connects markets to the debt distribution chain, in this case pools. Pools are actors in the market's debt distribution, where the amount of shares they possess depends on the amount of collateral they provide to the market. The value per share of this distribution depends on the total debt or balance of the market (netIssuance + reportedDebt).
         *
         * The debt distribution chain will move debt from the market into its connected pools.
         *
         * Actors: Pools.
         * Shares: The USD denominated credit capacity that the pool provides to the market.
         * Value per share: Debt per dollar of credit that the associated external market accrues.
         *
         */
        Distribution.Data poolsDebtDistribution;
        /**
         * @dev Additional info needed to remember pools when they are removed from the distribution (or subsequently re-added).
         */
        mapping(uint128 => MarketPoolInfo.Data) pools;
        /**
         * @dev Array of entries of market provided collateral.
         *
         * Markets may obtain additional liquidity, beyond that coming from stakers, by providing their own collateral.
         *
         */
        DepositedCollateral[] depositedCollateral;
        /**
         * @dev The maximum amount of market provided collateral, per type, that this market can deposit.
         */
        mapping(address => uint) maximumDepositableD18;
    }

    /**
     * @dev Data structure that allows the Market to track the amount of market provided collateral, per type.
     */
    struct DepositedCollateral {
        address collateralType;
        uint amountD18;
    }

    /**
     * @dev Returns the market stored at the specified market id.
     */
    function load(uint128 id) internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("Market", id));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Queries the external market contract for the amount of debt it has issued.
     *
     * The reported debt of a market represents the amount of USD that the market would ask the system to mint, if all of its positions were to be immediately closed.
     *
     * The reported debt of a market is collateralized by the assets in the pools which back it.
     *
     * See the `IMarket` interface.
     */
    function getReportedDebt(Data storage self) internal view returns (uint) {
        return IMarket(self.marketAddress).reportedDebt(self.id);
    }

    /**
     * @dev Queries the market for the amount of collateral which should be prevented from withdrawal.
     */
    function getLockedCreditCapacity(Data storage self) internal view returns (uint) {
        return IMarket(self.marketAddress).locked(self.id);
    }

    /**
     * @dev Returns the total debt of the market.
     *
     * A market's total debt represents its debt plus its issuance, and thus represents the total outstanding debt of the market.
     *
     * Note: it also takes into account the deposited collateral value. See note in  getDepositedCollateralValue()
     *
     * Example:
     * (1 EUR = 1.11 USD)
     * If an Euro market has received 100 USD to mint 90 EUR, its reported debt is 90 EUR or 100 USD, and its issuance is -100 USD.
     * Thus, its total balance is 100 USD of reported debt minus 100 USD of issuance, which is 0 USD.
     *
     * Additionally, the market's totalDebt might be affected by price fluctuations via reportedDebt, or fees.
     *
     */
    function totalDebt(Data storage self) internal view returns (int) {
        return getReportedDebt(self).toInt() + self.netIssuanceD18 - getDepositedCollateralValue(self).toInt();
    }

    /**
     * @dev Returns the USD value for the total amount of collateral provided by the market itself.
     *
     * Note: This is not credit capacity provided by stakers through pools.
     */
    function getDepositedCollateralValue(Data storage self) internal view returns (uint) {
        uint totalDepositedCollateralValueD18 = 0;

        // Sweep all DepositedCollateral entries and aggregate their USD value.
        for (uint i = 0; i < self.depositedCollateral.length; i++) {
            DepositedCollateral memory entry = self.depositedCollateral[i];
            CollateralConfiguration.Data storage collateralConfiguration = CollateralConfiguration.load(
                entry.collateralType
            );

            uint priceD18 = CollateralConfiguration.getCollateralPrice(collateralConfiguration);

            totalDepositedCollateralValueD18 += priceD18.mulDecimal(entry.amountD18);
        }

        return totalDepositedCollateralValueD18;
    }

    /**
     * @dev Returns the amount of credit capacity that a certain pool provides to the market.

     * This credit capacity is obtained by reading the amount of shares that the pool has in the market's debt distribution, which represents the amount of USD denominated credit capacity that the pool has provided to the market.
     */
    function getPoolCreditCapacity(Data storage self, uint128 poolId) internal view returns (uint) {
        return self.poolsDebtDistribution.getActorShares(bytes32(uint(poolId)));
    }

    /**
     * @dev Given an amount of shares that represent USD credit capacity from a pool, and a maximum value per share, returns the potential contribution to credit capacity that these shares could accrue, if their value per share was to hit the maximum.
     *
     * The resulting value is calculated multiplying the amount of creditCapacity provided by the pool by the delta between the maxValue per share vs current value.
     *
     * This function is used when the Pools are rebalanced to adjust each pool credit capacity based on a change in the amount of shares provided and/or a new maxValue per share
     *
     */
    function getCreditCapacityContribution(
        Data storage self,
        uint creditCapacitySharesD18,
        int maxShareValueD18
    ) internal view returns (uint contributionD18) {
        // Determine how much the current value per share deviates from the maximum.
        uint deltaValuePerShareD18 = (maxShareValueD18 - self.poolsDebtDistribution.getValuePerShare()).toUint();

        return deltaValuePerShareD18.mulDecimal(creditCapacitySharesD18);
    }

    /**
     * @dev Returns true if the market's current capacity is below the amount of locked capacity.
     *
     */
    function isCapacityLocked(Data storage self) internal view returns (bool) {
        return self.creditCapacityD18 < getLockedCreditCapacity(self);
    }

    /**
     * @dev Gets any outstanding debt. Do not call this method except in tests
     *
     * Note: This function should only be used in tests!
     */
    // solhint-disable-next-line private-vars-leading-underscore, func-name-mixedcase
    function _testOnly_getOutstandingDebt(Data storage self, uint128 poolId) internal returns (int debtChangeD18) {
        return self.pools[poolId].pendingDebtD18.toInt() + self.poolsDebtDistribution.accumulateActor(bytes32(uint(poolId)));
    }

    /**
     * @dev Returns the debt value per share
     */
    function getDebtPerShare(Data storage self) internal view returns (int debtPerShareD18) {
        return self.poolsDebtDistribution.getValuePerShare();
    }

    /**
     * @dev Wrapper that adjusts a pool's shares in the market's credit capacity, making sure that the market's outstanding debt is first passed on to its connected pools.
     *
     * Called by a pool when it distributes its debt.
     *
     */
    function rebalancePools(
        uint128 marketId,
        uint128 poolId,
        int maxDebtShareValueD18, // (in USD)
        uint newCreditCapacityD18 // in collateralValue (USD)
    ) internal returns (int debtChangeD18) {
        Data storage self = load(marketId);

        if (self.marketAddress == address(0)) {
            revert MarketNotFound(marketId);
        }

        // Iter avoids griefing - MarketManager can call this with user specified iters and thus clean up a grieved market.
        distributeDebtToPools(self, 9999999999);

        return adjustPoolShares(self, poolId, newCreditCapacityD18, maxDebtShareValueD18);
    }

    /**
     * @dev Called by pools when they modify the credit capacity provided to the market, as well as the maximum value per share they tolerate for the market.
     *
     * These two settings affect the market in the following ways:
     * - Updates the pool's shares in `poolsDebtDistribution`.
     * - Moves the pool in and out of inRangePools/outRangePools.
     * - Updates the market credit capacity property.
     */
    function adjustPoolShares(
        Data storage self,
        uint128 poolId,
        uint newCreditCapacityD18,
        int newPoolMaxShareValueD18
    ) internal returns (int debtChangeD18) {
        uint oldCreditCapacityD18 = getPoolCreditCapacity(self, poolId);
        int oldPoolMaxShareValueD18 = -self.inRangePools.getById(poolId).priority;

        // Sanity checks
        // require(oldPoolMaxShareValue == 0, "value is not 0");
        // require(newPoolMaxShareValue == 0, "new pool max share value is in fact set");

        self.pools[poolId].creditCapacityAmountD18 = newCreditCapacityD18.to128();

        int128 valuePerShareD18 = self.poolsDebtDistribution.getValuePerShare().to128();

        if (newPoolMaxShareValueD18 < valuePerShareD18) {
            // this will ensure calculations below can correctly gauge shares changes
            newCreditCapacityD18 = 0;
            self.inRangePools.extractById(poolId);
            self.outRangePools.insert(poolId, newPoolMaxShareValueD18.to128());
        } else {
            self.inRangePools.insert(poolId, -newPoolMaxShareValueD18.to128());
            self.outRangePools.extractById(poolId);
        }

        int changedValueD18 = self.poolsDebtDistribution.setActorShares(bytes32(uint(poolId)), newCreditCapacityD18);
        debtChangeD18 = self.pools[poolId].pendingDebtD18.toInt() + changedValueD18;
        self.pools[poolId].pendingDebtD18 = 0;

        // recalculate market capacity
        if (newPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 += getCreditCapacityContribution(self, newCreditCapacityD18, newPoolMaxShareValueD18)
                .to128();
        }

        if (oldPoolMaxShareValueD18 > valuePerShareD18) {
            self.creditCapacityD18 -= getCreditCapacityContribution(self, oldCreditCapacityD18, oldPoolMaxShareValueD18)
                .to128();
        }
    }

    /**
     * @dev Moves debt from the market into the pools that connect to it.
     *
     * This function should be called before any of the pools' shares are modified in `poolsDebtDistribution`.
     *
     * Note: The parameter `maxIter` is used as an escape hatch to discourage griefing.
     */
    function distributeDebtToPools(Data storage self, uint maxIter) internal {
        // Get the current and last distributed market balances.
        // Note: The last distributed balance will be cached within this function's execution.
        int256 targetBalanceD18 = totalDebt(self);
        int256 outstandingBalanceD18 = targetBalanceD18 - self.lastDistributedMarketBalanceD18;

        (, bool exhausted) = _bumpPools(self, outstandingBalanceD18, maxIter);

        if (!exhausted && self.poolsDebtDistribution.totalSharesD18 > 0) {
            // cannot use `outstandingBalance` here because `self.lastDistributedMarketBalance`
            // may have changed after calling the bump functions above
            self.poolsDebtDistribution.distributeValue(targetBalanceD18 - self.lastDistributedMarketBalanceD18);
            self.lastDistributedMarketBalanceD18 = targetBalanceD18.to128();
        }
    }

    /**
     * @dev Determine the target valuePerShare of the poolsDebtDistribution, given the value that is yet to be distributed.
     */
    function _getTargetValuePerShare(Market.Data storage self, int valueToDistributeD18)
        private
        view
        returns (int targetValuePerShareD18)
    {
        return
            self.poolsDebtDistribution.getValuePerShare() +
            valueToDistributeD18.divDecimal(self.poolsDebtDistribution.totalSharesD18.toInt());
    }

    /**
     * @dev Finds pools for which this market's max value per share limit is hit, distributes their debt, and disconnects the market from them.
     *
     * The debt is distributed up to the limit of the max value per share that the pool tolerates on the market.
     */
    function _bumpPools(
        Data storage self,
        int maxDistributedD18,
        uint maxIter
    ) private returns (int actuallyDistributedD18, bool exhausted) {
        if (maxDistributedD18 == 0 || self.poolsDebtDistribution.totalSharesD18 == 0) {
            return (0, false);
        }

        // Determine the direction based on the amount to be distributed.
        int128 k;
        HeapUtil.Data storage fromHeap;
        HeapUtil.Data storage toHeap;
        if (maxDistributedD18 > 0) {
            k = 1;
            fromHeap = self.inRangePools;
            toHeap = self.outRangePools;
        } else {
            k = -1;
            fromHeap = self.outRangePools;
            toHeap = self.inRangePools;
        }

        // Note: This loop should rarely execute its main body. When it does, it only executes once for each pool that exceeds the limit since `distributeValue` is not run for most pools. Thus, market users are not hit with any overhead as a result of this.
        uint iters;
        for (iters = 0; iters < maxIter; iters++) {
            // Exit if there are no in range pools.
            if (fromHeap.size() == 0) {
                break;
            }

            // Identify the pool with the lowest maximum value per share.
            HeapUtil.Node memory edgePool = fromHeap.getMax();

            // Exit if the lowest max value per share does not hit the limit.
            // Note: `-edgePool.priority` is actually the max value per share limit of the pool
            if (-edgePool.priority >= k * _getTargetValuePerShare(self, (maxDistributedD18 - actuallyDistributedD18))) {
                break;
            }

            // The pool has hit its maximum value per share and needs to be removed.
            // Note: No need to update capacity because pool max share value = valuePerShare when this happens.
            _togglePool(fromHeap, toHeap);

            // Distribute the market's debt to the limit, i.e. for that which exceeds the maximum value per share.
            int debtToLimitD18 = self.poolsDebtDistribution.totalSharesD18.toInt().mulDecimal(
                -k * edgePool.priority - self.poolsDebtDistribution.getValuePerShare() // Diff between current value and max value per share.
            );
            self.poolsDebtDistribution.distributeValue(debtToLimitD18);

            // Update the global distributed and outstanding balances with the debt that was just distributed.
            actuallyDistributedD18 += debtToLimitD18;

            // Detach the market from this pool by removing the pool's shares from the market.
            // The pool will remain "detached" until the pool manager specifies a new poolsDebtDistribution.
            if (maxDistributedD18 > 0) {
                require(
                    self.poolsDebtDistribution.getActorShares(bytes32(uint(edgePool.id))) > 0,
                    "no shares before actor removal"
                );

                uint newPoolDebtD18 = self.poolsDebtDistribution.setActorShares(bytes32(uint(edgePool.id)), 0).toUint();
                self.pools[edgePool.id].pendingDebtD18 += newPoolDebtD18.to128();
            } else {
                require(
                    self.poolsDebtDistribution.getActorShares(bytes32(uint(edgePool.id))) == 0,
                    "actor has shares before add"
                );

                self.poolsDebtDistribution.setActorShares(
                    bytes32(uint(edgePool.id)),
                    self.pools[edgePool.id].creditCapacityAmountD18
                );
            }
        }

        // Record the accumulated distributed balance.
        self.lastDistributedMarketBalanceD18 += actuallyDistributedD18.to128();

        exhausted = iters == maxIter;
    }

    /**
     * @dev Moves a pool from one heap into another.
     */
    function _togglePool(HeapUtil.Data storage from, HeapUtil.Data storage to) private {
        HeapUtil.Node memory node = from.extractMax();
        to.insert(node.id, -node.priority);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Stores information for specific actors in a Distribution.
 */
library MarketPoolInfo {
    struct Data {
        /**
         * @dev . Needed to re-add the pool to the distribution when going back in range
         */
        uint128 creditCapacityAmountD18;
        /**
         * @dev The amount of debt the pool has which hasn't been passed down the debt distribution chain yet
         */
        uint128 pendingDebtD18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Represents Oracle Manager
 */
library OracleManager {
    struct Data {
        /**
         * @dev The oracle manager address.
         */
        address oracleManagerAddress;
    }

    function load() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("OracleManager"));
        assembly {
            data.slot := s
        }
    }
}