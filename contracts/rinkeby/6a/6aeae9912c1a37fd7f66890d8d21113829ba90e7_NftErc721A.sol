// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";

contract NftErc721A is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;


  uint256 public MAX_PER_Transtion_DURING_Mint = 10; // maximam amount that user can mint
  uint256 public MAX_PER_Address_DURING_Mint_Presale = 5; // maximam amount that user can mint

  uint256 public  PUBLIC_SALE_PRICE = 25*10**15; //0.025 ether 
  uint256 public  PRESALE_PRICE = 25*10**15; //0.025 ether

  uint256 private constant TotalCollectionSize_ = 10000; // total number of nfts
  uint256 private constant MaxMintPerBatch_ = 20; //max mint per traction

  bool public _revelNFT = false;
  string private _baseTokenURI;
  string private _uriBeforeRevel;
  string private _URIExtension = ".json";

  bool public isPublicSale = false;
  bool public isPresale = false;

  address[] private whitelistedAddresses;

  constructor(string memory _baseUri, string memory _baseUriBefore) ERC721A("Cash Crabs","CashCrabs", MaxMintPerBatch_, TotalCollectionSize_) {
      _baseTokenURI = _baseUri;
      // ipfs://CID/
      _uriBeforeRevel = _baseUriBefore;
      // ipfs://CID/file.json
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
 
  function mint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    require(isPublicSale, "Public Sale is not Active");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(  quantity <= MAX_PER_Transtion_DURING_Mint,"can not mint this many");
    require(msg.value >= PUBLIC_SALE_PRICE * quantity, "Need to send more ETH.");
    _safeMint(msg.sender, quantity);
  }

  function mintPreSale(uint256 quantity)
    external
    payable
    callerIsUser
  {
    require(isPresale, "Presale is not Active");
    require(isWhitelisted(msg.sender), "You are not Whitelisted");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require( numberMinted(msg.sender) + quantity <= MAX_PER_Address_DURING_Mint_Presale,"can not mint this many");
    require(msg.value >= PRESALE_PRICE * quantity, "Need to send more ETH.");
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity,address _to)
    external
    payable
    callerIsUser
  {
    require(isPublicSale, "Public Sale is not Active");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require( quantity <= MAX_PER_Transtion_DURING_Mint,"can not mint this many");
    require(msg.value >= PUBLIC_SALE_PRICE * quantity, "Need to send more ETH.");
    _safeMint(_to, quantity);
  }

  function devMint(address _to,uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= collectionSize,
      "too many already minted before dev mint"
    );

    _safeMint(_to, quantity);
  }

  // // metadata URI

   function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    if(_revelNFT){
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(),_URIExtension))
        : "";
    } else{
      return _uriBeforeRevel;
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  
  function addNewWhitelistUsers(address[] calldata _users) public onlyOwner {
    // ["","",""]
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function setURIbeforeRevel(string memory URI) external onlyOwner {
    _uriBeforeRevel = URI;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setBaseURIExtension(string memory _baseURIEx) external onlyOwner {
    _URIExtension = _baseURIEx;
  }

  function _getUriExtension() internal view virtual override returns (string memory) {
    return _URIExtension;
  }

   function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }


  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }


    function FlipPublicSale() external onlyOwner
    {
        isPublicSale = !isPublicSale;
    }

    function FlipPresale() external onlyOwner
    {
        isPresale = !isPresale;
    }

    function changeRevelStatus() external onlyOwner {
      _revelNFT = !_revelNFT;
    }

    function changeMintPrice(uint256 _newPrice) external onlyOwner
    {
        PUBLIC_SALE_PRICE = _newPrice;
    }

    function changeMintPriceForPresale(uint256 _newPrice) external onlyOwner
    {
        PRESALE_PRICE = _newPrice;
    }

    function changeMAX_PER_Transtion_DURING_Mint(uint256 _newPrice) external onlyOwner
    {
        MAX_PER_Transtion_DURING_Mint = _newPrice;
    }
    function changeMAX_PER_Address_DURING_Mint_Presale(uint256 _newPrice) external onlyOwner
    {
        MAX_PER_Address_DURING_Mint_Presale = _newPrice;
    }

}