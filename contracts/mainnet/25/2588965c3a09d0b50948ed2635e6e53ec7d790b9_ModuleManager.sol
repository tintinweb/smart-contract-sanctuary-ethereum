/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ModuleManager {
  /**
   * @dev Modules
   */
  mapping (uint => address) private _modules;

  /**
   * @dev Module changed
   */
  event NewModule(uint function_, address newModule_);

  /**
   * @notice This module is vital to add the another ones
   */
  constructor (address votation_) {
    _modules[3] = votation_;
  }

  /**
   * @dev Only votation
   */
  modifier onlyVotation {
    require(msg.sender == _modules[3], 'E301');
    _;
  }  

  /**
   * @notice Function to set modules
   * @param module_ The module function
   * @param address_ The module address
   */
  function setModule(uint module_, address address_) public onlyVotation {
    _modules[module_] = address_;
    emit NewModule(module_, address_);
  }

  /**
   * @notice Get module address
   * @param module_ Function of the module to get
   * @return address of the module
   */
  function getModule(uint module_) public view returns (address) {
    return _modules[module_];
  }

}