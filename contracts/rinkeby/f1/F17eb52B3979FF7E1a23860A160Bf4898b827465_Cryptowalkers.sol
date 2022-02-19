// SPDX-License-Identifier: MIT

// @title: Cryptowalkers
// @author: Manifest Futures

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract Cryptowalkers is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  Ownable,
  ReentrancyGuard
{
  using Address for address payable;
  using SafeMath for uint256;

  struct WhitelistDetails {
    string whitelistType;
    uint256 amountToMint;
  }

  struct WhitelistUserStatus {
    uint256 whitelistLevel;
    uint256 amountMinted;
    bool limitReached;
  }

  enum State {
    Setup,
    Whitelist,
    Public
  }

  mapping(uint256 => WhitelistDetails) public _whitelistDetails;
  mapping(address => WhitelistUserStatus) public _whitelistUserStatus;
  mapping(uint256 => bool) private _walkerDetailsChanged;
  State private _state;

  string private _tokenUriBase;
  uint256 private _nextTokenId;
  uint256 private _startingIndex;
  uint256 private _amountReserved;
  bool private _reservedMinted;

  uint256 public constant MAX_CRYPTOWALKERS = 10000;
  uint256 public constant MAX_MINT = 10;
  uint256 public constant RESERVED_CRYPTOWALKERS = 400;
  uint256 public WALKER_PRICE = 8E16; // 0.08ETH
  uint256 public UPDATE_DETAILS_PRICE = 8E15; // 0.008ETH
  
  event WalkerDetailsChange(
    uint256 indexed _tokenId,
    string _name,
    string _description
  );

  constructor() ERC721("Cryptowalkers", "Walkers") {
    _state = State.Setup;
    _startingIndex = 1;
    _tokenUriBase = "http://api.cryptowalkers.io/api/token/";
    _whitelistDetails[0].whitelistType = "Not Whitelisted";
    _whitelistDetails[0].amountToMint = 0;
    _whitelistDetails[1].whitelistType = "Infected Walker / Metakey / PolyPixos";
    _whitelistDetails[1].amountToMint = 1;
    _whitelistDetails[2].whitelistType = "Netvrk Land Owner";
    _whitelistDetails[2].amountToMint = 2;
    _whitelistDetails[3].whitelistType = "Whitewalker";
    _whitelistDetails[3].amountToMint = 3;
    _whitelistDetails[4].whitelistType = "Zombie";
    _whitelistDetails[4].amountToMint = 4;
    _whitelistDetails[5].whitelistType = "Mutant";
    _whitelistDetails[5].amountToMint = 5;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
  }

  function baseTokenURI() public view virtual returns (string memory) {
    return _tokenUriBase;
  }

  function setTokenURI(string memory tokenUriBase_) public onlyOwner {
    _tokenUriBase = tokenUriBase_;
  }

  function state() public view virtual returns (State) {
    return _state;
  }

  function setStateToSetup() public onlyOwner {
    _state = State.Setup;
  }

  function setStateToWhitelist() public onlyOwner {
    _state = State.Whitelist;
  }

  function setStateToPublic() public onlyOwner {
    _state = State.Public;
  }

  function addUserToWhitelistByIndex(
    address userToWhitelist,
    uint256 whitelistDetailsIndex
  ) public onlyOwner returns (bool) {
    _whitelistUserStatus[userToWhitelist]
      .whitelistLevel = whitelistDetailsIndex;
    _whitelistUserStatus[userToWhitelist].amountMinted = 0;
    _whitelistUserStatus[userToWhitelist].limitReached = false;
    return true;
  }

  function addUsersToWhitelistByIndex(
    address[] memory usersToWhitelist,
    uint256 whitelistDetailsIndex
  ) public onlyOwner returns (bool) {
    for (uint256 i = 0; i < usersToWhitelist.length; i++) {
      address user = usersToWhitelist[i];
      addUserToWhitelistByIndex(user, whitelistDetailsIndex);
    }
    return true;
  }

  function checkUserMintStatus(address user, uint256 amountToMint) public view {
    require(
      !_whitelistUserStatus[user].limitReached,
      "Whitelist allocation for user has been reached"
    );
    require(
      amountToMint <=
        _whitelistDetails[_whitelistUserStatus[user].whitelistLevel]
          .amountToMint,
      "You can only mint the amount allowed for your whitelist level"
    );
  }

  function updateUserWhitelistStatus(address user) private {
    _whitelistUserStatus[user].amountMinted = _whitelistUserStatus[user]
      .amountMinted
      .add(1);
    if (
      _whitelistUserStatus[user].amountMinted ==
      _whitelistDetails[_whitelistUserStatus[user].whitelistLevel].amountToMint
    ) {
      _whitelistUserStatus[user].limitReached = true;
    }
  }

  function mintReserve(address reserveAddress, uint256 amountToReserve) public onlyOwner {
    require(!_reservedMinted, "Reserve minting has already been completed");
    require(_amountReserved.add(amountToReserve) <= RESERVED_CRYPTOWALKERS, "Reserving too many Cryptowalkers");
    if (totalSupply() == 0){
      _nextTokenId = _startingIndex;
    } 

    for (uint256 i = 0; i < amountToReserve; i++) {
      _safeMint(reserveAddress, _nextTokenId);
      _nextTokenId = _nextTokenId.add(1);
    }
    _amountReserved = _amountReserved.add(amountToReserve);
    if (_amountReserved == RESERVED_CRYPTOWALKERS) {
      _reservedMinted = true;
    }
  }

  function mintWalkers(uint256 amountOfWalkers)
    public
    payable
    virtual
    nonReentrant
    returns (uint256)
  {
    address recipient = msg.sender;
    require(_state != State.Setup, "Cryptowalkers aren't available yet");
    if (_state == State.Whitelist) {
      checkUserMintStatus(recipient, amountOfWalkers);
    }
    require(
      totalSupply().add(1) <= MAX_CRYPTOWALKERS,
      "Sorry, there is not that many Cryptowalkers left."
    );
    require(
      amountOfWalkers <= MAX_MINT,
      "You can only mint 10 Cryptowalkers at a time."
    );

    uint256 firstWalkerReceived = _nextTokenId;

    for (uint256 i = 0; i < amountOfWalkers; i++) {
      _safeMint(recipient, _nextTokenId);
      _nextTokenId = _nextTokenId.add(1);
      if (_state == State.Whitelist) {
        updateUserWhitelistStatus(recipient);
      }
    }

    return firstWalkerReceived;
  }

  function changeWalkerDetails(
    uint256 tokenId,
    string memory newName,
    string memory newDescription
  ) public payable {
    address owner = ownerOf(tokenId);
    require(msg.sender == owner, "This isn't your CryptoWalker");
    uint256 amountPaid = msg.value;
    if (_walkerDetailsChanged[tokenId]) {
      require(
        amountPaid == UPDATE_DETAILS_PRICE,
        "There is a price to tell your CryptoWalker's story again"
      );
    } else {
      require(
        amountPaid == 0,
        "First time telling your CryptoWalker's story is free!"
      );
      _walkerDetailsChanged[tokenId] = true;
    }
    emit WalkerDetailsChange(tokenId, newName, newDescription);
  }

  function setMintPricing(uint256 newPrice) public onlyOwner {
    WALKER_PRICE = newPrice;
  }

  function setDetailsPricing(uint256 newPrice) public onlyOwner {
    UPDATE_DETAILS_PRICE = newPrice;
  }

  function withdrawAllEth() public virtual onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}