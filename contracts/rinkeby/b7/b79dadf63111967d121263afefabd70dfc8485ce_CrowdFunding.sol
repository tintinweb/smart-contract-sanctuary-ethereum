/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity >= 0.5.0 <0.6.0;

contract CrowdFunding{
     
     // define investor, note that no NAME
     struct Investor{
         address payable addr;  // 可付款的(付款地址，匿名性)
         uint amount;           // 付款多少錢
     }
     
     address payable public owner;          // Issuer of the contract(owner可取走錢)
     uint public numInvestors;      // Number of investors (募資人數)
     uint public deadline;          // Deadline of investment in UNIX Time (何時結束)
     string public status;          // status of crowdfundinng (狀態:到期、額滿...)
     bool public ended;             // Is crowdfunding ended? Y?N (到期結束)
     uint public goalAmount;        // Target of crowdfunding (總數募款金額)
     uint public totalAmount;       // Actual amount gathered (目前募資總額狀況)
     
     mapping(uint => Investor) public investors; // Managing investors (投資金額為正數(>0)即是投資者→合格才啟動Matamesk)
     
     // Specifying that the issuer is the only contract owner
     modifier onlyOwner () {
         require (msg.sender == owner); // 只有owner可取走錢
         _;
     }
     
     // Initialization with cnstructor (初始化)
     constructor(uint _duration, uint _goalAmount) public {   // 募資時間、募資金額
        owner = msg.sender; // 部屬合約者(owner)
        deadline = now + _duration;   //set UNIX time (現在的時間加上募資時間)
        goalAmount = _goalAmount; //
        status = 'Funding'; // 募資中
        ended = false;
        numInvestors = 0;
        totalAmount = 0; // 目前總金額
     }
     
     // Launch the action with fund()
     function fund() payable public{ 
         // so long not finished
         require(!ended);
         
         // Increment ach time when the function is successfully activated
         Investor storage inv = investors[numInvestors++]; // storage存在硬碟裡不可改變的
         inv.addr = msg.sender; 
         inv.amount = msg.value;
         totalAmount += inv.amount; // 加上新投資人的錢
     }
     
     // Check whether the goal is reached
     function checkGoalReached() public onlyOwner{
         // Time and condition to check
         require(!ended);  // 判斷募款金額到了沒
         require(now >= deadline);  // 判斷募資期限到了沒
         
         // All money will be given to contract owner
         if (totalAmount >= goalAmount) {
             status =" Funding succeeded";
             ended = true;  // In case successful funding
              if (!owner.send(address(this).balance)){  //看是否為本人去取錢
                  revert(); //guarantee successful transfer (不是本人去取錢→拒絕)
              }
         } else {  
             // in case timeout befor the goal reached
             
             status = 'Campaign failed';
             ended = true;  // no more fund raising
             
             // Give money back to all investors
             uint j = 0;  // running Number
             while(j < numInvestors){  //退還給的人
                 // Send back the money he invested
                 if (!investors[j].addr.send(investors[j].amount)){  // 錢→送回去原本位置
                     revert();
                 }
                 j++;
             }
             
         }
     }
     
     // Destroy the funding contract
     function kill() public onlyOwner{  // 合約結束
         selfdestruct(owner);
     }
}