/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity^0.8.0;

contract FirstContract {

    address public contractOwner;

    string public entityName;

    constructor(string memory _entityName) {
        contractOwner = msg.sender;
        entityName = _entityName;
    }

    mapping (address => User) userDetails;

    struct User {
        string firstName;
        string lastName;
        string city;
        uint256 balance;
    }

    modifier isContractOwner() {
        require(msg.sender == contractOwner, "You are not the owner of the contract");
        _;
    }

    function registerUser(string memory _firstName, string memory _lastName, string memory _city) public {
        User memory contractUser = User(_firstName, _lastName, _city, 0);
        userDetails[msg.sender] = contractUser;
    }

    function deposit() payable public {
        require(userDetails[msg.sender].balance >= 0, "You are not registered");
        userDetails[msg.sender].balance += msg.value;
    } 

    function withdraw(uint8 withdrawAmount) public {
        require(userDetails[msg.sender].balance >= withdrawAmount, "You don't have enough balance");
        userDetails[msg.sender].balance -= withdrawAmount;
    }

    function changeEntityName(string memory newEntityName) public isContractOwner {
        entityName = newEntityName;
    }

    function viewBalance() public view returns (uint256) {
        return userDetails[msg.sender].balance;
    }

}