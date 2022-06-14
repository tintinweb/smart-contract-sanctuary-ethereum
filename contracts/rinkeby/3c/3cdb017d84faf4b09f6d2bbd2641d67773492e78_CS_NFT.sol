// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CS_NFT is ERC721A, Ownable {

  using Strings for uint256;

  string private baseURI;
  string private notRevealedUri;

  string public baseExtension = ".json";
  uint256 public cost = 0.0002 ether;
  uint256 public maxSupply = 30;
  uint256 public freeMintNumber = 10;
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 10;
  bool public paused = true;
  bool public revealed = false;
  mapping( address => uint256 ) public addressMintedBalance;
  mapping( address => mapping( uint256 => uint256 )) private _ownedTokens;
  constructor(
    string memory _initBaseURI,  
    string memory _initNotRevealUri 
  ) ERC721A( "cs_nft_2", "cn2" ) {
    setBaseURI( _initBaseURI ); 
    setNotRevealedURI( _initNotRevealUri ); 
  }

  function _baseURI() internal view virtual override returns ( string memory ) {
    return baseURI;
  }

  function mint( uint256 _mintAmount ) public payable {
    require( !paused, "The Contract is Paused!!!" );
    uint256 supply = totalSupply();
    require( _mintAmount > 0, "Need to Mint at Least 1 NFT" );
    require( _mintAmount <= maxMintAmount, "Max Mint Amount Per Session Exceeded" );
    require( supply + _mintAmount <= maxSupply, "Max NFT Limit Exceeded" );
    if ( msg.sender != owner() ) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT Per Address Exceeded");
        if(supply + _mintAmount > freeMintNumber) {
            require(msg.value >= cost * _mintAmount, "Insufficient Funds");
        }
    }
    addressMintedBalance[ msg.sender ] += _mintAmount;
    _safeMint( msg.sender, _mintAmount );
  }

  function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
    require( _exists( tokenId ), "ERC721Metadata: URI query for nonexistent token" );

    if ( revealed == false ) {
        return notRevealedUri;
    }
    
    string memory currentBaseURI = _baseURI();
    return bytes( currentBaseURI ).length > 0 ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension )) : "";
  }

  // View Number of Token in Wallet
  function getNoToken( address _wallet ) public view returns( uint ) {
    return balanceOf(_wallet);
  }

  // View Mint Cost
  function getMintCost() public view returns( uint ) {
    return cost;
  }

  // View Total Minted
  function getTotalMinted() public view returns( uint ) {
    return _totalMinted();
  }

  // View Max Supply
  function getMaxSupply() public view returns( uint ) {
    return maxSupply;
  }

  // View Mint Limit
  function getMintLimit() public view returns( uint ) {
    return nftPerAddressLimit;
  }

  // Check If Owner
  function isOwner( address _wallet ) public view returns( bool ) {
    if ( _wallet == owner() ) {
      return true;
    }
    return false;
  }

  // Check Mint Count
  function getMintCount( address _wallet ) public view returns( uint ) {
    return addressMintedBalance[ _wallet ];
  }

  // Pause
  function pause( bool _state ) public onlyOwner {
    paused = _state;
  }

  // Reveal NFT 
  function reveal() public onlyOwner {
    revealed = true;
  }
  // Not Reveal NFT 
  function notReveal() public onlyOwner {
    revealed = false;
  }
  
  // Set New Costs 
  function setCost( uint256 _newCost ) public onlyOwner {
    cost = _newCost;
  }

  // Set New Max Supply 
  function setMaxSupply( uint256 _newMaxSupply ) public onlyOwner {
    maxSupply = _newMaxSupply;
  }

  // Set Max Mint Amount
  function setMaxMintAmount( uint256 _newMaxMintAmount ) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  // Set NFT Limit Per Address 
  function setNftLimit( uint256 _limit ) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  // Set New Base Extension 
  function setBaseExtension( string memory _newBaseExtension ) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  // Set New Base URI
  function setBaseURI( string memory _newBaseURI ) public onlyOwner {
    baseURI = _newBaseURI;
  }

  // Set New Not Reveal URI
  function setNotRevealedURI( string memory _notRevealedURI ) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  // Withdraw
  function withdraw() public payable onlyOwner {
    ( bool _withdraw, ) = payable( owner() ).call { value: address( this ).balance }( "" );
    require( _withdraw );
  }

}