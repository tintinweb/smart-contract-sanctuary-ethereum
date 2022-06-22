/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

    pragma solidity >=0.7.0 <0.9.0;

    contract Ownable {
        address public owner;

        event OwnershipRenounced(address indexed previousOwner);
        event OwnershipTransferred(
            address indexed previousOwner,
            address indexed newOwner
        );

        /**
        * @dev The Ownable constructor sets the original `owner` of the contract to the sender
        * account.
        */
        constructor() {
            owner = msg.sender;
        }

        /**
        * @dev Throws if called by any account other than the owner.
        */
        modifier onlyOwner() {
            require(msg.sender == owner);
            _;
        }

        /**
        * @dev Allows the current owner to relinquish control of the contract.
        */
        function renounceOwnership() public onlyOwner {
            emit OwnershipRenounced(owner);
            owner = address(0);
        }

        /**
        * @dev Allows the current owner to transfer control of the contract to a newOwner.
        * @param _newOwner The address to transfer ownership to.
        */
        function transferOwnership(address _newOwner) public onlyOwner {
            _transferOwnership(_newOwner);
        }

        /**
        * @dev Transfers control of the contract to a newOwner.
        * @param _newOwner The address to transfer ownership to.
        */
        function _transferOwnership(address _newOwner) internal {
            require(_newOwner != address(0));
            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
        }
    }

    contract EMRRecord is Ownable {
        mapping(address => bool) whitelistedAddresses;

        struct Patient {
            address pat_address;
            uint256 pat_Id;
            string email;
            uint256[] medicalreport;
        }

        mapping(address => Patient) public patients;

        struct MedicalReport {
            string docname;
            string docpath;
            bool isActive;
            uint256 index;
        }

        mapping(uint256 => MedicalReport) public medicalreports;
        uint256 public MedicalReportIndex;

        constructor() {
            whitelistedAddresses[msg.sender] = true;
        }

        modifier isWhitelisted(address _address) {
            require(
                whitelistedAddresses[_address],
                "Whitelist: You need to be whitelisted"
            );
            _;
        }

        function Add_Whitelist(address _address) public onlyOwner {
            whitelistedAddresses[_address] = true;
        }

        function verifyUser(address _whitelistedAddress)
            public
            view
            returns (bool)
        {
            bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
            return userIsWhitelisted;
        }

        /*
        * Sign Up Patients
        */

        function RegisterPatient(
            address _patuseraddress,
            uint256 _patid,
            string memory _email,
            uint256[] memory _medicalreport
        ) public isWhitelisted(msg.sender) {
            require(
                _patuseraddress != patients[_patuseraddress].pat_address,
                "Patient Already Registered"
            );

            patients[_patuseraddress] = Patient(
                _patuseraddress,
                _patid,
                _email,
                _medicalreport
            );
        }

        /* 
        *Add medical Record for the patient
        */

        function AddMedicalReport(
            address _patuseraddress,
            string memory _docname,
            string memory _docpath
        ) public isWhitelisted(msg.sender) {
            require(
                _patuseraddress == patients[_patuseraddress].pat_address,
                "Entered Address doesnt exist!"
            );

            MedicalReportIndex++;
            medicalreports[MedicalReportIndex] = MedicalReport(
                _docname,
                _docpath,
                true,
                MedicalReportIndex
            );

            patients[_patuseraddress].medicalreport.push(MedicalReportIndex);
        }


        function GetMedicalReports(address _addr) public view returns(uint256[] memory){
        return patients[_addr].medicalreport;
    }

    }