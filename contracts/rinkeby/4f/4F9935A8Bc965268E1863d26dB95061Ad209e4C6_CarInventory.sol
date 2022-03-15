// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CarInventory {
 event addCarEvent(uint256 _price, address _carAddress);
 struct Car {
     uint256 price;
     address carAddress;
 }
 
 //Car list of this inventory
 Car[] public cars;

 mapping(address => uint256) public carToID;
 mapping(uint256 => address) public carToOwner;

 // Function that allow to add new cars
 // _price: price of the car
 // _carAddress; address where new car will be allocated.
 function addCar(uint256 _price, address _carAddress) public {
    carToID[_carAddress] = cars.length;
    cars.push(Car(_price, _carAddress));
    emit addCarEvent(_price, _carAddress);
 }

 function recordSale(address _carAddress, address _buyer) public {
     carToOwner[carToID[_carAddress]] = _buyer;     
 }
}