// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Citizenship.sol";

contract Election {
    struct Electee {
        string id;
        uint256 voteCount;
    }

    struct Elector {
        string id;
        bool alreadyElected;
    }

    error CitizenNotRegistered(address citizenAddress);
    error CitizenUnderaged(address citizenAddress);
    error ElecteeAlreadyRegistered(address electeeAddress);
    error ElecteeNotRegistered(address electeeAddress);
    error ElectorAlreadyRegistered(address electorAddress);
    error ElectorNotRegistered(address electorAddress);
    error ElectorAlreadyElected(address electorAddress);

    address public admin;
    Citizenship private citizenship;
    mapping(address => Electee) Electees;
    mapping(address => Elector) Electors;
    address[] electeesByAddress;
    address[] electorsByAddress;

    constructor(address citizenshipContractAddress) {
        admin = msg.sender;
        citizenship = Citizenship(citizenshipContractAddress);
    }

    function registerElectee(address _address) public {
        require(msg.sender == admin);

        (string memory _id, uint8 _age) = citizenship.getCitizen(_address);
        if (bytes(_id).length == 0) {
            revert CitizenNotRegistered({citizenAddress : _address});
        }
        if (_age < 18) {
            revert CitizenUnderaged({citizenAddress : _address});
        }

        if (bytes(Electees[_address].id).length != 0) {
            revert ElecteeAlreadyRegistered({electeeAddress : _address});
        }

        Electee memory electee = Electee({id : _id, voteCount : 0});
        Electees[_address] = electee;
        electeesByAddress.push(_address);
    }

    function getElectee(address _address) public view returns (string memory id, uint8 age, uint256 voteCount) {
        (id, age) = citizenship.getCitizen(_address);
        voteCount = Electees[_address].voteCount;
    }

    function getElectees() public view returns (address[] memory electeeAddresses){
        return electeesByAddress;
    }

    function registerElector(address _address) public {
        require(msg.sender == admin);

        (string memory _id, uint8 _age) = citizenship.getCitizen(_address);
        if (bytes(_id).length == 0) {
            revert CitizenNotRegistered({citizenAddress : _address});
        }
        if (_age < 18) {
            revert CitizenUnderaged({citizenAddress : _address});
        }

        if (bytes(Electors[_address].id).length != 0) {
            revert ElectorAlreadyRegistered({electorAddress : _address});
        }

        Elector memory elector = Elector({id : _id, alreadyElected : false});
        Electors[_address] = elector;
        electorsByAddress.push(_address);
    }

    function getElector(address _address) public view returns (string memory id, uint8 age, bool alreadyElected) {
        (id, age) = citizenship.getCitizen(_address);
        alreadyElected = Electors[_address].alreadyElected;
    }

    function getElectors() public view returns (address[] memory electorAddresses){
        return electorsByAddress;
    }

    function elect(address _address) public {
        if (bytes(Electees[_address].id).length == 0) {
            revert ElecteeNotRegistered({electeeAddress : _address});
        }

        if (bytes(Electors[msg.sender].id).length == 0) {
            revert ElectorNotRegistered({electorAddress : msg.sender});
        }

        if (Electors[msg.sender].alreadyElected == true) {
            revert ElectorAlreadyElected({electorAddress : msg.sender});
        }

        Elector memory elector = Electors[msg.sender];
        elector.alreadyElected = true;
        Electors[msg.sender] = elector;

        Electee memory electee = Electees[_address];
        electee.voteCount += 1;
        Electees[_address] = electee;
    }
}