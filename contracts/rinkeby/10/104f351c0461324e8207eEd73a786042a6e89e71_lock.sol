// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0<0.9.0;
contract lock{
  // 0x104f351c0461324e8207eEd73a786042a6e89e71
    mapping(address => uint) public balances;
    mapping(address => uint) withdrawLimit;
    event LockedAmount(uint indexed amount,address indexed user);
    event WithdrawAmount(uint indexed amount,address indexed user,uint remainingBalance);
    //We want to send deposited money in contract address and update the user balance
    function lockEth() public payable returns(bool){
        require(msg.value>0,"Enter Amount greater than zero");
        balances[msg.sender]+=msg.value;
        if(msg.value%2==0){
            withdrawLimit[msg.sender]=2;
        }else{
            withdrawLimit[msg.sender]=1;
        }
        emit LockedAmount(msg.value,msg.sender);
        return true;
    }
        
    
     function getContractBalance() public view returns(uint){
        return address(this).balance;
     }
 
    
     mapping(address=>uint) currentWithdrawTime;
     mapping(address=>uint) prevWithdrawTime;
     
// we want to withdraw the funds
     function withdraw(uint amount) public payable{
         require(balances[msg.sender]>0 && amount>0 ,"Deposit Ethers first");
         require(balances[msg.sender]>=amount,"Cannot withdraw the amount greater than amount deposited");
      
      uint timenow=block.timestamp;
      currentWithdrawTime[msg.sender]=timenow;
 
         
         if(currentWithdrawTime[msg.sender]-prevWithdrawTime[msg.sender]>1 days || withdrawLimit[msg.sender]>0){
            if(currentWithdrawTime[msg.sender]-prevWithdrawTime[msg.sender]>1 days && balances[msg.sender]%2==0){
                withdrawLimit[msg.sender]=2;
            }
            else if(currentWithdrawTime[msg.sender]-prevWithdrawTime[msg.sender]>1 days && balances[msg.sender]%2!=0){
                withdrawLimit[msg.sender]=1;
            }
             balances[msg.sender]-=amount;
            prevWithdrawTime[msg.sender]=timenow;
             withdrawLimit[msg.sender]--;

            payable(msg.sender).transfer(amount);
            emit WithdrawAmount(amount,msg.sender,balances[msg.sender]);


        }
        else{
            revert ("Withdrawl limit Exceeds ! Please come back Tomorrow");
        }
         
     }


    receive() external payable{}

}