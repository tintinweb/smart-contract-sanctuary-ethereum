/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockBeneficiary {
    struct Beneficiary {
        uint256 id;
        string name;
        string homeAddress;
        string nationality;
    }

    event idEmitted(uint256 _id);


    mapping(uint256 => Beneficiary) public beneficiaries;
    uint256 id;

    constructor() {
        id = 0;
    }

    function addBeneficiary(
        string memory _name,
        string memory _homeAddress,
        string memory _nationality
    ) public returns (uint256 identifier) {
        id++;
        beneficiaries[id] = Beneficiary(id, _name, _homeAddress, _nationality);
        emit idEmitted(id);
        return id;
    }
}