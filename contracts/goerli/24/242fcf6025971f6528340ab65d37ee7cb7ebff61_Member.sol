/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
/// @title 会员管理合约
/// @author hunkguo
/// @notice 实现会员上下级管理，付费及提成结算功能。
contract Member {
    address payable owner;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    constructor() {
        owner = payable(msg.sender);
    }

    // 会员管理
    struct HigherLevel {
        address higherLevelAddress;
    }
    struct LowerLevel{
        address lowerLevelAddress;
    }    
    mapping(address => HigherLevel) private  highers;
    mapping(address => LowerLevel[]) private  lowers;

    event setHigherLevel(address member, address inviteMember);
    /// @notice 保存上线地址
    /// @param inviteMember 邀请人的地址
    function setLevel(address inviteMember) public {
        require(msg.sender != inviteMember, 'Invitation is invalid');
        highers[msg.sender].higherLevelAddress = inviteMember;
        emit setHigherLevel(msg.sender, inviteMember);
        // 判断是否下线是否重复
        LowerLevel[] memory senderIsLower = lowers[inviteMember];
        bool result = false;
        for (uint p = 0; p < senderIsLower.length; p++) {
            if (msg.sender == senderIsLower[p].lowerLevelAddress){
                result = true;
            }
        }
        if(!result){
            lowers[inviteMember].push(LowerLevel({lowerLevelAddress: msg.sender}));
        }
        
    }    
    /// @notice 获取下线地址
    /// @return result 返回所有下线地址数组
    function getLower() public view returns( address[] memory  result){
        LowerLevel[] memory lowerlevel = lowers[msg.sender];
        result = new address[](lowerlevel.length);
        for (uint i = 0; i < lowerlevel.length; i++) {
            result[i] = lowerlevel[i].lowerLevelAddress;
        }

    }
    /// @notice 获取上线地址
    /// @return result 返回所有上线地址
    function getHigher() public view returns(address){
        return highers[msg.sender].higherLevelAddress;
    }
    /// @notice 获取上线地址
    /// @param member 成员地址
    /// @return result 返回所有上线地址
    function getHigher(address member) private view returns(address){
        return highers[member].higherLevelAddress;
    }

    function getConstractBalance() public view returns (uint256){
        return address(this).balance;
    }
    // 合约内金额
    mapping(address => uint256) private memberBlance;
    
    function getMemberInConstractBalance() public view returns (uint256){
        return memberBlance[msg.sender];
    }
    /// @notice 结算
    function memberClose() public {
        uint256 constractBalance = address(this).balance;
        uint256 memberInConstractBalance = memberBlance[msg.sender];
        
        require(constractBalance>0, 'The contract balance is zero');
        require(memberInConstractBalance>0, 'The personal balance in the contract is zero');
        require(constractBalance>memberInConstractBalance, 'Insufficient balance');

        memberBlance[msg.sender]=0;
        payable(msg.sender).transfer(memberInConstractBalance);
    }





    // 业务逻辑
    address[] public acl;
    function getOrderStatus() public view returns (bool result){
        result = false;
        address buyer = msg.sender;
        for (uint p = 0; p < acl.length; p++) {
            if (buyer == acl[p]){
                result = true;
            }
        }
    }

    event Performance(address indexed _from, address indexed _to, uint indexed value);
    
    /// @notice 收款
    event Received(address, uint);
    receive() external payable{
        emit Received(msg.sender, msg.value);

        // address inviteMember
        // setLevel(inviteMember)
        uint256 amount = msg.value;
        address buyer = msg.sender;
        require(amount > 1000, 'money not enjoy.'); 
        // 计算业绩提成
        uint256 performanceCommission = amount / 5;
        // 合约收入
        // uint256 realAmount = (amount * 4) /5;
        // payable(owner).transfer(realAmount);

        uint256 PerformanceCommissionPer = performanceCommission / 4;
        uint256 performanceCommissionSurplus = performanceCommission - PerformanceCommissionPer;
        // 一级上线
        address levelMembe1 = getHigher(buyer);
        if(performanceCommission >0 && performanceCommissionSurplus>0 && levelMembe1!=address(0)){            
            memberBlance[levelMembe1] = memberBlance[levelMembe1] + PerformanceCommissionPer;
            emit Performance(msg.sender, levelMembe1, PerformanceCommissionPer);
        }
        // 二级上线
        address levelMembe2 = getHigher(levelMembe1);
        if(performanceCommissionSurplus>0 && levelMembe2!=address(0)){
            performanceCommissionSurplus = performanceCommissionSurplus - PerformanceCommissionPer;         
            memberBlance[levelMembe2] = memberBlance[levelMembe2] + PerformanceCommissionPer;
            emit Performance(msg.sender, levelMembe2, PerformanceCommissionPer);
        }
        // 三级上线
        address levelMembe3 = getHigher(levelMembe2);
        if(performanceCommissionSurplus>0 && levelMembe3!=address(0)){
            performanceCommissionSurplus = performanceCommissionSurplus - PerformanceCommissionPer;         
            memberBlance[levelMembe3] = memberBlance[levelMembe3] + PerformanceCommissionPer;
            emit Performance(msg.sender, levelMembe3, PerformanceCommissionPer);
        }
        // 四级上线
        address levelMembe4 = getHigher(levelMembe3);
        if(performanceCommissionSurplus>0 && levelMembe4!=address(0)){
            performanceCommissionSurplus = performanceCommissionSurplus - PerformanceCommissionPer;         
            memberBlance[levelMembe4] = memberBlance[levelMembe4] + PerformanceCommissionPer;
            emit Performance(msg.sender, levelMembe4, PerformanceCommissionPer);
        }

        acl.push(buyer);
    }

    fallback() external payable { 
        
    }



    

}