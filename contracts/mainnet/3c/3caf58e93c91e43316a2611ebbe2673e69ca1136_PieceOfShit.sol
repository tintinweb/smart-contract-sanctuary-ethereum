// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PieceOfShit is ERC721A, Ownable {

  using Strings for uint256;

  string private baseURI;
  string private notRevealedUri;
  string public baseExtension = ".json";
  uint256 public cost = 0.004 ether;
  uint256 public maxSupply = 100000;
  uint256 public freeMint = 2000;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 100;

  bool public paused = false;
  bool public revealed = true;

  mapping( address => uint256 ) public addressMintedBalance;
  mapping( address => mapping( uint256 => uint256 )) private _ownedTokens;
  
  constructor(
    string memory _initBaseURI,  
    string memory _initNotRevealUri 
  ) ERC721A( "RRPieceofshit", "RRSHIT" ) {
    setBaseURI( _initBaseURI ); 
    setNotRevealedURI( _initNotRevealUri ); 
  }

  function _baseURI() internal view virtual override returns ( string memory ) {
    return baseURI;
  }

  function mint( uint256 _mintAmount ) public payable {
    require( !paused, "RRSHIT :The Contract is Paused!!!" );
    uint256 supply = totalSupply();
    require( _mintAmount > 0, "RRSHIT :Need to Mint at Least 1 NFT" );
    require( _mintAmount <= maxMintAmount, "RRSHIT :Max Mint Amount Per Session Exceeded" );
    require( supply + _mintAmount <= maxSupply, "RRSHIT :Max NFT Limit Exceeded" );
    if ( msg.sender != owner() ) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "RRSHIT :Max NFT Per Address Exceeded");
        if(supply <= freeMint) {
            uint256 valueNumber = freeMint - supply;
            if(_mintAmount >= valueNumber) {
              require(msg.value >= cost * (_mintAmount-valueNumber), "RRSHIT :Insufficient Funds");
            }
        } else {
            require(msg.value >= cost * _mintAmount, "RRSHIT :Insufficient Funds");
        }
    }
    addressMintedBalance[ msg.sender ] += _mintAmount;
    _safeMint( msg.sender, _mintAmount );
  }

  function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
    require( _exists( tokenId ), "RRSHIT : URI query for nonexistent token" );
    if ( revealed == false ) {
        return notRevealedUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes( currentBaseURI ).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension )) : "";
  }

  function getNoToken( address _wallet ) public view returns( uint ) {
    return balanceOf(_wallet);
  }

  function getMintCost() public view returns( uint ) {
    return cost;
  }

  function getTotalMinted() public view returns( uint ) {
    return _totalMinted();
  }

  function getMaxSupply() public view returns( uint ) {
    return maxSupply;
  }

  function getMintLimit() public view returns( uint ) {
    return nftPerAddressLimit;
  }

  function isOwner( address _wallet ) public view returns( bool ) {
    if ( _wallet == owner() ) {
      return true;
    }
    return false;
  }

  function getMintCount( address _wallet ) public view returns( uint ) {
    return addressMintedBalance[ _wallet ];
  }

  function pause( bool _state ) public onlyOwner {
    paused = _state;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function notReveal() public onlyOwner {
    revealed = false;
  }
  
  function setMaxMintAmount( uint256 _newMaxMintAmount ) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  function setNftLimit( uint256 _limit ) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setNftPerLimit( uint256 _limit ) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setBaseExtension( string memory _newBaseExtension ) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setBaseURI( string memory _newBaseURI ) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI( string memory _notRevealedURI ) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function withdraw() public payable onlyOwner {
    ( bool _withdraw, ) = payable( owner() ).call { value: address( this ).balance }( "" );
    require( _withdraw );
  }
}