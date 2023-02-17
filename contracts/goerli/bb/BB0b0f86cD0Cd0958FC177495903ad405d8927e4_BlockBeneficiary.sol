/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockBeneficiary {
    struct Beneficiary {
        uint256 id;
        string name;
        string homeAddress;
        string nationality;
    }

    mapping(uint256 => Beneficiary) public beneficiaries;
    uint256 id;

    constructor() {
        id = 1;
    }

    function addBeneficiary(
        string memory _name,
        string memory _homeAddress,
        string memory _nationality
    ) public {
        beneficiaries[id] = Beneficiary(id, _name, _homeAddress, _nationality);
        id++;
    }
}