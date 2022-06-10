// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";

contract MyKidsFirstNftCollections is ERC1155, Ownable, ERC1155Burnable {
    using Strings for uint256;

    constructor() ERC1155("") {}
    string tokenUri = "https://uplus-nft.s3.ap-northeast-2.amazonaws.com/Json/";

    // Mint function
    function airdrop(address[] calldata receiver, uint256[] calldata amount, uint256[] calldata tokenId) public onlyOwner {
        for(uint256 i = 0; i < receiver.length; i++) {
            _mint(receiver[i], tokenId[i], amount[i], "");
        }
    }

    function setTokenUri(string calldata newUri) public onlyOwner {
        tokenUri = newUri;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(tokenUri).length > 0 ? string(abi.encodePacked(tokenUri, tokenId.toString(), ".json")) : "";
    }
}