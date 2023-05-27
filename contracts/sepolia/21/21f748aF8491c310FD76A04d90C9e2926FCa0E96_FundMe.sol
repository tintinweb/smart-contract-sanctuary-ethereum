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
pragma solidity ^0.8.7; // >=0.8.7 <0.9.0   ^0.8.7

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint minimumUSD = 50 * 1e8;

    address[] public funders;
    mapping (address => uint256) public addressToAmountFunded;

    address public owner;

    uint tst = 13;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= minimumUSD, "You have to send at least 50 USD");

        funders.push(msg.sender);
        uint256 prevValue = addressToAmountFunded[msg.sender];
        addressToAmountFunded[msg.sender] = prevValue + msg.value;
    }

    function getList() public view returns (uint256) {
        return addressToAmountFunded[msg.sender];
    }

    function withdraw() public onlyOwner {

        for(uint256 funderI = 0; funderI < funders.length; funderI++) {
            address funder = funders[funderI];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "func only available for owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // >=0.8.7 <0.9.0   ^0.8.7

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getEthPrice(AggregatorV3Interface priceFeed) internal view returns (int256) {
        (
        /* uint80 roundID */,
        int256 answer,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return answer;
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = uint256(getEthPrice(priceFeed));
        //1e18 = 1_000000000000000000
        uint256 ethInUsd = (ethAmount * ethPrice) / 1e8;

        return ethInUsd;
    }
}