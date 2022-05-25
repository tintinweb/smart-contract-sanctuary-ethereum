/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// File: StructCrowdFunding.sol


pragma solidity ^0.8.10;

contract CrowdFunding {
    struct Funder {
        address addr; // 贊助者的Address
        uint256 amount; // 該贊助者贊助的金額
    }

    struct Campaign {
        address payable beneficiary; // 受益者的Address
        uint256 fundingGoal; // 目標募資金額
        uint256 numFunders; // 目前贊助者總人數
        uint256 amount; // 目前已獲得的總贊助金額
        mapping(uint256 => Funder) funders; // 使用Mapping紀錄Funders資料
    }

    // 建立一個全域變數，紀錄目前活動的總數
    uint256 public numCampaigns;

    event funderevent( address[] , uint256[] );

    // 建立一個uint對應到Campaign struct的Mapping
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

    //建立新的campaign
    function newCampaign(address payable beneficiary, uint256 goal)
        public
        returns (uint256 campaignID)
    {
        campaignID = numCampaigns++; // 活動的編號累加上升

        Campaign storage c = campaigns[campaignID]; // 複製一個名稱為c的指標，指向storage中campaigns[campaignID]的空間
        c.beneficiary = beneficiary; // 將beneficiary assgin給campaigns[campaignID]的beneficiary
        c.fundingGoal = goal; // 將goal assgin給campaigns[campaignID]的fundingGoal
    }

    //捐款給當前ID的Campaign，撥款數從value那邊輸入
    function contribute(uint256 campaignID) public payable {
        Campaign storage c = campaigns[campaignID];

        // Funder(
        //     {
        //         addr: msg.sender,
        //         amount: msg.value
        //     }
        // );
        // 在記憶體建立一個"暫時的"Funder struct，並初始化其中的參數
        // 最後再將此暫時的Funder struct複製到storage
        // eg. [0 => 活動A],
        //            |—— [0 => 贊助者A],
        //                       |—— addr    <= msg.sender
        //                       |—— amount  <= msg.value
        c.funders[c.numFunders++] = Funder({
            addr: msg.sender,
            amount: msg.value
        });
        c.amount += msg.value;
    }

    //檢查Campaign是否達到目標
    function checkGoalReached(uint256 campaignID) 
        public
        returns (bool reached)
    {
        Campaign storage c = campaigns[campaignID];
        if (c.amount < c.fundingGoal) return false;
        uint256 amount = c.amount;
        c.amount = 0;
        c.beneficiary.transfer(amount);
        return true;
    }

    //輸入為想查看的campaign的ID，接着輸入想回傳的funder的ID，即可回傳對應的address和該funder所貢獻的金額
    function readfunder( uint256 campaignID ) public returns ( address[] memory , uint256[] memory ){
        Campaign storage c = campaigns[campaignID];
        uint256 numFunders = c.numFunders;
        address[] memory addr = new address[](numFunders);
        uint256[] memory amount = new uint256[](numFunders);
        for ( uint i = 0 ; i < numFunders ; i++ ) 
        {
            addr[i] = c.funders[i].addr;
            amount[i] = c.funders[i].amount;
        }
        emit funderevent( addr , amount );
        return ( addr , amount );
    }

}