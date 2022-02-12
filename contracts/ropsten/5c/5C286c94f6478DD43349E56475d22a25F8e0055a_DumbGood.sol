//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";


contract DumbGood is ERC721 , Ownable {
    struct NFT_Info{
        string name;
        string detail;
        string image_URL;
    }
    mapping(uint256 => NFT_Info) private DumbGood_items;
    event TokenAdded(address indexed recipient, uint256 indexed newTokenIndex);

    constructor() ERC721("DumbGood", "NFT") {}

    function BuyAndMintItem(string memory name, string memory detail, string memory image_URL)
        public 
        returns (uint256)
    {

        uint256 newTokenIndex = totalSupply();
        _safeMint(_msgSender(), newTokenIndex);

        require(_exists(newTokenIndex), "set attribute for nonexistent token");
        DumbGood_items[newTokenIndex].name = name;
        DumbGood_items[newTokenIndex].detail = detail;
        DumbGood_items[newTokenIndex].image_URL = image_URL;
        emit TokenAdded(_msgSender(), newTokenIndex);


        return newTokenIndex;
    }

    /**
     * Get Information from tokenId
     */
    function getInfoOfToken(uint256 tokenId) public view returns(NFT_Info memory) {
      return DumbGood_items[tokenId];
    }

    function tokensOfOwner(address _owner)external view returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

}