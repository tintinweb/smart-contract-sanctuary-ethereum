/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Airline {

  address public owner;

  struct Customer {
      uint loyaltyPoints;
      uint totalFlights;
  }  

  struct Flight {
      string name;
      uint256 price;
  }

  uint etherPerPoint = 0.5 ether;

  Flight[] public flights;

  mapping(address => Customer) public customers;
  mapping(address => Flight[]) public customerFlights;
  mapping(address => uint) public customerTotalFlights;
  
  event FlightPurchased(address indexed customer, uint price, string flight);

  constructor() {
      owner = msg.sender;   
      flights.push(Flight('Tokio', 4 ether));
      flights.push(Flight('Germany', 3 ether));
      flights.push(Flight('Madrid', 3 ether));
  }   

  function buyFlight(uint flightIndex) public payable {
      Flight storage flight = flights[flightIndex];
      require(msg.value == flight.price);

      //Customer storage customer = customers[msg.sender];
      //customer.loyaltyPoints += 5;
      //customer.totalFlights += 1;
      customers[msg.sender].loyaltyPoints += 5;  
      customers[msg.sender].totalFlights += 1;
      customerFlights[msg.sender].push(flight);
      customerTotalFlights[msg.sender] ++;

      emit FlightPurchased(msg.sender, flight.price, flight.name);
  }

  function totalFlights() public view returns (uint256) {
      return flights.length;
  }

  function redeemLoyaltyPoints() public {
      Customer storage customer = customers[msg.sender];
      uint etherToRefund = etherPerPoint * customer.loyaltyPoints;
      payable(msg.sender).transfer(etherToRefund);
      customer.loyaltyPoints = 0;
  }

  function getRefundableEther() public view returns (uint256) {
      return etherPerPoint * customers[msg.sender].loyaltyPoints;
  }

  function getAirlineBalance() public isOwner view returns (uint256) {
      return address(this).balance;
  }

  modifier isOwner() {
      require(msg.sender == owner);
      _;
  }
}