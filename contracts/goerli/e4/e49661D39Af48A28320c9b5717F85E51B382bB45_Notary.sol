/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity ^0.8.9;

contract Notary {
    struct Hash {
        string hashValue;
        uint32 timestamp;
    }
    mapping(address => Hash[]) private hashes;

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    constructor() public {}

    function addHash(string calldata singleHash, uint32 timestamp) external returns(bool) {
        address user = msg.sender;
        for (uint i = 0; i < hashes[user].length; i++) {
            string memory currentHashValue = hashes[user][i].hashValue;
            require(!compareStrings(currentHashValue, singleHash));
        }
        Hash memory newHash;
        newHash.hashValue = singleHash;
        newHash.timestamp = timestamp;
        hashes[user].push(newHash);
        return true;
    }

    function getHashes(address user) public view returns(Hash[] memory) {
        return hashes[user];
    }

    function checkHash(address user, string memory hashValue) public view returns(bool) {
        for (uint i = 0; i < hashes[user].length; i++) {
            string memory currentHashValue = hashes[user][i].hashValue;
            if (compareStrings(currentHashValue, hashValue)) {
                return true;
            }
        }
        return false;
    }
}