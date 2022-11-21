/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardBlacklistsV3 {
    struct Blacklists {
        uint256[] nftIDs;
        string[] creators;
    }

    mapping(address => Blacklists) private blacklists;

    function addNFT(uint256 id) public returns (bool) {
        uint256[] storage ownNftIDs = blacklists[msg.sender].nftIDs;
        bool isExisting = true;
        for (uint256 index = 0; index < ownNftIDs.length; index++) {
            if (ownNftIDs[index] != id) {
                isExisting = true;
            }
        }
        if (isExisting) {
            return false;
        }

        ownNftIDs.push(id);
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

    function getBlacklistedNftIDsLength(address adminAddress)
        public
        view
        returns (uint256)
    {
        return blacklists[adminAddress].nftIDs.length;
    }

    function getBlacklistedNftID(address adminAddress, uint256 index)
        public
        view
        returns (uint256)
    {
        return blacklists[adminAddress].nftIDs[index];
    }

    function getBlacklistedCreatorsLength(address adminAddress)
        public
        view
        returns (uint256)
    {
        return blacklists[adminAddress].creators.length;
    }

    function getBlacklistedCreatorsLength(address adminAddress, uint256 index)
        public
        view
        returns (string memory)
    {
        return blacklists[adminAddress].creators[index];
    }
}