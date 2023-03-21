/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockPolicy {
    struct Policy {
        uint256 id;
        string section;
        string startDate;
        string endDate;
        string attribute;
        uint256 price;
        uint256 prize;
        string description;
    }

    event idEmitted(uint256 _id);

    mapping(uint256 => Policy) public policies;
    uint256 id;

    constructor() {
        id = 0;
    }

    function addPolicy(
        string memory _section,
        string memory _startDate,
        string memory _endDate,
        string memory _attribute,
        uint256 _price,
        uint256 _prize,
        string memory _description
    ) public returns (uint256 identifier)  {
        policies[id] = Policy(id, _section, _startDate, _endDate, _attribute, _price, _prize, _description);
        id++;
        emit idEmitted(id);
        return id;
    }
}