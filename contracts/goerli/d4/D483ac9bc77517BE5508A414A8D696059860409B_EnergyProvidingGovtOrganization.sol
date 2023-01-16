// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EnergyProvidingGovtOrganization {
    address owner = msg.sender;
    mapping (uint256=>uint256) public billOfMeter;

    function storeMeterBill(uint256 meterNum, uint256 bill) public {
        require(owner == msg.sender);
        billOfMeter[meterNum] = bill;
    }

    function payBill(uint256 meterNum) external payable{
        require(billOfMeter[meterNum] == msg.value);
        billOfMeter[meterNum] = 0;
    }
}