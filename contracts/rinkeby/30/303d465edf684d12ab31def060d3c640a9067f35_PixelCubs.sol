// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PixelCubs is ERC721Enumerable, Ownable {
  using Strings for uint256;
// Base URI variables
  string public baseURI;
  string public baseExtension = ".json";
// Initial values for contract
  uint256 public cost;
  uint256 public costHodlr;
  uint256 public maxSupply;
// Sets the Limit of Free Mints per Tier
  uint256 public maxCopper;
  uint256 public maxSilver;
  uint256 public maxGold;
  uint256 public maxDiamond;
  uint256 public maxLegendary;
  uint256 public maxMythical;
// Contract paused on Deployment
  bool public paused = true;
// Contract that is referenced for Discounted Cost
  address public genesisContract;
// Addresses Data, Tiers and Free Mint Count
  mapping(address => bool) public copperCub;
  mapping(address => bool) public silverCub;
  mapping(address => bool) public goldCub;
  mapping(address => bool) public diamondCub;
  mapping(address => bool) public legendaryCub;
  mapping(address => bool) public mythicalCub;
  mapping(address => uint256) public hodlrMints;
// These values are set on deployment 
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _cost,
    uint256 _costHodlr,
    uint256 _maxSupply,
    address _genesisContract
  ) ERC721(_name, _symbol) {
    cost = _cost;
    costHodlr = _costHodlr;
    maxSupply = _maxSupply;
    genesisContract = _genesisContract;
    setBaseURI(_initBaseURI);
  }
// Checks if contract is paused, mint amount is valid, and determines cost for mint
  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "CONTRACT IS PAUSED");
    uint256 _userBalance = IERC721(genesisContract).balanceOf(msg.sender);
        if (mythicalCub[msg.sender] == true && msg.value == 0) {
            require(hodlrMints[msg.sender] + _mintAmount <= maxMythical, "MAX FREE MINTS EXCEEDED");
        } else if (legendaryCub[msg.sender] == true && msg.value == 0) {
            require(hodlrMints[msg.sender] + _mintAmount <= maxLegendary, "MAX FREE MINTS EXCEEDED");
        } else if (diamondCub[msg.sender] == true && msg.value == 0) {
            require(hodlrMints[msg.sender] + _mintAmount <= maxDiamond, "MAX FREE MINTS EXCEEDED");
        } else if (goldCub[msg.sender] == true && msg.value == 0) {
            require(hodlrMints[msg.sender] + _mintAmount <= maxGold, "MAX FREE MINTS EXCEEDED");
        } else if (silverCub[msg.sender] == true && msg.value == 0) {
            require(hodlrMints[msg.sender] + _mintAmount <= maxSilver, "MAX FREE MINTS EXCEEDED");
        } else if (copperCub[msg.sender] == true && msg.value == 0) {
            require(hodlrMints[msg.sender] + _mintAmount <= maxCopper, "MAX FREE MINTS EXCEEDED");
        } else if (_userBalance > 0) {
            require(msg.value >= costHodlr * _mintAmount, "INSUFFICIENT FUNDS");
        } else {
            require(msg.value >= cost * _mintAmount, "INSUFFICIENT FUNDS");
        }
    _;
  }
// Verifies that supply is not exceeded
  modifier supplyCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "MAX SUPPLY EXCEEDED");
    _;
  }
// Mint function, counts free mints if value sent to contract is 0
  function mint() public payable mintCompliance(1) supplyCompliance(1) {  
    uint256 supply = totalSupply();
    if (msg.value == 0) {
        hodlrMints[msg.sender]++;
    }
     _safeMint(msg.sender, supply + 1);
  }
// Airdrop function - Single Mint
  function airdrop(address _receiver) public supplyCompliance(1) onlyOwner {
    uint256 supply = totalSupply();
    _safeMint(_receiver, supply + 1);
  }
// Gets Base URI 
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
// Gets Owners Wallet Address
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
// Get URI for Token, if it exists
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
// Updates new Cost for Public Mint
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
// Updates new Costs for Hodlr Mint
  function setHodlrCost(uint256 _newHodlrCost) public onlyOwner {
    costHodlr = _newHodlrCost;
  }
