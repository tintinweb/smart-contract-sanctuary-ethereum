/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

contract Squeue {
  address admin_address;
  uint32 public numOrders; //max order num
  bool public allowTipRemoval;
  bool public paused;

  event eTip(uint32 oid,uint256 amount);
  
  struct OrderStruct {
    uint32 id; 
    address owner;    
    uint256 tipAmount; 
  }
  
  mapping(uint32 => OrderStruct) orders;

  modifier requireAdmin() {
    require(admin_address == msg.sender,"Requires admin privileges");
    _;
  }

  modifier requireOwner(uint32 oid) {
    if (oid >= numOrders) {
      revert("Order ID out of range");
    }
    
    require(msg.sender == orders[oid].owner,"Not owner of order");
    _;
  }

  modifier requireOwnerOrAdmin(uint32 oid) {
    if (oid >= numOrders) {
      revert("Order ID out of range");
    }
    
    require(msg.sender == orders[oid].owner ||
	    admin_address == msg.sender,"Not owner or admin");
    _;
  }

  constructor() {
    numOrders = 0;
    admin_address = msg.sender;    
    paused = true;
    allowTipRemoval = true;
  }
  
  function orderByAddress(address a) public view returns(uint32) {
    uint32 oid = 0;
    
    for (uint32 i = 0;i<numOrders;i++) {
      if (orders[i].owner == a) {
	oid = i;
	break;
      }
    }
    return oid;
  }  
  
  function orderDetails(uint32 oid) public view returns (uint32 id, uint256 tipAmount, address owner) {
    require(oid < numOrders,"Order id not in range");
    id = orders[oid].id;
    tipAmount = orders[oid].tipAmount;
    owner = orders[oid].owner;
  }

  function changeTip(uint32 oid,uint256 amount) public requireOwner(oid) {
    require(!paused,"Contract is paused");
    if (!allowTipRemoval && amount < orders[oid].tipAmount) {
      revert("Can only increase tip amount");
    }
    orders[oid].tipAmount = amount;
    emit eTip(oid,amount);
  }

  function ownerOf(uint32 oid) public view returns(address) {
    return orders[oid].owner;
  }

  function setPaused(bool p) public requireAdmin {
    paused = p;
  }

  function setAllowTipRemoval(bool p) public requireAdmin {
    allowTipRemoval = p;
  }

  //add addresses and positions. Overwrites existing entries
  function addEntries(address[] memory a, uint32[] memory ids) public requireAdmin {
    for (uint32 j=0;j<ids.length;j++) {
      uint32 i = ids[j];
      orders[i].owner = a[j];
      orders[i].id = i;
      if (i >= numOrders) numOrders = i+1;
    }
  }
  
  // won't overwrite existing entries
  function addEntriesNoOverwrite(address[] memory a, uint32[] memory ids) public requireAdmin {
    for (uint32 j=0;j<ids.length;j++) {
      uint32 i = ids[j];
      if (orders[i].id == 0) {
	orders[i].owner = a[j];
	orders[i].id = i;
	if (i >= numOrders) numOrders = i+1;
      }
    }
  }

  // Allow admin to zero out a tip in case of a mistake
  function zeroTip(uint32 oid) public requireAdmin {
    require(!paused,"Contract is paused");    
    orders[oid].tipAmount = 0;
    emit eTip(oid,0);
  }
}