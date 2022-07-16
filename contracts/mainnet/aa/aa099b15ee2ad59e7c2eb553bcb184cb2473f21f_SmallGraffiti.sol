// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721T.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract SmallGraffiti is ERC721T, Ownable, ReentrancyGuard {
  using Strings for uint;


  /**
    * @dev Data structure of Moon
    */
  struct Moon {
    address owner;
    bool celestialType;
  }

  uint public MAX_SUPPLY   = 5555;
  uint public PRICE        = 0 ether;
  uint public MAX_QTY = 2;
  
  Moon[] public moons;

  bool public isMintActive = false;

  mapping(address => uint) private minted;

  mapping(address => uint) private _balances;
  string private _tokenURIPrefix="ipfs://Qmd82H1E7sBqvREn75TH64VnMPXeyr6H3XusSQ9gL61ctE/";
  string private _tokenURISuffix =  ".json";

  constructor() 
    ERC721T("Small Graffiti", "SG"){
  }
  
/**
  * @dev Returns the number of tokens in ``owners``'s account.
  */
  function balanceOf(address account) public view override returns (uint) {
    require(account != address(0), "Graffiti: balance query for the zero address");
    return _balances[account];
  }

/**
  * @dev Returns the bool of tokens if``owner``'s account contains the tokenIds.
  */
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool ){
    for(uint i; i < tokenIds.length; ++i ){
      if( moons[ tokenIds[i] ].owner != account )
        return false;
    }

    return true;
  }

/**
  * @dev Returns the owner of the `tokenId` token.
  *
  */
  function ownerOf( uint tokenId ) public override view returns( address owner_ ){
    address owner = moons[tokenId-1].owner;
    require(owner != address(0), "Graffiti: query for nonexistent token");
    return owner;
  }

/**
  * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
  * Use along with {totalSupply} to enumerate all tokens.
  */
  function tokenByIndex(uint index) external view returns (uint) {
    require(index <= totalSupply(), "Graffiti: global index out of bounds");
    return index;
  }

/**
  * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
  * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
  */
  function tokenOfOwnerByIndex(address owner, uint index) public view returns (uint tokenId) {
    uint count;
    for( uint i; i <= moons.length; ++i ){
      if( owner == moons[i].owner ){
        if( count == index )
          return i+1;
        else
          ++count;
      }
    }

    revert("ERC721Enumerable: owner index out of bounds");
  }

 /**
  * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
  */
  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "Graffiti: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

/**
  * @dev Returns the total amount of tokens stored by the contract.
  */
  function totalSupply() public view returns( uint totalSupply_ ){
    return moons.length;
  }



/**
  * @dev Returns the list of tokenIds stored by the owner's account.
  */
  function walletOfOwner( address account ) external view returns( uint[] memory ){
    uint quantity = balanceOf( account );
    uint[] memory wallet = new uint[]( quantity );
    for( uint i; i < quantity; ++i ){
        wallet[i] = tokenOfOwnerByIndex( account, i );
    }
    return wallet;
  }



 /**
  * @dev mints token based on the number of qty specified.
  */
  function mint( uint quantity ) external payable nonReentrant {
    require(isMintActive == true,"Graffiti: Minting needs to be enabled.");
    require(quantity + minted[msg.sender] <= MAX_QTY,"Graffiti:Quantity must be less than or equal MAX_QTY");
    require( msg.value >= PRICE , "Graffiti: Ether sent is not correct" );
    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Graffiti: Mint/order exceeds supply" );
    minted[msg.sender] += quantity;
    for(uint i; i < quantity; i++){
       uint tokenId =  ++supply ;
      _mint( msg.sender, tokenId );
    }
  }



/**
  * @dev Returns the balance amount of the Contract address.
  */
  function getBalanceofContract() external view returns (uint256) {
    return address(this).balance;
  }

/**
  * @dev Withdraws an amount from the contract balance.
  */
  function withdraw(uint256 amount_) public onlyOwner {
    require(address(this).balance >= amount_, "Address: insufficient balance");

    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: amount_}("");
    require(os);
    // =============================================================================
  }


  /**
  * @dev Allows team to mint the token without restriction.
  */
  function team_mint(uint[] calldata quantity, address[] calldata recipient) public onlyOwner{
    require(quantity.length == recipient.length, "Graffiti: Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_SUPPLY, "Graffiti: Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        uint tokenId = ++supply;
        _mint( recipient[i], tokenId);
      }
    }
  }

/**
  * @dev Owner/Delegate sets the Minting flag.
  */
  function setMintingActive(bool mintActive_) external onlyOwner {
    require( isMintActive != mintActive_ , "Graffiti: New value matches old" );
    isMintActive = mintActive_;
  }

/**
  * @dev Owner/Delegates sets the BaseURI of IPFS.
  */
  function setBaseURI(string calldata prefix, string calldata suffix) external onlyOwner{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }

/**
  * @dev Owner/Delegate sets the Max supply of the token.
  */
  function setMaxSupply(uint maxSupply) external onlyOwner{
    require( MAX_SUPPLY != maxSupply, "Graffiti: New value matches old" );
    require( maxSupply >= totalSupply(), "Graffiti: Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

/**
  * @dev Owner/Delegate sets the Max. qty 
  */
  function setMaxQty(uint maxQty) external onlyOwner{
    require( MAX_QTY != maxQty, "Graffiti: New value matches old" );
    MAX_QTY = maxQty;
  }

/**
  * @dev Owner/Delegate sets the minting price.
  */
  function setPrice(uint price) external onlyOwner{
    require( PRICE != price, "Graffiti: New value matches old" );
    PRICE = price;
  }

/**
  * @dev increment and decrement balances based on address from and  to.
  */
  function _beforeTokenTransfer(address from, address to) internal {
    if( from != address(0) )
      --_balances[ from ];

    if( to != address(0) )
      ++_balances[ to ];
  }

/**
  * @dev returns bool if the tokenId exist.
  */
  function _exists(uint tokenId) internal view override returns (bool) {
    return tokenId>0 && tokenId <= moons.length && moons[tokenId-1].owner != address(0);
  }

/**
  * @dev mints token based address and tokenId
  */
  function _mint(address to, uint tokenId) internal {
    _beforeTokenTransfer(address(0), to);
    moons.push(Moon(to,false));
    emit Transfer(address(0), to, tokenId);
  }

/**
    * @dev update the moon type.
    */
  function updateMoontype(bool moonType, uint[] calldata tokenIds ) external onlyOwner {
        //update logic to update the MoonType
        for(uint i=0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "Graffiti: TokenId not exist");
            moons[tokenIds[i]-1].celestialType = moonType;
        }
  }

/**
  * @dev returns the moontypes based on the tokenIds.
  */
  function getMoonType(uint[] calldata tokenIds) external view returns(bool[] memory moonTypes) {
      // return moontype true/false
      bool[] memory _moonTypes = new bool[](tokenIds.length);
      for(uint i; i < tokenIds.length; i++) {
        _moonTypes[i] = moons[tokenIds[i]-1].celestialType;
      }
      return _moonTypes;
  }

/**
  * @dev transfer tokenId to other address.
  */
  function _transfer(address from, address to, uint tokenId) internal override {
    require(moons[tokenId-1].owner == from, "Graffiti: transfer of token that is not owned");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _beforeTokenTransfer(from, to);

    moons[tokenId-1].owner = to;
    emit Transfer(from, to, tokenId);
  }
}