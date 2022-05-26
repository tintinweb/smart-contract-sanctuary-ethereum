/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;
}

contract ChainlinkPriceFeed {
    IPriceFeed ethPriceFeed;
    constructor() public {
        ethPriceFeed = IPriceFeed(0x44A12813D0C043d0A932aE4e4D856deECA8D2DeC);
    }

    function getPrice(bytes32 feedKey) external view returns(uint256) {
        return ethPriceFeed.getPrice(feedKey);
    }

    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256) {
        return ethPriceFeed.getTwapPrice(_priceFeedKey, _interval);
    }
}