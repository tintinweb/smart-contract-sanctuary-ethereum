/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// CrowdFunding.sol

pragma solidity >= 0.5.0 <0.6.0;

contract CrowdFunding{
     
     // define investor, note that no NAME
     struct Investor{
         address payable addr; 
         uint amount;  
     }
     
     address payable public owner;          // Issuer of the contract
     uint public numInvestors;      // Number of investors 
     uint public deadline;          // Deadline of investment in UNIX Time
     string public status;          // status of crowdfundinng   
     bool public ended;             // Is crowdfunding ended? Y?N
     uint public goalAmount;        // Target of crowdfunding
     uint public totalAmount;       // Actual amount gathered
     
     mapping(uint => Investor) public investors; // Managing investors
     
     // Specifying that the issuer is the only contract owner
     modifier onlyOwner () {
         require (msg.sender == owner);
         _;
     }
     
     // Initialization with cnstructor
     constructor(uint _duration, uint _goalAmount) public {
        owner = msg.sender;
        deadline = now + _duration;   //set UNIX time
        goalAmount = _goalAmount;
        status = 'Funding';
        ended = false;
        numInvestors = 0;
        totalAmount = 0;
     }
     
     // Launch the action with fund()
     function fund() payable public{ 
         // so long not finished
         require(!ended);
         
         // Increment ach time when the function is successfully activated
         Investor storage inv = investors[numInvestors++];
         inv.addr = msg.sender;
         inv.amount = msg.value;
         totalAmount += inv.amount;
     }
     
     // Check whether the goal is reached
     function checkGoalReached() public onlyOwner{
         // Time and condition to check
         require(!ended);
         require(now >= deadline);
         
         // All money will be given to contract owner
         if (totalAmount >= goalAmount) {
             status =" Funding succeeded";
             ended = true;  // In case successful funding
              if (!owner.send(address(this).balance)){
                  revert(); //guarantee successful transfer
              }
         } else {  
             // in case timeout befor the goal reached
             
             status = 'Campaign failed';
             ended = true;  // no more fund raising
             
             // Give money back to all investors
             uint j = 0;  // running Number
             while(j < numInvestors){
                 // Send back the money he invested
                 if (!investors[j].addr.send(investors[j].amount)){
                     revert();
                 }
                 j++;
             }
             
         }
     }
     
     // Destroy the funding contract
     function kill() public onlyOwner{
         selfdestruct(owner);
     }
}