// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Wcraft is ERC721, Ownable {
    using Strings for uint256;

    uint256 public totalSupply;
    string public baseTokenURI;
    bool public saleIsActive = false;
    mapping(uint256 => uint256) _tokens;
    mapping(uint256 => bool) private itemIds;

    constructor(string memory _baseTokenURI, bool _saleIsActive) ERC721("Wcraft Collection", "WCRAFT") {
        setBaseURI(_baseTokenURI);
        saleIsActive = _saleIsActive;
    }

    function existsItemId(uint256 itemId) public view returns (bool){
        return itemIds[itemId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, Strings.toString(_tokens[tokenId]))) : "";
    }

    function mint(address _to, uint256 itemId) external onlyOwner {
        require(saleIsActive, "Sale must be active to mint Item");
        require(!itemIds[itemId], "item id used");

        itemIds[itemId] = true;
        _tokens[itemId] = itemId;
        totalSupply++;
        _safeMint(_to, itemId);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint i = 0; i < totalSupply; i++) {
                if (ownerOf(i) == _owner) {
                    result[index] = _tokens[i];
                    index++;
                }
                if (index == tokenCount) break;
            }

            return result;
        }
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function flipSaleState(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}