/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    //internal can only be called from this and child contracts
    //external can only be called externally
    //public = internal and external
    //private functions can only be called by this contract, and not children

    struct Car {
        string vin;
        string make;
        string model;
        uint16 year;
        uint16 numOwners;
        bool cleanTitle;
    }

    string favoriteCar = "Porsche 992.2 GT3";

    //assumed to be public in global scope
    Car[] public carArr;

    mapping(string => uint256) vinToId;

    //calldata can't be modified
    //storage makes a global
    //memory is temporary + modifiable within function
    function addCar(
        string calldata _vin,
        string calldata _make,
        string calldata _model,
        uint16 _year,
        uint16 _numOwners,
        bool _cleanTitle
    ) public virtual {
        carArr.push(Car(_vin, _make, _model, _year, _numOwners, _cleanTitle));
        vinToId[_vin] = carArr.length - 1;
    }

    function vinToIndexMap(string calldata _vin) public view returns (uint256) {
        return vinToId[_vin];
    }

    function setFavoriteCar(string calldata _car) public {
        favoriteCar = _car;
    }

    function getFavoriteCar() public view returns (string memory) {
        return favoriteCar;
    }
}