// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: tos_nft                 *
 * @team:   TheOtherSide                *
 ****************************************
 *   TOS-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Delegated.sol';
import './ERC721EnumerableT.sol';
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract TheOtherSide is ERC721EnumerableT, Delegated, ReentrancyGuard {
  using Strings for uint;

  /**
    * @dev Data structure of Moon
    */
  struct Moon {
    address owner;
    bool celestialType;
  }

  /**
     *    @notice Keep track of each user and their info
     */
    struct Staker {
        mapping(address => uint256[]) stakedTokens;
        mapping(address => uint256) timeStaked;
        uint256 amountStaked;
    }
    
    // @notice mapping of a staker to its current properties
    mapping(address => Staker) public stakers;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public originalStakeOwner;

     // @notice event emitted when a user has staked a token
    event Staked(address owner, uint256 tokenId);

    // @notice event emitted when a user has unstaked a token
    event Unstaked(address owner, uint256 tokenId);

  bool public revealed = false;
  string public notRevealedUri = "ipfs://QmXZGWhQp3CQc3svnDhUuf4yTtoQBuqumHeC33jmEG69Dd/hidden.json";

  uint public MAX_SUPPLY   = 8888;
  uint public PRICE        = 0.15 ether;
  uint public MAX_QTY = 2;
  
  Moon[] public moons;

  bool public isWhitelistActive = false;
  bool public isMintActive = false;

  mapping(address => uint) public accessList;

  bool public isStakeActive   = false;

  mapping(address => uint) private _balances;
  string private _tokenURIPrefix;
  string private _tokenURISuffix =  ".json";

  constructor()
    ERC721T("The Other Side", "TOS"){
  }

/**
  * @dev Returns the number of tokens in ``owners``'s account.
  */
  function balanceOf(address account) public view override returns (uint) {
    require(account != address(0), "MOON: balance query for the zero address");
    return _balances[account];
  }

/**
  * @dev Returns the bool of tokens if``owner``'s account contains the tokenIds.
  */
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view override returns( bool ){
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
    address owner = moons[tokenId].owner;
    require(owner != address(0), "MOON: query for nonexistent token");
    return owner;
  }

/**
  * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
  * Use along with {totalSupply} to enumerate all tokens.
  */
  function tokenByIndex(uint index) external view override returns (uint) {
    require(index < totalSupply(), "MOON: global index out of bounds");
    return index;
  }

/**
  * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
  * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
  */
  function tokenOfOwnerByIndex(address owner, uint index) public view override returns (uint tokenId) {
    uint count;
    for( uint i; i < moons.length; ++i ){
      if( owner == moons[i].owner ){
        if( count == index )
          return i;
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
    require(_exists(tokenId), "MOON: URI query for nonexistent token");

    if(revealed == false) {
        return notRevealedUri;
    }
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

/**
  * @dev Returns the total amount of tokens stored by the contract.
  */
  function totalSupply() public view override returns( uint totalSupply_ ){
    return moons.length;
  }

/**
  * @dev Returns the list of tokenIds stored by the owner's account.
  */
  function walletOfOwner( address account ) external view override returns( uint[] memory ){
    uint quantity = balanceOf( account );
    uint[] memory wallet = new uint[]( quantity );
    for( uint i; i < quantity; ++i ){
        wallet[i] = tokenOfOwnerByIndex( account, i );
    }
    return wallet;
  }

/**
  * @dev Owner sets the Staking contract address.
  */
  function setRevealState(bool reveal_) external onlyDelegates {
      revealed = reveal_;
  }

  /**
  * @dev Owner sets the Staking contract address.
  */
  function setUnrevealURI(string calldata notRevealUri_) external onlyDelegates {
      notRevealedUri = notRevealUri_;
  }

 /**
  * @dev mints token based on the number of qty specified.
  */
  function mint( uint quantity ) external payable nonReentrant {
    require(isMintActive == true,"MOON: Minting needs to be enabled.");
    require( msg.value >= PRICE * quantity, "MOON: Ether sent is not correct" );

    //If whitelist is active, people in WL can mint 
    //based on the allowable qty limit set by owner/delegates.
    if( isWhitelistActive ){
      require( accessList[ msg.sender ] >= quantity, "MOON: Account is less than the qty limit");
      accessList[ msg.sender ] -= quantity;
    } else { 
      //For public, MAX_QTY limit will be applied. 
      //MAX_QTY is determined by the owner/delegates
      require(quantity <= MAX_QTY, "MOON:Quantity must be less than or equal MAX_QTY");
    }

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "MOON: Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
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
  function team_mint(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates{
    require(quantity.length == recipient.length, "MOON: Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity < MAX_SUPPLY, "MOON: Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        uint tokenId = supply++;
        _mint( recipient[i], tokenId);
      }
    }
  }

/**
  * @dev Owner/Delegate sets the Whitelist active flag.
  */
  function setWhitelistAddress(address[] calldata accounts, uint allowed) external onlyDelegates{
    for(uint i; i < accounts.length; ++i){
      accessList[ accounts[i] ] = allowed;
    }
  }

/**
  * @dev Owner/Delegate sets the Minting flag.
  */
  function setMintingActive(bool mintActive_) external onlyDelegates {
    require( isMintActive != mintActive_ , "MOON: New value matches old" );
    isMintActive = mintActive_;
  }

/**
  * @dev Owner/Delegate sets the Whitelist active flag.
  */
  function setWhitelistActive(bool isWhitelistActive_) external onlyDelegates{
    require( isWhitelistActive != isWhitelistActive_ , "MOON: New value matches old" );
    isWhitelistActive = isWhitelistActive_;
  }

/**
  * @dev Owner/Delegates sets the BaseURI of IPFS.
  */
  function setBaseURI(string calldata prefix, string calldata suffix) external onlyDelegates{
    _tokenURIPrefix = prefix;
    _tokenURISuffix = suffix;
  }

/**
  * @dev Owner/Delegate sets the Max supply of the token.
  */
  function setMaxSupply(uint maxSupply) external onlyDelegates{
    require( MAX_SUPPLY != maxSupply, "MOON: New value matches old" );
    require( maxSupply >= totalSupply(), "MOON: Specified supply is lower than current balance" );
    MAX_SUPPLY = maxSupply;
  }

/**
  * @dev Owner/Delegate sets the Max. qty 
  */
  function setMaxQty(uint maxQty) external onlyDelegates{
    require( MAX_QTY != maxQty, "MOON: New value matches old" );
    MAX_QTY = maxQty;
  }

/**
  * @dev Owner/Delegate sets the minting price.
  */
  function setPrice(uint price) external onlyDelegates{
    require( PRICE != price, "MOON: New value matches old" );
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
    return tokenId < moons.length && moons[tokenId].owner != address(0);
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
  function updateMoontype(bool moonType, uint[] calldata tokenIds ) external onlyDelegates {
        //update logic to update the MoonType
        for(uint i=0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "MOON: TokenId not exist");
            moons[tokenIds[i]].celestialType = moonType;
        }
  }

/**
  * @dev returns the moontypes based on the tokenIds.
  */
  function getMoonType(uint[] calldata tokenIds) external view returns(bool[] memory moonTypes) {
      // return moontype true/false
      bool[] memory _moonTypes = new bool[](tokenIds.length);
      for(uint i; i < tokenIds.length; i++) {
        _moonTypes[i] = moons[tokenIds[i]].celestialType;
      }
      return _moonTypes;
  }

/**
  * @dev transfer tokenId to other address.
  */
  function _transfer(address from, address to, uint tokenId) internal override {
    require(moons[tokenId].owner == from, "MOON: transfer of token that is not owned");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    _beforeTokenTransfer(from, to);

    moons[tokenId].owner = to;
    emit Transfer(from, to, tokenId);
  }

  /**
    * @dev Get the tokens staked by a user
    */
    function getStakedTokens(address _user) public view returns (uint256[] memory tokenIds) {
        Staker storage staker = stakers[_user];
        return staker.stakedTokens[_user]; 
    }

/**
  * @dev Stake the NFT based on array of tokenIds
  */
    function stake( uint[] calldata tokenIds ) external {
        require( isStakeActive, "MOON: Staking is not active" );
        
        Moon storage moon;
        //Check if TokenIds exist and the moon owner is the msge sender
        for( uint i; i < tokenIds.length; ++i ){
            require( _exists(tokenIds[i]), "MOON: Query for nonexistent token" );
            moon = moons[ tokenIds[i] ];
            require(moon.owner == msg.sender, "MOON: Staking token that is not owned");

            _stake(msg.sender, tokenIds[i]);
        }
    }

    /**
    * @dev For internal access to stake the NFT based tokenId
    */
    function _stake( address _user, uint256 _tokenId ) internal {

        Staker storage staker = stakers[_user];

        staker.amountStaked += 1;
        staker.timeStaked[_user] = block.timestamp;
        staker.stakedTokens[_user].push(_tokenId);

        originalStakeOwner[_tokenId] = msg.sender;

        _transfer(_user,address(this), _tokenId);
      
        emit Staked(_user, _tokenId);

        
    }

/**
  * @dev Unstake the token based on array of tokenIds
  */
    function unStake( uint[] calldata tokenIds ) external {
        require( isStakeActive, "MOON: Staking is not active" );
        //Check if TokenIds exist
        for( uint i; i < tokenIds.length; ++i ){
            require( originalStakeOwner[tokenIds[i]] == msg.sender, 
            "MOON._unstake: Sender must have staked tokenID");
            _unstake(msg.sender,tokenIds[i]);        
        }
    }

    /**
    * @dev For internal access to unstake the NFT based tokenId
    */
    function _unstake( address _user, uint256 _tokenId) internal {

        Staker storage staker = stakers[_user];

        _removeElement(_user, _tokenId);

        delete originalStakeOwner[_tokenId];
        staker.timeStaked[_user] = block.timestamp;
        staker.amountStaked -= 1;

        if(staker.amountStaked == 0) {
            delete stakers[_user];
        }

        _transfer(address(this),_user, _tokenId);
        
        emit Unstaked(_user, _tokenId);
        
    }

  /**
    * @dev Owner/Delegate sets the Whitelist active flag.
    */
    function setStakeActive( bool isActive_ ) external onlyDelegates {
      require( isStakeActive != isActive_ , "MOON: New value matches old" );
      isStakeActive = isActive_;
    }

    /**
    *   @notice remove given elements from array
    *   @dev usable only if _array contains unique elements only
     */
    function _removeElement(address _user, uint256 _element) internal {
        Staker storage staker = stakers[_user];
        for (uint256 i; i<staker.stakedTokens[_user].length; i++) {
            if (staker.stakedTokens[_user][i] == _element) {
                staker.stakedTokens[_user][i] = staker.stakedTokens[_user][staker.stakedTokens[_user].length - 1];
                staker.stakedTokens[_user].pop();
                break;
            }
        }
    }
}