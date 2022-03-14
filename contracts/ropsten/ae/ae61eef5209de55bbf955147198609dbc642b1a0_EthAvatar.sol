/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract EthAvatar {
    mapping (address => string) private ipfsHashes;

    event DidSetIPFSHash(address indexed hashAddress, string hash);


    function setIPFSHash( string calldata hash) public {
        ipfsHashes[msg.sender] = hash;

       emit DidSetIPFSHash(msg.sender, hash);
    }

    function getIPFSHash(address  hashAddress) public view returns (string memory) {
        return ipfsHashes[hashAddress];
    }
}