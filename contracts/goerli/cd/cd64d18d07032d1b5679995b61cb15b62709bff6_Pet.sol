/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;



contract Pet {

    address owner;
    address petStore;
    string animal;
    string name;
    string voice;

    constructor(string memory _animal, string memory _name, string memory _voice, address _owner) {
        owner = _owner;
        petStore = msg.sender;
        animal = _animal;
        name = _name;
        voice = _voice;
    }

    function getVoice(address caller) public view returns(string memory) {
        require(msg.sender == petStore && caller == owner);
        return voice;
    }
}

contract PetStore {

    address[] pets;
    address owner;

    constructor() {
        owner = msg.sender;
    }
    
    function buyPet(string memory animal, string memory name, string memory voice) public payable returns(address, uint256) {
        require(msg.value == 1_000_000 wei);
        pets.push(address(new Pet(animal, name, voice, msg.sender)));
        return (pets[pets.length - 1], pets.length - 1);
    }

    function getVoice(uint256 index) public view returns(string memory) {
        return Pet(pets[index]).getVoice(msg.sender);
    }
    
    function getVoice(address adr) public view returns(string memory) {
        for (uint256 i; i < pets.length; i++) {
            if (pets[i] == adr) {
                return Pet(pets[i]).getVoice(msg.sender);
            }
        }
        return "";
    }

    function withdraw(address payable reciever) public payable {
        require(msg.sender == owner);
        reciever.transfer(msg.value);
    }
}