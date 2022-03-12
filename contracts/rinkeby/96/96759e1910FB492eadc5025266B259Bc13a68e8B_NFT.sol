// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";

contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;
    uint256 public lastId;

    constructor(address marketplaceAddress) ERC721("PUFS Token", "PUFS") {
        contractAddress = marketplaceAddress;
    }

    function createToken(string memory tokenURI) public onlyOwner returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);
        lastId = newItemId;
        return newItemId;
    }

    function getLastId() public view returns(uint) {
        return lastId;
    }

}