//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Zavod {
    // structs
    enum VehicleType {
        NONE,
        BIKE,
        CAR
    }
    enum VehicleColor {
        NONE,
        RED,
        BLUE,
        YELLOW
    }
    VehicleType private transportType;
    VehicleColor private color;
    uint256 private price;

    // constructor
    constructor(VehicleType _transportType, VehicleColor _color, uint256 _price) {
        transportType = _transportType;
        color = _color;
        price = _price;
    }

    // view functions
    function getTransportType() view external returns (VehicleType) {
        return transportType;
    }
    function getTransportColor() view external returns (VehicleColor) {
        return color;
    }
    function getTransportPrice() view external returns (uint256) {
        return price;
    }

    // change functions
    function changeTransportType(VehicleType _transportType) external {
        transportType = _transportType;
    }
    function changeTransportColor(VehicleColor _color) external {
        color = _color;
    }
    function changeTransportPrice(uint256 _price) external {
        price = _price;
    }
}