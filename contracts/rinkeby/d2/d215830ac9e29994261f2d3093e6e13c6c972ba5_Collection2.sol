// SPDX-License-Identifier: MIT

// 1st Collection

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Collection2 is ERC721A, Ownable {

  using Strings for uint256;

  string private baseURI;
  string private notRevealedUri;
  string public baseExtension = ".json";

  uint256 public cost = 0.0002 ether;
  uint256 public maxSupply = 6666;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 20;

  bool public paused = false;
  bool public revealed = false;

  address public cltAddress;

  mapping( address => uint256 ) public addressMintedBalance;
  mapping( address => mapping( uint256 => uint256 )) private _ownedTokens;

  constructor(
    // string memory _initBaseURI,
    // string memory _initNotRevealUri
  ) ERC721A( "Collection 2", "CLT2" ) {
    // setBaseURI( _initBaseURI );
    // setNotRevealedURI( _initNotRevealUri );

    setBaseURI( "ipfs://QmS5otJCU2xrda7Kgye25QgXXf9cxLJCpjjrNDyTGZNGCw/" );
    setNotRevealedURI( "ipfs://QmYULr86h9oU26qdX5UN24G44Yw2ZkdR9R7NvoKAoBFb63/hidden.json/" );
    setCltAddress( 0x5e1D0C2b1C1336C0F238F45a9Ea584315A24110C );
  }

  // internal
  function _baseURI() internal view virtual override returns ( string memory ) {
    return baseURI;
  }

  // Mint
  function mint( uint256 _mintAmount ) public payable {
    require( !paused, "The Contract is Paused!!!" );

    IERC721A clt = IERC721A( cltAddress );
    uint256 supply = totalSupply();
    uint256 nftOwned = clt.balanceOf( msg.sender );
    
    require( _mintAmount > 0, "Need to Mint at Least 1 NFT" );
    require( _mintAmount <= maxMintAmount, "Max Mint Amount Per Session Exceeded" );
    require( supply + _mintAmount <= maxSupply, "Max NFT Limit Exceeded" );

    if ( msg.sender != owner() ) {
      uint256 ownerMintedCount = addressMintedBalance[ msg.sender ];
      require( ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT Per Address Exceeded" );

      if ( nftOwned >= 3) {
        require( nftOwned >= 3, "You Don't Own The First Collection" );
      } 
      
      else {
        require( msg.value >= cost * _mintAmount, "Insufficient Funds" );
      }
    }

    addressMintedBalance[ msg.sender ] += _mintAmount;
    _safeMint( msg.sender, _mintAmount );
  }

  // View TokenURI
  function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
    require( _exists( tokenId ), "ERC721Metadata: URI query for nonexistent token" );
    
    // Check If Revealed
    if ( revealed == false ) {
        return notRevealedUri;
    }
    
    string memory currentBaseURI = _baseURI();
    return bytes( currentBaseURI ).length > 0
      ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension )) : "";
  }

  // View Number of NFT in Wallet
  function getNFTBalance( address _wallet ) public view returns( uint ) {
    return balanceOf( _wallet );
  }

  // View NFT of 1st Collection Owned
  function getCltOwned( address _wallet ) public view returns( uint ) {
    IERC721A _clt = IERC721A( cltAddress );

    return _clt.balanceOf( _wallet );
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


  // ------------------------------------------------------------------------------- //
  // Only Owner                                                                     //
  // ----------------------------------------------------------------------------- //

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

  // Set Collection Address
  function setCltAddress( address _newAddress ) public onlyOwner {
    cltAddress = _newAddress;
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