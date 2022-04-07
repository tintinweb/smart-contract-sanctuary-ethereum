/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

contract BNBRain {
    uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;//最低存款金额为0.05 BNB
    uint256[] public REFERRAL_PERCENTS = [50];  //合约超过 1 级支付 5% 的推荐佣金
    uint256 constant public PROJECT_FEE = 100; //项目费用  10%
    uint256 constant public MARKETING_FEE = 50; //营销费用 5%
    uint256 constant public INSURANCE_FEE = 100;//保险费 10%
    //保险系统是一个由所有者管理的钱包。它将被手动管理，所有者可以将其用作或不用作保险系统。
    uint256 constant public HOLD_BONUS = 700; //如果用户直到存款计划结束才提款，他将额外获得70%的奖金
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days; //一天只有一次 提现时间

    uint256 public totalStaked;
    uint256 public totalReinvested;
    uint256 public totalRefBonus;

    struct Plan { //计划
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit { //钱包
        uint8 plan; //计划
        uint256 percent;
        uint256 amount;
        uint256 profit;//利润
        uint256 start;
        uint256 finish;
    }

    struct User { //用户
        Deposit[] deposits; //钱包
        uint256 checkpoint;
        address referrer;
        uint256[1] levels;
        uint256 bonus; //奖金
        uint256 totalBonus; //总奖金
    }

    mapping (address => User) internal users;

    uint256 public startUNIX;
    address payable public projectWallet; //项目钱包
    address payable public marketingWallet; //市场钱包
    address payable public insuranceWallet; //保证金钱包

    event Newbie(address user);//推荐新人
    //新开账户
    event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
    //再投资
    event Reinvest(address indexed user, uint256 amount);
    //提现
    event Withdrawn(address indexed user, uint256 amount);
    //推荐奖金
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    //花费
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor() {
        projectWallet   = payable(0xD6a2d0E7179E4Bf2b6b9BaC38a7bf082472087fE);
        marketingWallet = payable(0x46fDCb5ee2EA002f77B39b0a798F0de9D1879EBF);
        insuranceWallet = payable(0x276301Fa092e4a10855196E08fB4DB8AFD20c379);
        startUNIX = block.timestamp;
        plans.push(Plan(10, 150));//10天计划，15%的利润
    }

    function investing(uint256 amount,address referral) public {
        this.invest{value:amount}(referral);
    }

    //投资
    function invest(address referrer) public payable {
        //最低存款金额为0.05 BNB
        require(msg.value >= INVEST_MIN_AMOUNT,"min deposit is 0.05 BNB");
        uint8 plan = 0;

        uint256 pro = msg.value * PROJECT_FEE / PERCENTS_DIVIDER;//项目费
        projectWallet.transfer(pro);
        uint256 mar = msg.value * MARKETING_FEE / PERCENTS_DIVIDER;//营销费
        marketingWallet.transfer(mar);
        uint256 ins = msg.value * INSURANCE_FEE / PERCENTS_DIVIDER;//保险费
        insuranceWallet.transfer(ins);
        emit FeePayed(msg.sender, pro + mar + ins);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 1; i++) {
                if (upline != address(0)) {
                    //推荐人在首次存款时指定一次，并分配给用户，不得更改。从随后的每次存款中，推荐人将获得他的百分比。
                    users[upline].levels[i] = users[upline].levels[i] + 1;
                    upline = users[upline].referrer;
                } else break;
            }
        }else{
            address upline = user.referrer;
            for (uint256 i = 0; i < 1; i++) {
                if (upline != address(0)) {
                    //推荐人在首次存款时指定一次，并分配给用户，不得更改。从随后的每次存款中，推荐人将获得他的百分比。
                    uint256 amount = msg.value * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;
                    users[upline].bonus = users[upline].bonus + amount;
                    users[upline].totalBonus = users[upline].totalBonus + amount;
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

        totalStaked = totalStaked + msg.value;
        emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
    }

    //用户每天只能提取或再投资一次
    function withdraw() public {
        User storage user = users[msg.sender];
        //一天只有一次提现时间
        require(user.checkpoint + TIME_STEP < block.timestamp, "only once a day");
        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount + referralBonus;
        }

        require(totalAmount > 0, "User has no dividends");
        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        user.checkpoint = block.timestamp;
        payable(msg.sender).transfer(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    //用户每天只能提取或再投资一次
    function reinvest() public {
        User storage user = users[msg.sender];
        require(user.checkpoint + TIME_STEP < block.timestamp, "only once a day");
        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount + referralBonus;
        }

        require(totalAmount > INVEST_MIN_AMOUNT, "User has no dividends");
        user.checkpoint = block.timestamp;

        (uint256 percent, uint256 profit, uint256 finish) = getResult(0, totalAmount);
        user.deposits.push(Deposit(0, percent, totalAmount, profit, block.timestamp, finish));

        totalReinvested = totalReinvested + totalAmount;
        emit Reinvest(msg.sender, totalAmount);
    }

    //获取合约balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //获取投资计划
    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        time = plans[plan].time; //计划投资天数
        percent = plans[plan].percent; //计划获得的利润百分比
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        return plans[plan].percent;
    }

    function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
        percent = getPercent(plan);
        profit = deposit * percent / PERCENTS_DIVIDER * plans[plan].time;
        finish = block.timestamp + (plans[plan].time * TIME_STEP);
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalAmount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                uint256 share = user.deposits[i].amount * user.deposits[i].percent / PERCENTS_DIVIDER;
                uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount + (share * (to - from) / TIME_STEP);
                }

                //如果用户直到存款计划结束
                if(user.checkpoint <= user.deposits[i].start && user.deposits[i].finish < block.timestamp){
                    totalAmount = totalAmount + (user.deposits[i].amount * HOLD_BONUS / PERCENTS_DIVIDER);
                }

            }
        }

        return totalAmount;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns(uint256) {
        return (users[userAddress].levels[0]);
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus - users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress) + getUserDividends(userAddress);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount + users[userAddress].deposits[i].amount;
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    //
    function setPlan(uint256 amount) public{
        require(msg.sender == projectWallet, "only owner");
        //所有者有权在 1% 到 20% 之间更改每日利润
        require(amount >= 1 && amount <= 20, "amount should be in range of 1 to 20");
        plans[0].percent = amount * 10;
    }
}