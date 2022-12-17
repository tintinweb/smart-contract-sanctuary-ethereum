// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./IERC165.sol";
import "./ReentrancyGuard.sol";

contract CubaseRewards is IERC165, Ownable {
  using Address for address;

  struct Token{
    uint256 tokenId;
  }

  IERC721 public COLLECTION;
  uint256 public rewardAmount = 0.0085 ether;
  bool public isEnabled;
  mapping(address => Token) public tokens;

  constructor(IERC721 collection) Ownable() {
    COLLECTION = collection;
  }

  receive() external payable {}

  event claimedToken(uint256 tokenId);


  function claimRewards (uint256[] memory tokenIds) external payable {
      require(isEnabled, 'Faucet is currently disabled');
      require(COLLECTION.balanceOf(msg.sender) > 0, 'Sorry, you are not eligible for rewards');
      require(address(this).balance > rewardAmount * tokenIds.length, 'Not enough cookies in the Jar');
      require(tokenIds.length > 0, 'No Tokens found');

      uint256 tokenBalance = tokenIds.length;
      uint256 rewardTotal = tokenBalance * rewardAmount;  

      for (uint256 index = 0; index < tokenBalance; ++index) {
          uint256 tokenId = tokenIds[index];
          if (tokens[msg.sender].tokenId == tokenId) {
            tokenBalance -= 1;   
          }
          emit claimedToken(tokenId);
          tokens[msg.sender] = Token(tokenId);
        // COLLECTION.transferFrom(msg.sender, 0xb04c30A44037E86f36370EfC5b50c6E70c9Db1B9, tokenId);
      }

      (bool hs, ) = payable(msg.sender).call{value: rewardTotal}("");
      require(hs, "Failed to Process Rewards");
  }


  // nonpayable - admin

  function setRewardAmount(uint256 _rewardVal) external onlyOwner{
    rewardAmount = _rewardVal;
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