/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CarRegistry {

    address private contractOwner = msg.sender;

    struct Car {
        string name;
        uint number;
        address owner;
    }

    mapping(uint => Car) private carDetails; 

    function getCarByCarNumber(uint _number) public view returns(Car memory) {
        require(_number != 0, "Car number can't be zero");
        require(carDetails[_number].number != 0, "Car not exisits");
        return carDetails[_number];
    }

    function addCarByCarNumber(string memory _name, uint _number) public {
        require(msg.sender == contractOwner, "only contract owner can add cars");
        require(carDetails[_number].number == 0, "Car already exisits");
        carDetails[_number] = Car(_name, _number, contractOwner);
    }

    function transferOwner(address transferTo, uint _number) public {
        require(carDetails[_number].number != 0, "Car not exisits");
        require(carDetails[_number].owner == msg.sender, "Only owner of car can transfer");
        require(transferTo != msg.sender, "can not transfer to oneself");
        carDetails[_number].owner = transferTo;
    }

}