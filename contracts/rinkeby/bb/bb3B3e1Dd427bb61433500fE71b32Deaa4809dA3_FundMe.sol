// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./PriceConverter.sol";

error notOwner();
contract FundMe {
    using  PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    mapping(address => uint256) public adressToAmountFunded;

    address[] public funders;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    function Fund() public payable {
        require(msg.value.getConversionRate(priceFeed) < MINIMUM_USD, "You dont send enough eth");
        funders.push(msg.sender);
        adressToAmountFunded[msg.sender] = msg.value;
    }

    function Withdraw() public  onlyOwner{
        
        for(uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) {
            address funder = funders[fundersIndex];
            adressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Tranfer failed");
        (bool callSucess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSucess, "Call failed");
    }

    modifier onlyOwner{
        // require(msg.sender == i_owner, "Only owner can withdraw");
        if (msg.sender == i_owner){ revert notOwner();} // worked like require
        _;
    }

    receive() external payable {
        Fund();
    }

    fallback() external payable {
        Fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter{

    // function getVersion() internal view returns (uint256){
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return priceFeed.version();
    // }

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,,)=priceFeed.latestRoundData();
        //ETH in USD

        return uint256(price *1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount)/ 1e18;
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