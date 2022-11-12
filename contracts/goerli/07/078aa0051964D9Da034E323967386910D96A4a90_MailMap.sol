/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MailMap {
    
    mapping(bytes32 => address) registeredAddresses;
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
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _emailHash));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        registeredAddresses[_emailHash] = signer;
    }

    function getWalletAddress(bytes32 emailHash) external view returns(address) {
        return registeredAddresses[emailHash];
    }

}