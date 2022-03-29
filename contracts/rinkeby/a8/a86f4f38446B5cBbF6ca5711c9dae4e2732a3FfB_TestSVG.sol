/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// File: TestSVG.sol

contract TestSVG {
    // Rinkeby Chainlink BTC price feed
    AggregatorV3Interface private btcPriceFeed =
        AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
    AggregatorV3Interface private ethPriceFeed =
        AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    uint80 private roundInterval = 5; // ~once an hour

    constructor() {}

    /**
     * get the price for 0: BTC, 1: ETH
     * This should be the only function that needs to be duplicated if Open Editions
     * and drawings are still on a separate contract
     */
    function getPrice(uint8 priceType) private view returns (uint256, uint256) {
        AggregatorV3Interface feed = priceType == 0
            ? btcPriceFeed
            : ethPriceFeed;
        // current price data
        (uint80 roundId, int256 answer, , , ) = feed.latestRoundData();
        uint256 current = uint256(answer) / (10**uint256(feed.decimals()));

        // previous price data
        (, int256 prevAnswer, , , ) = feed.getRoundData(
            roundId - roundInterval
        );
        uint256 prev = uint256(prevAnswer) / (10**uint256(feed.decimals()));

        return (prev, current);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokenURI() external view returns (string memory) {
        // ipfs hash for image: QmbXUiGUuXEf3h1hoRy6MzVmQgXyJwCzLaDJLXs8NmVfBB
        (uint256 prevBTC, uint256 currentBTC) = getPrice(0);
        return
            string(
                abi.encodePacked(
                    bytes(
                        '{"name": "testsvg", "description": "A simple test", "image_data": "'
                    ),
                    bytes(
                        '<div style="position:relative;display:inline-block;transition: transform 150ms ease-in-out"><img style="display:block;max-width:100%;height:auto;" src="https://ipfs.io/ipfs/QmbXUiGUuXEf3h1hoRy6MzVmQgXyJwCzLaDJLXs8NmVfBB"><svg style="position:absolute;top:0;left:0;" viewBox="0 0 2105 1600"><text x="0" y="15" fill="black" transform="rotate(30 20,40)">'
                    ),
                    bytes(toString(currentBTC)),
                    bytes("</text></svg></div>"),
                    bytes('", "attributes": []}')
                )
            );
    }
}