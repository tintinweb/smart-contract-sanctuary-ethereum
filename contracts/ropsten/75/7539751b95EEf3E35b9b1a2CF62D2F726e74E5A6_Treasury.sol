// SPDX-License-Identifier: MIT  
pragma solidity 0.8.15;
import "./Initializable.sol";
import "./AdminRole.sol";
import "./CollateralManagement.sol";
import "./WithdrawFromEscrow.sol";
contract Treasury is AdminRole, CollateralManagement, WithdrawFromEscrow {
  function initialize(address admin) public initializer {
    AdminRole._initializeAdminRole(admin);
  }
}