/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

contract TesterChainlink {

    uint8 decimalsUSDValue = 18;
    uint256 usdValuePerToken;
    uint256 lastUpdateGlobal;

    uint80 public globalRoundId;
    uint16 public phaseId;

    address master;

    mapping(uint80 => uint256) timeStampByroundId;

    constructor(
        uint256 _usdValue,
        uint8 _decimals
    )
    {
        usdValuePerToken = _usdValue;
        decimalsUSDValue = _decimals;

        master = msg.sender;
    }

    function updateDecimals(
        uint8 newDecimals
    )
        external
    {
        decimalsUSDValue = newDecimals;
    }


    function latestAnswer(
    )
        external
        view
        returns (uint256)
    {
        return usdValuePerToken;
    }

    function decimals(
    )
        external
        view
        returns (uint8)
    {
        return decimalsUSDValue;
    }

    function latestRoundData()
        external
        view
        returns (
            uint256 roundId,
            uint256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint256 answerdInRound
        )
    {
        updatedAt = lastUpdateGlobal;
        roundId = globalRoundId;
        return (
            roundId,
            answer,
            startedAt,
            updatedAt,
            answerdInRound
        );
    }

    function setlastUpdateGlobal(
        uint256 _time
    )
        public
    {
        lastUpdateGlobal = _time;
    }

    function setUSDValue(
        uint256 _usdValue
    )
        public
    {
        if (master != msg.sender) {

            revert("testerChainlink: NOT_MASTER");
        }

        usdValuePerToken = _usdValue;
    }

    function updatePhaseId(
        uint16 _phaseId
    )
        external
    {
        phaseId = _phaseId;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        updatedAt = timeStampByroundId[_roundId];
        return (
            _roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound
        );
    }

    function setRoundData(
        uint80 _roundId,
        uint256 _updateTime
    )
        external
    {
        timeStampByroundId[_roundId] = _updateTime;
    }

    function getTimeStamp()
        external
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function setGlobalAggregatorRoundId(
        uint80 _aggregatorRoundId
    )
        external
    {
        globalRoundId = _aggregatorRoundId;
    }
}