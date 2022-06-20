// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ABDKMath64x64 as M} from "./ABDKMath64x64.sol";

contract bigFarm{
    address payable public owner;
    bool public divable;
    uint public totalPoint;
    uint public startTime;
    mapping (address => uint) public point;
    mapping (address => uint) private bonusTime;
    mapping (address => uint) private bonusAdd;
    mapping (address => address) public referral;

    event OwnershipTransferred(address indexed previousOwner, address indexed _newOwner);

    constructor (){
        owner = payable(address(0x53F12Fb27C01277244264D4Ff4d468C46d6AA093));
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    receive() external payable {
        toDeposit(owner);
    }

// Service Logic
    function toDeposit(address _ref) public payable {
        require(msg.value > 0, "have to bigger than 0.");
        if(!divable) initStartTime();
        if(!hasRef()) setRef(_ref);
        uint fee = calFee(msg.value);
        uint amount = msg.value - fee;
        owner.transfer(fee);
        updatePoint(amount);
    }
    function toWithdraw(uint _amount) external {
        uint amount = subBonus(_amount);
        payable(msg.sender).transfer(amount);
    }
    function toReinvest(uint _amount) external {
        uint amount = subBonus(_amount);
        updatePoint(amount);
    }

// About point
    function updatePoint(uint _pay) private {
        uint newPoint = getNewPoint(_pay);
        uint toRef = newPoint * 20 / 100;
        point[msg.sender] += newPoint;
        point[referral[msg.sender]] += toRef;
        totalPoint += newPoint + toRef;
        if(divable) {
            initBonusTime(msg.sender);
            initBonusTime(referral[msg.sender]);
        }
    }
    function getNewPoint(uint _pay) internal view returns(uint){
        uint mins = divable ? calGap(startTime) : 0;
        uint bal = address(this).balance;
        uint k = calK(mins, 1000000);
        return M.mulu(M.divu(_pay / 1000000, (bal + _pay) / 1000000), k);
    }

// About bonus
    function subBonus(uint _amount) private returns(uint){
        uint CB = curBonus();
        require(_amount > 0 && _amount <= CB, "Not enough funds.");
        bonusTime[msg.sender] = block.timestamp;
        bonusAdd[msg.sender] = CB - _amount;
        uint fee = calFee(_amount);
        owner.transfer(fee);
        return _amount - fee;
    }

// About time
    function initStartTime() private {
        if(address(this).balance > 10**18){
            startTime = block.timestamp;
            divable = true;
        }
    }
    function initBonusTime(address _addr) private {
        if (bonusTime[_addr] == 0) {
            bonusTime[_addr] = block.timestamp;
        }
    }

// About referral
    function hasRef() public view returns(bool){
        return referral[msg.sender] != address(0);
    }
    function setRef(address _ref) public{
        require(!hasRef(),"you have already set.");
        // check if the address is valid
        bool isValid = _ref != msg.sender && _ref != address(0); 
        referral[msg.sender] = isValid ? _ref : owner;
    }

// Watch
    function curBonus() public view returns(uint){
        uint mins = (divable && point[msg.sender] > 0) ? calGap(calMax(bonusTime[msg.sender], startTime)) : 0;
        uint bal = address(this).balance;
        uint A = M.mulu(M.divu(point[msg.sender], totalPoint + 1), bal);
        return A - calK(mins, A) + bonusAdd[msg.sender];
    }
    function curTotalPoint() public view returns(uint){
        return totalPoint;
    }
    function curPoint() public view returns(uint){
        return point[msg.sender];
    }
    function curUserBal() public view returns(uint){
        return msg.sender.balance;
    }
    function curConBal() public view returns(uint){
        return address(this).balance;
    }
    function curPointPrice() public view returns(uint){
        return getNewPoint(1 ether);
    }

// Calculate
    function calGap(uint _timestamp) internal view returns(uint){
        return (block.timestamp - _timestamp) / 60;
    }
    function calFee(uint _amount) internal pure returns(uint){
        return _amount / 100;
    }
    function calK(uint _gap, uint _num) internal pure returns(uint){
        return M.mulu(M.pow(M.divu(19999, 20000), _gap), _num);
    }
    function calMax(uint _a, uint _b) internal pure returns(uint){
        return _a > _b ? _a : _b;
    }

// Only owner functions
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = payable(_newOwner);
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}