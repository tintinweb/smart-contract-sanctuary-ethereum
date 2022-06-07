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
        mapping(bytes32 => uint256) timestamp;
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
        uint256 _timestamp,
        uint256 _vaccineCode,
        uint256 _vaccineDose
    );

    function registerVaccination(
        address _personAddress,
        address _centreAddress,
        uint256 _timestamp,
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
            vaccinationCentre.centreIsRegistered(_centreAddress),
            "You cannot register your vaccination from this registration centre"
        );

        VaccinationHistory storage record = vaccinationsDatabase[msg.sender];

        if (!record.isRegistered) {
            record.isRegistered = true;
            record.personId = generatePersonId(
                _fullName,
                _birthDate,
                _passportNumber,
                _nationality,
                msg.sender
            );
        }

        bytes32 _proof = generateVaccinationProof(
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

    function generatePersonId(
        string memory _fullName,
        string memory _birthDate,
        string memory _passportNumber,
        string memory _nationality,
        address _personAddress
    ) public pure returns (bytes32) {
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

    function generateVaccinationProof(
        address _centreAddress,
        uint256 _timestamp,
        uint256 _vaccineCode,
        uint256 _vaccineDose,
        bytes32 _personId
    ) public pure returns (bytes32) {
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

    function generateUserOTP() public view returns (bytes32) {
        return
            bytes32(
                uint256(vaccinationsDatabase[msg.sender].personId) +
                    block.timestamp
            );
    }

    function validateVaccination(
        string memory _fullName,
        string memory _birthDate,
        string memory _passportNumber,
        string memory _nationality,
        address _area,
        bytes32 _userOTP
    ) public view {
        bytes32 _expectedOTPMin = bytes32(
            uint256(
                generatePersonId(
                    _fullName,
                    _birthDate,
                    _passportNumber,
                    _nationality,
                    msg.sender
                )
            ) +
                block.timestamp -
                30
        );

        bytes32 _expectedOTPMax = bytes32(
            uint256(
                generatePersonId(
                    _fullName,
                    _birthDate,
                    _passportNumber,
                    _nationality,
                    msg.sender
                )
            ) + block.timestamp
        );

        require(
            (_expectedOTPMin < _userOTP) && (_expectedOTPMax >= _userOTP),
            "OTP is expired"
        );

        VaccinationHistory storage record = vaccinationsDatabase[msg.sender];
        require(record.isRegistered, "Vaccination is not registered");

        uint256 _noOfRulesMet;
        bytes32[] memory _vaccineProofs = record.vaccineProofs;
        for (uint256 i = 0; i < _vaccineProofs.length; i++) {
            bool _outcome = vaccinationValidator.vaccinationIsValid(
                _area,
                record.vaccineCode[_vaccineProofs[i]],
                record.vaccineDose[_vaccineProofs[i]]
            );
            if (_outcome) {
                _noOfRulesMet++;
            }
        }
        if (_noOfRulesMet != vaccinationValidator.getRuleCount(_area)) {
            revert("You have not met the vaccination rules for this area");
        }
    }

    function getVaccinationProofs() public view returns (bytes32[] memory) {
        VaccinationHistory storage record = vaccinationsDatabase[msg.sender];
        return record.vaccineProofs;
    }

    function userIsRegistered() public view returns (bool) {
        VaccinationHistory storage record = vaccinationsDatabase[msg.sender];
        if (record.isRegistered) {
            return true;
        }
        return false;
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

    function ruleIsRegistered(address _area) public view returns (bool) {
        if (ruleDatabase[_area].isRegistered) {
            return true;
        }
        return false;
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
        require(
            vaccineApproved,
            "The used vaccine is not accepted in the area"
        );

        require(
            rule.dose[_vaccineCode] == _vaccineDose,
            "The used vaccine has insufficient dose for the area"
        );
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

    function getRuleCount(address _area) public view returns (uint256) {
        return ruleDatabase[_area].ruleCount;
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

    function centreIsRegistered(address _centreAddress)
        public
        view
        returns (bool)
    {
        Centre storage centre = centreDatabase[_centreAddress];
        if (centre.isRegistered) {
            return true;
        }
        return false;
    }

    function getCentreName(address _centreAddress)
        public
        view
        returns (string memory)
    {
        require(
            centreIsRegistered(_centreAddress),
            "The centre address does not exist"
        );
        return centreDatabase[_centreAddress].name;
    }

    function getCentreLocation(address _centreAddress)
        public
        view
        returns (string memory)
    {
        require(
            centreIsRegistered(_centreAddress),
            "The centre address does not exist"
        );
        return centreDatabase[_centreAddress].location;
    }
}