//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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
        );

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

// This is the main building block for smart contracts.
contract myLink {
    AggregatorV3Interface BTCUSD =
        AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);

    function getPrice() public view returns (int256) {
        (, int256 answer, , , ) = BTCUSD.latestRoundData();
        return answer;
    }
}