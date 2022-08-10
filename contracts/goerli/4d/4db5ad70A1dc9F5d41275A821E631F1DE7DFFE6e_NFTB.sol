// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";

contract NFTB is ERC721Enumerable {
    constructor() ERC721("NFTB", "NFTB") {}
    uint256 private _tokenId;
    function mint(uint count) external {
        for(uint i=0;i<count; i++) {
            _tokenId++;
            _safeMint(_msgSender(), _tokenId);
        }
    }
}