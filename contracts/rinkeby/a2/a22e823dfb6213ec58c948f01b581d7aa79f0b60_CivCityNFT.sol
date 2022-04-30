// SPDX-License-Identifier: MIT

/*
          _____                    _____                _____                _____          
         /\    \                  /\    \              /\    \              |\    \         
        /::\    \                /::\    \            /::\    \             |:\____\        
       /::::\    \               \:::\    \           \:::\    \            |::|   |        
      /::::::\    \               \:::\    \           \:::\    \           |::|   |        
     /:::/\:::\    \               \:::\    \           \:::\    \          |::|   |        
    /:::/  \:::\    \               \:::\    \           \:::\    \         |::|   |        
   /:::/    \:::\    \              /::::\    \          /::::\    \        |::|   |        
  /:::/    / \:::\    \    ____    /::::::\    \        /::::::\    \       |::|___|______  
 /:::/    /   \:::\    \  /\   \  /:::/\:::\    \      /:::/\:::\    \      /::::::::\    \ 
/:::/____/     \:::\____\/::\   \/:::/  \:::\____\    /:::/  \:::\____\    /::::::::::\____\
\:::\    \      \::/    /\:::\  /:::/    \::/    /   /:::/    \::/    /   /:::/~~~~/~~      
 \:::\    \      \/____/  \:::\/:::/    / \/____/   /:::/    / \/____/   /:::/    /         
  \:::\    \               \::::::/    /           /:::/    /           /:::/    /          
   \:::\    \               \::::/____/           /:::/    /           /:::/    /           
    \:::\    \               \:::\    \           \::/    /            \::/    /            
     \:::\    \               \:::\    \           \/____/              \/____/             
      \:::\    \               \:::\    \                                                   
       \:::\____\               \:::\____\                                                  
        \::/    /                \::/    /                                                  
         \/____/                  \/____/                                                   
                                                                                            
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";
import "./ICityToken.sol";


contract CivCityNFT is Ownable, ERC721A, PaymentSplitter {
  enum Step {
      Before,
      WhitelistSale,
      PublicSale,
      Revealed
  }

  Step public sellingStep;

  uint256 private constant MAX_SUPPLY = 7777;
  uint256 private constant MAX_WHITELIST = 2777;
  uint256 private constant MAX_PUBLIC = 4900;
  uint256 private constant MAX_GIFT = 100;

  uint256 public wlSalePrice = 0.0025 ether;
  uint256 public publicSalePrice = 0.003 ether;
  uint256 private teamLength;

  bytes32 public merkleRoot;

  ICityToken city;

  mapping(address => uint) public amountNFTsperWalletWhitelistSale;

  modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
  }

  modifier tokenExist(uint256 tokenId) {
      require(_exists(tokenId), "Nonexistent token");
      _;
  }
  
  modifier ownerOfToken(uint256 tokenId) {
      require(ownerOf(tokenId)== msg.sender, "Only Owner");
      _;
  }
  constructor(address _city, address[] memory _team, uint[] memory _teamShares, bytes32 _merkleRoot) ERC721A("Civilization.Cities.NFT", "CC") 
  PaymentSplitter(_team, _teamShares) {

    city= ICityToken(_city);
    merkleRoot = _merkleRoot;
    teamLength = _team.length;
  }

  function whitelistMint(address _account, 
      bytes32[] calldata _proof,
      string[] calldata _names, 
      int _zoneDiff, 
      uint8[] calldata _translate) external payable callerIsUser {

      require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
      require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
      require(amountNFTsperWalletWhitelistSale[msg.sender] == 0, "You can only get 1 NFT on the Whitelist Sale");
      require(totalSupply() < MAX_WHITELIST, "Max supply exceeded");
      require(msg.value >= wlSalePrice, "Not enought funds");
      amountNFTsperWalletWhitelistSale[msg.sender] += 1;

      _safeMint(_account, _names, _zoneDiff, _translate);
  }

  function publicSaleMint(address _account,
      string[] calldata _names, 
      int _zoneDiff, 
      uint8[] calldata _translate) external payable callerIsUser {

      require(sellingStep == Step.PublicSale, "Public sale is not activated");
      require(totalSupply() < MAX_WHITELIST + MAX_PUBLIC, "Max supply exceeded");
      require(msg.value >= publicSalePrice, "Not enought funds");

      _safeMint(_account, _names, _zoneDiff, _translate);
  }

  function gift(address _account,
      string[] calldata _names, 
      int _zoneDiff, 
      uint8[] calldata _translate) external onlyOwner {
      require(sellingStep > Step.PublicSale, "Gift is after the public sale");
      require(totalSupply() < MAX_SUPPLY, "Reached max Supply");

      _safeMint(_account, _names, _zoneDiff, _translate);
  }

  function _safeMint(address to,string[] calldata _names, int _zoneDiff, uint8[] calldata _translate) internal {
      city.mint(_names, _zoneDiff, _translate);
      _safeMint(to, 1, '');
  }

  function currentTime() internal view returns(uint) {
      return block.timestamp;
  }

  function setStep(uint _step) external onlyOwner {
      sellingStep = Step(_step);
  }

  //Whitelist
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
      merkleRoot = _merkleRoot;
  }

  function setIPFSPrefix(string memory _prefix) external onlyOwner{
      city.setIPFSPrefix(_prefix);
  }

  function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
      return _verify(leaf(_account), _proof);
  }

  function leaf(address _account) internal pure returns(bytes32) {
      return keccak256(abi.encodePacked(_account));
  }

  function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
      return MerkleProof.verify(_proof, merkleRoot, _leaf);
  }

  //ReleaseALL
  function releaseAll() external onlyOwner{
      for(uint i = 0 ; i < teamLength ; i++) {
          release(payable(payee(i)));
      }
  }

  receive() override external payable {
      revert('Only if you mint');
  }

  function tokenURI(uint256 tokenId) public view virtual override 
    tokenExist(tokenId) returns (string memory){
    return city.tokenURI(tokenId, sellingStep == Step.Revealed);
  }

  function showAnimation(uint256 tokenId, bool _show) external tokenExist(tokenId) {
      require(ownerOf(tokenId)== msg.sender, "You are not onwer of this NFT");
      city.showAnimation(tokenId, _show);
  }

  function setFont(uint256 tokenId, string calldata _font) external 
    tokenExist(tokenId) ownerOfToken(tokenId){
      city.setFont(tokenId, _font);
  }
  
  function getFont(uint256 tokenId) view external tokenExist(tokenId) {
      city.getFont(tokenId);
  }
  function setMainLang(uint256 tokenId, string calldata _lang) external 
    tokenExist(tokenId) ownerOfToken(tokenId){
    city.setMainLang(tokenId, _lang);
  }

  function getMainLang(uint256 tokenId) view external tokenExist(tokenId) returns(string memory){
    return city.getMainLang(tokenId);
  }
}

// Generated by /Users/iwan/work/brownie-test/NFTCity/scripts/flatten.py