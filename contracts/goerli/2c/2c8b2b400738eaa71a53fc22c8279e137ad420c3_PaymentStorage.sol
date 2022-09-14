/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentStorage {
  uint256 public favoriteNumber;

  error ValueSmall();

  enum RaffleState {
    BEGINEER,
    AMATEUR
  }

  RaffleState public s_raffleState;

  mapping(address => uint256) public valuePaid;

  struct PeopleId {
    uint256 id;
    address s_address;
  }

  mapping(string => PeopleId) public PeopleIdentity;

  address[] public funders;

  address public i_owner;

  constructor() {
    i_owner = msg.sender;
    s_raffleState = RaffleState.BEGINEER;
  }

  modifier onlyowner() {
    i_owner == msg.sender;
    _;
  }

  function modify() public payable {
    if (msg.value < favoriteNumber) {
      revert ValueSmall();
    }

    valuePaid[msg.sender] += msg.value;
    funders.push(msg.sender);
  }

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber + 1;
    s_raffleState = RaffleState.AMATEUR;
  }

  function getFavoriteNumber() public view returns (uint256) {
    return favoriteNumber;
  }

  function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
  }

  function getUserDetails(uint256 _id, string memory _name) public {
    PeopleId memory person = PeopleId(_id, msg.sender);
    PeopleIdentity[_name] = person;
  }
}