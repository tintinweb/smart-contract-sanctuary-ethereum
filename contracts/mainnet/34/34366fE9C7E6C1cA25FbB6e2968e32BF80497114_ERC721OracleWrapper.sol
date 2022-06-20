// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IEACAggregatorProxy} from "../interfaces/IEACAggregatorProxy.sol";

interface NFTOracle {
    function getTwap(address token) external view returns (uint128 price);

    function getLastUpdateTime(address token)
        external
        view
        returns (uint128 timestamp);
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
        return int256(uint256(oracleAddress.getTwap(asset)));
    }

    function latestTimestamp() external view override returns (uint256) {
        return uint256(oracleAddress.getLastUpdateTime(asset));
    }

    function latestRound() external view override returns (uint256) {
        return 0;
    }

    function getAnswer(uint256 roundId)
        external
        view
        override
        returns (int256)
    {
        return int256(uint256(oracleAddress.getTwap(asset)));
    }

    function getTimestamp(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        return uint256(oracleAddress.getLastUpdateTime(asset));
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