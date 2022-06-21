//SPDX-License-Identifier:MIT


pragma solidity ^0.8.0;

contract SimpleStorage{

    uint public  favorateNumber;

    function store(uint _number) external {
        favorateNumber = _number;
    }

    function getNumber() external view returns(uint){
        return favorateNumber;
    }
}