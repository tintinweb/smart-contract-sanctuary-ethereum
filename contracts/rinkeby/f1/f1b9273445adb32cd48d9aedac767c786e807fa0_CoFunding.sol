/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: GPL-3.0
// 创建不同的集资活动，用来募集加密货币
// 记录不同集资活动的详细信息（参与人数，地址列表、每个用户的集资数量、募集的加密货币总数）
// 业务逻辑（用户参与投资、创建新的集资活动、活动后的资金提取、集资失败情况下的退款活动）
pragma solidity >=0.7.0 <0.9.0;

// 模板集资合约
contract CoFunding{

    // 集资者信息结构体
    struct Funder{
        address addr;  // 集资者的地址
        uint amount;  // 当前地址总投资数
    }

    // 定义集资活动结构体
    struct CofundingCampaign{
        address payable reciver;  // 基金的提款账户
        uint fundingGoal;  // 目标集资数量
        uint totalAmount;  // 目前已经募集到的资金数
        Funder[] funderList;  // 集资活动参与者列表
        uint funderIndex;  // 参与者列表索引
        mapping(address => uint) funderIndexMap;  // 地址到索引的映射
        mapping(address => bool) isParticipated; // 某个地址是否参与本次集资活动的映射表 
    }

    uint public campaignIndex;  // 集资活动的索引 
    mapping(uint => CofundingCampaign) public coFundingMap;  // 集资活动的映射表

}


contract  RaiseFunding is CoFunding{

    address public immutable owner;

    // 定义一个创建集资活动的事件
    event NewCampaign(address  payable indexed _receiver, uint indexed _goal);

    // 存款事件
    event Deposit(uint indexed _campaingnIndex, address indexed _addr, uint  amount);

    // 取款事件
    event Withdraw(uint indexed _campaingnIndex, uint amount);

    constructor(){
        owner = msg.sender;
    }

    // 每个地址只允许存款一次
    modifier onlyonce(uint _campaignID){
        require(coFundingMap[_campaignID].isParticipated[msg.sender] == false, "Address has disdeposited");
        _;
    }

    modifier onlyowner{
        require(owner == msg.sender, "address isnt owner");
        _;
    }

    // 集资活动必须事先存在
    modifier notNULL(uint _campaignID){
        require(coFundingMap[_campaignID].reciver != address(0), "NULL Campaign");
        _;
    }

    // 新建集资活动
    function newCampaign(address payable _receiver, uint _goal) external onlyowner returns(uint campaingnID){
        uint  _index = campaignIndex; 
        CofundingCampaign storage cfc = coFundingMap[_index];  // cfc 相当于按引用传递
        cfc.reciver = _receiver;
        cfc.fundingGoal = _goal;
        campaignIndex++;
        emit NewCampaign(_receiver, _goal);
        return _index;
    }

    // 存款函数, 每个地址只能存款一次
    function deposit(uint _campaingnIndex) external payable notNULL( _campaingnIndex) onlyonce(_campaingnIndex) returns(uint _index){
        CofundingCampaign storage cfc = coFundingMap[_campaingnIndex];
        cfc.totalAmount += msg.value;  
        cfc.funderList.push(Funder({  // 添加集资者信息
            addr: msg.sender,
            amount: msg.value
        }));
        cfc.isParticipated[msg.sender] = true;  // 将当前地址放入参与者列表
        uint index = cfc.funderIndex;
        cfc.funderIndex++;

        emit Deposit(_campaingnIndex, msg.sender, msg.value);
        return index;
    }

    // 拿到某次集资活动中，某个地址的索引
    function getFunderIndex(uint _campaignIndex, address _addr)internal view notNULL( _campaignIndex) returns(uint _index){
        return coFundingMap[_campaignIndex].funderIndexMap[_addr];
    }

    // 获取地址的存款信息
    function getFunderInfo(uint _campaignIndex)internal view notNULL( _campaignIndex) returns(uint _amount){
        CofundingCampaign storage cfc = coFundingMap[_campaignIndex];       
        uint index = cfc.funderIndexMap[msg.sender];
        return cfc.funderList[index].amount;
    }

    // 提款函数,返回时间状态，成功提款返回true
    function withdraw(uint _campaingnIndex)external  returns(bool){
        CofundingCampaign storage cfc = coFundingMap[_campaingnIndex];
        require(cfc.reciver == msg.sender, "you are not receiver");
        if(cfc.totalAmount < cfc.fundingGoal){
            return false;
        }
        uint amount = cfc.totalAmount;
        cfc.totalAmount = 0;
        cfc.reciver.transfer(amount);  // 将钱转给reciver
        emit Withdraw(_campaingnIndex, amount);
        return true;
    }

}