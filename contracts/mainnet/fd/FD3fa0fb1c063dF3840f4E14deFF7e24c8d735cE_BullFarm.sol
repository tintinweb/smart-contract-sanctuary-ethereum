// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBullFund.sol";

contract BullFarm {
    // Structs
    struct User {
        address account;
        address upline;
        uint deposit;
        uint withdraw;
        uint x3Factor;
        uint x3FactorCount;
        uint lastDepositUpdate;
        uint deferredProfit;
        uint openLines;
        uint[6] missedPartnersRewardByLine;
        uint[6] partnersRewardByLine;
        uint[6] partnersCountByLine;
    }

    // Constants
    uint public constant MIN_DEPOSIT_VALUE = 0.1 ether;
    uint public constant MIN_REINVEST_VALUE = 0.01 ether;
    uint public constant MIN_WITHDRAWAL_VALUE = 0.01 ether;
    uint public constant INITIAL_MAX_DEPOSIT = 1 ether;
    uint public constant MAX_DEPOSIT_DAILY_STEP = 0.2 ether;
    uint public constant MAX_DEPOSIT = 20 ether;
    uint public constant STAGE_PERIOD = 3 days;
    uint public constant MAX_LINES = 6;
    uint public constant DEVS_FEE = 300; // 3%
    uint public constant HONEY_BANK_FEE = 400; // 4%
    uint public constant INSURANCE_FEE = 300; // 3%
    uint public constant TOTAL_FEES = DEVS_FEE + HONEY_BANK_FEE + INSURANCE_FEE; // 10%
    uint[4] public PROFIT_BY_STAGES = [500,400,300,200]; // [5%, 4%, 3%, 2%]
    uint[6] public OPEN_LINE_MIN_DEPOSIT = [0.1 ether, 0.5 ether, 1 ether, 1.5 ether, 2 ether, 2.5 ether];
    uint[][] public PARTNER_PROGRAMS; // [12%, 10%, 8%] -> [10%, 8%, 7%, 5%] -> [9%, 7%, 6%, 5%, 3%] -> [8%, 7%, 6%, 4%, 3%, 2%]
    uint public PERCENTS_DIVISOR = 10000;

    // State
    mapping(address => User) users;
    mapping(address => bool) waitingMigration;
    address public admin;
    address public lineManager;
    uint public launchTimestamp;
    uint[] public stageTimestamps;
    mapping(address => bool) unlimited;
    uint public totalUsers;

    // Addresses for fee distribution
    address public devAddress;
    address public honeyFundAddress;
    IBullFarmFund public insuranceFund;

    // Events
    event Deposit(address account, uint value);
    event Reinvest(address account, uint value);
    event Withdraw(address account, uint value);
    event WithdrawTokens(address account, uint value);
    event Registration(address account, address upline);
    event PartnerReward(address account, address upline, uint reward);
    event FailedPartnerReward(address account, address upline, uint reward);
    event MissedPartnerReward(address account, address upline, uint reward);
    event X3FactorApply(address account, uint deposit);
    event Launch();

    // Modifiers
    modifier onlyRegistered() {
        require(users[msg.sender].account != address(0), "User is not registered");
        _;
    }

    constructor(address _devAddress, address _honeyFundAddress, IBullFarmFund _insuranceFund) {
        devAddress = _devAddress;
        honeyFundAddress = _honeyFundAddress;
        insuranceFund = _insuranceFund;
        admin = msg.sender;
        users[admin].account = admin;
        users[admin].upline = admin;
        users[admin].openLines = MAX_LINES;
        unlimited[admin] = true;
        totalUsers++;
        PARTNER_PROGRAMS.push([1200, 1000, 800]); //12%, 10%, 8%
        PARTNER_PROGRAMS.push([1000, 800, 700, 500]); //10%, 8%, 7%, 5%
        PARTNER_PROGRAMS.push([900, 700, 600, 500, 300]); //9%, 7%, 6%, 5%, 3%
        PARTNER_PROGRAMS.push([800, 700, 600, 400, 300, 200]); //8%, 7%, 6%, 4%, 3%, 2%
    }

    receive() external payable { /* Do nothing */ }

    // State changing functions
    function registerAndDeposit(address upline) payable external {
        register(upline);
        depositTo(msg.sender);
    }

    function register(address upline) public {
        if(users[upline].account == address(0)) {
            upline = admin;
        }

        require(users[msg.sender].account == address(0), "User is already registered");
        require(users[upline].account != address(0), "Upline is not registered");

        users[msg.sender].account = msg.sender;
        users[msg.sender].upline = upline;
        totalUsers++;

        address curUpline = upline;
        for(uint line; line < MAX_LINES; line++) {
            users[curUpline].partnersCountByLine[line]++;
            if (curUpline != users[curUpline].upline) {
                curUpline = users[curUpline].upline;
            } else {
                break;
            }
        }

        emit Registration(msg.sender, upline);
    }

    function deposit() payable external onlyRegistered {
        depositTo(msg.sender);
    }

    function depositTo(address account) payable public {
        require(launchTimestamp > 0, "BullFarm: not launched");
        require(users[account].account != address(0), "User is not registered");
        require(msg.value >= MIN_DEPOSIT_VALUE, "Deposit value is too small");
        require(users[account].deposit + msg.value <= getCurrentMaxDeposit(), "Deposit limit exceeded");
        require(!waitingMigration[account], "Migration required before deposit");

        users[account].deferredProfit += calcProfitForPeriod(users[account].deposit, users[account].lastDepositUpdate, block.timestamp);
        users[account].lastDepositUpdate = block.timestamp;
        users[account].deposit += msg.value;
        users[account].x3Factor += msg.value * 3;
        users[account].openLines = recalcOpenLines(account);

        distributeFees(msg.value);
        sendPartnerRewards(account, msg.value);

        emit Deposit(account, msg.value);
    }

    function reinvest() external onlyRegistered {
        require(launchTimestamp > 0, "BullFarm: not launched");
        require(users[msg.sender].deposit > 0, "Nothing to reinvest");

        uint availableProfit = calcAvailableProfit(msg.sender);
        require(availableProfit >= MIN_REINVEST_VALUE, "Reinvest value is too small");
        require(users[msg.sender].deposit + availableProfit <= getCurrentMaxDeposit(), "Reinvest value is too big");

        users[msg.sender].deferredProfit = 0;
        users[msg.sender].lastDepositUpdate = block.timestamp;
        users[msg.sender].deposit += availableProfit;
        users[msg.sender].x3Factor += availableProfit * 3;
        users[msg.sender].openLines = recalcOpenLines(msg.sender);

        uint feeAndPartnersReward = availableProfit * (getCurrentTotalPartnersRewardPercents() + TOTAL_FEES) / PERCENTS_DIVISOR;
        if (address(this).balance >= feeAndPartnersReward) {
            distributeFees(availableProfit);
            sendPartnerRewards(msg.sender, availableProfit);
        }

        emit Reinvest(msg.sender, availableProfit);
    }

    function withdraw() external onlyRegistered {
        require(users[msg.sender].lastDepositUpdate > 0, "No deposits");

        uint profit = calcAvailableProfit(msg.sender);
        require(profit > MIN_WITHDRAWAL_VALUE, "No profit available");

        users[msg.sender].deferredProfit = 0;
        users[msg.sender].lastDepositUpdate = block.timestamp;

        if (profit * (PERCENTS_DIVISOR + TOTAL_FEES) / PERCENTS_DIVISOR <= address(this).balance) {
            users[msg.sender].withdraw += profit;
            users[msg.sender].x3Factor -= min(profit, users[msg.sender].x3Factor);
            distributeFees(profit);
            payable(msg.sender).transfer(profit);
            emit Withdraw(msg.sender, profit);
        } else if(users[msg.sender].withdraw < users[msg.sender].deposit) {
            users[msg.sender].withdraw += profit;
            users[msg.sender].x3Factor -= min(profit, users[msg.sender].x3Factor);
            insuranceFund.sendTokens(msg.sender, profit);
            emit WithdrawTokens(msg.sender, profit);
        } else {
            revert("Withdrawal failed");
        }

        if (users[msg.sender].x3Factor == 0) {
            applyX3Factor(msg.sender);
        }
    }

    function launch() external {
        require(msg.sender == admin, "Only admin");
        require(launchTimestamp == 0, "Launch can be used only once");
        launchTimestamp = block.timestamp;
        stageTimestamps = [
            block.timestamp,
            block.timestamp + STAGE_PERIOD,
            block.timestamp + 2 * STAGE_PERIOD,
            block.timestamp + 3 * STAGE_PERIOD
        ];

        emit Launch();
    }

    function setUnlimited(address account) external {
        require(msg.sender == admin, "Only admin");
        require(launchTimestamp == 0, "Can be used only before launch");
        require(users[account].account == account, "User is not registered");

        unlimited[account] = true;
        users[account].openLines = MAX_LINES;
    }

    function migrate(address account) external payable {
        require(msg.sender == lineManager, "Only lineManager");
        require(launchTimestamp > 0, "BullFarm: not launched");
        require(users[account].account != address(0), "User is not registered");
        require(waitingMigration[account], "Account not waiting for migration");

        waitingMigration[account] = false;
        if (users[account].x3Factor > 0) {
            users[account].lastDepositUpdate = block.timestamp;
            users[account].deposit = msg.value;
        }

        distributeFees(msg.value);
        sendPartnerRewards(account, msg.value);

        emit Deposit(account, msg.value);
    }

    function setOpenLines(address account, uint lines) external {
        require(msg.sender == lineManager, "Only lineManager");
        require(launchTimestamp == 0, "Can be used only before launch");
        require(users[account].account == account, "User is not registered");
        require(lines > 0 && lines <= MAX_LINES, "Invalid lines count");

        users[account].openLines = lines;
        users[account].x3Factor = OPEN_LINE_MIN_DEPOSIT[lines - 1] * 3;
        waitingMigration[account] = true;
    }

    function setLineManager(address _lineManager) external {
        require(msg.sender == admin, "Only admin");
        lineManager = _lineManager;
    }

    // Private functions
    function distributeFees(uint depositValue) private {
        uint devFeeValue = depositValue * DEVS_FEE / PERCENTS_DIVISOR;
        (bool devFeeSent,) = payable(devAddress).call{value : devFeeValue}("");
        require(devFeeSent, "Failed to send dev fee");

        uint honeyFundFeeValue = depositValue * HONEY_BANK_FEE / PERCENTS_DIVISOR;
        (bool honeyFundFeeSent,) = payable(honeyFundAddress).call{value : honeyFundFeeValue}("");
        require(honeyFundFeeSent, "Failed to send Honey Fund fee");

        uint insuranceFeeValue = depositValue * INSURANCE_FEE / PERCENTS_DIVISOR;
        bool insuranceFeeSent = payable(address(insuranceFund)).send(insuranceFeeValue);
        require(insuranceFeeSent, "Failed to send Insurance Fund fee");
    }

    function sendPartnerRewards(address account, uint depositValue) private {
        uint[] memory partnersProgram = getCurrentPartnersProgram();
        address upline = users[account].upline;
        for(uint line; line < partnersProgram.length; line++) {
            uint reward = depositValue * partnersProgram[line] / PERCENTS_DIVISOR;
            if (users[upline].openLines > line) {
                bool sent = payable(upline).send(reward);
                if (sent) {
                    users[upline].partnersRewardByLine[line] += reward;
                    users[upline].x3Factor -= min(reward, users[upline].x3Factor);
                    if(users[upline].x3Factor == 0) {
                        applyX3Factor(upline);
                    }
                    emit PartnerReward(account, upline, reward);
                } else {
                    // Only if receiver is smart contract with broken handler
                    payable(admin).transfer(reward);
                    emit FailedPartnerReward(account, upline, reward);
                }
            } else {
                users[upline].missedPartnersRewardByLine[line] += reward;
                emit MissedPartnerReward(account, upline, reward);
            }

            upline = users[upline].upline;
        }
    }

    function applyX3Factor(address account) private {
        if (unlimited[account]) {
            return;
        }

        users[account].x3FactorCount++;
        users[account].withdraw = 0;
        users[account].x3Factor = 0;
        users[account].lastDepositUpdate = 0;
        users[account].deferredProfit = 0;
        users[account].openLines = 0;

        emit X3FactorApply(account, users[account].deposit);
        users[account].deposit = 0;
    }

    // View functions
    function recalcOpenLines(address account) public view returns(uint) {
        for(uint i = users[account].openLines; i < MAX_LINES; i++) {
            if (users[account].deposit < OPEN_LINE_MIN_DEPOSIT[i]) {
                return i;
            }
        }

        return MAX_LINES;
    }

    function getCurrentPartnersProgram() public view returns(uint[] memory) {
        return PARTNER_PROGRAMS[getCurrentStageIndex()];
    }

    function getCurrentProfitPercents() public view returns(uint) {
        return PROFIT_BY_STAGES[getCurrentStageIndex()];
    }

    function calcAvailableProfit(address account) public view returns(uint) {
        uint profit = users[account].deferredProfit + calcProfitForPeriod(users[account].deposit, users[account].lastDepositUpdate, block.timestamp);
        if (unlimited[account]) {
            return profit;
        }

        return profit > users[account].x3Factor ? users[account].x3Factor : profit;
    }

    function calcProfitForPeriod(uint depositValue, uint from, uint to) public view returns(uint) {
        if (launchTimestamp == 0 || to <= from || to < stageTimestamps[0]) {
            return 0;
        }

        uint result;

        // Profit for stage 1
        if (from < stageTimestamps[1]) {
            result += calcProfitForStage(depositValue, 0, min(to, stageTimestamps[1]) - max(from, stageTimestamps[0]));
        }

        // Profit for stage 2
        if (from < stageTimestamps[2] && to > stageTimestamps[1]) {
            result += calcProfitForStage(depositValue, 1, min(to, stageTimestamps[2]) - max(from, stageTimestamps[1]));
        }

        // Profit for stage 3
        if (from < stageTimestamps[3] && to > stageTimestamps[2]) {
            result += calcProfitForStage(depositValue, 2, min(to, stageTimestamps[3]) - max(from, stageTimestamps[2]));
        }

        // Profit for stage 4
        if (to >= stageTimestamps[3]) {
            result += calcProfitForStage(depositValue, 3, to - max(from, stageTimestamps[3]));
        }

        return result;
    }

    function getCurrentMaxDeposit() public view returns(uint) {
        uint curMaxDep = INITIAL_MAX_DEPOSIT + MAX_DEPOSIT_DAILY_STEP * ((block.timestamp - launchTimestamp) / 1 days);
        return curMaxDep > MAX_DEPOSIT ? MAX_DEPOSIT : curMaxDep;
    }

    function getCurrentStageIndex() public view returns(uint) {
        uint timeSpent = (block.timestamp - launchTimestamp);
        if (timeSpent < STAGE_PERIOD) {
            return 0;
        } else if (timeSpent < STAGE_PERIOD * 2) {
            return 1;
        } else if (timeSpent < STAGE_PERIOD * 3) {
            return 2;
        } else {
            return 3;
        }
    }

    function getProfitByStages() external view returns(uint[4] memory) {
        return PROFIT_BY_STAGES;
    }

    function getOpenLinesMinDeposit() external view returns(uint[6] memory) {
        return OPEN_LINE_MIN_DEPOSIT;
    }

    function getUser(address account) external view returns(User memory) {
        return users[account];
    }

    function calcProfitForStage(uint depositValue, uint stageIndex, uint duration) private view returns(uint) {
        return depositValue * PROFIT_BY_STAGES[stageIndex] * duration * 10000 / 1 days / 10000 / PERCENTS_DIVISOR;
    }

    function getStageTimestamps() external view returns(uint[] memory) {
        return stageTimestamps;
    }

    function getCurrentTotalPartnersRewardPercents() public view returns(uint) {
        uint result;
        uint[] memory rewardPercents = getCurrentPartnersProgram();
        for(uint i; i < rewardPercents.length; i++) {
            result += rewardPercents[i];
        }

        return result;
    }

    function min(uint value1, uint value2) private pure returns(uint) {
        return value1 < value2 ? value1 : value2;
    }

    function max(uint value1, uint value2) private pure returns(uint) {
        return value1 > value2 ? value1 : value2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IBullFarmFund {
    function sendTokens(address to, uint ethAmount) external;
}