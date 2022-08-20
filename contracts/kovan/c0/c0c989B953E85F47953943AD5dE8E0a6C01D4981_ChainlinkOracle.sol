// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IOracle} from "../interfaces/IOracle.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";

/**
 * @title Chainlink Oracle
 *
 * @notice Provides a value onchain from a chainlink oracle aggregator
 */
contract ChainlinkOracle is IOracle {
    // The address of the Chainlink Aggregator contract
    IChainlinkAggregator public immutable oracle;
    uint256 public immutable stalenessThresholdSecs;

    constructor(address _oracle, uint256 _stalenessThresholdSecs) {
        oracle = IChainlinkAggregator(_oracle);
        stalenessThresholdSecs = _stalenessThresholdSecs;
    }

    /**
     * @notice Fetches the latest market price from chainlink
     * @return Value: Latest market price as an 8 decimal fixed point number.
     *         valid: Boolean indicating an value was fetched successfully.
     */
    function getData() external view override returns (uint256, bool) {
        (, int256 answer, , uint256 updatedAt, ) = oracle.latestRoundData();
        uint256 diff = block.timestamp - updatedAt;
        return (uint256(answer), diff <= stalenessThresholdSecs);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IOracle {
    function getData() external view returns (uint256, bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

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