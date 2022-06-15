// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

error NotOwner();

contract Iot {
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    struct stats {
        int256 temperature;
        int256 humidity;
        int256 moisture;
    }

    stats iotReading;

    function updateIot(
        int256 _temperature,
        int256 _humidity,
        int256 _moisture
    ) public {
        iotReading = stats(_temperature, _humidity, _moisture);
    }

    function readStats() public view returns (stats memory) {
        return iotReading;
    }

    // modifier onlyOwner() {
    //     if (msg.sender != i_owner) {
    //         revert NotOwner();
    //     }
    //     _;
    // }
}