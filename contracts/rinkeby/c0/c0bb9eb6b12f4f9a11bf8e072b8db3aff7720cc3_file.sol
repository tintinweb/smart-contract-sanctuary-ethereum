/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract file {

    string private CID;
    string private HashValueCipher;
    string private HashValuePlain;
    address[] private ACL;
    address owner;

    constructor(string memory _CID, string memory _HashValueCipher, string memory _HashValuePlain) {
        owner = msg.sender;
        CID = _CID;
        HashValueCipher = _HashValueCipher;
        HashValuePlain = _HashValuePlain;
        ACL.push(owner);
    }

    function getCID () public view returns (string memory) {
        return CID;
    }

    function getHashValueCipher () public view returns (string memory ) {
        return HashValueCipher;
    }
        
    function getHashValuePlain () public view returns (string memory ) {
        return HashValuePlain;
    }

    function addPermission (address requester) public {
        ACL.push(requester);

    }
}