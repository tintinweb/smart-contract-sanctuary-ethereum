// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";

contract Chit is ERC721Burnable {

  address public _minter;
  uint256 public _serial;

  mapping(uint256 => address) public _itemTypes; // sca, or use 0x0 for Ether
  mapping(uint256 => uint256) public _itemAmounts; // amount if ERC20 or Ether
  mapping(uint256 => uint256) public _itemTokenIds; // tokenId if ERC721

  constructor() ERC721("Chit NFT", "CHIT") {
    _minter = msg.sender;
    _serial = 1;
  }

  function mint( address to,
                 address itemType,
                 uint256 itemAmount,
                 uint256 itemTokenId,
                 bytes memory data )
                 external
                 returns (uint256 tokenId) {

    require( msg.sender == _minter, "only minter may mint" );

    _safeMint( to, tokenId = _serial++, data );

    _itemTypes[tokenId] = itemType;
    _itemAmounts[tokenId] = itemAmount;
    _itemTokenIds[tokenId] = itemTokenId;
  }
}