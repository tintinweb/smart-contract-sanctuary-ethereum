// SPDX-License-Identifier: MIT

/*
 ________  _____  ________  ________  ______      ___   ____    ____
|_   __  ||_   _||_   __  ||_   __  ||_   _ `.  .'   `.|_   \  /   _|
  | |_ \_|  | |    | |_ \_|  | |_ \_|  | | `. \/  .-.  \ |   \/   |
  |  _|     | |    |  _| _   |  _|     | |  | || |   | | | |\  /| |
 _| |_     _| |_  _| |__/ | _| |_     _| |_.' /\  `-'  /_| |_\/_| |_
|_____|   |_____||________||_____|   |______.'  `.___.'|_____||_____|
      _       _______      ______  ____  ____  ________  _________  ____  ____  _______  ________
     / \     |_   __ \   .' ___  ||_   ||   _||_   __  ||  _   _  ||_  _||_  _||_   __ \|_   __  |
    / _ \      | |__) | / .'   \_|  | |__| |    | |_ \_||_/ | | \_|  \ \  / /    | |__) | | |_ \_|
   / ___ \     |  __ /  | |         |  __  |    |  _| _     | |       \ \/ /     |  ___/  |  _| _
 _/ /   \ \_  _| |  \ \_\ `.___.'\ _| |  | |_  _| |__/ |   _| |_      _|  |_    _| |_    _| |__/ |
|____| |____||____| |___|`.____ .'|____||____||________|  |_____|    |______|  |_____|  |________|

by steviep.eth (2022)


All Fiefdom Proxy contracts inheret the behavior of the Fiefdom Archetype.

Upon publication, a fiefdom contract will set a placeholder name and symbol, record the timestamp
of its founding at, and will mint token #0 to itself.

Ownership over the Fiefdom will follow the owner of the corrsponding Vassal token, which is manage by
the Fiefdom Kingdom contract.

At any point, the Vassal owner may choose to activate the Fiefdom. This will set the contract's name,
symbol, license, max supply of tokens, and tokenURI contract. While name and symbol are fixed, maxSupply
and tokenURIContract can be updated later. maxSupply and tokenURI can also be frozen by the Vassal owner.

Additionally, the Vassal owner my activate the fiefdom with activateWitHooks. This also accepts a contract
that defines the behavior of transfer and approval hooks.

The Vassal owner will be the default minter of the contract, but can also set the minter to another
address. In pactice, the minter will be a separate minting contract. The minter can mint tokens using
any of three methods: mint, mintBatch, and mintBatchTo.

If set to 0x0, tokenURI logic will default to the default token URI contract set at the kingdom level. Otherwise,
the Fiefdom may freely change its token URI contract.

*/

import "./DefaultTokenURI.sol";
import "./BaseTokenURI.sol";
import "./ERC721Hooks.sol";
import "./Dependencies.sol";

pragma solidity ^0.8.11;

interface IBaseContract {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function defaultTokenURIContract() external view returns (address tokenURIContract);
}

interface ITokenURI {
  function tokenURI(uint256 tokenId) external view returns (string memory uri);
}

