// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol"; // needed source for Price Feeds

contract FundMe {
    address ETH_USD_ID = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
    address USD_ETH_ID = 0x614715d2Af89E6EC99A233818275142cE88d1Cfd;

    mapping(address => uint256) public addressToAmountFunded;

    address public owner;

    address[] funders;

    function fund() public payable {
        // $50 checking:
        uint256 minAmount = 50 * (10**18);
        require(getConversionRate(msg.value) >= minAmount);

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    AggregatorV3Interface public priceFeed; // address

    constructor(address _priceFeed) {
        // this code block exetuces immediately... after deploying
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        // Just owner to this contract
        // require(msg.sender == owner); THIS LINE OPTIMIZED WITH MODIFIER
        payable(msg.sender).transfer(address(this).balance);

        // resetting procedure starts

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        // resetting procedure stops
    }

    function getVerison() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // this has 8 decimal. but we should make it 18 DIGIT.
        uint256 result = uint256(answer) * (10**10);
        return uint256(result);
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(); // 18 digit
        uint256 conversationResult = (ethAmount * ethPrice); // 18 digit (wei)
        uint256 conversationResultReadable = conversationResult / (10**18); // non-18 digit version
        return conversationResultReadable;
    }
}

// PRICE NOTES:

/*
 Directly Taking ETH/USD rate is = 109368000000
 Last 8 number in here is decimal part. So actual number is in above:
 1093,6800..00
 So we should do: 109368000000/10**8
*/

/*
 When donating all types(ether,gwei,wei) converted to wei.
 So when to compare, it is useful to consider this.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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