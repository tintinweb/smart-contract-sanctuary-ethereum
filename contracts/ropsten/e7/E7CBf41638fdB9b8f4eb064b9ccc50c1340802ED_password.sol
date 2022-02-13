/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

//@davyh
contract password {

    mapping(address => bytes32) Passwords;
    mapping(address => bool) PasswordsActive;

    function getPassword() public view returns(bytes32) {
        return Passwords[msg.sender];
    }

    function getPasswordActive(address _owner) public view returns(bool) {
        return PasswordsActive[_owner];
    }

    function createPassword(string memory _password, string memory _password2) public {
        require(!PasswordsActive[msg.sender], "Vous avez deja configurer votre mot de passe");
        require(keccak256(abi.encodePacked((_password))) != keccak256(abi.encodePacked((''))), "le champ password ne peux pas etre vide !");
        require(keccak256(abi.encodePacked(_password)) == keccak256(abi.encodePacked(_password2)), "Les 2 mot de passe doivent etre pareils !");
        
        
        bytes32 passwordEncoded = keccak256(abi.encodePacked(_password));
        Passwords[msg.sender] = passwordEncoded;
        PasswordsActive[msg.sender] = true;
    }

    function verifyPassword(address _owner, string memory _password) public view returns (bool) {
        require(Passwords[_owner] == keccak256(abi.encodePacked(_password)), "Le mot de passe ne correspond pas !");
        return true;
    }

}