// SPDX-License-Identifier: MIT


/*
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/


                    contract by steviep.eth
*/


import "./BaseDependencies.sol";
import "./TokenURI.sol";



pragma solidity ^0.8.11;

interface IBaseContract {
  function ownerOf(uint256) external view returns (address);
}


// TODO on initialize, add optional: mint hook, transfer hook, approval hook, transfer override, approval override

contract BaseERC721 is Initializable, ERC721Upgradeable {
  string public license = 'CC BY-NC 4.0';

  TokenURI private _tokenURIContract;
  uint256 private _totalSupply = 1;
  uint256 private _maxSupply = 1;
  string private _name;
  string private _symbol;
  bool private _initialized;

  uint256 private _parentTokenId;
  IBaseContract private _parent;

  address private minter;
  address private royaltyBenificiary;
  uint16 private royaltyBasisPoints = 1000;

  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  constructor() {
    preInitialize(msg.sender, 0);
  }

  function preInitialize(address parent, uint256 parentTokenId) public initializer {
    _parent = IBaseContract(parent);
    _parentTokenId = parentTokenId;

    _mint(address(this), 0);
  }

  function initialize(string memory name_, string memory symbol_, uint256 maxSupply_, string memory baseURI_) external onlyOwner {
    require(!_initialized);
    _name = name_;
    _symbol = symbol_;
    _maxSupply = maxSupply_;
    minter = msg.sender;
    royaltyBenificiary = msg.sender;
    _tokenURIContract = new TokenURI(baseURI_);
    _initialized = true;
    _transfer(address(this), msg.sender, 0);

  }

  // OWNERSHIP
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function owner() public view virtual returns (address) {
    return _parent.ownerOf(_parentTokenId);
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address previousOwner, address newOwner) external {
    require(msg.sender == address(_parent));
    emit OwnershipTransferred(previousOwner, newOwner);
  }

  // VARIABLES

  function name() public view virtual override(ERC721Upgradeable) returns (string memory) {
   return  _name;
  }

  function symbol() public view virtual override(ERC721Upgradeable) returns (string memory) {
    return _symbol;
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }


  // BASE FUNCTIONALITY
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }


  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function mint(address to, uint256 tokenId) external {
    require(minter == msg.sender, 'Caller is not the minting address');

    require(tokenId < _maxSupply, 'Invalid tokenId');
    _mint(to, tokenId);
    _totalSupply += 1;
  }


  // Events
  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == _msgSender() || ERC721Upgradeable.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, eventType, content);
  }

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyOwner {
    emit ProjectEvent(_msgSender(), eventType, content);
  }


  // Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return _tokenURIContract.tokenURI(tokenId);
  }

  function setTokenURIContract(address _tokenURIAddress) external onlyOwner {
    _tokenURIContract = TokenURI(_tokenURIAddress);
  }

  function tokenURIContract() external view returns (address) {
    return address(_tokenURIContract);
  }


  // Contract owner actions
  function updateLicense(string calldata newLicense) external onlyOwner {
    license = newLicense;
  }

  // Royalty Info
  function setRoyaltyInfo(
    address _royaltyBenificiary,
    uint16 _royaltyBasisPoints
  ) external onlyOwner {
    royaltyBenificiary = _royaltyBenificiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBenificiary, _salePrice * royaltyBasisPoints / 10000);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
    // ERC2981
    return interfaceId == bytes4(0x2a55205a) || super.supportsInterface(interfaceId);
  }





  // Proxy overrides
  // modifier onlyInternal() {
  //   require(msg.sender == address(this), "Only internal");
  //   _;
  // }

  // // TODO test this + total supply
  // function __burn(uint256 tokenId) external onlyInternal {
  //   _burn(tokenId);
  //   _burnt++;
  // }

  // function __mint(address to, uint256 tokenId) external onlyInternal {
  //   _mint(to, tokenId);
  // }

  // function __approve(address to, uint256 tokenId) external onlyInternal {
  //   _approve(to, tokenId);
  // }

  // function __transfer(address from, address to, uint256 tokenId) external onlyInternal {
  //   _transfer(from, to, tokenId);
  // }

  // function __setApprovalForAll(address owner, address operator, bool approved) external onlyInternal {
  //   _setApprovalForAll(owner, operator, approved);
  // }
}