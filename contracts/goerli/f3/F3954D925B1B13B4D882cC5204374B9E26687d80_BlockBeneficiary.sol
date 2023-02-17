/// SPDX-License-Identifier: MIT

pragma solidity >=0.7.3;

contract BlockBeneficiary {
    struct Beneficiary {
        uint256 id;
        string name;
        string homeAdress;
        string nationality;
    }

    mapping(uint256 => Beneficiary) public beneficiaries;
    uint256 id;

    constructor() {
        id = 1;
    }

    function addBeneficiary(
        string memory _name,
        string memory _homeAdress,
        string memory _nationality
    ) public {
        beneficiaries[id] = Beneficiary(id, _name, _homeAdress, _nationality);
        id++;
    }
}