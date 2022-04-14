// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Delegated.sol';
import './ERC721EnumerableB.sol';
import "./Strings.sol";
import "./PaymentSplitter.sol";

contract KronicKatzNFT is Delegated, ERC721EnumerableB, PaymentSplitter {
  using Strings for uint;

  uint public FRELINE        = 2;
  uint public MAX_ORDER      = 1;
  uint public MAX_SUPPLY     = 10000;
  uint public MAX_WALLET     = 1;
  uint public PRESALE_WALLET = 1;
  uint public PRESALE_PRICE  = 0.025 ether;
  uint public MAINSALE_PRICE = 0 ether;
  
  bool public isMainsaleActive = true;
  bool public isPresaleActive  = false;
  mapping(address => bool) presale;

  string private _tokenURIPrefix = 'https://kronickatznfts.mypinata.cloud/ipfs/bafybeiamkhfq2tyzcjgz2wemhsnlst2mgjjethssuxxpwbtvfxoqqzel2a/';
  string private _tokenURISuffix = '.json';


  address[] private addressList = [
    0x86f2aD57b59bb5BE8091A0a5fDBecb168b63cA17,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a,
    0xBEcfbeb0359a7E0724760fa8018Eb0E4B8E0AE6b,
    0x43f2cF53FA7feD61b68EecB1Ba61b40D8C8809b4
  ];
  uint[] private shareList = [
    88,
    10,
     1,
     1
  ];

  constructor()
    ERC721B("KronicKatz.NFT", "KRONIC", 1)
    PaymentSplitter( addressList, shareList ){
  }

  //external
  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //external payable
  fallback() external payable {}

  function mint( uint quantity ) external payable {
    uint balance = balanceOf( msg.sender );
    if( isMainsaleActive ){
      require( quantity <= MAX_ORDER,            "Order too big"      );
      require( balance + quantity <= MAX_WALLET, "Don't be greedy" );
      require( msg.value >= MAINSALE_PRICE * quantity, "Ether sent is not correct" );
    }
    else if( isPresaleActive ){
      require( quantity <= MAX_ORDER,            "Order too big"          );
      require( presale[ msg.sender ],            "Account not authorized" );
      require( balance + quantity <= PRESALE_WALLET, "Don't be greedy" );
      require( msg.value >= PRESALE_PRICE * quantity, "Ether sent is not correct" );
    }
    else{
      revert( "No sales active" );
    }

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, _next() );
    }

    if( FRELINE > 0 && balance < FRELINE && balanceOf( msg.sender ) >= FRELINE )
      _mint( msg.sender, _next() );
  }

  //delegated
  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], _next() );
      }
    }
  }

  function setActive(bool isMainsaleActive_, bool isPresaleActive_) external onlyDelegates{
    require( isMainsaleActive != isMainsaleActive_ ||
      isPresaleActive != isPresaleActive_, "New value matches old" );
    isMainsaleActive = isMainsaleActive_;
    isPresaleActive = isPresaleActive_;
  }

  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates{
    _tokenURIPrefix = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  function setFreline(uint freline) external onlyDelegates{
    FRELINE = freline;
  }

  function setMaxOrder(uint maxOrder, uint maxSupply, uint maxWallet, uint presaleWallet) external onlyDelegates{
    require( MAX_ORDER != maxOrder ||
      MAX_SUPPLY != maxSupply ||
      MAX_WALLET != maxWallet ||
      PRESALE_WALLET != presaleWallet, "New value matches old" );
    require( maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPresale( address[] calldata accounts, bool allowed ) external onlyDelegates {
    for(uint i; i < accounts.length; ++i ){
      presale[ accounts[i] ] = allowed;
    }
  }

  function setPrice(uint mainsalePrice, uint presalePrice ) external onlyDelegates{
    require( MAINSALE_PRICE != mainsalePrice ||
      PRESALE_PRICE != presalePrice, "New value matches old" );
    MAINSALE_PRICE = mainsalePrice;
    PRESALE_PRICE = presalePrice;
  }
}