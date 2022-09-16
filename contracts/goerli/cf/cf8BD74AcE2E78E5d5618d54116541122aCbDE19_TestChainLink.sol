// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TestChainLink {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     * https://docs.chain.link/docs/ethereum-addresses/
     */
    constructor() {
        //ETH / USD
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }
    function getLatestPrice() public view returns (int) {
        (
           ,
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();

        //for ETH/USD price is scaled up by 10 **8
        return price /1e8;
    }
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );

}