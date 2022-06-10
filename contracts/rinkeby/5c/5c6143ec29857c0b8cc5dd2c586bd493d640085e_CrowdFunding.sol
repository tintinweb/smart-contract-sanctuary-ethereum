/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity >= 0.5.0 < 0.6.0;

contract CrowdFunding{
     
     // define investor, note that no NAME
     struct Investor{
         address payable addr;     // your address: pay or be paid
         uint amount;              //how many money
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
         require (msg.sender == owner);   //only owner could get the money
         _;
     }
     
     // Initialization with cnstructor
     constructor(uint _duration, uint _goalAmount) public { //time and goal
        owner = msg.sender;                        // who deploy the contract
        deadline = now + _duration;   //set UNIX time
        goalAmount = _goalAmount;    
        status = 'Funding';           //CrowdFunding status
        ended = false;                //not ended  
        numInvestors = 0;             //defaut investors
        totalAmount = 0;              //defaut amount
     }
     
     // Launch the action with fund()
     function fund() payable public{ 
         // so long not finished
         require(!ended);     // not ended (is able to pay)
         
         // Increment ach time when the function is successfully activated
         Investor storage inv = investors[numInvestors++];      //storage: can't be change
         inv.addr = msg.sender;                                 //catch investor's address
         inv.amount = msg.value;                                //catch investor's amount
         totalAmount += inv.amount;                             //totalAmount = totalAmount + inv.amount
     }
     
     // Check whether the goal is reached
     function checkGoalReached() public onlyOwner{
         // Time and condition to check
         require(!ended);       //status: not ended
         require(now >= deadline);      
         
         // All money will be given to contract owner
         if (totalAmount >= goalAmount) {    //reach the goal
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
                 if (!investors[j].addr.send(investors[j].amount)){ //loop through all the investor's address in investers[]
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