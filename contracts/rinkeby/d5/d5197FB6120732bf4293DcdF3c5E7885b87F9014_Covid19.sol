// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error InsufficientEth();
error TransferFailed();
error UnauthorizedCaller();

contract Covid19 {
    uint256 public usdPrice;
    address public owner;
    AggregatorV3Interface internal ethUsdPriceFeed;

    struct Appointment {
        string testType;
        address testee;
        uint256 startTime;
        uint256 endTime;
        uint256 ethPaid;
    }
    
    Appointment[] public appointments;
    mapping(address => Appointment) public userAppointment;
    
    constructor() {
        ethUsdPriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        if(msg.sender != owner) 
            revert UnauthorizedCaller();
        _;
    }

    function getAppointments() public view returns (Appointment[] memory) {
        return appointments;
    }

    function changeUsdPrice (uint256 _usdPrice) public onlyOwner {
        usdPrice = _usdPrice *1e18;
    }
     
    function getEthTestFee() public view returns (uint256) {
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 1e10;
        uint256 ethTestFee = (usdPrice * 1e18) / adjustedPrice;
        return ethTestFee;
    }

    function createAppointment(string memory _testType, uint256 _startTime, uint256 _endTime) public payable {
        if (msg.value < getEthTestFee())
            revert InsufficientEth();
        Appointment memory appointment = Appointment(_testType, msg.sender, _startTime, _endTime, msg.value); 
        appointments.push(appointment);
        userAppointment[msg.sender] = appointment;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success)
            revert TransferFailed();
    }

    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
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