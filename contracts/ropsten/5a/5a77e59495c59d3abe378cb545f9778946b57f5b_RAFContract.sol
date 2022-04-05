/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RAFContract {
 
    mapping(address => uint8) public owners;
    string public message;

    event UpdateMessage(address sender, string newMessage); 

    constructor() {
        owners[0x5a86C2e675e291bbc1e70549CE953ea6454c3658] = 1;
        owners[0x50e4861837b3CA72C7Caa04954aD593D4c2850d8] = 1;
        owners[0xb7eA7C538b649E18B702Ee1bF91f8db78F1c553D] = 1;
        owners[0x83e683A0777FEFD207817d1b459B3EdcC6AAdc56] = 1;
        owners[0x5e3D08746187b9ac827e7A2F4Bc2Ab5745811371] = 1;
        owners[0x53a9576363AB061F9C024876e4105B4e30a6345d] = 1;
        owners[0xc8df09d6DF8A25FBb4f9912C003bBDccEd68007A] = 1;
        owners[0x4B5F5C5CBE2410D09FC93F76cAA9fEE2826e5B22] = 1;
        owners[0x1270f932335d27F92dD8b56a586f42B5c8f1085F] = 1;
        owners[0xb7B64766D8D13fb88ADFC1684188A90b751c4e0b] = 1;
        owners[0x40A6573B117f0e5C48Ec2754E94137E4dD0A796a] = 1;
        owners[0x2d45361b6ad9812F4FdA1740493aBff09bbF3CEA] = 1;
        owners[0x5E36ee824ee289368d4d7B220D16e70641a24a0A] = 1;
        message = "init poruka";
    }

    function updateMessage(string memory _newMessage) public {
        require(owners[msg.sender] == 1, "Not an owner");
        message = _newMessage;
        emit UpdateMessage(msg.sender, message);
        
        return;
    }










    
}