//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    struct persona {
        string name;
        uint256 amount;
        address addressperson;
    }

    persona[] public personas;

    mapping(address => uint256) public addressToamount;
    mapping(string => uint256) public nameToamount;

    function addPerson(string memory _name, uint256 _amount) public {
        persona memory personKeep = persona(_name, _amount, msg.sender);
        personas.push(personKeep);
        addressToamount[msg.sender] = _amount;
        nameToamount[_name] = _amount;
    }

    function retrieveWithName(string memory _name)
        public
        view
        returns (uint256)
    {
        return nameToamount[_name];
    }

    function retrieveWithAddress() public view returns (uint256) {
        return addressToamount[msg.sender];
    }

    function returnObjectWithName(string memory _name)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < personas.length; i++) {
            if (
                keccak256(abi.encodePacked(_name)) ==
                keccak256(abi.encodePacked(personas[i].name))
            ) {
                return personas[i].amount;
            }
        }
    }
}