/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

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

// File: priceConsumer.sol


pragma solidity ^0.8.7;

// interfaceをimportする

contract PriceConsumerV3 {
// コントラクト名
    AggregatorV3Interface internal priceFeed; 
    // interfaceの宣言

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * 今回のコントラクトはKovan上のETH/USDを用いる
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    /**
     * 最新の価格を返す
   　*/
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/, // dataのid
            int price, // 最新価格 decimalsは 8
            /*uint startedAt*/, // roundスタートしたタイムスタンプ
            /*uint timeStamp*/, // data更新のタイムスタンプ
            /*uint80 answeredInRound*/ // どのroundで更新されたか
        ) = priceFeed.latestRoundData(); 
        // interfaceで作ったpriceFeedオブジェクトを利用
        // 今回欲しいのはpriceだけなので、その他はコメントアウト。コンマは残しておく
        return price;
        // 最新の価格を返す
    }
}