/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}
contract TokenVest{
    using SafeMath for uint256;
    IERC20 public vestedToken;
    uint256 public releaseInterval;
    uint256 public lockingPeriod;
    uint256 public releasePer;
    IERC20 public otherToken;

    address payable public owner;

    uint256 public totalAddedToken; // total no of tokens vested in contract
    uint256 public totalReleasedToken; // total released tokens 
    uint256 public RemainToken;
    uint256 public totalVestor; // total no. of vestors
    uint256 public percentDivider;
    uint256 public minimumLimit;

    struct VestToken {
        uint256 lockedtilltime;
        uint256 vesttime;
        uint256 amount;
        uint256 completewithdrawtill;
        uint256 persecondLimit;
        uint256 lastWithdrawalTime;
        uint256 totalWithdrawal;
        uint256 remainWithdrawal;
        uint256 releaseinterval;
        uint256 releaseperperinterval;
        bool withdrawan;
    }

    struct User {
        uint256 totalVestedTokenUser;
        uint256 totalWithdrawedTokenUser;
        uint256 vestCount;
        bool alreadyExists;
    }

    mapping(address => User) public Vestors;
    mapping(uint256 => address) public VesterID;
    mapping(address => mapping(uint256 => VestToken)) public vestorRecord;

    event VEST(address Vestors, uint256 amount);
    event RELEASE(address Vestors, uint256 amount);


    modifier onlyowner() {
        require(owner == msg.sender, "only owner");
        _;
    }
    constructor(address payable _owner, address mainToken) {
        owner = _owner;
        vestedToken = IERC20(mainToken); // address of token that we will stake or vest
        lockingPeriod = 120; // locking period in days or no of seconds like 3600 for 1 hour
        releaseInterval = 60; // release interval in days or seconds
        releasePer = 50; // release percentage per interval valuse will be multiplied with 10
        percentDivider = 1000;
        minimumLimit = 1e20; // minimum limit for the vesting in wei
    }

    /** This method is used to deposit amount in contract 
	* amount will be in wei */
    function vest(uint256 amount) public {
       
        require(amount >= minimumLimit, "vest more than minimum amount");
    
        if (!Vestors[msg.sender].alreadyExists) {
            Vestors[msg.sender].alreadyExists = true;
            VesterID[totalVestor] = msg.sender;
            totalVestor++;
        }

        vestedToken.transferFrom(msg.sender, address(this), amount);

        uint256 index = Vestors[msg.sender].vestCount;
        Vestors[msg.sender].totalVestedTokenUser = Vestors[msg.sender]
            .totalVestedTokenUser
            .add(amount);
        totalAddedToken = totalAddedToken.add(amount);
        RemainToken = RemainToken.add(amount);
        vestorRecord[msg.sender][index].lockedtilltime = block.timestamp.add(
            lockingPeriod
        );
        vestorRecord[msg.sender][index].vesttime = block.timestamp;
        vestorRecord[msg.sender][index].amount = amount;
        vestorRecord[msg.sender][index].completewithdrawtill = vestorRecord[msg.sender][index].lockedtilltime.add((percentDivider.div(releasePer)).mul(releaseInterval));
        vestorRecord[msg.sender][index].lastWithdrawalTime = 0;
        vestorRecord[msg.sender][index].totalWithdrawal = 0;
        vestorRecord[msg.sender][index].remainWithdrawal = amount;

        vestorRecord[msg.sender][index].releaseinterval = releaseInterval;
        vestorRecord[msg.sender][index].releaseperperinterval = releasePer;

        vestorRecord[msg.sender][index].persecondLimit = amount.div((percentDivider.div(releasePer)).mul(releaseInterval));

        Vestors[msg.sender].vestCount++;

        emit VEST(msg.sender, amount);
    }

   /** This method will used to withdraw vested token 
	* before release, the token will be locked for the locking duration, and then it will release the set percentage for the set period */
    function releaseToken(uint256 index) public {
        require(
            !vestorRecord[msg.sender][index].withdrawan,
            "already withdrawan"
        );
        require(
            vestorRecord[msg.sender][index].lockedtilltime < block.timestamp,
            "cannot release token before locked duration"
        );

        uint256 releaseLimitTillNow;
        uint256 commontimestamp;
        (releaseLimitTillNow,commontimestamp) = realtimeReleasePerBlock(msg.sender , index);
        
        vestedToken.transfer(
            msg.sender,
            releaseLimitTillNow
        );

        totalReleasedToken = totalReleasedToken.add(
            releaseLimitTillNow
        );
        RemainToken = RemainToken.sub(releaseLimitTillNow);
        
        vestorRecord[msg.sender][index].lastWithdrawalTime =  commontimestamp;
        
        vestorRecord[msg.sender][index].totalWithdrawal = vestorRecord[msg.sender][index].totalWithdrawal.add(releaseLimitTillNow);

        vestorRecord[msg.sender][index].remainWithdrawal = vestorRecord[msg.sender][index].remainWithdrawal.sub(releaseLimitTillNow);

        Vestors[msg.sender].totalWithdrawedTokenUser = Vestors[msg.sender].totalWithdrawedTokenUser.add(releaseLimitTillNow);

        if(vestorRecord[msg.sender][index].totalWithdrawal == vestorRecord[msg.sender][index].amount){
            vestorRecord[msg.sender][index].withdrawan = true;

        }

        emit RELEASE(
            msg.sender,
            releaseLimitTillNow
        );
    }

    /** This method will return realtime release amount for particular user's block */
    function realtimeReleasePerBlock(address user, uint256 blockno) public view returns (uint256,uint256) {

        uint256 ret;
        uint256 commontimestamp;
            if (
                !vestorRecord[user][blockno].withdrawan &&
                vestorRecord[user][blockno].lockedtilltime < block.timestamp
            ) {
                uint256 val;
                uint256 tempwithdrawaltime = vestorRecord[user][blockno].lastWithdrawalTime;
                commontimestamp = block.timestamp;
                if(tempwithdrawaltime == 0){
                    tempwithdrawaltime = vestorRecord[user][blockno].lockedtilltime;
                }
                val = commontimestamp - tempwithdrawaltime;
                val = val.mul(vestorRecord[user][blockno].persecondLimit);
                if (val < vestorRecord[user][blockno].remainWithdrawal) {
                    ret += val;
                } else {
                    ret += vestorRecord[user][blockno].remainWithdrawal;
                }
            }
        return (ret,commontimestamp);
    }

    /** This method can only be invoked by the owner's address and is used to adjust the Release Interval; the argument will be in seconds */

    function SetReleaseInterval(uint256 val) external onlyowner {
        releaseInterval = val;
    }

    
    function SetReleasePercentage(uint256 val) external onlyowner {
        releasePer = val;
    }

    /** This method can only be invoked by the owner's address and is used to adjust the vesting duration (locking period), the argument will be in seconds */
    function SetLockingPeriod(uint256 val) external onlyowner {
        lockingPeriod = val;
    }

    /** The base currency is withdrawn using this method */

    function withdrawBaseCurrency() public onlyowner {
        uint256 balance = address(this).balance;
        require(balance > 0, "does not have any balance");
        payable(msg.sender).transfer(balance);
    }

    /** These two methods will enable the contract owner in withdrawing any incorrectly deposited tokens
    * first call initToken method with passing token contract address as an argument 
    * then, as an argument, call withdrawToken with the value in wei */

    function initToken(address addr) public onlyowner{
        otherToken = IERC20(addr);
    }
    function withdrawToken(uint256 amount) public onlyowner {
        otherToken.transfer(msg.sender
        , amount);
    }

}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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