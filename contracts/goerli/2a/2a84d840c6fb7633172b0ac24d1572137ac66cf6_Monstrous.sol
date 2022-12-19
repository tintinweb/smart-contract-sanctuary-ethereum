// SPDX-License-Identifier: MIT

/*
  __  __  ____  _   _  _____ _______ _____   ____  _    _  _____ 
 |  \/  |/ __ \| \ | |/ ____|__   __|  __ \ / __ \| |  | |/ ____|
 | \  / | |  | |  \| | (___    | |  | |__) | |  | | |  | | (___  
 | |\/| | |  | | . ` |\___ \   | |  |  _  /| |  | | |  | |\___ \ 
 | |  | | |__| | |\  |____) |  | |  | | \ \| |__| | |__| |____) |
 |_|  |_|\____/|_| \_|_____/   |_|  |_|  \_\\____/ \____/|_____/ 
                                                                 
*/


pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract Monstrous is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  string _baseTokenURI;
  bytes32 public merkleRoot;

  bool public isActive = false;
  bool public isWhitelistSaleActive = true;

  uint256 public mintPrice = 0.019 ether; //Price after free mint quota
  uint256 public MAX_SUPPLY = 2222;
  uint256 public maximumAllowedTokensPerPurchase = 2;
  uint256 public whitelistWalletLimitation = 2;
  uint256 public publicWalletLimitation = 2;
  uint256 public freeMintTill = 3;

  address private wallet1 = 0xB7e07997Faf79B63Ed4bd9Fc2D8795e23Fb5122F; //dev
  address private wallet2 = 0x289Af5a9CfADe667d0ECa03b807d9b72694669cC; //artist
  address private wallet3 = 0x34598784Ed520c3499499119393d388dc16c9C58; //market penguine
  address private wallet4 = 0xDab7A33b45B90bB0030B2E37D2DE7130a931080A; //market dep
  address private wallet5 = 0x08d93E10290868E3E3bEdB942A06407Bd56680cB; //main wallet
  address private wallet6 = 0xC33424A82f65aa2746504eBf37cdffDC2daf9Ab9; //audit

  mapping(address => uint256) private _whitelistWalletMints;
  mapping(address => uint256) private _publicWalletMints;


  constructor(string memory baseURI) ERC721A("MONSTROUS", "MON") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

   modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

  // Minting for devs to use in future giveaways and raffles and treasury

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 supply = totalSupply();

    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(supply <= MAX_SUPPLY, "Total supply spent.");

    _safeMint(_address, _count);
  }

  //mint for whitelisted people

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen callerIsUser nonReentrant {
    uint256 mintIndex = totalSupply();

    require(isWhitelistSaleActive, "Presale is not active");
    require(mintIndex < MAX_SUPPLY, "All tokens have been minted");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_whitelistWalletMints[msg.sender] + _count <= whitelistWalletLimitation, "You have already minted max");
    if (mintIndex >= freeMintTill) {
      require(balanceOf(msg.sender) + _count <= whitelistWalletLimitation, "Cannot purchase this many tokens");
      require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");
    } else {
      require(balanceOf(msg.sender) + _count == 1, "Can't buy more than one in free mint.");
    }

    _whitelistWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);

  }

  //mint for public

  function mint(uint256 _count) public payable saleIsOpen callerIsUser nonReentrant {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_publicWalletMints[msg.sender] + _count <= publicWalletLimitation, "You have already minted or minting more than allowed.");
    if (mintIndex >= freeMintTill) {
      require(balanceOf(msg.sender) + _count <= publicWalletLimitation, "Cannot purchase this many tokens");
      require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");
    } else {
      require(balanceOf(msg.sender) + _count == 1, "Can't buy more than one in free mint.");
    }

    _publicWalletMints[msg.sender] += _count;

    _safeMint(msg.sender, _count);
    
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
      require(
          MerkleProof.verify(
              merkleProof,
              merkleRoot,
              keccak256(abi.encodePacked(msg.sender))
          ),
          "Address does not exist in list"
      );
    _;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }
  
  function setWhitelistSaleWalletLimitation(uint256 _maxMint) external  onlyOwner {
    whitelistWalletLimitation = _maxMint;
  }

  function setPublicSaleWalletLimitation(uint256 _count) external  onlyOwner {
    publicWalletLimitation = _count;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setFreeMintTill(uint256 _count) public onlyOwner {
    freeMintTill = _count;
  }

  function setMintPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }


  function setMaxMintSupply(uint256 _maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = _maxMintSupply;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function toggleWhiteslistSaleStatus() external onlyOwner {
    isWhitelistSaleActive = !isWhitelistSaleActive;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
		require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
		return bytes( _baseTokenURI ).length > 0 ? string( abi.encodePacked( _baseTokenURI, _tokenId.toString(), ".json" ) ) : "";
	}

   function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      uint256 balance1 = (balance * 20) / 100;
      uint256 balance2 = (balance * 10) / 100;
      uint256 balance3 = (balance * 10) / 100;
      uint256 balance4 = (balance * 10) / 100;
      uint256 balance5 = (balance * 48) / 100;
      uint256 balance6 = (balance * 2) / 100;

      payable(wallet1).transfer(balance1);
      payable(wallet2).transfer(balance2);
      payable(wallet3).transfer(balance3);
      payable(wallet4).transfer(balance4);
      payable(wallet5).transfer(balance5); 
      payable(wallet6).transfer(balance6); 
    }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}