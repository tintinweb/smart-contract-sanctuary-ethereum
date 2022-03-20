/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

contract Smart {
    uint constant TIME_STEP = 1 days;
    uint constant INVEST_DURATION = 10;
    uint constant PERCENTS_DIVIDER = 1000;
    uint constant PERCENT_ROI = 200;
    uint256 constant INVEST_MIN_AMOUNT = 900; // 0.1 bnb 
    uint[] REFERRAL_PERCENTS    = [80, 40, 20]; 

    address DEPLOYER;
    uint TOTAL_WITHDRAWN;

    struct Deposit {
        uint amount;
        uint timeStart;
        uint timeEnd;
    }

    struct User {
        address referrer;
        uint checkpoint;
        uint totalWithdrawn;
        uint totalInvested;
        uint refDividends;
        uint totalRefDividends;
        uint[3]     refCount;    
        Deposit[]   deposits;
    }

    struct Deps_Status_n_History {  
        Deposit deposit;
        bool ended;
    }
      
    mapping (address => User) internal users;

    event newDeposit(address user, uint256 amount);
    event newInvestor(address user);
    event withdrawnAmount(address user, uint256 amount);
    event refInvited(address referrer, address user);
    event refDividends(address referrer, address user, uint refLevel, uint amount);


    constructor() {
        DEPLOYER = msg.sender;
    }

    function invest(address _referrer, uint amount) public payable {
        require(amount >= INVEST_MIN_AMOUNT, "The deposit amount is too low");
        //User storage user = users[msg.sender];
        setUserReferrer(msg.sender, _referrer);
        setReferralRewards(msg.sender, amount);
        createDeposit(msg.sender, amount);
    }

    function createDeposit(address _user, uint amount)  internal returns(uint depositId) {
        User storage user = users[_user];
        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit newInvestor(_user);
        }
        uint startInvest = block.timestamp;
        uint endInvest = startInvest + INVEST_DURATION * TIME_STEP;
        
        Deposit memory deposit = Deposit(amount, startInvest, endInvest);
        depositId = user.deposits.length;
        user.deposits.push(deposit);

        emit newDeposit(msg.sender, msg.value);
    }

    function setUserReferrer(address _user, address _referrer) internal {
        if (users[_user].referrer != address(0)) return;    
        // No need to deposit to be considered as valid referrer
        //if (users[_referrer].deposits.length == 0) return;    
        if (_user == _referrer) return;                     

        users[_user].referrer = _referrer;

        //loop through the referrer hierarchy, increase every referral Levels counter
        address upline = users[_user].referrer;
        for (uint i=0; i < REFERRAL_PERCENTS.length; i++) {
            if(upline==address(0)) break;
            users[upline].refCount[i]++;
            upline = users[upline].referrer;
        }

        emit refInvited(_referrer,_user);
    }

    function setReferralRewards(address _user, uint _amount) internal {
        address upline = users[_user].referrer;
        for (uint i=0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline == address(0)) break;
            uint amount = _amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;
            users[upline].refDividends += amount;
            users[upline].totalRefDividends += amount;
            upline = users[upline].referrer;
            emit refDividends(upline, _user, i, amount);
        }
    }

    function getDepositsDividends (address _user) internal view returns (uint amount) {
        for(uint i=0;i < users[_user].deposits.length; i++) {
            amount += getSingleDepositDividends(_user,i);
        }
    }

    function getDepositsHistory (address _user) public view returns (Deps_Status_n_History[] memory) {
        Deps_Status_n_History[] memory f = new Deps_Status_n_History[](users[_user].deposits.length);
        for(uint k = 0; k < users[_user].deposits.length; k++) {
            f[k].deposit = users[_user].deposits[k];
            f[k].ended = f[k].deposit.timeEnd < block.timestamp ? !false : false;
        }
        return f;
    }

    function getSingleDepositDividends (address _user, uint depositId) public view returns (uint amount) {
        User storage user = users[_user];
        Deposit storage deposit = user.deposits[depositId];

        uint totalReward = deposit.amount * PERCENT_ROI / PERCENTS_DIVIDER;
        uint timeA = deposit.timeStart > user.checkpoint ? deposit.timeStart : user.checkpoint;
        uint timeB = deposit.timeEnd < block.timestamp ? deposit.timeEnd : block.timestamp;
        
        if (timeA < timeB) {
            amount = totalReward * (timeB - timeA) / TIME_STEP;
        }
    }

    function withdraw() public  {
        User storage user = users[msg.sender];
        uint amount = getDepositsDividends(msg.sender) + user.refDividends;

        require(amount > 0, "Nothing to withdraw");
        // clear acculumated dividends
        user.checkpoint = block.timestamp;
        user.refDividends = 0;

        user.totalWithdrawn += amount;
        TOTAL_WITHDRAWN += amount;

        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success, "Transfer failed.");
        emit withdrawnAmount(msg.sender, amount);
    }

    struct RefInfo {
        uint[3] count;
        uint dividends;
        uint totalEarned;
    }

    struct UserInfo {
        uint available;
        uint checkpoint;
        uint totalDepositCount;
        uint totalInvested;
        uint totalWithdrawn;
    }

    function getRefData(address _user) public view returns (RefInfo memory refInfo) {
        User storage user = users[_user]; 

        refInfo.count = user.refCount;
        refInfo.dividends = user.refDividends;
        refInfo.totalEarned = user.totalRefDividends;
    }

    function getFinanceData(address _user) public view returns (UserInfo memory userInfo) {
        User storage user = users[_user]; 

        userInfo.available = getDepositsDividends(_user) + user.refDividends;
        userInfo.checkpoint = user.checkpoint;
        userInfo.totalInvested = user.totalInvested;
        userInfo.totalDepositCount = user.deposits.length;
        userInfo.totalWithdrawn = user.totalWithdrawn;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    fallback() external payable {

    }
    receive() external payable {
        invest(address(0), msg.value);
    }
     
}