/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
     * by making the `nonReentrant` function external, and making it call a
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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract RETHSLPStaking is Ownable, ReentrancyGuard  {
    
    using SafeMath for uint256;
    IERC20 public sRETH=IERC20(0x66e7C1bDA2F82b2D3Aed82E2862F9CDeDFa1E9Df); //sRETH
    IERC20 public RETH=IERC20(0x75546ccb9d41FC5bCcE4ffd6Aec315487e43BaBf);
    IERC20 public RETH_LP=IERC20(0x26a7Ef71cE7A39786062a5C7956B0a26722E9A7A);
    bool public  PauseClaim = false;
    
    uint256 private constant ONE_MONTH_SEC = 2592000;
    Pool[] public pools; // Staking pools

    struct stakes{
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 months;
        bool collected;
        uint256 approxRETH;
        uint256 claimed;
    }
    
    event StakingUpdate(
        address wallet,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        bool collected,
        uint256 claimed,
        uint256 poolId
    );
    event APYSet(
        uint256[] APYs
    );

      struct Pool {
        uint256 tokensStaked; // Total tokens staked
        uint256 totalRewardsClaimed; // Last block number the user had their rewards calculated
        bool stakingPause;
      }
        

    mapping(uint256=> mapping(address=>stakes[])) public Stakes;
    mapping (uint256 => mapping(address=> uint256)) public userstakes;
    mapping (uint256=> mapping(uint256=>uint256) )public APY;
   
    event PoolCreated(uint256 poolId);
    event StakingPause(bool pause);
    event ClaimPause(bool status);


    constructor() {}


    function stake(uint256 amount, uint256 months, uint256 poolId) public nonReentrant {
        require(months == 1 || months == 3 || months == 6 || months == 12,"ENTER VALID MONTH");
        _stake(amount, months,  poolId);
    }
 

    function _stake(uint256 amount, uint256 months, uint256 poolId) private {
        RETH_LP.transferFrom(msg.sender, address(this), amount);
         Pool storage pool = pools[poolId];
         require(pool.stakingPause==false,"STAKING PAUSE");
        userstakes[poolId][msg.sender]++;
        pool.tokensStaked +=amount;
        uint256 duration = block.timestamp.add( months.mul(ONE_MONTH_SEC));   
        uint256 approxRETH = getApproxRETH().mul(amount);
        Stakes[poolId][msg.sender].push(stakes(msg.sender, amount, block.timestamp, duration, months, false,approxRETH, 0));
        emit StakingUpdate(msg.sender, amount, block.timestamp, duration, false, 0,poolId);
    }

    function unStake(uint256 stakeId,uint256 poolId ) public nonReentrant{
        require(Stakes[poolId][msg.sender][stakeId].collected == false ,"ALREADY WITHDRAWN");
        require(Stakes[poolId][msg.sender][stakeId].endTime < block.timestamp,"STAKING TIME NOT ENDED");
        require(PauseClaim==false, "Claim Pause");
        _unstake(stakeId,poolId);
    }

    function _unstake(uint256 stakeId,uint256 poolId) private {
        Pool storage pool = pools[poolId];
        Stakes[poolId][msg.sender][stakeId].collected = true;
        uint256 stakeamt = Stakes[poolId][msg.sender][stakeId].amount;
        uint256 gtreward = getTotalRewards(msg.sender, stakeId,poolId) > Stakes[poolId][msg.sender][stakeId].claimed ? 
                            getTotalRewards(msg.sender, stakeId,poolId) : Stakes[poolId][msg.sender][stakeId].claimed;
        uint256 rewards = gtreward.sub(Stakes[poolId][msg.sender][stakeId].claimed);
        Stakes[poolId][msg.sender][stakeId].claimed += rewards;
        pool.totalRewardsClaimed +=rewards;
        RETH_LP.transfer(msg.sender, stakeamt );
        sRETH.transfer(msg.sender, rewards );
        emit StakingUpdate(msg.sender, stakeamt, Stakes[poolId][msg.sender][stakeId].startTime, Stakes[poolId][msg.sender][stakeId].endTime, true, Stakes[poolId][msg.sender][stakeId].claimed,poolId);
    }

    function claimRewards(uint256 stakeId,uint256 poolId) public nonReentrant {
        require(PauseClaim==false, "Claim Pause");
        Pool storage pool = pools[poolId];
        require(Stakes[poolId][msg.sender][stakeId].claimed < getTotalRewards(msg.sender, stakeId,poolId), "All claimed");
        uint256 cuamt = getCurrentRewards(msg.sender, stakeId,poolId);
        require(getCurrentRewards(msg.sender, stakeId,poolId)>Stakes[poolId][msg.sender][stakeId].claimed, "Already claimed enough");
        uint256 clamt = cuamt.sub( Stakes[poolId][msg.sender][stakeId].claimed);
        Stakes[poolId][msg.sender][stakeId].claimed += clamt;
        pool.totalRewardsClaimed +=clamt;
        sRETH.transfer(msg.sender, clamt);
        emit StakingUpdate(msg.sender, Stakes[poolId][msg.sender][stakeId].amount, Stakes[poolId][msg.sender][stakeId].startTime, Stakes[poolId][msg.sender][stakeId].endTime, false, Stakes[poolId][msg.sender][stakeId].claimed,poolId);
    }

    function getStakes( address wallet,uint256 poolId) public view returns(stakes[] memory){
        uint256 itemCount = userstakes[poolId][wallet];
        uint256 currentIndex = 0;
        stakes[] memory items = new stakes[](itemCount);

        for (uint256 i = 0; i < userstakes[poolId][wallet]; i++) {
                stakes storage currentItem = Stakes[poolId][wallet][i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        return items;
    }

    function getTotalRewards(address wallet, uint256 stakeId,uint256 poolId) public view returns(uint256) {
        require(Stakes[poolId][wallet][stakeId].amount != 0);
        uint256 stakeamt = Stakes[poolId][wallet][stakeId].approxRETH;
        uint256 mos = Stakes[poolId][wallet][stakeId].months;
        uint256  rewards = (((stakeamt.mul(APY[poolId][mos])).mul(mos)).div(12)).div(100);
        return rewards;
    }

    function getCurrentRewards(address wallet, uint256 stakeId,uint256 poolId) public view returns(uint256) {
        require(Stakes[poolId][wallet][stakeId].amount != 0,"ZERO amount staked");
        uint256 stakeamt = Stakes[poolId][wallet][stakeId].approxRETH;
        uint256 mos = Stakes[poolId][wallet][stakeId].months;
        uint256 etime = Stakes[poolId][wallet][stakeId].endTime > block.timestamp ? block.timestamp : Stakes[poolId][wallet][stakeId].endTime;
        uint256 timec = etime.sub(Stakes[poolId][wallet][stakeId].startTime);
        uint256  rewards = (((stakeamt.mul(APY[poolId][mos])).mul(mos)).div(12)).div(100);
        uint256 crewards = (rewards.mul(timec)).div(mos.mul(ONE_MONTH_SEC));
        return crewards;
    }


    function getApproxRETH() public view returns(uint256) {
        uint256 lp_supply = RETH_LP.totalSupply();
        uint256 currentReth = RETH.balanceOf(address(RETH_LP));
        uint256 approxRETHPerLP = currentReth/lp_supply;
        return approxRETHPerLP;
    }

    function rewardsClaimed(uint256 poolId ) public view returns(uint256){
        Pool storage pool = pools[poolId];
        return pool.totalRewardsClaimed;
    }

    function setAPYs(uint256[] memory apys, uint256 poolId) external onlyOwner {
       require(apys.length == 4,"4 INDEXED ARRAY ALLOWED");
        APY[poolId][1] = apys[0];
        APY[poolId][3] = apys[1];
        APY[poolId][6] = apys[2];
        APY[poolId][12] = apys[3];
        emit APYSet(apys);
    }

    function withdrawToken(IERC20 _token) external nonReentrant onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

     
     function createPool() external onlyOwner {
        Pool memory pool;
        pool.totalRewardsClaimed =  0;
        pool.tokensStaked=0;
        pool.stakingPause=false;
        pools.push(pool);
        uint256 poolId = pools.length - 1;
        emit PoolCreated(poolId);
    }

    function pauseStaking (bool _pause, uint256 poolId) external onlyOwner {
         Pool storage pool = pools[poolId];
         pool.stakingPause = _pause;
         emit StakingPause(_pause);
    }

    function pauseClaim(bool status) public onlyOwner {
        PauseClaim = status;
        emit ClaimPause(status);
    }

}