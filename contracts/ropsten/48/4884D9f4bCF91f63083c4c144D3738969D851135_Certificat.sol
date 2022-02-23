/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Certificat for valentin
contract Certificat {
    string public company;
    address private owner;
    mapping (string => string) private signatures;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event UpdatedEmails();

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

     /**
     * @dev Set contract deployer as owner
     */
    constructor(string memory _company) {
        company = _company;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    function createNewSignature(string memory newEmail, string memory newSignature) public isOwner {
        signatures[newEmail] = newSignature;
    }

    function retrieveSignatureByMail (string memory email) public view returns(string memory) {
        return signatures[email];
    }

    function transferOwnership(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function addEmails(string[] memory email, string[] memory hash) public isOwner {
        for (uint256 index = 0; index < email.length; index++) {
            signatures[email[index]] = hash[index];
        }
        emit UpdatedEmails();
    }
}