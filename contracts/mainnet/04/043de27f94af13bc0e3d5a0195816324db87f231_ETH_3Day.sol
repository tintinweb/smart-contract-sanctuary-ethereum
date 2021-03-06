/**
 *Submitted for verification at Etherscan.io on 2020-11-05
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract ETH_3Day {
    using SafeMath for uint256;
    uint256 constant public CONTRACT_BALANCE_STEP = 3;
    address public manager;
    uint256 public day = 3 days;
    uint256 public rechargeTime;
    uint256 public minAmount = 1 ether;
    uint256 public percentage = 900;
    uint256 public totalUsers;
    
    address public ERC20;
    
    struct RechargeInfo{
        address rec_addr;
        uint256 rec_value;
        uint256 rec_time;
    }
    RechargeInfo[] public rechargeAddress;
    struct UserInfo {
		address   referrer;   
        address[] directPush; 
        uint256 amountWithdrawn;
        uint256 distributionIncome72;
    }
    mapping(address => UserInfo) public user;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => bool)) public userDireMap;
    
    constructor(address _token)public{
        manager = msg.sender;
        ERC20 = _token;
     }
    
    // ??????
    function deposit(address referrer,uint256 value)  public {
        require(value >= minAmount,"Top up cannot be less than 1 eth");
        // ??????72??????-??????
        distribution72();
        
        IERC20(ERC20).transferFrom(msg.sender,address(this),value);
        UserInfo storage u = user[msg.sender];
        //  ?????????????????????    &&      ????????? ????????? ??????
		if (u.referrer == address(0) && referrer != msg.sender) {
			// ????????????
            u.referrer = referrer;
            if (userDireMap[referrer][msg.sender] == false){
                // ???????????????????????????
                user[referrer].directPush.push(msg.sender);
                userDireMap[referrer][msg.sender] = true;
            }
		}
		
		if (balance[msg.sender] == 0){
		    totalUsers = totalUsers.add(1);
		}
		// ??????
		balance[msg.sender] = balance[msg.sender].add(value);
		rechargeAddress.push(RechargeInfo({rec_addr:msg.sender,rec_value:value,rec_time:block.timestamp}));
		rechargeTime = block.timestamp;
    }
    
    // ??????
    function withdraw(uint256 value) public {
        require(value > 0 && directPushMultiple(msg.sender) >= 3,"3 times withdrawal");
        // ?????????????????????????????????
        uint256 count = availableQuantity(msg.sender);
        require(count >= value,"Not enough quota");
        // ??????
        IERC20(ERC20).transfer(msg.sender,value);
        user[msg.sender].amountWithdrawn = user[msg.sender].amountWithdrawn.add(value);
    }
    
    // pool ??????
    function getPoolETH() view public returns(uint256){
        return IERC20(ERC20).balanceOf(address(this));
    }
    
    // ???????????????
    function getRecTotal() view public returns(uint256){
        return rechargeAddress.length;
    }
    
    // ??????10?????????
    function getRec10() view public returns(RechargeInfo[] memory){
        uint256 l = rechargeAddress.length;
        uint256 a = 0;
        uint256 i = 0;
        if (rechargeAddress.length>10){
            l = 10;
            a = rechargeAddress.length.sub(10);
        }
        RechargeInfo[] memory data = new RechargeInfo[](l);
        for (;a < rechargeAddress.length; a++){
            data[i] = rechargeAddress[a];
            i = i+1;
        }
        return data;
    }
    
    // ??????72????????????
    function distribution72() public {
        if (isTime() == false){return;}
        uint256 a = 0;
        if (rechargeAddress.length>50){
            a = rechargeAddress.length.sub(50);
        }
        uint256 total = (IERC20(ERC20).balanceOf(address(this)).mul(percentage)).div(uint256(1000));
        for (;a < rechargeAddress.length; a++){
            user[rechargeAddress[a].rec_addr].distributionIncome72 = user[rechargeAddress[a].rec_addr].distributionIncome72.add(total.div(100));
        }
        return;
    }
    
    // ???????????????????????? 72 ??????
    function isTime()view public returns(bool) {
        if ((block.timestamp.sub(rechargeTime)) >= day && rechargeTime != 0){
            return true;
        }
        return false;
    }
    
    // ????????????
    function directPushMultiple(address addr) view public isAddress(addr) returns(uint256) {
        if(balance[addr] == 0){
            return 0;
        }
        return getDirectTotal(addr).div(balance[addr]);
    }
    
    // ????????????
    function getMaxIncome(address addr) view public isAddress(addr) returns(uint256){
        return directPushMultiple(addr).mul(balance[addr]);
    }
    
    // ????????????
    function getIncome(address addr) view public isAddress(addr) returns(uint256){
        uint256 multiple = directPushMultiple(addr);
        if (multiple == 0){
            return 0;
        }
        if (multiple > 3){
            multiple = 3;
        }
        return balance[addr].mul(multiple);
    }
    
    // ?????????????????????
    function numberWithdrawn(address addr) view public isAddress(addr) returns(uint256) {
        return user[addr].amountWithdrawn;
    }
    
    // ?????????????????????
    function availableQuantity(address addr) view public isAddress(addr) returns(uint256) {
        if (directPushMultiple(addr) < 3){
            return 0;
        }
        return getIncome(addr).sub(numberWithdrawn(addr));
    }
    
    // ????????????  (???????????? - (?????? * 3)) / 3                 ???????????????????????????
    function additionalThrow(address addr) view public isAddress(addr) returns(uint256,uint256){
        // ????????????
        uint256 dirTotal = getDirectTotal(addr);
        // ??????????????????
        uint256 userTotal = getIncome(addr);
        // ????????????
        uint256 ztAmount = (dirTotal.sub(userTotal)).div(CONTRACT_BALANCE_STEP);
        // uint256 t = ztAmount.div(CONTRACT_BALANCE_STEP);
        return (ztAmount,ztAmount.mul(CONTRACT_BALANCE_STEP));
    }
    
    // ????????????????????????
    function getDirectTotal(address addr) view public isAddress(addr) returns(uint256) {
        UserInfo memory u = user[addr];
        if (u.directPush.length == 0){return (0);}
        uint256 total;
        for (uint256 i= 0; i<u.directPush.length;i++){
            total += balance[u.directPush[i]];
        }
        return (total);
    }
    
    // 72????????????
    function distributionIncome72()public{
        require(user[msg.sender].distributionIncome72 > 0);
        IERC20(ERC20).transfer(msg.sender,user[msg.sender].distributionIncome72);
    }
    
    // ??????????????????
    function getDirectLength(address addr) view public isAddress(addr) returns(uint256){
        return user[addr].directPush.length;
    }
    
    // Owner ??????
    function ownerWitETH(uint256 value) public onlyOwner{
        require(getPoolETH() >= value);
        IERC20(ERC20).transfer(msg.sender,value);
    }
    
    // ????????????
    function ownerTransfer(address newOwner) public onlyOwner isAddress(newOwner) {
        manager = newOwner;
    }
    
    modifier isAddress(address addr) {
        require(addr != address(0));
        _;
    }
    
    modifier onlyOwner {
        require(manager == msg.sender);
        _;
    }

}