/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.5.17;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
}

contract Bank {
     using SafeMath for uint256;
     mapping (address => uint256) private balances;
     
     address[] accounts;
     address public owner;
     
     event DepositMade(address indexed accounts, uint amount);
     event WithdrawMade(address indexed accounts, uint amount);
     event Transfer(address _from, address _to, uint amount);
     event SystemWithdrawMade(address indexed accounts, uint amount);
     event SystemDepositMade(address indexed accounts, uint amount);
     
     constructor() public {
         owner = msg.sender;
     }
     
     function deposit() public payable returns (uint){
         if(0 == balances[msg.sender]){
             accounts.push(msg.sender);
         }
         
         balances[msg.sender] = balances[msg.sender].add(msg.value);
         emit DepositMade(msg.sender,msg.value);
         return balances[msg.sender];
     }
     
     function withdraw(uint amount) public payable returns (uint){
         require(balances[msg.sender] >= amount, "Balance is not enought");
         balances[msg.sender] = balances[msg.sender].sub(amount);
         msg.sender.transfer(amount);
         emit WithdrawMade(msg.sender,amount);
         return balances[msg.sender];
     }
     
     function transfer(uint amount,address _to) public payable returns (uint){
         require(balances[msg.sender] >= amount, "Balance is not enought");
         balances[msg.sender] = balances[msg.sender].sub(amount);
         balances[_to] = balances[_to].add(amount);
         emit Transfer(msg.sender,_to,amount);
         return balances[msg.sender];
     }

     function systemBalance() public view returns (uint){
         return address(this).balance;
     }
     
     function userBalance() public view returns (uint){
         return balances[msg.sender];
     }
     
     function systemWithdraw(uint amount) public returns (uint){
         require(owner == msg.sender, "Address is not onwer");
         require(systemBalance() >= amount, "Balance in system not enought");
         msg.sender.transfer(amount);
         emit SystemDepositMade(msg.sender,amount);
         return systemBalance();
     }
     
     function systemDeposit(uint amount) public payable returns (uint){
         require(owner == msg.sender, "Address is not onwer");
         emit SystemDepositMade(msg.sender,amount);
         return systemBalance();
     }
}