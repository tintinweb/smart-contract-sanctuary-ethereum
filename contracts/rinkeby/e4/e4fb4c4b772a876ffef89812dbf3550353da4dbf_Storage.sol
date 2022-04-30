/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
    string name;
    string company;
    mapping (string => string) public dates;

    constructor(string memory _name, string memory _company)
    {        
        require(bytes(_name).length > 0,"name is mandatory");
        require(bytes(_company).length > 0,"name is mandatory");

        name=_name;
        company=_company;
    }
    
    function store(string memory _date, string memory _cid) public {
        dates[_date]=_cid;
    }
    
    function retrieve(string memory _date) public view returns (string memory){
        return dates[_date];
    }
}