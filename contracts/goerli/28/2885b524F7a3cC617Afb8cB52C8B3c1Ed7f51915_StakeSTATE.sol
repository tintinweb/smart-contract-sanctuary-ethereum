// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";

contract StateContext {
    bool public isStakeActive = true;
    bool public isUnStakeActive = true;

    bool public apyEnabled = true;
    bool public autoCompund = false;

    using TransferHelper for IERC20;

    IERC20 public token;
    address public rewardingWallet;

    uint256 public apyTier = 1618;

    struct User {
        uint256 stakedAmount;
        uint256 totalAmount;
        uint256 depositTime;
        uint256 lastClaimTime;
        uint256 reward;
        uint256 endtime;
    }

    mapping(address => User) public deposit;

    uint256 public totalStaked;

    event Stake(address indexed staker, uint256 _amount, uint256 _lockPeriod);
    event Unstake(address indexed unstaker, uint256 unstakeTime);
    event Emergencyunstake(address indexed unstaker, uint256 unstakeTime);
    event Withdraw(address indexed withdrawer);
    event WithdrawToken(address indexed withdrawer, uint256 amount);
    event Claim(address staker, uint256 reward);
}

contract StakeSTATE is StateContext, Ownable, ReentrancyGuard{

    using SafeMath for uint256;

    constructor(IERC20 _token, address wallet){
        token = _token;
        rewardingWallet = wallet;
    }

    receive() external payable{}
    
    /**
      * function to Enable or Disable the Reward
      */
    function flipApyEnabled() public onlyOwner {
        apyEnabled = !apyEnabled;
    }

    /**
      * function to set the apy. It takes one argument and it should be multiplied with 100.
      */
    function setApy(uint256 apy) public onlyOwner {
        apyTier = apy;
    }
    
    /**
      * function to set the rewarding Wallet. It takes one argument as address of wallet.
      */
    function setRewardingWallet(address wallet) public onlyOwner{
        rewardingWallet = wallet;
    }

    /**
      * function to change the state of staking. Enable or Disable staking.
      */
    function flipStakeState() public onlyOwner {
       isStakeActive = !isStakeActive;
    }

    /**
      * function to change the state of Unstaking. Enable or Disable Unstaking.
      */
    function flipUnStakeState() public onlyOwner {
       isUnStakeActive = !isUnStakeActive;
    }
    
    /**
      * function to set the Token Address. It takes one argument of token address.
      */
    function setTokenAddress(IERC20 _token) public onlyOwner {
       token = _token;
    }
    
    /**
      * Public function to stake the $STATE tokens. It takes one argument of amount as input.
      */
    function stake(uint256 _amount) public {
      require(token.balanceOf(_msgSender()) >= _amount, "You Do Not Have Sufficient Balance");
      require(token.allowance(_msgSender(), address(this)) >= _amount, "Tokens Not Approved");
      require(isStakeActive, "Staking Is Paused");

      _stakeTokens(_amount);
    }

    /**
      * Internal function to stake the $STATE tokens. It takes one argument of amount as input and called from public function.
      */
 
    function _stakeTokens(uint256 _amount) internal {        
      User storage wUser = deposit[_msgSender()];
      uint256 prevReward = checkReward(_msgSender());

      wUser.stakedAmount = wUser.stakedAmount.add(_amount);
      wUser.totalAmount = wUser.stakedAmount.add(_amount).add(prevReward);
      wUser.depositTime = block.timestamp;
      wUser.lastClaimTime = block.timestamp;
      wUser.reward = prevReward;

      TransferHelper.safeTransferFrom(address(token), _msgSender(), address(this), _amount);

      totalStaked +=_amount;
      
      emit Stake(_msgSender(), _amount, block.timestamp);
    }

    /**
      * Public function to unstake the tokens. It takes one argument as an input.
      */
    function UnstakeTokens(uint256 amount) public {
      require(isUnStakeActive, "Staking Is Paused");
      _unstakeTokens(_msgSender(), amount);
    }

    /**
      * Internal function to unstake the tokens. It takes one argument as an input and called from public function.
      */
    function _unstakeTokens(address _address, uint256 amount) internal {
      User memory wUser = deposit[_address];
      require(wUser.stakedAmount >= amount, "Stake First To Unstake Tokens");

      if(apyEnabled){
          _claim(_address);
      }
      token.transfer(_address, amount);

      totalStaked -= amount;

      wUser.stakedAmount = wUser.stakedAmount.sub(amount);
      wUser.totalAmount = wUser.totalAmount.sub(amount);
      wUser.depositTime = block.timestamp;
      wUser.lastClaimTime = block.timestamp;

      emit Unstake(_address, block.timestamp);
    }

    /**
      * Intenal function to claim the token reward. It takes one argument of staker wallet address.
      */
    function _claim(address _address) internal {
        User storage info = deposit[_address];
        
        uint256 claimcurrentReward = checkReward(_address);
        claimcurrentReward = claimcurrentReward.add(info.reward);

        if(claimcurrentReward <= pendingRewards()){
            TransferHelper.safeTransferFrom(address(token), rewardingWallet, _address, claimcurrentReward);
        } else{
            require(false, "Pending Rewards Not Allocated");
        }
        info.lastClaimTime = block.timestamp;
        info.reward = 0;
        emit Claim(_address , claimcurrentReward);
    }

    /**
      * Public function to claim the token reward.
      */
    function claim() public {
        User memory info = deposit[_msgSender()];
        require(info.stakedAmount > 0, "Not Staked");
        require(apyEnabled, "APY is not enabled");

        uint256 reward = checkReward(_msgSender());
        reward = reward.add(info.reward);
        require(reward > 0, "Current Reward Is 0");
          _claim(_msgSender());
    }

    /**
      * function to check the pending or approved rewarding amount of tokens.
      */
    function pendingRewards() public view returns (uint256){
        return token.allowance(rewardingWallet, address(this));
    }

    /**
      * To withdraw tokens stuck in the smart contract. Only owner of contract can call this method.
      */
    function withdrawAnyTokens(address _token, address recipient, uint256 amount) public onlyOwner{
        IERC20 anyToken = IERC20(_token);
        anyToken.transfer(recipient, amount);
        emit WithdrawToken(recipient, amount);
    }

    /**
      * To withdraw Eth stuck in the contract. Only owner of contract can call this method.
      */
    function withdrawFunds() public onlyOwner{
       payable(_msgSender()).transfer(address(this).balance);
       emit Withdraw(_msgSender());
    }

    /**
      * function to get the ETH Balance of contract
      */
    function contracEthBalance() public view returns (uint256){
      return address(this).balance;
    }

    /**
      * Public function to check the Reward of staker wallet. It takes one argument as input and returns the rewarding amoun.
      */
    function checkReward(address _address) public view returns (uint256){
      User memory cUser = deposit[_address];
      if(block.timestamp + 1 days > cUser.lastClaimTime){
        uint256 stakedtime = (block.timestamp).sub(cUser.lastClaimTime);
        stakedtime = stakedtime / 1 days;

        uint256 reward = apyTier.mul(stakedtime).mul(cUser.stakedAmount).div(10000).div(365);
        return reward;
      }
      else{

        return 0;

        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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