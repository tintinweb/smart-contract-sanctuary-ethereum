// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./priceConverter.sol";

error FundMe_NotOwner();
contract fundMe{
    using priceConverter for uint;
    address private Owner;
    uint256 public minimumUSD = 0.01 * 1e18;
    AggregatorV3Interface private priceFeed;
    mapping(address => uint) private addressToAmountFunded;
    address[] private funders;

    modifier onlyOwner {
        if(msg.sender != Owner) revert FundMe_NotOwner();
        _;
    }
    constructor(address priceFeedAddress) {
        Owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed)>=minimumUSD, "send more eth");
        addressToAmountFunded[msg.sender] += msg.value; // addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value
        funders.push(msg.sender);
    }

    function withdraw() onlyOwner public{
        for(uint256 i=0; i< funders.length; i++){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return addressToAmountFunded[funder];
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getOwner() public view returns (address) {
        return Owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceConverter{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256)  {
        (, int price, , ,) = priceFeed.latestRoundData();
        return uint256(price * 1e18);
    }

    function getConversionRate(uint256 _ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256)  {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * _ethAmount)/1e18;
        return ethAmountInUSD;
    }

}

// SPDX-License-Identifier: MIT
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