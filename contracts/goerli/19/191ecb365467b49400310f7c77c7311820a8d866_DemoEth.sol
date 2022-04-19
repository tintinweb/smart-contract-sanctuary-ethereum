/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface DemoEthStorage {

  event ReceivedEth(address _sender, uint _amount);

}


contract DemoEth is DemoEthStorage {

  address public owner;
  address public admin;

  constructor() {
    initialize();
  }

  // 初始化参数
  function initialize() internal  {
    require(owner == address(0x0), "ALREADY_INITIALIZED");
    owner = msg.sender;
    admin = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "ONLY_ADMIN");
    _;
  }

  function changeOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function changeAdmin(address newAdmin) external onlyAdmin {
    admin = newAdmin;
  }

  // ETH 存款
  function depositETH() external payable {

    emit ReceivedEth(msg.sender, msg.value);
  }

  // ERC20 存款
  function deposit(uint256 l2Recipient) external {

  }

  // 批量 ETH 转账
  function transferETHBulk(address[] calldata addresses, uint amount) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      payable(addresses[i]).transfer(amount);
    }
  }

  // 提现
  function withdraw(uint amount, address recipient) external  onlyAdmin {
    require(recipient != address(0x0), "INVALID_RECIPIENT");
    payable(recipient).transfer(amount);
  }

}