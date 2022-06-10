//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../helpers/IAggregatorInterface.sol";

contract MockAggregator is IAggregatorInterface {

    string name;
    int256 price;
    uint8 dec;
    address owner;

    constructor(
        string memory name_,
        int256 price_,
        uint8 decimals_
    ) { 
        name = name_;
        price = price_;
        dec = decimals_;
        owner = msg.sender;
    }

    function decimals() public override view returns (uint8) {
        return dec;
    }

    function description() public view returns (string memory) {
        return name;
    }

    function version() public view returns (uint256) {
        return 0;
    }

    function getRoundData(uint80 _roundId)
        public
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, price, 0, block.timestamp, 0);
    }

    function latestRoundData()
        public
        override
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, price, 0, block.timestamp, 0);
    }

    function updatePriceAndDecimals(
        int256 price_,
        uint8 decimals_
    ) public {
        require(msg.sender == owner, "Not owner");
        price = price_;
        dec = decimals_;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity >=0.6.8 <=0.7.6;

interface IAggregatorInterface {
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