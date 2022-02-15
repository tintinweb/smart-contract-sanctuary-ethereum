/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: testContract2.sol

contract test1 {
    struct Person {
        address addressId;
        uint256 id;
    }

    Person[] public person;

    mapping(address => uint256) public addressToId;

    function _generatePerson(address _address, uint256 _id) private {
        person.push(Person(_address, _id));
        addressToId[_address] = _id;
    }

    function _generateId(address _address) private pure returns (uint256) {
        uint256 id = uint256(keccak256(abi.encodePacked(_address)));
        return id;
    }

    function generateId(address Address) public {
        uint256 id = _generateId(Address);
        return _generatePerson(Address, id);
    }
}