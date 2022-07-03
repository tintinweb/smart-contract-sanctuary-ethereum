/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

//创建不同的募资活动，用来募集以太坊
//记录相应活动下的 募资总体信息（参与人数、募集的以太数量）、以及记录参与的用户地址以及投入的数量


//以下的状态变量是永久存储在链上的  如果涉及写数据的话 gas消耗很高
//改为临时变量则gas消耗会变低
//只有状态变量可以用mapping类型

//Solidity支持多继承


//业务逻辑：（用户参与，添加新的活动，活动结束后进行资金领取）
pragma solidity 0.8.11;


//继承----用于变量储存
contract CrowdFundingStorge {
     struct Campaign {
        address payable receiver;

        uint numFunders; //募集的人数
        uint fundingGoal; //目标募集的以太数量
        uint totalAmount; //目前募集到的以太数量
    }

    struct Funder {
        address addr;
        uint amount;
    }

    uint public numCapaigns; //从0开始作为活动的编号，就是key，索引募集活动的信息
    mapping(uint => Campaign) campaigns;//结构体可以作为ValueType存在
    mapping(uint => Funder[]) funders;//数组作为ValueType存在

    mapping(uint => mapping(address => bool)) public isParticipate;
}





contract CrowdFunding is CrowdFundingStorge { //继承
    address  immutable owner; //owner才能创建活动

    constructor () {
        owner = msg.sender;
    }

    modifier judgeParticipate(uint campingID) {//用户重复性检查
        require(isParticipate[campingID][msg.sender] == false);
        _;//revert
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;//revert

    }

//storage类型 -> 状态变量 -> 可以写到mapping里
    function newCampaign(address payable receiver, uint goal) external isOwner() returns(uint campaignID) {
        campaignID = numCapaigns++; 
        Campaign storage c = campaigns[campaignID];
        c.receiver = receiver;
        c.fundingGoal = goal;
    }


    function bid(uint campingID) external payable { //一个用户 一个募资活动只能参与一次
        Campaign storage c = campaigns[campingID];

        c.totalAmount += msg.value;
        c.numFunders += 1;

        funders[campingID].push(Funder({
            addr: msg.sender,
            amount : msg.value
        }));

        isParticipate[campingID][msg.sender] = true; //为用户上锁，使得用户不能再参与该活动
    }


    function withdraw(uint campingID) external returns(bool reached) {
        Campaign storage c= campaigns[campingID];

        if(c.totalAmount < c.fundingGoal) {
            return false;
        }

        uint amount = c.totalAmount;
        c.totalAmount = 0;   //以免资金重复提取
        c.receiver.transfer(amount);  //receiver带有payable的修饰符 才能用transfer的方法

        return true;
    }


    


}