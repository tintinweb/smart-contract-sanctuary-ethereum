// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract EnergyProvidingGovtOrg{
    address  admin = msg.sender;
    mapping (uint256=>uint256) public billOfMeter;

    function storeMeterBill(uint256 meterNum, uint256 bill) public{
        require(admin == msg.sender);
        billOfMeter[meterNum] = bill;
    }

    function payBill(uint256 meterNum) external payable{
        require(billOfMeter[meterNum] == msg.value);
        billOfMeter[meterNum] = 0;
    }
}