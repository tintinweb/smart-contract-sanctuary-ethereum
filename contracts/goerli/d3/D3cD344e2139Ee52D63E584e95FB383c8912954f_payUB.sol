// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "AggregatorV3Interface.sol";


contract payUB {

    mapping(address => uint256) public billsToPay;
    address[] public studentsBilled;

    address owner;

    AggregatorV3Interface priceFeed;
    modifier onlyOwner() {
        require(msg.sender == owner,"You are not Authorized to Withdraw");
        _;
    }

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function addBill(address student, uint256 billAmount) public onlyOwner {
        studentsBilled.push(student);
        billsToPay[student] += billAmount;
    }

    function pay() public payable {
        require(getConversionRate(msg.value) <= billsToPay[msg.sender],"Paying too much");
        billsToPay[msg.sender] -= msg.value;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function viewMyBill() public view returns(uint256) {
        return billsToPay[msg.sender];
    }

    function getPrice() public view returns (uint256) {

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
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