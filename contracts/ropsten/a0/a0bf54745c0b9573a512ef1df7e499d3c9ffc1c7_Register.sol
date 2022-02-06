/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Register {
    address public owner;
    address public adminOne = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public adminTwo = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyAdmin() {
        require(adminOne == adminTwo, "not admin");
        require(adminTwo == adminTwo, "not admin");
        _;
    }

    SignUp[] public papers;

    struct SignUp {
        string name;
        uint age;
        address yourAddress;
    }

    function register(string calldata _name, 
    uint _age, address _yourAddress) external {
        papers.push(SignUp({name: _name, 
        age: _age, yourAddress: _yourAddress}));
    }

    function changeInfo(uint _index, 
    string calldata _name, uint _age, 
    address _yourAddress) external onlyAdmin {
        SignUp storage paper = papers[_index];
        paper.name = _name;
        paper.age = _age;
        paper.yourAddress = _yourAddress;    
    }

    function setAdminOne(address _adminOne) external onlyOwner {
        adminOne = _adminOne;
    }

    function setAdminTwo(address _adminTwo) external onlyOwner {
        adminTwo = _adminTwo;
    } 
}