// Updates Max Free Mints for Copper Cubs
  function setMaxCopper(uint256 _newmaxCopper) public onlyOwner {
    maxCopper = _newmaxCopper;
  }
// Updates Max Free Mints for Silver Cubs
   function setMaxSilver(uint256 _newmaxSilver) public onlyOwner {
    maxSilver = _newmaxSilver;
  }
// Updates Max Free Mints for Gold Cubs
  function setMaxGold(uint256 _newmaxGold) public onlyOwner {
    maxGold = _newmaxGold;
  }
// Updates Max Free Mints for Diamond Cubs
  function setMaxDiamond(uint256 _newmaxDiamond) public onlyOwner {
    maxDiamond = _newmaxDiamond;
  }
// Updates Max Free Mints for Legendary Cubs
  function setMaxLegendary(uint256 _newmaxLegendary) public onlyOwner {
    maxLegendary = _newmaxLegendary;
  }
// Updates Max Free Mints for Mythical Cubs
  function setMaxMythical(uint256 _newmaxMythical) public onlyOwner {
    maxMythical = _newmaxMythical;
  }
// Adds an address to the Copper Cub Free Mint list
  function addCopper(address _user) public onlyOwner {
    copperCub[_user] = true;
  }
// Adds an address to the Silver Cub Free Mint list
  function addSilver(address _user) public onlyOwner {
    silverCub[_user] = true;
  }
// Adds an address to the Gold Cub Free Mint list
  function addGold(address _user) public onlyOwner {
    goldCub[_user] = true;
  }
// Adds an address to the Diamond Cub Free Mint list
  function addDiamond(address _user) public onlyOwner {
    diamondCub[_user] = true;
  }
// Adds an address to the Legendary Cub Free Mint list
  function addLegendary(address _user) public onlyOwner {
    legendaryCub[_user] = true;
  }
// Adds an address to the Mythical Cub Free Mint list
  function addMythical(address _user) public onlyOwner {
    mythicalCub[_user] = true;
  }
// Removes an address from the Copper Cub Free Mint list
  function removeCopper(address _user) public onlyOwner {
    copperCub[_user] = false;
  }
// Removes an address from the Silver Cub Free Mint list
  function removeSilver(address _user) public onlyOwner {
    silverCub[_user] = false;
  }
// Removes an address from the Gold Cub Free Mint list
  function removeGold(address _user) public onlyOwner {
    goldCub[_user] = false;
  }
// Removes an address from the Diamond Cub Free Mint list
  function removeDiamond(address _user) public onlyOwner {
    diamondCub[_user] = false;
  }
// Removes an address from the Legendary Cub Free Mint list
  function removeLegendary(address _user) public onlyOwner {
    legendaryCub[_user] = false;
  }
// Removes an address from the Mythical Cub Free Mint list
  function removeMythical(address _user) public onlyOwner {
    mythicalCub[_user] = false;
  }
// Adds a Batch of addresses to the Copper Cub list
  function batchCopperCubs(address[] calldata _users) public onlyOwner {
    require(_users.length > 1, "MUST ADD MORE THAN ONE USER");
    for (uint256 h; h < _users.length; h++) {
        copperCub[_users[h]] = true;
    }
  }
// Adds a Batch of addresses to the Silver Cub list
  function batchSilverCubs(address[] calldata _users) public onlyOwner {
    require(_users.length > 1, "MUST ADD MORE THAN ONE USER");
    for (uint256 h; h < _users.length; h++) {
        silverCub[_users[h]] = true;
    }
  }
// Adds a Batch of addresses to the Gold Cub list
  function batchGoldCubs(address[] calldata _users) public onlyOwner {
    require(_users.length > 1, "MUST ADD MORE THAN ONE USER");
    for (uint256 h; h < _users.length; h++) {
        goldCub[_users[h]] = true;
    }
  }
// Updates the Contract that is referenced for Discounted Cost
  function setGenesisContract(address _newGenesisContract) public onlyOwner {
    genesisContract = _newGenesisContract;
  }
// Updates the Base URI for the Metadata
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
// Updates the Base URI extension for the Metadata
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
// Set to False to Unpause and True to Pause
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
// Allows Owner to withdraw Contract Funds
   function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}