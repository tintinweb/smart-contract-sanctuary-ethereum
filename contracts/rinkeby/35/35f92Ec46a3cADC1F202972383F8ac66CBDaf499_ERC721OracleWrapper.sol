// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IEACAggregatorProxy} from "../interfaces/IEACAggregatorProxy.sol";

interface NFTOracle {
    function getPrice(address token) external view returns (uint256 price);
}

contract ERC721OracleWrapper is IEACAggregatorProxy {
    NFTOracle private immutable oracleAddress;
    address private immutable asset;

    constructor(address _oracleAddress, address _asset) {
        oracleAddress = NFTOracle(_oracleAddress);
        asset = _asset;
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    function latestAnswer() external view override returns (int256) {
        return int256(oracleAddress.getPrice(asset)); // TODO update to the correct strategy
    }

    function latestTimestamp() external view override returns (uint256) {
        return block.timestamp; // TODO update to the oracle timestamp
    }

    function latestRound() external view override returns (uint256) {
        return 1; // TODO update to the oracle round
    }

    function getAnswer(uint256 roundId)
        external
        view
        override
        returns (int256)
    {
        return int256(oracleAddress.getPrice(asset));
    }

    function getTimestamp(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(uint256 indexed roundId, address indexed startedBy);
}