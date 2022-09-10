// SPDX-License-Identifier: MIT

//  _____ ______   ________  ________  _______           ________      ___    ___      ___  __    ___  ___  ________  ___      _______  _________  ___  ___     
// |\   _ \  _   \|\   __  \|\   ___ \|\  ___ \         |\   __  \    |\  \  /  /|    |\  \|\  \ |\  \|\  \|\   __  \|\  \    |\  ___ \|\___   ___\\  \|\  \    
// \ \  \\\__\ \  \ \  \|\  \ \  \_|\ \ \   __/|        \ \  \|\ /_   \ \  \/  / /    \ \  \/  /|\ \  \ \  \ \  \|\  \ \  \   \ \   __/\|___ \  \_\ \  \\\  \   
//  \ \  \\|__| \  \ \   __  \ \  \ \\ \ \  \_|/__       \ \   __  \   \ \    / /      \ \   ___  \ \  \ \  \ \   _  _\ \  \   \ \  \_|/__  \ \  \ \ \   __  \  
//   \ \  \    \ \  \ \  \ \  \ \  \_\\ \ \  \_|\ \       \ \  \|\  \   \/  /  /        \ \  \\ \  \ \  \ \  \ \  \\  \\ \  \ __\ \  \_|\ \  \ \  \ \ \  \ \  \ 
//    \ \__\    \ \__\ \__\ \__\ \_______\ \_______\       \ \_______\__/  / /           \ \__\\ \__\ \__\ \__\ \__\\ _\\ \__\\__\ \_______\  \ \__\ \ \__\ \__\
//     \|__|     \|__|\|__|\|__|\|_______|\|_______|        \|_______|\___/ /             \|__| \|__|\|__|\|__|\|__|\|__|\|__\|__|\|_______|   \|__|  \|__|\|__|
//                                                                   \|___|/                                                                                    

// made by kiiri.eth

pragma solidity ^0.8.0;
// import contracts
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC721COLL.sol";

contract collectors is Ownable, ERC721COLL, ReentrancyGuard {

  uint256 public saleStatus;
  uint256 public total;
  string private baseURI;
  uint256 public reservedCounter;
  uint256 public price;
  uint256 public totalMinted;
  uint256 public currentCap;

  mapping(address => uint256) minted;

  // constructor 
  constructor() ERC721COLL("Collectors3", "C3") { 
    total = 5000; // total amount of NFTS
    saleStatus = 0; // sale status 0 = off 1 = on
    reservedCounter = 0; // reserved counter
    totalMinted = 0; // total amount of nfts minted
    price = 0.02 ether; // price for non free nfts
    currentCap = 1000; // Current cap of mintable tokens
    baseURI = "collectors3.io/metadata/premium/json";

  }

  //see if {tokenId} is minted
  function isMinted(uint256 _tokenId) external view returns (bool) {
    require(_tokenId <= total, "tokenId outside collection bounds");
    return _exists(_tokenId);
  }

  // view the base URI
  function _baseURI() internal override view returns (string memory) {
    return baseURI;
  }

  // mint reserved

  function mintReserved(uint256 numberOfTokens) public onlyOwner {
    _safeMint(msg.sender, (numberOfTokens));
    totalMinted += numberOfTokens;
    reservedCounter += numberOfTokens;
  }

  // Public mint function
  function mint() public payable nonReentrant{
    require(saleStatus == 1, "Sale must be active to mint");
    require(totalMinted + 1 < total);
    require(totalMinted + 1 < currentCap);
    require(msg.value >= price);
    require(minted[msg.sender] == 0, "Minter must not have minted an nft");
    _safeMint(msg.sender, 1);
    totalMinted += 1;
    updateMintCount(msg.sender, 1);
  }

    // Public mint function
  function mintFriend(address _address) public payable {
    require(saleStatus == 1, "Sale must be active to mint");
    require(totalMinted + 1 < total);
    require(totalMinted + 1 < currentCap);
    require(msg.value >= price);
    require(minted[_address] == 0, "Minter must not have minted an nft");
    _safeMint(_address, 1);
    totalMinted += 1;
    updateMintCount(_address, 1);
  }


  // internal functions
  function updateMintCount(address _sender, uint256 _amount) internal{
    minted[_sender] = _amount;
  }

  // Owner Only functions
  function setSaleState(uint256 _saleState) public onlyOwner {
    saleStatus = _saleState;
  }

  function withdraw() public payable onlyOwner{
    uint256 balance = address(this).balance;
    payable(0x2523323a8f18477dA41F368bA6B61443b6A627Cc).transfer(balance/3*2);
    payable(0xF7A4BF9D6fC605F3c0A32a90C061547cd0115e53).transfer(balance/3);
  }

  function setPrice(uint256 _newprice) public onlyOwner{
    price = _newprice;
  }
  function setCap(uint256 _newCap) public onlyOwner{
    require(_newCap <= total, "New cap cant be greater then collection max");
    currentCap = _newCap;
  }

  function setURI(string memory _URI) public onlyOwner{
    baseURI = _URI;
  }
}