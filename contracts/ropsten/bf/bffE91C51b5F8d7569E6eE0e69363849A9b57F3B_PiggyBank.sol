/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity   0.5.17;


contract PiggyBank {

  struct InvestorArray {
      address payable etherAddress;
      uint amount;
  }

  InvestorArray[] public investors;

  uint public k = 0;
  uint public fees;
  uint public balance = 0;
  address payable owner;

  // simple single-sig function modifier
  modifier onlyowner { if (msg.sender == owner) _ ;}

  // this function is executed at initialization and sets the owner of the contract
  constructor() public {
    owner = msg.sender;
  }

  // fallback function - simple transactions trigger this

  
  function enter() public payable {
       
    if (msg.value < 50 finney) {
        msg.sender.send(msg.value);
        return;
    }
	
    uint amount=msg.value;


    // add a new participant to array
    uint total_inv = investors.length;
    investors.length += 1;
    investors[total_inv].etherAddress = msg.sender;
    investors[total_inv].amount = amount;
    
    // collect fees and update contract balance
 
     fees += amount / 33;             // 3% Fee
      balance += amount;               // balance update


     if (fees != 0) 
     {
     	if(balance>fees)
	{
      	owner.send(fees);
      	balance -= fees;                 //balance update
	}
     }
 

   // 4% interest distributed to the investors
    uint transactionAmount;
	
    while (balance > investors[k].amount * 3/100 && k<total_inv)  //exit condition to avoid infinite loop
    { 
     
     if(k%25==0 &&  balance > investors[k].amount * 9/100)
     {
      transactionAmount = investors[k].amount * 9/100;  
      investors[k].etherAddress.send(transactionAmount);
      balance -= investors[k].amount * 9/100;                      //balance update
      }
     else
     {
      transactionAmount = investors[k].amount *3/100;  
      investors[k].etherAddress.send(transactionAmount);
      balance -= investors[k].amount *3/100;                         //balance update
      }
      
      k += 1;
    }
    
    //----------------end enter
  }



  function setOwner(address payable new_owner)public  onlyowner {
      owner = new_owner;
  }
}