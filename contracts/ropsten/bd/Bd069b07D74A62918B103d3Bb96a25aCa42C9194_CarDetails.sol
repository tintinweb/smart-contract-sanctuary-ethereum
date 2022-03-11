//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract CarDetails{
    uint public carCount = 0;

    struct Car{
        uint id;
        string carModel;
        uint vin;
        uint mileage;
        uint numOfOwners;
        uint numOfServiceVisits;
        uint numOfReportedAccidents;
    }
    mapping(uint => Car) public cars;

    event AddCar(
        uint id,
        string carModel,
        uint vin,
        uint mileage,
        uint numOfOwners,
        uint numOfServiceVisits,
        uint numOfReportedAccidents
    );

// Gets called when a smart contract is run for the first time
    constructor(string memory model, uint vin, uint mileage, uint numOfOwners, uint numOfServiceVisits, uint numOfReportedAccidents) {
        // Add default car
        createCar(model, vin, mileage, numOfOwners, numOfServiceVisits, numOfReportedAccidents);
    }

    // Put a new car inside the mapping
    function createCar(string memory model, uint vin, uint mileage, uint  numOfOwners, uint numOfServiceVisits, uint numOfReportedAccidents) public {
        carCount++;
        cars[carCount] = Car(carCount, model, vin, mileage, numOfOwners, numOfServiceVisits, numOfReportedAccidents);

        // Trigger event
        emit AddCar(carCount, model, vin, mileage, numOfOwners, numOfServiceVisits, numOfReportedAccidents);
    }
}