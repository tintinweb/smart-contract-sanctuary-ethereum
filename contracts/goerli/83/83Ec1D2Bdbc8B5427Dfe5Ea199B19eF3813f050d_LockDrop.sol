/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
// File: lockDrop.sol
pragma solidity 0.8.1;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LockDrop  {

    address public rewardToken;
    address public usdt;
    address public owner;

    uint8 constant TEST_MONTHS = 2;
    uint8 constant SIX_MONTHS = 182;
    uint16 constant ONE_YEAR = 365;

    uint256 public tokenTotalSupply;
    uint256 public tokenCapacity;
    uint256 public ending;
    uint256 public constant TIMEUINT = 1 seconds;//  hardhat:seconds   eth:days  goerly: seconds
    uint256 public constant RELEASEUINT = 10 minutes; //hardhat: ( 6 seconds  ); eth: (182 days) ; goerly:( 10 minutes)

    struct Lock {
        uint amount;
        uint256 numOfTokens;
        uint256 releasedToken;
        uint256 lockEnding;
    }

    mapping ( uint => mapping (address => Lock) )  locks;
    event Deposit(address indexed sender, uint numOfTokens, uint lockIndex,uint lengthInDays);
    event Unlock(address indexed sender, uint lengthInDays);
    event Withdraw(address indexed sender, uint value,uint lengthInDays);

    modifier hasNotEnded() {
        require(block.timestamp <= ending, "lock-drop-ended");
        _;
    }

    modifier hasEnded() {
        require(block.timestamp  > ending, "lock-drop-still-active");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender   == owner,"need address is owner");
        _;
    }

    constructor()  {
        owner = msg.sender;
    }


    function initial( uint initTokenCapacity,address token ,uint lockJoinInDays, address initialUsdt)external  onlyOwner{

        require(initialUsdt != address(0),"usdt address wrong");
        require(initTokenCapacity>0,"tokenCapacity >0");
        require(token != address(0),"token address wrong");

        unchecked{
            ending = (block.timestamp + TIMEUINT*lockJoinInDays);
            usdt = initialUsdt;
        }

        tokenCapacity = initTokenCapacity;
        tokenTotalSupply = initTokenCapacity;
        rewardToken = token;

        bool success = IERC20(token).transferFrom(msg.sender, address(this), initTokenCapacity);


    require(success, "Call failed");
    }

    function adminWithDraw()external onlyOwner{
        require(block.timestamp> ending+ (ONE_YEAR * TIMEUINT) + RELEASEUINT,"now time  is not valid");
        bool successUsdt = IERC20(usdt).transfer(msg.sender,IERC20(usdt).balanceOf(address(this)));
        require(successUsdt, "Call failed");
        bool successRewardToken = IERC20(rewardToken).transfer(msg.sender,tokenCapacity);
        require(successRewardToken, "Call failed");
    }

    function lockERC20(uint lengthInDays,uint initAmount)  external hasNotEnded {

        require(initAmount >0 ,"invalid-value");
        require(tokenCapacity > 0, "no-more-tokens-available");
        require(lengthInDays ==TEST_MONTHS || lengthInDays ==  SIX_MONTHS || lengthInDays == ONE_YEAR,"invalid-lengtInDays");

        unchecked{
            uint _numOfTokens =(initAmount*uint(2));
            require(_numOfTokens <= tokenCapacity, "amount-exceeds-available-tokens");
            tokenCapacity = (tokenCapacity - _numOfTokens);
            if (locks[lengthInDays][msg.sender].amount == 0){
                Lock memory l = Lock({
                amount: initAmount,
                numOfTokens: _numOfTokens,
                lockEnding: ( ending+ (lengthInDays* TIMEUINT)),
                releasedToken:0
                });
                locks[lengthInDays][msg.sender]=l;
            }else{
                locks[lengthInDays][msg.sender].amount = (locks[lengthInDays][msg.sender].amount + initAmount);
                locks[lengthInDays][msg.sender].numOfTokens = (locks[lengthInDays][msg.sender].numOfTokens + _numOfTokens);
            }
            emit Deposit(msg.sender, _numOfTokens, initAmount,lengthInDays);

            bool success = IERC20(usdt).transferFrom(msg.sender, address(this), initAmount);
            require(success, "Call failed");
        }
    }

    function unlock(uint lengthInDays) external hasNotEnded {

        require(locks[lengthInDays][msg.sender].amount > 0, "deposit-already-unlocked");
        Lock memory l = locks[lengthInDays][msg.sender];
        delete locks[lengthInDays][msg.sender];
        unchecked{
            tokenCapacity = (tokenCapacity +  l.numOfTokens);
        }
        emit Unlock(msg.sender, lengthInDays);
        bool success =  IERC20(usdt).transfer(msg.sender,  l.amount);
        require(success, "Call failed");

    }

    function withdraw(uint lengthInDays) external hasEnded {
        require((locks[lengthInDays][msg.sender].numOfTokens - locks[lengthInDays][msg.sender].releasedToken) > 0,
            "no-token-withdraw");
        Lock memory l = locks[lengthInDays][msg.sender];
        unchecked{
            uint256 rewardAmount = vestedAmount( l , uint256(block.timestamp)  );
            locks[lengthInDays][msg.sender].releasedToken += rewardAmount;

            require(rewardAmount > 0, "no-locked-amount-found");

            emit Withdraw(msg.sender, rewardAmount,lengthInDays);

            bool success = IERC20(rewardToken).transfer(msg.sender,  rewardAmount);
            require(success, "Call failed");
        }
    }

    function getTotalLocks(address user,uint lengthInDays) external view returns (uint _length) {
        return locks[lengthInDays][user].releasedToken;
    }

    function getLockAt(address user, uint lengthInDays) external view returns (uint amount, uint numOfTokens, uint lockEnding,uint releaseToken) {
        return (locks[lengthInDays][user].amount, locks[lengthInDays][user].numOfTokens, locks[lengthInDays][user].lockEnding,locks[lengthInDays][user].releasedToken);
    }

    function vestedAmount(Lock  memory lock ,uint256 timestamp ) public pure returns (uint256) {

        unchecked{
            if (timestamp < lock.lockEnding) {
                return 0;
            } else if (timestamp > lock.lockEnding + RELEASEUINT ) {
                return lock.numOfTokens  - lock.releasedToken ;
            } else {
                return (lock.numOfTokens * (timestamp - lock.lockEnding)) / RELEASEUINT  - lock.releasedToken;
            }
        }
        }
}