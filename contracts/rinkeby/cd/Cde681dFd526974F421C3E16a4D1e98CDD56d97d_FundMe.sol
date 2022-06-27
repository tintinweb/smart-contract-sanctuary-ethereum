// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe{

    mapping(address => uint) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    constructor(){
        owner = msg.sender;
    }

    function fund() public payable {

        // Minimum $50;
        uint minimum50USD = 1 * 10 ** 18;

        require(getConversionRate(msg.value) >= minimum50USD, "atleast 0.1USD requied");

        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);

        // what the ETH -> USD conversion
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not allow to withdrawn");
        _;
    }
    function withdraw() payable onlyOwner public{

        (bool sent, bytes memory data) = owner.call{value: address(this).balance}("");

        for(uint i = 0; i < funders.length; i++){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);


        // msg.sender.transfer(address(this).balance);
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }



    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        ( ,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }


    // 1000000000
    function getConversionRate(uint _ethAmount) public view returns(uint){
        uint ethPrice =  getPrice();
        uint ethAmountToUSD = (ethPrice * _ethAmount) / 1000000000000000000;
        return ethAmountToUSD;
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