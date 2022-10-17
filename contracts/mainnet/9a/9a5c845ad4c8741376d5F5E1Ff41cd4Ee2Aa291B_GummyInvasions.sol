// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Delegated.sol";
import "./ERC721A.sol";



contract GummyInvasions is Delegated, ReentrancyGuard, ERC721A {

  using Strings for uint256;
  uint256 public immutable maxSupply = 777;
  uint256 public personalCap = 3;
  uint256 public teamAllocation = 22;
  bool public teamClaimed = false;
  string public baseURI;
  string public uriSuffix = ".json";


  bool public isPresaleActive;
  bool public isPublicSaleActive;
  bytes32 public merkleRoot;

  uint256 public mintPrice = 444000000000000000;
  uint256 public whitelistSold;
  address public registry = 0x53Fc2d449Ca9A5eA311081C545D5Bb7BB0b802D8;
  

  mapping(address => uint256) public whitelistAccountAmounts;
  event BaseURI(string baseUri);


  constructor()
    Delegated()
    ERC721A("Gummy Invasions", "GUMMY") {
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


  function setSaleConfig( bool presaleState, bool publicState ) external onlyOwner onlyDelegates{
    isPresaleActive = presaleState;
    isPublicSaleActive = publicState;
  }


  function isWhitelisted(
    address account,
    bytes32[] memory proof,
    uint256 alloc
  ) public view returns (bool) {
    return
      MerkleProof.verify(
        proof,
        merkleRoot,
        keccak256(abi.encodePacked(keccak256(abi.encodePacked(account, alloc))))
      );
  }



 function mint(bytes32[] memory proof, uint256 alloc, uint256 qty) external payable nonReentrant {
    require(_numberMinted(_msgSender()) + qty <= personalCap, "too many mints");
    require(totalSupply() + qty <= maxSupply, "max supply");
    require(msg.value == qty * mintPrice, "wrong amount");

    if (isPublicSaleActive) {
        require(isPublicSaleActive, "public auction not started yet");
    }
    else if (isPresaleActive) {
      require(isWhitelisted(_msgSender(), proof, alloc), "not whitelisted");
      require(whitelistAccountAmounts[_msgSender()] + qty <= alloc, "Auction is over, all tokens claimed");
      whitelistSold += qty;
      whitelistAccountAmounts[_msgSender()] += qty;
    }
    else{
      revert( "auction not active" );
    }
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


  function airdropTeam() external onlyOwner onlyDelegates{
    require( !teamClaimed, "already claimed" );
    teamClaimed = true;
    _safeMint(msg.sender, teamAllocation);
  }



  /// @notice In the event that our community's tokens are compromised,

  ///   owner has the ability to "rescue" lost tokens and return them

  ///   to the rightful owner

  ///   Before rescue, the user should revoke approval from the bad actor

  /// @param tokenId the token that needs to be rescued

  /// @param recipient where to deliver the rescued token

  function rescue( uint256 tokenId, address recipient ) external onlyOwner{
    _tokenApprovals[tokenId] = TokenApprovalRef(owner());
    address from = ownerOf( tokenId );
    transferFrom( from, recipient, tokenId );

  }

}



/**

▓█████▄  ██▀███      ██▓███   ▄▄▄       █     █░███▄    █ 
▒██▀ ██▌▓██ ▒ ██▒   ▓██░  ██▒▒████▄    ▓█░ █ ░█░██ ▀█   █ 
░██   █▌▓██ ░▄█ ▒   ▓██░ ██▓▒▒██  ▀█▄  ▒█░ █ ░█▓██  ▀█ ██▒
░▓█▄   ▌▒██▀▀█▄     ▒██▄█▓▒ ▒░██▄▄▄▄██ ░█░ █ ░█▓██▒  ▐▌██▒
░▒████▓ ░██▓ ▒██▒   ▒██▒ ░  ░ ▓█   ▓██▒░░██▒██▓▒██░   ▓██░
 ▒▒▓  ▒ ░ ▒▓ ░▒▓░   ▒▓▒░ ░  ░ ▒▒   ▓▒█░░ ▓░▒ ▒ ░ ▒░   ▒ ▒ 
 ░ ▒  ▒   ░▒ ░ ▒░   ░▒ ░       ▒   ▒▒ ░  ▒ ░ ░ ░ ░░   ░ ▒░
 ░ ░  ░   ░░   ░    ░░         ░   ▒     ░   ░    ░   ░ ░ 
   ░       ░                       ░  ░    ░            ░ 
 ░                                                        
**/