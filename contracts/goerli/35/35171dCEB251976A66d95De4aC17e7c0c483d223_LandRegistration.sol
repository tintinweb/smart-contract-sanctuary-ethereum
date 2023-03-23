// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandRegistration {
    struct Land {
        address owner;
        string county;
        string subcounty;
        string location;
        string village;
        int256 latitude;
        int256 longitude;
        uint256 size;
        uint256 value;
        bool forSale;
    }

    mapping(uint256 => Land) public landRegistry;
    mapping(address => uint256) public landOwned;

    event LandRegistered(
        uint256 id,
        address owner,
        string county,
        string subcounty,
        string location,
        string village,
        int256 latitude,
        int256 longitude,
        uint256 size,
        uint256 value
    );
    event LandTransferred(uint256 id, address from, address to);
    event LandPutUpForSale(uint256 id, uint256 value);
    event LandSold(uint256 id, address buyer, uint256 value);

    uint256 public nextId;

    function registerLand(
        string memory _county,
        string memory _subcounty,
        string memory _location,
        string memory _village,
        int256 _latitude,
        int256 _longitude,
        uint256 _size,
        uint256 _value
    ) public returns (Land memory) {
        landRegistry[nextId] = Land(
            msg.sender,
            _county,
            _subcounty,
            _location,
            _village,
            _latitude,
            _longitude,
            _size,
            _value,
            false
        );
        landOwned[msg.sender] = nextId;
        emit LandRegistered(
            nextId,
            msg.sender,
            _county,
            _subcounty,
            _location,
            _village,
            _latitude,
            _longitude,
            _size,
            _value
        );
        nextId++;
        return landRegistry[nextId - 1];
    }

    function transferLand(address _to, uint256 _id) public {
        Land storage land = landRegistry[_id];
        require(msg.sender == land.owner, "You are not the owner of this land");
        landOwned[land.owner] = 0;
        landOwned[_to] = _id;
        land.owner = _to;
        emit LandTransferred(_id, msg.sender, _to);
    }

    function putLandUpForSale(uint256 _id, uint256 _value) public {
        Land storage land = landRegistry[_id];
        require(msg.sender == land.owner, "You are not the owner of this land");
        land.value = _value;
        land.forSale = true;
        emit LandPutUpForSale(_id, _value);
    }

    function buyLand(uint256 _id) public payable {
        Land storage land = landRegistry[_id];
        require(
            msg.value == land.value,
            "The amount sent does not match the land value"
        );
        payable(land.owner).transfer(msg.value);
        land.forSale = false;
        land.owner = msg.sender;
        landOwned[msg.sender] = _id;
        emit LandSold(_id, msg.sender, msg.value);
    }

    function getLand(uint256 _id) public view returns (Land memory) {
        return landRegistry[_id];
    }

    function getLandOwned() public view returns (Land memory) {
        return landRegistry[landOwned[msg.sender]];
    }

    function getLandOwnedId() public view returns (uint256) {
        return landOwned[msg.sender];
    }

    function getLandOwnedAddress() public view returns (address) {
        return landRegistry[landOwned[msg.sender]].owner;
    }

    function getAllLands() public view returns (Land[] memory) {
        Land[] memory lands = new Land[](nextId);
        for (uint256 i = 0; i < nextId; i++) {
            lands[i] = landRegistry[i];
        }
        return lands;
    }

    function getAllLandsForSale() public view returns (Land[] memory) {
        Land[] memory lands = new Land[](nextId);
        uint256 count = 0;
        for (uint256 i = 0; i < nextId; i++) {
            if (landRegistry[i].forSale) {
                lands[count] = landRegistry[i];
                count++;
            }
        }
        return lands;
    }
}