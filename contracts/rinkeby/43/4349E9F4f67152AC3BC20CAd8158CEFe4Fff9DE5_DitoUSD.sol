/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20
{
     function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
}



contract DitoUSD{

    string private Name = "DitoUSD";
    string private Symbol ="DUSD";
    uint8 private Decimals = 18;
    address private Owner;
    uint256 public DtotalSupply;
    address private contractaddr;
    //mapp address and their balance
    mapping (address=>uint256) Dbalances;

    //initiallize variables and assign supply to owner
     constructor () 
     {
         DtotalSupply = (1000000*10**18);
         Dbalances[msg.sender] = DtotalSupply;
         Owner = msg.sender;


     }

      function name()public view returns(string memory) 
     {
         return Name;

     }

     function symbol()public view returns(string memory)
     {
         return Symbol;
     }

     function decimals()public view returns(uint8)
     {
         return Decimals;
     }


     function totalSupply()public view returns(uint256)
     {
         return DtotalSupply;
     }

     function mintDUSD(address _addr,uint _amount)public
     {
         uint256 amount = (_amount*10**18);
         require (msg.sender == Owner, "No Permission to use this function");
         DtotalSupply += amount;
         Dbalances[_addr]+= amount;
     }

     //can only be called by DitoFarm to pay rewards
     function reward(address _to, uint256 _amount)public
     {
         require(msg.sender==contractaddr,"You cant call this funtion");
         uint256 amount = (_amount*10**18);
         Dbalances[_to] += amount;
     }

     function transfer(address _addr, uint _amount )public returns(bool)
     {
         //check for sufficient balance of user
         require (Dbalances[msg.sender] >= (_amount*10**18), "Insufficient Balance");
         uint256 amount = (_amount*10**18);
         //debit sender and credit reciever
         Dbalances[ msg.sender ]-= amount ;
         Dbalances[ _addr ]+= amount ;
         return true;

     }

     function balanceOf(address _addr)public view returns(uint256)
     {
         //show balance of address
         return Dbalances[_addr];
     }

     function setStakingContract(address _addr)public 
     {
         require(msg.sender == Owner,"Only owner can execute this function");
         contractaddr = _addr;

     }

}