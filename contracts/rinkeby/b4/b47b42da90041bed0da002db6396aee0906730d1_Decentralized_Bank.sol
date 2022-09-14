/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

//SPDX-License-Identifier: mit
pragma solidity ^0.8.0;

contract Decentralized_Bank 
{
   address owner ;
   address payable fee;
   uint lockedUntil;


  constructor () { owner = msg.sender;}

    modifier onlyOwner() { require (msg.sender == owner); _;}
  //  modifier lockTime () {require (block.timestamp > lockedUntil); _;}

struct User
{
    string firstName;                   //Users informatin 
    string lastName;
    uint password;
    address userAddr;
}
         
mapping (address => uint)  balance;
mapping (address => bool) registered;
mapping (address => User) Userinfos;


            /*Regiteration Area: (User at first place must register to be able to interact with DBank*/
//--------------------------------------------------------------------
function register(string memory FirstName, string memory LastName, uint Password) public {
    require(msg.sender != owner, "Owner can not register");
    require(registered[msg.sender] != true , "You already have registered");
    registered[msg.sender] = true;

    Userinfos [msg.sender] = User (FirstName,LastName,Password,msg.sender);
}
        /*In Deposit field you need to declare اow long do you want to lock the money in the contract?*/
//--------------------------------------------------------------------
function deposit(uint lockDuration) public payable {
    lockedUntil = lockDuration + block.timestamp;
    balance[msg.sender] += msg.value;
}
        /*10 percent of withdrawl as fee goes to the owner*/
//--------------------------------------------------------------------
function withdraw(uint withdrawAmount, uint Passcode) public payable {
    
    withdrawAmount = withdrawAmount * 1e18; // shows as Ether
    require (Userinfos [msg.sender].password == Passcode,"Wrong Passcode" );
    require (lockedUntil < block.timestamp ,"The withdrawal time has not yet arrived");
    require (withdrawAmount <= balance[msg.sender], "Insufficient Funds");
        
        balance[msg.sender] -= withdrawAmount;                                                      
        payable (msg.sender).transfer(withdrawAmount * 90 / 100);               
        payable (fee).transfer(withdrawAmount  * 10 / 100);
}

            /*Gives you the ability to see how much you have put in the contract*/
//--------------------------------------------------------------------
function getBalance () public view returns(uint) {
    return (address(this).balance /1e18);
}
            /*By calling this function all the fees that have save threw the transactions goes to the owner address*/
//--------------------------------------------------------------------
function getFee() public payable onlyOwner {
   balance[owner] += balance[fee]; 
}



/*function usersInfors(address user_address) public onlyOwner view returns (string memory,string memory,address,uint) {
       
        return (Userinfos[user_address].firstName,
                Userinfos[user_address].lastName,
                Userinfos[user_address].userAddr,
                Userinfos[user_address].password);
    }
*/
}