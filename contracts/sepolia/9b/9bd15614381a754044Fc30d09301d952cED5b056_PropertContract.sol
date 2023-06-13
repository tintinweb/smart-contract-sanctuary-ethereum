// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract PropertContract {
    struct Location {
        uint256 latitude;
        uint256 longitude;
    }

    struct Buyer {
        address investor;
        uint256 amount;
    }

    struct Date {
        uint256 added_at;
        uint256 closes_at;
    }

    struct Property {
        address seller;
        string name;
        string description;
        uint256 price;
        uint256 invested;
        Location location;
        Date date;
        uint256 deadline;
        string[] images;
        Buyer[] buyers;
    }

    mapping(uint256 => Property) public properties;
    uint256 public property_num = 0;

    // Creates new property
    function createProperty(
        address _seller,
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _latitude,
        uint256 _longitude,
        uint256 _added,
        uint256 _closes,
        string[] memory _images
    ) public returns (uint256) {
        Date memory _date = Date(_added, _closes);
        Location memory _location = Location(_latitude, _longitude);
        Property storage property = properties[property_num];

        property.seller = _seller;
        property.name = _name;
        property.date = _date;
        property.location = _location;
        property.description = _description;
        property.images = _images;
        property.price = _price;
        property_num++;

        return property_num - 1;
    }

    function getProperties() public view returns (Property[] memory) {
        Property[] memory all_properties = new Property[](property_num);
        for (uint i = 0; i < property_num; i++) {
            Property storage item = properties[i];
            all_properties[i] = item;
        }
        return all_properties;
    }

    // Get buyers of property id
    function propertyBuyers(
        uint256 property_id
    ) public view returns (Buyer[] memory) {
        return properties[property_id].buyers;
    }

    //get property of property id
    function getProperty(
        uint256 property_id
    ) public view returns (Property memory) {
        return properties[property_id];
    }

    // buy property
    function buyProperty(uint256 property_id) public payable {
        uint256 amount = msg.value;
        Property storage property = properties[property_id];
        Buyer[] storage buyers = property.buyers;
        buyers.push(Buyer(msg.sender, msg.value));

        (bool sent, ) = payable(property.seller).call{value: amount}("");
        if (sent) {
            property.invested = property.invested + amount;
        }
    }
}