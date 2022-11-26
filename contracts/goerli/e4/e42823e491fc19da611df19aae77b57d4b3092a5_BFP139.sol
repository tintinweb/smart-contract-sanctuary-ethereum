/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

pragma solidity >=0.8.0;

interface IInvite {
    function getParents(address) external view returns(address[6] memory);
    function getChilds(address) external view returns(address[] memory);
    function getInviteNum(address) external view returns(uint256[3] memory);
}
 
contract BFP139 is IInvite {
    address public factory; // 记录合约发布者地址
    address public Platform; // 记录平台地址
    address public reInvestmentCollectionaddress; // 复投归集地址
    mapping(address => bool) public whiteList;//白名单地址
    mapping(address => bool) public revoteWhiteList;//复投白名单地址
    mapping(address => uint256) public remainNumberRerolls;//剩余复投次数
    mapping(address => address[]) public inviteRecords; // 邀请记录  邀请人地址 => 被邀请人地址数组
    mapping(address => address[]) public existingAddress; // 有效奖金用户  支付地址 => 有效奖金用户地址数组
    mapping(address => mapping(address=>bool)) public isExistingAddress; // 验证有效奖金用户数组内是否拥有该地址  支付地址 => 有效奖金用户地址=>是否记录
    mapping(address => uint256[]) public existingAmount; // 有效奖金金额  支付地址 => 有效奖金金额数组
    mapping(address => bool) public isRank; // 记录排号信息  序号 => 有效奖金金额数组
    mapping(address => uint256[]) public rankNum; // 记录排号信息  序号 => 有效奖金金额数组
    mapping(address => address) public parents; // 记录上级  我的地址 => 我的上级地址  
    mapping(address => uint256[3]) public inviteNumRecords; // 记录邀请数量  我的地址 => [邀请的一级用户数量,邀请的二级用户数量]
    address public firstAddress; // 合约发布时需要初始化第一个用户地址，否则无法往下绑定用户
    uint256 public totalPeople;
    uint256 public payNum;
    address[] public rank;
    address public rewardsAddress;
    bool public isHaveReward;
    /**
    * @dev 调用者不是‘主人’，就会抛出异常
    */
    modifier onlyOwner(){
        require(msg.sender == factory,'Invite: Only the contract publisher can call');
        _;
    }
    
    constructor() {
        factory = msg.sender; // 记录合约发布人地址
        firstAddress = 0x781E9995CbAC038d3C7cDbad076647641DeaAaBD; // 初始化第一个用户地址，发布前改成自己项目用的地址
        Platform = 0x77f2bB93998553A867771DBa51205a99f31f4520;//平台技术支持地址
        reInvestmentCollectionaddress = 0x673Db7C0C3c05Df8A40ee545907c27952D321031;//复投归集地址
    }
    fallback() external payable {
   
    }
  
    receive() external payable {

    }

    function blind(address  parentAddress,address  sonAddress) public onlyOwner{
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
        //初始复投次数
        remainNumberRerolls[myAddress]+=5;//复投次数+5
        //标识地址
        address markAddress = parentAddress;
        //第一代
        uint256 directPushesNumber1 = inviteNumRecords[markAddress][0] + 1;// 获取直接邀请数量
        updateAddressData(markAddress,0,directPushesNumber1);

        //第二代
        markAddress = parents[markAddress];
        uint256 directPushesNumber2 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber2 + directPushesNumber1);
        
        //第三代
        markAddress = parents[markAddress];
        uint256 directPushesNumber3 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        //第四代
        markAddress = parents[markAddress];
        uint256 directPushesNumber4 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber4 + directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        //第五代
        markAddress = parents[markAddress];
        uint256 directPushesNumber5 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber5 + directPushesNumber4 + directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        //第六代
        markAddress = parents[markAddress];
        uint256 directPushesNumber6 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber6 + directPushesNumber5 + directPushesNumber4 + directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        totalPeople++; // 总用户数+1
    }

    /**
    *   更新直推人数、复投次数、复投白名单
    */
    function updateAddressData(address markAddress_th,uint inviteNumRecords_subscript,uint256 directPushesNumber) private {
        inviteNumRecords[markAddress_th][inviteNumRecords_subscript]++; // 推荐人数+1
        remainNumberRerolls[markAddress_th]+=5;//复投次数+5

        //判断是否复投白名单用户
        if(!revoteWhiteList[markAddress_th]){
            //判断是否满足添加复投白名单
            if(directPushesNumber >= 5){
                 //满足条件添加复投白名单
                 revoteWhiteList[markAddress_th] = true;
            }
        }
    }

    function setIsRank(address[] memory rankArr) public onlyOwner{
        for (uint256 i = 0; i < rankArr.length-1; i++) {
            isRank[rankArr[i]] = true;
            rankNum[rankArr[i]].push(i);
        }
        payNum = rankArr.length;

    }

    
    
    function setRank(address[] memory rankArr) public onlyOwner{
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

     // 获取指定用户的6个上级地址，可以调用此接口，进行分佣等操作
    function getParents(address myAddress) external view override returns(address[6] memory myParents){
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
        // 以数组形式返回
        myParents = [firstParent, secondParent, threeParent, fourParent, fiveParent, sixParent];
    }


    // 排号并发放奖金金额
    function pay(address parentAddress) public payable {
        require(msg.value >= 13900000000000000, 'Invite: 0001'); // 金额大于13900000000000000
        // require(msg.value >=1390000000000000000, 'value is 0'); // 不允许上级地址为0地址

        address myAddress = msg.sender; // 重新赋个值，没什么实际意义，单纯为了看着舒服

        // 已经在排号中不允许再投
        require(!isRank[myAddress], 'Already in qualifying'); 

        require(parentAddress != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        // require(msg.value != address(0), 'Invite: 0001'); // 不允许上级地址为0地址
        require(parentAddress != myAddress, 'Invite: 0002');// 不允许自己的上级是自己
        // 验证要绑定的上级是否有上级，只有有上级的用户，才能被绑定为上级（firstAddress除外）。如果没有此验证，那么就可以随意拿一个地址绑定成上级了
        require(parents[parentAddress] != address(0) || parentAddress == firstAddress, 'Invite: 0003');
        // 记录邀请关系，parentAddress邀请了myAddress，给parentAddress对应的数组增加一个记录
        inviteRecords[parentAddress].push(myAddress);
        // 记录我的上级
        parents[myAddress] = parentAddress;

        //初始复投次数
        remainNumberRerolls[myAddress]+=5;//复投次数+5

        // 统计数量        
        //标识地址
        address markAddress = parentAddress;
        //第一代
        uint256 directPushesNumber1 = inviteNumRecords[markAddress][0] + 1;// 获取直接邀请数量
        updateAddressData(markAddress,0,directPushesNumber1);

        //第二代
        markAddress = parents[markAddress];
        uint256 directPushesNumber2 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber2 + directPushesNumber1);
        
        //第三代
        markAddress = parents[markAddress];
        uint256 directPushesNumber3 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        //第四代
        markAddress = parents[markAddress];
        uint256 directPushesNumber4 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber4 + directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        //第五代
        markAddress = parents[markAddress];
        uint256 directPushesNumber5 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber5 + directPushesNumber4 + directPushesNumber3 + directPushesNumber2 + directPushesNumber1);
        
        //第六代
        markAddress = parents[markAddress];
        uint256 directPushesNumber6 = inviteNumRecords[markAddress][0];// 获取直接邀请数量
        updateAddressData(markAddress,2,directPushesNumber6 + directPushesNumber5 + directPushesNumber4 + directPushesNumber3 + directPushesNumber2 + directPushesNumber1);

        totalPeople++; // 总用户数+1

        //添加排号
        rank.push(myAddress);
        rankNum[myAddress].push(payNum);
        isRank[myAddress] = true;
    
        rewardDistribution(myAddress);
        //支付的总数每次支付后递增    
        payNum++;
    }




    
    event Log(uint256);
    event Log(bool);
 
    // 重复排号
      function payReply() public  payable onlyOwner{
        address addressRank;
        // 生成排位
        rankNum[rank[0]].push(payNum);

        //判断用户是否满足复投条件
        if(whiteList[rank[0]] || revoteWhiteList[rank[0]] || remainNumberRerolls[rank[0]] > 0){
            // payable(rank[0]).transfer(290000000000000000);
            payable(rank[0]).transfer(2900000000000000);
            //剩余复投次数减一
            if(remainNumberRerolls[rank[0]] > 0){
                remainNumberRerolls[rank[0]]--;
            }
            rewardDistribution(rank[0]);
        }else {
            payable(reInvestmentCollectionaddress).transfer(770000000000000);
            // payable(Platform).transfer(70000000000000000);
            payable(Platform).transfer(700000000000000);
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
        }
        rank[rank.length -1] = addressRank;

    }

    /**
    *   奖励发放
    */
    function rewardDistribution(address myAddress_th) private{
        //获取6代上级
        address[6] memory myParents = this.getParents(myAddress_th);
        // 获取满足条件的上级
        if(myParents[0]!=address(0)&& !isExistingAddress[myAddress_th][myParents[0]]){
            existingAddress[myAddress_th].push(myParents[0]);
            isExistingAddress[myAddress_th][myParents[0]]=true;
            // existingAmount[myAddress_th].push(300000000000000000);
            existingAmount[myAddress_th].push(3000000000000000);

        }
        if(myParents[1]!=address(0)&&!isExistingAddress[myAddress_th][myParents[1]]){
            existingAddress[myAddress_th].push(myParents[1]);
            isExistingAddress[myAddress_th][myParents[1]]=true;
            // existingAmount[myAddress_th].push(100000000000000000);
            existingAmount[myAddress_th].push(1000000000000000);
        }
        uint256 length = myParents.length;
        for (uint256 i = 2; i < length; i++) {
            if(myParents[i] != address(0)){
                address[] memory currParents = this.getChilds(myParents[i]); 
                if(currParents.length>=2&&!isExistingAddress[myAddress_th][myParents[i]]){
                    existingAddress[myAddress_th].push(myParents[i]);
                    // existingAmount[myAddress_th].push(20000000000000000);
                    existingAmount[myAddress_th].push(200000000000000);
                }
            }
        }
        uint256 lengths = existingAddress[myAddress_th].length;
       
        for (uint256 i = 0; i < lengths; i++) {
            payable(existingAddress[myAddress_th][i]).transfer(existingAmount[myAddress_th][i]);
        }
    //    payable(Platform).transfer(70000000000000000);
       payable(Platform).transfer(700000000000000);
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

    // 获取地址当前剩余复投次数
      function getAddressRemainNumber(address myAddress) external view returns(uint256 remainNumber){
        remainNumber = remainNumberRerolls[myAddress];
    }
 
    // 我的邀请数量。其他合约可以调用此接口，进行统计分佣等其他操作
    function getInviteNum(address myAddress) external view override returns(uint256[3] memory){
        // 返回我的直接邀请数量和二级邀请数量
        return inviteNumRecords[myAddress];
    }
       //将合约地址的转账到钱包地址
    function transferTo(address payable accountAddress) external onlyOwner returns(bool){
        accountAddress.transfer(address(this).balance);
        return true;
    }

    /*
     * @notice 批量添加白名单
     */
    function batchAddWhiteList(address[] calldata whiteList_) external onlyOwner{
        for(uint256 i; i<whiteList_.length; i++){
            whiteList[whiteList_[i]] = true;
        }
    }

    /*
     * @notice 批量移除白名单
     */
    function batchRmWhiteList(address[] calldata whiteList_) external onlyOwner{
        for(uint256 i; i<whiteList_.length; i++){
            delete whiteList[whiteList_[i]];
        }
    }
}