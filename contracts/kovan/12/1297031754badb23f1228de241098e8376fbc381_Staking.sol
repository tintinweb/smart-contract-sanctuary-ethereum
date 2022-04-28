// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.13;
 
contract Staking {

uint ETHTVL;
 
address[] public ActiveUsers; //arrau of depositors
mapping (address => uint[2]) public balances; //balances[][0] = deposit, balances[][1] = positive index of depositor (from 1 to array.length, not from 0 to array.length-1)

event AddUser(address NewUser); 
event DeleteUser(address OldUser);
event EraseFailed(address OldUser);
event IndexNotFound(address addr);
event Deposit(address depositor, uint amount);
event Withdrawal(address withdrawer, uint amount);

/// VIEW FUNCTIONS

function getStakedBalance(address addr) public view returns (uint) {return balances[addr][0];}

//calculate the positive index of an address
function getPositiveIndex(address addr) public view returns (uint PositiveIndex) {
     uint i = balances[addr][1]; if (i<ActiveUsers.length) {i=ActiveUsers.length;}
     while (i>0) {
         if (ActiveUsers[i-1] == addr) {PositiveIndex = i;i=1;}
         i--;
        } 
}
     
function getETHTVL() public view returns (uint) {return ETHTVL;}

function getVaultBalance() public view returns (uint) {return address(this).balance;}

function getNbUsers() public view returns (uint) {return ActiveUsers.length;} //Number of active depositors

/// FUNCTIONS GENERATING GAS

function deposit() external payable {
   require (msg.value > 0, "no 0 deposit");
   require (msg.sender.balance>=msg.value, "lack of funds");
   if (!(balances[msg.sender][0]>0)) {
       ActiveUsers.push(msg.sender); 
       balances[msg.sender][1]=ActiveUsers.length; 
       emit AddUser(msg.sender);
    }
   balances[msg.sender][0] += msg.value;
   ETHTVL += msg.value;
   emit Deposit(msg.sender, msg.value);
  
}

function withdrawal(uint amount) external payable {
   require (amount > 0, "no 0 withdrawal");
   require (balances[msg.sender][0]>=amount, "lack of funds");
   balances[msg.sender][0] -= amount;
   ETHTVL -= amount; 
   address payable addr = payable(msg.sender); 
   addr.transfer(amount);
   emit Withdrawal(msg.sender, amount);
   //we want to remove a depositor with 0 ETH staked
   if (balances[msg.sender][0]==0) { 
     //we are sure that the positive index of depositor is less than Min(balances[msg.sender])[1],ActiveUsers.length) so we start searching for that value of i  
     uint i = (balances[msg.sender])[1];if (i<ActiveUsers.length) {i=ActiveUsers.length;} 
     uint PositiveIndex;
     while (i>0) {
         if (ActiveUsers[i-1] == msg.sender) {PositiveIndex = i;i=1;}
         i--;
        } 
     if (PositiveIndex==0) {emit EraseFailed(msg.sender);}
     else {
     ActiveUsers[PositiveIndex-1]=ActiveUsers[ActiveUsers.length-1]; //exchange the inactive depositor with the last one
     ActiveUsers.pop(); //delete the last depositor since he has be copied
     emit DeleteUser(msg.sender);
     }
    }
   }

}