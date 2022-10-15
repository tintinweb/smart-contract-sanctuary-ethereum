// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract DownMarketDucks is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  mapping(address => bool) private _approvedMarketplaces;

  uint256 public cost = 0.00375 ether;
  uint256 public maxDucks = 10000;
  uint256 public txnMax = 10;
  uint256 public maxFreeMintEach = 1;
  uint256 public maxMintAmount = 31;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  bool public revealed = true;
  bool public paused = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier quackCompliance(uint256 _mintAmount) {
    require(!paused, "Duck season has not started.");
    require(_mintAmount > 0 && _mintAmount <= txnMax, "Maximum of 10 ducks per txn!");
    require(totalSupply() + _mintAmount <= maxDucks, "No ducks lefts!");
    require(tx.origin == msg.sender, "No smart contract minting.");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "You may have minted max number of ducks!"
    );
    _;
  }

  modifier quackPriceCompliance(uint256 _mintAmount) {
    uint256 realCost = 0;
    
    if (numberMinted(msg.sender) < maxFreeMintEach) {
      uint256 freeMintsLeft = maxFreeMintEach - numberMinted(msg.sender);
      realCost = cost * freeMintsLeft;
    }
   
    require(msg.value >= cost * _mintAmount - realCost, "Insufficient/incorrect funds.");
    _;
  }

  function quack(uint256 _mintAmount) public payable quackCompliance(_mintAmount) quackPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxDucks, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setmaxFreeMintEach(uint256 _maxFreeMintEach) public onlyOwner {
    maxFreeMintEach = _maxFreeMintEach;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

   function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool withdrawFunds, ) = payable(owner()).call{value: address(this).balance}("");
    require(withdrawFunds);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    require(_approvedMarketplaces[to], "Invalid marketplace");
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_approvedMarketplaces[operator], "Invalid marketplace");
    super.setApprovalForAll(operator, approved);
  }

  function setApprovedMarketplace(address market, bool approved) public onlyOwner {
    _approvedMarketplaces[market] = approved;
  }
}