//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BaseDeDatosPersonas {

    struct persona {
        string name;
        uint256 height;
        uint256 weight;
    }

    mapping(address => persona) public Referente;
    
    function setMyName(string memory _name) public {
        persona storage p = Referente[msg.sender];
        p.name = _name;
    }

    function getMyName() public view returns (string memory) {
        return Referente[msg.sender].name;
    }
}