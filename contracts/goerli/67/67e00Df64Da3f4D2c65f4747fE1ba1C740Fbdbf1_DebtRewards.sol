pragma solidity 0.6.7;

abstract contract TokenLike {
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual external returns (bool);
}
abstract contract RewardDripperLike {
    function dripReward(address) virtual external;
    function rewardPerBlock() virtual external view returns (uint256);
    function rewardToken() virtual external view returns (TokenLike);
}

abstract contract SafeEngineLike {
    function canModifySAFE(address,address) external virtual view returns (bool);
}

// Stores tokens, owned by DebtRewards
contract TokenPool {
    TokenLike public immutable token;
    address   public immutable owner;

    constructor(address token_) public {
        token = TokenLike(token_);
        owner = msg.sender;
    }

    // @notice Transfers tokens from the pool (callable by owner only)
    function transfer(address to, uint256 wad) public {
        require(msg.sender == owner, "unauthorized");
        require(token.transfer(to, wad), "TokenPool/failed-transfer");
    }

    // @notice Returns token balance of the pool
    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

// @notice Do not use tokens with transfer callbacks with this contract
contract DebtRewards {
    // Staked Supply (== sum of all debt balances)
    uint256                     public totalDebt; 
    // Amount of rewards per share accumulated (total, see rewardDebt for more info)
    uint256                     public accTokensPerShare;
    // Balance of the rewards token in this contract since last update
    uint256                     public rewardsBalance;    
    // Last block when a reward was pulled
    uint256                     public lastRewardBlock;    
    // Balances
    mapping(address => uint256) public debtBalanceOf;
    // The amount of tokens inneligible for claiming rewards (see formula below)
    mapping(address => uint256) internal rewardDebt;
    // Pending reward = (descendant.balanceOf(user) * accTokensPerShare) - rewardDebt[user]    
    mapping(address => uint256) internal rewardPendingPayment;
    // Rewwards to be paid for each safe

    //  SafeEngine
    SafeEngineLike    immutable public safeEngine;
    // Contract that drips rewards
    RewardDripperLike immutable public rewardDripper;        
    // Reward Pool
    TokenPool         immutable public rewardPool;      
    // Tokens accrued by users, pending pull withdraw
    TokenPool         immutable public userPool;   

    // --- Events ---
    event DebtSet(address indexed safe, uint256 amount);
    event RewardsPaid(address account, uint256 amount);
    event PoolUpdated(uint256 accTokensPerShare, uint256 stakedSupply);    

    // --- Math ---
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant RAY = 10 ** 27;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DebtRewards/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "DebtRewards/sub-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "DebtRewards/mul-overflow");
    }

    constructor(
        address safeEngine_,
        address rewardDripper_
    ) public {
        require(rewardDripper_ != address(0), "DebtRewards/null-reward-dripper");
        require(safeEngine_ != address(0), "DebtRewards/null-safe-engine");

        safeEngine    = SafeEngineLike(safeEngine_);
        rewardDripper = RewardDripperLike(rewardDripper_);
        rewardPool    = new TokenPool(address(RewardDripperLike(rewardDripper_).rewardToken()));
        userPool      = new TokenPool(address(RewardDripperLike(rewardDripper_).rewardToken()));
    }

    /*
    * @notice Returns unclaimed rewards for a given user
    */
    function pendingRewards(address user) public view returns (uint256) {
        uint accTokensPerShare_ = accTokensPerShare;
        if (block.number > lastRewardBlock && totalDebt != 0) {
            uint increaseInBalance = multiply(subtract(block.number, lastRewardBlock), rewardDripper.rewardPerBlock());
            accTokensPerShare_ = addition(accTokensPerShare_, multiply(increaseInBalance, RAY) / totalDebt);
        }
        return subtract(multiply(debtBalanceOf[user], accTokensPerShare_) / RAY, rewardDebt[user]);
    }

    /*
    * @notice Returns rewards earned per block for each token deposited (WAD)
    */
    function rewardRate() public view returns (uint256) {
        if (totalDebt == 0) return 0;
        return multiply(rewardDripper.rewardPerBlock(), WAD) / totalDebt;
    }

    // --- Core Logic ---
    /*
    * @notice Updates the pool and pays rewards (if any)
    * @dev Must be included in deposits and withdrawals
    * @param who Account for whom to recompute the rewards
    */
    modifier computeRewards(address who) {
        updatePool();

        if (debtBalanceOf[who] > 0 && rewardPool.balance() > 0) {
            // Pays the reward
            uint256 pending = subtract(multiply(debtBalanceOf[who], accTokensPerShare) / RAY, rewardDebt[who]);

            rewardPool.transfer(address(userPool), pending);
            rewardPendingPayment[who] = addition(rewardPendingPayment[who], pending);

            rewardsBalance = rewardPool.balance();

            emit RewardsPaid(who, pending);
        }
        _;
        rewardDebt[who] = multiply(debtBalanceOf[who], accTokensPerShare) / RAY;
    }

    /*
    * @notice Pays outstanding rewards to msg.sender
    */
    function getRewards() external computeRewards(msg.sender) {
        userPool.transfer(msg.sender, rewardPendingPayment[msg.sender]);
        rewardPendingPayment[msg.sender] = 0;
    }

    /*
    * @notice Pays outstanding rewards to a user set as param
    * @dev Any address authed on safeEngine to manage the safe can call this funcion
    * @param from Account from witch to claim rewards
    * @param to Address rewards will be sent to
    */
    function getRewards(address from, address to) external computeRewards(from) {
        require(safeEngine.canModifySAFE(from, msg.sender), "DebtRewards/unauthed");
        userPool.transfer(to, rewardPendingPayment[from]);
        rewardPendingPayment[from] = 0;
    }    

    /*
    * @notice Pull funds from the dripper
    */
    function pullFunds() public {
        rewardDripper.dripReward(address(rewardPool));
    }

    /*
    * @notice Updates pool data
    */
    function updatePool() public {
        if (block.number <= lastRewardBlock) return;
        lastRewardBlock = block.number;
        if (totalDebt == 0) return;

        pullFunds();
        uint256 increaseInBalance = subtract(rewardPool.balance(), rewardsBalance);
        rewardsBalance = addition(rewardsBalance, increaseInBalance);

        // Updates distribution info
        accTokensPerShare = addition(accTokensPerShare, multiply(increaseInBalance, RAY) / totalDebt);
        emit PoolUpdated(accTokensPerShare, totalDebt);
    }

    /*
    * @notice Set a safe debt
    * @param who Owner of the safe
    * @param wad Current debt of the safe
    * @dev Only safeEngine can call this function
    */
    function setDebt(address who, uint256 wad) external computeRewards(who) {
        require(msg.sender == address(safeEngine), "DebtRewards/unauthed");
        if (debtBalanceOf[who] > wad)
            totalDebt = subtract(totalDebt, debtBalanceOf[who] - wad);
        else
            totalDebt = addition(totalDebt, wad - debtBalanceOf[who]);
        
        debtBalanceOf[who] = wad;

        emit DebtSet(who, wad);
    }
}