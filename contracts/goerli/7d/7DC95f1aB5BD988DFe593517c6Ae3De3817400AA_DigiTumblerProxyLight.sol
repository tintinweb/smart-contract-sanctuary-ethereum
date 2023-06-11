// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDigiTumblerInstance {

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


contract DigiTumblerProxyLight {

    event EncryptedNote(address indexed sender, bytes encryptedNote);

    function deposit(
        IDigiTumblerInstance _digiTumbler,
        bytes32 _commitment,
        bytes calldata _encryptedNote
    ) external payable {
        _digiTumbler.deposit{ value: msg.value }(_commitment);
        emit EncryptedNote(msg.sender, _encryptedNote);
    }

    function withdraw(
        IDigiTumblerInstance _digiTumbler,
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable {
        _digiTumbler.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
    }

    function backupNotes(bytes[] calldata _encryptedNotes) external {
        for (uint256 i = 0; i < _encryptedNotes.length; i++) {
            emit EncryptedNote(msg.sender, _encryptedNotes[i]);
        }
    }
}