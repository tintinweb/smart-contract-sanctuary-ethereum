// contracts/Azuki.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// import "./ERC721Enumerable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract Test is ERC721A, Ownable {
  
  using Strings for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 1 ether;
  uint256 public maxSupply = 20;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 3;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelist = true;
  address[] public whitelistAddress;
  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721A( "Azuki 721A Test", "AZUKITEST" ) {
    setBaseURI( "ipfs://Qmb7yUiZfTZcu3no64VYVFiVoH45j46D3sTwUo4o4KerNV/" );
    setNotRevealedURI( "ipfs://QmfUCjbiwA1rrQfSWgN1EnAZSQQN9f29Xj67PzFQCf2xup/notRevealed.json/" );
  }

  // internal
  function _baseURI() internal view virtual override returns ( string memory ) {
    return baseURI;
  }

  // Public Mint
  function mint( uint256 _mintAmount ) public payable {
    require( !paused, "The Contract is Paused!!!" );
    uint256 supply = totalSupply();
    require( _mintAmount > 0, "Need to Mint at Least 1 NFT" );
    require( _mintAmount <= maxMintAmount, "Max Mint Amount Per Session Exceeded" );
    require( supply + _mintAmount <= maxSupply, "Max NFT Limit Exceeded" );
    
    if ( msg.sender != owner() ) {
        if( onlyWhitelist == true ) {
            require( isWhitelist( msg.sender ), "The Wallet is Not Whitelisted" );
        }

        uint256 ownerMintedCount = addressMintedBalance[ msg.sender ];
        require( ownerMintedCount + _mintAmount <= nftPerAddressLimit, "Max NFT Per Address Exceeded" );
        require( msg.value >= cost * _mintAmount, "Insufficient Funds" );
        
    }

    addressMintedBalance[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
    
    // for ( uint256 i = 1; i <= _mintAmount; i++ ) {
    //     addressMintedBalance[ msg.sender ]++;
    //   _safeMint( msg.sender, supply + i );
    // }
  }

  // ============================================================================= //
  // ***************************************************************************** //
  // Public View
  // ***************************************************************************** //
  // ============================================================================= //
  
  // View Token Ids in The Wallet 
  // function NFTinWallet( address _wallet ) public view returns ( uint256[] memory ) {
  //   uint256 numberOfOwnedNFT = balanceOf( _wallet );
  //   uint256[] memory tokenIds = new uint256[]( numberOfOwnedNFT );

  //   for ( uint256 i; i < numberOfOwnedNFT; i++ ) {
  //     tokenIds[ i ] = tokenOfOwnerByIndex( _wallet, i );
  //   }

  //   return tokenIds;
  // }

  // View TokenURI
  function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
    require( _exists( tokenId ), "ERC721Metadata: URI query for nonexistent token" );
    
    // Check If Revealed
    if ( revealed == false ) {
        return notRevealedUri;
    }
    // else {
    //   string memory currentBaseURI = _baseURI();
    //     return bytes( currentBaseURI ).length > 0
    //         ? string( abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension )) : "";
    // }
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
  }

  // View Mint Cost
  function getMintCost() public view returns( uint ) {
    return cost;
  }

  // View Total Supply
  function getTotalSupply() public view returns( uint ) {
    return totalSupply();
  }

  // View Max Supply
  function getMaxSupply() public view returns( uint ) {
    return maxSupply;
  }

  // Check If Owner
  function isOwner( address _wallet ) public view returns( bool ) {
    if ( _wallet == owner() ) {
      return true;
    }

    return false;
  }

  // ============================================================================= //
  // ***************************************************************************** //
  // Only Owner
  // ***************************************************************************** //
  // ============================================================================= //

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
    cost = _newMaxSupply;
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

  // ============================================================================= //
  // Whitelist
  // ============================================================================= //

  // Check if Pre-sale
  function isPreSale() public view returns( bool ) {
    return onlyWhitelist;
  }

  // Set Only Whitelist
  function setPreSale() public onlyOwner {
    onlyWhitelist = true;
  }

  // Set All Public Sale
  function setPublicSale() public onlyOwner {
      onlyWhitelist = false;
  }

  // Check Whitelist Wallet
  function isWhitelist( address _wallet ) public view returns ( bool ) {
    for ( uint i = 0; i < whitelistAddress.length; i++ ) {
      if ( whitelistAddress[ i ] == _wallet ) {
          return true;
      }
    }
    return false;
  }

  // Add Whitelist Address
  function whitelistWallet( address[] calldata _wallets ) public onlyOwner {
    delete whitelistAddress;
    whitelistAddress = _wallets;
  }

  // Get Whitelist Address
  function getWhitelist() public onlyOwner view returns ( address[] memory ) {
    return whitelistAddress;
  }

  // ============================================================================= //
  // Withdraw
  // ============================================================================= //
  function withdraw() public payable onlyOwner {
    ( bool _withdraw, ) = payable( owner() ).call { value: address( this ).balance }( "" );
    require( _withdraw );
  }
}