// SPDX-License-Identifier: MIT

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.8.0;

contract StakingBNB {
    string public tariff = "BNB 30 Standard";
    uint256 private apr = 365;
    uint256 private lock = 2;
    uint256 private permLock = 1;
    uint256 private fineWithdraw = 20;

    uint256 private lockSec;
    uint256 private permLockSec;
    uint256 private timeFineSec;

    address owner;

    mapping(address => uint256) public stakeDeposit;
    mapping(address => uint256) public stakeData;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Even(
        uint256 indexed timeStampNewStake,
        address indexed addresNewStake,
        uint256 indexed amountNewStake
    );

    constructor() {
        lockSec = SafeMath.mul(SafeMath.mul(SafeMath.mul(lock, 24), 60), 60);
        permLockSec = SafeMath.mul(
            SafeMath.mul(SafeMath.mul(permLock, 24), 60),
            60
        );
        timeFineSec = SafeMath.sub(lockSec, permLockSec);

        owner = msg.sender;

        emit OwnershipTransferred(owner, owner);
    }

    function Stake() public payable {
        uint256 _amount = msg.value;
        uint256 _timestamp = block.timestamp;
        address _address = msg.sender;

        require(
            stakeDeposit[_address] == 0,
            "Staking is possible only after the end of the tariff"
        );

        stakeDeposit[_address] = _amount;
        stakeData[_address] = _timestamp;

        emit Even(_timestamp, _address, _amount);
    }

    function CalculateProfit() public view returns (uint256) {
        address _sender;
        uint256 _deposit;
        uint256 _timeStamp;
        uint256 _stakingTime;
        uint256 _multiplier;
        uint256 _aprResultMult;
        uint256 _profit;
        uint256 _total;
        uint256 _totalProfit;
        uint256 _year;

        _sender = msg.sender;

        require(
            stakeDeposit[_sender] > 0,
            "Profit calculation is not possible, make a deposit for staking."
        );

        _deposit = stakeDeposit[_sender];
        _timeStamp = stakeData[_sender];
        _stakingTime = SafeMath.sub(block.timestamp, _timeStamp);
        _multiplier = 1000000000;
        _year = 31536000;

        if (_stakingTime > lockSec) {
            _stakingTime = lockSec;
        }

        _aprResultMult = SafeMath.div(SafeMath.mul(apr, _multiplier), _year);
        _profit = SafeMath.div(
            SafeMath.mul(
                SafeMath.mul(_stakingTime, _multiplier),
                _aprResultMult
            ),
            _multiplier
        );
        _total = SafeMath.mul(SafeMath.div(_deposit, 100), _profit);
        //
        _totalProfit = SafeMath.div(_total, _multiplier);

        return _totalProfit;
    }

    //
    function Withdraw() public {
        address payable _sender;
        uint256 _timeStamp;
        uint256 _stakingTime;
        uint256 _profit;
        uint256 _totalWithdraw;

        _sender = payable(msg.sender);

        require(
            stakeDeposit[_sender] > 0,
            "It is impossible to take profit, make a deposit for staking."
        );

        _timeStamp = stakeData[_sender];
        _stakingTime = SafeMath.sub(block.timestamp, _timeStamp);

        require(
            _stakingTime > permLockSec,
            "Wait for the permanent lockout to complete."
        );

        if (_stakingTime > lockSec) {
            _profit = CalculateProfit();
        } else {
            _profit = 0;
        }

        _totalWithdraw = SafeMath.add(_profit, stakeDeposit[_sender]);

        stakeDeposit[_sender] = 0;
        stakeData[_sender] = 0;

        _sender.transfer(_totalWithdraw);

        emit Even(block.timestamp, _sender, _totalWithdraw);
    }

    function GetBalance(address targetAddr) public view returns (uint256) {
        return targetAddr.balance;
    }

    function Fine(address addr) public view returns (uint256) {
        uint256 _deposit;
        uint256 _totalFine;
        uint256 _fineSec;
        uint256 _multiplier;
        uint256 _timeStamp;
        uint256 _stakingTime;
        uint256 _fineWei;

        if (stakeDeposit[addr] == 0) {
            _fineWei = 0;

            return _fineWei;
        }

        _deposit = stakeDeposit[addr];
        _totalFine = SafeMath.mul(SafeMath.div(_deposit, 100), fineWithdraw);

        _multiplier = 1000000000;
        _fineSec = SafeMath.div(
            SafeMath.mul(_totalFine, _multiplier),
            timeFineSec
        );

        _timeStamp = stakeData[addr];
        _stakingTime = SafeMath.sub(block.timestamp, _timeStamp);

        if (_stakingTime > permLockSec) {
            _fineWei = SafeMath.div(
                SafeMath.mul(SafeMath.sub(lockSec, _stakingTime), _fineSec),
                _multiplier
            );
        } else {
            _fineWei = 0;
        }

        return _fineWei;
    }
}