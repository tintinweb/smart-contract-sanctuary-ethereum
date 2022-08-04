/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library LibShare {
    // Defines the share of royalties for the address
    struct Share {
        address payable account;
        uint96 value;
    }
}

contract LazyMintStorage {

    struct LazyMetaData {
        string imageHash;
        string name;
        string description;
        LibShare.Share[] royalties;
    }

    uint counter;
    LazyMetaData[] public uris;

    constructor() {
        counter = 0;
    }

    function addLazyNft(string memory _hash, string memory _name, string memory _description, LibShare.Share[] memory royalties) public {
        LazyMetaData storage data = uris[counter];
        data.imageHash = _hash;
        data.name = _name;
        data.description = _description;
        
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                "Royalty recipient should be present"
            );
            require(royalties[i].value != 0, "Royalty value should be > 0");
            data.royalties.push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties < 10000, "Sum of Royalties > 100%");

        counter ++;
    }

    function getLazyNft(uint256 _id) public view returns(LazyMetaData memory) {
        return uris[_id];
    }

}