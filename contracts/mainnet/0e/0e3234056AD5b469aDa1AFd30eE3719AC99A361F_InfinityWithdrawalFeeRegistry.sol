//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

contract InfinityWithdrawalFeeRegistry {
  address public destination;
  uint256 public paymentId;

  event LogDeposit(
    address indexed from,
    string rewardWithdrawalId,
    uint256 paymentId,
    uint256 value
  );

  /**
    @param destination_ - wallet address which pays out rewards
   */
  constructor(address destination_) {
    destination = destination_;
  }

  /**
    @param rewardWithdrawalId for which withdrawal fee is paid
   */
  function transfer(string memory rewardWithdrawalId) public payable {
    require(msg.value > 0, "Amount must be greater than zero");
    require(msg.sender != address(0), "Transfer from the zero address");
    (bool sent, ) = payable(destination).call{value: msg.value}("");
    require(sent, "Failed to send Ether");
    uint256 paymentId_ = ++paymentId;
    emit LogDeposit(msg.sender, rewardWithdrawalId, paymentId_, msg.value);
  }
}