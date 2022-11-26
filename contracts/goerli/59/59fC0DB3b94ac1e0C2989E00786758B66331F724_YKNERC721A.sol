//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MGYERC721A.sol";

contract YKNERC721A is MGYERC721A{
  constructor (
      string memory _name,
      string memory _symbol
  ) MGYERC721A (_name,_symbol) {
    _extension = ".json";
  }
  //disabled
  function setSBTMode(bool) external virtual override onlyOwner {
  }
  //widraw ETH from this contract.only owner.  
  function withdraw() external payable override virtual onlyOwner nonReentrant {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    address wallet = payable(0xE99073F2BA37B44f5CCCf4758b179485F3984d7f);
    bool os;
    (os, ) = payable(wallet).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }



}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "./MGYREWARD.sol";

contract MGYERC721A is Ownable,ERC4907A, ReentrancyGuard, ERC2981{

  //Project Settings
  uint256 public wlMintPrice;//wl.price.
  uint256 public wlMintPrice1;//wl1.price.
  uint256 public wlMintPrice2;//wl2.price.
  uint256 public psMintPrice;//publicSale. price.
  uint256 public bmMintPrice;//Burn&MintSale. price.
  uint256 public hmMintPrice;//Hold&MintSale. price.
  uint256 public maxMintsPerPS;//publicSale.max mint num per wallet.
  uint256 public maxMintsPerBM;//Burn&MintSale.max mint num per wallet.
  uint256 public maxMintsPerHM;//Hold&MintSale.max mint num per wallet.
  uint256 public otherContractCount;//Hold&MintSale must hold otherContract count.
  
  uint256 public maxSupply;//max supply
  address payable internal _withdrawWallet;//withdraw wallet
  bool public isSBTEnabled;//SBT(can not transfer.only owner) mode enable.

  //URI
  mapping(uint256 => string) internal _revealUri;//by Season
  mapping(uint256 => string) internal _baseTokenURI;//by Season
  //flags
  bool public isWlEnabled;//WL enable.
  bool public isPsEnabled;//PublicSale enable.
  bool public isBmEnabled;//Burn&MintSale enable.
  bool public isHmEnabled;//Hold&MintSale enable.
  bool public isStakingEnabled;//Staking enable.
  mapping(uint256 => bool) internal _isRevealed;//reveal enable.by Season.
  //mint records.
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _wlMinted;//wl.mint num by wallet.by Season.by reset index
  mapping(uint256 => mapping(address => uint256)) internal _psMinted;//PublicSale.mint num by wallet.by Season.
  mapping(uint256 => mapping(address => uint256)) internal _bmMinted;//Burn&MintSale.mint num by wallet.by Season.
  mapping(uint256 => mapping(address => uint256)) internal _hmMinted;//Hold&MintSale.mint num by wallet.by Season.
  mapping(uint256 => mapping(uint256 => bool)) internal _otherTokenidUsed;//Hold&MintSale.otherCOntract's tokenid used .by Season.
  uint256 internal _wlResetIndex;   //_wlMinted value reset index.

  //Season value.
  uint256 internal _seasonCounter;   //Season Counter.
  mapping(uint256 => uint256) public seasonStartTokenId;//Start tokenid by Season.

  //contract status.for UI/UX frontend.
  uint256 internal _contractStatus;

  //merkleRoot
  bytes32 internal _merkleRoot;//whitelist
  bytes32 internal _merkleRoot1;//whitelist1
  bytes32 internal _merkleRoot2;//whitelist2
  //custom token uri
  mapping(uint256 => string) internal _customTokenURI;//custom tokenURI by tokenid
  //metadata file extention
  string internal _extension;
  //otherContract
  address public otherContract;//with Burn&MintSale or Hold&Mint.
  MGYERC721A internal _otherContractFactory;//otherContract's factory
  //staking
  mapping(uint256 => uint256) internal _stakingStartedTimestamp; // tokenId -> staking start time (0 = not staking).
  mapping(uint256 => uint256) internal _stakingTotalTime; // tokenId -> cumulative staking time, does not include current time if staking
  mapping(uint256 => uint256) internal _claimedLastTimestamp; // tokenId -> last claimed timestamp
  uint256 internal constant NULL_STAKED = 0;
  address public rewardContract;//reward contract address
  MGYREWARD internal _rewardContractFactory;//reward Contract's factory
  uint256 public stakingStartTimestamp;//staking start timestamp
  uint256 public stakingEndTimestamp;//staking end timestamp


  constructor (
      string memory _name,
      string memory _symbol
  ) ERC721A (_name,_symbol) {
    seasonStartTokenId[_seasonCounter] = _startTokenId();
    _extension = "";
  }
  //start from 1.adjust for bueno.
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
  }
  //set Default Royalty._feeNumerator 500 = 5% Royalty
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external virtual onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }
  //for ERC2981,ERC721A.ERC4907A
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC4907A, ERC2981) returns (bool) {
    return(
      ERC721A.supportsInterface(interfaceId) || 
      ERC4907A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId)
    );
  }
  //for ERC2981 Opensea
  function contractURI() external view virtual returns (string memory) {
        return _formatContractURI();
  }
  //make contractURI
  function _formatContractURI() internal view returns (string memory) {
    (address receiver, uint256 royaltyFraction) = royaltyInfo(0,_feeDenominator());//tokenid=0
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
                '{"seller_fee_basis_points":', Strings.toString(royaltyFraction),
                ', "fee_recipient":"', Strings.toHexString(uint256(uint160(receiver)), 20), '"}'
            )
          )
        )
      )
    );
  }
  //set owner's wallet.withdraw to this wallet.only owner.
  function setWithdrawWallet(address _owner) external virtual onlyOwner {
    _withdrawWallet = payable(_owner);
  }

  //set maxSupply.only owner.
  function setMaxSupply(uint256 _maxSupply) external virtual onlyOwner {
    require(totalSupply() <= _maxSupply, "Lower than _currentIndex.");
    maxSupply = _maxSupply;
  }
  //set wl price.only owner.
  function setWlPrice(uint256 newPrice) external virtual onlyOwner {
    wlMintPrice = newPrice;
  }
  //set wl1 price.only owner.
  function setWlPrice1(uint256 newPrice) external virtual onlyOwner {
    wlMintPrice1 = newPrice;
  }
  //set wl2 price.only owner.
  function setWlPrice2(uint256 newPrice) external virtual onlyOwner {
    wlMintPrice2 = newPrice;
  }
  //set public Sale price.only owner.
  function setPsPrice(uint256 newPrice) external virtual onlyOwner {
    psMintPrice = newPrice;
  }
  //set Burn&MintSale price.only owner.
  function setBmPrice(uint256 newPrice) external virtual onlyOwner {
    bmMintPrice = newPrice;
  }
  //set Hold&MintSale price.only owner.
  function setHmPrice(uint256 newPrice) external virtual onlyOwner {
    hmMintPrice = newPrice;
  }
  //set reveal.only owner.current season.
  function setReveal(bool bool_) external virtual onlyOwner {
    _isRevealed[_seasonCounter] = bool_;
  }
  //set reveal.only owner.by season.
  function setRevealBySeason(bool bool_,uint256 _season) external virtual onlyOwner {
    _isRevealed[_season] = bool_;
  }

  //return _isRevealed.current season.
  function isRevealed() external view virtual returns (bool){
    return _isRevealed[_seasonCounter];
  }
  //return _isRevealed.by season.
  function isRevealedBySeason(uint256 _season) external view virtual returns (bool){
    return _isRevealed[_season];
  }

  //return _wlMinted.current season.
  function wlMinted(address _address) external view virtual returns (uint256){
    return _wlMinted[_seasonCounter][_address][_wlResetIndex];
  }
  //return _wlMinted.by season.
  function wlMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _wlMinted[_season][_address][_wlResetIndex];
  }

  //return _psMinted.current season.
  function psMinted(address _address) external view virtual returns (uint256){
    return _psMinted[_seasonCounter][_address];
  }
  //return _psMinted.by season.
  function psMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _psMinted[_season][_address];
  }

  //return _bmMinted.current season.
  function bmMinted(address _address) external view virtual returns (uint256){
    return _bmMinted[_seasonCounter][_address];
  }
  //return _bmMinted.by season.
  function bmMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _bmMinted[_season][_address];
  }

  //return _hmMinted.current season.
  function hmMinted(address _address) external view virtual returns (uint256){
    return _hmMinted[_seasonCounter][_address];
  }
  //return _hmMinted.by season.
  function hmMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _hmMinted[_season][_address];
  }

  //set PublicSale's max mint num.only owner.
  function setPsMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerPS = _max;
  }
  //set Burn&MintSale's max mint num.only owner.
  function setBmMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerBM = _max;
  }
  //set Hold&MintSale's max mint num.only owner.
  function setHmMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerHM = _max;
  }
  //set otherContract count with Hold&Mint.only owner.
  function setOtherContractCount(uint256 _count) external virtual onlyOwner {
    otherContractCount = _count;
  }
  //set _otherTokenidUsed with Hold&Mint.only owner.
  function setOtherTokenidUsed(uint256 _tokenId,bool bool_) external virtual onlyOwner {
    require(_otherContractFactory.ownerOf(_tokenId) != address(0), "nonexistent token");
    _otherTokenidUsed[_seasonCounter][_tokenId] = bool_;
  }
  //set _otherTokenidUsed with Hold&Mint by season .only owner.
  function setOtherTokenidUsedBySeason(uint256 _tokenId,bool bool_,uint256 _season) external virtual onlyOwner {
    require(_otherContractFactory.ownerOf(_tokenId) != address(0), "nonexistent token");
    _otherTokenidUsed[_season][_tokenId] = bool_;
  }
  //return _otherTokenidUsed
  function getOtherTokenidUsed(uint256 _tokenId) external view virtual returns (bool){
    return _otherTokenidUsed[_seasonCounter][_tokenId];
  }
  //return _otherTokenidUsed.by Season
  function getOtherTokenidUsedBySeason(uint256 _tokenId,uint256 _season) external view virtual returns (bool){
    return _otherTokenidUsed[_season][_tokenId];
  }
    
  //set WLsale.only owner.
  function setWhitelistSale(bool bool_) external virtual onlyOwner {
    isWlEnabled = bool_;
  }
  //set Publicsale.only owner.
  function setPublicSale(bool bool_) external virtual onlyOwner {
    isPsEnabled = bool_;
  }
  //set Burn&MintSale.only owner.
  function setBurnAndMintSale(bool bool_) external virtual onlyOwner {
    isBmEnabled = bool_;
  }
  //set Hold&MintSale.only owner.
  function setHoldAndMintSale(bool bool_) external virtual onlyOwner {
    isHmEnabled = bool_;
  }

  //set MerkleRoot.only owner.
  function setMerkleRoot(bytes32 merkleRoot_) external virtual onlyOwner {
    _merkleRoot = merkleRoot_;
  }
  //set MerkleRoot.only owner.
  function setMerkleRoot1(bytes32 merkleRoot_) external virtual onlyOwner {
    _merkleRoot1 = merkleRoot_;
  }
  //set MerkleRoot.only owner.
  function setMerkleRoot2(bytes32 merkleRoot_) external virtual onlyOwner {
    _merkleRoot2 = merkleRoot_;
  }
  //isWhitelisted
  function isWhitelisted(address address_, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external view virtual returns (bool) {
    return(_isWhitelisted(address_,maxmint_,proof_,proof1_,proof2_));
  }
  function _isWhitelisted(address address_,uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal view  returns (bool) {
    return(
          _hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)   || 
          _hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof1_) ||
          _hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof2_)
    );
  }
  //get WL maxMints.
  function getWhitelistedMaxMints(address address_, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external view virtual returns (uint256) {
    return(_getWhitelistedMaxMints(address_, maxmint_, proof_, proof1_, proof2_));
  }
  function _getWhitelistedMaxMints(address address_, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal view  returns (uint256) {
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)) return maxmint_;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof1_)) return maxmint_;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof2_)) return maxmint_;
    return 0;
  }
  //have you WL?
  function hasWhitelistedOneWL(address address_,uint256 maxmint_, bytes32[] memory proof_) external view virtual returns (bool) {
    return(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_));
  }
  function _hasWhitelistedOneWL(address address_,uint256 maxmint_,bytes32 root_, bytes32[] memory proof_) internal pure returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(address_,maxmint_));
    return(root_ != 0x0 && MerkleProof.verify(proof_,root_,_leaf));
  }
  //have you WL1?
  function hasWhitelistedOneWL1(address address_,uint256 maxmint_,bytes32[] memory proof_) external view virtual returns (bool) {
    return(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof_));
  }
  //have you WL2?
  function hasWhitelistedOneWL2(address address_,uint256 maxmint_,bytes32[] memory proof_) external view virtual returns (bool) {
    return(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof_));
  }
  //get WL price.
  function getWhitelistedPrice(address address_, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external view virtual returns (uint256) {
    return(_getWhitelistedPrice(address_, maxmint_, proof_, proof1_, proof2_));
  }
  function _getWhitelistedPrice(address address_, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal view  returns (uint256) {
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)) return wlMintPrice;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof1_)) return wlMintPrice1;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof2_)) return wlMintPrice2;
    return 9999;
  }

  //set SBT mode Enable. only owner.Noone can transfer. only contract owner can transfer.
  function setSBTMode(bool bool_) external virtual onlyOwner {
    isSBTEnabled = bool_;
  }
  //override for SBT mode.only owner can transfer. or mint or burn.
  function _beforeTokenTransfers(address from_,address to_,uint256 startTokenId_,uint256 quantity_) internal virtual override {
    require(!isSBTEnabled || msg.sender == owner() || from_ == address(0) || to_ == address(0) ,"SBT mode Enabled: token transfer while paused.");

    //check tokenid transfer
    for (uint256 tokenId = startTokenId_; tokenId < startTokenId_ + quantity_; tokenId++) {
      //check staking
      require(!isStakingEnabled || _stakingStartedTimestamp[tokenId] == NULL_STAKED,"Staking now.: token transfer while paused.");

      //unstake if staking
      if (_stakingStartedTimestamp[tokenId] != NULL_STAKED) {
        //accum current time
        uint256 deltaTime = block.timestamp - _stakingStartedTimestamp[tokenId];
        _stakingTotalTime[tokenId] += deltaTime;
        //no longer staking
        _stakingStartedTimestamp[tokenId] = NULL_STAKED;
        _claimedLastTimestamp[tokenId] = NULL_STAKED;

      }
    }
    super._beforeTokenTransfers(from_, to_, startTokenId_, quantity_);
  }

  //set HiddenBaseURI.only owner.current season.
  function setHiddenBaseURI(string memory uri_) external virtual onlyOwner {
    _revealUri[_seasonCounter] = uri_;
  }
  //set HiddenBaseURI.only owner.by season.
  function setHiddenBaseURIBySeason(string memory uri_,uint256 _season) external virtual onlyOwner {
    _revealUri[_season] = uri_;
  }

  //return _nextTokenId
  function getCurrentIndex() external view virtual returns (uint256){
    return _nextTokenId();
  }
  //return status.
  function getContractStatus() external view virtual returns (uint256){
    return _contractStatus;
  }
  //set status.only owner.
  function setContractStatus(uint256 status_) external virtual onlyOwner {
    _contractStatus = status_;
  }
  //return wlResetIndex.
  function getWlResetIndex() external view virtual returns (uint256){
    return _wlResetIndex;
  }
  //reset _wlMinted.only owner.
  function resetWlMinted() external virtual onlyOwner {
    _wlResetIndex++;
  }
  //return Season.
  function getSeason() external view virtual returns (uint256){
    return _seasonCounter;
  }
  //increment next Season.only owner.
  function incrementSeason() external virtual onlyOwner {
    //pause all sale
    isWlEnabled = false;
    isPsEnabled = false;
    isBmEnabled = false;
    isHmEnabled = false;
    //reset tree
    _merkleRoot = 0x0;
    _merkleRoot1 = 0x0;
    _merkleRoot2 = 0x0;
    //increment season
    _seasonCounter++;
    seasonStartTokenId[_seasonCounter] = _nextTokenId();//set start tonkenid for next Season.
  }
  //return season by tokenid.
  function getSeasonByTokenId(uint256 _tokenId) external view virtual returns(uint256){
    return _getSeasonByTokenId(_tokenId);
  }
  //return season by tokenid.
  function _getSeasonByTokenId(uint256 _tokenId) internal view returns(uint256){
    require(_exists(_tokenId), "Season query for nonexistent token");
    uint256 nextStartTokenId = 10000000000;//start tokenid for next season.set big tokenid.
    for (uint256 i = _seasonCounter; i >= 0; i--) {
      if(seasonStartTokenId[i] <= _tokenId && _tokenId < nextStartTokenId) return i;
      nextStartTokenId = seasonStartTokenId[i];
    }
    return 0;//can not reach here.
  }


  //set BaseURI at after reveal. only owner.current season.
  function setBaseURI(string memory uri_) external virtual onlyOwner {
    _baseTokenURI[_seasonCounter] = uri_;
  }
  //set BaseURI at after reveal. only owner.by season.
  function setBaseURIBySeason(string memory uri_,uint256 _season) external virtual onlyOwner {
    _baseTokenURI[_season] = uri_;
  }

  //set custom tokenURI at after reveal. only owner.
  function setCustomTokenURI(uint256 _tokenId,string memory uri_) external virtual onlyOwner {
    require(_exists(_tokenId), "URI query for nonexistent token");
    _customTokenURI[_tokenId] = uri_;
  }
  function getCustomTokenURI(uint256 _tokenId) external view virtual returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    return(_customTokenURI[_tokenId]);
  }
  //retuen BaseURI.internal.current season.
  function _currentBaseURI(uint256 _season) internal view returns (string memory){
    return _baseTokenURI[_season];
  }
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    uint256 _season = _getSeasonByTokenId(_tokenId);//get season.
    if(_isRevealed[_season] == false) return _revealUri[_season];
    if(bytes(_customTokenURI[_tokenId]).length != 0) return _customTokenURI[_tokenId];//custom URI
    return string(abi.encodePacked(_currentBaseURI(_season), Strings.toString(_tokenId), _extension));
  }

  //common mint.transfer to _address.
  function _commonMint(address _address,uint256 _amount) internal virtual { 
    require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");

    _safeMint(_address, _amount);
  }
  //owner mint.transfer to _address.only owner.
  function ownerMint(uint256 _amount, address _address) external virtual onlyOwner {
    _commonMint(_address, _amount);
  }
  //WL mint.
  function whitelistMint(uint256 _amount, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external payable virtual nonReentrant {
    _whitelistMintCheck(_amount, maxmint_, proof_, proof1_, proof2_);
    _whitelistMintCheckValue(_amount, maxmint_, proof_, proof1_, proof2_);
    unchecked{
      _wlMinted[_seasonCounter][msg.sender][_wlResetIndex] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //WL check.except value.
  function _whitelistMintCheck(uint256 _amount, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal virtual {
    require(isWlEnabled, "whitelistMint is Paused");
    require(_isWhitelisted(msg.sender, maxmint_,proof_, proof1_, proof2_), "You are not whitelisted!");
    uint256 maxMints = _getWhitelistedMaxMints(msg.sender, maxmint_, proof_, proof1_, proof2_);
    require(maxMints >= _amount, "whitelistMint: Over max mints per wallet");
    require(maxMints >= _wlMinted[_seasonCounter][msg.sender][_wlResetIndex] + _amount, "You have no whitelistMint left");
  }
  //WL check.Only Value.for optional free mint.
  function _whitelistMintCheckValue(uint256 _amount, uint256 maxmint_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal virtual {
    uint256 price = _getWhitelistedPrice(msg.sender, maxmint_, proof_, proof1_, proof2_);
    require(msg.value == price * _amount, "ETH value is not correct");
  }
  //Public mint.
  function publicMint(uint256 _amount) external payable virtual nonReentrant {
    require(isPsEnabled, "publicMint is Paused");
    require(maxMintsPerPS >= _amount, "publicMint: Over max mints per wallet");
    require(maxMintsPerPS >= _psMinted[_seasonCounter][msg.sender] + _amount, "You have no publicMint left");
    _publicMintCheckValue(_amount);

    unchecked{
      _psMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //Public check.Only Value.for optional free mint.
  function _publicMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == psMintPrice * _amount, "ETH value is not correct");
  }
  //set otherContract.only owner
  function setOtherContract(address _addr) external virtual onlyOwner {
    otherContract = _addr;
    _otherContractFactory = MGYERC721A(otherContract);
  }
  //Burn&MintSale mint.
  function burnAndMint(uint256 _amount,uint256[] calldata _tokenids) external payable virtual nonReentrant {
    require(isBmEnabled, "Burn&MintSale is Paused");
    require(maxMintsPerBM >= _amount, "Burn&MintSale: Over max mints per wallet");
    require(maxMintsPerBM >= _bmMinted[_seasonCounter][msg.sender] + _amount, "You have no Burn&MintSale left");
    _burnAndMintCheckValue(_amount);
    require(otherContract != address(0),"not set otherContract.");
    require(otherContractCount != 0 ,"not set otherContractCount.");
    require( _tokenids.length == (otherContractCount * _amount),"amount must be multiple of other contract count.");
    //check tokens owner , used.
    for (uint256 i = 0; i < _tokenids.length; i++) {
      require(_otherContractFactory.ownerOf(_tokenids[i]) == msg.sender,"You are not owner of this tokenid.");
      _otherContractFactory.burn(_tokenids[i]);//must approval.
    }
    
    unchecked{
      _bmMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //BM check.Only Value.for optional free mint.
  function _burnAndMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == bmMintPrice * _amount, "ETH value is not correct");
  }

  //Hold&MintSale mint.
  function holdAndMint(uint256 _amount,uint256[] calldata _tokenids) external payable virtual nonReentrant {
    require(isHmEnabled, "Hold&MintSale is Paused");
    require(maxMintsPerHM >= _amount, "Hold&MintSale: Over max mints per wallet");
    require(maxMintsPerHM >= _hmMinted[_seasonCounter][msg.sender] + _amount, "You have no Hold&MintSale left");
    _holdAndMintCheckValue(_amount);
    require(otherContract != address(0),"not set otherContract.");
    require(otherContractCount != 0 ,"not set otherContractCount.");
    require( _tokenids.length == (otherContractCount * _amount),"amount must be multiple of other contract count.");
    //check tokens owner , used.
    for (uint256 i = 0; i < _tokenids.length; i++) {
      require(_otherContractFactory.ownerOf(_tokenids[i]) == msg.sender,"You are not owner of this tokenid.");
      require(!_otherTokenidUsed[_seasonCounter][_tokenids[i]] ,"This other tokenid is Used.");
      _otherTokenidUsed[_seasonCounter][_tokenids[i]] = true;
    }

    unchecked{
      _hmMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //HM check.Only Value.for optional free mint.
  function _holdAndMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == hmMintPrice * _amount, "ETH value is not correct");
  }

  //burn
  function burn(uint256 tokenId) external virtual {
    _burn(tokenId, true);
  }

  //widraw ETH from this contract.only owner. 
  function withdraw() external payable virtual onlyOwner nonReentrant{
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    bool os;
    if(_withdrawWallet != address(0)){//if _withdrawWallet has.
      (os, ) = payable(_withdrawWallet).call{value: address(this).balance}("");
    }else{
      (os, ) = payable(owner()).call{value: address(this).balance}("");
    }
    require(os);
    // =============================================================================
  }
  //return wallet owned tokenids.it used high gas and running time.
  function walletOfOwner(address owner) external view virtual returns (uint256[] memory) {
    //copy from tokensOfOwner in ERC721AQueryable.sol 
    unchecked {
      uint256 tokenIdsIdx = 0;
      address currOwnershipAddr = address(0);
      uint256 tokenIdsLength = balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; i++) {
        ownership = _ownershipAt(i);
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }
  //set Staking enable.only owner.
  function setStakingEnable(bool bool_) external virtual onlyOwner {
    isStakingEnabled = bool_;
    if(bool_){
      stakingStartTimestamp = block.timestamp;
      stakingEndTimestamp = NULL_STAKED;
    }else{
      stakingEndTimestamp = block.timestamp;
    }
  }
  //get staking information.
  function _getStakingInfo(uint256 _tokenId) internal view virtual returns (uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking,uint256 claimedLastTimestamp ){
    require(_exists(_tokenId), "nonexistent token");

    currentStakingTime = 0;
    startTimestamp = _stakingStartedTimestamp[_tokenId];

    if (startTimestamp != NULL_STAKED) {  // is staking
      currentStakingTime = block.timestamp - startTimestamp;
    }
    totalStakingTime = currentStakingTime + _stakingTotalTime[_tokenId];
    isStaking = startTimestamp != NULL_STAKED;
    claimedLastTimestamp = _claimedLastTimestamp[_tokenId];
  }
  //get staking information.
  function getStakingInfo(uint256 _tokenId) external view virtual returns (uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking,uint256 claimedLastTimestamp ){
    (startTimestamp, currentStakingTime, totalStakingTime, isStaking, claimedLastTimestamp) = _getStakingInfo(_tokenId);
  }
  
  //toggle staking status
  function _toggleStaking(uint256 _tokenId) internal virtual {
    require(ownerOf(_tokenId) == msg.sender,"You are not owner of this tokenid.");
    require(_exists(_tokenId), "nonexistent token");

    uint256 startTimestamp = _stakingStartedTimestamp[_tokenId];

    if (startTimestamp == NULL_STAKED) { 
      //start staking
      require(isStakingEnabled, "Staking closed");
      _stakingStartedTimestamp[_tokenId] = block.timestamp;
    } else { 
      //start unstaking
      _stakingTotalTime[_tokenId] += block.timestamp - startTimestamp;
      _stakingStartedTimestamp[_tokenId] = NULL_STAKED;
      _claimedLastTimestamp[_tokenId] = NULL_STAKED;
    }
  }
  //toggle staking status
  function toggleStaking(uint256[] calldata _tokenIds) external virtual {
    uint256 num = _tokenIds.length;

    for (uint256 i = 0; i < num; i++) {
      uint256 tokenId = _tokenIds[i];
      _toggleStaking(tokenId);
    }
  }
  //set rewardContract.only owner
  function setRewardContract(address _addr) external virtual onlyOwner {
    rewardContract = _addr;
    _rewardContractFactory = MGYREWARD(rewardContract);
  }

  //claim reward
  function _claimReward(uint256 _tokenId) internal virtual {
    require(ownerOf(_tokenId) == msg.sender,"You are not owner of this tokenid.");
    require(_exists(_tokenId), "nonexistent token");

    //get staking infomation
    (uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking,uint256 claimedLastTimestamp ) = _getStakingInfo(_tokenId);
    uint256 _lastTimestamp = block.timestamp;
    
    _claimedLastTimestamp[_tokenId] = _lastTimestamp; //execute before claimReward().Warning for slither.
    //call reword. other contract 
    _rewardContractFactory.claimReward(stakingStartTimestamp, stakingEndTimestamp, _tokenId, startTimestamp,  currentStakingTime,  totalStakingTime,  isStaking,  claimedLastTimestamp,  _lastTimestamp);

  }
  //claim reward
  function claimReward(uint256[] calldata _tokenIds) external virtual nonReentrant{
    require(isStakingEnabled, "Staking closed");//only staking period
    uint256 num = _tokenIds.length;

    for (uint256 i = 0; i < num; i++) {
      uint256 tokenId = _tokenIds[i];
      _claimReward(tokenId);
    }
  }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC4907A.sol';
import '../ERC721A.sol';

/**
 * @title ERC4907A
 *
 * @dev [ERC4907](https://eips.ethereum.org/EIPS/eip-4907) compliant
 * extension of ERC721A, which allows owners and authorized addresses
 * to add a time-limited role with restricted permissions to ERC721 tokens.
 */
abstract contract ERC4907A is ERC721A, IERC4907A {
    // The bit position of `expires` in packed user info.
    uint256 private constant _BITPOS_EXPIRES = 160;

    // Mapping from token ID to user info.
    //
    // Bits Layout:
    // - [0..159]   `user`
    // - [160..223] `expires`
    mapping(uint256 => uint256) private _packedUserInfo;

    /**
     * @dev Sets the `user` and `expires` for `tokenId`.
     * The zero address indicates there is no user.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual override {
        // Require the caller to be either the token owner or an approved operator.
        address owner = ownerOf(tokenId);
        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A()))
                if (getApproved(tokenId) != _msgSenderERC721A()) revert SetUserCallerNotOwnerNorApproved();

        _packedUserInfo[tokenId] = (uint256(expires) << _BITPOS_EXPIRES) | uint256(uint160(user));

        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * @dev Returns the user address for `tokenId`.
     * The zero address indicates that there is no user or if the user is expired.
     */
    function userOf(uint256 tokenId) public view virtual override returns (address) {
        uint256 packed = _packedUserInfo[tokenId];
        assembly {
            // Branchless `packed *= (block.timestamp <= expires ? 1 : 0)`.
            // If the `block.timestamp == expires`, the `lt` clause will be true
            // if there is a non-zero user address in the lower 160 bits of `packed`.
            packed := mul(
                packed,
                // `block.timestamp <= expires ? 1 : 0`.
                lt(shl(_BITPOS_EXPIRES, timestamp()), packed)
            )
        }
        return address(uint160(packed));
    }

    /**
     * @dev Returns the user's expires of `tokenId`.
     */
    function userExpires(uint256 tokenId) public view virtual override returns (uint256) {
        return _packedUserInfo[tokenId] >> _BITPOS_EXPIRES;
    }

    /**
     * @dev Override of {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        // The interface ID for ERC4907 is `0xad092b5c`,
        // as defined in [ERC4907](https://eips.ethereum.org/EIPS/eip-4907).
        return super.supportsInterface(interfaceId) || interfaceId == 0xad092b5c;
    }

    /**
     * @dev Returns the user address for `tokenId`, ignoring the expiry status.
     */
    function _explicitUserOf(uint256 tokenId) internal view virtual returns (address) {
        return address(uint160(_packedUserInfo[tokenId]));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MGYERC721A.sol";

contract MGYREWARD is Ownable,ReentrancyGuard{
  address public callContract;//callable MGYERC721A address
  MGYERC721A internal _callContractFactory;//callable Contract's factory

  //set callContract.only owner
  function setCallContract(address _callAddr) external virtual onlyOwner{
    callContract = _callAddr;
    _callContractFactory = MGYERC721A(callContract);
  }
  //execute reward
  function _claimReward(uint256 _stakingStartTimestamp, uint256 _stakingEndTimestamp, uint256 _tokenId,uint256 _startTimestamp, uint256 _currentStakingTime, uint256 _totalStakingTime, bool _isStaking, uint256 _claimedLastTimestamp, uint256 _currentClaimedLastTimestamp) internal virtual{
    //do reword something todo
  }
  //execute reward
  function claimReward(uint256 _stakingStartTimestamp, uint256 _stakingEndTimestamp, uint256 _tokenId,uint256 _startTimestamp, uint256 _currentStakingTime, uint256 _totalStakingTime, bool _isStaking, uint256 _claimedLastTimestamp, uint256 _currentClaimedLastTimestamp) external virtual nonReentrant{
    require(callContract != address(0),"not set callContract.");
    require(msg.sender == callContract,"only callContract can call this function.");
    
    _claimReward(_stakingStartTimestamp, _stakingEndTimestamp, _tokenId, _startTimestamp,  _currentStakingTime,  _totalStakingTime, _isStaking, _claimedLastTimestamp,  _currentClaimedLastTimestamp);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC4907A.
 */
interface IERC4907A is IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error SetUserCallerNotOwnerNorApproved();

    /**
     * @dev Emitted when the `user` of an NFT or the `expires` of the `user` is changed.
     * The zero address for user indicates that there is no user address.
     */
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /**
     * @dev Sets the `user` and `expires` for `tokenId`.
     * The zero address indicates there is no user.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /**
     * @dev Returns the user address for `tokenId`.
     * The zero address indicates that there is no user or if the user is expired.
     */
    function userOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the user's expires of `tokenId`.
     */
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}