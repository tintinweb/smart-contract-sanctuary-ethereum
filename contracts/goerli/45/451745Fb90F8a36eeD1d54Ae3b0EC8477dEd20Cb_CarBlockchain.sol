// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

error NotOwner();
error NotServiceWorker();

struct CarData {
    string color;
    string price; 
}

struct CarD {
    bytes32 ownerDetail;
    bytes32 modelDetail;
    bytes32 carCost;
    bytes32 carLoanOrBankDetail;
    bytes32 showroomName;
    bytes32 showroomAddress;
    bytes32 showroomId;
    uint256 issuedDate;
    bytes32 additionalDetail;
}

contract CarBlockchain {

    address public immutable i_owner; 
    mapping(uint256 => CarData) public cars;
    mapping(address => bool) public serviceWorkers; 

    /* Events */
    event CarDataAdded(address indexed serviceWorker, uint256 indexed VIN, CarData carData);

    constructor() {
        i_owner = msg.sender;
    }

    function addServiceWorker(address add) onlyOwner public{
        serviceWorkers[add] = true;
    }
    function revokeServiceWorkerAccess(address add) onlyOwner public {
        serviceWorkers[add] = false;
    }
    function getServiceWorker(address add) public onlyOwner view returns (bool) {
        return serviceWorkers[add];
    }

    function addNewCar(uint256 VIN) onlyServiceWorker public {
        cars[VIN] = CarData('', '');
    }
    function addCarData(uint256 VIN, CarData memory carData) onlyServiceWorker public {
        cars[VIN] = carData;
        emit CarDataAdded(msg.sender, VIN, carData);
    }

    function getCarData(uint256 VIN) public view returns (CarData memory){
        return cars[VIN];
    }


    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier onlyServiceWorker {
        if (serviceWorkers[msg.sender] != true) revert NotServiceWorker();
        _;
    }
}