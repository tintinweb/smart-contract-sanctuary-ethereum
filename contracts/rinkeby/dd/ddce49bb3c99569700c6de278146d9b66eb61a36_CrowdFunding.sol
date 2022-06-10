/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

//CrowdFunding.sol

pragma solidity >= 0.5.0 <0.6.0;

contract CrowdFunding{
     
     // define investor, note that no NAME
     struct Investor{
         address payable addr;  //可以付錢，投資人地址：patable
         uint amount;  //付了多少錢
     }
     
     address payable public owner;          // Issuer of the contract 把錢取走
     uint public numInvestors;      // Number of investors 有多少人來
     uint public deadline;          // Deadline of investment in UNIX Time 什麼時候結束
     string public status;          // status of crowdfundinng  狀態如何（額滿等）
     bool public ended;             // Is crowdfunding ended? Y?N 結束
     uint public goalAmount;        // Target of crowdfunding 總數募款多少錢
     uint public totalAmount;       // Actual amount gathered 總共多少
     
     mapping(uint => Investor) public investors; // Managing investors 
     //付款大於0就是投資者
     //管理會不會加一，且付款金額必須正確
     
     // Specifying that the issuer is the only contract owner
     modifier onlyOwner () { //
         require (msg.sender == owner);
         _; //不做任何事情
     }
     
     // Initialization with cnstructor
     constructor(uint _duration, uint _goalAmount) public { //建構值，定義兩個參數 目的：讓程式初始化
        owner = msg.sender;//誰部署合約
        deadline = now + _duration;   //set UNIX time 現在的時間＋到期
        goalAmount = _goalAmount;
        status = 'Funding';//目前狀態：募資中
        ended = false;
        numInvestors = 0;
        totalAmount = 0;//目前金額
     }
     
     // Launch the action with fund() 對出宣告要募款
     function fund() payable public{  //
         // so long not finished
         require(!ended); //不是ended
         
         // Increment ach time when the function is successfully activated存在硬碟，不可以被改變的
         Investor storage inv = investors[numInvestors++];//變數：inv，數量加一
         inv.addr = msg.sender;//從你的地址送過來
         inv.amount = msg.value;//送過來的值放在amount
         totalAmount += inv.amount;//累積的投資額，新的投資者的錢加進去
     }
     
     // Check whether the goal is reached
     function checkGoalReached() public onlyOwner{ //檢查目標到達了沒？
         // Time and condition to check
         require(!ended);//必須是true
         require(now >= deadline);//現在的時間超過deadline
         
         // All money will be given to contract owner
         if (totalAmount >= goalAmount) { //如果募資的錢>=目標的時候
             status =" Funding succeeded"; //結束
             ended = true;  // In case successful funding 變成true
              if (!owner.send(address(this).balance)){ //誰可以取錢
                  revert(); //guarantee successful transfer //如果不是本人取錢，就駁回
              }
         } else {  
             // in case timeout before the goal reached 時間還沒到
             
             status = 'Campaign failed'; //募款失敗
             ended = true;  // no more fund raising 宣告失敗
             
             // Give money back to all investors
             uint j = 0;  // running Number 退還給多少人的錢
             while(j < numInvestors){
                 // Send back the money he invested 錢退還給人家 
                 if (!investors[j].addr.send(investors[j].amount)){ //照地址把錢一個一個送回去
                     revert();//不成功
                 }
                 j++;
             }
             
         }
     }
     
     // Destroy the funding contract
     function kill() public onlyOwner{ //按kill，把smartcontract刪掉
         selfdestruct(owner);//把oener 地址給毀掉
     }
}