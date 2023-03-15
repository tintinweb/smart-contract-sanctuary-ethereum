/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CarRegistry {

    struct Car {
        string name;
        uint number;
    }

    mapping(uint => Car) private carDetails; 

    function getCarByCarNumber(uint _number) public view returns(Car memory) {
        require(_number == 0, "Car number can't be zero");
        require(carDetails[_number].number != 0, "Car not exisits");
        return carDetails[_number];
    }

    function addCarByCarNumber(string memory _name, uint _number) public {
        require(carDetails[_number].number == 0, "Car already exisits");
        carDetails[_number] = Car(_name, _number);
    }

}