/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

/**
 *Submitted for verification at optimistic.etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.0;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}

contract SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract StakingProgram is Ownable, SafeMath {
    ERC20token public erc20tokenInstance;
    uint256 public stakingFee; // percentage
    uint256 public unstakingFee; // percentage
    uint256 public round = 1;
    uint256 public totalStakes = 0;
    uint256 public totalDividends = 0;
    uint256 public scaledRemainder = 0;
    uint256 constant private scaling = 10 ** 18;
    bool public stakingStopped = false;

    struct Staker {
        uint256 stakedTokens;
        uint256 round;
    }

    mapping(address => Staker) public stakers;
    mapping(address => bool) public whitelistedStakers;
    mapping(uint256 => uint256) public payouts;

    constructor(address _erc20token_address, uint256 _stakingFee, uint256 _unstakingFee) public {
        erc20tokenInstance = ERC20token(_erc20token_address);
        stakingFee = _stakingFee;
        unstakingFee = _unstakingFee;
    }

    // ==================================== EVENTS ====================================
    event staked(address indexed staker, uint256 tokens, uint256 fee);
    event unstaked(address indexed staker, uint256 tokens, uint256 fee);
    event payout(uint256 round, uint256 tokens, address indexed sender);
    event claimedReward(address indexed staker, uint256 reward);
    // ==================================== /EVENTS ====================================

    // ==================================== MODIFIERS ====================================
    modifier onlyWhitelistedStakers() {
        require(whitelistedStakers[msg.sender] == true);
        _;
    }

    modifier checkIfStakingStopped() {
        require(!stakingStopped, "ERROR: staking is stopped.");
        _;
    }
    // ==================================== /MODIFIERS ====================================

    // ==================================== CONTRACT ADMIN ====================================
    function stopUnstopStaking() external onlyOwner {
        if (!stakingStopped) {
            stakingStopped = true;
        } else {
            stakingStopped = false;
        }
    }

    function setFees(uint256 _stakingFee, uint256 _unstakingFee) external onlyOwner {
        require(_stakingFee <= 10 && _unstakingFee <= 10, "Invalid fees.");

        stakingFee = _stakingFee;
        unstakingFee = _unstakingFee;
    }

    function setWhitelistedStaker(address _address, bool _bool) external onlyOwner {
        whitelistedStakers[_address] = _bool;
    }
    // ==================================== /CONTRACT ADMIN ====================================

    // ==================================== CONTRACT BODY ====================================
    function stake(uint256 _tokens_amount) external checkIfStakingStopped {
        require(_tokens_amount > 0, "ERROR: invalid token amount.");
        require(erc20tokenInstance.transferFrom(msg.sender, address(this), _tokens_amount), "ERROR: tokens cannot be transferred from the sender.");

        uint256 _fee = 0;
        if (totalStakes > 0) {
            _fee = div(mul(_tokens_amount, stakingFee), 100);
        }

        uint256 pendingReward = getPendingReward(msg.sender);
        stakers[msg.sender].round = round;
        // saving user staked tokens minus the staking fee
        stakers[msg.sender].stakedTokens = add(sub(_tokens_amount, _fee), stakers[msg.sender].stakedTokens);

        // adding this user stake to the totalStakes
        totalStakes = add(totalStakes, sub(_tokens_amount, _fee));

        // if fee then spread it in the staking pool
        if (_fee > 0) {
            _addPayout(_fee);
        }

        // if existing rewards then send them to the staker
        if (pendingReward > 0) {
            require(erc20tokenInstance.transfer(msg.sender, pendingReward), "ERROR: error in sending reward from contract to sender.");
            emit claimedReward(msg.sender, pendingReward);
        }

        emit staked(msg.sender, sub(_tokens_amount, _fee), _fee);
    }

    function whitelistedStake(uint256 _tokens_amount, address _staker) external checkIfStakingStopped onlyWhitelistedStakers {
        require(_tokens_amount > 0, "ERROR: invalid token amount.");
        require(erc20tokenInstance.transferFrom(msg.sender, address(this), _tokens_amount), "ERROR: tokens cannot be transferred from sender.");

        uint256 _fee = 0;
        if (totalStakes > 0) {
            _fee = div(mul(_tokens_amount, stakingFee), 100);
        }

        uint256 pendingReward = getPendingReward(_staker);
        stakers[_staker].round = round;
        // saving user staked tokens minus the staking fee
        stakers[_staker].stakedTokens = add(sub(_tokens_amount, _fee), stakers[_staker].stakedTokens);

        // adding this user stake to the totalStakes
        totalStakes = add(totalStakes, sub(_tokens_amount, _fee));

        // if fee then spread it in the staking pool
        if (_fee > 0) {
            _addPayout(_fee);
        }

        // if existing rewards then send them to the staker
        if (pendingReward > 0) {
            require(erc20tokenInstance.transfer(_staker, pendingReward), "ERROR: error in sending reward from contract to sender.");
            emit claimedReward(_staker, pendingReward);
        }

        emit staked(_staker, sub(_tokens_amount, _fee), _fee);
    }

    function claimReward() external {
        uint256 pendingReward = getPendingReward(msg.sender);
        if (pendingReward > 0) {
            stakers[msg.sender].round = round; // update the round
            require(erc20tokenInstance.transfer(msg.sender, pendingReward), "ERROR: error in sending reward from contract to sender.");
            emit claimedReward(msg.sender, pendingReward);
        }
    }

    function unstake(uint256 _tokens_amount) external {
        require(_tokens_amount > 0 && stakers[msg.sender].stakedTokens >= _tokens_amount, "ERROR: invalid token amount to unstake.");

        uint256 pendingReward = getPendingReward(msg.sender);
        stakers[msg.sender].round = round;
        stakers[msg.sender].stakedTokens = sub(stakers[msg.sender].stakedTokens, _tokens_amount);

        // calculating this user unstaking fee based on the tokens amount that user want to unstake
        totalStakes = sub(totalStakes, _tokens_amount);

        // if totalStakes then spread the fee in the staking pool
        uint256 _fee = 0;
        if (totalStakes > 0) {
            _fee = div(mul(_tokens_amount, unstakingFee), 100);
            _addPayout(_fee);
        }

        // if existing rewards then add them to the unstaking amount
        uint256 _unstaking_amount = sub(_tokens_amount, _fee);
        if (pendingReward > 0) {
            _unstaking_amount = add(_unstaking_amount, pendingReward);
            emit claimedReward(msg.sender, pendingReward);
        }

        // sending to user desired token amount minus his unstacking fee
        require(erc20tokenInstance.transfer(msg.sender, _unstaking_amount), "ERROR: error in unstaking tokens.");

        emit unstaked(msg.sender, sub(_tokens_amount, _fee), _fee);
    }

    function addRewards(uint256 _tokens_amount) external checkIfStakingStopped {
        if (totalStakes > 0) {
            require(erc20tokenInstance.transferFrom(msg.sender, address(this), _tokens_amount), "ERROR: tokens cannot be transferred from sender.");
            _addPayout(_tokens_amount);
        }
    }

    function _addPayout(uint256 _fee) private {
        uint256 available = add(mul(_fee, scaling), scaledRemainder);
        uint256 dividendPerToken = div(available, totalStakes);
        scaledRemainder = mod(available, totalStakes);

        totalDividends = add(totalDividends, dividendPerToken);
        payouts[round] = add(payouts[round-1], dividendPerToken);
        round+=1;

        emit payout(round, _fee, msg.sender);
    }

    function getPendingReward(address _staker) public view returns(uint256) {
        return div(mul((sub(totalDividends, payouts[stakers[_staker].round - 1])), stakers[_staker].stakedTokens), scaling);
    }
    // ===================================== CONTRACT BODY =====================================
}

interface ERC20token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

// MN bby ¯\_(ツ)_/¯