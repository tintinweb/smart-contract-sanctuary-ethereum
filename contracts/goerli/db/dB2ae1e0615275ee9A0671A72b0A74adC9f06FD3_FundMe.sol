// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "AggregatorV3Interface.sol";

contract FundMe{

    address owner;
    AggregatorV3Interface priceFeed;

    address[] public fundingAddresses;
    mapping(address => uint256) public addressToFund;

    constructor(address _aggregatorAddress) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    function fund() public payable{
        uint256 minimumValue = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumValue, "Not Enough ETH");
        fundingAddresses.push(msg.sender);
        addressToFund[msg.sender] += msg.value;
    }

    function getLatestData() public view returns (uint256){
        (, int256 answer, , ,) = priceFeed.latestRoundData();
        return uint256(answer * 10 ** 10);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethUsdPrice = getLatestData();
        uint256 ethAmountInUsd = (ethUsdPrice * ethAmount) / 10 ** 18;
        return ethAmountInUsd;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only contract owner can execute this operation.");
        _;
    }

    function withdraw() public onlyOwner payable{
        payable(msg.sender).transfer(address(this).balance);
        resetFundings();
    }

    function resetFundings() internal{
        for (uint256 i = 0; i < fundingAddresses.length; i++){
            addressToFund[fundingAddresses[i]] = 0;
        }
        fundingAddresses = new address[](0);
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