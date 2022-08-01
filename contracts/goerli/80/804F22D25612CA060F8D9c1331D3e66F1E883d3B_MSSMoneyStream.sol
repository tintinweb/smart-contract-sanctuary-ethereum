// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MSSMoneyStream {

  uint256 internal constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

  bool private _initializing;
  bool private _entered;

  mapping(address => uint256) private _pendingWithdrawals;
  
  uint32 private _total;
  struct Member {
    address account;
    uint32 value;
  }
  
  Member[] private _members;

  modifier initializer() {
    require(!_initializing, "Initializable: contract is not initializing");
    _;
  }
  modifier nonReentrant() {
    require(!_entered, "reentrant call");
    _entered = true;
    _;
    _entered = false;
    }

  function initialize(Member[] calldata memberData) initializer external {
    require(memberData.length > 0, "Initializable: must have at least one member");
    
    for(uint16 i = 0; i < memberData.length; i++) {
      _members.push(memberData[i]);
      _total += memberData[i].value;
    }
 
    _initializing = true;
  }

  receive () external payable {
    require(_members.length > 0, "Stream: contract is not initialized");
    
    for(uint i=0; i<_members.length; i++) {
      Member memory member = _members[i];
      _transfer(member.account, msg.value * member.value / _total);
    }
  }

  function withdrawFor(address payable user) external nonReentrant {
    uint256 amount = _pendingWithdrawals[user];
    require(amount != 0, "No Funds Available"); 
    
    _pendingWithdrawals[user] = 0;
    (bool success, ) = user.call{ value: amount, gas: SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT }("");
    if (!success) {
      revert("withdrawFor failed");
    }
  }

  function getMembers() external view returns (Member[] memory) {
    return _members;
  }

  function getPendingWithdrawal(address user) external view returns (uint256 balance) {
    return _pendingWithdrawals[user];
  }

  function _transfer(address to, uint256 amount) internal {
    (bool success, ) = to.call{ value: amount, gas: SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT }("");
    
    if (!success) {
      _pendingWithdrawals[to] += amount;
    }
  }
}