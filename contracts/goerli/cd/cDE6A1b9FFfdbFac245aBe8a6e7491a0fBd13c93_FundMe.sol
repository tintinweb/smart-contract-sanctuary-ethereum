// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // constant && immutable

    // ADDRESS => 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    // CONTRACT => 0x61E3DD57f1c65Ed59d625d253A2373E331FCc3BC

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        // REQUIRE => Revert if Condition is not Fulfilled
        require(msg.value.getConversionRate(priceFeed)  > MINIMUM_USD, "Not Enough Fund");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }



    function withdraw() public onlyOwner{
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // RESET ARRAY
        funders = new address[](0);

        // TRANSFER THROW ERROR IF FAIL + REVERT
        // payable(msg.sender).transfer(address(this).balance);

        // SEND RETURN BOOL + NOT REVERT
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // CALL
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");

    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Only Owner Can Withdraw");
        if(msg.sender != i_owner) {
            revert NotOwner(); // SAVE GAS
        }
        _; // _; means DO REST OF CODE
    }

    // receive && fallback
    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// NPM LIBRARY == REMIX DOWNLOAD PACKAGE AUTO
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        // LEAVE COMMAS!!!
        (,int256 price,,,) = priceFeed.latestRoundData(); // ETH IN DOLLAR WITH 8 DECIMALS
        return uint256(price * 1e10); // WEI FORMAT
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice*ethAmount) / 1e18;
        return ethAmountInUsd;
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