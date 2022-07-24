//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import './ERC721A.sol';
import './IERC2981Royalties.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './ReentrancyGuard.sol';
import './Address.sol';

contract Hertz is ERC721A, Ownable, IERC2981Royalties,ReentrancyGuard{
  using SafeMath for uint256;
  using Address for address payable;
  bool private whitelistSaleActive;
  bool private publicSaleActive;
  bool private  mintListSaleActive;
  mapping(address=>bool) public whitelistedAddresses;
  mapping(address=>bool) public mintListAddresses;

  mapping(address=>uint256) public whitelistMintedCount;
  mapping(address=>uint256) public mintListMintedCount;

  uint256 public presaleMintTotal;
  uint256 public mintListMintedTotal;
  uint256 public whitelistMintedTotal;

  string private tokenBaseURI;
  string private baseExtension = ".json";

  uint256 constant TOTAL_SUPPLY=8121;
  uint256 constant PRESALE_SUPPLY=4121;
  uint256 constant WHITELIST_SUPPLY=4000;
  uint256 constant MINTLIST_SUPPLY=4000;

  uint256 constant PUBLIC_MINT_LIMIT_PER_ADDR=8121;
  uint256 constant WHITELIST_MINT_LIMIT_PER_ADDR=2;
  uint256 constant MINTLIST_LIMIT_PER_ADDR=3;

  uint256 constant PRESALE_MINT_PRICE=0;
  uint256 constant PUBLIC_MINT_PRICE=0.3 ether;
  uint256 constant WHITELIST_MINT_PRICE=0.22 ether;
  uint256 constant MINTLIST_MINT_PRICE=0.2 ether;

  address payable treasuryWallet;

  constructor() ERC721A("Hertz","HERTZ"){
    treasuryWallet=payable(msg.sender);
    whitelistMintedTotal=0;
    mintListMintedTotal=0;
    presaleMintTotal=0;
  }

  receive() external payable {}

  function royaltyInfo(uint256 _tokenId, uint256 _value)
      external
      view
      returns (address _receiver, uint256 _royaltyAmount){
        if(_tokenId<=TOTAL_SUPPLY){
        return (treasuryWallet,_value.mul(75).div(1000));
        }

      }

  function getTreasuryWallet() public view returns(address){
      return treasuryWallet;
    }

  function setTreasuryWallet(address _wallet) external onlyOwner{
    require(_wallet!=address(0x0));
    treasuryWallet=payable(_wallet);
  }

  function isPublicSaleActive() external view returns (bool){
    return publicSaleActive;
  }

  function isWhitelistSaleActive() external view returns (bool){
    return whitelistSaleActive;
  }

  function isMintListSaleActive() external view returns (bool){
    return mintListSaleActive;
  }

  function getMintListPrice() public pure returns (uint256){
    return MINTLIST_MINT_PRICE;
  }
  function getPresalePrice() public pure returns (uint256){
    return PRESALE_MINT_PRICE;
  }

  function getWhitelistPrice() public pure returns (uint256){
    return WHITELIST_MINT_PRICE;
  }

  function getPublicPrice() public pure returns (uint256){
    return PUBLIC_MINT_PRICE;
  }

  function setPublicSaleActive(bool newStatus) external onlyOwner{
    publicSaleActive=newStatus;
  }

  function setWhitelistSaleActive(bool newStatus) external onlyOwner{
    whitelistSaleActive=newStatus;
  }

  function setMintListSaleActive(bool newStatus) external onlyOwner{
    mintListSaleActive=newStatus;
  }

  function addToWhitelist(address[] memory addresses) external onlyOwner {
    for(uint256 i=0;i<addresses.length;i++){
      whitelistedAddresses[addresses[i]]=true;
    }
  }

  function addToMintList(address[] memory addresses) external onlyOwner {
    for(uint256 i=0;i<addresses.length;i++){
      mintListAddresses[addresses[i]]=true;
    }
  }

  function setBaseExtension(string memory _newBaseExtension) external  onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

  function presaleMint(address recipient,uint256 quantity) external payable onlyOwner nonReentrant{
    require(quantity>0);
    require(msg.value>=PRESALE_MINT_PRICE*quantity);
    require(presaleMintTotal+quantity<=PRESALE_SUPPLY);
    require(_totalMinted()+quantity<=TOTAL_SUPPLY);

    _safeMint(recipient,quantity);
  }

  function publicMint(uint256 quantity) external payable nonReentrant{
    require(publicSaleActive);
    require(quantity>0);
    require(quantity<=PUBLIC_MINT_LIMIT_PER_ADDR);
    require(msg.value>=PUBLIC_MINT_PRICE*quantity);
    require(_totalMinted()+quantity<=TOTAL_SUPPLY);

    _safeMint(msg.sender,quantity);
  }

  function mintListMint(uint256 quantity) external payable nonReentrant{
    require(mintListSaleActive);
    require(quantity>0);
    require(mintListAddresses[msg.sender]);
    require(msg.value>=MINTLIST_MINT_PRICE*quantity);
    require(_totalMinted()+quantity<=TOTAL_SUPPLY);
    require(mintListMintedTotal+quantity<=MINTLIST_SUPPLY);
    require(mintListMintedCount[msg.sender]+quantity<=MINTLIST_LIMIT_PER_ADDR);

    _safeMint(msg.sender,quantity);
    mintListMintedTotal+=quantity;
    mintListMintedCount[msg.sender]=mintListMintedCount[msg.sender]+quantity;
  }

  function whitelistMint(uint256 quantity) external payable nonReentrant{
    require(whitelistSaleActive);
    require(quantity>0);
    require(whitelistedAddresses[msg.sender]);
    require(msg.value>=WHITELIST_MINT_PRICE*quantity);
    require(_totalMinted()+quantity<=TOTAL_SUPPLY);
    require(whitelistMintedTotal+quantity<=WHITELIST_SUPPLY);
    require(whitelistMintedCount[msg.sender]+quantity<=WHITELIST_MINT_LIMIT_PER_ADDR);

    _safeMint(msg.sender,quantity);
    whitelistMintedTotal+=quantity;
    whitelistMintedCount[msg.sender]=whitelistMintedCount[msg.sender]+quantity;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(tokenId<TOTAL_SUPPLY,"ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0? string(abi.encodePacked(currentBaseURI,_toString(tokenId),baseExtension)): "";
    }

  function withdraw() external {
    treasuryWallet.sendValue(address(this).balance);
  }

  function setBaseURI(string memory _base) external onlyOwner{
    tokenBaseURI=_base;
  }

  function _baseURI() internal view override returns (string memory) {
      return tokenBaseURI;
  }
}