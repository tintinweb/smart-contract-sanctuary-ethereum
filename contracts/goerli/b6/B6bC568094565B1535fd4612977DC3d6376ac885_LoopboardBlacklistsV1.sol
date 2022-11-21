/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardBlacklistsV1 {
    struct Blacklists {
        uint256[] nftIDs;
        string[] CIDs;
        string[] creators;
    }

    mapping(address => Blacklists) private blacklists;

    function addNFT(uint256 id) public returns (bool) {
        uint256[] storage ownNftIDs = blacklists[msg.sender].nftIDs;
        uint256[] memory newNftIDs;
        bool isExisting = true;
        for (uint256 index = 0; index < ownNftIDs.length; index++) {
            if (ownNftIDs[index] != id) {
                newNftIDs[isExisting ? index - 1 : index] = id;
            } else {
                isExisting = true;
            }
        }
        if (isExisting) {
            return false;
        }

        blacklists[msg.sender].nftIDs = newNftIDs;
        return true;
    }

    function addCID(string memory cid) public returns (bool) {
        string[] storage ownCIDs = blacklists[msg.sender].CIDs;
        string[] memory newCIDs;
        bool isExisting = true;
        bytes32 idHash = keccak256(abi.encode(cid));
        for (uint256 index = 0; index < ownCIDs.length; index++) {
            if (keccak256(abi.encode(ownCIDs[index])) != idHash) {
                newCIDs[isExisting ? index - 1 : index] = cid;
            } else {
                isExisting = true;
            }
        }
        if (isExisting) {
            return false;
        }

        blacklists[msg.sender].CIDs = newCIDs;
        return true;
    }

    function addCreator(string memory minterAddress) public returns (bool) {
        string[] storage ownCreators = blacklists[msg.sender].creators;
        string[] memory newCreators;
        bool isExisting = true;
        bytes32 idHash = keccak256(abi.encode(minterAddress));
        for (uint256 index = 0; index < ownCreators.length; index++) {
            if (keccak256(abi.encode(ownCreators[index])) != idHash) {
                newCreators[isExisting ? index - 1 : index] = minterAddress;
            } else {
                isExisting = true;
            }
        }
        if (isExisting) {
            return false;
        }

        blacklists[msg.sender].creators = newCreators;
        return true;
    }

    function getBlacklist(address adminAddress)
        public
        view
        returns (Blacklists memory)
    {
        return blacklists[adminAddress];
    }
}