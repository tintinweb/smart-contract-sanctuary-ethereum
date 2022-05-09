/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.13;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDaocontrol`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyDaocontrol() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyDaocontrol` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyDaocontrol {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyDaocontrol {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
contract AccelVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    IERC20 public accelToken;
    IERC20 public tokenOutput;

    struct TokenInputInfo {
        address addr;
        uint256 rateInput;
        uint256 rateOutput;
    }

    mapping (uint256 => TokenInputInfo) public tokenInput;

    uint256 SEED_CLIFF = 30 days;
    
    uint256 Vest_Backdate;

    uint256 SEED_RELEASE_EACH_MONTH = 833; // 8.33%
    
    struct UserInfo {
        uint256 vestBalance;
        uint256 totalClaimed;
        uint256 start;
        uint256 end;
        uint256 claimedCheckPoint;

        // To calculate Reward
        uint256 rewardTokenDebt;
        uint256 rewardEthDebt;
        
        uint256 amount;
        uint256 depositTime;
        uint256 pendingEthReward;

    }

    mapping (address => bool) public isBlacklistWallet;

    mapping(address => UserInfo) public userInfo;
    
    uint256 public totalTokenForSwapping;
    uint256 public totalTokenForSeed;
    uint256 public totalTokenForPublic;

    uint256 public soldAmountSeed        = 0;
    uint256 public soldAmountPublic      = 0;
    uint256 public soldTotal             = 0;

    uint256 public TYPE_SEED = 1;
    uint256 public TYPE_PUBLIC = 2;

    uint256 public MONTH = 30 days;

    uint256 public totalStakedAmount;

    bool public swapEnabled;

    address public DAOcontrol;

    event Deposit(address indexed user, uint256 amount);
    
    constructor(address _DAOcontrol, address _addressAccel) {
        DAOcontrol = _DAOcontrol;
        accelToken = IERC20(_addressAccel);
    }    
    
    function startSwap(address outputToken) public onlyDaocontrol{
        require(swapEnabled == false, "Swap already started");
        tokenOutput = IERC20(outputToken);
        swapEnabled = true;
    }

    function stopSwap() public onlyDaocontrol {
        swapEnabled = false;
    }

    function addInputTokenForSwap(uint256 _id, address _inputToken, uint256 _inputRate, uint256 _outputRate)public onlyDaocontrol{
        require(_id < 3);
        tokenInput[_id].addr = _inputToken;
        tokenInput[_id].rateInput = _inputRate;
        tokenInput[_id].rateOutput = _outputRate;
    }

    receive() external payable {
        addEthForReward();
    }

    function setBlacklistWallet(address account, bool blacklisted) external onlyDaocontrol {
        isBlacklistWallet[account] = blacklisted;
    }

    function addOutputTokenForSwap(uint256 amount) public{    
        tokenOutput.transferFrom(msg.sender, address(this), amount);
        totalTokenForSwapping = totalTokenForSwapping.add(amount);
    }

    function ownerWithdrawToken(address tokenAddress, uint256 amount) public onlyDaocontrol{    
        if(tokenAddress == address(tokenOutput)){
            require(amount < totalTokenForSwapping.sub(soldTotal), "You're trying withdraw an amount that exceed availabe balance");
            totalTokenForSwapping = totalTokenForSwapping.sub(amount);
        }
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function getClaimableInVesting(address account) public view returns (uint256){
        UserInfo memory vestPlan = userInfo[account];

        //Already withdraw all
        if(vestPlan.totalClaimed >= vestPlan.vestBalance){
            return 0;
        }

        //No infor
        if(vestPlan.start == 0 || vestPlan.end == 0 || vestPlan.vestBalance == 0){
            return 0;
        }
        
        uint256 currentTime = block.timestamp;
        if(currentTime >= vestPlan.end){
            return vestPlan.vestBalance.sub(vestPlan.totalClaimed);
        }else if(currentTime < vestPlan.start + SEED_CLIFF){
            return 0;
        }else {
            uint256 currentCheckPoint = 1 + (currentTime - vestPlan.start - SEED_CLIFF) / MONTH;
            if(currentCheckPoint > vestPlan.claimedCheckPoint){
                uint256 claimable =  ((currentCheckPoint - vestPlan.claimedCheckPoint) * SEED_RELEASE_EACH_MONTH * vestPlan.vestBalance) / 10000;
                return claimable;
            }else
                return 0;
        }
    }

    function balanceRemainingInVesting(address account) public view returns(uint256){
        UserInfo memory vestPlan = userInfo[account];
        return vestPlan.vestBalance -  vestPlan.totalClaimed;
    }

    function withDrawFromVesting() public {
        UserInfo storage vestPlan = userInfo[msg.sender];

        uint256 claimableAmount = getClaimableInVesting(msg.sender);
        require(claimableAmount > 0, "There isn't token in vesting that's claimable at the moment");

        uint256 currentTime = block.timestamp;
        if(currentTime > vestPlan.end){
            currentTime = vestPlan.end;
        }
        
        vestPlan.claimedCheckPoint = 1 + (currentTime - vestPlan.start - SEED_CLIFF) / MONTH;
        vestPlan.totalClaimed = vestPlan.totalClaimed.add(claimableAmount);

        tokenOutput.transfer(msg.sender, claimableAmount);
    }

    function Mergerdeposit (uint256 inputTokenId, uint256 inputAmount, uint256 buyType) public payable {
        require(inputTokenId < 3, "Invalid input token ID");
        require(isBlacklistWallet[msg.sender] == false, "You're in blacklist");
        require(swapEnabled, "Swap is not available");

        IERC20 inputToken = IERC20(tokenInput[inputTokenId].addr);

        uint256 numOutputToken = inputAmount.mul(tokenInput[inputTokenId].rateOutput).mul(10**tokenOutput.decimals()).div(tokenInput[inputTokenId].rateInput);
        if(buyType == TYPE_SEED)
            numOutputToken = numOutputToken.mul(3);
     
        require(numOutputToken < totalTokenForSwapping.sub(soldTotal), "Exceed avaialble token");

        inputToken.transferFrom(msg.sender, address(this), inputAmount.mul(10**inputToken.decimals()));
        soldTotal = soldTotal.add(numOutputToken);
        addingVestToken(msg.sender, numOutputToken, buyType);

    }

    function addingVestToken(address account, uint256 amount, uint256 vType) private {
        if(vType == TYPE_SEED){
            UserInfo storage vestPlan = userInfo[account];
            soldAmountSeed = soldAmountSeed.add(amount);
            vestPlan.vestBalance = vestPlan.vestBalance.add(amount);
            vestPlan.start = vestPlan.start == 0 ? block.timestamp : vestPlan.start;
            vestPlan.end = vestPlan.end == 0 ? block.timestamp + SEED_CLIFF + (10000 / SEED_RELEASE_EACH_MONTH) * MONTH : vestPlan.end;
        }else{
            soldAmountPublic = soldAmountPublic.add(amount);
            tokenOutput.transfer(account, amount);
            return;
        }
    }
    
    //Vest_Backdate is days before the current day. Only applicable for new additions to the contract.
    function AddVest(address account, uint256 amount, uint256 _Vest_Backdate) external onlyDaocontrol {
            UserInfo storage vestPlan = userInfo[account];
            soldAmountSeed = soldAmountSeed.add(amount);
            vestPlan.vestBalance = vestPlan.vestBalance.add(amount);
            Vest_Backdate = _Vest_Backdate * 1 days;
            vestPlan.start = vestPlan.start == 0 ? block.timestamp - Vest_Backdate: vestPlan.start;
            vestPlan.end = vestPlan.end == 0 ? block.timestamp + (10000 / SEED_RELEASE_EACH_MONTH) * MONTH : vestPlan.end;
            tokenOutput.transferFrom(msg.sender, address(this), amount);
            totalTokenForSwapping = totalTokenForSwapping.add(amount);
        }

    function RemoveVest(address account, uint256 amount) external onlyDaocontrol{
            UserInfo storage vestPlan = userInfo[account];
            soldAmountSeed = soldAmountSeed.sub(amount);
            vestPlan.vestBalance = vestPlan.vestBalance.sub(amount);
            IERC20(tokenOutput).transfer(msg.sender, amount);
            totalTokenForSwapping = totalTokenForSwapping.sub(amount);
        }

    /*REWARD FOR VESTING*/
    address public rewardToken;
    uint256 public amountTokenForReward;
    uint256 public amountEthForReward;

    uint256 public totalRewardEthDistributed;
    uint256 public totalRewardTokenDistributed;

    uint256 public rewardTokenPerSecond;
    uint256 public rewardEthPerSecond;

    // Accrued token per share
    uint256 public accTokenPerShare;    
    // Accrued EHT per share
    uint256 public accEthPerShare;
    // The block number of the last pool update
    uint256 public lastRewardTime;
    // The precision factor
    uint256 public PRECISION_FACTOR = 10**12;

    bool public enableRewardSystem;


    
    function startRewardSystem(address _rewardToken) public onlyDaocontrol{
        enableRewardSystem = true;
        rewardToken = _rewardToken;
        rewardTokenPerSecond = 0.05 ether;   // 0.65 token/block
        rewardEthPerSecond = 0.000004 ether; // 10 eth/month
        
        lastRewardTime = block.timestamp;
    }

    function setNewRewardToken(address _rewardToken)public onlyDaocontrol{
        rewardToken = _rewardToken;
    }

    function setRewardTokenPerSecond(uint256 _rewardTokenPerSecond) public onlyDaocontrol{
        rewardTokenPerSecond = _rewardTokenPerSecond;
    }

    function setRewardEthPerSecond(uint256 _rewardEthPerSecond) public onlyDaocontrol{
        rewardEthPerSecond = _rewardEthPerSecond;
    }

    function addTokenForReward(uint256 amount) public {
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        amountTokenForReward = amountTokenForReward.add(amount);
    }

    function addEthForReward() payable public {
        amountEthForReward = amountEthForReward.add(msg.value);
    }

    function updateEthForReward() public {
        amountEthForReward = address(this).balance;
    }
     
    /*
     * Harvest reward
     */
    function harvest() public {
     _updateVestingPool();
        UserInfo storage user = userInfo[msg.sender];

        if (user.vestBalance > 0) {
            uint256 pendingToken = user.vestBalance.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardTokenDebt);
            uint256 pendingEth = user.vestBalance.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt);
            if (pendingToken > 0) {
                IERC20(rewardToken).transfer( address(msg.sender), pendingToken);
            }
            if (pendingEth > 0) {
                payable(msg.sender).transfer(pendingEth);
            }
        }
        user.rewardTokenDebt = user.vestBalance.mul(accTokenPerShare).div(PRECISION_FACTOR);
        user.rewardEthDebt = user.vestBalance.mul(accEthPerShare).div(PRECISION_FACTOR);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */

    function pendingReward(address _user) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 pendingToken;
        uint256 pendingEth;
        
        if(enableRewardSystem == false){
            return (0, 0);
        }

        if (block.timestamp > lastRewardTime && soldAmountSeed != 0) {
            uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp);

            uint256 tokenReward = multiplier.mul(rewardTokenPerSecond);
            if(tokenReward > amountTokenForReward){
                tokenReward = amountTokenForReward;
            }
            uint256 adjustedTokenPerShare = accTokenPerShare.add(tokenReward.mul(PRECISION_FACTOR).div(soldAmountSeed));

            uint256 ethReward = multiplier.mul(rewardEthPerSecond);
            if(ethReward > amountEthForReward){
                ethReward = amountEthForReward;
            }
            uint256 adjustedEthPerShare = accEthPerShare.add(ethReward.mul(PRECISION_FACTOR).div(soldAmountSeed + totalStakedAmount));

            pendingToken =  user.vestBalance.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardTokenDebt);
            pendingEth =  user.vestBalance.mul(adjustedEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt);
        } else {
            pendingToken = user.vestBalance.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardTokenDebt);
            pendingEth = user.vestBalance.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt);
        }

        return (pendingToken, pendingEth);
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updateVestingPool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (enableRewardSystem == false || soldAmountSeed == 0) {
            lastRewardTime = block.timestamp;
            return;
        }  
        _updatepool;

    }

    function _updatepool() internal {

    uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp);

    uint256 tokenReward = multiplier.mul(rewardTokenPerSecond);
        
        if(tokenReward > amountTokenForReward){
            tokenReward = amountTokenForReward;
        }
        accTokenPerShare = accTokenPerShare.add(tokenReward.mul(PRECISION_FACTOR).div(soldAmountSeed));
        amountTokenForReward = amountTokenForReward.sub(tokenReward);
        totalRewardTokenDistributed = totalRewardTokenDistributed.add(tokenReward);
    
    uint256 ethReward = multiplier.mul(rewardEthPerSecond);

        if(ethReward > amountEthForReward){
            ethReward = amountEthForReward;
        }
        accEthPerShare = accEthPerShare.add(ethReward.mul(PRECISION_FACTOR).div(soldAmountSeed + totalStakedAmount));
        amountEthForReward = amountEthForReward.sub(ethReward);
        totalRewardEthDistributed = totalRewardEthDistributed.add(ethReward);

        lastRewardTime = block.timestamp;
    }

    function _updateStakingPool() internal {
        
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalStakedAmount == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        _updatepool;
    }
    
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "Can't deposit zero amount");

        _updateStakingPool();

        if (user.amount > 0) {
            user.pendingEthReward = user.pendingEthReward.add(user.amount.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt));
        }

        user.depositTime = user.depositTime > 0 ? user.depositTime : block.timestamp;

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            accelToken.transferFrom(address(msg.sender), address(this), _amount);
        }

        totalStakedAmount = totalStakedAmount.add(_amount);
        user.rewardEthDebt = user.amount.mul(accEthPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
            return _to.sub(_from);
    }

    function updatedaocontrol (address _daocontrol) onlyDaocontrol external {
       DAOcontrol = _daocontrol;
    }

    function emergencyWithdraw () onlyDaocontrol external {
        payable(msg.sender).transfer(address(this).balance);
    }

}