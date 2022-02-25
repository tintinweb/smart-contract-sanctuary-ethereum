/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT



interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ADAMSTAKE{
       function stakedetails(address add, uint256 count)
        external
        view
        returns (
        // uint256 stakeTime,
        uint256 withdrawTime,
        uint256 amount,
        uint256 bonus,
        uint256 plan,
        bool withdrawan
        );

    function users(address)external returns(uint256,uint256,uint256);
}




contract StakeContract {
    using SafeMath for uint256;

    //Variables
    IBEP20 public wolveToken;
    IBEP20 public amdToken;
    ADAMSTAKE public stakeInstance;

    address payable public owner;
    uint256 public totalUniqueStakers;
    uint256 public totalStaked;
    uint256 public calculatedfee;
    uint256 public minStake;
    uint256 public constant percentDivider = 100000;

    //arrays
    uint256[4] public percentages = [500, 1500, 5000, 10000];
    uint256[4] public durations = [10 minutes, 15 minutes, 20 minutes, 25 minutes];

    
    //structures
    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
        bool unstaked;
        int transactions;
    }

    struct User {
        uint256 totalstakeduser;
        uint256 stakecount;
        uint256 claimedstakeTokens;
        uint256 unStakedTokens;
        mapping(uint256 => Stake) stakerecord;
    }
    
    //mappings
    mapping(address => uint256) deductedAmount;
    mapping(address => User) public users;
    mapping(address => bool) public uniqueStaker;
    uint256 public totalWolveStakeToken;
    uint256 public totalAmdStakeToken;
    uint256 public totalWolveRewardToken;
    uint256 public totalAmdRewardToken;



    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: Not an owner");
        _;
    }

    //events
    event Staked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );


    event UnStaked(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event Withdrawn(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event ExtenderStake(
        address indexed _user,
        uint256 indexed _amount,
        uint256 indexed _Time
    );

    event UNIQUESTAKERS(address indexed _user);

    // constructor
    constructor(address wolve, address amd,address amdStaking) {
        owner = payable(msg.sender);
        wolveToken = IBEP20(wolve);
        amdToken = IBEP20(amd);
        stakeInstance=ADAMSTAKE(amdStaking);
        minStake = 5e18;
    }

    // functions


    //writeable
    function stakeWithWolve(uint256 amount, uint256 plan) public {
        require(plan >= 0 && plan < 4, "put valid plan details");
        require(amount >= minStake,"cant deposit need to stake more than minimum amount");
        
        if (!uniqueStaker[msg.sender]) {
            uniqueStaker[msg.sender] = true;
            totalUniqueStakers++;
            emit UNIQUESTAKERS(msg.sender);
        }
        
        User storage user = users[msg.sender];
        wolveToken.transferFrom(msg.sender, address(this), amount);
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
        user.stakerecord[user.stakecount].transactions = 1;
        user.stakecount++;
        totalStaked += amount;
        totalWolveStakeToken+=amount;
        emit Staked(msg.sender, amount, block.timestamp);

        
        uint256 value1 = 10; // percentage that how much amount that was deducted in Wolvrine token
        uint256 deductedAmount1 = amount.mul(value1).div(100); //amount that was deducted in Wolvrine token

        // mapping(address => uint256) deductedAmount;

        deductedAmount[msg.sender] = deductedAmount1;

    }


function stakeWithAmd(uint256 amount, uint256 plan) public {
        require(plan >= 0 && plan < 4, "put valid plan details");
        require(
            amount >= minStake,
            "cant deposit need to stake more than minimum amount"
        );
        if (!uniqueStaker[msg.sender]) {
            uniqueStaker[msg.sender] = true;
            totalUniqueStakers++;
            emit UNIQUESTAKERS(msg.sender);
        }
        User storage user = users[msg.sender];
        amdToken.transferFrom(msg.sender, address(this), amount);
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
        user.stakerecord[user.stakecount].transactions = 2;
        user.stakecount++;
        totalStaked += amount;
        totalAmdStakeToken+=amount;
        emit Staked(msg.sender, amount, block.timestamp);
    }



    function withdrawInWolve(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(!user.stakerecord[count].unstaked," withdraw completed ");
        
        wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
       
       // transfer the deducted amount of tokens from owner to the user account
       if(user.stakerecord[user.stakecount].transactions == 1){

            wolveToken.transferFrom(owner,msg.sender,deductedAmount[msg.sender]); 
       }

        user.claimedstakeTokens += user.stakerecord[count].amount;
        user.claimedstakeTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        totalWolveRewardToken+= user.stakerecord[count].bonus;
        emit Withdrawn(msg.sender,user.stakerecord[count].amount,block.timestamp);
            
    }


    function withdrawInAmd(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(!user.stakerecord[count].unstaked," withdraw completed ");
       
        amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        
        user.claimedstakeTokens += user.stakerecord[count].amount;
        user.claimedstakeTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        totalAmdRewardToken+= user.stakerecord[count].bonus;

        if(user.stakerecord[user.stakecount].transactions == 1){
           
            wolveToken.transferFrom(owner,msg.sender,deductedAmount[msg.sender]); 
        }

        emit Withdrawn(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp);
    }
    
    function extendStake(uint256 count,uint256 newplan) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(newplan >= 0 && newplan < 4 ,"Enter Valid Plan");
        require(user.stakerecord[count].plan < newplan, "Can not extend to lower plan");
        
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        user.stakerecord[count].plan = newplan ;
        user.stakerecord[user.stakecount].withdrawTime = user.stakerecord[count].stakeTime.add(durations[user.stakerecord[count].plan]);
        user.stakerecord[user.stakecount].bonus = (user.stakerecord[count].amount.mul(percentages[user.stakerecord[count].plan])).div(percentDivider);
        emit ExtenderStake(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }

    function unstakeOfWolve(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        wolveToken.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        user.unStakedTokens += user.stakerecord[count].amount;
        user.stakerecord[count].unstaked = true;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }

    function unstakeOfAmd(uint256 count) public {
        User storage user = users[msg.sender];
        require(user.stakecount >= count, "Invalid Stake index");
        require(
            !user.stakerecord[count].withdrawan,
            " withdraw completed "
        );
        require(
            !user.stakerecord[count].unstaked,
            " unstake completed "
        );
        amdToken.transfer(
            msg.sender,
            user.stakerecord[count].amount
        );
        user.unStakedTokens += user.stakerecord[count].amount;
        user.stakerecord[count].unstaked = true;
        emit UnStaked(
            msg.sender,
            user.stakerecord[count].amount,
            block.timestamp
        );
    }

    function migrateV1() external onlyOwner returns (bool){
    User storage user=users[msg.sender];
       (uint256 totalstakeduser,
        uint256 stakecount,
        uint256 claimedstakeTokens)=stakeInstance.users(msg.sender);

        require(stakecount>0,"you are not old investor");



        user.totalstakeduser=totalstakeduser;
        user.stakecount=stakecount;
        user.claimedstakeTokens=claimedstakeTokens;
        for(uint256 i=0;i>stakecount;i++){
            (uint256 withdrawTime,
        uint256 amount,
        uint256 bonus,
        uint256 plan,
        bool withdrawan)=stakeInstance.stakedetails(msg.sender,i);
        


        user.totalstakeduser=totalstakeduser;
        user.stakecount=stakecount;
        user.claimedstakeTokens=claimedstakeTokens;
    
        user.stakerecord[i].plan = plan;
        user.stakerecord[i].stakeTime = block.timestamp;
        user.stakerecord[i].amount = amount;
        user.stakerecord[i].withdrawTime = withdrawTime;
        user.stakerecord[i].bonus = bonus;
        user.stakerecord[i].withdrawan=withdrawan;
        }
        totalUniqueStakers++;
        return true;

    }


    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function migrateStuckFunds() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function migratelostToken(address lostToken) external onlyOwner {
        IBEP20(lostToken).transfer(
            owner,
            IBEP20(lostToken).balanceOf(address(this))
        );
    }

    //readable
    
    function stakedetails(address add, uint256 count)
        public
        view
        returns (
        // uint256 stakeTime,
        uint256 withdrawTime,
        uint256 amount,
        uint256 bonus,
        uint256 plan,
        bool withdrawan,
        // bool unstaked,
        int transactions
        )
    {
        return (
            // users[add].stakerecord[count].stakeTime,
            users[add].stakerecord[count].withdrawTime,
            users[add].stakerecord[count].amount,
            users[add].stakerecord[count].bonus,
            users[add].stakerecord[count].plan,
            users[add].stakerecord[count].withdrawan,
            // users[add].stakerecord[count].unstaked,
            users[add].stakerecord[count].transactions
        );
    }



        function stakedetails1(address add, uint256 count)
        public
        view
        returns (
        uint256 stakeTime,

        bool unstaked
        )
    {
        return (
            users[add].stakerecord[count].stakeTime,

            users[add].stakerecord[count].unstaked

        );
    }

    function calculateRewards(uint256 amount, uint256 plan)
        external
        view
        returns (uint256)
    {
        return amount.mul(percentages[plan]).div(percentDivider);
    }

    function currentStaked(address add) external view returns (uint256) {
        uint256 currentstaked;
        for (uint256 i; i < users[add].stakecount; i++) {
            if (!users[add].stakerecord[i].withdrawan) {
                currentstaked += users[add].stakerecord[i].amount;
            }
        }
        return currentstaked;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractstakeTokenBalanceOfWolve() external view returns (uint256) {
        return wolveToken.allowance(owner, address(this));
    }

    function getContractstakeTokenBalanceOfAmd() external view returns (uint256) {
        return amdToken.allowance(owner, address(this));
    }

    function getCurrentwithdrawTime() external view returns (uint256) {
        return block.timestamp;
    }
}

//library
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}