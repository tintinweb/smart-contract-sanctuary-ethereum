// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract staking is Ownable {
    using SafeMath for uint256;

    address public treasury;

    uint256 constant private divider=10000;

    uint256 public depoiteTax=0;

    uint256 public withdrawTax=0;

    uint256 public rewardPercentage=150;

    uint256 public totalInvestedToken;

    uint256 public totalWithdrawToken;

    IERC20 public token;
    struct depoite{
        uint256 amount;
        uint256 DepositTime;
        uint256 checkPointToken;
    }

    struct user {
        depoite[] Deposits;
        uint256 totalRewardWithdrawToken;
        uint256 checkToken;
        uint256 withdrawCheckToken;
    }

    mapping (address=>user) public investor;

	event NewDeposit(address indexed user, uint256 amount);
    event compoundRewards (address indexed user, uint256 amount);
	event withdrawal(address indexed user, uint256 amount);
	event RewardWithdraw(address indexed user,uint256 amount);
    event SetTax(uint256 DepositTax,uint256 withdrawTax);
    event SetRewardPercentage(uint256 rewardPercentage);
    constructor() Ownable(0x0c2f01db0e79a1D40B5a478A33a1B31A450C8F95){
        treasury=0x0c2f01db0e79a1D40B5a478A33a1B31A450C8F95;
        token=  IERC20(0x29cD78954c023cd9BffC435a816E568eDaf732aF);
    }
    
   
    function setWallet( address _treasury) public  onlyOwner{
        require(_treasury!=address(0),"Error: Can not set treasury wallet to zero address ");
        treasury=_treasury;
    }

    function setTax(uint256 _depoiteTax,uint256 _withdrawTax) public  onlyOwner{
        require(_depoiteTax<=2000,"Deposit Tax Must be less than 20%");
        require(_withdrawTax<=2000,"Withdraw Tax  Must be less than 20%");
        depoiteTax=_depoiteTax;
        withdrawTax=_withdrawTax;
        emit SetTax(_depoiteTax,_withdrawTax);
    }

    function setRewardPercentage(uint256 _rewardPercentage) public  onlyOwner{
        require(_rewardPercentage>=100,"Reward Percentage Must be less than 1%");
        require(_rewardPercentage<=2000,"Reward Percentage Must be less than 20%");
        rewardPercentage=_rewardPercentage; 
        emit SetRewardPercentage(_rewardPercentage);       
    }

    function invest(uint256 amount) public payable {
        user storage users =investor[msg.sender];
        
        require(amount<=token.allowance(msg.sender, address(this)),"Insufficient Allowence to the contract");
        uint256 tax=amount.mul(depoiteTax).div(divider);
        
        token.transferFrom(msg.sender, treasury, tax);
        token.transferFrom(msg.sender, address(this), amount.sub(tax));
        users.Deposits.push(depoite(amount.sub(tax), block.timestamp,block.timestamp));
        totalInvestedToken=totalInvestedToken.add(amount.sub(tax));
        users.checkToken=block.timestamp;
        emit NewDeposit(msg.sender, amount);
    }
    
    function compound() public payable {
        user storage users =investor[msg.sender];
        
            (uint256 amount)=calclulateReward(msg.sender);
           
            require(amount>0,"compound  Amount very low");
            users.Deposits.push(depoite(amount, block.timestamp,block.timestamp));
            totalInvestedToken=totalInvestedToken.add(amount);
            emit compoundRewards (msg.sender, amount);
                for(uint256 i=0;i<investor[msg.sender].Deposits.length;i++){
                investor[msg.sender].Deposits[i].checkPointToken=block.timestamp;
        }
            users.withdrawCheckToken=block.timestamp;
             users.checkToken=block.timestamp;
        
        
    }
   
    function withdrawTokens()public {
        uint256 totalDeposit=getUserTotalDepositToken(msg.sender);
        require(totalDeposit>0,"No Deposit Found");
        require(totalDeposit<=getContractTokenBalacne(),"Not Enough Token for withdrwal from contract please try after some time");
        uint256 tax=totalDeposit.mul(withdrawTax).div(divider);
        token.transfer(treasury, tax);
        token.transfer(msg.sender, totalDeposit.sub(tax));
        investor[msg.sender].checkToken=block.timestamp;
        investor[msg.sender].withdrawCheckToken=block.timestamp;
        
        emit withdrawal(msg.sender, totalDeposit);
    }
    
    function withdrawRewardToken()public {
        (uint256 totalRewards)=calclulateReward(msg.sender);
        require(totalRewards>0,"No Rewards Found");
        require(totalRewards<=getContractTokenBalacne(),"Not Enough Token for withdrwal from contract please try after some time");
        uint256 taxR=totalRewards.mul(withdrawTax).div(divider);
        token.transfer(msg.sender, totalRewards.sub(taxR));

        for(uint256 i=0;i<investor[msg.sender].Deposits.length;i++){
            investor[msg.sender].Deposits[i].checkPointToken=block.timestamp; 
        }
        investor[msg.sender].totalRewardWithdrawToken+=totalRewards;
        investor[msg.sender].checkToken=block.timestamp;
        totalWithdrawToken+=totalRewards;
        emit RewardWithdraw(msg.sender, totalRewards);
    }
    
    function calclulateReward(address _user) public view returns(uint256){
        uint256 totalRewardToken;
        user storage users=investor[_user];
        for(uint256 i=0;i<users.Deposits.length;i++){
            uint256 DepositAmount=users.Deposits[i].amount;
            uint256 time = block.timestamp.sub(users.Deposits[i].checkPointToken);
            totalRewardToken += DepositAmount.mul(rewardPercentage).div(divider).mul(time).div(1 days);            
        }
        return(totalRewardToken);
    }

    function getUserTotalDepositToken(address _user) public view returns(uint256 _totalInvestment){
        for(uint256 i=0;i<investor[_user].Deposits.length;i++){
             _totalInvestment=_totalInvestment.add(investor[_user].Deposits[i].amount);
        }
    }
    
    function getUserTotalRewardWithdrawToken(address _user) public view returns(uint256 _totalWithdraw){
        _totalWithdraw=investor[_user].totalRewardWithdrawToken;
    }
    

    function getContractTokenBalacne() public view returns(uint256 totalToken){
        totalToken=token.balanceOf(address(this));
    }

    function getContractBNBBalacne() public view returns(uint256 totalBNB){
        totalBNB=address(this).balance;
    }
    
    function withdrawalBNB() public payable onlyOwner{
        payable(owner()).transfer(getContractBNBBalacne());
    }
    function getUserDepositHistoryToken( address _user) public view  returns(uint256[] memory,uint256[] memory){
        uint256[] memory amount = new uint256[](investor[_user].Deposits.length);
        uint256[] memory time = new uint256[](investor[_user].Deposits.length);
        for(uint256 i=0;i<investor[_user].Deposits.length;i++){
                amount[i]=investor[_user].Deposits[i].amount;
                time[i]=investor[_user].Deposits[i].DepositTime;
        }
        return(amount,time);
    }
    receive() external payable {
      
    }
     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Context.sol";
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
    constructor(address newOwner) {
        _transferOwnership(newOwner);
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
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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