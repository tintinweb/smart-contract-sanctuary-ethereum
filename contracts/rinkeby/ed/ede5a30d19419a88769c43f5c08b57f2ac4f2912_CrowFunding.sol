/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CrowFunding {
    struct Funder {
        address addr;  //贊助者的address
        uint256 amount;//該贊助者的金額    
    }

    struct Campaign {
        address payable beneficiary;  //贊助者的address
        uint256 fundingGoal;//目標募資金額    
        uint256 numFunders;//贊助者的總人數    
        uint256 amount;//已獲得的總贊助金額
        mapping(uint256 => Funder) funders; //使用mapping紀錄funders資料
    }

    //建立一個全域變數，紀錄目前活動的總數
    uint256 public numCampaigns; //0


    //建立一個uint對應到Camaign struct 的mapping
    /* eg. [0 => 活動A],
                 |—— beneficiary
                 |—— fundingGoal
                 |—— numFunders
                 |—— amount
                 |—— [0 => 贊助者A],      [1 => 贊助者B],      [2 => 贊助者C]
                            |—— addr            |—— addr             |—— addr
                            |—— amount          |—— amount           |—— amount
    */
    mapping(uint256 => Campaign) public campaigns;

    function newCampaign(address payable beneficiary, uint256 goal) public returns (uint256 campaignID) {

        campaignID = numCampaigns++;//活動的編號上升

        Campaign storage  c = campaigns[campaignID]; //複製一個名稱為c的指標，指向storage campaign中campaigns[campaignID]的空間
        c.beneficiary = beneficiary;//將beneficiary assign給campaigns[campaignID]的beneficiary
        c.fundingGoal = goal;//將goal assign給campaigns[campaignID]的fundingGoal
    }

    function contrubute(uint256 campaignID) public payable {
        Campaign storage  c = campaigns[campaignID];

        /*
            Funder(
                {
                    addr: msg.sender,
                    amount: msg.value
                }
            );
            在記憶體建立一個"暫時的"Funder struct，並初始化其中的參數
            最後再將此暫時的Funder struct複製到storage
            eg. [0 => 活動],
                | --[0 => 贊助者],
                        | --addr   <= msg.sender
                        | --amount <=msg.value
        */
        c.funders[c.numFunders++] = Funder(
            {
                addr: msg.sender,
                amount: msg.value
            }
        );

        c.amount += msg.value;
    }

    function checkGoalReached(uint256 campaignID) 
        public 
        returns (bool reached){
            Campaign storage  c = campaigns[campaignID];

            if(c.amount < c.fundingGoal) return false;

            uint256 amount = c.amount;
            c.amount = 0;
            c.beneficiary.transfer(amount);
            return true;
    }

    event useit(address funder,uint256 amount);

    function getTheFunders(uint256 campaignID, uint256 funderID) public returns (address funder,uint256 amount) {
        Campaign storage  c = campaigns[campaignID];
        funder = c.funders[funderID].addr;
        amount = c.funders[funderID].amount;
        emit useit(funder, amount);
    }

}