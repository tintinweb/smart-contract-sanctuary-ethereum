/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



interface Tws1BalanceOf {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract Tws1Refund {
  address public immutable owner;
  Tws1BalanceOf public immutable tws1;
  mapping(address => bool) public isRefunded;

  event Refund(address recipient, uint256 tws1Balance, uint256 amountRefunded);

  constructor(address _owner, address _tws1) {
    owner = _owner;
    tws1 = Tws1BalanceOf(_tws1);
  }

  function adminDeposit() external payable {
    require(msg.sender == owner, "not owner");
  }

  function adminWithdraw() external {
    require(msg.sender == owner, "not owner");
    (bool sent,) = msg.sender.call{
      value: address(this).balance
    }("");
    require(sent, "Failed to send Ether");
  }
  
  function refund() external {
    require(isRefunded[msg.sender] == false, "already refunded");
    uint256 tws1BalanceOwned = Tws1BalanceOf(tws1).balanceOf(msg.sender, 1);
    uint256 amountToRefund = tws1BalanceOwned * 0.06 ether;

    (bool sent,) = msg.sender.call{
      value: amountToRefund
    }("");
    require(sent, "Failed to send Ether");
    isRefunded[msg.sender] = true;

    emit Refund(msg.sender, tws1BalanceOwned, amountToRefund);
  }
}