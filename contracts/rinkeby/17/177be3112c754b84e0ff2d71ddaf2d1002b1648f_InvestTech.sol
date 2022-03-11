/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract InvestTech {
    address public administrator;

    struct PL {
        uint256 pl;
        bool isSet;
    }

    struct Fund {
        string name;
        mapping (uint => PL) dateToPl;
        bool isSet;
    }

    mapping(uint => Fund) idToFund;

    event FundCreated(string name, uint id);
    event PlAdded(uint fundId, uint date, uint pl);


    constructor() {
        administrator = msg.sender;
    }

    function registerFund(string memory name, uint id) public {
        require (
            msg.sender == administrator,
            "Only the administrator can add a new Fund."
        );

        Fund storage fund = idToFund[id];

        require (
            fund.isSet == false,
            "A Fund with this Id has already been created."
        );

        fund.name = name;
        fund.isSet = true;

        emit FundCreated(name, id);
    }

    function getFundName (uint id) public view returns (string memory _name) {
        // Fund storage fund = idToFund[id];
        _name = idToFund[id].name;
    }

    function addPlByDate(uint fundId, uint _date, uint _pl) external {
        require (
            msg.sender == administrator,
            "Only the administrator can add a new PL."
        );

        Fund storage fund = idToFund[fundId];
        require (
            fund.isSet == true,
            "Invalid Fund Id"
        );

        PL storage pl = fund.dateToPl[_date];
        require (
            pl.isSet == false,
            "PL has already been set for this date"
        );

        pl.pl = _pl;
        pl.isSet = true;

        emit PlAdded(fundId, _date, _pl);
    }

    function getPl (uint fundId, uint _date) external view returns (uint _pl) {
        Fund storage fund = idToFund[fundId];
        PL storage pl = fund.dateToPl[_date];
        _pl = pl.pl;
    }

}