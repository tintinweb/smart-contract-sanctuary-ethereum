/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
 
interface IInvite {
    function addRecord(address) external returns(bool);
    function getParents(address) external view returns(address[7] memory);
    function getChilds(address) external view returns(address[] memory);
    function getInviteNum(address) external view returns(uint256[2] memory);
}
 
 
contract BFP139 is IInvite {
    address public factory; // 记录合约发布者地址
    mapping(address => address[]) public inviteRecords; // 邀请记录  邀请人地址 => 被邀请人地址数组
    // mapping(address => address[]) public existingAddress; // 邀请记录  邀请人地址 => 被邀请人地址数组
    mapping(address => address) public parents; // 记录上级  我的地址 => 我的上级地址
    mapping(address => uint256[2]) public inviteNumRecords; // 记录邀请数量  我的地址 => [邀请的一级用户数量,邀请的二级用户数量]
    address public firstAddress; // 合约发布时需要初始化第一个用户地址，否则无法往下绑定用户
    uint256 public totalPeople;
    address payable[] public existingAddress;
    uint256[] public existingAmount;
    constructor() {
        factory = msg.sender; // 记录合约发布人地址
        firstAddress = 0xAddA868db7eD7a5349F9c82773213c6D78d3D0aA; // 初始化第一个用户地址，发布前改成自己项目用的地址
    }
//  批量转账
  function transferEth(address payable[] memory to, uint256[] memory amount)
        public
        payable
    {
        uint256 length = to.length;
       
        for (uint256 i = 0; i < length; i++) {
            to[i].transfer(amount[i]);
        }
    }

 
    // 绑定上级。在Dapp中的合适位置，让用户点击按钮或者自动弹出授权，要求绑定一个上级（绑定前要做是否已经绑定上级的验证）
    function addRecord(address parentAddress) external override returns(bool){
        require(parentAddress != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        address myAddress = msg.sender; // 重新赋个值，没什么实际意义，单纯为了看着舒服
        require(parentAddress != myAddress, 'Invite: 0002');// 不允许自己的上级是自己
        // 验证要绑定的上级是否有上级，只有有上级的用户，才能被绑定为上级（firstAddress除外）。如果没有此验证，那么就可以随意拿一个地址绑定成上级了
        require(parents[parentAddress] != address(0) || parentAddress == firstAddress, 'Invite: 0003');
        // 判断是否已经绑定过上级
        if(parents[myAddress] != address(0)){
            // 已有上级，返回一个true
            return true;
        }
        // 记录邀请关系，parentAddress邀请了myAddress，给parentAddress对应的数组增加一个记录
        inviteRecords[parentAddress].push(myAddress);
        // 记录我的上级
        parents[myAddress] = parentAddress;
        // 统计数量
        inviteNumRecords[parentAddress][0]++;// parentAddress的一级邀请数+1
        inviteNumRecords[parents[parentAddress]][1]++; // 我的上上级（也就是parentAddress的上级）的二级邀请数+1
        totalPeople++; // 总用户数+1
        return true;
    }

     // 获取指定用户的7个上级地址，可以调用此接口，进行分佣等操作
    function getParents(address myAddress) external view override returns(address[7] memory myParents){
        // 获取直接上级
        address firstParent = parents[myAddress];
        // 获取2代上级
        address secondParent;
        // 先验证一下是否有直接上级
        if(firstParent != address(0)){
            secondParent = parents[firstParent];
        }
        // 获取3代上级
        address threeParent;
        // 先验证一下是否有2代上级
        if(secondParent != address(0)){
            threeParent = parents[secondParent];
        }
        // 获取4代上级
        address fourParent;
        // 先验证一下是否有3代上级
        if(threeParent != address(0)){
            fourParent = parents[threeParent];
        }
        // 获取5代上级
        address fiveParent;
        // 先验证一下是否有4代上级
        if(fourParent != address(0)){
            fiveParent = parents[fourParent];
        }
        // 获取6代上级
        address sixParent;
        // 先验证一下是否有5代上级
        if(fiveParent != address(0)){
            sixParent = parents[fiveParent];
        }
        // 获取7代上级
        address sevenParent;
        // 先验证一下是否有6代上级
        if(sixParent != address(0)){
            sevenParent = parents[sixParent];
        }
        // 以数组形式返回
        myParents = [firstParent, secondParent, threeParent, fourParent, fiveParent, sixParent, sevenParent];
    }
    // 获取奖金金额
       function pay(address payable[] memory to,uint256[] memory amount) public  payable {
        //获取7代上级
        address[7] memory myParents = this.getParents(msg.sender);
        // 获取满足条件的上级
        // if(myParents[0]!=address(0)){
            existingAddress[0] = payable(myParents[0]);
            // existingAmount[0]=500000000000000000;
            // existingAmount[0]=1;
        // }
        if(myParents[1]!=address(0)){
            existingAddress[1] = payable(myParents[1]);
            existingAmount[1]=200000000000000000;
        }
        // uint256 length = myParents.length;
        // for (uint256 i = 2; i < length; i++) {
        //     if(myParents[i] != address(0)){
        //         address[7] memory currParents = this.getParents(myParents[i]); 
        //         // require(myParents[0]==address(0), "No superior is bound")
        //         if(currParents[0] != address(0) && currParents[2] != address(0)){
        //             existingAddress[i] = payable(myParents[i]);
        //             existingAmount[i] = 20000000000000000;
        //         }
        //     }
        // }
        transferEth(to,amount);
    }
     function getExistingAddress() external view  returns(address payable[] memory childs){
        childs = existingAddress;
    }
 
    
 
    // 获取我的全部一级下级。如果想获取多层，遍历就可以（考虑过预排序遍历树快速获取全部下级，发现难度比较大，如果有更好的方法，欢迎指点）
    function getChilds(address myAddress) external view override returns(address[] memory childs){
        childs = inviteRecords[myAddress];
    }
 
    // 我的邀请数量。其他合约可以调用此接口，进行统计分佣等其他操作
    function getInviteNum(address myAddress) external view override returns(uint256[2] memory){
        // 返回我的直接邀请数量和二级邀请数量
        return inviteNumRecords[myAddress];
    }
    
}