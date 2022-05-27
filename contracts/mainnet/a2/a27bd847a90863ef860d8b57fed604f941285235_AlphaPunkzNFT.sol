//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

pragma solidity >=0.7.0 <0.9.0;

contract AlphaPunkzNFT is ERC721A, Ownable {

  /** ERRORS */
  error ExceedsMaxSupply();
  error InvalidAmount();
  error FreeMintOver();
  error ExceedsWalletLimit();
  error InsufficientValue();
  error TokenNotFound();
  error ContractMint();
  error SaleInactive();

  using Strings for uint256;

  uint256 public cost = 0.001 ether;
  uint256 public maxSupply = 4444;
  uint256 public maxMintAmountPerTx = 20;
  uint256 public freeMaxMintPerWallet = 5;
  uint256 public freeMintMax = 1500;
  
  bool public saleActive = false;
  bool public revealed = true;
  
  mapping(address => uint256) public freeWallets;

  string public _baseTokenURI = "ipfs://QmRRFgJb2Fv65E4uVM78E1fkMyg4AR9q7gkUvzJRfXbCeG/";

  constructor() ERC721A("Alpha Punkz NFT", "AlphaPunkzNFT") payable {
      _safeMint(msg.sender, 5);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    if (!saleActive) revert SaleInactive();
    if (msg.sender != tx.origin) revert ContractMint();
    if (totalSupply() + _mintAmount > maxSupply) revert ExceedsMaxSupply();
    if (_mintAmount < 1 || _mintAmount > maxMintAmountPerTx) revert InvalidAmount();
    _;
  }

  function freeMint(uint256 _mintAmount) public mintCompliance(_mintAmount) {
    if (!isFreeMint()) revert FreeMintOver();
    if (freeWallets[msg.sender] + _mintAmount > freeMaxMintPerWallet) revert ExceedsWalletLimit();
    unchecked { freeWallets[msg.sender] += _mintAmount; }

    _safeMint(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount)
    external
    payable
    mintCompliance(_mintAmount)
  {
    if (msg.value < (cost * _mintAmount)) revert InsufficientValue();
    _safeMint(msg.sender, _mintAmount);
  }

  function _startTokenId()
      internal
      view
      virtual
      override returns (uint256) 
  {
      return 1;
  }

  function isFreeMint() public view returns (bool) {
    return totalSupply() < freeMintMax;
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
 
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  
  function toggleSaleState() public onlyOwner {
    saleActive = !saleActive;
  }

  function setMaxFreeMint(uint256 _max) public onlyOwner {
    freeMintMax = _max;
  }

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /** METADATA */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setRevealed(bool state) public onlyOwner {
      revealed = state;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(_tokenId)) revert TokenNotFound();

    if (!revealed) return _baseURI();
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
  }

}