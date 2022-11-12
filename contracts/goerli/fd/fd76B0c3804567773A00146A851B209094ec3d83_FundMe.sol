// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConvertor.sol";

contract FundMe {
    // ! we want PriceConvertor to act on uint256
    using PriceConvertor for uint256;
    uint256 public constant MIN_USD = 0.0000000000000001 * 1e18; // ! in wei

    // ! immutable - set the value in constructor once and then constant
    address internal immutable i_OWNER;

    // ! we create a global aggregrator interface object
    AggregatorV3Interface internal priceFeed;

    constructor(address priceFeedAddress) {
        i_OWNER = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funders;
    mapping(address => uint256) addressToAmtFunded;

    function fund() external payable {
        require(
            // ! pass the MockV3Aggregator.sol contract address to the getConversionRate function
            msg.value.getConversionRate(priceFeed) >= MIN_USD,
            "Didn't send enough ETH"
        );
        funders.push(msg.sender);
        addressToAmtFunded[msg.sender] += msg.value;
    }

    // ! modifier onlyOwner makes sure that only i_OWNER can call this function
    function withdraw() external onlyOwner {
        // ! reset the funders array and mapping
        address[] memory memFunders = funders;
        for (uint256 i = 0; i < memFunders.length; i++) {
            addressToAmtFunded[memFunders[i]] = 0;
        }
        funders = new address[](0);

        // ! three ways to transfer funds - transfer, send, call(RECOMMENDED)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == i_OWNER, "You are not the i_OWNER");
        // ! _ = kinda like a placeholder for the function that is being called
        _;
    }

    receive() external payable {
        this.fund();
    }

    fallback() external payable {
        this.fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    function getPrice(AggregatorV3Interface priceFeed)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // msg.value has 18 zeroes after decimal point, this means if x.(18 zeroes) = x,0000...(18 zeroes without decimal places)
        // price is int gwei, thus it already has 8 decimal places, we need to give it 10 more decimal places and so we multiple with 1e10;
        return uint256(price * 1e10);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            // ! 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e is the address of the price feed for ETH/USD coming form chainlink contracts
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ! We need the ABI of the price feed to get the latest price
        uint256 ethPrice = getPrice(priceFeed); // returns the price of 1 ETH in USD into 1e18
        uint ethAmtInusd = (ethAmt * ethPrice) / 1e18; // 1e18 is the number of zeroes after decimal point in ETH
        return ethAmtInusd;
    }
}

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