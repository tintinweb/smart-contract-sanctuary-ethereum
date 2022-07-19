// SPDX-License-Identifier: GPL v3.0
// developed by Dinozaver959#2328 (discord), @citizen1525 (twitter)
// Inspired by Azuki Project

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract ManaManiacsNFT is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable MAX_SUPPLY=1000;
  uint256 public immutable MAX_PER_ADDRESS_DURING_MINT=10;
  uint256 public immutable AMOUNT_FOR_DEVS=50;
  uint256 public immutable MINT_PRICE=0.05 ether;

  // sale active flags (default = false)
  bool public SaleActive;

  // CONSTRUCTOR
  constructor() ERC721A("ManaManiacsNFT", "MM", 10, 1000){}    // 3rd argument adjust based on the max number of tokens allowed to mint (take in account multipliers), but 10 is not a bad number

  // MODIFIERS
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier onlyTeam() {
    require(
      _msgSender() == owner() || _msgSender() == 0x1591C783EfB2Bf91b348B6b31F2B04De1442836c || _msgSender() == 0x53226060E28F38e62CB7023A7Add4a1e06a51C58 ,  //... add more addresses that will get royalties (fail-safe so that anyone on the team can initiate the withdrawal)
      "Ownable: caller is not part of the team"
    );
    _;
  }


  // PUBLIC MINT FUNCTIONS
  function Mint(uint256 numTokens) external payable callerIsUser {
    require(msg.value >= MINT_PRICE * numTokens,"not enough Ether sent");
    require(SaleActive, "public sale is not active");
    require(totalSupply() + numTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(numTokens <= MAX_PER_ADDRESS_DURING_MINT,"can not mint this many");
    _safeMint(msg.sender, numTokens);
  }

  // DEV MINT FUNCTIONS - For marketing etc.
  function devMint(uint256 numTokens) external onlyOwner {
    require(totalSupply() + numTokens <= AMOUNT_FOR_DEVS,"can not mint this many");

    uint256 numChunks = numTokens / MAX_PER_ADDRESS_DURING_MINT;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, MAX_PER_ADDRESS_DURING_MINT);
    }

    uint256 left = numTokens % MAX_PER_ADDRESS_DURING_MINT;
    if(left > 0){
      _safeMint(msg.sender, left);
    }
  }



  // metadata URI
  string private _baseTokenURI = "https://easylaunchnftdospace1.fra1.digitaloceanspaces.com/ManaManiacs_json/";          // update this,  added paths are:  'rare' and 'common' -> just manually upload them to the IPFS

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }  
  
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
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



  // ONLY OWNER
  function setSaleActive(bool _SaleActive) public onlyOwner {
    SaleActive = _SaleActive;
  }

  function withdraw() external onlyTeam nonReentrant {

    address user1=0x21F173672edE7B5192f0cCa428403422E9f3dB59;
    uint256 user1_ROYALTY=50;
    address user2=0x53226060E28F38e62CB7023A7Add4a1e06a51C58;
    uint256 user2_ROYALTY=30;
    address user3=0x2e4C1FC1f91d5d7b7E4980fF9144f5a1413e908E;
    uint256 user3_ROYALTY=20;


    uint256 balanceUnits = address(this).balance / 100;

    Address.sendValue(
      payable(user1),
      user1_ROYALTY * balanceUnits
    );

    Address.sendValue(
      payable(user2),
      user2_ROYALTY * balanceUnits
    );

    Address.sendValue(
      payable(user3),
      user3_ROYALTY * balanceUnits
    );

  }

}