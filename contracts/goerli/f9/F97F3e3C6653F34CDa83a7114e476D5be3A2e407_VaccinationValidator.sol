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