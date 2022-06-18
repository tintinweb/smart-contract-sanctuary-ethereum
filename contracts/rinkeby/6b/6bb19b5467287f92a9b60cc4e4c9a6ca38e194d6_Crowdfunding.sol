/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: SimPL-3.0
pragma solidity ^0.7.0;

// 众筹智能合约
contract Crowdfunding{
    // 出资人
    struct Donor {
        address addr; //出资人地址
        uint amount; //出资人金额
    }
    
    // 募资人
    struct Donee {
        address addr; //募资人地址
        uint goal; //募资目标金额
        uint amount; //已筹集金额
        uint donorCount; //捐赠者数量
        bool status; //项目有效性：true 有效 false 无效
        mapping(uint => Donor) donorMap; //出资人字典
    }
    
    uint doneeCount;// 募资人数量
    mapping(uint => Donee) doneeMap; //募资人字典
    
    address payable owner; //合约拥有者

    // 构造函数
    constructor(){
        // 设置合约拥有者
        owner = msg.sender;
    }

    // 销毁合约
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }

    // 校验合约拥有者
    modifier onlyOwner() {
        // 判断函数调用者是否为owner
        require(msg.sender == owner);
        _;
    }

    // 校验募资项目ID合法性
    modifier validDonee(uint doneeID) {
        require(doneeID>0 && doneeID<=doneeCount);
        _;
    }

    // 设置募资人和募资金额
    function setDonee(address addr, uint goal) public onlyOwner{
        for(uint i=0;i<doneeCount;i++){
            Donee storage d = doneeMap[i+1];
            if(d.addr == addr){
                d.goal = goal;
                return;
            }
        }

        doneeCount++;
        Donee storage donee = doneeMap[doneeCount];
        donee.addr = addr;
        donee.goal = goal;
        donee.status = true;
    }
    
    // 出资人捐赠
    function donate(uint doneeID) public payable validDonee(doneeID){
        Donee storage donee = doneeMap[doneeID];
        require(donee.status);
    
        donee.donorCount++;
        donee.amount += msg.value;//出资人金额

        Donor storage donor = donee.donorMap[donee.donorCount];
        donor.addr = msg.sender;
        donor.amount = msg.value;
    }
    
    // 完成目标给募资人转账
    function transfer(uint doneeID) public payable onlyOwner validDonee(doneeID) {
        Donee storage donee = doneeMap[doneeID];
        if(donee.amount >= donee.goal){
            // 给募资人转账
            payable(donee.addr).transfer(donee.goal);
        } else {
            // 金额不足
            revert();
        }
    }
    
    // 合约转账到拥有者
    function withdraw() public payable onlyOwner{
        msg.sender.transfer(address(this).balance);
    }

    // 查询募资人数量
    function getDoneeCount() public view returns(uint) {
        return doneeCount;
    }

    // 获取募资人信息
    function getDonee(uint doneeID) public view returns(address doneeAddr,uint doneeGoal,uint doneeAmount){
        return (doneeMap[doneeID].addr,doneeMap[doneeID].goal,doneeMap[doneeID].amount);
    }

    // 获取合约余额
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 设定项目状态是否有效
   function setStatus(uint doneeID, bool status) public onlyOwner {
        Donee storage donee = doneeMap[doneeID];
        donee.status = status;
    }

    // 获取项目状态
    function getStatus(uint doneeID) public view validDonee(doneeID) returns(bool) {
        Donee storage donee = doneeMap[doneeID];
        return donee.status;
    }

    fallback() external{
    }

    receive() payable external{
    }
}