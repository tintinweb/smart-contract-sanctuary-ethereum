// SPDX-License-Identifier: MIT

/*
 ________  _____  ________  ________  ______      ___   ____    ____
|_   __  ||_   _||_   __  ||_   __  ||_   _ `.  .'   `.|_   \  /   _|
  | |_ \_|  | |    | |_ \_|  | |_ \_|  | | `. \/  .-.  \ |   \/   |
  |  _|     | |    |  _| _   |  _|     | |  | || |   | | | |\  /| |
 _| |_     _| |_  _| |__/ | _| |_     _| |_.' /\  `-'  /_| |_\/_| |_
|_____|   |_____||________||_____|   |______.'  `.___.'|_____||_____|
 ___  ____   _____  ____  _____   ______  ______      ___   ____    ____
|_  ||_  _| |_   _||_   \|_   _|.' ___  ||_   _ `.  .'   `.|_   \  /   _|
  | |_/ /     | |    |   \ | | / .'   \_|  | | `. \/  .-.  \ |   \/   |
  |  __'.     | |    | |\ \| | | |   ____  | |  | || |   | | | |\  /| |
 _| |  \ \_  _| |_  _| |_\   |_\ `.___]  |_| |_.' /\  `-'  /_| |_\/_| |_
|____||____||_____||_____|\____|`._____.'|______.'  `.___.'|_____||_____|

by steviep.eth (2022)


The Fiefdoms Kingdom is an ERC721 collection of 721 Vassal tokens.

Each Vassal token gives the token holder ownership over a separate, unique ERC721
contract (a "Fiefdom").

Transfering a Vassal token will also transfer ownership over that Fiefdom.

Minting a Vassal token will create a proxy contract, which inherets all of its behavior
from the Fiefdom Archetype.

Vassal #0 controls the domain of the Fiefdom Archetype directly.

Fiefdoms may collect own royalties without restriction on all tokens within their domain,
but Vassal tokens are subject to the strict trading rules of the broader kingdom.

*/

import "./Dependencies.sol";
import "./BaseTokenURI.sol";
import "./DefaultTokenURI.sol";
import "./FiefdomProxy.sol";
import "./FiefdomArchetype.sol";

pragma solidity ^0.8.11;


contract Fiefdoms is ERC721, Ownable {
  string public license = 'CC BY-NC 4.0';

  mapping(uint256 => address) public tokenIdToFiefdom;
  mapping(address => bool) public allowList;

  address public minter;
  address public fiefdomArchetype;
  address public defaultTokenURIContract;
  bool public useAllowList = true;

  BaseTokenURI private _tokenURIContract;

  uint256 private _totalSupply = 1;
  address private _royaltyBeneficiary;
  uint16 private _royaltyBasisPoints = 1000;
  uint256 public constant maxSupply = 721;

  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);


  // SETUP
  constructor() ERC721('Fiefdoms', 'FIEF') {
    minter = msg.sender;
    _royaltyBeneficiary = msg.sender;
    _tokenURIContract = new BaseTokenURI();
    defaultTokenURIContract = address(new DefaultTokenURI());

    // Publish an archetype contract. All proxy contracts will derive its functionality from this
    fiefdomArchetype = address(new FiefdomArchetype());

    // Token 0 will use the archetype contract directly instead of a proxy
    _mint(msg.sender, 0);

    tokenIdToFiefdom[0] = fiefdomArchetype;
  }


  // BASE FUNCTIONALITY
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function mint(address to) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply < maxSupply, 'Cannot create more fiefdoms');

    _mint(to, _totalSupply);

    // Publish a new proxy contract for this token
    FiefdomProxy proxy = new FiefdomProxy();
    tokenIdToFiefdom[_totalSupply] = address(proxy);

    _totalSupply += 1;
  }

  function mintBatch(address to, uint256 amount) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply + amount <= maxSupply, 'Cannot create more fiefdoms');


    for (uint256 i; i < amount; i++) {
      _mint(to, _totalSupply);
      FiefdomProxy proxy = new FiefdomProxy();
      tokenIdToFiefdom[_totalSupply] = address(proxy);
      _totalSupply++;
    }

  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    // When this token is transferred, also transfer ownership over its fiefdom
    FiefdomArchetype(tokenIdToFiefdom[tokenId]).transferOwnership(from, to);
    return super._transfer(from, to, tokenId);
  }

  // ROYALTIES

  function approve(address to, uint256 tokenId) public virtual override {
    if (useAllowList) require(allowList[to], 'Operator must be on Allow List');
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (useAllowList && approved) require(allowList[operator], 'Operator must be on Allow List');
    super.setApprovalForAll(operator, approved);
  }

  // Fiefdoms may collect their own royalties without restriction, but must follow the rules of the broader kingdom
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    address operator = super.getApproved(tokenId);
    if (useAllowList) {
      return allowList[operator] ? operator : address(0);
    } else {
      return operator;
    }
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    if (useAllowList && !allowList[operator]) {
      return false;
    } else {
      return super.isApprovedForAll(owner, operator);
    }
  }


  function updateUseAllowList(bool _useAllowList) external onlyOwner {
    useAllowList = _useAllowList;
  }

  function updateAllowList(address operator, bool isALed) external onlyOwner {
    allowList[operator] = isALed;
  }

  function setRoyaltyInfo(
    address royaltyBenificiary_,
    uint16 royaltyBasisPoints_
  ) external onlyOwner {
    _royaltyBeneficiary = royaltyBenificiary_;
    _royaltyBasisPoints = royaltyBasisPoints_;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (_royaltyBeneficiary, _salePrice * _royaltyBasisPoints / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // ERC2981 & ERC4906
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }


  // Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return _tokenURIContract.tokenURI(tokenId);
  }

  function setTokenURIContract(address _tokenURIAddress) external onlyOwner {
    _tokenURIContract = BaseTokenURI(_tokenURIAddress);
  }

  function setDefaultTokenURIContract(address newDefault) external onlyOwner {
    defaultTokenURIContract = newDefault;
  }

  function tokenURIContract() external view returns (address) {
    return address(_tokenURIContract);
  }

  // Contract owner actions
  function setLicense(string calldata newLicense) external onlyOwner {
    license = newLicense;
  }

  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  function overlord() external view returns (address) {
    return owner();
  }

  // Events
  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, eventType, content);
  }

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyOwner {
    emit ProjectEvent(_msgSender(), eventType, content);
  }
}