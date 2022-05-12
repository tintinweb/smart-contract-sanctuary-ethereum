//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyManager {
    Property[] public properties;

    event List(address _propertyOwner, uint _availableFrom, uint _availableTo,  uint256 _pricePerDay, string  _metadata);
    event Delist(address _propertyOwner, address _property);
    
    function list(uint _availableFrom, uint _availableTo,  uint256 _pricePerDay, string memory _metadata) public {
        properties.push( new Property(msg.sender, _availableFrom, _availableTo, _pricePerDay, _metadata));

        emit List(msg.sender, _availableFrom, _availableTo, _pricePerDay, _metadata);
    }

    // TODO remove
    function listTest() public {
        uint today = block.timestamp / (24 * 60 * 60);
        properties.push( new Property(msg.sender, today, today + 5, 1 ether, "metadata_string"));
    }

    function delist(uint index) public{
        require(address(properties[index]) != address(0), "no property at that index");
        require(msg.sender == properties[index].propertyOwner(), "you are not the owner");
        require(!properties[index].hasOutstandingBookings(), "there are outstanding bookings");

        emit Delist(msg.sender, address(properties[index]));

        delete properties[index];
    }

    function getProperties() public view returns ( Property[] memory) {
        return properties;
    }

    function getMeta(uint index)  public view returns ( string memory) {
        string memory s = properties[index].getMetadata();
        return s;
    }
}

contract Property {

    address public propertyOwner;
    uint public availableFrom;
    uint public availableTo;
    uint256 public pricePerDay;
    string public metadata;

    mapping(uint => address)  public availability;

    
    event Rent(address _renter, uint rentFrom, uint rentTo, address _property);
    event Cancel(address _renter,uint rentFrom, uint rentTo, address _property);

    constructor(address _propertyOwner, uint _availableFrom, uint _availableTo,  uint256 _pricePerDay, string memory _metadata) {
        propertyOwner=_propertyOwner;
        availableFrom=_availableFrom;
        availableTo=_availableTo;
        pricePerDay=_pricePerDay;
        metadata=_metadata;
    }

    modifier isAvailable(uint rentStart, uint rentEnd){
        // TODO check that it is not in the past 
        require(rentStart < availableTo &&  rentStart >= availableFrom, "rentStart out of availability range");
        require(rentEnd <= availableTo && rentEnd > availableFrom , "rentEnd out of availability range");
        require(rentEnd > rentStart , "rentEnd must be after rendStart");
        for(uint i=rentStart; i<rentEnd; i++){
            require(availability[i] == address(0), "flat already occupied");
        }
        _;
    }

    modifier isRenter(uint rentStart, uint rentEnd){
        for(uint i=rentStart; i<rentEnd; i++){
            require(availability[i] == msg.sender, "you are not the renter");
        }
        _;
    }

    modifier isFuture(uint rentStart, uint rentEnd){
        require(rentStart >= currentDay(), "rentStart is in the past");
        require(rentEnd >= currentDay(), "rentEnd is in the past");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == propertyOwner, "You are not the owner!");
        _;
    }


    function rent(uint rentFrom, uint rentTo) public payable isFuture(rentFrom, rentTo) isAvailable(rentFrom, rentTo) {
        require(msg.value == (rentTo - rentFrom)*pricePerDay, "wrong amount of money");
        for(uint i=rentFrom; i<rentTo; i++) {
            availability[i] = msg.sender;
        }
        emit Rent(msg.sender, rentFrom, rentTo, address(this));
    }


    function cancel(uint rentFrom, uint rentTo) public isFuture(rentFrom, rentTo) isRenter(rentFrom, rentTo) {
        for(uint i=rentFrom; i<rentTo; i++) {
            availability[i] = address(0);
        }
        
        payable(msg.sender).transfer((rentTo - rentFrom) * pricePerDay);
            
        emit Cancel(msg.sender, rentFrom, rentTo, address(this));

    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function collect() public onlyOwner {
        require(currentDay() > availableFrom, "too early to collect");
        uint lastPossibleTime = currentDay() > availableTo ? availableTo : currentDay();
        uint counter = 0;
        for(uint i=availableFrom; i<lastPossibleTime; i++) {
             if(availability[i] != address(0)) {
                counter++;
                availability[i] = address(0);
             }
        }

        payable(msg.sender).transfer(counter * pricePerDay);
    }

    function hasOutstandingBookings() public view returns(bool) {
        for(uint i=availableFrom; i<availableTo; i++) {
             if(availability[i] != address(0)) {
                return true;
             }
        }
        return false;
    }

    function currentDay() internal view returns(uint) {
        return block.timestamp / (24 * 60 * 60);
    }

    function getMetadata() public view returns(string memory) {
        return  metadata;
    }
}