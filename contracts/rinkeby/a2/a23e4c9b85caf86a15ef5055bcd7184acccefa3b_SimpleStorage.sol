/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    // Sample Types:
    // bool exampleBool = false;
    // string sampleString = "string";
    // int256 sampleInt = 10;
    // address sampleAddress = 0xF1A89Bfa2Dc3aba82FD2e57C103412993A11D145;
    // bytes32 sampleBytes = "cat";

    // default 0
    uint256 public favNumber;
    // Sample Setter
    function storeFavNumber(uint256 _acceptNumber) public{
        favNumber = _acceptNumber;
    }
    // Sample Getter = view, pure
    function getFavNumber() public view returns(uint256){
        return favNumber;
    }

    // struct / object
    struct Pet {
        uint256 petId;
        string name;
    }
    Pet[] public pets;
    // takes a key
    mapping(string => uint256) public nameToPetId;

    // declare var samplePet Pet Object
    // Pet private samplePet = Pet({petId: 1, name: 'Joyce'});

    // memory: data stored on function execution
    // storage: data persist
    // string: array of bytes
    function addPet(string memory _name, uint256 _petId) public{
        // pets.push(Pet({petId: _petId, name: _name}));
        // OR
        pets.push(Pet(_petId, _name));
        nameToPetId[_name] = _petId;
    }
}