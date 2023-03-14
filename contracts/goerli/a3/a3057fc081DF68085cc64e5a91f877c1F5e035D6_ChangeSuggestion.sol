/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

contract ChangeSuggestion {
    address public contractOwner;
    mapping(address => bool) authorizedAccounts;

    event ChangeSuggestionSubmitted(address indexed proposer, string data);

    constructor() {
        contractOwner = msg.sender;
        authorizedAccounts[msg.sender] = true; 
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can perform this action.");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAccounts[msg.sender], "Only authorized accounts can perform this action.");
        _;
    }

    function authorizeAccount(address _account) public onlyOwner {
        authorizedAccounts[_account] = true;
    }

    function revokeAuthorization(address _account) public onlyOwner {
        authorizedAccounts[_account] = false;
    }

    function submitChangeSuggestion(string memory _data) public onlyAuthorized {
        emit ChangeSuggestionSubmitted(msg.sender, _data);
    }
}