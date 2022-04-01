/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

/*
* DecentraMix (DeMix) - Product Of DecentraWorld
* Built With Zero-Knowledge Privacy Protocols (zkSNARK)
* 
* Live DApp: https://decentramix.io/
* Documentation: http://docs.decentraworld.co/
* GitHub: https://github.com/decentraworldDEWO
* Main Website: https://DecentraWorld.co
*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░██████╗░███████╗░█████╗░███████╗███╗░░██╗████████╗██████╗░░█████╗░░░
*░░██╔══██╗██╔════╝██╔══██╗██╔════╝████╗░██║╚══██╔══╝██╔══██╗██╔══██╗░░
*░░██║░░██║█████╗░░██║░░╚═╝█████╗░░██╔██╗██║░░░██║░░░██████╔╝███████║░░
*░░██║░░██║██╔══╝░░██║░░██╗██╔══╝░░██║╚████║░░░██║░░░██╔══██╗██╔══██║░░
*░░██████╔╝███████╗╚█████╔╝███████╗██║░╚███║░░░██║░░░██║░░██║██║░░██║░░
*░░╚═════╝░╚══════╝░╚════╝░╚══════╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░░░░░░░░░░░░░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░░░░░░░░░░░░
*░░░░░░░░░░░░░░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗░░░░░░░░░░░
*░░░░░░░░░░░░░░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║░░░░░░░░░░░
*░░░░░░░░░░░░░░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║░░░░░░░░░░░
*░░░░░░░░░░░░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝░░░░░░░░░░░
*░░░░░░░░░░░░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░░░░░░░░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

// File: contracts/interfaces/IDeMixInstance.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IDeMixInstance {
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

// File: contracts/DeMixProxyLight.sol

/*
* DecentraMix (DeMix) - Product Of DecentraWorld
* Built With Zero-Knowledge Privacy Protocols (zkSNARK)
* 
* Live DApp: https://decentramix.io/
* Documentation: http://docs.decentraworld.co/
* GitHub: https://github.com/decentraworldDEWO
* Main Website: https://DecentraWorld.co
*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░██████╗░███████╗░█████╗░███████╗███╗░░██╗████████╗██████╗░░█████╗░░░
*░░██╔══██╗██╔════╝██╔══██╗██╔════╝████╗░██║╚══██╔══╝██╔══██╗██╔══██╗░░
*░░██║░░██║█████╗░░██║░░╚═╝█████╗░░██╔██╗██║░░░██║░░░██████╔╝███████║░░
*░░██║░░██║██╔══╝░░██║░░██╗██╔══╝░░██║╚████║░░░██║░░░██╔══██╗██╔══██║░░
*░░██████╔╝███████╗╚█████╔╝███████╗██║░╚███║░░░██║░░░██║░░██║██║░░██║░░
*░░╚═════╝░╚══════╝░╚════╝░╚══════╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*░░░░░░░░░░░░░░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░░░░░░░░░░░░
*░░░░░░░░░░░░░░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗░░░░░░░░░░░
*░░░░░░░░░░░░░░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║░░░░░░░░░░░
*░░░░░░░░░░░░░░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║░░░░░░░░░░░
*░░░░░░░░░░░░░░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝░░░░░░░░░░░
*░░░░░░░░░░░░░░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░░░░░░░░░
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract DeMixProxyLight {
  event EncryptedNote(address indexed sender, bytes encryptedNote);

  function deposit(
    IDeMixInstance _demix,
    bytes32 _commitment,
    bytes calldata _encryptedNote
  ) external payable {
    _demix.deposit{ value: msg.value }(_commitment);
    emit EncryptedNote(msg.sender, _encryptedNote);
  }

  function withdraw(
    IDeMixInstance _demix,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) external payable {
    _demix.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
  }

  function backupNotes(bytes[] calldata _encryptedNotes) external {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }
}