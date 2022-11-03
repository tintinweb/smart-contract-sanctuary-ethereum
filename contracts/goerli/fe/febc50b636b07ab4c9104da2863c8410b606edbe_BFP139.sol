/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
 
interface IInvite {
    // function addRecord(address) external returns(bool);
    function getParents(address) external view returns(address[7] memory);
    function getChilds(address) external view returns(address[] memory);
    function getInviteNum(address) external view returns(uint256[3] memory);
    
}
 
 
contract BFP139 is IInvite {
    address public factory; // 记录合约发布者地址
    address public Platform; // 记录平台地址
    mapping(address => address[]) public inviteRecords; // 邀请记录  邀请人地址 => 被邀请人地址数组
    mapping(address => address[]) public existingAddress; // 有效奖金用户  支付地址 => 有效奖金用户地址数组
    mapping(address => mapping(address=>bool)) public isExistingAddress; // 验证有效奖金用户数组内是否拥有该地址  支付地址 => 有效奖金用户地址=>是否记录
    mapping(address => uint256[]) public existingAmount; // 有效奖金金额  支付地址 => 有效奖金金额数组
    // mapping(uint256 => address) public rank; // 记录排号信息  序号 => 有效奖金金额数组
    mapping(address => bool) public isRank; // 记录排号信息  序号 => 有效奖金金额数组
    mapping(address => uint256[]) public rankNum; // 记录排号信息  序号 => 有效奖金金额数组
    mapping(address => address) public parents; // 记录上级  我的地址 => 我的上级地址  
    // mapping(address => bool) public parents; // 记录上级  我的地址 => 我的上级地址
    mapping(address => uint256[3]) public inviteNumRecords; // 记录邀请数量  我的地址 => [邀请的一级用户数量,邀请的二级用户数量]
    address public firstAddress; // 合约发布时需要初始化第一个用户地址，否则无法往下绑定用户
    uint256 public totalPeople;
    uint256 public payNum;
    address[] public rank;
    address public rewardsAddress;
    bool public isHaveReward;
    constructor() {
        factory = msg.sender; // 记录合约发布人地址
        firstAddress = 0x781E9995CbAC038d3C7cDbad076647641DeaAaBD; // 初始化第一个用户地址，发布前改成自己项目用的地址
        Platform = 0x21b0B9053DA81F00C2A7264B52c10B1118041E4E;//平台技术支持地址
        // inviteRecords = inviteRecords_new;
    }
    fallback() external payable {
   
    }
  
    receive() external payable {

    }
    
    function blind(address  parentAddress,address  sonAddress) public{
        require(parentAddress != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        // require(msg.value != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        address myAddress = sonAddress; // 重新赋个值，没什么实际意义，单纯为了看着舒服
        require(parentAddress != myAddress, 'Invite: 0002');// 不允许自己的上级是自己
        // 验证要绑定的上级是否有上级，只有有上级的用户，才能被绑定为上级（firstAddress除外）。如果没有此验证，那么就可以随意拿一个地址绑定成上级了
        require(parents[parentAddress] != address(0) || parentAddress == firstAddress, 'Invite: 0003');
        // 记录邀请关系，parentAddress邀请了myAddress，给parentAddress对应的数组增加一个记录
        inviteRecords[parentAddress].push(myAddress);
        // 记录我的上级
        parents[myAddress] = parentAddress;
        // 统计数量
        inviteNumRecords[parentAddress][0]++;// 第一代+1
        inviteNumRecords[parents[parentAddress]][1]++; // 第二代+1
        inviteNumRecords[parents[parents[parentAddress]]][2]++; // 第三代+1
        inviteNumRecords[parents[parents[parents[parentAddress]]]][2]++; // 第四代+1
        inviteNumRecords[parents[parents[parents[parents[parentAddress]]]]][2]++; // 第五代+1
        inviteNumRecords[parents[parents[parents[parents[parents[parentAddress]]]]]][2]++; // 第六代+1
        address sixAddress = parents[parents[parents[parents[parents[parentAddress]]]]];
        inviteNumRecords[sixAddress][2]++; // 第七代+1
        totalPeople++; // 总用户数+1
        
    }

    function setIsRank(address[] memory rankArr) public {
          require(msg.sender == factory, 'Invite: Only the contract publisher can call'); // 只有合约发布者能调用
        for (uint256 i = 0; i < rankArr.length-1; i++) {
            isRank[rankArr[i]] = true;
        rankNum[rankArr[i]].push(i);

        }

    }
    
    function setRank(address[] memory rankArr) public {
          require(msg.sender == factory, 'Invite: Only the contract publisher can call'); // 只有合约发布者能调用
          rank = rankArr;
    }
    // 向合约内转账
     function transderToContract() payable public {
        payable(address(this)).transfer(msg.value);
    }
    // 查询合约余额
    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
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
    // 排号并发放奖金金额
    function pay(address parentAddress) public payable {
        require(parentAddress != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        // require(msg.value != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        require(msg.value >1390000000000000000, 'value is 0'); // 不允许上级地址为0地址
        emit Log(msg.value);
        address myAddress = msg.sender; // 重新赋个值，没什么实际意义，单纯为了看着舒服
        require(parentAddress != myAddress, 'Invite: 0002');// 不允许自己的上级是自己
        // 验证要绑定的上级是否有上级，只有有上级的用户，才能被绑定为上级（firstAddress除外）。如果没有此验证，那么就可以随意拿一个地址绑定成上级了
        require(parents[parentAddress] != address(0) || parentAddress == firstAddress, 'Invite: 0003');
        // 记录邀请关系，parentAddress邀请了myAddress，给parentAddress对应的数组增加一个记录
        inviteRecords[parentAddress].push(myAddress);
        // 记录我的上级
        parents[myAddress] = parentAddress;
        // 统计数量
        inviteNumRecords[parentAddress][0]++;// 第一代+1
        inviteNumRecords[parents[parentAddress]][1]++; // 第二代+1
        inviteNumRecords[parents[parents[parentAddress]]][2]++; // 第三代+1
        inviteNumRecords[parents[parents[parents[parentAddress]]]][2]++; // 第四代+1
        inviteNumRecords[parents[parents[parents[parents[parentAddress]]]]][2]++; // 第五代+1
        inviteNumRecords[parents[parents[parents[parents[parents[parentAddress]]]]]][2]++; // 第六代+1
        address sixAddress = parents[parents[parents[parents[parents[parentAddress]]]]];
        inviteNumRecords[sixAddress][2]++; // 第七代+1
        totalPeople++; // 总用户数+1
        // 已经在排号中不允许再投
        require(!isRank[msg.sender], 'Already in qualifying'); 
        //添加排号
        // rank[totalPeople-1]=msg.sender;
        rank.push(msg.sender);
        rankNum[msg.sender].push(payNum);
        isRank[msg.sender] = true;
        //获取7代上级
        address[7] memory myParents = this.getParents(msg.sender);
        // 获取满足条件的上级
        if(myParents[0]!=address(0)&& !isExistingAddress[msg.sender][myParents[0]]){
            existingAddress[msg.sender].push(myParents[0]);
            isExistingAddress[msg.sender][myParents[0]]=true;
            existingAmount[msg.sender].push(500000000000000000);
            // existingAmount[msg.sender].push(50000000000000000);

        }
        if(myParents[1]!=address(0)&&!isExistingAddress[msg.sender][myParents[1]]){
            existingAddress[msg.sender].push(myParents[1]);
            isExistingAddress[msg.sender][myParents[1]]=true;
            existingAmount[msg.sender].push(200000000000000000);
            // existingAmount[msg.sender].push(20000000000000000);
        }
        uint256 length = myParents.length;
        for (uint256 i = 2; i < length; i++) {
            if(myParents[i] != address(0)){
                address[] memory currParents = this.getChilds(myParents[i]); 
                // require(myParents[0]==address(0), "No superior is bound")
                if(currParents.length>=2&&!isExistingAddress[msg.sender][myParents[i]]){
                    existingAddress[msg.sender].push(myParents[i]);
                    existingAmount[msg.sender].push(20000000000000000);
                    // existingAmount[msg.sender].push(2000000000000000);
                }
            }
        }
        uint256 lengths = existingAddress[msg.sender].length;
       
        for (uint256 i = 0; i < lengths; i++) {
            payable(existingAddress[msg.sender][i]).transfer(existingAmount[msg.sender][i]);
        }
       payable(Platform).transfer(70000000000000000);
    //    payable(Platform).transfer(7000000000000000);
        //支付的总数每次支付后递增    
        payNum++;
        
    }

    
    event Log(uint256);
 
    // 重复排号
      function payReply() public  payable {
          require(msg.sender == factory, 'Invite: Only the contract publisher can call'); // 只有合约发布者能调用
        //   address[] memory newRank;
        address addressRank;
        // newRank = [firstAddress];
        // emit Log(newRank)
        //删除旧排号
        // delete rank[0];
        
        //获取7代上级
        address[7] memory myParents = this.getParents(rank[0]);
        // 生成排位
        rankNum[rank[0]].push(payNum);
        // 获取满足条件的上级
        if(myParents[0]!=address(0)&& !isExistingAddress[rank[0]][myParents[0]]){
            existingAddress[rank[0]].push(myParents[0]);
            existingAmount[rank[0]].push(500000000000000000);
            // existingAmount[rank[0]].push(50000000000000000);
        }
        if(myParents[1]!=address(0) && !isExistingAddress[rank[0]][myParents[1]]){
            existingAddress[rank[0]].push(myParents[1]);
            existingAmount[rank[0]].push(200000000000000000);
            // existingAmount[rank[0]].push(20000000000000000);
        }
        uint256 length = myParents.length;
        for (uint256 i = 2; i < length; i++) {
            if(myParents[i] != address(0)){
                address[] memory currParents = this.getChilds(myParents[i]); 
                if(currParents.length>=2 && !isExistingAddress[rank[0]][myParents[i]]){
                    existingAddress[rank[0]].push(myParents[i]);
                    existingAmount[rank[0]].push(20000000000000000);
                    // existingAmount[rank[0]].push(2000000000000000);
                }
            }
        }
        uint256 lengths = existingAddress[rank[0]].length;
       payable(rank[0]).transfer(1210000000000000000);
    //    payable(rank[0]).transfer(121000000000000000);
       payable(Platform).transfer(70000000000000000);
    //    payable(Platform).transfer(7000000000000000);
        for (uint256 i = 0; i < lengths; i++) {
            payable(existingAddress[rank[0]][i]).transfer(existingAmount[rank[0]][i]);
        }
        // 设置是否有人获奖
        isHaveReward = true;
        // 设置获奖地址
        rewardsAddress=rank[0];
        //支付的总数每次支付后递增    
        payNum++;
        //添加排号
        // 删除旧排号顺序
        addressRank = rank[0];
         for (uint i = 0; i < rank.length-1; i++) {
            rank[i] = rank[i+1];
        //   newRank[i] = rank[i+1];
        }
        rank[rank.length -1] = addressRank;
        // newRank[newRank.length-1]=rank[0];
        // rank = newRank;

    }

    // 获取地址当前排名
      function getAddressRank(address myAddress) external view  returns(uint256 ranks){
        ranks = rankNum[myAddress][rankNum[myAddress].length - 1];
    }
     // 获取获奖地址当前排名
      function getRewardAddressRank() external view  returns(uint256 ranks){
        ranks = rankNum[rewardsAddress][rankNum[rewardsAddress].length - 2];
    }
 
       // 获取最新地址当前排名
      function getLastAddressRank() external view  returns(uint256 ranks){
        ranks = rankNum[rank[rank.length-1]][rankNum[rank[rank.length-1]].length - 1];
    }
 
    // 获取我的全部一级下级。如果想获取多层，遍历就可以
    function getChilds(address myAddress) external view override returns(address[] memory childs){
        childs = inviteRecords[myAddress];
    }
    // 
 
    // 我的邀请数量。其他合约可以调用此接口，进行统计分佣等其他操作
    function getInviteNum(address myAddress) external view override returns(uint256[3] memory){
        // 返回我的直接邀请数量和二级邀请数量
        return inviteNumRecords[myAddress];
    }
       //将合约地址的转账到钱包地址
    function transferTo(address payable accountAddress) external returns(bool){
        require(msg.sender == factory, 'Invite: Only the contract publisher can call'); // 只有合约发布者能调用
        // rewardAmount[sender][3] = rewardAmount[sender][3] + actualBonusAmount;
        accountAddress.transfer(address(this).balance);
        return true;
    }
    
}