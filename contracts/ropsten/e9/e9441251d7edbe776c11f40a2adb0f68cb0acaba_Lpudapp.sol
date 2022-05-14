/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

/// @title A smart contrat to manage LPU (Lavori Pubblica Utilità)
/// @author Stampiz S.r.l.
/// @notice You can use this contract only on ROPSTEN Ethereum env 
/// @dev All function calls should be currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract Lpudapp {
  /// @notice gip address
  address gip;
  
  /// @notice agency affiliated agency 
  address agency;

  /// @notice registerId indicating the unique register number of LPU
  bytes32 public registerId;

  /// @notice digest indicating the SHA256 hash output on LPU official document
  bytes32 public digest;

  /// @notice completed indicating the current state of LPU process
  int16 public completed;

  event gipSet(address gip, uint timestamp);
  
  event agencySet(address agency, uint timestamp);

  event completedChanged(int16 completed, uint timestamp);

  /// @notice The contract constructor, gip is addreess of initiator, completed is -1
  /// @param _registerId unique register number of LPU
  /// @param _digest SHA256 hash output on LPU official document 
  constructor (bytes32 _registerId, bytes32 _digest) {
    gip = msg.sender;
    registerId = _registerId;
    digest = _digest;
    completed = -1;

    emit gipSet(gip, block.timestamp);
    emit completedChanged(completed, block.timestamp);
  }


  /// @notice set agency address
  function setAgency(address _agency) public {
    if (msg.sender != gip) {
      revert('1');
    }
    else if (completed != -1) {
      revert('2');
    }

    agency = _agency;
    
    completed = 0;

    emit completedChanged(completed, block.timestamp);
  }


  /// @notice Manage error string according completed code
  /// @dev There is table with the meaning of completed
  /// @param _completed completed to set
  function update(int16 _completed) public {
    if (msg.sender == gip ) {
      if (
          (completed == -1 && _completed == 0) || //set Agency
          (completed == -100 && _completed == -128) || //negative gip close
          (completed == -200 && _completed == -256) //positive gip close
      ) {
        completed = _completed;
      }
      else {
        revert('3');
      }
    }
    else if (msg.sender == agency ) {
      if (completed >= 0 && (
           _completed > completed || //positive update
           _completed == -100 || //negative agency close
           _completed == -200) //positive agency close
      ) {
        completed = _completed;
      }
      else {
        revert('4');
      }
    }
    else {
      revert('5');
    }

    emit completedChanged(completed, block.timestamp);
  }

  /// @notice Close positively LPU
  /// @dev There is table with the meaning of completed
  function close() public {
    if (msg.sender == gip && completed == -200) {
      completed = -256;
    }
    else {
      revert('5');
    }
  }


  /// @notice Read the current values for registerId, digest, completed
  /// @dev There is table with the meaning of completed
  /// @return gip xxxxx
  /// @return agency xxxxx
  /// @return registerId xxxxx
  /// @return digest xxxxx
  /// @return completed xxxxxx
  function read () public view returns (address, address, bytes32, bytes32, int16) {

    return (gip, agency, registerId, digest, completed);
  } 

}