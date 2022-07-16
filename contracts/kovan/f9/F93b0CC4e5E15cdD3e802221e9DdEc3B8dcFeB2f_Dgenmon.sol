// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Context.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Presalable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract Dgenmon is ERC721AQueryable, Ownable, Pausable, Presalable, ReentrancyGuard {
  using SafeMath for uint;
  using ECDSA for bytes32;

  string public baseTokenURI;

  uint256 public constant PRICE = 0.0099 ether;
  uint256 public constant PRESALE_PRICE = 0.0069 ether;
  uint256 public constant MAX_TOKEN_COUNT = 7878;

  mapping(address => bool) public isPresaleMinted;

  address t1 = 0x402351069CFF2F0324A147eC0a138a1C21491591; // marketing wallet 1
  address t2 = 0x66B60143Fe3388551a4749aCD5C07Bbd368874ad; // dev wallet 2

  bool internal _locked;

  constructor(string memory _baseTokenURI) ERC721A("Dgenmon", "Dgenmon")  {
    setBaseURI(_baseTokenURI);
    presale();
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function totalBurned() public view returns (uint256) {
    return _totalBurned();
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function mint(uint256 _amount, bytes memory _signature) public payable whenNotPresaled whenNotPaused {
    address signer = _recoverSigner(msg.sender, _signature);

    require(signer == owner(), "Not authorized to mint");
    require(_numberMinted(msg.sender) + _amount <= 4, "Can only mint 4 tokens at address");
    require(_totalMinted() + _amount <= MAX_TOKEN_COUNT, "Exceeds maximum supply");

    //(, uint256 _nonFreeAmount) = _numberMinted(msg.sender) == 2 
    //                             ? (true, 1) : (_numberMinted(msg.sender) + _amount).trySub(1);

    //require(_nonFreeAmount == 0 || msg.value >= PRICE * _nonFreeAmount, "Ether value sent is not correct");
    if (_numberMinted(msg.sender) == 0)
        require(msg.value >= PRICE * _amount-1, "Ether value sent is not correct");
    else
        require(msg.value >= PRICE * _amount, "Ether value sent is not correct");

    _safeMint(msg.sender, _amount);
  }

  function presaleMint(uint256 _amount, bytes memory _signature) public payable whenPresaled whenNotPaused {        
    address signer = _recoverSigner(msg.sender, _signature);
    require(isPresaleMinted[msg.sender] == false, "Already mint for presale");
    require(signer == owner(), "Not authorized to mint");
    require(_numberMinted(msg.sender) + _amount <= 4, "Can only mint 4 tokens at address");
    require(_totalMinted() + _amount <= MAX_TOKEN_COUNT, "Exceeds maximum supply");

    //(, uint256 _nonFreeAmount) = _numberMinted(msg.sender) == 4 
    //                             ? (true, 1) : (_numberMinted(msg.sender) + _amount).trySub(2);

    //require(_nonFreeAmount == 0 || msg.value >= PRESALE_PRICE * _nonFreeAmount, "Ether value sent is not correct");
    
    require( msg.value >= PRESALE_PRICE * _amount-1, "Ether value sent is not correct");

    _safeMint(msg.sender, _amount);
    isPresaleMinted[msg.sender] = true;
  }

  function burnUnlucky(uint256[] memory _tokenIds) public onlyOwner whenNotPaused {
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(_tokenIds[i]);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 _balance = address(this).balance / 100;

    require(payable(t1).send(_balance * 15));
    require(payable(t2).send(_balance * 85));
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function presale() public onlyOwner {
    _presale();
  }

  function unpresale() public onlyOwner {
    _unpresale();
  }

  function _recoverSigner(address _wallet, bytes memory _signature) private pure returns (address){
    return keccak256(abi.encodePacked(_wallet)).toEthSignedMessageHash().recover(_signature);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}