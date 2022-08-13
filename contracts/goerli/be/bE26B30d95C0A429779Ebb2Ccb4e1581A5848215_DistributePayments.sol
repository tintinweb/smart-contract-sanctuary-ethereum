/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract DistributePayments {
  uint256 private constant _version = 1;
  address public immutable your_team_account;

  address[] public employees;

  constructor(address[] memory _employees) public payable {
    your_team_account = msg.sender;
    employees = _employees;
  }

  function addEmployees(address[] calldata newEmployees) external {
    for (uint256 i = 0; i < newEmployees.length; i++) {
      employees.push(newEmployees[i]);
    }
  }

  function payOut() external {
    require(msg.sender == your_team_account, 'not-your-team-account');
    require(employees.length > 0, '!employees');
    uint256 amountPerEmployee = address(this).balance / employees.length;
    for (uint256 i = 0; i < employees.length; i++) {
      payable(employees[i]).send(amountPerEmployee);
    }
  }
}