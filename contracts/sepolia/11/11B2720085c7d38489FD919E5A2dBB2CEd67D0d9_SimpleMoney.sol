// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

contract SimpleMoney {
    mapping(address => uint) public ledger;

    function deposit() external payable {
        ledger[msg.sender] += msg.value;
    }

   function withdraw(uint amt) external {
       require(amt != 0, "amount can't be 0");
       require(amt <= ledger[msg.sender], "insufficient balance" );
       ledger[msg.sender] -= amt;
       payable(msg.sender).transfer(amt);
   }

}