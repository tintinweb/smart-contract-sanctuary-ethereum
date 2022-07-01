// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract TokenStaking is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    event Newbie(address user, uint256 registerTime);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 apr,
        uint256 amount,
        uint256 start,
        uint256 finish,
        uint256 fee
    );
    event UnStake(
        address indexed user,
        uint256 start,
        uint256 amount,
        uint256 profit
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    uint256 public PROJECT_FEE = 0 ether;
    uint256 public UNLOCK_FEE = 0.005 ether;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public TIME_STEP = 1 days;
    uint256 public TIME_STAKE = 0 minutes;
    IERC20 public stakingToken;

    uint256 public totalStakedAmount;

    struct Plan {
        uint256 time;
        uint256 fixedInvest;
        uint256 apr;
        uint256 totalStakedAmount;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 apr;
        uint256 amount;
        uint256 start;
        uint256 finish;
        address userAddress;
        uint256 fee;
        bool isUnStake;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address owner;
        uint256 registerTime;
        uint256 lastStake;
    }

    mapping(address => User) users;

    address payable public commissionWallet;

    /**
     * @dev Constructor function
     */
    constructor(address payable wallet, IERC20 _bep20) public {
        commissionWallet = wallet;
        stakingToken = _bep20;
        plans.push(Plan(30, 1000000 * 10**18, 477, 0));
        plans.push(Plan(60, 2000000 * 10**18, 655, 0));
        plans.push(Plan(90, 2500000 * 10**18, 877, 0));
        plans.push(Plan(120, 3000000 * 10**18, 1255, 0));
        plans.push(Plan(180, 40000000 * 10**18, 1777, 0));
    }

    function invest(uint8 plan, uint256 _amount)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            _amount == plans[plan].fixedInvest,
            "Invest amount isn't enough"
        );
        require(plans[plan].fixedInvest > 0, "Invalid plan");
        require(
            stakingToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        _invest(plan, msg.sender, _amount);
        if (PROJECT_FEE > 0) {
            commissionWallet.transfer(PROJECT_FEE);
            emit FeePayed(msg.sender, PROJECT_FEE);
        }
    }

    function _invest(
        uint8 plan,
        address userAddress,
        uint256 _amount
    ) internal {
        User storage user = users[userAddress];
        Plan storage planStore = plans[plan];
        uint256 currentTime = block.timestamp;
        require(
            user.lastStake.add(TIME_STAKE) <= currentTime,
            "Required: Must be take time to stake"
        );
        _safeTransferFrom(userAddress, address(this), _amount);
        user.lastStake = currentTime;
        user.owner = userAddress;
        user.registerTime = currentTime;

        if (user.deposits.length == 0) {
            user.checkpoint = currentTime;
            emit Newbie(userAddress, currentTime);
        }

        (uint256 apr, uint256 finish) = getResult(plan);
        user.deposits.push(
            Deposit(
                plan,
                apr,
                _amount,
                currentTime,
                finish,
                userAddress,
                PROJECT_FEE,
                false
            )
        );
        totalStakedAmount = totalStakedAmount.add(_amount);
        planStore.totalStakedAmount = planStore.totalStakedAmount.add(_amount);
        emit NewDeposit(
            userAddress,
            plan,
            apr,
            _amount,
            currentTime,
            finish,
            PROJECT_FEE
        );
    }

    function _safeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        bool sent = stakingToken.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }

    function unStake(uint256 start)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(msg.value == UNLOCK_FEE, "Required: Pay fee for unlock stake");
        User storage user = users[msg.sender];
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].start == start &&
                user.deposits[i].isUnStake == false &&
                block.timestamp >= user.deposits[i].finish
            ) {
                user.deposits[i].isUnStake = true;
                uint256 profit = user.deposits[i].amount.mul(user.deposits[i].apr).div(PERCENTS_DIVIDER);
                stakingToken.transfer(_msgSender(), user.deposits[i].amount.add(profit));
                emit UnStake(
                    msg.sender,
                    start,
                    user.deposits[i].amount,
                    profit
                );
                if (UNLOCK_FEE > 0) {
                    commissionWallet.transfer(UNLOCK_FEE);
                    emit FeePayed(msg.sender, UNLOCK_FEE);
                }
            }
        }
    }

    function setFeeSystem(uint256 _fee) external onlyOwner {
        PROJECT_FEE = _fee;
    }

    function setUnlockFeeSystem(uint256 _fee) external onlyOwner {
        UNLOCK_FEE = _fee;
    }

    function setTime_Step(uint256 _timeStep) external onlyOwner {
        TIME_STEP = _timeStep;
    }

    function setTime_Stake(uint256 _timeStake) external onlyOwner {
        TIME_STAKE = _timeStake;
    }

    function setCommissionsWallet(address payable _addr) external onlyOwner {
        commissionWallet = _addr;
    }

    function updatePlan(uint256 planId, Plan memory plan)
        external
        onlyOwner
    {
        plans[planId] = plan;
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner{
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }

    function getResult(uint8 plan)
        public
        view
        returns (uint256 apr, uint256 finish)
    {
        apr = plans[plan].apr;

        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (User memory userInfo)
    {
        userInfo = users[userAddress];
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

    function getPlanInfo(uint8 planId) public view returns (Plan memory plan) {
        plan = plans[planId];
    }

    function isUnStake(address userAddress, uint256 start)
        public
        view
        returns (bool _isUnStake)
    {
        User storage user = users[userAddress];
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].start == start) {
                _isUnStake = user.deposits[i].isUnStake;
            }
        }
    }

    function getAllDepositsByAddress(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        User memory user = users[userAddress];
        return user.deposits;
    }
}