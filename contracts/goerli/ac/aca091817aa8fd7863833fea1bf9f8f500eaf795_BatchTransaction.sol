// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BatchTransaction {
  event TransactionComplete(address to_, bytes data_);

  function sendBatchedTransactions(
    address[] memory _address,
    bytes[] calldata _data
  ) public {
    uint256 len_ = _address.length;
    require(len_ == _data.length, 'invalid-length');

    for (uint256 i = 0; i < len_; i++) {
      address to_ = _address[i];
      bytes memory data_ = _data[i];
      (bool sent, ) = _address[i].delegatecall(_data[i]);
      require(sent, 'Failed to send Ether');

      emit TransactionComplete(to_, data_);
    }
  }
}