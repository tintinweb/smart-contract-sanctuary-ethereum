// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract BAZ is ERC721A, Ownable {

  using SafeMath for uint256;

  uint256 public maxMint;
  uint256 public maxTokens;
  mapping (address => bool) private whitelist;
  uint256 totalWhitelist = 0;
  uint256 whitelistMintMax = 3;
  address payable foundersWallet;
  address payable artistWallet;
  uint256 maxPresaleMint = 4;
  bool apeSaleIsActive = false;
  bool public saleIsActive = false;
  uint256 public mintEthPrice = .09 ether;
  uint256 public mintApePrice = 24;
  address tokenAddress = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;
  uint private artistShare;

  constructor(uint256 initialSupply, uint256 maxTotalMints, address payable artist, address payable founders ) ERC721A("BAZ", "BAZ") {
    maxTokens = initialSupply;
    maxMint = maxTotalMints;
    artistWallet = artist;
    foundersWallet = founders;
  }

  function withdraw() external onlyFounders {
    require(artistShare > 0, "Set artist share");
    require(address(this).balance > 0, "This contract has no balance");

    artistWallet.transfer(address(this).balance.mul(artistShare).div(100));
    foundersWallet.transfer(address(this).balance);

  }

  function getArtistShare() external view onlyFounders returns (uint256) {
    return artistShare;
  }

  function setArtistShare(uint256 intPercentage) external onlyOwner {
    require (artistShare >=0  && artistShare<101, "Value must between 0 and 100");
    artistShare = intPercentage;
  }

  modifier onlyFounders() {
    require(msg.sender == artistWallet || msg.sender == foundersWallet);
    _;
  }

  // overriding startTokenId() to set starting token index to 1
  function _startTokenId() internal view virtual override returns (uint256){
    return 1;
  }

  // reserve 50 tokens to deployer wallet
  function reserveMint() external onlyOwner {      
    require(totalSupply().add(50) <= maxTokens, "Purchase would exceed max supply of tokens");      
    _safeMint(msg.sender, 50);
  }

  function mint(uint256 quantity) public payable {

    require(saleIsActive || whitelist[msg.sender], "You cannot mint at this time"); 

    uint mintLimit;
    if (!saleIsActive) {
      mintLimit = 3;
      require(balanceOf(msg.sender) < whitelistMintMax, "You exceeded your whitelist maximum");
    } else {
      mintLimit = maxTokens;
    }

    require(quantity > 0, "Must mint at least 1 token");
    require(quantity <= mintLimit, "You cannot that amount of tokens");
    require(totalSupply().add(quantity) <= maxTokens, "Purchase would exceed max supply of tokens");
    require(mintEthPrice.mul(quantity) <= msg.value, "Ether value sent is not correct");

    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);
  }

  function apeMint(uint256 quantity) public {
    
    require(saleIsActive || whitelist[msg.sender], "You cannot mint at this time");
    require(apeSaleIsActive, "You cannot use ApeCoin at this time");
    require(quantity > 0, "Must mint at least 1 token");
    require(quantity <= maxMint, "Can only mint 20 tokens at a time");
    require(totalSupply().add(quantity) <= maxTokens, "Purchase would exceed max supply of tokens");

    uint256 mintPrice = quantity.mul(mintApePrice); 

    IERC20 paymentToken = IERC20(tokenAddress);
 
    require(paymentToken.allowance(msg.sender, address(this)) >= quantity.mul(mintApePrice),"Insuficient Allowance");
    require(paymentToken.transferFrom(msg.sender, address(this), mintPrice),"transfer Failed");

    // _safeMint's second argument now takes in a quantity, not a tokenId.
    _safeMint(msg.sender, quantity);    

  }

  function flipApeSaleState() external onlyOwner {
    apeSaleIsActive = !apeSaleIsActive;
  }

  function getApeSaleState() external view onlyOwner returns (bool)  {
    return apeSaleIsActive;
  }

  function flipSaleState() external onlyOwner {    
    saleIsActive = !saleIsActive;
  }

  function getSaleState() public view returns (bool) {
    return saleIsActive;
  }

  function setApePrice(uint256 newPrice) external onlyOwner {
    require(newPrice > 0, 'Must set Price Above 0 $APE');
    mintApePrice = newPrice;
  }

  function getApePrice() public view returns (uint256) {
    return mintApePrice;
  }

  function getTotalApePrice( uint256 quantity ) public view returns (uint256){
    return mintApePrice.mul(quantity);
  }

  function updateWhitelist(address[] calldata _addresses) external onlyOwner {    
    for (uint i=0; i<_addresses.length; i++) {
         whitelist[_addresses[i]] = true;
         totalWhitelist++;
      }
  }

  function getWhitelistSize() external view onlyOwner returns (uint256){
    return totalWhitelist;
  }

  function getWhitelistAddress(address _address) external view onlyOwner returns (bool){
    return whitelist[_address];
  }

  function setWhitelistMintMax(uint256 newMax) external onlyOwner {
    whitelistMintMax = newMax;
  }

}