/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity >=0.6.0 <0.9.0;

// Fix this bank 😉 

contract HelloWorld_Bank{
address public owner;
uint private money; 
uint public numberOfAccounts; 
address[] addressesOfCostumers; 
uint public allMoneyBankHave; 


   mapping (address => uint) private balances;
   mapping(address => bool) usedAddresses;

  
   constructor () public payable {
      owner = msg.sender; 
   }
    
//Setting Up authorization
     function isOwner () public view returns(bool) {
          return msg.sender == owner;
   }

     modifier onlyOwner() {
          require(isOwner());
           _;
   }
  
   function deposit () public payable {
          require((balances[msg.sender] + msg.value) >= balances[msg.sender]);
          balances[msg.sender] += msg.value;
          allMoneyBankHave=allMoneyBankHave+msg.value;
          if(usedAddresses[msg.sender]!=true)
            {   
                numberOfAccounts++;
                addressesOfCostumers.push(msg.sender); 
                
            }
          usedAddresses[msg.sender] = true; 

        


     }

     function withdraw (uint withdrawAmount) public {
         require (withdrawAmount <= balances[msg.sender]);
        
         balances[msg.sender] -= withdrawAmount;
         allMoneyBankHave=allMoneyBankHave-withdrawAmount;
         payable(msg.sender).transfer(withdrawAmount);
     }
  
  
     function withdrawAll() public {
          require(balances[msg.sender]>0,"You need money to withdraw!");
          payable(msg.sender).transfer(balances[msg.sender]);
          allMoneyBankHave=allMoneyBankHave-balances[msg.sender];
          balances[msg.sender]=0;
   }

     function getBalance () public view returns (uint){
          return balances[msg.sender];
     }
     
     function getAllMoney() public onlyOwner{
         payable(msg.sender).transfer(address(this).balance);
         for(uint i=0; i<numberOfAccounts;i++ ){
             balances[addressesOfCostumers[i]]=0;
         }
     

        
     }
    
}