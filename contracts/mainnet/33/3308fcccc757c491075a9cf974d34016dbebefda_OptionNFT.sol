// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";

// An OptionNFT is a digital receipt that can later be used by its owner to
// exercise (take) an Option contract

contract OptionNFT is ERC721Burnable {

  // emitted when an expired option is canceled by the maker to retrieve the
  // collateral, even though the maker no longer owns the NFT
  event Singed( uint256 tokenId );

  enum OptionType { PUT, CALL }

  address public _minter;
  uint256 public _count;

  mapping(uint256 => OptionType) public _optionTypes;
  mapping(uint256 => address) public _makers;
  mapping(uint256 => address) public _collatTypes; // sca, or 0x0 for Ether
  mapping(uint256 => uint256) public _collatAmounts; // amount of asset type
  mapping(uint256 => uint256) public _collatTokenIds; // amount of asset type
  mapping(uint256 => address) public _settleTypes;
  mapping(uint256 => uint256) public _settleAmounts;
  mapping(uint256 => uint256) public _settleTokenIds;
  mapping(uint256 => uint256) public _expirations; // seconds since Unix epoch

  constructor() ERC721("Ethereum Option NFT", "EONFT") {
    _minter = msg.sender;
    _count = 1;
  }

  function mint( address to,
                 OptionType otype,
                 address collatType,
                 uint256 collatAmount,
                 uint256 collatTokenId,
                 address settleType,
                 uint256 settleAmount,
                 uint256 settleTokenId,
                 uint256 expires,
                 bytes memory data )
                 external returns (uint256 tokenId) {

    require( msg.sender == _minter, "minter only" );
    require(    collatType != address(this)
             && settleType != address(this),
             "OptionNFT excused" );

    _safeMint( to, tokenId = _count++, data );
    _makers[tokenId] = to;
    _optionTypes[tokenId] = otype;
    _collatTypes[tokenId] = collatType;
    _collatAmounts[tokenId] = collatAmount;
    _collatTokenIds[tokenId] = collatTokenId;
    _settleTypes[tokenId] = settleType;
    _settleAmounts[tokenId] = settleAmount;
    _settleTokenIds[tokenId] = settleTokenId;
    _expirations[tokenId] = expires;
  }

  function isSinged( uint256 tokenId ) public view returns (bool) {
    return _makers[tokenId] == address(0x0);
  }

  function singe( uint256 tokenId ) external {
    require( msg.sender == _minter, "only minter may singe tokens" );
    _makers[tokenId] = address(0x0);
    emit Singed(tokenId);
  }
}