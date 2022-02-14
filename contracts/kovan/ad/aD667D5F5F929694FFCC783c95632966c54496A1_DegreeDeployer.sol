/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BaseDegree {
    string name;
    uint64 regno;
    string prog;
    string branch;
    string gender;
    uint64 cpi;
    string nationality;
    string category;

    constructor(
        string memory _name,
        uint64 _regno,
        string memory _prog,
        string memory _branch,
        string memory _gender,
        uint64 _cpi,
        string memory _nationality,
        string memory _category
    ) {
        name = _name;
        regno = _regno;
        prog = _prog;
        branch = _branch;
        gender = _gender;
        cpi = _cpi;
        nationality = _nationality;
        category = _category;
    }
}

contract DegreeDeployer {
    BaseDegree[] public degreesArray;
    mapping(uint64 => uint256) regnoToIndex;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function createDegree(
        string memory _name,
        uint64 _regno,
        string memory _prog,
        string memory _branch,
        string memory _gender,
        uint64 _cpi,
        string memory _nationality,
        string memory _category
    ) public isOwner {
        BaseDegree new_degree = new BaseDegree(
            _name,
            _regno,
            _prog,
            _branch,
            _gender,
            _cpi,
            _nationality,
            _category
        );
        degreesArray.push(new_degree);
        regnoToIndex[_regno] = degreesArray.length - 1;
    }

    function viewDegreeUsingIndex(uint256 index)
        public
        view
        returns (BaseDegree)
    {
        return degreesArray[index];
    }

    function viewDegreeUsingRegno(uint64 _regno)
        public
        view
        returns (BaseDegree)
    {
        return viewDegreeUsingIndex(regnoToIndex[_regno]);
    }
}