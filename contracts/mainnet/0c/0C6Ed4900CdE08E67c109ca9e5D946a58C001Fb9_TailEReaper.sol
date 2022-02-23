// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../ERC721.sol";
import "../ERC721Enumerable.sol";
import "../Ownable.sol";

contract TailEReaper is ERC721, ERC721Enumerable, Ownable {
    constructor() ERC721("4 Tail E-Reaper", "FTeR") {}

    uint256 supply = 0;

    function _baseURI() internal pure override returns (string memory) {return "ipfs://QmQLs3MB26UhNENWZs5eck7ucEMRwdW4JtPVZo7aF1D5vm/";}
    function _maxSupply() public view virtual returns (uint) {return 1000;}

    function safeMint(address to) public onlyOwner {
        require(supply < _maxSupply());

        supply += 1;
        _safeMint(to, supply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {super._beforeTokenTransfer(from, to, tokenId);}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {return super.supportsInterface(interfaceId);}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory tokenEnd = string(abi.encodePacked(Strings.toString(tokenId), ".json"));
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenEnd)) : "";
    }
}