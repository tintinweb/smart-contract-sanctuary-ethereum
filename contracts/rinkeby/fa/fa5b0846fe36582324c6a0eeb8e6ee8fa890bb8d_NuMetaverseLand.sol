// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // <-- version directive

import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NuMetaverseLand is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _tokenIds;

  // these are all optional params we might create for our characters
  uint256 salePrice  = 0.69 ether; // <-- any fees we want to change on txs
  uint256 public constant maxSupply = 20000; // <-- max supply of tokens
  string public notRevealedUri = "https://ipfs.moralis.io:2053/ipfs/Qmd8GLFmqW4yM7zp9CV38AmVW4ntQUuqPh9S6QK89gQhkM";
  bool public paused = false; // <-- stop interaction witb contract
  bool public revealed = true; // <-- is the collection revealled yet?
  address payable public contractOwner;
  
  constructor() ERC721("Nu", "Metaverse") {
    contractOwner = payable(msg.sender);
  }

  struct Land {
    uint256 tokenId;
    string  LandName;
    string  tokenURI;
    uint256 price;
    address defaultOwner;
    address currentOwner;
    bool    saleStatus;
  }
  Land[maxSupply] public _tokenDetails;
  event NewParcel(address indexed owner, uint256 id);
  event Purchase(address indexed previousOwner, address indexed newOwner, uint nftprice, uint nftId , string nftUri);
  
  /** func to get token details
   *  - token by id
   *  - returns array
   */
  function getTokenDetails(uint256 _id) public view returns (Land memory) {
    return _tokenDetails[_id];
  }
  /** func to get the Sale price
  * 
  *    - returns sale price
  */
  function getParcelPrice() public view returns(uint256){
    return salePrice;
  }
  /** func to get total supply
   *
   */
  function getTokenCirculations() public view returns (uint256) {
    return _tokenIds.current();
  }

  /** func to link token to metadata
   *
   */
  function tokenURI(uint256 _id)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_id), "ERC721Metadata: URI query for nonexistent token");
    if (revealed == true) {
      return _tokenDetails[_id].tokenURI;
    } else {
      return notRevealedUri;
    }
  }

  /**
   * func to mint/create token
   *  - amount to be minted/created
   *  - set link to token's metadata
   *  - emits array of new token's details
   */
  function mintParcel(string memory _tokenURI,string memory _landName)
    public
    payable
  {
    require(!paused, "The contract is paused.");
    require(_tokenIds.current() + 1 <= maxSupply,"Max supply exceeded.");
    require(msg.value >= salePrice, "Insufficient funds.");    

    _tokenIds.increment();
    uint256 newParcelID = _tokenIds.current();
    _safeMint(msg.sender, newParcelID);
    _setTokenURI(newParcelID, _tokenURI);
    // id,  level, evac, landName,tokenURI
    Land memory newLand = Land(
      newParcelID,
      _landName,
      _tokenURI,
      msg.value,
      msg.sender,
      msg.sender,
      false
    );
    _tokenDetails[newParcelID] = newLand;
    
    emit NewParcel(msg.sender, newParcelID);

  }
  
  //Buy Parcel
  function buy(uint tokenId) external payable {
    require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
    require(_tokenDetails[tokenId].saleStatus, "Item not listed currently");
    require(msg.value >= _tokenDetails[tokenId].price, "Error, the amount is lower");
    require(msg.sender != ownerOf(tokenId), "Can not buy what you own");

    address previousOwner = ownerOf(tokenId);
    address newOwner = msg.sender;
    trade(tokenId);
    emit Purchase(previousOwner, newOwner, _tokenDetails[tokenId].price, tokenId , _tokenDetails[tokenId].tokenURI);
  }

  function trade(uint tokenId) internal {
    address payable buyer = payable(msg.sender);
    address payable nftOwner = payable(ownerOf(tokenId));
    _transfer(nftOwner, buyer, tokenId);
    _tokenDetails[tokenId].currentOwner = msg.sender;
    uint256 commissionValue = _tokenDetails[tokenId].price * 2 / 100;
    uint256 sellerValue = _tokenDetails[tokenId].price - commissionValue;
    nftOwner.transfer(sellerValue);
    contractOwner.transfer(commissionValue);
    // If buyer sent more than price, we send them back their rest of funds
    if (msg.value > _tokenDetails[tokenId].price) {
        buyer.transfer(msg.value - _tokenDetails[tokenId].price);
    }
  }

  function updateParcelURI(uint256 _id, string memory _uri) public {
    require(_exists(_id), "ERC721URIStorage: URI set of nonexistent token");
    require(ownerOf(_id) == msg.sender || contractOwner == msg.sender);
    _tokenDetails[_id].tokenURI = _uri;
    _setTokenURI(_id, _uri);
  }

  function updateParcelPrice(uint256 _id, uint256 price) public {
    require(_exists(_id), "ERC721URIStorage: URI set of nonexistent token");
    require(ownerOf(_id) == msg.sender || contractOwner == msg.sender);
    _tokenDetails[_id].price = price;
  }

  function updateParcelSaleStatus(uint256 _id, bool status) public {
    require(_exists(_id), "ERC721URIStorage: URI set of nonexistent token");
    require(ownerOf(_id) == msg.sender || contractOwner == msg.sender);
    _tokenDetails[_id].saleStatus = status;
  }

  function pauseContract(bool flag) public onlyOwner {
    paused = flag;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function updateParcelPrice(uint256 price) external onlyOwner {
    salePrice = price;
  }

  function withdraw() external payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
  

}