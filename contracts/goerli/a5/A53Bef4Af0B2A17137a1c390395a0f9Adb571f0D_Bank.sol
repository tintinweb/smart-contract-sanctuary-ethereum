// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Bank{

// 存款成功事件
event DepositSuccessEvent(address indexed depositor, uint256 amount);
// 取款成功事件
event WithdrawalSuccessEvent(address indexed depositor, uint256 amount);

  /**
  * @dev 记录地址的存款金额
  */
  mapping(address => uint256) public balances;

  /**
   * @dev 存款方法
   */
  function deposit() public payable{
      require(msg.value > 0, "deposit amount should be greater than 0");
      balances[msg.sender] += msg.value;
      emit DepositSuccessEvent(msg.sender, msg.value);
  }
  
  /**
   *  @dev 取款方法, 取指定数量的余额
   */
  function withdraw(uint256 _amount) public {
      require(balances[msg.sender] >= _amount, "insufficient balance");
      balances[msg.sender] -= _amount;
      (bool _success, ) = msg.sender.call{value: _amount}("");
      require(_success, "withdraw failed");
      emit WithdrawalSuccessEvent(msg.sender, _amount);
  }

  /**
   *  @dev 取款方法, 取所有的余额
   */
  function withdrawAll() public {
      require(balances[msg.sender] > 0, "insufficient balance");
      uint256 _amount = balances[msg.sender];
      balances[msg.sender] = 0;
      (bool _success, ) = msg.sender.call{value: _amount}("");
      require(_success, "withdrawAll failed");
      emit WithdrawalSuccessEvent(msg.sender, _amount);
  }

  /**
   * @dev 限制仅能通过deposit方法进行存款
   */
  receive() external payable {
      revert("only use deposit function to deposit");
  }

  /**
   * @dev 限制仅能通过deposit方法进行存款
   */
  fallback() external payable {
      revert("only use deposit function to deposit");
  }

}