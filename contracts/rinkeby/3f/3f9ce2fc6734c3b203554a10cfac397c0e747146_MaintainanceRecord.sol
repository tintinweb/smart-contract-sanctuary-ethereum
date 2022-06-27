/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// File: record.sol


pragma solidity ^0.8.4;

contract MaintainanceRecord {

    address public owner;
    // mapping (address => uint) public balances;
    
    // Record type
    struct Maintainance {
        string date;   
        string location;
        string maintenanceWorkshop;
        string description;
        string engineer;
    }

    Maintainance newRecord;
    Maintainance[] public maintainance;

    event RecordMaintainance(string date, string location, string maintenanceWorkshop, string description, string engineer);
    event ResetMaintainance(uint recordNum, string description, uint price);
    event GetMaintainance(uint recordNum);

    constructor()  {
        owner = msg.sender;
    }

    // add new record
    function recordMaintainance(string memory  date, string memory location, string memory maintenanceWorkshop, string memory description, string memory engineer) public {
        if (msg.sender != owner) return;

        newRecord.date = date;
        newRecord.location = location;
        newRecord.maintenanceWorkshop = maintenanceWorkshop;
        newRecord.description = description;
        newRecord.engineer = engineer;
        maintainance.push(newRecord);
        emit RecordMaintainance(date, location, maintenanceWorkshop, description, engineer);
    }

    // get record information
    function getMaintainance(uint recordNum) public view returns (string[] memory) {
        // if (recordNum<1 || recordNum>maintainance.length) return;
        // emit GetMaintainance(recordNum);
        string[] memory record_list = new string[](uint256(5));

        record_list[uint256(0)] = maintainance[recordNum-1].date;
        record_list[uint256(1)] = maintainance[recordNum-1].location;
        record_list[uint256(2)] = maintainance[recordNum-1].maintenanceWorkshop;
        record_list[uint256(3)] = maintainance[recordNum-1].description;
        record_list[uint256(4)] = maintainance[recordNum-1].engineer;

        return record_list;
        
    }

    // reset record information
    // function resetMaintainance(uint recordNum, string memory  description, uint price) public {
    //     if (msg.sender != owner) return;
    //     // if (recordNum<1 || recordNum>maintainance.length) return "record not exist";
    //     maintainance[recordNum-1].description = description;
    //     maintainance[recordNum-1].price = price;
    //     emit ResetMaintainance(recordNum, description, price);
    // }

}