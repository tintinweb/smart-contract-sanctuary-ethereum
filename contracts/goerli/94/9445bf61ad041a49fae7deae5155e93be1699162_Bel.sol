// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract Bel is ERC721, Ownable {
    using Strings for uint256;

    //max supply
    uint256 public MAX_SUPPLY = 3210;

    //current minted supply
    uint256 public totalSupply;

    //address allowed to drop
    address private _dropperAddress;

    //metadatas
    string public baseURI = "";

    constructor()
    ERC721("test leb", "LEB")
        {
        }

    function drop(address targetAddress) external {
        require(msg.sender == owner() || msg.sender == _dropperAddress, "not allowed");
        require(totalSupply<MAX_SUPPLY, "supply limit reached");
        _mint(targetAddress, totalSupply++);
    }

    function setDropper(address dropperAddress) external onlyOwner {
        _dropperAddress = dropperAddress;
    }

    function getDropperAddress() external view returns (address) {
        return _dropperAddress;
    }

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }


}