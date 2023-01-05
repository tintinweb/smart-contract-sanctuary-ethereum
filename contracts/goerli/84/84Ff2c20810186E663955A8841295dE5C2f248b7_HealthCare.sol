/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HealthCare {
    address public hospitalAdmin;
    address public labAdmin;

    struct Record {
        uint256 ID;
        uint256 price;
        uint256 signatureCount;
        string testName;
        string date;
        string hospitalName;
        bool isValue;
        address pAddr;
        mapping (address => uint256) signatures;
    }

    constructor(address _labAdmin) {
        hospitalAdmin = msg.sender;
        labAdmin = _labAdmin;
    }

    // Mapping to store records
    mapping (uint256 => Record) public _records;
    uint256[] public recordsArr;

    event recordCreated(uint256 ID, string testName, string date, string hospitalName, uint256 price);
    event recordSigned(uint256 ID, string testName, string date, string hospitalName, uint256 price);

    modifier signOnly {
        require (msg.sender == hospitalAdmin || msg.sender == labAdmin, "You are not authorized to sign this.");
        _;
    }

    modifier checkAuthBeforeSign(uint256 _ID) {
        require(_records[_ID].isValue, "Recored does not exist");
        require(address(0) != _records[_ID].pAddr, "Address is zero");
        require(msg.sender != _records[_ID].pAddr, "You are not authorized to perform this action");
        require(_records[_ID].signatures[msg.sender] != 1, "Same person cannot sign twice.");
        _;

    }

    modifier validateRecord(uint256 _ID) {
        require(!_records[_ID].isValue, "Record with this ID already exists");
        _;
    }

    // Create new record
    function newRecord (
        uint256 _ID,
        string memory _testName,
        string memory _date,
        string memory _hospitalName,
        uint256 price
    )
    validateRecord(_ID) public {
        Record storage _newrecord = _records[_ID];
        _newrecord.pAddr = msg.sender;
        _newrecord.ID = _ID;
        _newrecord.testName = _testName;
        _newrecord.date = _date;
        _newrecord.hospitalName = _hospitalName;
        _newrecord.price = price;
        _newrecord.isValue = true;
        _newrecord.signatureCount = 0;

        recordsArr.push(_ID);
        emit  recordCreated(_newrecord.ID, _testName, _date, _hospitalName, price);
    }

    // Function to sign a record
    function signRecord(uint256 _ID) signOnly checkAuthBeforeSign(_ID) public {
        Record storage records = _records[_ID];
        records.signatures[msg.sender] = 1;
        records.signatureCount++;

        // Checks if the record has been signed by both the authorities to process insurance claim
        if(records.signatureCount == 2)
            emit  recordSigned(records.ID, records.testName, records.date, records.hospitalName, records.price);

    }
}