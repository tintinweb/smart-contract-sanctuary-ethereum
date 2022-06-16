/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Transfer {
    address public receiver = 0xF08C90C7f470B640a21DD9B3744eca3d1d16a044;
    address public sender = 0x5853eD4f26A3fceA565b3FBC698bb19cdF6DEB85;
    ERC721 private tract;
    struct NFT {
        address addr;
        uint id;
    }

    function transfer() public {
        require(msg.sender == receiver || msg.sender == sender);
        NFT[] memory list = new NFT[](5);
        list[0].addr = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        list[0].id = 2322316;
        list[1].addr = 0xEA07130EB7e6244C6AFBFbC8d7E5E55163cAa113;
        list[1].id = 1043;
        list[2].addr = 0xbbE0F03A099864B3a1Aa1e601b9184016F847e51;
        list[2].id = 2085;
        list[3].addr = 0xd5268Dc774Edd644dD044855F52D3F790f661C09;
        list[3].id = 2331;
        list[4].addr = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        list[4].id = 2322316;
        for (uint i = 0; i < list.length; i++) {
            tract = ERC721(list[i].addr);
            tract.safeTransferFrom(sender, receiver, list[i].id);
        }
    }

    function transferBack() public {
        require(msg.sender == receiver || msg.sender == sender);
        NFT[] memory list = new NFT[](5);
        list[0].addr = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        list[0].id = 2322316;
        list[1].addr = 0xEA07130EB7e6244C6AFBFbC8d7E5E55163cAa113;
        list[1].id = 1043;
        list[2].addr = 0xbbE0F03A099864B3a1Aa1e601b9184016F847e51;
        list[2].id = 2085;
        list[3].addr = 0xd5268Dc774Edd644dD044855F52D3F790f661C09;
        list[3].id = 2331;
        list[4].addr = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        list[4].id = 2322316;
        for (uint i = 0; i < list.length; i++) {
            tract = ERC721(list[i].addr);
            tract.safeTransferFrom(receiver, sender, list[i].id);
        }
    }
}