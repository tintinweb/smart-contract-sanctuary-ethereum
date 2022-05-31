// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {

    address public owner;

    using PriceConverter for uint256;

    uint256 public minimumUsd = 50;

    address[] public funders;
    mapping(address=>uint256) public funderToAmountFunded;

    constructor(){
        owner = msg.sender;
    }

    function fund() public payable{
        require(msg.value.getConversionRate() >= minimumUsd, "Didn't send enough eth"); // 1e18 = 1 * 10 ** 18
        funders.push(msg.sender);
        funderToAmountFunded[msg.sender] = msg.value;
    }

    function withdrawFunds () public onlyOwner{

        // reseting all funding

        for(uint i=0; i<funders.length; i++){
            address funder = funders[i];
            funderToAmountFunded[funder] = 0;
        }

        // resetting funders array

        funders = new address[](0);

        // Sending eth to the account from the contract

        // Transfer
        // payable(msg.sender).transfer(address(this).balance);

        // Send

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failure... Transaction failed");

        // Call

       (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failure.... Transaction failed");

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can withdraw eth.");
        _;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
       function getPrice () internal view returns (uint256) {
        // abi
        // address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion () internal view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getConversionRate (uint256 ethAmount) internal view returns (uint256){
        uint256 ethPrice = getPrice();

        uint256 ethInUsd = (ethPrice * ethAmount)/1e18;
        return ethInUsd;
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