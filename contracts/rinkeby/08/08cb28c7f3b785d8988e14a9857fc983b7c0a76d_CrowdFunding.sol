/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT

//创建不同的募资活动，用来募集以太坊
//记录相应活动下的募资总体信息（参与人数，募集的以太坊数量），以及记录参与的用户地址以及投入的数量
//业务逻辑（用户参与、添加新的募集活动，活动结束后进行资金领取）

pragma solidity 0.8.11;

contract CrowdFunding {
    //合约创建人（谁来部署合约谁就是onwer）
    address immutable owner;

    /**
    * 募资活动
    */
    struct Campaign {
        //接收资金地址
        address payable receiver;
        //参与的用户的数量
        uint numFunders;
        //募集的目标
        uint fundingGoal;
        //当前已经募集的数量
        uint totalAmount;
    }

    /**
    * 记录参与用户的地址和操作数
    */
    struct Funder {
        //地址
        address addr;
        //投入的以太坊数量
        uint amount;
    }

    //活动数量
    uint public numCampagins;
    //k 活动编号， V 活动
    mapping(uint => Campaign) campagins;
    //K 活动编号， V 参与人
    mapping(uint => Funder[]) funders;

    //K1 活动编号， K2 参与人地址，V 是否已参与过
    mapping(uint => mapping(address => bool)) public isParticipate;

    //todo??????????????
    Campaign[] public campaignsArray;

    event CampaignLog(uint campaignID, address receiver, uint goal);

    constructor() {
        owner = msg.sender;
    }

    /**
    * 不允许重复参与
    */
    modifier judgeParticipate(uint campaignID) {
        require(isParticipate[campaignID][msg.sender] == false);
        _;  //表示上面语句执行通过，会执行函数内容
    }

    /**
    * 是否是合同创建人
    */
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    /** 
    * 创建新的募资活动
    */
    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignID) {
        //递增活动编号
        campaignID = numCampagins++;
        //
        Campaign storage c = campagins[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;

        // todo ???????????
        campaignsArray.push(c);
        emit CampaignLog(campaignID, receiver, goal);
    }

    /**
    * 用户参与
    */
    function bid(uint campaignID) external payable judgeParticipate(campaignID) {
        // campagins[campaignID] 表示创建一个以key=campaignID 的合约对象
        Campaign storage c = campagins[campaignID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campaignID].push(Funder({
            addr: msg.sender,   //当前调用的账户地址（合约or外部账户）
            amount: msg.value//,
            //data:msg.data
        }));

        isParticipate[campaignID][msg.sender] = true;
    }

    /**
    * 提款函数
    */
    function withdraw(uint campaignID) external returns(bool reached) {
        Campaign storage c = campagins[campaignID];

        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;
        //把募集的以太币转给receiver
        c.receiver.transfer(amount);

        return true;
    }

    /**
    * 提款hash
    */
    function getReceiver(uint campaignID) external view returns (address receiver) {
        Campaign storage c = campagins[campaignID];
        receiver = c.receiver; 
    }

}