// SPDX-License-Identifier: MIT
// @Copyright: (c) 2022 by XXXX
// @Filename : FundMe
// @dev      :
// @Version  : v1.0
// @Author   : XingLin
// @Time     : 2022-04-08
// @Note     :
// Date Changed             Version              Editer                  Content
// -------------------------------------------------------------------------------------------
//
// -------------------------------------------------------------------------------------------
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";


contract FundMe {
    address internal owner;
    // array of addresses who deposited
    address[] public funders;
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) public addressToAmountFunded;

    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    modifier onlyOwner {
    	// is the message sender owner of the contract?
        require(msg.sender == owner);
        _;
    }

    // 捐赠
    function fund() public payable {
        // 最少 $50
        uint256 minUSD = 50 * 1e18;
        //is the donated amount less than 50USD?
        require(getConversionRate(msg.value) >= minUSD, "You need to spend more ETH!");

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // 入场费, 不能低于此 Eth
    function getEntranceFee() public view returns (uint256) {
        // minUSD
        uint256 minUSD = 50 * 1e18;
        uint256 price = getLatestPrice();
        uint256 precision = 1e18; // 精度

        return (minUSD* precision) / price ;
    }

    /**
     * @dev 获取 ETH/USD 的价格
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        /**
         * ETH/USD rate in 18 digit
         * 3075,8373,0283
         */
        return uint256(price * 1e10);
    }

    // ETH => USD
    // ethAmount: 单位 wei
    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getLatestPrice();
        // 3085.66 0000 0000 0000 0000
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    // 取款
    function withdraw() public onlyOwner payable {
        payable(msg.sender).transfer(address(this).balance);

        // resetting
        for (uint256 i=0; i < funders.length; ++i) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // funders array will be initialized to 0
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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