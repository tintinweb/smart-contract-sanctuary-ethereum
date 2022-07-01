// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Wcraft is ERC721, Ownable {

    uint256 public currentSupply;
    string public baseTokenURI;
    bool public saleIsActive = false;
    uint256 public tokenPrice = 0.00 ether;
    mapping(uint256 => uint256) _tokens;
    mapping(uint256 => bool) private itemIds;

    constructor(string memory _baseTokenURI, bool _saleIsActive) ERC721("WitchCraft", "WCraft") {
        setBaseURI(_baseTokenURI);
        saleIsActive = _saleIsActive;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function existsItemId(uint256 itemId) public view returns (bool){
        return itemIds[itemId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, Strings.toString(_tokens[tokenId]))) : "";
    }

    function mint(address _to, uint256 itemId) external payable onlyOwner {
        require(saleIsActive, "Sale must be active to mint Item");
        require(msg.value >= tokenPrice, "Ether sent is not correct");
        require(!itemIds[itemId], "item id used");

        itemIds[itemId] = true;
        _tokens[itemId] = itemId;
        _safeMint(_to, itemId);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint i = 0; i < currentSupply; i++) {
                if (ownerOf(i) == _owner) {
                    result[index] = _tokens[i];
                    index++;
                }
                if (index == tokenCount) break;
            }

            return result;
        }
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner() {
        tokenPrice = _tokenPrice;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function flipSaleState(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}