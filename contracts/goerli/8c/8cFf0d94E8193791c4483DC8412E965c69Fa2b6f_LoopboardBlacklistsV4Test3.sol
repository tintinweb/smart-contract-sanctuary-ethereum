/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardBlacklistsV4Test3 {
    mapping(address => uint256[]) private nftIDs;
    mapping(address => string[]) private creators;
    address[] private nftIDsAdders;
    address[] private creatorsAdders;

    function addNFT(uint256 id) public returns (bool) {
        uint256[] storage ownNftIDs = nftIDs[msg.sender];
        bool isExisting = false;
        for (uint256 index = 0; index < ownNftIDs.length; index++) {
            if (ownNftIDs[index] == id) {
                isExisting = true;
            }
        }
        if (isExisting) {
            return false;
        }

        ownNftIDs.push(id);
        bool isExistingAdder = false;
        for (uint256 index = 0; index < nftIDsAdders.length; index++) {
            if (nftIDsAdders[index] != msg.sender) {
                isExistingAdder = true;
            }
        }
        if (!isExistingAdder) {
            nftIDsAdders.push(msg.sender);
        }
        return true;
    }

    function addCreator(string memory minterAddress) public returns (bool) {
        bytes32 idHash = keccak256(abi.encode(minterAddress));
        bool isExisting = false;
        for (uint256 index = 0; index < creators[msg.sender].length; index++) {
            if (keccak256(abi.encode(creators[msg.sender][index])) == idHash) {
                isExisting = true;
            }
        }
        if (isExisting) {
            return false;
        }

        creators[msg.sender].push(minterAddress);
        bool isExistingAdder = false;
        for (uint256 index = 0; index < nftIDsAdders.length; index++) {
            if (nftIDsAdders[index] != msg.sender) {
                isExistingAdder = true;
            }
        }
        if (!isExistingAdder) {
            creatorsAdders.push(msg.sender);
        }
        return true;
    }

    function getBlacklistedNftIDsLength(address adminAddress)
        public
        view
        returns (uint256)
    {
        return nftIDs[adminAddress].length;
    }

    function getBlacklistedNftID(address adminAddress, uint256 index)
        public
        view
        returns (uint256)
    {
        return nftIDs[adminAddress][index];
    }

    function getBlacklistedNftIDs(address adminAddress, uint256 offset)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids;
        for (
            uint256 i = 0;
            i < 16 && i < nftIDs[adminAddress].length + offset;
            i++
        ) {
            ids[i] = nftIDs[adminAddress][i + offset];
        }
        return ids;
    }

    function getBlacklistedCreatorsLength(address adminAddress)
        public
        view
        returns (uint256)
    {
        return creators[adminAddress].length;
    }

    function getBlacklistedCreator(address adminAddress, uint256 index)
        public
        view
        returns (string memory)
    {
        return creators[adminAddress][index];
    }

    function getBlacklistedCreators(address adminAddress, uint256 offset)
        public
        view
        returns (string[] memory)
    {
        string[] memory ids;
        for (
            uint256 i = 0;
            i < 16 && i < creators[adminAddress].length + offset;
            i++
        ) {
            ids[i] = creators[adminAddress][i + offset];
        }
        return ids;
    }

    function getNftIDsAdders() public view returns (address[] memory) {
        return nftIDsAdders;
    }

    function getCreatorsAdders() public view returns (address[] memory) {
        return creatorsAdders;
    }
}