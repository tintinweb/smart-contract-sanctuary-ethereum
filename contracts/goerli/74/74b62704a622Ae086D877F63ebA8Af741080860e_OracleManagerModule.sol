//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOracleManagerModule.sol";
import "../utils/ReducerNodeLibrary.sol";
import "../utils/ExternalNodeLibrary.sol";
import "../utils/PythNodeLibrary.sol";
import "../utils/ChainlinkNodeLibrary.sol";

import "../storage/Node.sol";
import "../storage/NodeDefinition.sol";

contract OracleManagerModule is IOracleManagerModule {
    error UnsupportedNodeType(uint nodeType);
    error NodeNotRegistered(bytes32 nodeId);

    event NodeRegistered(bytes32 nodeId, bytes32[] parents, NodeDefinition.NodeType nodeType, bytes parameters);

    /// @notice registers a new node
    function registerNode(
        bytes32[] memory parents,
        NodeDefinition.NodeType nodeType,
        bytes memory parameters
    ) external returns (bytes32) {
        NodeDefinition.Data memory nodeDefinition = NodeDefinition.Data({
            parents: parents,
            nodeType: nodeType,
            parameters: parameters
        });

        return _registerNode(nodeDefinition);
    }

    /// @notice get the node Id by passing nodeDefinition
    function getNodeId(
        bytes32[] memory parents,
        NodeDefinition.NodeType nodeType,
        bytes memory parameters
    ) external pure returns (bytes32) {
        NodeDefinition.Data memory nodeDefinition = NodeDefinition.Data({
            parents: parents,
            nodeType: nodeType,
            parameters: parameters
        });

        return _getNodeId(nodeDefinition);
    }

    /// @notice get a node by nodeId
    function getNode(bytes32 nodeId) external pure returns (NodeDefinition.Data memory) {
        return _getNode(nodeId);
    }

    /// @notice the function to process the prices based on the node's type
    function process(bytes32 nodeId) external view returns (Node.Data memory) {
        return _process(nodeId);
    }

    function _getNode(bytes32 nodeId) internal pure returns (NodeDefinition.Data storage) {
        return NodeDefinition.load(nodeId);
    }

    modifier onlyValidNodeType(NodeDefinition.NodeType nodeType) {
        if (!_validateNodeType(nodeType)) {
            revert UnsupportedNodeType(uint(nodeType));
        }

        _;
    }

    function _validateNodeType(NodeDefinition.NodeType nodeType) internal pure returns (bool) {
        return (NodeDefinition.NodeType.REDUCER == nodeType ||
            NodeDefinition.NodeType.EXTERNAL == nodeType ||
            NodeDefinition.NodeType.CHAINLINK == nodeType ||
            NodeDefinition.NodeType.PYTH == nodeType);
    }

    function _getNodeId(NodeDefinition.Data memory nodeDefinition) internal pure returns (bytes32) {
        return NodeDefinition.getId(nodeDefinition);
    }

    function _registerNode(NodeDefinition.Data memory nodeDefinition)
        internal
        onlyValidNodeType(nodeDefinition.nodeType)
        returns (bytes32 nodeId)
    {
        nodeId = _getNodeId(nodeDefinition);
        //checks if the node is already registered
        if (_isNodeRegistered(nodeId)) {
            return nodeId;
        }
        // checks nodeDefinition.parents if they are valid
        for (uint256 i = 0; i < nodeDefinition.parents.length; i++) {
            if (!_isNodeRegistered(nodeDefinition.parents[i])) {
                revert NodeNotRegistered(nodeDefinition.parents[i]);
            }
        }

        (, nodeId) = NodeDefinition.create(nodeDefinition);

        emit NodeRegistered(nodeId, nodeDefinition.parents, nodeDefinition.nodeType, nodeDefinition.parameters);
    }

    function _isNodeRegistered(bytes32 nodeId) internal view returns (bool) {
        NodeDefinition.Data storage nodeDefinition = NodeDefinition.load(nodeId);
        return (nodeDefinition.nodeType != NodeDefinition.NodeType.NONE);
    }

    function _process(bytes32 nodeId) internal view returns (Node.Data memory price) {
        NodeDefinition.Data storage nodeDefinition = NodeDefinition.load(nodeId);

        Node.Data[] memory prices = new Node.Data[](nodeDefinition.parents.length);
        for (uint256 i = 0; i < nodeDefinition.parents.length; i++) {
            prices[i] = this.process(nodeDefinition.parents[i]);
        }

        if (nodeDefinition.nodeType == NodeDefinition.NodeType.REDUCER) {
            return ReducerNodeLibrary.process(prices, nodeDefinition.parameters);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.EXTERNAL) {
            return ExternalNodeLibrary.process(prices, nodeDefinition.parameters);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.CHAINLINK) {
            return ChainlinkNodeLibrary.process(nodeDefinition.parameters);
        } else if (nodeDefinition.nodeType == NodeDefinition.NodeType.PYTH) {
            return PythNodeLibrary.process(nodeDefinition.parameters);
        } else {
            revert UnsupportedNodeType(uint(nodeDefinition.nodeType));
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/Node.sol";

library ReducerNodeLibrary {
    error UnsupportedOperation(uint operation);

    enum Operations {
        MAX,
        MIN,
        MEAN,
        MEDIAN,
        RECENT
    }

    function process(Node.Data[] memory prices, bytes memory parameters) internal pure returns (Node.Data memory) {
        Operations operation = abi.decode(parameters, (Operations));

        if (operation == Operations.MAX) {
            return max(prices);
        }
        if (operation == Operations.MIN) {
            return min(prices);
        }
        if (operation == Operations.MEAN) {
            return mean(prices);
        }
        if (operation == Operations.MEDIAN) {
            return median(prices);
        }
        if (operation == Operations.RECENT) {
            return recent(prices);
        }

        revert UnsupportedOperation(uint(operation));
    }

    function median(Node.Data[] memory prices) internal pure returns (Node.Data memory medianPrice) {
        quickSort(prices, int(0), int(prices.length - 1));
        return prices[uint(prices.length / 2)];
    }

    function mean(Node.Data[] memory prices) internal pure returns (Node.Data memory meanPrice) {
        for (uint256 i = 0; i < prices.length; i++) {
            meanPrice.price += prices[i].price;
            meanPrice.timestamp += prices[i].timestamp;
        }

        meanPrice.price = meanPrice.price / int(prices.length);
        meanPrice.timestamp = meanPrice.timestamp / prices.length;
    }

    function recent(Node.Data[] memory prices) internal pure returns (Node.Data memory recentPrice) {
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i].timestamp > recentPrice.timestamp) {
                recentPrice = prices[i];
            }
        }
    }

    function max(Node.Data[] memory prices) internal pure returns (Node.Data memory maxPrice) {
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i].price > maxPrice.price) {
                maxPrice = prices[i];
            }
        }
    }

    function min(Node.Data[] memory prices) internal pure returns (Node.Data memory minPrice) {
        minPrice = prices[0];
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i].price < minPrice.price) {
                minPrice = prices[i];
            }
        }
    }

    function quickSort(
        Node.Data[] memory arr,
        int left,
        int right
    ) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        int pivot = arr[uint(left + (right - left) / 2)].price;
        while (i <= j) {
            while (arr[uint(i)].price < pivot) i++;
            while (pivot < arr[uint(j)].price) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/Node.sol";
import "../interfaces/external/IExternalNode.sol";

library ExternalNodeLibrary {
    function process(Node.Data[] memory prices, bytes memory parameters) internal view returns (Node.Data memory) {
        IExternalNode externalNode = IExternalNode(abi.decode(parameters, (address)));
        return externalNode.process(prices, parameters);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/Node.sol";
import "../interfaces/external/IPyth.sol";

library PythNodeLibrary {
    function process(bytes memory parameters) internal view returns (Node.Data memory) {
        (IPyth pyth, bytes32 priceFeedId) = abi.decode(parameters, (IPyth, bytes32));
        PythStructs.Price memory pythPrice = pyth.getPrice(priceFeedId);

        // TODO: use confidence score to determine volatility and liquidity scores
        return Node.Data(pythPrice.price, pythPrice.publishTime, 0, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/Node.sol";
import "../interfaces/external/IAggregatorV3Interface.sol";

library ChainlinkNodeLibrary {
    function process(bytes memory parameters) internal view returns (Node.Data memory) {
        (address chainlinkAggr, uint twapTimeInterval) = abi.decode(parameters, (address, uint));

        (uint80 roundId, int256 price, , uint256 updatedAt, ) = IAggregatorV3Interface(chainlinkAggr).latestRoundData();
        int256 finalPrice = twapTimeInterval == 0 ? price : getTwapPrice(chainlinkAggr, roundId, price, twapTimeInterval);
        return Node.Data(finalPrice, updatedAt, 0, 0);
    }

    function getTwapPrice(
        address chainlinkAggr,
        uint80 latestRoundId,
        int latestPrice,
        uint twapTimeInterval
    ) internal view returns (int256) {
        int priceSum = latestPrice;
        uint priceCount = 1;

        uint startTime = block.timestamp - twapTimeInterval;

        while (latestRoundId > 0) {
            try IAggregatorV3Interface(chainlinkAggr).getRoundData(--latestRoundId) returns (
                uint80,
                int256 answer,
                uint256,
                uint256 updatedAt,
                uint80
            ) {
                if (updatedAt < startTime) {
                    break;
                }
                priceSum += answer;
                priceCount++;
            } catch {
                break;
            }
        }

        return priceSum / int(priceCount);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../storage/Node.sol";

/// @title interface for external node
interface IExternalNode {
    function process(Node.Data[] memory prices, bytes memory parameters) external view returns (Node.Data memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when an update for price feed with `id` is processed successfully.
    /// @param id The Pyth Price Feed ID.
    /// @param fresh True if the price update is more recent and stored.
    /// @param chainId ID of the source chain that the batch price update containing this price.
    /// This value comes from Wormhole, and you can find the corresponding chains at https://docs.wormholenetwork.com/wormhole/contracts.
    /// @param sequenceNumber Sequence number of the batch price update containing this price.
    /// @param lastPublishTime Publish time of the previously stored price.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        bool indexed fresh,
        uint16 chainId,
        uint64 sequenceNumber,
        uint lastPublishTime,
        uint publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    /// @param batchSize Number of prices within the batch price update.
    /// @param freshPricesInBatch Number of prices that were more recent and were stored.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber, uint batchSize, uint freshPricesInBatch);

    /// @dev Emitted when a call to `updatePriceFeeds` is processed successfully.
    /// @param sender Sender of the call (`msg.sender`).
    /// @param batchCount Number of batches that this function processed.
    /// @param fee Amount of paid fee for updating the prices.
    event UpdatePriceFeeds(address indexed sender, uint batchCount, uint fee);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateDataSize Number of price updates.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(uint updateDataSize) external view returns (uint feeAmount);
}

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
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