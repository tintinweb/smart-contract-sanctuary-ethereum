// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// import "./Spaces.sol";

contract Cars {

  // Spaces private spaces;
  int16 public constant defaultScore = 100;
  uint public costForRegistration = 8674167106557; // 865454873589090 wei ~= £1 • 8674167106557 wei ~= £0.01

  // owner of this contract
  address owner;

  // registration of cars using smarty park
  mapping(string => CarDetails) public cars;

  // reviews need to be separate due to issues of arrays in structs
  mapping(string => int) public scores;

  // events
  event CarRegistered(string _regNumber, address _owner);
  event CarScoreUpdated(string _regNumber, int by, int total, string reason);
  event CarDisabledChanged(string _regNumber, bool _disabled);

  // we need a reference to spaces
  constructor() { //address _t) {
    // spaces = Spaces(_t);
    owner = msg.sender;
  }
  modifier _ownerOnly() {
      require(msg.sender == owner);
      _;
  }

  // the registered details of a user
  struct CarDetails {
    address owner;
    bool disabledByAdmin;
    uint256 addedAt;
    string nickname;
  }

  // perform a new car registration
  function registerCar(string memory _regNumber, string memory _nickname) public payable {
    CarDetails memory car = cars[_regNumber];
    int score = scores[_regNumber];
    int newScore = score + defaultScore;
    require(bytes(_regNumber).length > 5, 'REG_TOO_SHORT');
    require(bytes(_regNumber).length < 10, 'REG_TOO_LONG');
    require(car.owner == address(0), 'ALREADY_REGISTERED');
    // pay for registration
    require(msg.value == costForRegistration, 'COST_OF_REG_NOT_SATISFIED');
    (bool success, ) = payable(owner).call{value: msg.value}("");
    require(success, 'PAYMENT_NOT_SUCCESSFUL');
    // now add details into the block
    car.addedAt = block.timestamp;
    car.owner = msg.sender;
    car.nickname = _nickname;
    cars[_regNumber] = car;
    scores[_regNumber] = newScore;
    emit CarRegistered(_regNumber, msg.sender);
    emit CarScoreUpdated(_regNumber, defaultScore, newScore, "REGISTRATION");
  }

  // admins can disable/enable a car if they need to
  function setCarDisabled(string memory _regNumber, bool _disabled) public _ownerOnly {
    CarDetails memory car = cars[_regNumber];
    require(car.owner != address(0), 'NOT_REGISTERED');
    car.disabledByAdmin = _disabled;
    cars[_regNumber] = car;
    emit CarDisabledChanged(_regNumber, _disabled);
  }

  function getCar(string memory _carID) public view returns (CarDetails memory) {
    return cars[_carID];
  }

  function changeRegistrationCost(uint costInWei) public _ownerOnly {
    costForRegistration = costInWei;
  }

}