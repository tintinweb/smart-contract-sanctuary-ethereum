// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;


contract bets {
    
    /*
    *@id: User Sequence New Order User Auto +1
    *@account: Only one result can be purchased for the same user account
    *@amount: bet quantity
    *@buyTeam: bet Which team wins (1 Team1 (home team) wins, 2 Team2 (Away team), and 3 draw)
    *@referrer: Referrer
    *@dispute: Record user disputes
    */
    struct bill {
        uint number;
        uint id;
        uint time;
        address account;
        uint amount;
        uint buyTeam;
        address referrer;
        string dispute;
    }

    /*
    *@number: issue number
    *@tag: Event category (football: 10, basketball: 20,...)
    *@status: Issue status (1 is normal, 2 is suspended; when the event is abnormal, the operator manually pauses; when the event resumes, the operator manually resumes; 3 is settled, and 4 is rolled back)
    *@team1: Team1 name (home team)
    *@team2: Team2 name (Away team)
    *@startTime: Start buying time
    *@endTime: End buying time
    *@playingTime: playing start time
    *@userCount: Number of users
    *@disputeCount: Number of disputes
    *@winTeam: The winning team is initially 0. When the game is played, the result is imported from the oracle
    *@memo: Remarks It is used when the game is abnormal and can be used to save the abnormal announcement
    *@dev: When the game is abnormal, the coo can suspend buying
    */
    struct status {
        uint number;
        uint tag;
        uint status;
        string team1;
        string team2;
        uint startTime;
        uint endTime;
        uint playingTime;
        uint userCount;
        uint disputeCount;
        uint winTeam;
        string memo;
    }


    //Issue Serial Number User Bill
    mapping (uint => mapping(uint => bill)) public NumberAccount;

    //Issue number, number Status
    mapping (uint => status) public NumberStatus;

    //User income=profit income+recommendation income
    mapping (address => uint)  MyReturns;
    mapping (address => address) public MyReferrer;

    uint[] public NumberSet;

    // 80%
    // Proportion of winner's income
    uint WinnerRate = 8000;
    // 7%
    // Reward proportion of recommenders
    uint referrerRate = 700;

    // Proportion of community operating expenses
    uint fee;
    // 1 pic
    // min bet 1 token
    uint minBet = 1000000000000000000;

    // Used to set COO and CFO not to participate in operation
    bytes32 CEO= 0x44d5da1524d709ea5f9cc2e97e75890cadbae85e9111e1da979f5333c9f9024d;
    // Create and settle events
    bytes32 COO= 0x0e02a154a8b4a23993e4a42c7c58faf0ee0253ffdccbed46e8c32e69fe318b20;
    // For administrative expenses
    bytes32 CFO= 0xdd6dbf535bc7270694309536d902dab1380b991dfc2c9b12d1a36e52cef360a2;

    event eventCreateNumber(status newNumber);
    event eventSetPause(status pauseNumber);
    event eventUnPause(status unpauseNumber);
    event eventUserDispute(status disputeNumber);
    event eventDeposit(status depositNumber);
    event eventSettlement(status settlementNumber);
    event eventWithdrawReturn(address user,uint amount,uint balance);
    event eventWithdrawFee(address account,uint amount,uint balance);

    IERC20 bank;

    constructor(IERC20 _bank) {
        bank = _bank;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyCEO() {
        require(keccak256(abi.encodePacked(msg.sender)) == CEO, "invalid account");
        _;
    }

    modifier onlyCOO() {
        require(keccak256(abi.encodePacked(msg.sender)) == COO, "invalid account");
        _;
    }

    modifier onlyCFO() {
        require(keccak256(abi.encodePacked(msg.sender)) == CFO, "invalid account");
        _;
    }

    modifier onlyManage() {
        bytes32 manage = keccak256(abi.encodePacked(msg.sender));
        require(manage == CEO || manage == COO || manage == CFO, "invalid account");
        _;
    }

    function SetCOO(address newCOO) external onlyCEO {
        require(newCOO != address(0), "invalid zero address");
        COO = keccak256(abi.encodePacked(newCOO));
    }

    function SetCFO(address newCFO) external onlyCEO {
        require(newCFO != address(0), "invalid zero address");
        CFO = keccak256(abi.encodePacked(newCFO));
    }

    function SetCEO(address newCEO) external onlyCEO {
        require(newCEO != address(0), "invalid zero address");
        CEO = keccak256(abi.encodePacked(newCEO));
    }

    function SetMinBet(uint minAmount) external onlyCOO {
        minBet = minAmount;
    }

    function getTime() public view returns(uint) {
        return(block.timestamp);
    }

    /* 
    *building New Games
    *@number: start number from 1
    *@status: For all parameters in the current period, default values will be given if there is no definite value
    *@dev: Only the COO can establish the competition, which cannot be repeated
    */
    function CreateNumber(status calldata _status) external onlyCOO {
        // Non repeatable
        require(NumberStatus[_status.number].status == 0, "invalid number");
        NumberStatus[_status.number].number = _status.number;
        NumberStatus[_status.number].tag = _status.tag;        
        NumberStatus[_status.number].status = _status.status;
        NumberStatus[_status.number].team1 = _status.team1;
        NumberStatus[_status.number].team2 = _status.team2;
        NumberStatus[_status.number].startTime = _status.startTime;
        NumberStatus[_status.number].endTime = _status.endTime;

        NumberSet.push(_status.number);
        
        emit eventCreateNumber(NumberStatus[_status.number]);
    }

    // Get the betting information of an account
    function getBillOf(uint number, address account) public view returns(uint time,uint id,uint buyTeam,uint amount,address referrer, uint winTeam) {
        for(uint i;i<NumberStatus[number].userCount + 1; i++) {
            if (NumberAccount[number][i].account == account) {
                time = NumberAccount[number][i].time;
                id = NumberAccount[number][i].id;
                buyTeam = NumberAccount[number][i].buyTeam;
                amount = NumberAccount[number][i].amount;
                referrer = NumberAccount[number][i].referrer;
                winTeam = NumberStatus[number].winTeam;
            }
        }
    }

    // Get the betting information of an account in batch
    function getAllBillOf(address account, uint count) public view returns(bill[] memory billSet) {
        require(count>0, "invalid count");
        billSet = new bill[](count);
        uint step = 0;
        for(uint i=NumberSet.length; i>0; i--) {
            
            if(step > count){
                return billSet;

            } else {
                uint number = NumberSet[i-1];
                for(uint i2;i2<NumberStatus[number].userCount + 1; i2++) {
                    if (NumberAccount[number][i2].account == account) {
                        billSet[step] = NumberAccount[number][i2];
                        step = step + 1;
                    }
                }
            }
        }
    }

    // Count the number of bets and people of each team in a certain period
    function getBetsCount(uint number) public view returns(uint numberid, uint team1Amount, uint team1user, uint team2Amount, uint team2user, uint tieAmount, uint tieUser) {
        for(uint i; i<NumberStatus[number].userCount + 1; i++) {
            
            numberid = number;
            if(NumberAccount[number][i].buyTeam==1){
                team1Amount = team1Amount + NumberAccount[number][i].amount;
                team1user = team1user + 1;
            }
            
            if(NumberAccount[number][i].buyTeam==2){
                team2Amount = team2Amount + NumberAccount[number][i].amount;
                team2user = team2user + 1;
            }

            if(NumberAccount[number][i].buyTeam==3){
                tieAmount = tieAmount + NumberAccount[number][i].amount;
                tieUser = tieUser + 1;
            }
        }
    }

    // Batch statistics of the number of bets and people of each team in each period
    function getBetsCountBatch(uint[] calldata numberSet) public view returns(uint[7][] memory result) {
        result = new uint[7][](numberSet.length);

        for(uint i; i<numberSet.length;i++) {
            (result[i][0],result[i][1],result[i][2],result[i][3],result[i][4],result[i][5],result[i][6]) = getBetsCount(numberSet[i]);
        }

    }

    function getLastNumber() public view returns (uint length,uint number) {
        require(NumberSet.length>0,"no data");
        return (NumberSet.length, NumberSet[NumberSet.length-1]);
    }

    /* 
    *Statistically approaching the specified number of sets
    *@count: Number returned
    *@dev: Used for the most recent schedule list
    */
    function getNewCount(uint count) public view returns(status[] memory setarray) {
        require(count>0, "invalid count");
        setarray = new status[](count);
        uint step = 0;
        for(uint i=NumberSet.length; i>0; i--) {
            
            if(step > count){
                return setarray;

            } else {

                setarray[step] = NumberStatus[NumberSet[i-1]];
                step = step + 1;
                
            }
        }
    }

    /* 
    *Statistic the status collection of a category
    *@tag: Type parameter
    *@status: Status parameter
    *@count: Number of returned
    *@dev: used to access the scheduling list of different categories
    */
    function getTagStatusCount(uint tag, uint statusID, uint count) public view returns(status[] memory setarray) {
        require(count>0, "invalid count");
        setarray = new status[](count);
        uint step = 0;
        for(uint i=NumberSet.length; i>0; i--) {
            
            if(step > count){
                return setarray;

            } else {
              if(NumberStatus[NumberSet[i-1]].tag == tag && NumberStatus[NumberSet[i-1]].status == statusID) {
                    setarray[step] = NumberStatus[NumberSet[i-1]];
                    step = step + 1;
                }
            }
        }
    }

    /* 
    *Statistics of a category collection
    *@tag: Type parameter
    *@count: Number of returned
    *@dev: Used to access the schedule list of different categories
    */
    function getTagCount(uint tag, uint count) public view returns(status[] memory setarray) {
        require(count>0, "invalid count");
        setarray = new status[](count);
        uint step = 0;
        for(uint i=NumberSet.length; i>0; i--) {
            
            if(step > count){
                return setarray;

            } else {
              if(NumberStatus[NumberSet[i-1]].tag == tag) {
                    setarray[step] = NumberStatus[NumberSet[i-1]];
                    step = step + 1;
                }
            }

        }
    }

    /* 
    * Statistics of a state set
    *@status: Status parameters
    *@count: Number returned
    *@dev: Used to access the schedule list in different states
    */
    function getStatusCount(uint statusID, uint count) public view returns(status[] memory setarray) {
        require(count>0, "invalid count");
        setarray = new status[](count);
        uint step = 0;
        for(uint i=NumberSet.length; i>0; i--) {
            
            if(step > count){
                return setarray;

            } else {
              if(NumberStatus[NumberSet[i-1]].status == statusID) {
                    setarray[step] = NumberStatus[NumberSet[i-1]];
                    step = step + 1;
                }
            }
        }
    }

    // Back to the user when the game result is abnormal
    function Backout(uint number) external onlyCFO {
        require(NumberStatus[number].status == 2, "must be suspend first");
        for(uint i;i<NumberStatus[number].userCount + 1; i++) {
            if (NumberAccount[number][i].amount > 0) {
                MyReturns[NumberAccount[number][i].account] = MyReturns[NumberAccount[number][i].account] + NumberAccount[number][i].amount;
            }
        }
    }

    function getMyReturns() public view returns(uint) {
        return(MyReturns[msg.sender]);
    }

    function getReferrerRate() public view returns(uint) {
        return(referrerRate);
    }

    function getFee() onlyManage public view returns(uint) {
        return(fee);
    }

    function getManager() public view returns(bytes32 ceo,bytes32 coo,bytes32 cfo){
        return(CEO,COO,CFO);
    }

    function SetStartTime(uint number,uint time, string memory memo) external onlyCOO {
        require(time > block.timestamp,"invalid time");
        NumberStatus[number].startTime = time;
        NumberStatus[number].memo = memo;

    }

    function SetEndTime(uint number,uint time, string memory memo) external onlyCOO {
        require(time > NumberStatus[number].startTime,"invalid time");
        NumberStatus[number].endTime = time;
        NumberStatus[number].memo = memo;

    }

    function SetPlayTime(uint number,uint time, string memory memo) external onlyCOO {
        require(time > NumberStatus[number].endTime,"invalid time");
        NumberStatus[number].playingTime = time;
        NumberStatus[number].memo = memo;

    }

    function SetMemo(uint number,string memory memo) external onlyCOO {
        NumberStatus[number].memo = memo;
    }

    //Pause when the game result is abnormal
    //After pausing, you can back out the token to the user or wait for it to return to normal
    function SetPause(uint number,string memory memo) external onlyCOO {

        NumberStatus[number].status = 2;
        NumberStatus[number].memo = memo;
        emit eventSetPause(NumberStatus[number]);

    }

    //Resume when the game is suspended
    function UnPause (uint number,string memory memo) external onlyCOO {

        require(NumberStatus[number].status == 2, "must be suspend first");
        NumberStatus[number].status = 1;
        NumberStatus[number].memo = memo;
        emit eventUnPause(NumberStatus[number]);

    }

    //The recorded user dispute content must be the user who has already bet
    function UserDispute(uint number,string memory dispute) external {
        //Check whether the user has a purchase record. If yes, you can only add different types
        (,uint MyId,,uint MyAmount,,) = getBillOf(number,msg.sender);
        require(MyAmount > 0, "invalid user");
        NumberAccount[number][MyId].dispute = dispute;
        NumberStatus[number].disputeCount = NumberStatus[number].disputeCount + 1;
        emit eventUserDispute(NumberStatus[number]);

    }

    //Get the content disputed by the user
    function getDispute(uint number) public view returns(string[] memory res) {
        uint lg = NumberStatus[number].disputeCount;
        uint stepLg = 0;
        res = new string[](lg);
        for(uint i; i<NumberStatus[number].userCount +1; i++) {
            if (stepLg>lg) {
                return res;
            } else{
                if (bytes(NumberAccount[number][i].dispute).length>0) {

                    res[stepLg] = NumberAccount[number][i].dispute;
                    stepLg = stepLg + 1;
                }
            }
        }
    }

    /*
    *bet
    *@number: number
    *@amount: bet amount
    *@buyTeam: Bet which team wins (1 (home team) win, 2 (away team), 3 draw)
    *@referrer: Recommender (7% reward can be obtained)
    *@dev: User bank approval is required to give this contract before placing a bet
    */
    function deposit(uint number, uint amount, uint buyTeam, address referrer) external {
        require(amount >= minBet, "under minimum number");
        require(msg.sender!=referrer, "invalid referrer");
        require(NumberStatus[number].status==1, "invalid status");
        require(block.timestamp > NumberStatus[number].startTime && block.timestamp<NumberStatus[number].endTime, "invalid time");
        require(buyTeam==1 || buyTeam==2 || buyTeam==3, "invalid Team");
        //Check whether the user has a purchase record. If yes, you can only add different types
        (,uint MyId,uint MyTeam,uint MyAmount,,) = getBillOf(number,msg.sender);
        require(MyAmount == 0 || MyTeam==buyTeam, "The same account can't buy many");
        bank.transferFrom(msg.sender, address(this), amount);
        if (MyAmount==0) {
            //new bet
            uint id = NumberStatus[number].userCount + 1;
            NumberStatus[number].userCount = id;
            NumberAccount[number][id].id = id;
            NumberAccount[number][id].number = number;
            NumberAccount[number][id].time = block.timestamp;     
            NumberAccount[number][id].account = msg.sender;
            NumberAccount[number][id].buyTeam = buyTeam;
            NumberAccount[number][id].amount = amount;
            if(referrer != address(0)) {
                NumberAccount[number][id].referrer = referrer;
                MyReferrer[msg.sender] = referrer;
            }
        } else {
            //Additional betting
            if (MyTeam == buyTeam) {
                NumberAccount[number][MyId].time = block.timestamp;
                NumberAccount[number][MyId].amount = NumberAccount[number][MyId].amount + amount;
                if(NumberAccount[number][MyId].referrer != referrer) {
                    NumberAccount[number][MyId].referrer = referrer;
                    MyReferrer[msg.sender] = referrer;
                }
            
            }
        }

        emit eventDeposit(NumberStatus[number]);
    }

    /*
    *settle
    *@number: number
    *@winTeam: The winning team is initially 0. When the game is played, the result is imported from the oracle
    *@dev:When the game is over, the game will be settled
    */
    function settlement(uint number, uint winTeam) external onlyCOO{
        require(NumberStatus[number].status==1, "invalid status");
        require(block.timestamp>NumberStatus[number].endTime, "invalid time");
        uint buyTeam1count;
        uint buyTeam2count;
        uint buyTeam3count;
        uint allCount;
        uint winAmount;
        uint lostAmount;
        //The proportion of my quantity in the total amount of the same type
        uint myRate;

        for(uint i; i<NumberStatus[number].userCount +1; i++) {
            bill memory billcount = NumberAccount[number][i];
            allCount = allCount + billcount.amount;
            if (billcount.buyTeam == 1) {
                buyTeam1count = buyTeam1count + billcount.amount;
            }
            if (billcount.buyTeam == 2) {
                buyTeam2count = buyTeam2count + billcount.amount;
            }
            if (billcount.buyTeam == 3) {
                buyTeam3count = buyTeam3count + billcount.amount;
            }
        }

        if (winTeam == 1) {
            winAmount = buyTeam1count;
            lostAmount = buyTeam2count + buyTeam3count;
        }

        if (winTeam == 2) {
            winAmount = buyTeam2count;
            lostAmount = buyTeam1count + buyTeam3count;
        }

        if (winTeam == 3) {
            winAmount = buyTeam3count;
            lostAmount = buyTeam1count + buyTeam2count;
        }

        //Comparing the number of winners and losers, no loser will not settle and refund to the user
        require(lostAmount > 0, "nobody lose the race");

        for(uint i;i<NumberStatus[number].userCount + 1; i++) {

            if (NumberAccount[number][i].buyTeam == winTeam) {
                bill memory winbill = NumberAccount[number][i];
                //The proportion of my bets in the total number of winners
                myRate = (winbill.amount * 10000) / winAmount;
                uint allReturn = (allCount * myRate) / 10000;
                uint netReturn = (allReturn * WinnerRate) / 10000;            
                MyReturns[winbill.account] = MyReturns[winbill.account] + netReturn;
                //If there are referrals, they should be distributed to them
                if(winbill.referrer != address(0)) {
                    uint refReturn = (allReturn * referrerRate) / 10000;
                    fee = fee + (allReturn - netReturn - refReturn);
                    MyReturns[winbill.referrer] = MyReturns[winbill.referrer] + refReturn;
                } else {
                    fee = fee + (allReturn - netReturn);
                }
            }
        }

        NumberStatus[number].winTeam = winTeam;
        NumberStatus[number].status = 3;
        emit eventSettlement(NumberStatus[number]);
    }

    //Withdraw my income, including profit and recommendation reward
    function WithdrawReturn(uint amount) external {
        require(MyReturns[msg.sender] >= amount, "over your balance");
        require(bank.balanceOf(address(this)) >= amount, "over contract balance");
        
        bank.transfer(msg.sender, amount);
        MyReturns[msg.sender] = MyReturns[msg.sender] - amount;
        emit eventWithdrawReturn(msg.sender,amount,MyReturns[msg.sender]);
        
    }

    //Withdrawal of operating expenses
    function WithdrawFee(uint amount) external onlyCFO {
        require(fee >= amount, "over fee balance");
        require(bank.balanceOf(address(this)) >= amount, "over balance");
        
        bank.transfer(msg.sender, amount);
        fee = fee - amount;
        emit eventWithdrawFee(msg.sender,amount,fee);
    }

}