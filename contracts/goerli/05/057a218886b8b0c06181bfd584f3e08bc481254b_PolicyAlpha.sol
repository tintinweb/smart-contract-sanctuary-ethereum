/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum PolicyType {
    Travel,
    PersonalAccidents
}

enum PolicyRiskOption {
    PrePaid,
    PostPaid
}

struct Issue {
    uint256 policyNo;
    uint256 date;
    uint256 rideId;
    PolicyType policyType;
    PolicyRiskOption policyRisk;
    string productName;
}

struct Insured {
    string name;
    string addressLocation;
    string personalFinancialId;
    uint256 phone;
    string birthDate;
}

struct Coverage {
    string name;
    uint256 maxIndenization;
    uint256 dtStartsCoverage;
    uint256 gracePeriod;
    uint256 priceWithoutTax;
    uint256 rateTax;
    uint256 priceWithTax;
    uint256 effectiveDt;
    uint256 expiryDt;
    uint256 claimScore;
}

struct Bagage {
    string description;
    uint256 estValue;
    string dimensions;
    int16 weight;
}

enum TravelLocation {
    Origin,
    Pickup,
    Destiny
}

struct Travel {
    string addressLocation;
    string addressLat;
    string addressLng;
    uint256 addressDt;
    TravelLocation location;
}

struct Driver {
    string name;
    string personalFinancialId;
}

struct InsurerCompany {
    string name;
    string CompanyId;
    string licenseNumber;
    string eMail;
    string addressLocation;
    uint256 phone;
}

struct BrokerCompany {
    string name;
    string CompanyId;
    string licenseNumber;
    string eMail;
    string addressLocation;
    uint256 phone;
}

struct ThirdPartAdm {
    string name;
    string CompanyId;
    string eMail;
    string addressLocation;
    uint256 phone;
}

struct Policy {
    Issue issue;
    Insured insured;
    Coverage[] coverages;
    Bagage[] bagages;
    Travel[] travels;
    Driver driver;
    InsurerCompany insurerCompany;
    BrokerCompany[] brokerCompanies;
    ThirdPartAdm thirdPartAdm;
}

uint8 constant _maxInputString = 16;
uint8 constant _maxInputInt = 8;
uint8 constant _coveragesString = 1;
uint8 constant _coveragesInt = 9;
uint8 constant _travelsString = 3;
uint8 constant _travelsInt = 2;
uint8 constant _brokersString = 5;
uint8 constant _brokersInt = 1;

contract PolicyAlpha {

    address internal dead = 0x0000000000000000000000000000000000000000;

    Issue internal issue;
    Insured internal insured;
    Coverage[] internal coverages;
    Bagage[] internal bagages;
    Travel[] internal travels;
    Driver internal driver;
    InsurerCompany internal insurerCompany;
    BrokerCompany[] internal brokerCompanies;
    ThirdPartAdm internal thirdPartAdm;
    Policy internal policy;

    constructor(
         string[_maxInputString]     memory inputsStrings,
        uint256[_maxInputInt]        memory inputsInts,
         string[_coveragesString] [] memory coveragesString,
        uint256[_coveragesInt]    [] memory coveragesInts,
         string[_travelsString]   [] memory travelsString,
        uint256[_travelsInt]      [] memory travelsInt,
         string[_brokersString]   [] memory brokersString,
        uint256[_brokersInt]      [] memory brokersInt
    ) {

        // Apply policy type
        PolicyType _policyType = PolicyType.Travel;
        if(inputsInts[3] == 1) {
            _policyType = PolicyType.PersonalAccidents;
        }
        
        // Apply policy risk
        PolicyRiskOption _policyRiskOption = PolicyRiskOption.PrePaid;
        if(inputsInts[4] == 1) {
            _policyRiskOption = PolicyRiskOption.PostPaid;
        }

        // Apply coverages
        for (uint256 i = 0; i < coveragesString.length; i++) {
            string[_coveragesString] memory coverageString = coveragesString[i];
            uint256[_coveragesInt] memory coverageInts = coveragesInts[i];
            coverages.push(
                Coverage(
                    coverageString[0],
                    coverageInts[0],
                    coverageInts[1],
                    coverageInts[2],
                    coverageInts[3],
                    coverageInts[4],
                    coverageInts[5],
                    coverageInts[6],
                    coverageInts[7],
                    coverageInts[8]
                )
            );
        }

        // Apply travels
        for (uint256 i = 0; i < travelsString.length; i++) {
            string[_travelsString] memory travelString = travelsString[i];
            uint256[_travelsInt] memory travelInt = travelsInt[i];
            
            // Apply travel location
            TravelLocation _travelLocation = TravelLocation.Origin;
            if(travelInt[1] == 1) {
                _travelLocation = TravelLocation.Pickup;
            }
            if(travelInt[1] == 2) {
                _travelLocation = TravelLocation.Destiny;
            }

            travels.push(
                Travel(
                    travelString[0],
                    travelString[1],
                    travelString[2],
                    travelInt[0],
                    _travelLocation
                )
            );
        }

        // Apply brokers
        for (uint256 i = 0; i < brokersString.length; i++) {
            string[_brokersString] memory brokerString = brokersString[i];
            uint256[_brokersInt] memory brokerInt = brokersInt[i];
            brokerCompanies.push(
                BrokerCompany(
                    brokerString[0],
                    brokerString[1],
                    brokerString[2],
                    brokerString[3],
                    brokerString[4],
                    brokerInt[0]
                )
            );
        }

        // Apply Issue
        issue = Issue(
            inputsInts[0],
            inputsInts[1],
            inputsInts[2],
            _policyType,
            _policyRiskOption,
            inputsStrings[0]
        );
        
        // Apply Insured
        insured = Insured(
            inputsStrings[1],
            inputsStrings[2],
            inputsStrings[3],
            inputsInts[5],
            inputsStrings[4]
        );
        
        // Apply Driver
        driver = Driver(
            inputsStrings[5],
            inputsStrings[6]
        );
        
        // Apply InsurerCompany
        insurerCompany = InsurerCompany(
            inputsStrings[7],
            inputsStrings[8],
            inputsStrings[9],
            inputsStrings[10],
            inputsStrings[11],
            inputsInts[6]
        );
        
        // Apply ThirdPartAdm
        thirdPartAdm = ThirdPartAdm(
            inputsStrings[12],
            inputsStrings[13],
            inputsStrings[14],
            inputsStrings[15],
            inputsInts[7]
        );
    }

    function getIssue() public view returns (Issue memory) {
        return issue;
    }

    function getInsured() public view returns (Insured memory) {
        return insured;
    }

    function getCoverages() public view returns (Coverage[] memory) {
        return coverages;
    }

    function getTravels() public view returns (Travel[] memory) {
        return travels;
    }

    function getDriver() public view returns (Driver memory) {
        return driver;
    }

    function getInsurerCompany() public view returns (InsurerCompany memory) {
        return insurerCompany;
    }

    function getBrokerCompanies() public view returns (BrokerCompany[] memory) {
        return brokerCompanies;
    }

    function getThirdPartAdm() public view returns (ThirdPartAdm memory) {
        return thirdPartAdm;
    }

    function getPolicy() public view returns (Policy memory) {
        return policy;
    }
}