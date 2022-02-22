// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./IERC721.sol";

/**
 * @title NonCoolCats Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NonCoolCats is ERC721Burnable {
    uint16 private mintedCount;

    string public baseTokenURI;
    uint16 public MAX_SUPPLY;
    uint16 public FREE_COUNT;

    uint256 public mintPrice;
    uint16 public maxByMint;

    address public fundAddress;
    address public adminAddress;
    address public marketerAddress;

    constructor(address _fundWallet, address _admin, address _marketer)
        ERC721("Non Cool Cats", "NCC")
    {
        MAX_SUPPLY = 10000;
        FREE_COUNT = 1000;
        mintPrice = 0.03 ether;
        maxByMint = 20;
        fundAddress = _fundWallet;
        adminAddress = _admin;
        marketerAddress = _marketer;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function getMintPrice() public view returns (uint256) {
        uint16 tokenId = totalSupply();
        if (tokenId < FREE_COUNT) {
            return 0;
        } else {
            return mintPrice;
        }
    }

    function setFreeCount(uint16 _free_count) external onlyOwner {
        FREE_COUNT = _free_count;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function totalSupply() public view virtual returns (uint16) {
        return mintedCount;
    }

    function getTokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256 supply = totalSupply();

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 0; tokenId < supply; tokenId++) {
                if (_owners[tokenId] == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                    if (resultIndex >= tokenCount) {
                        break;
                    }
                }
            }
            return result;
        }
    }

    function mintByUser(uint8 _numberOfTokens) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");

        require(
            getMintPrice() * _numberOfTokens <= msg.value,
            "Low Price To Mint"
        );

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            uint16 tokenId = uint16(totalSupply() + i);
            _safeMint(msg.sender, tokenId);
        }
        mintedCount = mintedCount + _numberOfTokens;
    }

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 amount = totalBalance * 3 / 10;
        payable(adminAddress).transfer(amount);
        payable(fundAddress).transfer(amount);
        payable(marketerAddress).transfer(totalBalance - amount - amount);
    }
}