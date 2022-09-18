// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


error notOwner();

contract FundMe {

    using PriceConverter for uint256;
    uint256 public minimumUsd = 50 * 1e18;
    AggregatorV3Interface private  priceFeed ;

    address[] public funders;
    address public owner;
    mapping (address => uint256) public addressToAumountFundMe;

    constructor(address _priceFeed) {
        owner = msg.sender;
        minimumUsd=2*1e18;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable  {
        //Want to able to set a minimum fund amount is USD
        require(msg.value.getConversionRate(priceFeed) >= minimumUsd,"Please send enough money!");
        funders.push(msg.sender);
        addressToAumountFundMe[msg.sender]  = addressToAumountFundMe[msg.sender] + msg.value;
    }

    function withdraw() public onlyOwner  {
        for(uint256 funderIndex ; funderIndex < funders.length;funderIndex++){
            address funder = funders[funderIndex];
            addressToAumountFundMe[funder] = 0;
        }
        payable (msg.sender).transfer(address(this).balance);
    }

    modifier onlyOwner {
        // require(msg.sender== owner , "Sender is not owner");
        if(msg.sender != owner) { revert notOwner(); }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getVersion(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrize = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrize) / 1e18;
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