contract FiefdomArchetype is ERC721 {
  using Strings for uint256;

  IBaseContract public kingdom;
  IERC721Hooks public erc721Hooks;

  bool public isActivated;
  bool public tokenURIFrozen;
  bool public maxSupplyFrozen;
  address public minter;
  uint256 public fiefdom;
  string public license;
  uint256 public maxSupply;
  uint256 public foundedAt;

  string private _name;
  string private _symbol;
  uint256 private _totalSupply;
  bool private _isInitialized;
  address private _royaltyBeneficiary;
  uint16 private _royaltyBasisPoints;
  address private _tokenURIContract;

  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  // This is only called when the archetype contract is published
  constructor() ERC721('', '') {
    initialize(msg.sender, 0);
  }

  // This is called by the proxy contract when *it* is published
  // Mints token 0 and does not set a name/symbol
  function initialize(address _kingdom, uint256 _fiefdomTokenId) public {
    require(!_isInitialized, "Can't initialize more than once");
    _isInitialized = true;

    // Since constructor is not called (or called the first time with empty values)
    _name = string(abi.encodePacked('Fiefdom ', _fiefdomTokenId.toString()));
    _symbol = string(abi.encodePacked('FIEF', _fiefdomTokenId.toString()));
    kingdom = IBaseContract(_kingdom);
    fiefdom = _fiefdomTokenId;
    foundedAt = block.timestamp;

    _totalSupply = 1;
    _mint(address(this), 0);
  }

  // Instantiates the project beyond the 0th mint
  function activate(
    string memory name_,
    string memory symbol_,
    string memory license_,
    uint256 maxSupply_,
    address tokenURIContract_
  ) public onlyOwner {
    // Require that it can only be called once
    require(!isActivated, "Fiefdom has already been activated");

    // Set the name/symbol
    _name = name_;
    _symbol = symbol_;

    // Set the max token supply
    maxSupply = maxSupply_;

    // Set the defailt minter address + ERC2981 royalty beneficiary
    minter = msg.sender;
    _royaltyBeneficiary = msg.sender;
    _royaltyBasisPoints = 1000;

    // Set the tokenURI contract
    _tokenURIContract = tokenURIContract_;

    license = license_;
    isActivated = true;

    // Recover the 0th token
    _transfer(address(this), msg.sender, 0);
  }

  function activateWitHooks(
    string memory name_,
    string memory symbol_,
    string memory license_,
    uint256 maxSupply_,
    address tokenURIContract_,
    address _erc721Hooks
  ) public onlyOwner {
    activate(name_, symbol_, license_, maxSupply_, tokenURIContract_);
    erc721Hooks = IERC721Hooks(_erc721Hooks);
  }


  // Register hooks
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    if (address(erc721Hooks) != address(0)) erc721Hooks.beforeTokenTransfer(from, to, tokenId);
  }

  function approve(address to, uint256 tokenId) public virtual override {
    if (address(erc721Hooks) != address(0)) erc721Hooks.beforeApprove(to, tokenId);
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (address(erc721Hooks) != address(0)) erc721Hooks.beforeSetApprovalForAll(operator, approved);
    super.setApprovalForAll(operator, approved);
  }


  // OWNERSHIP
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // The owner of this contract is the owner of the corresponding fiefdom token
  function owner() public view virtual returns (address) {
    return kingdom.ownerOf(fiefdom);
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  // This is called by the Fiefdoms contract whenever the corresponding fiefdom token is traded
  function transferOwnership(address previousOwner, address newOwner) external {
    require(msg.sender == address(kingdom), 'Ownership can only be transferred by the kingdom');
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  // VARIABLES

  // BASE FUNCTIONALITY
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }


  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function name() public view virtual override(ERC721) returns (string memory) {
   return  _name;
  }

  function symbol() public view virtual override(ERC721) returns (string memory) {
    return _symbol;
  }

  // MINTING

  function mint(address to, uint256 tokenId) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply < maxSupply, 'Cannot create more tokens');

    _mint(to, tokenId);
    _totalSupply += 1;
  }


  function mintBatch(address[] calldata to, uint256 tokenIdStart) external {
    require(minter == msg.sender, 'Caller is not the minting address');

    uint256 amount = to.length;
    require(_totalSupply + amount <= maxSupply, 'Cannot create more tokens');

    for (uint256 i; i < amount; i++) {
      _mint(to[i], tokenIdStart + i);
    }

    _totalSupply += amount;
  }

  function mintBatchTo(address to, uint256 amount, uint256 tokenIdStart) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply + amount <= maxSupply, 'Cannot create more tokens');

    for (uint256 i; i < amount; i++) {
      _mint(to, tokenIdStart + i);
    }

    _totalSupply += amount;
  }

  // Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return ITokenURI(tokenURIContract()).tokenURI(tokenId);
  }

  function tokenURIContract() public view returns (address) {
    return _tokenURIContract == address(0)
      ? kingdom.defaultTokenURIContract()
      : _tokenURIContract;
  }

  function setTokenURIContract(address tokenURIContract_) external onlyOwner {
    require(!tokenURIFrozen, 'Token URI has been frozen');
    _tokenURIContract = tokenURIContract_;
  }

  function freeszeTokenURI() external onlyOwner {
    require(isActivated, 'Feifdom must be activated');
    tokenURIFrozen = true;
  }

  // Contract owner actions
  function freezeMaxSupply() external onlyOwner {
    require(isActivated, 'Feifdom must be activated');
    maxSupplyFrozen = true;
  }

  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    require(isActivated, 'Feifdom must be activated');
    require(newMaxSupply >= _totalSupply, 'maxSupply must be >= than totalSupply');
    require(!maxSupplyFrozen, 'maxSupply has been frozen');
    maxSupply = newMaxSupply;
  }

  function setLicense(string calldata newLicense) external onlyOwner {
    license = newLicense;
  }

  // Royalty Info
  function setRoyaltyInfo(
    address royaltyBeneficiary,
    uint16 royaltyBasisPoints
  ) external onlyOwner {
    _royaltyBeneficiary = royaltyBeneficiary;
    _royaltyBasisPoints = royaltyBasisPoints;
  }

  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (_royaltyBeneficiary, _salePrice * _royaltyBasisPoints / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // ERC2981
    return interfaceId == bytes4(0x2a55205a) || super.supportsInterface(interfaceId);
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