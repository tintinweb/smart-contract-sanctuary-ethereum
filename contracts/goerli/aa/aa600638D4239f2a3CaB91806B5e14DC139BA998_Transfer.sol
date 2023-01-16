// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Transfer {
  struct TransferStruct {
    address sender;
    address receiver;
    string message;
    uint256 amount;
  }

  event Transfered(address sender, address receiver, string message, uint256 amount);  

  TransferStruct[] public transactions;

  function TransferEther(address receiver, string memory message, uint256 amount) public payable returns(bool) {
    require(amount > 0 ether, "no amount was specified");

    TransferStruct memory transferStruct = TransferStruct(msg.sender, receiver, message, amount);

    transactions.push(transferStruct);
    emit Transfered(msg.sender, receiver, message, amount);

    (bool sent,) = payable(receiver).call{ value: amount }("");

    return sent;
  }

  function getAllTransactions() public view returns(TransferStruct[] memory) {
    return transactions;
  }
}