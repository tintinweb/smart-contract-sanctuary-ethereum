/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.0;



// File: Hospital_Management.sol

contract Hospital {
    //address[] public  Patients;
    struct patients {
        uint256 patient_ID;
        string patient_name;
        string disease;
        uint256 age;
        string password;
    }
    patients[] private patient_list;

    function store(
        uint256 _patientID,
        string memory _patientName,
        string memory _disease,
        uint256 _age,
        string memory _password
    ) public payable {
        patient_list.push(
            patients(_patientID, _patientName, _disease, _age, _password)
        );
    }

    function retrieve(uint256 _patientID, string memory _password)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        patients memory details;
        details = patient_list[_patientID];
        require(
            uint256(keccak256(abi.encodePacked(details.password))) ==
                uint256(keccak256(abi.encodePacked(_password))),
            "Validation Failed!!"
        );
        return (
            details.patient_ID,
            details.patient_name,
            details.disease,
            details.age
        );
    }
}