/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library StringLib {
  function compareTwoStrings(string memory s1, string memory s2)
    public
    pure
    returns (bool)
  {
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
  }
}

contract BlockVoteUser {

    struct User {
        string hashMnemonic;
        string email;
        bool isValid;
    }
    mapping(string => User) private users;

    constructor() {}

    function register(string memory mnemonic, string memory hashMnemonic, string memory email)
        public
    {
        users[mnemonic].hashMnemonic = hashMnemonic;
        users[mnemonic].email = email;
        users[mnemonic].isValid = true;
    }

    function login(string memory mnemonic, string memory hashMnemonic)
        public view returns(bool isSuccess)
    {
        return (
            isSuccess = StringLib.compareTwoStrings(users[mnemonic].hashMnemonic, hashMnemonic)
        );
    }

    function getEmail(string memory mnemonic)
        public view returns(string memory email)
    {
        return (
            email = users[mnemonic].email
        );
    }

    function updateHashMnemonic(string memory mnemonic, string memory hashMnemonic) 
        public 
    {
        users[mnemonic].hashMnemonic = hashMnemonic;
    }
}