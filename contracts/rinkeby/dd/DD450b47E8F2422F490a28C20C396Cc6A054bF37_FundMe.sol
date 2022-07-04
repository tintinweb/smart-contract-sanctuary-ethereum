// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;
    uint256 constant minimumUSD = 50 * 1e18;
    AggregatorV3Interface public priceFeedAddress;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    constructor(address _priceFeedAddress){
        owner = msg.sender;
        priceFeedAddress = AggregatorV3Interface(_priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeedAddress) >= minimumUSD, "To small amount");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint i=0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        
        funders = new address[](0);
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to send money");
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Only owner can withdraw money");
        _;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeedAddress)
    internal
    view
    returns (uint256)
  {
    (, int256 price, , , ) = priceFeedAddress.latestRoundData();
    return uint256(price * 1e10); //1789 36001981 0000000000
  }

  function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeedAddress
  ) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeedAddress);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
    return ethAmountInUsd;
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