/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CarInventory {
    
    struct Car {
        string name;
        uint256 price;
        address carAddress;
    }

    Car[] public cars;

    mapping(address =>uint256) public carId;
    mapping(uint256 =>address) public owner;
    
    event Added(string _name, uint256 _price, address _address);


    function addCarToInventory(string memory _name, uint256 _price, address _address) public  {
        require(_price > 0 , "Car price is empty");
        carId[_address] = cars.length;
        cars.push(Car(_name, _price, _address));
        emit Added(_name, _price, _address);
       
    }
    function recordSaleCar(address _carAddress,address _buyer) public  {
        require(_carAddress != _buyer, "Car address and buyer Address must not be the same.");
        owner[carId[_carAddress]] = _buyer;
    }
}