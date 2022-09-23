/**
 *Submitted for verification at Etherscan.io on 2022-09-23
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
}contract SMAuth {

        address public auth;
        bool internal locked;
        
        modifier onlyAuth {
        require(isAuthorized(msg.sender));
        _;
    }

    modifier nonReentrancy() {
        require(!locked, "No reentrancy allowed");

        locked = true;
        _;
        locked = false;
    }
    function setAuth(address src1) public onlyAuth {
        auth = src1;
    }

    function isAuthorized(address src) internal view returns (bool) {
        if(src == auth){
            return true;
        } else return false;
    }
 }
contract RETHStaking is SMAuth, ReentrancyGuard  {
    
    using SafeMath for uint256;
    IERC20 public rewardToken;
    IERC20 public depositToken;
    address public RETH_LP=0x26a7Ef71cE7A39786062a5C7956B0a26722E9A7A;
    uint256 internal totalRewardsClaimed;
    
    uint256 private constant ONE_MONTH_SEC = 2592000;

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
        uint256 claimed
    );
    event APYSet(
        uint256[] APYs
    );
    mapping(address=>stakes[]) public Stakes;
    mapping(address=> uint256) public userstakes;
    mapping(uint256=>uint256) public APY;

    constructor(IERC20 _rewardtoken,IERC20 _depositToken) {
        auth = msg.sender;
        rewardToken = _rewardtoken;
        depositToken=_depositToken;
    }

    function stake(uint256 amount, uint256 months) public nonReentrant {
        require(months == 1 || months == 3 || months == 6 || months == 12,"ENTER VALID MONTH");
        _stake(amount, months);
    }
 

    function _stake(uint256 amount, uint256 months) private {
        depositToken.transferFrom(msg.sender, address(this), amount);
        userstakes[msg.sender]++;
        uint256 duration = block.timestamp.add( months.mul(30 days));   
        uint256 approxRETH = getApproxRETH().mul(amount);
        Stakes[msg.sender].push(stakes(msg.sender, amount, block.timestamp, duration, months, false,approxRETH, 0));
        emit StakingUpdate(msg.sender, amount, block.timestamp, duration, false, 0);
    }

    function unStake(uint256 stakeId) public nonReentrant{
        require(Stakes[msg.sender][stakeId].collected == false ,"ALREADY WITHDRAWN");
        require(Stakes[msg.sender][stakeId].endTime < block.timestamp,"STAKING TIME NOT ENDED");
        _unstake(stakeId);
    }

    function _unstake(uint256 stakeId) private {
        Stakes[msg.sender][stakeId].collected = true;
        uint256 stakeamt = Stakes[msg.sender][stakeId].amount;
        uint256 gtreward = getTotalRewards(msg.sender, stakeId) > Stakes[msg.sender][stakeId].claimed ? 
                            getTotalRewards(msg.sender, stakeId) : Stakes[msg.sender][stakeId].claimed;
        uint256 rewards = gtreward.sub(Stakes[msg.sender][stakeId].claimed);
        Stakes[msg.sender][stakeId].claimed += rewards;
        totalRewardsClaimed = totalRewardsClaimed.add (rewards);
        depositToken.transfer(msg.sender, stakeamt );
        rewardToken.transfer(msg.sender, rewards );

        emit StakingUpdate(msg.sender, stakeamt, Stakes[msg.sender][stakeId].startTime, Stakes[msg.sender][stakeId].endTime, true, getTotalRewards(msg.sender, stakeId));
    }

    function claimRewards(uint256 stakeId) public nonReentrant {
        require(Stakes[msg.sender][stakeId].claimed != getTotalRewards(msg.sender, stakeId));
        uint256 cuamt = getCurrentRewards(msg.sender, stakeId);
        require(getCurrentRewards(msg.sender, stakeId)>Stakes[msg.sender][stakeId].claimed, "Already claimed enough");
        uint256 clamt = cuamt.sub( Stakes[msg.sender][stakeId].claimed);
        Stakes[msg.sender][stakeId].claimed += clamt;
        totalRewardsClaimed = totalRewardsClaimed .add(clamt);
        rewardToken.transfer(msg.sender, clamt);
        emit StakingUpdate(msg.sender, Stakes[msg.sender][stakeId].amount, Stakes[msg.sender][stakeId].startTime, Stakes[msg.sender][stakeId].endTime, true, Stakes[msg.sender][stakeId].claimed);
    }

    function getStakes( address wallet) public view returns(stakes[] memory){
        uint256 itemCount = userstakes[wallet];
        uint256 currentIndex = 0;
        stakes[] memory items = new stakes[](itemCount);

        for (uint256 i = 0; i < userstakes[wallet]; i++) {
                stakes storage currentItem = Stakes[wallet][i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        return items;
    }

    function getTotalRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        require(Stakes[wallet][stakeId].amount != 0);
        uint256 stakeamt = Stakes[wallet][stakeId].approxRETH;
        uint256 mos = Stakes[wallet][stakeId].months;
        uint256  rewards = (((stakeamt.mul(APY[mos])).mul(mos)).div(12)).div(100);
        return rewards;
    }

     function getCurrentRewards(address wallet, uint256 stakeId) public view returns(uint256) {
        require(Stakes[wallet][stakeId].amount != 0,"ZERO amount staked");
        uint256 stakeamt = Stakes[wallet][stakeId].approxRETH;
        uint256 mos = Stakes[wallet][stakeId].months;
        uint256 etime = Stakes[wallet][stakeId].endTime > block.timestamp ? block.timestamp : Stakes[wallet][stakeId].startTime;
        uint256 timec = etime.sub(Stakes[wallet][stakeId].startTime);
        uint256  rewards = (((stakeamt.mul(APY[mos])).mul(mos)).div(12)).div(100);
        uint256 crewards = (rewards.mul(timec)).div(mos.mul(ONE_MONTH_SEC));
        return crewards;
    }


    function getApproxRETH() internal view returns(uint256) {
        uint256 lp_supply = IERC20(RETH_LP).totalSupply();
        uint256 currentReth = IERC20(rewardToken).balanceOf(RETH_LP);
        uint256 approxRETHPerLP = currentReth/lp_supply;
        return approxRETHPerLP;
    }



     function rewardsClaimed() public view returns(uint256){
       return(totalRewardsClaimed);
    }

    function setAPYs(uint256[] memory apys) external onlyAuth {
       require(apys.length == 4,"4 INDEXED ARRAY ALLOWED");
        APY[1] = apys[0];
        APY[3] = apys[1];
        APY[6] = apys[2];
        APY[12] = apys[3];
        emit APYSet(apys);
    }



    function withdrawToken(IERC20 _token) external nonReentrant onlyAuth{
        _token.transfer(auth, _token.balanceOf(address(this)));
    }

}