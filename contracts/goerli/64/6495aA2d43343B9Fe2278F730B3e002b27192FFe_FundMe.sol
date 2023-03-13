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
import "./PriceConvertor.sol";

error NotOwner();

contract FundMe {
    using PriceConvertor for uint256;
    uint256 mininmumUSD = 50*1e18;
    address[] public funders;
    mapping(address=>uint256) public fundersToAmountFunded;
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function  fund() public payable {
        // require(getConversionRate(msg.value) >= mininmumUSD, "Didn't send enough");
        require(msg.value.getConversionRate(priceFeed) >= mininmumUSD, "Didn't send enough");
        funders.push(msg.sender);
        fundersToAmountFunded[msg.sender] = msg.value;
    }

    function widthdraw() public onlyOwner {
        require(msg.sender==owner, "Only owner can withdraw!");

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            fundersToAmountFunded[funder] = 0;
        }
        // resetting the array
        funders = new address[](0); // (0) this tells array of length 0

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); // it returns two parameters one boolean and other data which is returned by the function written in (""), here don't have to call the function so it is empty 
        require(callSuccess, "Send failed!");
    }

    modifier onlyOwner {
        // require(msg.sender==owner, "Only owner can withdraw!");
        if(msg.sender != owner) revert NotOwner();
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

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountUSD = (ethAmount * ethPrice)/1e18;
        return ethAmountUSD;
    }

    
}