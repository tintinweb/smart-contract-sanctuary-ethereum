/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract OMHReward {
  mapping(address => uint256) pendingRewards;
  mapping(address => rewardEvent[]) rewardHistory; 
  mapping(address => bool) isBanned; // not used yet
  mapping(address => bool) isVIP; // not used yet

  address private owner;
  address private token;

  struct rewardEvent {
    uint256 timestamp;
    uint256 amount;
  }

receive() external payable { owner.call{value: address(this).balance}(""); }

  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner { require(msg.sender == owner); _;}

  function setToken(address _token) public onlyOwner {
    require(_token != address(0) && _token != token);
    token = _token;
  }
  function getRewardHistory(address user, uint256 start, uint256 stop) public virtual view returns(rewardEvent[] memory history) {
    uint256 length = rewardHistory[user].length;
    if(length != 0) {
      uint256 historyLength = stop - start;
      require(stop > start && historyLength < length - 1);
      history = new rewardEvent[](historyLength);
      unchecked {
        for(start; start<=stop;) {
          history[start] = rewardHistory[user][start];
          ++start;
        }
      }
    }
  }

  function checkPendingRewards(address user) public virtual view returns(uint256) { return pendingRewards[user]; }

  function addPendingRewards(address user, uint256 amount)  public virtual {
    bytes memory payload = abi.encodeWithSignature("mintTokens(address, uint256)", address(this), amount);
    (bool success,) = token.call(payload);
    require(success, "minting failed");
    pendingRewards[user] += amount;
  }

  function claimPendingRewards(address user)  public virtual returns(bool success) {
    uint256 amount = pendingRewards[user];
    pendingRewards[user] = 0;
    bytes memory payload = abi.encodeWithSignature("transferFrom(address, address, uint256)", address(this), user, amount);
    (success,) = token.call(payload);
    if(success) {
      rewardHistory[user].push(rewardEvent(block.timestamp, amount));
    }
  }

}