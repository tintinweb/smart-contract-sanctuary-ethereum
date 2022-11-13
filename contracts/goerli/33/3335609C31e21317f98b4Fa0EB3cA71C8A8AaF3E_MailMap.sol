/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MailMap {

    mapping(bytes32 => address) registeredAddresses;
    mapping(address => bytes32) registeredEmails;

    bytes constant HASH_PREFIX = "\x19Ethereum Signed Message:\n32";

    address oracleAddress;

    constructor(
        address  _oracleAddress
    ) {
        oracleAddress = _oracleAddress;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress);
        _;
    }

    function registerEmail(bytes32 _emailHash, uint8 _v, bytes32 _r, bytes32 _s) onlyOracle external {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(HASH_PREFIX, _emailHash));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        registeredAddresses[_emailHash] = signer;
        registeredEmails[signer] = _emailHash;
    }

    function getWalletAddress(bytes32 emailHash) external view returns(address) {
        require(registeredAddresses[emailHash] != address(0), "Email is not registered");
        return registeredAddresses[emailHash];
    }

    function removeUser() external {
        bytes32 email = registeredEmails[msg.sender];
        delete registeredAddresses[email];
        delete registeredEmails[msg.sender];
    }

}