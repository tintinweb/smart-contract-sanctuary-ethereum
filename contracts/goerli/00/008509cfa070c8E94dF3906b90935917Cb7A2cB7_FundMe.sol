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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import './PriceConvertor.sol';

contract FundMe {
    using PriceConvertor for uint;

    uint public mimimumUsd = 10 * 1e18; // 1000000000000000000 ETH
    address[] public funders;
    mapping(address=>uint) public funderAddressToPrice;

    address public owner;
    AggregatorV3Interface priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }


    function fund() public payable {
        // want to send minimum USD for fund
        // require(priceConversionRate(msg.value) > mimimumUsd, "don't have enfough amount");

        // with library we need to call something like below
        // require(priceConversionRate(msg.value) > mimimumUsd, "don't have enfough amount"); // or
        require(msg.value.priceConversionRate(priceFeed) > mimimumUsd, "don't have enfough amount"); // here bydefault msg.value is first paramter if we need to send second Params use msg.value.priceConversionRate(234)

        funders.push(msg.sender);
        funderAddressToPrice[msg.sender] = msg.value;
    }

    function withdraw() public _onlyOwner {
        for(uint fundIndex = 0; fundIndex < funders.length; fundIndex++) {
            address funder = funders[fundIndex];
            funderAddressToPrice[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{ value : address(this).balance}("");
        require(callSuccess, "Transfer Failed");
    }

    modifier _onlyOwner() {
        require(owner == msg.sender, "Your are not owner!");
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int price, , ,) = priceFeed.latestRoundData();
        return uint(price*1e10);

    }

    function priceConversionRate(uint ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint) {
        uint ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD Price
        // 1_000000000000000000 = ETH
        uint ethPriceInUsd = ( ethAmount * ethPrice ) / 1e18;
        return ethPriceInUsd;

    }

    function getVersion() internal view returns(uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }
}