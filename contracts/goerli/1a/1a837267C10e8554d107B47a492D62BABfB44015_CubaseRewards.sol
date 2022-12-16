// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./IERC165.sol";
import "./ReentrancyGuard.sol";

contract CubaseRewards is IERC165, IERC721Receiver, Ownable {
  using Address for address;

  struct Token{
    address owner;
    uint32 blockid;
    uint32 timestamp;
  }

  IERC721 public COLLECTION;
  uint256 public award;
  bool public isEnabled;
  mapping(uint256 => Token) public tokens;

  constructor(IERC721 collection) Ownable() {
    COLLECTION = collection;
  }

  receive() external payable {}

  // events
  function onERC721Received(
      address,
      address from,
      uint256 tokenId,
      bytes calldata
  ) external returns (bytes4){
    require(isEnabled);
    require(tokens[tokenId].blockid == 0);

    tokens[tokenId] = Token(from, uint32(block.number), uint32(block.timestamp));
    _sendValue(payable(from), award, 5000);
    return IERC721Receiver(this).onERC721Received.selector;
  }


  function claimRewards (uint256[] memory tokenIds) external payable {
      require(COLLECTION.balanceOf(msg.sender) > 0, 'Sorry, you are not eligible for rewards');

      uint256 tokenBalance = tokenIds.length;
      // uint256 rewardAmount = tokenBalance * 0.0085 ether;  
      uint256 rewardAmount = 0 ether;  
      for (uint256 index = 0; index < tokenBalance; ++index) {
            uint256 tokenId = tokenIds[index];
            COLLECTION.transferFrom(msg.sender, address(this), tokenId);
      }
      (bool hs, ) = payable(msg.sender).call{value: rewardAmount}("");
      require(hs, "Failed to Process Rewards");
  }

  // nonpayable
  function safeTransferTo(address to, uint256 tokenId) external {
    require(msg.sender == tokens[tokenId].owner);

    tokens[tokenId] = Token(address(0), 0, 0);
    COLLECTION.safeTransferFrom(address(this), to, tokenId);
  }

  function safeTransferTo(address to, uint256 tokenId, bytes calldata data) external {
    require(msg.sender == tokens[tokenId].owner);

    tokens[tokenId] = Token(address(0), 0, 0);
    COLLECTION.safeTransferFrom(address(this), to, tokenId, data);
  }

  function transferTo(address to, uint256 tokenId) external {
    require(msg.sender == tokens[tokenId].owner);

    tokens[tokenId] = Token(address(0), 0, 0);
    COLLECTION.transferFrom(address(this), to, tokenId);
  }


  // nonpayable - admin
  function setAward(uint256 newAward) external onlyOwner{
    award = newAward;
  }

  function setEnabled(bool newEnabled) external onlyOwner{
    isEnabled = newEnabled;
  }

  function setCollection (IERC721 _collection) external onlyOwner {
    COLLECTION = _collection;
  }

  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    _sendValue(payable(owner()), totalBalance, gasleft());
  }

  function withdraw(uint256 tokenId, address to) external onlyOwner{
    require(tokens[tokenId].blockid == 0);

    tokens[tokenId] = Token(address(0), 0, 0);
    COLLECTION.transferFrom(address(this), to, tokenId);
  }


  // view
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return type(IERC721Receiver).interfaceId == interfaceId
      || type(IERC721).interfaceId == interfaceId
      || type(IERC165).interfaceId == interfaceId;
  }



  // internal
  function _sendValue(address payable recipient, uint256 amount, uint256 gasLimit) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{gas: gasLimit, value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
}