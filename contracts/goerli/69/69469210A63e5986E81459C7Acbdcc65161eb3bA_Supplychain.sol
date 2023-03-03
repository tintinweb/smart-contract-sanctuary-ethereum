// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Supplychain {
    struct Shipment{
        address owner;
        string title;
        string category;
        string sender;
        string logistics;
        string receiver;
        string description;
        string commonDocuments;
        string confidentialDocuments;
        string image;
    }

    // Check if the mapping is public
    mapping(uint256 => Shipment) public shipments;

    uint256 public numberOfShipments = 0;

    function createShipment(address _owner,string memory _title, string memory _category, string memory _sender, string memory _logistics, string memory _receiver, string memory _description, string memory _commonDocuments, string memory _confidentialDocuments, string memory _image) public returns (uint256) {
        Shipment storage shipment = shipments[numberOfShipments];
        shipment.owner = _owner;
        shipment.title = _title;
        shipment.category = _category;
        shipment.sender = _sender;
        shipment.logistics = _logistics;
        shipment.receiver = _receiver;
        shipment.description = _description;
        shipment.commonDocuments = _commonDocuments;
        shipment.confidentialDocuments = _confidentialDocuments;
        shipment.image = _image;

        numberOfShipments++;

        return numberOfShipments - 1;
    }

    function getShipments() public view returns (Shipment[] memory){
        Shipment[] memory allShipments = new Shipment[](numberOfShipments);

        for(uint i = 0; i < numberOfShipments; i++){
            Shipment storage item = shipments[i];

            allShipments[i] = item;
        }

        return allShipments;
    }

}