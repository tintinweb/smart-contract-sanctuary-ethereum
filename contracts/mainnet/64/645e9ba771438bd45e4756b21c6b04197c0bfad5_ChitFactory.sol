// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./Chit.sol";

contract HasAdmin {
  address payable public admin_;

  modifier isAdmin {
    if (msg.sender != admin_) { revert("must be admin"); }
    _;
  }

  constructor() { admin_ = payable(msg.sender); }

  function setAdmin( address payable newadmin ) public isAdmin {
    admin_ = newadmin;
  }
}

// ============================================================================
// Contract enabling anyone to exchange assets for Chits and vice-versa
// ============================================================================

contract ChitFactory is HasAdmin {

  event ClientPublished( string ipfsHash );

  Chit public chit;

  uint256 public makerfee;
  uint256 public takerfee;

  // Gas estimates. Add 68 gas per byte if providing data:
  // - sale item is eth: 123843
  // - sale item is erc20: 177140
  // - sale item is erc721: 160876

  function make( uint256 _sellunits,
                 address _selltoken,
                 uint256 _selltokid,
                 bytes memory _data ) public payable {

    if (_selltoken == address(0)) { // ETH
      require( _sellunits + makerfee >= _sellunits, "safemath: bad arg" );
      require( msg.value >= _sellunits + makerfee, "insufficient fee" );
      admin_.transfer( msg.value - _sellunits );
    }
    else {
      if ( _sellunits == uint256(0) ) {
        IERC721 tok = IERC721(_selltoken);
        tok.transferFrom( msg.sender, address(this), _selltokid );
      }
      else {
        IERC20 tok = IERC20(_selltoken);
        require( tok.transferFrom(msg.sender, address(this), _sellunits),
                 "failed ERC20.transferFrom()" );
      }

      admin_.transfer( msg.value );
    }

    chit.mint( msg.sender, _selltoken, _sellunits, _selltokid, _data );
  }

  // gas estimates:
  // - 82472 to take ether
  // - 102668 to take erc20 (includes 48789 for the approve)
  // - 106286 to take an erc721
  function take( uint256 _chitId ) public payable {

    chit.transferFrom( msg.sender, address(this), _chitId );

    require( msg.value >= takerfee, "insufficient take fee" );
    admin_.transfer( msg.value );

    if (chit._itemTypes(_chitId) == address(0)) { // ETH
      payable(msg.sender).transfer( chit._itemAmounts(_chitId) );
    }
    else {
      if (chit._itemAmounts(_chitId) != uint256(0)) { // ERC20
        IERC20 tok = IERC20( chit._itemTypes(_chitId) );
        tok.approve( msg.sender, chit._itemAmounts(_chitId) );
      }
      else { // ERC721
        IERC721 tok = IERC721( chit._itemTypes(_chitId) );
        tok.approve( msg.sender, chit._itemTokenIds(_chitId) );
      }
    }

    chit.burn( _chitId );
  }

  // =========================================================================

  constructor( uint256 _mf, uint256 _tf ) {
    makerfee = _mf;
    takerfee = _tf;
    chit = new Chit(); // this contract is minter
  }

  function setFee( uint256 _makefeewei, uint256 _takefeewei ) public isAdmin {
    makerfee = _makefeewei;
    takerfee = _takefeewei;
  }

  function setClient( string memory _client ) public isAdmin {
    emit ClientPublished( _client );
  }

  // Remaining logic attempts to capture accidental donations of ether or
  // certain token types

  // if caller sends ether and leaves calldata blank
  receive() external payable {
    admin_.transfer( msg.value );
  }

  // called if calldata has a value that does not match a function
  fallback() external payable {
    admin_.transfer( msg.value );
  }

  // Generic ERC721 (NFT) safe transfer callback
  function onERC721Received( address _operator,
                             address _from,
                             uint256 _tokenId,
                             bytes calldata _data)
                             external pure returns(bytes4) {

    if (    _operator == address(0x0)
         && _from == address(0x0)
         && _tokenId == 0x0
         && _data.length > 0 ) {
      // does nothing but suppress compiler warnings about unused params
    }

    return IERC721Receiver.onERC721Received.selector;
  }
}