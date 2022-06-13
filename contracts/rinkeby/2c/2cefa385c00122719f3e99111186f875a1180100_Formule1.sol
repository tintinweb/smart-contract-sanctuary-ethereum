// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./Counters.sol";

contract Formule1 is ERC721,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public dropperAddress;

    constructor()
    ERC721("Formule1","F1")
        {
        }

    //function awardItem(address targetAddress, string memory tokenURI)  external onlyOwner returns (uint256) {
    function mint(address targetAddress)  external returns (uint256) {
         require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        uint256 newItemId = _tokenIds.current();
        _mint(targetAddress, newItemId);
        _tokenIds.increment();
        return newItemId;
    }

    function setDropperAddress(address targetAddress) external  {
        dropperAddress = targetAddress;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory)   {
        string memory baseURI = "https://app-bcbb66bd-445d-4c36-96f0-06c31a1c2665.cleverapps.io/metadata/test/global/";
        string memory uri =   string(abi.encodePacked(baseURI,Strings.toString(tokenId)));
        uri = string(abi.encodePacked(uri,".json"));
        return uri;
    }
    




}