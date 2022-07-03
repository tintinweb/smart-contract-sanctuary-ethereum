/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract Escrow {
  address public payer; // address paying the funds
  address payable public  payee; // address receiving the funds
  address public thirdParty; // contract address releasing the funds to payee
  uint amount ; // amount of  money or ether being sent 

  constructor(address _payer, address payable _payee, uint _amount){
    payer = _payer;
    payee = _payee;
    thirdParty = msg.sender;
    amount = _amount;
    
  }
  

 // To deposit funds to payee and make sure sender is payer
  function deposit(address _payee)public payable{
    require(msg.sender == payer, "Sender must be payer");
    require(address(this).balance <= amount, "Amount cant be greater than drop");
  }


 // To release the funds to payee
    
    function release() public{
      address(this).balance;
      require(address(this).balance <= amount, "cannot release funds before full amount is sent");

      // when release button is called , it checks if the sender is the third party if else, it reverts
      require(msg.sender == thirdParty , "only thirdParty can release funds");
      payable(payee).transfer(amount);

      

    }

    // Get Balance of Payeee

     function balanceOfpayee()public view returns(uint){
        return address(this).balance;
      }
 
}