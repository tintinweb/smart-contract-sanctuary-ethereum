// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;



import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Delegated.sol";
import "./ERC721A.sol";



contract Seven22 is Delegated, ReentrancyGuard, ERC721A {

  using Strings for uint256;
  uint256 public immutable maxSupply = 7022;
  uint256 public immutable maxPreSaleSupply = 678;
  uint256 public immutable personalCap = 55;

  
  address public immutable treasury = 0xCf11d957D94A7d2988d9f9b875EAFBB1A2D765D1;
  

  uint256 public immutable teamAllocation = 60;

  bool public teamClaimed = false;



  string public baseURI;

  uint256 public currentSupply = 2200;

  bool public isPresaleActive;

  bool public isPublicSaleActive;

  bytes32 public merkleRoot;

  uint256 public publicPrice = 733000000000000000;

  uint256 public whitelistSold;

  

  mapping(address => uint256) public whitelistAccountAmounts;



  event BaseURI(string baseUri);

  event Presale(address indexed user, uint256 qty);



  constructor(bytes32 _merkleRoot)

    Delegated()

    ERC721A("Seven22 HDN FIGRZ", "HDNFIGRZ") {

    merkleRoot = _merkleRoot;

  }



  function setBaseURI(string calldata _baseUri) external onlyOwner {

    baseURI = _baseUri;
    emit BaseURI(_baseUri);

  }



  function _baseURI() internal view override returns (string memory) {

    return baseURI;

  }



  function setMerkleRoot(bytes32 root) external onlyOwner {

    merkleRoot = root;

  } 



  function setPublicPrice(uint256 _publicPrice) external onlyOwner {

    publicPrice = _publicPrice;

  }



  function setSaleConfig( bool presaleState, bool publicState ) external onlyOwner{

    isPresaleActive = presaleState;

    isPublicSaleActive = publicState;

  }



  function setSupply( uint256 newSupply ) external onlyOwner{

    require(newSupply <= maxSupply, "new supply too large");

    currentSupply = newSupply;

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



  /// @notice Allows whitelisted addresses to participate in the presale

  /// @param proof the merkle proof that the given user with the provided allocation is in the merke tree

  /// @param alloc the initial allocation to this whitelisted account

  /// @param amount the amount of NFTs to mint

  function presale(

    bytes32[] memory proof,

    uint256 alloc,

    uint256 amount

  ) external nonReentrant {

    require(isWhitelisted(_msgSender(), proof, alloc), "not whitelisted");

    require(

      whitelistAccountAmounts[_msgSender()] + amount <= alloc,

      "all NFTs purchased"

    );

    require(isPresaleActive, "presale not started");

    require(whitelistSold + amount <= maxPreSaleSupply, "max presale supply");



    whitelistSold += amount;

    whitelistAccountAmounts[_msgSender()] += amount;



    _safeMint(_msgSender(), amount);

    emit Presale(_msgSender(), amount);

  }





  /// @notice Mints the given quantity of tokens. Anyone can call it as long the

  /// total price is paid

  /// @param qty number of tokens to mint

  function mint(uint256 qty) external payable nonReentrant {

    require(isPublicSaleActive, "public sale not started yet");

    require(_numberMinted(_msgSender()) + qty <= personalCap, "too many mints");

    require(totalSupply() + qty <= currentSupply, "max supply");

    require(msg.value == qty * publicPrice, "wrong amount");



    _safeMint(_msgSender(), qty);

  }



  function withdraw() external onlyOwner {

    (bool hs, ) = payable(0xa33a70FABFeb361Fe891C208B1c27ec0b64baBEB).call{value: address(this).balance *10 / 100}("");
    require(hs, "Transfer failed");

    (bool success, ) = payable(treasury).call{value: address(this).balance}("");
    require(success, "transfer failed");

  }



  function airdrop(uint256[] calldata qty, address[] calldata recipients) external payable onlyDelegates{

    require(qty.length == recipients.length, "arguments must have equal counts");



    uint256 total = 0;

    for( uint256 i = 0; i < qty.length; ++i ){

      total += qty[i];

    }

    require(totalSupply() + total <= currentSupply, "max supply");



    for( uint256 i = 0; i < qty.length; ++i ){

      _safeMint(recipients[i], qty[i]);

    }

  }



  function airdropTeam() external onlyDelegates{

    require( !teamClaimed, "already claimed" );



    teamClaimed = true;

    _safeMint(treasury, teamAllocation);

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