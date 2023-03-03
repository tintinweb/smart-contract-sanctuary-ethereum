// SPDX-License-Identifier: GNU
pragma solidity ^0.8.9;

contract TrueMile {
    struct Car {
        string licensePlate;
        address owner;
        uint256 mileage;
    }

    mapping(string => Car) private cars; //mappa che associa ad ogni targa un oggetto macchina
    mapping(string => uint256[]) private mileageRecords; // mappa che associa ad ogni targa il suo registro di km registrati
    mapping(string => address[]) private owners; //mappa che associa a una automobile la lista dei suioi proprietari nel tempo

    function addCar(string memory licensePlate, uint256 mileage) public {
        require(cars[licensePlate].owner == address(0), "Car already exists");
        Car memory newCar = Car(licensePlate, msg.sender, mileage);
        cars[licensePlate] = newCar;
        mileageRecords[licensePlate].push(mileage);
        owners[licensePlate].push(msg.sender);
    }

    function updateMileage(string memory licensePlate, uint256 mileage) public {
        require(
            cars[licensePlate].owner == msg.sender,
            "You do not own this car"
        );
        require(
            mileage > cars[licensePlate].mileage,
            "New mileage must be greater than current mileage"
        );
        cars[licensePlate].mileage = mileage;
        mileageRecords[licensePlate].push(mileage);
    }

    function getCarByLicencePlate(
        string memory licensePlate
    ) public view returns (string memory, address, uint256) {
        require(cars[licensePlate].owner != address(0), "Car not found");
        return (
            cars[licensePlate].licensePlate,
            cars[licensePlate].owner,
            cars[licensePlate].mileage
        );
    }

    function getLatestMileage(
        string memory licensePlate
    ) public view returns (uint256) {
        require(cars[licensePlate].owner != address(0), "Car not found");
        uint256[] memory records = mileageRecords[licensePlate];
        if (records.length == 0) {
            return cars[licensePlate].mileage;
        } else {
            return records[records.length - 1];
        }
    }

    function getMileageRecord(
        string memory licensePlate
    ) public view returns (uint256[] memory) {
        require(cars[licensePlate].owner != address(0), "Car not found");
        return mileageRecords[licensePlate];
    }

    function changeOwner(string memory licensePlate, address newOwner) public {
        require(cars[licensePlate].owner != address(0), "Car not found");
        cars[licensePlate].owner = newOwner;
        owners[licensePlate].push(newOwner);
    }

    function getOwners(
        string memory licensePlate
    ) public view returns (address[] memory) {
        require(cars[licensePlate].owner != address(0), "Car not found");
        return owners[licensePlate];
    }
}