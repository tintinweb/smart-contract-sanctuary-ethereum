/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IAno2MassInstance {
  function token() external view returns (address);

  function denomination() external view returns (uint256);

  function deposit(bytes32 commitment) external payable;

  function withdraw(
    bytes calldata proof,
    bytes32 root,
    bytes32 nullifierHash,
    address payable recipient,
    address payable relayer,
    uint256 fee,
    uint256 refund
  ) external payable;
}


contract Ano2MassProxyLight {
  event EncryptedNote(address indexed sender, bytes encryptedNote);

  function deposit(
    IAno2MassInstance _tornado,
    bytes32 _commitment,
    bytes calldata _encryptedNote
  ) external payable {
    _tornado.deposit{ value: msg.value }(_commitment);
    emit EncryptedNote(msg.sender, _encryptedNote);
  }

  function withdraw(
    IAno2MassInstance _tornado,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) external payable {
    _tornado.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
  }

  function backupNotes(bytes[] calldata _encryptedNotes) external {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }
}