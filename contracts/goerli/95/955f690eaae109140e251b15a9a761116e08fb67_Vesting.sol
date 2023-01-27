/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.2; 



interface SokoToken {
    
    function transfer(address to, uint256 amount) external returns(bool);
    

}

contract Vesting { 
    address public owner;  
    mapping(address => uint) public lockingWallet;
    mapping(address => uint) public VestingTime;
    uint public unlockDate;
    address public tokenContract=address(0);
   
    
    
    constructor(address[] memory _wallet,uint[] memory  _tokenamount, uint[] memory  _vestingTime, address _tokenContract) {

       owner=msg.sender;       
       
       tokenContract= _tokenContract; 
       
       require(_wallet.length == _tokenamount.length && _wallet.length == _vestingTime.length,"Please check parameter values");

       for(uint i=0;i<1;i++){      
       
         lockingWallet[_wallet[i]]=_tokenamount[i]; 
         VestingTime[_wallet[i]]=_vestingTime[i];
        }

        //unlockDate = block.timestamp + 1200; //(30*9*(24*60*60));
    } 
 

    event withdraw(address _to, uint _amount);

    function withdrawTokens() public returns (bool){
            
             
             
             require(lockingWallet[msg.sender] > 0,"Wallet Address not Exist");
             require(block.timestamp > VestingTime[msg.sender],"Tokens are Locked");
             SokoToken(tokenContract).transfer(msg.sender, lockingWallet[msg.sender]);
             lockingWallet[msg.sender]=0;
              VestingTime[msg.sender]=0;
             emit withdraw(msg.sender,lockingWallet[msg.sender]);
            return true;

             
           
    }

    
}