//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BaseDeDatosPersonas {

    struct persona {
        string name;
        uint256 height;
        uint256 weight;
    }

    mapping(address => persona) public Referente;
    
    function setMyProfile(string memory _name, uint256 _height, uint256 _weight) public {
        persona storage p = Referente[msg.sender];
        p.name = _name;
        p.height = _height;
        p.weight = _weight;
    }
}