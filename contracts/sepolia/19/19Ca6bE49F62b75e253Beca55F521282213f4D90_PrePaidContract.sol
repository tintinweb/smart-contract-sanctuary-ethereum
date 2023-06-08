/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18 <0.8.20;

abstract contract AbstractTPC {
  address public masterCopy;
  function upgrade(address master) external virtual payable;
  function version() public pure virtual returns(uint256 v);
}

abstract contract AbstractTM {
  address internal masterCopy;

  bytes32 internal name32;
  uint256 private ownerPrices;                                                  // buyPrice, sellPrice, owner address

  mapping(address => uint256)                     private balances;
  mapping(address => mapping(address => uint256)) private allowed;

  function getMemberBalances(bytes32 hash,address gwfc) external view virtual returns (uint[] memory);
  function balanceOf(address tokenOwner) external view virtual returns (uint thebalance);
  function sellPrice() external view virtual returns (uint256 sp);
  function buyPrice() external view virtual returns (uint256 bp);
  function name() external view virtual returns (string memory);
  function owner() external view virtual returns (address ow);
  function getMasterCopy() external view virtual returns (address);
}

contract PrePaidContract {
    address private pp_account;
    address private pp_owner;

    event PrePaidCreated(address indexed);
    event DepositPrePayment(address from, uint256 value);
    
    constructor(address _account) payable {
      pp_account = _account;
      pp_owner   = AbstractTM(AbstractTPC(msg.sender).masterCopy()).getMasterCopy();
      emit PrePaidCreated(address(this));
    }
    
    receive() external payable {
      if (msg.value==0) return;                                                 // no payment at all
      
      uint256 gasPrice;
      assembly { gasPrice := gasprice() }
  
      require(payable(pp_account).send(msg.value-uint(gasPrice*318659))&&payable(pp_owner).send(address(this).balance),"pp"); // forwarding funding - cost of transaction
     
      emit DepositPrePayment(msg.sender, msg.value);
    }
}