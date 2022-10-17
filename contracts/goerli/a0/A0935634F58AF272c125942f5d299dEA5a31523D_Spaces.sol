// SPX-License-Identifier: GPL-3.0-or-later
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
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
  }

  // 1. register a new parking space. This will be set to disabled and unverified for now
  function registerNewSpace(
    string memory _id,
    string memory _locationWtw,
    string memory _locationHint,
    string memory _rules)
    public {
    // find space with name
    ParkingSpace memory space = carPark[_id];
    // pre-guards
    require(space.landlord == address(0));
    require(bytes(_locationWtw).length < 100);
    require(bytes(_locationHint).length < 1000);
    require(bytes(_rules).length < 2000);
    // set up new registration
    space.landlord = msg.sender;
    space.addedAt = block.timestamp;
    space.locationWtw = _locationWtw;
    space.locationHint = _locationHint;
    space.rules = _rules;
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

  // at any point in time, the space is available and public
  function getSpace(string memory _id) public view returns (ParkingSpace memory) {
    ParkingSpace memory space = carPark[_id];
    require(space.landlord != address(0), 'NOT_REGISTERED');
    return space;
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

}