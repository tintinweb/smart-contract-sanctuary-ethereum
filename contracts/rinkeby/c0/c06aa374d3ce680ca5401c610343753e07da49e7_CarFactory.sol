/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier:MIT

pragma solidity 0.8.7;

contract Car{
    string model;
    address owner;
    
    constructor(string memory _model) payable {
        model=_model;
        owner=msg.sender;
    }
}

contract CarFactory{
    Car[] cars;
    function makeCar(string memory model) public payable{
        require(msg.value>=1 ether,"not enough money");
        Car car=new Car{value:msg.value}(model);
        cars.push(car);
    }
}