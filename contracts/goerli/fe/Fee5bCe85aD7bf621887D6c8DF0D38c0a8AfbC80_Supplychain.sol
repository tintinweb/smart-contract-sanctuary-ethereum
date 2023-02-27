// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Supplychain {
    struct Shipment{
        string title;
        string category;
        address sender;
        address logistics;
        address receiver;
        string description;
        string commonDocuments;
        string confidentialDocuments;
        string image;
    }

    // Check if the mapping is public
    mapping(uint256 => Shipment) public shipments;

    uint256 public numberOfShipments = 0;

    function createShipment(string memory _title, string memory _category, address _sender, address _logistics, address _receiver, string memory _description, string memory _commonDocuments, string memory _confidentialDocuments, string memory _image) public returns (uint256) {
        Shipment storage shipment = shipments[numberOfShipments];

        shipment.title = _title;
        shipment.category = _category;
        shipment.sender = _sender;
        shipment.logistics = _logistics;
        shipment.receiver = _receiver;
        shipment.description = _description;
        shipment.commonDocuments = _commonDocuments;
        shipment.confidentialDocuments = _confidentialDocuments;

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

    constructor() {}
}