// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Felipe {

    string public name;
    address public owner;

    event newName(address indexed owner, string indexed nName);

    constructor(string memory nomeNovo){
        name = nomeNovo;
        owner = msg.sender;
    }

    function setName(string memory _newName) public {
       name = _newName;
       emit newName(msg.sender, _newName);
    }
}