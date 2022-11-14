// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface IAggregatorV3Interface{

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

// ETH // USD 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
// EUR // USD Euro Forex	0x0bf79F617988C472DcA68ff41eFe1338955b9A80
// INR // USD Indian Rupee Forex	0xeF0a3109ce97e0B58557F0e3Ba95eA16Bfa4A89d
// JPY // USD Japanese Yen Forex	0x22Db8397a6E77E41471dE256a7803829fDC8bC57
// ZAR // USD South African Rand	Forex 0xDE1952A1bF53f8E558cc761ad2564884E55B2c6F
// AUD // USD Australian Dollar Forex 0x498F912B09B5dF618c77fcC9E8DA503304Df92bF
// BRL // USD Brazilian Real	Forex 0x5cb1Cb3eA5FB46de1CE1D0F3BaDB3212e8d8eF48
// CHF // USD Swiss Franc Forex 0x964261740356cB4aaD0C3D2003Ce808A4176a46d

// EUR / USD = 101860000
// BTC / USD
contract ChainlinkPriceFeed {

    IAggregatorV3Interface _priceFeed = IAggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    
    
    // constructor() {
    //     priceFeed = IAggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    // }

    /**
     * Returns the latest price
     */
    function getLatestPrice(IAggregatorV3Interface priceFeed) public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function ETHgetLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = _priceFeed.latestRoundData();
        return price;
    }

}