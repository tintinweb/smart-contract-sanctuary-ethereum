/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
 * @title TokenStaking
 */
contract TokenStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 constant DEMOMINATOR = 100;
    struct stakingMeta {
        uint256 yield;
        uint256 depositAmount;
        uint256 totalReward;
        uint256 startDepositedAt;
        uint256 yieldUpdatedAt;
    }
    IERC20 public stakingToken;
    address public treasuryAddress;
    address public depositAddress;
    address public admin_address;
    uint256 public depositPeriod;
    uint256 public totalDepositCap;
    uint256 public initialYield; // Initial value, do not update
    uint256 public totalDeposited;
    mapping (address => stakingMeta) public stakingMetaList;
    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event FinalWithdraw(address indexed account, uint256 amount);
    event UpdateYield(uint256 newYield, uint256 numberOfAccountsUpdated);
    modifier onlyAdmin() {
        require(msg.sender == admin_address, "TokenStaking: The caller is another account");
        _;
    }
    constructor(
        address _treasuryAddress,
        address _tokenAddress,
        address _adminAddress,
        uint256 _depositPeriod,
        uint256 _yield,
        uint256 _totalDepositCap
    ) {
        treasuryAddress = _treasuryAddress;
        depositAddress = address(this);
        admin_address = _adminAddress;
        stakingToken = IERC20(_tokenAddress);
        depositPeriod = _depositPeriod;
        initialYield = _yield;
        totalDepositCap = _totalDepositCap;
    }
    /**
     * @notice Staking is possible only once per account
     * @param amount Amount to stake
     */
    function deposit(uint256 amount) external nonReentrant {
        require(stakingMetaList[msg.sender].depositAmount == 0, "TokenStaking: deposit: This is a staked account.");
        require(amount > 0, "TokenStaking: deposit: Invalid amount.");
        require(totalDepositCap > (totalDeposited + amount), "TokenStaking: deposit: The staking amount is invalid.");
        totalDeposited = totalDeposited.add(amount);
        stakingMetaList[msg.sender] = stakingMeta(
            initialYield,
            amount,
            amount,
            block.timestamp,
            block.timestamp
        );
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }
    /**
     * @notice Return staking information
     * @return Staking information
     */
    function getStakingInfo() external view returns(stakingMeta memory) {
        return stakingMetaList[msg.sender];
    }
    /**
     * @notice It can update the interest rate only once
     */
    function updateYield(uint256 newYield, address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            require(stakingMetaList[account].yieldUpdatedAt == 0, "TokenStaking: updateYield: An updated account exists.");
        }
        // 金利の更新タイミングで、前の金利によって積み立てられた受け取り総額を計算して、総受け取り額（金利更新前時点）に加算し、金利更新時刻をセットする。
        uint256 yieldUpdatedAt = block.timestamp;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            stakingMetaList[account] = stakingMeta(
                newYield,
                stakingMetaList[account].depositAmount,
                stakingMetaList[account].totalReward,
                stakingMetaList[account].startDepositedAt,
                yieldUpdatedAt
            );
        }
        emit UpdateYield(newYield, accounts.length);
    }
    /**
     * 
     */
    function getTotalReward() external view returns(uint256) {
        // require(msg.sender != address(0));
        uint256 currentTime = block.timestamp;
        uint256 yieldUpdatedAt = stakingMetaList[msg.sender].yieldUpdatedAt;
        uint256 pendingReward = 0;
        if (yieldUpdatedAt == 0) {
            // 金利の更新がない
            // リワード総額 (初期金利)
            uint256 fullRewards = stakingMetaList[msg.sender].depositAmount.mul(initialYield).div(DEMOMINATOR);
            // ステーキング日時の進捗 (金利更新前)
            uint256 percentageUntilEndOfStaking = _getPercentageUntilEndOfStaking(stakingMetaList[msg.sender].startDepositedAt, currentTime);
            // 受け取れる金利
            pendingReward = fullRewards.mul(percentageUntilEndOfStaking).div(DEMOMINATOR);
        // } else {
            // 金利の更新がある
            // リワード総額 (金利変更前)
            // uint256 fullRewards = stakingMetaList[msg.sender].depositAmount.mul(initialYield).div(DEMOMINATOR);
            // ステーキング日時の進捗 (金利更新前)
            // uint256 percentageUntilEndOfStaking = _getPercentageUntilEndOfStaking(stakingMetaList[msg.sender].startDepositedAt, yieldUpdatedAt);
            // 受け取れる金利
            // pendingReward = fullRewards.mul(percentageUntilEndOfStaking).div(DEMOMINATOR);
            // リワード総額 (金利変更後)
            // uint256 fullRewardsForUpdatedYield = stakingMetaList[msg.sender].depositAmount.mul(stakingMetaList[msg.sender].yield).div(DEMOMINATOR);
            // ステーキング日時の進捗 (金利更新後)
            // uint256 percentageUntilEndOfStakingForUpdatedYield = _getPercentageUntilEndOfStaking(yieldUpdatedAt, currentTime);
            // 受け取れる金利
            // pendingReward = pendingReward.add(fullRewardsForUpdatedYield.mul(percentageUntilEndOfStakingForUpdatedYield).div(DEMOMINATOR));
        }
        return pendingReward;
    }
    /**
     * 
     */
    function withdraw() external nonReentrant {
        uint256 withdrawAmount = stakingMetaList[msg.sender].depositAmount.add(stakingMetaList[msg.sender].totalReward);
        stakingToken.transfer(msg.sender, withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAmount);
        stakingMetaList[msg.sender].depositAmount = 0;
        stakingMetaList[msg.sender].totalReward = 0;
    }
    /**
     * @notice Withdraw all the deposited amount to treasuryAddress
     */
    function finalWithdraw() external onlyAdmin {
        uint256 withdrawAmount = stakingToken.balanceOf(depositAddress);
        stakingToken.transfer(treasuryAddress, withdrawAmount);
        emit FinalWithdraw(msg.sender, withdrawAmount);
    }
    /**
     * @notice Get Full Rewards
     * @param _depositAmount Amount deposited
     * @param _yield the yield to use in the calculation
     */
    function _getFullRewards(uint256 _depositAmount, uint256 _yield) internal pure returns(uint256) {
        return _depositAmount.mul(_yield).div(DEMOMINATOR);
    }
    /**
     * @notice Get percentage until end of staking
     * @param _startDepositedAt Start Deposit time (unitxtime)
     * @param _currentTime Current time (unitxtime)
     */
    function _getPercentageUntilEndOfStaking(uint256 _startDepositedAt, uint256 _currentTime) internal view returns(uint256) {
        uint256 diffTime = _currentTime.sub(_startDepositedAt);
        uint256 percUntilEndOfStaking = diffTime.mul(depositPeriod).div(DEMOMINATOR);
        if (percUntilEndOfStaking < DEMOMINATOR) {
            return percUntilEndOfStaking;
        }
        return DEMOMINATOR;
    }
}