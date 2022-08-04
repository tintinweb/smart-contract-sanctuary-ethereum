// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./Ownable.sol";
contract MyToken is ERC721, Ownable {
constructor() ERC721("AREVEA", "AVA") {}
function safeMint(address to, uint256 tokenId) public onlyOwner {
_safeMint(to, tokenId);
}
}