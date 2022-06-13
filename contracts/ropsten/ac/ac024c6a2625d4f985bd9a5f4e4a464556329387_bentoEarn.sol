// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ABDKMath64x64 as M} from "./ABDKMath64x64.sol";

contract bentoEarn{
    address payable public owner;
    bool public initialized;
    bool public divable;
    uint public totalPoint;
    uint public startTime;
    uint internal pointTime;
    mapping (address => uint) public deposit;
    mapping (address => uint) public bonus;
    mapping (address => uint) public point;
    mapping (address => uint) internal bonusTime;
    mapping (address => address) public referral;

    event Deposit(uint amount);
    event Withdraw(uint amount);
    event Reinvest(uint amount);
    event Dividend(uint bonus);
    event UpdatePoint(uint prePoint, uint newPoint);
    event Referral(address indexed referral);
    event OwnershipTransferred(address indexed previousOwner, address indexed _newOwner);

    constructor (){
        owner = payable(msg.sender);
        initialized = true;
        divable = true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyInit() {
        require(initialized, "Not initialized");
        _;
    }

    modifier onlyDivable() {
        require(divable, "Not dividend");
        _;
    }

    receive() external payable {}

// Service Logic
    function toWithdraw(uint _amount) public onlyInit{
        if(divable) updateBonus();
        require(_amount > 0 && _amount <= deposit[msg.sender], "Not enough funds.");
        deposit[msg.sender] -= _amount;
        uint fee = calFee(_amount);
        uint outPut = _amount - fee;
        owner.transfer(fee);
        payable(msg.sender).transfer(outPut);
        emit Withdraw(_amount);
    }
    function toDeposit(address _ref) public payable onlyInit{
        require(msg.value > 0 && msg.value <= currentUserBal(), "Not enough balance.");
        if(divable) updateBonus();
        if (!hasRef()) setRef(_ref);
        uint fee = calFee(msg.value);
        uint inPut = msg.value - fee;
        owner.transfer(fee);
        deposit[msg.sender] += inPut;
        updatePoint(inPut);
        emit Deposit(inPut);
    }
    function toReinvest() public onlyInit{
        require(bonus[msg.sender] > 0, "Not enough bonus.");
        if(divable) updateBonus();
        uint fee = calFee(bonus[msg.sender]);
        uint inPut = bonus[msg.sender] - fee;
        emit Reinvest(bonus[msg.sender]);
        bonus[msg.sender] = 0;
        deposit[owner] += fee;
        deposit[msg.sender] += inPut;
    }

// About point
    function updatePoint(uint _pay) internal onlyInit{
        uint newPoint = getNewPoint(_pay);
        pointTime = block.timestamp;
        uint toRef = newPoint * 20 / 100;
        point[msg.sender] += newPoint;
        point[referral[msg.sender]] += toRef;
        totalPoint += newPoint + toRef;
        emit UpdatePoint(point[msg.sender], newPoint);
    }
    function getNewPoint(uint _pay) internal view returns(uint){
        uint gap = calGap(pointTime);
        uint bal = address(this).balance;
        uint k = M.mulu(M.pow(M.divu(19999, 20000), gap), 1000000);
        return M.mulu(M.divu(_pay,bal),k);
    }

// About bonus
    function updateBonus() public onlyDivable {
        bonus[msg.sender] = currentBonus();
        bonusTime[msg.sender] = block.timestamp;
        emit Dividend(bonus[msg.sender]);
    }
    function getNewBonus() internal view returns(uint){
        if(!divable) return 0;
        uint time = bonusTime[msg.sender] != 0 ? bonusTime[msg.sender] : startTime;
        uint gap = calGap(time);
        uint bal = address(this).balance;
        int128 bonusPerMin = M.divu(bal, 20000);
        return M.mulu(M.pow(bonusPerMin, gap), point[msg.sender]) / totalPoint;
    }

// About referral
    function hasRef() public view returns(bool){
        return referral[msg.sender] != address(0);
    }
    function setRef(address _ref) public{
        require(!hasRef());
        if(_ref == msg.sender || _ref == address(0) || deposit[_ref] == 0) {
            _ref = owner;
        }
        referral[msg.sender] = _ref;
        emit Referral(_ref);
    }
// Watch
    function currentTotalPoint() public view onlyInit returns(uint){
        return totalPoint;
    }
    function currentBonus() public view onlyDivable returns(uint){
        return bonus[msg.sender] + getNewBonus();
    }
    function currentUserBal() public view returns(uint){
        return msg.sender.balance;
    }
    function currentBalance() public view returns(uint){
        return address(this).balance;
    }
// Simple calculate
    function calGap(uint _timestamp) internal view returns(uint){
        return (block.timestamp - _timestamp) / 60 + 1440; //attention
    }
    function calFee(uint _amount) internal pure returns(uint){
        return _amount / 100;
    }
// Only owner functions
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = payable(_newOwner);
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
    function init() public onlyOwner{
        require(!initialized);
        initialized = true;
    }
    function openDiv() public onlyInit onlyOwner{
        // require(address(this).balance) >= toWei(200));
        startTime = block.timestamp;
        pointTime = startTime;
        divable = true;
    }
}