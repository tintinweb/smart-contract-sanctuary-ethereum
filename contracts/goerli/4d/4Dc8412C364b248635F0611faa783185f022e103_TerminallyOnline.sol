// SPDX-License-Identifier: MIT

/*
   ______              _           ____
  /_  __/__ ______ _  (_)__  ___ _/ / /_ __
   / / / -_) __/  ' \/ / _ \/ _ `/ / / // /
  /_/__\__/_/ /_/_/_/_/_//_/\_,_/_/_/\_, /
   / __ \___  / (_)__  ___          /___/
  / /_/ / _ \/ / / _ \/ -_)
  \____/_//_/_/_/_//_/\__/

  by steviep.eth

  The index page for this project is viewabile as a decentralized website at terminallyonline.eth
  Individual pieces are viewable at the following subdomains:
    time.terminallyonline.eth
    money.terminallyonline.eth
    life.terminallyonline.eth
    death.terminallyonline.eth
    fomo.terminallyonline.eth
    fear.terminallyonline.eth
    uncertainty.terminallyonline.eth
    doubt.terminallyonline.eth
    god.terminallyonline.eth
    hell.terminallyonline.eth
    stop.terminallyonline.eth
    yes.terminallyonline.eth

  The `multisig` role for this contract is assigned to a multisig wallet where each tokenholder gets one vote.
  Following this contract's publication, the terminallyonline.eth ENS + all subdoimains will be transferred to the multisig.
  In addition, the multisig has the sole ability to update the TokenURI contract.

*/

import "./Dependencies.sol";
import "./TokenURI.sol";
import "./Multisig.sol";

pragma solidity ^0.8.11;


contract TerminallyOnline is ERC721, Ownable {
  string public license = 'CC BY-NC 4.0';

  TokenURI private _tokenURIContract;
  Multisig private _multisig;

  address private royaltyBenificiary;
  uint16 private royaltyBasisPoints = 1000;

  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
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
    // ERC2981 & ERC4906
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}