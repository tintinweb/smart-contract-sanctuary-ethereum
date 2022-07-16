//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract DeadNeighbors is ERC1155Supply, Ownable {
    using SafeMath for uint256;

    string public name = "Dead Neighbors";
    bool private isPublicSaleActive = false;
    uint256 private collectionsCount = 2000;
    uint256[] collection1 = [1, 2, 3, 4, 5];
    uint256[] collection2 = [6, 7, 8, 9, 10];
    uint256[] amount = [1, 1, 1, 1, 1];

    constructor() ERC1155("https://storage.googleapis.com/nbrs.io/dead-neighbors/{id}.json") {}

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function reserve(address to) external onlyOwner {
        require(collectionsCount > 1, "Not enough supply");

        _mintBatch(to, collection1, amount, "");
        collectionsCount--;
        _mintBatch(to, collection2, amount, "");
        collectionsCount--;
    }

    function mint() external payable {
        require(isPublicSaleActive, "Mint is not active.");
        require(collectionsCount > 0, "Not enough supply");

        if (collectionsCount % 2 == 0) {
            _mintBatch(msg.sender, collection1, amount, "");
        } else {
            _mintBatch(msg.sender, collection2, amount, "");
        }
        collectionsCount--;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function contractURI() public pure returns (string memory) {
        return "https://nbrs.io/opensea/dead_neighbors.json";
    }

    function uri(uint256 _tokenId) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://storage.googleapis.com/nbrs.io/dead-neighbors/",
                Strings.toString(_tokenId),".json"
            )
        );
    }
}