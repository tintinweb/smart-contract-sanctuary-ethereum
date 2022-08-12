/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Citizenship {
    struct Citizen {
        string id;
        uint8 age;
    }

    error CitizenAlreadyRegistered(address citizenAddress);
    error BadRequest();

    event Registered(address citizenAddress);

    address public admin;
    mapping(address => Citizen) Citizens;
    address[] citizensByAddress;

    constructor() {
        admin = msg.sender;
    }

    function registerCitizen(address _address, string memory _id, uint8 _age) public {
        require(msg.sender == admin);

        if (bytes(_id).length == 0) {
            revert BadRequest();
        }

        if (bytes(Citizens[_address].id).length != 0) {
            revert CitizenAlreadyRegistered({citizenAddress : _address});
        }

        Citizen memory citizen = Citizen({
        id : _id,
        age : _age
        });
        Citizens[_address] = citizen;
        citizensByAddress.push(_address);

        emit Registered(_address);
    }

    function getCitizen(address _address) public view returns (string memory id, uint8 age) {
        return (Citizens[_address].id, Citizens[_address].age);
    }

    function getCitizens() public view returns (address[] memory citizenAddresses){
        return citizensByAddress;
    }
}