// SPDX-License-Identifier: MIT

import "./Dependencies.sol";
import "./TokenURI.sol";
import "./Multisig.sol";

pragma solidity ^0.8.11;


contract TerminallyOnline is ERC721, Ownable {
  TokenURI private _tokenURIContract;
  Multisig private _multisig;

  address private royaltyBenificiary;
  uint16 private royaltyBasisPoints = 1000;
  string public license = 'CC BY-NC 4.0';


  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  constructor() ERC721("Terminally Online", 'ONLINE') {
    royaltyBenificiary = msg.sender;
    _multisig = new Multisig(this);
    _tokenURIContract = new TokenURI(this);
    for (uint256 i = 0; i < 12; i++) {
      _mint(msg.sender, i);
    }
  }

  modifier onlyMultisig() {
    require(multisig() == _msgSender(), 'Caller is not the multisig address');
    _;
  }

  function multisig() public view returns (address) {
    return address(_multisig);
  }

  // Base functionality
  function totalSupply() external pure returns (uint256) {
    return 12;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  // Multisig update
  function setMultisigContract(Multisig newMultisig) external onlyMultisig {
    _multisig = newMultisig;
  }


  // Events
  function emitTokenEvent(uint256 tokenId, string calldata eventType, string calldata content) external {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, eventType, content);
  }

  function emitProjectEvent(string calldata eventType, string calldata content) external onlyMultisig {
    emit ProjectEvent(_msgSender(), eventType, content);
  }


  // Token URI

  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return _tokenURIContract.tokenURI(tokenId);
  }

  function setTokenURIContract(address _tokenURIAddress) external onlyMultisig {
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

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    // 0x2a55205a == ERC2981 interface id
    return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
  }
}