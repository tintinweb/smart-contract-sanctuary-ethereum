// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract Mcatcoffee is ERC721, ERC721Enumerable, ERC721URIStorage {
        using SafeMath for uint256;
    uint public constant mintPrice = 0;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    constructor() ERC721("Art Conveny7", "ACY7") {}
    function mint(string memory _uri) public payable {
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        _setTokenURI(mintIndex, _uri);
    }
}