/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {

    mapping (address => uint256) public addressToAmmoundFunded;
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 8;
        require(getConversionRate(msg.value) >= minimumUSD, "value should be more than 50$");
        addressToAmmoundFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getConversionRate(uint256 ethAmmounWei) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 price = (ethPrice * ethAmmounWei) / (1000000000000000000);
        return price;
    }

    modifier onluOwner(){
        require(msg.sender == owner, "You dont have permission to withdraw from contract!");
        _;
    }

    function withdraw() public payable onluOwner {
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderindex=0; funderindex < funders.length; funderindex++){
            address funder = funders[funderindex];
            addressToAmmoundFunded[funder] = 0;
        }
        delete funders;
    }
}