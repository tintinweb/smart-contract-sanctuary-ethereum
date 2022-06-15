// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./VaccinationCentre.sol";
import "./VaccinationValidator.sol";

contract VaccinationRegistry {
    struct VaccinationHistory {
        bool isRegistered;
        bytes32 personId;
        bytes32[] vaccineProofs;
        mapping(bytes32 => address) centreAddress;
        mapping(bytes32 => string) timestamp;
        mapping(bytes32 => uint256) vaccineCode;
        mapping(bytes32 => uint256) vaccineDose;
    }

    mapping(address => VaccinationHistory) vaccinationsDatabase;

    VaccinationCentre public vaccinationCentre;
    VaccinationValidator public vaccinationValidator;

    constructor(
        VaccinationCentre _vaccinationCentre,
        VaccinationValidator _vaccinationValidator
    ) {
        vaccinationCentre = _vaccinationCentre;
        vaccinationValidator = _vaccinationValidator;
    }

    event VaccinationRegistered(
        address _personAddress,
        address _centreAddress,
        string _timestamp,
        uint256 _vaccineCode,
        uint256 _vaccineDose
    );

    function registerVaccination(
        address _personAddress,
        address _centreAddress,
        string memory _timestamp,
        uint256 _vaccineCode,
        uint256 _vaccineDose,
        string memory _fullName,
        string memory _birthDate,
        string memory _passportNumber,
        string memory _nationality
    ) public {
        require(
            _personAddress == msg.sender,
            "You cannot register vaccination for this address"
        );

        require(
            vaccinationCentre.getCentreDetails(_centreAddress).isRegistered,
            "You cannot register your vaccination from this registration centre"
        );

        VaccinationHistory storage record = vaccinationsDatabase[msg.sender];

        if (!record.isRegistered) {
            record.isRegistered = true;
            record.personId = _generatePersonId(
                _fullName,
                _birthDate,
                _passportNumber,
                _nationality,
                msg.sender
            );
        }

        bytes32 _proof = _generateVaccinationProof(
            _centreAddress,
            _timestamp,
            _vaccineCode,
            _vaccineDose,
            record.personId
        );

        record.vaccineProofs.push(_proof);
        record.centreAddress[_proof] = _centreAddress;
        record.timestamp[_proof] = _timestamp;
        record.vaccineCode[_proof] = _vaccineCode;
        record.vaccineDose[_proof] = _vaccineDose;

        emit VaccinationRegistered(
            msg.sender,
            _centreAddress,
            _timestamp,
            _vaccineCode,
            _vaccineDose
        );
    }

    function _generatePersonId(
        string memory _fullName,
        string memory _birthDate,
        string memory _passportNumber,
        string memory _nationality,
        address _personAddress
    ) private pure returns (bytes32) {
        bytes32 _personId = keccak256(
            abi.encode(
                _fullName,
                _birthDate,
                _passportNumber,
                _nationality,
                _personAddress
            )
        );
        return _personId;
    }

    function _generateVaccinationProof(
        address _centreAddress,
        string memory _timestamp,
        uint256 _vaccineCode,
        uint256 _vaccineDose,
        bytes32 _personId
    ) private pure returns (bytes32) {
        bytes32 _proof = keccak256(
            abi.encode(
                _centreAddress,
                _timestamp,
                _vaccineCode,
                _vaccineDose,
                _personId
            )
        );
        return _proof;
    }

    function validateVaccination(address _area) public view {
        (
            bool _isRegistered,
            ,
            bytes32[] memory _vaccineProofs,
            ,
            ,
            uint256[] memory _vaccineCodes,
            uint256[] memory _vaccineDoses
        ) = getUserInformation(msg.sender);

        require(_isRegistered, "Vaccination is not registered");

        uint256 _noOfRulesMet;
        for (uint256 i = 0; i < _vaccineProofs.length; i++) {
            bool _outcome = vaccinationValidator.vaccinationIsValid(
                _area,
                _vaccineCodes[i],
                _vaccineDoses[i]
            );
            if (_outcome) {
                _noOfRulesMet++;
            }
        }
        require(
            _noOfRulesMet >= vaccinationValidator.getRule(_area).length,
            "You have not met the vaccination rules for this area"
        );
    }

    function getUserInformation(address _personAddress)
        public
        view
        returns (
            bool,
            bytes32,
            bytes32[] memory,
            address[] memory,
            string[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        require(
            msg.sender == _personAddress,
            "You cannot view details for this address"
        );
        VaccinationHistory storage record = vaccinationsDatabase[msg.sender];
        uint256 _noOfRecords = record.vaccineProofs.length;
        address[] memory _centreAddresses = new address[](_noOfRecords);
        string[] memory _timeStamps = new string[](_noOfRecords);
        uint256[] memory _vaccineCodes = new uint256[](_noOfRecords);
        uint256[] memory _vaccineDoses = new uint256[](_noOfRecords);
        for (uint256 i = 0; i < _noOfRecords; i++) {
            bytes32 _cur = record.vaccineProofs[i];
            _centreAddresses[i] = record.centreAddress[_cur];
            _timeStamps[i] = record.timestamp[_cur];
            _vaccineCodes[i] = record.vaccineCode[_cur];
            _vaccineDoses[i] = record.vaccineDose[_cur];
        }
        return (
            record.isRegistered,
            record.personId,
            record.vaccineProofs,
            _centreAddresses,
            _timeStamps,
            _vaccineCodes,
            _vaccineDoses
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract VaccinationValidator {
    struct Rule {
        bool isRegistered;
        uint256 ruleCount;
        mapping(uint256 => uint256) approvedVaccines;
        mapping(uint256 => uint256) dose;
    }

    mapping(address => Rule) ruleDatabase;

    event VaccinationRuleGenerated(
        address _area,
        uint256 _ruleCount,
        uint256 _approvedVaccine,
        uint256 _dose
    );

    function registerRule(
        address _area,
        uint256 _approvedVaccine,
        uint256 _dose
    ) public {
        require(
            _area == msg.sender,
            "You cannot register a rule for this address"
        );

        Rule storage rule = ruleDatabase[_area];

        if (!rule.isRegistered) {
            rule.isRegistered = true;
        }

        rule.ruleCount++;
        rule.approvedVaccines[rule.ruleCount] = _approvedVaccine;
        rule.dose[_approvedVaccine] = _dose;

        emit VaccinationRuleGenerated(
            _area,
            rule.ruleCount,
            _approvedVaccine,
            _dose
        );
    }

    function vaccinationIsValid(
        address _area,
        uint256 _vaccineCode,
        uint256 _vaccineDose
    ) public view returns (bool) {
        Rule storage rule = ruleDatabase[_area];
        require(
            rule.isRegistered,
            "Vaccination rules are not registered for this area"
        );

        bool vaccineApproved;
        for (uint256 i = 1; i <= rule.ruleCount; i++) {
            if (_vaccineCode == rule.approvedVaccines[i]) {
                vaccineApproved = true;
                break;
            }
        }

        if (!vaccineApproved || rule.dose[_vaccineCode] != _vaccineDose) {
            return false;
        }

        return true;
    }

    function getRule(address _area) public view returns (uint256[2][] memory) {
        uint256 _ruleCount = ruleDatabase[_area].ruleCount;
        uint256[2][] memory _approvedList = new uint256[2][](_ruleCount);
        for (uint256 i = 0; i < _ruleCount; i++) {
            uint256 _approvedVaccine = ruleDatabase[_area].approvedVaccines[
                i + 1
            ];
            uint256 _dose = ruleDatabase[_area].dose[_approvedVaccine];
            _approvedList[i][0] = _approvedVaccine;
            _approvedList[i][1] = _dose;
        }
        return _approvedList;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract VaccinationCentre {
    struct Centre {
        bool isRegistered;
        string name;
        string location;
    }

    mapping(address => Centre) centreDatabase;

    event VaccinationCentreRegistered(
        address _centreAddress,
        string _name,
        string _location
    );

    function registerCentre(
        address _centreAddress,
        string memory _name,
        string memory _location
    ) public {
        require(
            _centreAddress == msg.sender,
            "You are cannot register this address as a vaccination centre"
        );
        Centre storage centre = centreDatabase[_centreAddress];

        if (!centre.isRegistered) {
            centre.isRegistered = true;
        }

        centre.name = _name;
        centre.location = _location;

        emit VaccinationCentreRegistered(_centreAddress, _name, _location);
    }

    function getCentreDetails(address _centreAddress)
        public
        view
        returns (Centre memory)
    {
        return centreDatabase[_centreAddress];
    }
}