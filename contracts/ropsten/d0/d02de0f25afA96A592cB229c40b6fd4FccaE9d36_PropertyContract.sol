// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract PropertyContract {
    //vars
    uint256 currentID = 0;
    struct Property { 
        //property id (incrementing from 1+)
        uint256 id;
        //owner of booking
        address owner;
        //current renter
        address renter;
        //check in block timestamp
        uint256 checkIn;
        //check out block timestamp
        uint256 checkOut;
        //is it currently listed
        bool listed;
    }   
    mapping(uint256=>Property) public propertiesListed;

    //fallbacks
    receive() external payable {}
    fallback() external payable {}

    //events
    event NewProperty(Property prop, uint256 blockTime);
    event Delisted(Property prop, uint256 blockTime);
    event Relisted(Property prop, uint256 blockTime);
    event BookedProperty(Property prop, uint256 blockTime);

    function createProperty() public payable returns(uint256) {
        require(msg.value >= 0.1 ether, "NEED 0.1 ETHER");
        Property memory newProp = Property(currentID+1, msg.sender, msg.sender, 0, 0, true);
        propertiesListed[currentID+1] = newProp;
        currentID+=1;
        emit NewProperty(newProp, block.timestamp);
        return currentID;
    }

    //_id refers to the property id
    function delistProperty(uint256 _id) public {
        require(propertiesListed[_id].owner == msg.sender, "NOT OWNER");
        require(propertiesListed[_id].checkOut < block.timestamp, "CANNOT DELIST WHILE BOOKED");
        propertiesListed[_id].listed = false;
        emit Delisted(propertiesListed[_id], block.timestamp);
    }

    //_id refers to the property id
    function relistProperty(uint256 _id) public {
        require(propertiesListed[_id].owner == msg.sender, "NOT OWNER");
        require(!propertiesListed[_id].listed, "NOT DELISTED");
        propertiesListed[_id].listed = true;
        emit Relisted(propertiesListed[_id], block.timestamp);
    }

    //_id refers to the property id
    //_renter is the person who will be renting
    //_days is the number of days to book for
    function bookProperty(uint256 _id, address _renter, uint256 _days) public {
        require(propertiesListed[_id].checkOut < block.timestamp, "ALREADY BOOKED");
        //Also makes sure listing exists, non existent = false
        require(propertiesListed[_id].listed, "DELISTED");
        require(_days > 0);

        propertiesListed[_id].checkIn = block.timestamp;
        propertiesListed[_id].checkOut = block.timestamp + _days * 1 days;
        propertiesListed[_id].renter = _renter;
        emit BookedProperty(propertiesListed[_id], block.timestamp);
    }
}