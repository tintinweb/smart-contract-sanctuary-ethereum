/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract DistributePayments {
  address public owner;
  address[] public employees;

  constructor(address[] memory _employees) public payable {
    owner = msg.sender;
    employees = _employees;
  }

  function addEmployees(address[] calldata newEmployees) external {
    for (uint256 i = 0; i < newEmployees.length; i++) {
      employees.push(newEmployees[i]);
    }
  }

  function payOut() external {
    require(msg.sender == owner, '!owner');
    require(employees.length > 0, '!employees');
    uint256 amountPerEmployee = address(this).balance / employees.length;
    for (uint256 i = 0; i < employees.length; i++) {
      payable(employees[i]).send(amountPerEmployee);
    }
  }
}