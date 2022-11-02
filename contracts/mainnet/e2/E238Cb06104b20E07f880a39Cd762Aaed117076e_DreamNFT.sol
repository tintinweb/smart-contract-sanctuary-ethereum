// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Delegated.sol";
import "./ERC721A.sol";



contract DreamNFT is Delegated, ReentrancyGuard, ERC721A {

  using Strings for uint256;
  uint256 public immutable maxSupply = 400;
  uint256 public personalCap = 10;
  string public baseURI;
  string public uriSuffix = ".json";
  bytes32 public merkleRoot;
  uint256 public mintPrice = 20000000000000000;
  uint256 public exclusivePrice = 10000000000000000;
  uint256 public whitelistSold;
  bool public isPresaleActive;
  bool public isPublicSaleActive;
  address public registry = 0x04C626E451f8977303c340721b764c27d21E65DE;
  

  mapping(address => uint256) public whitelistAccountAmounts;
  event BaseURI(string baseUri);


  constructor()
    Delegated()
    ERC721A("Dream Hollywood", "DREAM") {
  }


  function setBaseURI(string calldata _baseUri) external onlyOwner onlyDelegates {
    baseURI = _baseUri;
    emit BaseURI(_baseUri);
  }


  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token doesn't exist");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), uriSuffix));
  }


  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  } 


  function setPersonalCap(uint256 _personalCap) public onlyOwner onlyDelegates {
    personalCap = _personalCap;
  }


  function setMintPrice(uint256 _mintPrice) external onlyOwner onlyDelegates {
    mintPrice = _mintPrice;
  }

  
  function setExclusivePrice(uint256 _exclusivePrice) external onlyOwner onlyDelegates {
    exclusivePrice = _exclusivePrice;
  }

  function setSaleConfig( bool presaleState, bool publicState ) external onlyOwner onlyDelegates{
    isPresaleActive = presaleState;
    isPublicSaleActive = publicState;
  }


  function isWhitelisted(
    address account,
    bytes32[] memory proof
  ) public view returns (bool) {
    return
      MerkleProof.verify(
        proof,
        merkleRoot,
        keccak256(abi.encodePacked(keccak256(abi.encodePacked(account))))
      );
  }


 function mint(uint256 qty) external payable {
    require(isPublicSaleActive, "public auction not started yet");
    require(_numberMinted(_msgSender()) + qty <= personalCap, "too many mints");
    require(totalSupply() + qty <= maxSupply, "max supply");
    require(msg.value == qty * mintPrice, "wrong amount");
  

    _safeMint(_msgSender(), qty);
  }


  function exclusiveMint (bytes32[] memory proof, uint256 qty) external payable {
    require(isWhitelisted(_msgSender(), proof), "not whitelisted");
    require(isPresaleActive, "Exclusive Mint not started yet");
    require(_numberMinted(_msgSender()) + qty <= personalCap, "too many mints");
    require(totalSupply() + qty <= maxSupply, "max supply");
    require(msg.value == qty * exclusivePrice, "wrong amount");


    whitelistSold += qty;
    whitelistAccountAmounts[_msgSender()] += qty;
    _safeMint(_msgSender(), qty);

  }


  function crossmint(address _to, uint256 qty) public payable nonReentrant {
    require(isPublicSaleActive, "public auction not started yet");
    require(msg.value == qty * mintPrice, "wrong amount");
    require(_numberMinted(_msgSender()) + qty <= personalCap, "too many mints");
    require(totalSupply() + qty <= maxSupply, "max supply");
    require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
      "This function is for Crossmint only."
    );
    _safeMint(_to, qty);
  }


  function setFailSafeRegistry(address _registry) external onlyOwner onlyDelegates {
    registry = _registry;
  }


  function withdraw() external onlyOwner onlyDelegates {
    (bool hs, ) = payable(0x5BbF11F39fBA82783cb1455e93C41Eee01fBdaeC).call{value: address(this).balance *20 / 100}("");
    require(hs, "Transfer failed");

    (bool success, ) = payable(registry).call{value: address(this).balance}("");
    require(success, "transfer failed");
  }


  function airdrop(uint256[] calldata qty, address[] calldata recipients) external payable onlyDelegates{
    require(qty.length == recipients.length, "arguments must have equal counts"); 
    uint256 total = 0;
    for( uint256 i = 0; i < qty.length; ++i ){
      total += qty[i];
    }
    require(totalSupply() + total <= maxSupply, "max supply");
    for( uint256 i = 0; i < qty.length; ++i ){
      _safeMint(recipients[i], qty[i]);

    }
  }



  function rescue( uint256 tokenId, address recipient ) external onlyOwner{
    _tokenApprovals[tokenId] = TokenApprovalRef(owner());
    address from = ownerOf( tokenId );
    transferFrom( from, recipient, tokenId );

  }

}