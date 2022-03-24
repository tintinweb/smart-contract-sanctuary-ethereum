// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "ERC721Enumerable.sol";
import "Ownable.sol";
import "MerkleProof.sol";



contract NFT_BABA is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";

  uint256 public whitelistCost = 0.05 ether;
  uint256 public cost = 0.1 ether;

  uint256 public maxSupply = 7785;
  uint256 public maxMintAmount = 100;
  uint256 public nftPerAddressLimit = 3;

  uint256 public whitelistStartDate;
  uint256 public whitelistEndDate;


  bool public paused = false;
  bool public revealed = false;

  bytes32 public whitelistSigner; 

  mapping(address => bool) whitelistClaimed;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");   
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");

        
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }


  function whitelistMint(bytes32[] calldata  _proof) payable public{

   require(whitelistStartDate <= block.timestamp, "Whitelist Session Not Started yet");
   require(whitelistEndDate >= block.timestamp, "Whitelist Session Has Ended"); 
   
   require(!whitelistClaimed[msg.sender], "Already Claimed");
   require(msg.value >= whitelistCost, "insufficient funds");

   uint256 supply = totalSupply();

   bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
   require(MerkleProof.verify(_proof,leaf,whitelistSigner),"Invalid Proof");

    whitelistClaimed[msg.sender] = true;

     
     //   addressMintedBalance[msg.sender]++; // Can be uncommented if maxperAddress is exempting the Whitelist
      _safeMint(msg.sender, supply + 1);
    
  


  }


  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

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
    
   

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner

  function setWhitelistSigner(bytes32 newWhitelistSigner) external onlyOwner {
   whitelistSigner = newWhitelistSigner;
  }

   
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setWhitelistDates(uint256 _start, uint256 _end) public onlyOwner {
    whitelistStartDate = _start;      
    whitelistEndDate = _end;

  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
 
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  
  function withdraw() public payable onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);

  }
}