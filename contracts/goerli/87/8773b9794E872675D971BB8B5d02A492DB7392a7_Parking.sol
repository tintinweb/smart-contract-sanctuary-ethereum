// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./Spaces.sol";
import "./Cars.sol";

contract Parking {

  // instances to access APIs
  Spaces spaceRepo;
  Cars carRepo;

  // events
  event SuccessfulTransaction(address from, address to, string space, string car, uint256 timestamp);

  // contract state
  mapping(string => bool) public spacesInUse;
  mapping(string => ParkingInfo) public carsParked;

  // our parking info
  struct ParkingInfo {
    string space;
    address paymentRecipient;
    uint256 startedAt;
    uint pricePerMinute;
  }

  // ctor
  constructor(address spacesAddr, address carsAddr) {
    spaceRepo = Spaces(spacesAddr);
    carRepo = Cars(carsAddr);
  }

  // begin a parking session
  // TODO: ensure user has agreed to the rules via signature?
  function startParkingSession(string memory _carId, string memory _spaceId) public {
    Cars.CarDetails memory car = carRepo.getCar(_carId);
    Spaces.ParkingSpace memory space = spaceRepo.getSpace(_spaceId);
    ParkingInfo memory session = carsParked[_carId];
    require(car.owner != address(0), 'CAR_NOT_FOUND');
    require(car.disabledByAdmin == false, 'CAR_DISABLED');
    require(session.startedAt == 0, 'CAR_ALREADY_PARKED');
    require(space.enabled == true, 'SPACE_DISABLED');
    require(space.verified == true, 'SPACE_NOT_VERIFIED');
    session.space = _spaceId;
    session.startedAt = block.timestamp;
    session.pricePerMinute = space.pricePerMinute;
    session.paymentRecipient = space.landlord;
    carsParked[_carId] = session;
    spacesInUse[_spaceId] = true;
  }

  function costForParking(string memory _carId, uint256 atTime) public view returns (uint, ParkingInfo memory) {
    ParkingInfo memory session = carsParked[_carId];
    require(session.startedAt != 0, 'PARKING_SESSION_NOT_FOUND');
    uint parkedForSeconds = atTime - session.startedAt;
    uint parkedForMins = parkedForSeconds / 60.0;
    uint priceForParking = session.pricePerMinute * parkedForMins;
    return (priceForParking, session);
  }

  function completeParking(string memory _carId) public payable {
    // calculate cost of parking
    uint timeNow = block.timestamp;
    (uint priceForParking, ParkingInfo memory session) = costForParking(_carId, timeNow);
    require(msg.value >= priceForParking, 'NOT_ENOUGH_PAYMENT');
    // make payment
    (bool success, ) = session.paymentRecipient.call{value:priceForParking}("");
    require(success, "TRANSACTION_FAILED");
    delete carsParked[_carId];
    delete spacesInUse[session.space];
    // emit event
    emit SuccessfulTransaction(msg.sender, session.paymentRecipient, session.space, _carId, timeNow);
    // TODO: we don't have a method yet for deploying our 'first reward' ERC1155 token :(
  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// import "./Spaces.sol";

contract Cars {

  // Spaces private spaces;
  int16 public constant defaultScore = 100;

  // owner of this contract
  address public owner;

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
  function registerCar(string memory _regNumber, string memory _nickname) public {
    CarDetails memory car = cars[_regNumber];
    int score = scores[_regNumber];
    int newScore = score + defaultScore;
    require(bytes(_regNumber).length > 5, 'REG_TOO_SHORT');
    require(bytes(_regNumber).length < 10, 'REG_TOO_LONG');
    require(car.owner == address(0), 'ALREADY_REGISTERED');
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

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

contract Spaces {

  // owner / admin of contract
  address owner;

  // this is our virtual, crowd-sourced car park!
  mapping(string => ParkingSpace) public carPark;

  // events
  event NewSpaceRegistration(address landlord, string id, string locationWtw);
  event SpaceVerified(address landlord, string id, string locationWtw);
  event SpaceEnabledChanged(string id, bool newValue);
  event UpdatedSpaceField(string id, string fieldName, string oldValue, string newValue);
  event NewLandlord(string id, address oldLandlord, address newLandlord);
  event PriceChanged(string id, uint oldPrice, uint newPrice);
  event SpaceRemoved(string id, string locationWtw);

  // construct this contract
  constructor() {
    owner = msg.sender;
  }
  // ensure a method can only be called by the owner
  modifier _ownerOnly() {
      require(msg.sender == owner);
      _;
  }

  // all registration information for each parking space
  struct ParkingSpace {
    address landlord;
    uint256 addedAt;
    bool enabled;
    bool verified;
    string locationWtw; // what three words space
    string locationHint; // describe succinctly which space or space ID if labelled
    string rules; // any rules that need to be adhered to
    uint pricePerMinute; // e.g., 8725742565957 wei ~= £0.01
  }

  // 1. register a new parking space. This will be set to disabled and unverified for now
  function registerNewSpace(
    string memory _id,
    string memory _locationWtw,
    string memory _locationHint,
    string memory _rules,
    uint _pricePerMinute)
    public {
    // find space with name
    ParkingSpace memory space = carPark[_id];
    // pre-guards
    require(space.landlord == address(0), 'ALREADY_REGISTERED');
    require(bytes(_locationWtw).length < 100, 'WTW_TOO_LONG');
    require(bytes(_locationHint).length < 1000, 'HINT_TOO_LONG');
    require(bytes(_rules).length < 2000, 'RULES_TOO_LONG');
    require(_pricePerMinute > 0, 'PRICE_ZERO');
    // set up new registration
    space.landlord = msg.sender;
    space.addedAt = block.timestamp;
    space.locationWtw = _locationWtw;
    space.locationHint = _locationHint;
    space.rules = _rules;
    space.pricePerMinute = _pricePerMinute;
    if (owner == msg.sender) { // auto-enable for admin
      space.verified = true;
      space.enabled = true;
    }
    carPark[_id] = space;
    // emit registration event
    emit NewSpaceRegistration(msg.sender, _id, _locationWtw);
  }

  // 2. an admin can now verify a space
  function verifySpace(string memory _id) public _ownerOnly {
    // find space with name
    ParkingSpace memory space = carPark[_id];
    // pre-guards
    require(space.landlord != address(0), 'NOT_REGISTERED');
    require(space.verified == false, 'ALREADY_VERIFIED');
    // update verified flag
    space.verified = true;
    carPark[_id] = space;
    // emit verified event
    emit SpaceVerified(space.landlord, _id, space.locationWtw);
  }

  // 3. now owner can enable the parking space so people 
  // can start parking there
  function toggleSpaceEnabled(string memory _id, bool enable) public {
    // find space with name
    ParkingSpace memory space = carPark[_id];
    require(space.landlord == msg.sender, 'NOT_LANDLORD'); // caller must be the landlord
    require(space.verified == true, 'NOT_VERIFIED'); // must be verified
    require(space.enabled != enable, 'ALREADY_AT_STATE'); // must be the opposite state
    // update enabled state
    space.enabled = enable;
    carPark[_id] = space;
    emit SpaceEnabledChanged(_id, enable);
  }

  // the landlord can also update the location hint, rules and transfer to a new owner
  function updateLocationHint(string memory _id, string memory _locationHint) public {
    ParkingSpace memory space = carPark[_id];
    require(space.landlord != address(0), 'NOT_REGISTERED');
    require(space.landlord == msg.sender, 'NOT_LANDLORD');
    string memory oldValue = space.locationHint;
    space.locationHint = _locationHint;
    carPark[_id] = space;
    emit UpdatedSpaceField(_id, "locationHint", oldValue, _locationHint);
  }
  function updateRules(string memory _id, string memory _rules) public {
    ParkingSpace memory space = carPark[_id];
    require(space.landlord != address(0), 'NOT_REGISTERED');
    require(space.landlord == msg.sender, 'NOT_LANDLORD');
    string memory oldValue = space.rules;
    space.rules = _rules;
    carPark[_id] = space;
    emit UpdatedSpaceField(_id, "rules", oldValue, _rules);
  }
  function updatePrice(string memory _id, uint _newPricePerMinute) public {
    ParkingSpace memory space = carPark[_id];
    require(space.landlord != address(0), 'NOT_REGISTERED');
    require(space.landlord == msg.sender, 'NOT_LANDLORD');
    require(space.pricePerMinute != _newPricePerMinute, 'NOT_CHANGED');
    uint oldValue = space.pricePerMinute;
    space.pricePerMinute = _newPricePerMinute;
    carPark[_id] = space;
    emit PriceChanged(_id, oldValue, _newPricePerMinute);
  }
  function transferToNewOwner(string memory _id, address _newLandlord) public {
    ParkingSpace memory space = carPark[_id];
    require(space.landlord != address(0), 'NOT_REGISTERED');
    require(space.landlord == msg.sender, 'NOT_LANDLORD');
    address oldLandlord = space.landlord;
    space.landlord = _newLandlord;
    carPark[_id] = space;
    emit NewLandlord(_id, oldLandlord, _newLandlord);
  }

  // de-registering a space is just deleting it
  function removeSpace(string memory _id) public {
    ParkingSpace memory space = carPark[_id];
    require(space.landlord != address(0), 'NOT_REGISTERED');
    require(space.landlord == msg.sender, 'NOT_LANDLORD');
    delete carPark[_id];
    emit SpaceRemoved(_id, space.locationWtw);
  }

  function getSpace(string memory _spaceID) public view returns (ParkingSpace memory) {
    return carPark[_spaceID];
  }

}