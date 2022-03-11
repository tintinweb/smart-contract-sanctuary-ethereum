/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract InvestTech {
    
    
    address public owner;   
    
    struct PL {
        uint256 pl;
        uint32  fundId;
    }

    struct Fund {
        string name; 
        mapping (uint256 => PL) dateToPL;
        bool isSet; 
    }    

    mapping(uint32 => Fund) fundToDate;

    constructor() {
        owner = msg.sender;
    }

    function getPlByDateId(uint256 _date, uint32 _fundId) public view returns (string memory name, uint256 pl) {
        return (fundToDate[_fundId].name, fundToDate[_fundId].dateToPL[_date].pl);
    } 

    function addPlByDate(uint _date, uint _pl, uint32 _fundId, string memory _name) public {
        require (
            msg.sender == owner,
            "Only the owner can add a new PL"
        );
        fundToDate[_fundId].name  = _name; 
        fundToDate[_fundId].dateToPL[_date] = PL({pl: _pl, fundId: _fundId});
        fundToDate[_fundId].isSet =  true;
    }

    
}