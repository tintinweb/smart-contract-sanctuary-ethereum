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
    postPaid
}

struct Issue {
    int128 policyNo;
    int64 date;
    int128 rideId;
    PolicyType policyType;
    PolicyRiskOption policyRisk;
    string productName;
}

struct Insured {
    string name;
    string addressLocation;
    string personalFinancialId;
    int64 phone;
    string birthDate;
}

struct Coverage {
    string name;
    int256 maxIndenization;
    int64 dtStartsCoverage;
    int64 gracePeriod;
    int256 priceWithoutTax;
    int256 rateTax;
    int256 priceWithTax;
    int64 effectiveDt;
    int64 expiryDt;
    int256 claimScore;
}

struct Bagage {
    string description;
    int256 estValue;
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
    int64 addressDt;
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
    int64 phone;
}

struct BrokerCompany {
    string name;
    string CompanyId;
    string licenseNumber;
    string eMail;
    string addressLocation;
    int64 phone;
}

struct ThirdPartAdm {
    string name;
    string CompanyId;
    string eMail;
    string addressLocation;
    int64 phone;
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

contract PolicyBeta {

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

    constructor() {
        issue = Issue(880212022000053100000007, 1674764470, 836704628674, PolicyType.PersonalAccidents, PolicyRiskOption.PrePaid, "PersonalAccidents");
        insured = Insured(
            "Joao Moraes",
            "Rua das Couves, 700",
            "000.000.000-00",
            11999999999,
            "10/23/1980"
        );
        coverages.push(
            Coverage("Personal Accidents", 7500000, 1674766473, 0, 950, 69, 1020, 1674766473, 1706300470, 0)
        );
        travels.push(
            Travel(
                unicode"Av Alcantara Machado, 700 - Mooca - São Paulo / SP",
                "-23.548090",
                "-23.548090",
                1674766803,
                TravelLocation.Origin
            )
        );
        travels.push(
            Travel(
                unicode"Av Alcantara Machado, 700 - Mooca - São Paulo / SP",
                "-23.548090",
                "-23.548090",
                1674766803,
                TravelLocation.Pickup
            )
        );
        travels.push(
            Travel(
                unicode"Rua Oriente, 255 - Brás - São Paulo / SP",
                "-23.537900",
                "-23.548090",
                1674766803,
                TravelLocation.Destiny
            )
        );
        driver = Driver(
            unicode"José das Couves",
            "000.000.000-00"
        );
        insurerCompany = InsurerCompany(
            unicode"88i 1",
            "00.000.000/0000-00",
            "12345",
            "[email protected]",
            unicode"Rua das ruas, 300 - Centro - São Paulo / SP",
            11999999999
        );
        brokerCompanies.push(
            BrokerCompany(
                unicode"88i 2",
                "00.000.000/0000-00",
                "12345",
                "[email protected]",
                unicode"Rua das ruas, 300 - Centro - São Paulo / SP",
                11999999999
            )
        );
        thirdPartAdm = ThirdPartAdm(
            unicode"88i 3",
            "00.000.000/0000-00",
            "[email protected]",
            unicode"Rua das ruas, 300 - Centro - São Paulo / SP",
            11999999999
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