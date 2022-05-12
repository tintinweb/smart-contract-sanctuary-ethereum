// SPDX-License-Identifier: MIT
  pragma solidity ^0.7.5;

  contract TestModule {

      uint public amount;

      event Approval(address indexed owner, address indexed spender, uint256 value);

      function emitApproval(address _owner, address _spender, uint256 _value) public {
          emit Approval( _owner, _spender, _value);
      }

  }