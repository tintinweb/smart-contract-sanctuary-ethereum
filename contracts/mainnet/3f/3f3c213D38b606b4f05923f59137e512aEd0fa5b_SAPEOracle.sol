// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "AggregatorV3Interface.sol";

interface IApePool {

    function exchangeRateStored() external view returns (uint256);
}

/**
 * @title Pawnfi's SAPEOracle Contract
 * @author Pawnfi
 */
contract SAPEOracle is AggregatorV3Interface {

    /// @notice apePool contract address
    address public immutable apePool;

    /// @notice chainlink ape coin oracle contract address 
    address public immutable apeOracle;
    
    /**
     * @notice Initialize contract parameters
     * @param apePool_ apePool contract address
     * @param apeOracle_ chainlink ape coin oracle contract address 
     */
    constructor(address apePool_, address apeOracle_) {
        apePool = apePool_;
        apeOracle = apeOracle_;
    }

    /**
     * @notice represents the number of decimals the aggregator responses represent.
     */
    function decimals() external view returns (uint8) {
        return AggregatorV3Interface(apeOracle).decimals();
    }

    /**
     * @notice returns the description of the aggregator the proxy points to.
     */
    function description() external view returns (string memory) {
        return string(abi.encodePacked("s", AggregatorV3Interface(apeOracle).description()));
    }

    /**
     * @notice the version number representing the type of aggregator the proxy
     * points to.
     */
    function version() external view returns (uint256) {
        return AggregatorV3Interface(apeOracle).version();
    }

    /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @param _roundId the round ID to retrieve the round data for
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer corresponds to the computed sAPE price for the specific round, 
   * which is derived from the APE price provided.
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) {

            (
                roundId,
                answer,
                startedAt,
                updatedAt,
                answeredInRound
            ) = AggregatorV3Interface(apeOracle).getRoundData(_roundId);
            answer = int256(calculateSAPEPrice(answer));
        }

    /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer corresponds to the computed sAPE price for the specific round, 
   * which is derived from the APE price provided.
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
    function latestRoundData()
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) {
            (
                roundId,
                answer,
                startedAt,
                updatedAt,
                answeredInRound
            ) = AggregatorV3Interface(apeOracle).latestRoundData();
			answer = int256(calculateSAPEPrice(answer));
        }

    /**
     * @notice Get the sAPE price by APE price 
     * @param price APE price from chainlink 
     * @return sAPEPrice sAPE price
     */
    function calculateSAPEPrice(int256 price) public view returns (uint256 sAPEPrice) {
        require(price > 0, "Price error");
        uint256 exchangeRate = IApePool(apePool).exchangeRateStored();
        sAPEPrice = uint256(price) * exchangeRate / 1e28;
    }
}