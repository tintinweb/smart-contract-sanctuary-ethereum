/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Vaccine{
    
    address public owner;

    string[] public vaccineCodes;

    uint256 public entryCountVaccines;

    mapping(string => address) public vaccineManufacturer;
    mapping(string => uint256) public manufactureDate;
    mapping(string => uint256) public expiryDate;
    mapping(string => string) public typeVaccine;

    mapping(address => bool) public isManufacturer;
    mapping(address => bool) public isReceiver;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isRegisteredpatient;
    mapping(address => uint256) public totalDoses;

    struct Dose {
        uint256 timeAdminister;
        string vaccineCode;
        string typeDose;
        address Administrator;
    }

    struct Patient {
        string fullName;
        string cnic;
        string city;
        string state;
        string phone;
        string dob;
    }

    mapping (address => Patient) public patient;
    mapping (address => Dose[]) public dose;

    constructor() public {
        owner = msg.sender;
    }
    
    function addManufacturer(address _account) public {
        require(msg.sender == owner, "Only contract creator can add Manufacturer Account");

        isManufacturer[_account] = true;
    }

    function addAdmin(address _account) public {
        require(msg.sender == owner, "Only contract creator can add Vaccine Administrator Account");

        isAdmin[_account] = true;
    }

    function addVaccine(string memory _vaccineCode,uint256 _manufactureDate,uint256 _expiryDate,string memory _typeVaccine) public {
        require(isManufacturer[msg.sender] == true, "Only Manufactuer may add Vaccine");

        vaccineManufacturer[_vaccineCode] = msg.sender;
        manufactureDate[_vaccineCode] = _manufactureDate;
        expiryDate[_vaccineCode] = _expiryDate;
        typeVaccine[_vaccineCode] = _typeVaccine;

        vaccineCodes.push(_vaccineCode);
        entryCountVaccines = entryCountVaccines + 1;

    }

    function administerDose(string memory _vaccineCode,string memory _typeDose,address receiver ) public
    {
        require(isRegisteredpatient[receiver] == true,"Receiver not registered as patient");
        require(isAdmin[msg.sender] == true,"Only Administator Account may add Dosage Entry");
        dose[receiver].push(Dose(block.timestamp,_vaccineCode,_typeDose,msg.sender));
        totalDoses[receiver] = totalDoses[receiver] + 1;
    }

    function registerPatient(address receiver,string memory fullName,string memory cnic,string memory city,string memory state,string memory phone,string memory dob) public
    {
        require(isRegisteredpatient[receiver] == false,"Patient already registered with this address");
        patient[receiver].fullName = fullName;
        patient[receiver].cnic = cnic;
        patient[receiver].city = city;
        patient[receiver].state = state;
        patient[receiver].phone = phone;
        patient[receiver].dob = dob;
        isRegisteredpatient[receiver] = true;
    }

    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
    }

}