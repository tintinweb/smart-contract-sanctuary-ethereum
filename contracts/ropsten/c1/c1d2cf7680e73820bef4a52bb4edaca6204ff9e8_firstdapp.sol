/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract firstdapp{
    address payable private _owner;
    uint public startTime;
    uint public totalPoints;
    bool public initialized=false;
    bool public startDividend=false;
    mapping (address => uint) public deposit;
    mapping (address => uint) public dividendTsp;
    mapping (address => uint) public points;
    mapping (address => address) public referrals;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed sender, uint amount);
    event Dividend(address indexed sender, uint deposit, uint lastDiv);
    event AddPoints(address indexed sender, uint points, uint newPoints);
    event Referrals(address indexed sender, address indexed referral);

    constructor () {
        _owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier isInit() {
        require(initialized, "Dapp not initialized");
        _;
    }

    modifier startDiv() {
        require(startDividend, "Dapp not dividend");
        _;
    }

// 业务逻辑
    // 提现
    function toWithdrawal(uint amount) public isInit{
        // 更新分红
        updateDiv();
        require(amount <= deposit[msg.sender], "Not enough funds.");
        // 提款
        deposit[msg.sender] -= amount;
        uint fee = getFee(amount);
        uint outPut = amount - fee;
        _owner.transfer(fee);
        payable(msg.sender).transfer(outPut);
        // 监听
        emit Withdraw(msg.sender, amount);
    }

    function toDonate() external payable {
        require(msg.value > 0);
        uint fee = getFee(msg.value);
        uint inPut = msg.value - fee;
        _owner.transfer(fee);
        deposit[msg.sender] += inPut;
    }

    // 充值
    function toDeposit(address ref) public payable isInit{
        require(msg.value > 0);
        // 设置推荐人
        if (!haveReferral(msg.sender)){
          setReferrals(ref);
        }
        // 充值
        uint fee = getFee(msg.value);
        uint inPut = msg.value - fee;
        _owner.transfer(fee);
        deposit[msg.sender] += inPut;
        // 增加积分
        updatePoints(inPut);
        // 更新分红
        updateDiv();
        // 监听充值事件
        emit Deposit(msg.sender, inPut);
    }

    // 更新积分
    function updatePoints(uint amount) public isInit{
        uint newPoints = getNewPoints(amount);
        points[msg.sender] += newPoints;
        // 添加给推荐人（20%）
        uint newPointsToRef = newPoints * 20 / 100;
        points[referrals[msg.sender]] += newPointsToRef;
        totalPoints += newPoints + newPointsToRef;
        // 监听增加积分事件
        emit AddPoints(msg.sender, points[msg.sender], newPoints);
    }

    // 更新当前用户分红
    function updateDiv() public isInit startDiv{
        deposit[msg.sender] += getLastDiv();
        dividendTsp[msg.sender] = block.timestamp;
        // 监听分红事件
        emit Dividend(msg.sender, deposit[msg.sender], getLastDiv());
    }

// 初始化
    // 启动项目
    function init() public onlyOwner{
        require(totalPoints==0);
        require(!initialized);
        initialized = true;
    }

    // 触发分红
    function openDividend() public isInit onlyOwner{
        // require(toEth(getBalance()) >= 200);
        startTime = block.timestamp;
        startDividend = true;
    }

    // 设置推荐人
    function setReferrals(address ref) public{
        require(!haveReferral(msg.sender));
        if(ref == msg.sender || ref == address(0) || deposit[ref] == 0) {
            ref = _owner;
        }
        referrals[msg.sender] = ref;
        // 监听推荐人事件
        emit Referrals(msg.sender, ref);
    }

// 获取属性
    // 判断是否有推荐人
    function haveReferral(address addr) public view returns(bool){
        return referrals[addr] != address(0);
    }

    // 获取时间差
    function getGap(uint stp) public view returns(uint){
        return (block.timestamp - stp)/60;
    }

    // 获取积分价格
    function getPointPerEth() public view returns(uint){
        uint timeGap = getGap(startTime);
        return 1000000 / (1 + toEth(getBalance())) * 20000**timeGap / 20001**timeGap;
    }

    // 获取所添加积分
    function getNewPoints(uint amount) public view returns(uint){
        return toEth(amount) * getPointPerEth();
    }

    // 获取每笔存取手续费（1%）
    function getFee(uint amount) public pure returns(uint){
        return amount / 100;
    }

    // 获取每分钟可分红总额（分红池的0.005%）
    function getDivPerMin() public view returns(uint) {
        return getBalance() / 20000;
    }

    // 获取当前用户积分占比
    function getShare() public view returns(uint){
        return totalPoints / points[msg.sender];
    }
    
    // 获取当前用户最新一波分红
    function getLastDiv() public view returns(uint){
        uint timeGap = getGap(dividendTsp[msg.sender]==0?startTime:dividendTsp[msg.sender]);
        return timeGap * getDivPerMin() / getShare();
    }

    // 获取合约余额
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    // 单位转换 wei -> eth
    function toEth(uint amount) public pure returns(uint){
        return amount / 1 ether;
    }

    // 单位转换 eth -> wei
    function toWei(uint amount) public pure returns(uint){
        return amount * 1 ether;
    }

// 所有者权限
    // 获取当前所有者
    function owner() public view returns (address) {
        return _owner;
    }
    
    // 所有者提取合约金额
    function ownerWithdrawal(uint amount) public onlyOwner{
        require(amount > 0);
        _owner.transfer(amount);
    }
    
    // 更换所有者
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = payable(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}