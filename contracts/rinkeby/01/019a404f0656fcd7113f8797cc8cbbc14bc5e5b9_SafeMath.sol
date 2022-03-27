/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

/**
 *Submitted for verification at snowtrace.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Testv11 {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 0.1 ether;
    uint256 public constant INVEST_MAX_AMOUNT = 500 ether;
    uint256 public constant CLAIM_MAX_AMOUNT = 200 ether;
    uint256[] public REFERRAL_PERCENTS = [60, 30, 10];
    uint256 public constant INVEST_FEE = 30;
    uint256 public constant CLAIM_FEE = 70;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    uint256 public constant CLAIM_COOLDOWN = 0.5 days;
    uint256 public totalStaked;
    uint256 public totalInvestors;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 cooldownCheckpoint;
        address referrer;
        uint256[3] levels;
        uint256 claimed;
        uint256 claimPool;
        uint256 bonus;
        uint256 totalBonus;
    }

    mapping(address => User) internal users;

    address payable public commissionAddress;
    uint256 public launchTime;

    event Newbie(address user);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event feePaid(address indexed user, uint256 totalAmount);

    constructor(address payable wallet) {
        require(!isContract(wallet));
        commissionAddress = wallet;
        launchTime = block.timestamp.add(999 days);

        plans.push(Plan(14, 150));
        plans.push(Plan(21, 130));
        plans.push(Plan(28, 110));
    }

    function launch() public {
        require(msg.sender == commissionAddress);
        launchTime = block.timestamp;
    }

    function invest(address referrer, uint8 plan) public payable {
        require(launchTime < block.timestamp, "Project not launched yet");
        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum amount is 0.1 AVAX");
        require(msg.value <= INVEST_MAX_AMOUNT, "Maximum amount is 500 AVAX");
        require(plan < 3, "Incorrect plan");

        User storage user = users[msg.sender];
        require(
            user.deposits.length < 100,
            "Maximum 99 deposits from single address"
        );

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalInvestors++;
            emit Newbie(msg.sender);
        }

        uint256 fee = msg.value.mul(INVEST_FEE).div(PERCENTS_DIVIDER);
        commissionAddress.transfer(fee);
        emit feePaid(msg.sender, fee);

        (uint256 percent, uint256 profit, uint256 finish) = getResult(
            plan,
            msg.value
        );
        user.deposits.push(
            Deposit(plan, percent, msg.value, profit, block.timestamp, finish)
        );

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            msg.value,
            profit,
            block.timestamp,
            finish
        );
    }

    function reinvest(uint8 plan) public {
        require(plan < 3, "Incorrect plan");

        User storage user = users[msg.sender];
        require(
            user.deposits.length < 100,
            "Maximum 99 deposits from single address"
        );

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 userClaimPool = getUserClaimPool(msg.sender);
        uint256 userReferralBonus = getUserReferralBonus(msg.sender);

        if (userClaimPool > 0) {
            totalAmount = totalAmount.add(userClaimPool);
            user.claimPool = 0;
        }

        if (userReferralBonus > 0) {
            totalAmount = totalAmount.add(userReferralBonus);
            user.bonus = 0;
        }

        require(totalAmount >= INVEST_MIN_AMOUNT, "Minimum amount is 0.1 AVAX");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            user.claimPool = totalAmount.sub(contractBalance);
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.claimed = user.claimed.add(totalAmount);

        (uint256 percent, uint256 profit, uint256 finish) = getResult(
            plan,
            totalAmount
        );
        user.deposits.push(
            Deposit(plan, percent, totalAmount, profit, block.timestamp, finish)
        );

        totalStaked = totalStaked.add(totalAmount);
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            totalAmount,
            profit,
            block.timestamp,
            finish
        );
    }

    function claim() public {
        User storage user = users[msg.sender];
        require(
            user.cooldownCheckpoint <= block.timestamp.sub(CLAIM_COOLDOWN),
            "User can claim 1 time only per 12 hours"
        );

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 userClaimPool = getUserClaimPool(msg.sender);
        uint256 userReferralBonus = getUserReferralBonus(msg.sender);

        if (userClaimPool > 0) {
            totalAmount = totalAmount.add(userClaimPool);
            user.claimPool = 0;
        }

        if (userReferralBonus > 0) {
            totalAmount = totalAmount.add(userReferralBonus);
            user.bonus = 0;
        }

        if (totalAmount > CLAIM_MAX_AMOUNT) {
            user.claimPool = totalAmount.sub(CLAIM_MAX_AMOUNT);
            totalAmount = CLAIM_MAX_AMOUNT;
        }

        require(totalAmount > 0, "User has no claimable rewards");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            user.claimPool = user.claimPool.add(totalAmount).sub(
                contractBalance
            );
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.cooldownCheckpoint = block.timestamp;
        user.claimed = user.claimed.add(totalAmount);

        uint256 fee = totalAmount.mul(CLAIM_FEE).div(PERCENTS_DIVIDER);
        commissionAddress.transfer(fee);
        emit feePaid(msg.sender, fee);

        payable(msg.sender).transfer(totalAmount.sub(fee));
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getResult(uint8 plan, uint256 deposit)
        public
        view
        returns (
            uint256 percent,
            uint256 profit,
            uint256 finish
        )
    {
        percent = plans[plan].percent;

        profit = deposit.mul(plans[plan].percent).div(PERCENTS_DIVIDER).mul(
            plans[plan].time
        );

        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                uint256 share = user
                    .deposits[i]
                    .amount
                    .mul(user.deposits[i].percent)
                    .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = user.deposits[i].finish < block.timestamp
                    ? user.deposits[i].finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
        }

        return totalAmount;
    }

    function getUserBalance(address userAddress)
        public
        view
        returns (
            uint256 currentDeposits,
            uint256 claimed,
            uint256 claimable
        )
    {
        currentDeposits = getUserCurrentDeposits(userAddress);
        claimed = getUserClaimed(userAddress);
        claimable = getUserClaimable(userAddress);
    }

    function getUserReferralStats(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].levels[0],
            users[userAddress].levels[1],
            users[userAddress].levels[2],
            users[userAddress].totalBonus
        );
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].levels[0],
            users[userAddress].levels[1],
            users[userAddress].levels[2]
        );
    }

    function getUserClaimPool(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].claimPool;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserClaimable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserClaimPool(userAddress)
                .add(getUserReferralBonus(userAddress))
                .add(getUserDividends(userAddress));
    }

    function getUserClaimed(address userAddress) public view returns (uint256) {
        return users[userAddress].claimed;
    }

    function getUserDepositsCount(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserCurrentDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            if (users[userAddress].deposits[i].finish > block.timestamp) {
                amount = amount.add(users[userAddress].deposits[i].amount);
            }
        }
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserAllDepositsInfo(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        return users[userAddress].deposits;
    }

    function getContractInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalInvestors, totalStaked, address(this).balance);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
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