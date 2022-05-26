// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error InsufficientEth();
error TransferFailed();
error UnauthorizedCaller();

contract Covid19 {
    // Initializing usPrice in constructor would return 0 value the next time it's updated 
    uint256 public usdPrice; 
    address public owner;
    AggregatorV3Interface internal ethUsdPriceFeed;

    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */

    struct Appointment {
        string testType;
        address testee;
        uint256 startTime;
        uint256 endTime;
        uint256 ethPaid;
    }
    
    // Getter function contract.appointments() wouldn't render frontend
    Appointment[] public appointments;

    event userAppointment(string _testName, address indexed _from, uint256 startTime, uint256 endTime, uint256 _amount);

    // Parameterize Price Feed Address
    constructor(address _priceFeed) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        if(msg.sender != owner) 
            revert UnauthorizedCaller(); // Gas saving error message
        _;
    }

    function getAppointments() public view returns (Appointment[] memory) {
        return appointments;
    }

    function changeUsdPrice (uint256 _usdPrice) public onlyOwner {
        usdPrice = _usdPrice *1e18; // *10**18 would malfunction when attemting to get ethTestFee
    }

    // Calculate the equivalent amount of ETH for the current usdPrice 
    function getEthTestFee() public view returns (uint256) {
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 1e10; // To make it 18 decimals
        uint256 ethTestFee = (usdPrice * 1e18) / adjustedPrice;
        return ethTestFee;
    }

    function createAppointment(string memory _testType, uint256 _startTime, uint256 _endTime) public payable {
        if (msg.value < getEthTestFee())
            revert InsufficientEth();
        Appointment memory appointment = Appointment(_testType, msg.sender, _startTime, _endTime, msg.value); 
        appointments.push(appointment); 
        emit userAppointment (_testType, msg.sender, _startTime, _endTime, msg.value);   
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