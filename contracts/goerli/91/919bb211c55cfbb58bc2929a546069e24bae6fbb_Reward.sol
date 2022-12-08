/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.10;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File: contracts/Reward.sol

pragma solidity ^0.8.10;
contract Reward{
    struct Pool{
        uint256 poolId;
        address owner;
        IERC20Metadata  depositToken;
        IERC20Metadata  rewardToken;
        uint8   depositTokenDecimal;
        uint256 supply;
        uint256 depositAmount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardShare;
        uint256 rewardPerBlock;
        uint256 lastUpdateBlock;
    }
    
    struct User{
        address user;
        IERC20Metadata  token;
        uint256 amount;
        uint256 depositBlock;
    }

    uint256 public poolId;
    uint256 public fee = 3;
    address public feeAddress;
    mapping(uint256 => Pool) public pools;
    mapping(address => mapping(uint256 =>User)) public  users;


    constructor(uint256 feePercent,address feeDest){
        fee = feePercent;
        feeAddress =  feeDest;
    }

    function createPool(IERC20Metadata depositToken,IERC20Metadata rewardToken,uint256 supply,uint256 startBlock,uint256 endBlock) external{
        require(endBlock > startBlock,"end block must bigger than start block");
        poolId ++;
        pools[poolId].poolId = poolId;
        pools[poolId].owner = msg.sender;
        pools[poolId].depositToken = depositToken;
        pools[poolId].rewardToken = rewardToken;
        pools[poolId].depositTokenDecimal = depositToken.decimals();
        pools[poolId].supply = supply;
        pools[poolId].startBlock = startBlock;
        pools[poolId].lastUpdateBlock = startBlock;
        pools[poolId].endBlock = endBlock;
        pools[poolId].rewardPerBlock = supply/(endBlock-startBlock);

        rewardToken.transferFrom(msg.sender,address(this), supply);
    }

    function deposit(uint256 depositPoolId,IERC20Metadata token, uint256 amount) external{
        Pool memory pool =  pools[poolId];
        require(pool.endBlock >= block.number  && pool.startBlock <= block.number,"pool not exist or already end");
        require(pool.depositToken == token,"not support token");
        pools[poolId].depositAmount += amount;

        claimRewards(depositPoolId);

        User memory user = users[msg.sender][depositPoolId];
        user.token = token;
        user.amount += amount;
        user.user = msg.sender;
        user.depositBlock = block.number;
        users[msg.sender][poolId]  = user;
        
        token.transferFrom(msg.sender,address(this), amount);
    }

    function claimRewards(uint256 claimPoolId) public{
        updateReward(claimPoolId);
        uint256 reward = rewards(claimPoolId);
        if (reward == 0){
            return;
        }

        IERC20Metadata token = pools[claimPoolId].rewardToken;
        
        uint256 userReward = reward*(100-fee)/100;
        uint256 rewardFee = reward - userReward;
        if (userReward > 0 ){
            token.transfer(msg.sender, userReward);
        }
        if (rewardFee > 0){
            token.transfer(feeAddress, rewardFee);
        }
    }

    function withdraw(uint256 withdrawPoolId,bool isEmergecy) internal{
        claimRewards(withdrawPoolId);
        Pool memory pool = pools[withdrawPoolId];
        IERC20Metadata token = pool.depositToken;
        uint256 balance = users[msg.sender][withdrawPoolId].amount;
        if (balance == 0 ){
            return;
        }
        
        if (!isEmergecy){
            users[msg.sender][withdrawPoolId].amount = 0;
            token.transfer(msg.sender,balance);
            return;
        }

        uint256 userBalance = (100-fee)*balance/100;
        uint256 feeBalance = balance - userBalance;
        users[msg.sender][withdrawPoolId].amount = 0;
        if (userBalance > 0 ){
            token.transfer(msg.sender,userBalance);
        }
        if (feeBalance > 0){
            token.transfer(feeAddress,feeBalance);
        } 
    }

    function rewards(uint256 pid) public view returns (uint256 userReward){
        Pool memory pool = pools[pid];

        if (block.number <= pool.lastUpdateBlock){
            return 0;
        }

        uint256 endBlock = block.number;
        if (endBlock > pool.endBlock){
            endBlock = pool.endBlock;
        }

        uint256 blockDelta  = endBlock - pool.lastUpdateBlock;
        uint256 rewardShare = pool.rewardShare + blockDelta*pool.rewardPerBlock*(10**pool.depositTokenDecimal)/pool.depositAmount;
        
        User memory user = users[msg.sender][pid];
        userReward = user.amount*(endBlock-user.depositBlock)*rewardShare /(endBlock - pool.startBlock)/(10**pool.depositTokenDecimal);
    }

    function updateReward(uint256 pid) internal{
        Pool memory pool = pools[pid];

        if (block.number <= pool.lastUpdateBlock){
            return;
        }

        uint256 endBlock = block.number;
        if (endBlock > pool.endBlock){
            endBlock = pool.endBlock;
        }

        uint256 blockDelta  = endBlock - pool.lastUpdateBlock;
        pool.rewardShare += blockDelta*pool.rewardPerBlock*(10**pool.depositTokenDecimal)/pool.depositAmount;
        pool.lastUpdateBlock = endBlock;

        pools[pid] = pool;
    }

    function  withdrawAll(uint256 withdrawPoolId) external{
        Pool memory pool = pools[withdrawPoolId];
        require(block.number > pool.endBlock && pool.endBlock > 0,"pool not end yet");
        withdraw(poolId,false);
    }

    function emergencyWithdrawAll(uint256 withdrawPoolId) external{
        Pool memory pool = pools[withdrawPoolId];
        require(block.number > pool.startBlock && pool.startBlock > 0,"pool not start yet");
        withdraw(poolId,true);
    }

}