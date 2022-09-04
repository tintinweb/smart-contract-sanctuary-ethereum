/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract PasswordManager {
    address _ownerAddress;
    modifier owner {
        _owner();
        _;
    }

    struct PasswordBook {
        string domain;
        string username;
        string password;
    }

    mapping (string => PasswordBook) Passwords;

    constructor(address ownerAddress) {
        _ownerAddress = ownerAddress; 
    }
    
    // Modifiers
    function _owner() internal view virtual {
        require(msg.sender == _ownerAddress, "You are not authorized to do this operation");
    }

    // Functions
    function changeOwner(address newOwner) public virtual owner {
        _ownerAddress = newOwner;
    }

    function savePassword(string memory domain, string memory username, string memory password) public virtual owner {
        Passwords[domain].domain = domain;
        Passwords[domain].username = username;
        Passwords[domain].password = password;
    }

    function getPassword(string memory domain) public virtual view owner returns (PasswordBook memory) {
        return Passwords[domain];
    }
}