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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();
contract FundMe {
    using PriceConverter for uint256;
    address[] public funders;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;
    mapping (address => uint256) addressToAmountFunded;
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >=10000000000, "Didn't send enough wei");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }
    modifier onlyOwner {
        if(i_owner == msg.sender){
            revert NotOwner();
        }
        _;
    }
    function withdraw() public onlyOwner{
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder]=0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        }
        receive() external payable{
            fund();
        }
        fallback() external payable{
            fund();
        }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
library  PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price*1e10);
    }
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice*ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}