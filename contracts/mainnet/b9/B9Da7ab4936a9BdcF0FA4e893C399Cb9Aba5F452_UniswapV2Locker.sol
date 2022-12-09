/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: UNLICENSED
// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/Context.sol


// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/Ownable.sol


// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/TransferHelper.sol

pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}


// File contracts/ReentrancyGuard.sol


// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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


// File contracts/SafeMath.sol


// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

pragma solidity >=0.6.0 <0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/interfaces/IERC20u.sol

interface IERC20u {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);
    function decimals() external view returns (uint);
    function snapshot() external returns(uint256);
    function unpause() external;
    function pause() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function unpauseExceptSelling() external;
    function setPoolAddress(address pool) external;
    function isPaused() external view returns(bool);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
}


// File contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File contracts/UniswapV2Locker.sol


// This contract locks uniswap v2 liquidity tokens pairs with a betting parameter. the wining side will be able to claim the losing side liquidity tokens

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;






interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

contract UniswapV2Locker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  IUniFactory public uniswapFactory;
  IUniswapV2Router01 public uniswapV2Router;

  string constant BEFORE_START="BEFORE_START";
  string constant ON_GOING="ON_GOING";
  string constant ENDED="ENDED";

  uint256 feePercent = 1000; // 1000 = 10%

  struct TeamStats {
    address token;
    address pool;
    string tokenName;
    string tokenSymbol;
    uint256 price;
    uint256 amountToken0;
    uint256 amountToken1;
    uint32 timestampLast;
    uint256 marketcap;
    uint256 liquidityAmount;
    uint256 prizePerUnit;
    uint256 circulationSupply;
    bool traded;
  }

  struct Team {
    address lpToken;
    address token;
    uint256 amountLp;
    uint256 initialStableAmount;
    uint256 snapshotId;
  }

  struct BetLock {
    uint256 lockDate; // the date the token was locked
    Team teamA;
    Team teamB;
    string status;
    uint256 unlockDate; // the date the token can be withdrawn
    uint256 lockID; // lockID nonce per uni pair
    address owner;
    uint256 result;
  }

  mapping(uint256 => BetLock) public betLocks; //map univ2 pair to all its locks
  mapping(address => mapping(uint => bool)) claimedMapping;
  uint256 betLockCounter = 0;
  uint256 totalLockTime;
  address payable devaddr;

  constructor(IUniFactory _uniswapFactory,IUniswapV2Router01 _uniswapV2Router) public {
    devaddr = msg.sender;
    uniswapFactory = _uniswapFactory;
    uniswapV2Router = _uniswapV2Router;
    totalLockTime = block.timestamp + 60*60*24*30; //1 month total lock
  }
  
  function setDev(address payable _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }

  function setFeePercent(uint256 _percent) public onlyOwner {
    require(_percent < 10 && _percent > 5, "fee precent is not in the range");
    feePercent = _percent;
  }

  /**
   * @notice Creates a new lock with a bet between lp's
   * @param _lpTokenA the univ2 token address
   * @param _tokenA the univ2 token address
   * @param _amountA amount of LP tokens to lock
   * @param _lpTokenB the univ2 token address
   * @param _tokenB the univ2 token address
   * @param _amountB amount of LP tokens to lock
   * @param _unlock_date the unix timestamp (in seconds) until unlock
   * @param intialLiquidity the stable token amount that was added to the pools when initialized
   */
  function lockLPTokenWithBet(
    address _lpTokenA,
    address _tokenA,
    uint256 _amountA,
    address _lpTokenB,
    address _tokenB,
    uint256 _amountB,
    uint256 _unlock_date,
    uint256 intialLiquidity
  ) external nonReentrant returns (uint256) {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
    require(_amountA > 0, 'INSUFFICIENT');
    require(_amountB > 0, 'INSUFFICIENT');

     // ensure this pair is a univ2 pair by querying the factory
     IUniswapV2Pair lpairA = IUniswapV2Pair(address(_lpTokenA));
     address factoryPairAddressA = uniswapFactory.getPair(lpairA.token0(), lpairA.token1());
     require(factoryPairAddressA == address(_lpTokenA), 'NOT UNIV2');

     // ensure this pair is a univ2 pair by querying the factory
     IUniswapV2Pair lpairB = IUniswapV2Pair(address(_lpTokenB));
     address factoryPairAddressB = uniswapFactory.getPair(lpairB.token0(), lpairB.token1());
     require(factoryPairAddressB == address(_lpTokenB), 'NOT UNIV2');

    if(IERC20u(_lpTokenA).balanceOf(address(msg.sender)) == _amountA){
      IERC20u(_lpTokenA).transferFrom(address(msg.sender), address(this), _amountA);
    }
    if(IERC20u(_lpTokenB).balanceOf(address(msg.sender)) == _amountB){
      IERC20u(_lpTokenB).transferFrom(address(msg.sender), address(this), _amountB);
    }

    BetLock memory bet_lock;
    Team memory teamA;
    teamA.lpToken = _lpTokenA;
    teamA.token = _tokenA;
    teamA.amountLp = _amountA;
    teamA.initialStableAmount = intialLiquidity;
    Team memory teamB;
    teamB.lpToken = _lpTokenB;
    teamB.token = _tokenB;
    teamB.amountLp = _amountB;
    teamB.initialStableAmount = intialLiquidity;
    bet_lock.teamA = teamA;
    bet_lock.teamB = teamB;
    bet_lock.unlockDate = _unlock_date;
    bet_lock.lockID = betLockCounter;
    bet_lock.result = 0;
    bet_lock.status = BEFORE_START;
    betLocks[betLockCounter] = bet_lock;
    betLockCounter = betLockCounter + 1;
    //set pool address
    IERC20u(_tokenA).setPoolAddress(bet_lock.teamA.lpToken);
    IERC20u(_tokenB).setPoolAddress(bet_lock.teamB.lpToken);
    return (betLockCounter - 1);
  }

  /**
   * @notice Claim the prize in LP if the user has won
   * @param _betId the id of the lock bet
   */
  function claim(uint256 _betId) external nonReentrant {
    require(!claimedMapping[msg.sender][_betId], "User already claimed");
    BetLock memory lock = betLocks[_betId];
    require(lock.result != 0,"results was not announced yet");

    (address losingLpToken,uint256 share) = amountAbleToClaim(msg.sender,_betId, lock.result);

    TransferHelper.safeTransfer(losingLpToken, msg.sender, share);
    claimedMapping[msg.sender][_betId] = true;

  }

  /**
   * @notice returns the lp amount the user is able to claim if a certain side was winning
   * @param user the user address
   * @param _betId the id of the lock bet
   * @param match_results the result of the match (1 for lpA, 2 for lpB)
   */
  function amountAbleToClaim(address user,uint256 _betId,uint256 match_results) public view returns(address, uint256){
    require(!claimedMapping[user][_betId], "User already claimed");
    BetLock memory lock = betLocks[_betId];

    address winningToken;
    address losingLpToken;
    address winningLpToken;
    uint256 losingLpTokenAmount;
    uint256 winningSnapshotId;

    if(match_results == 1){
      winningToken = lock.teamA.token;
      winningSnapshotId = lock.teamA.snapshotId;
      losingLpToken = lock.teamB.lpToken;
      winningLpToken = lock.teamA.lpToken;
      losingLpTokenAmount = lock.teamB.amountLp;
    }else if(match_results == 2){
      winningToken = lock.teamB.token;
      winningSnapshotId = lock.teamB.snapshotId;
      losingLpToken = lock.teamA.lpToken;
      winningLpToken = lock.teamB.lpToken;
      losingLpTokenAmount = lock.teamA.amountLp;
    }
    require(losingLpTokenAmount > 0, "not enough liquidity locked in contract");

    uint256 winningTokenUserBalance = IERC20u(winningToken).balanceOfAt(msg.sender, winningSnapshotId);
    uint256 winningTokenTotalCirculationSupply = IERC20u(winningToken).totalSupplyAt(winningSnapshotId).sub(IERC20u(winningToken).balanceOfAt(winningLpToken, winningSnapshotId));
    uint256 amount = winningTokenUserBalance.mul(losingLpTokenAmount).div(winningTokenTotalCirculationSupply);

    return (losingLpToken, amount);
  }

  /**
   * @notice Claim the prize in LP and remove liquidity to get the 2 assets
   * @param _betId the id of the lock bet
   */
  function claimAndRemoveLiquidity(uint256 _betId, uint256 deadline) external nonReentrant {

    require(!claimedMapping[msg.sender][_betId], "User already claimed");

    BetLock memory lock = betLocks[_betId];
    require(lock.result != 0);

    (address losingLpToken,uint256 share) = amountAbleToClaim(msg.sender,_betId, lock.result);

    IERC20u(losingLpToken).approve(address(uniswapV2Router), share);

    if(deadline == 0){
      deadline = block.timestamp + 60*2;
    }

    IUniswapV2Router01(uniswapV2Router).removeLiquidity(
      IUniswapV2Pair(losingLpToken).token0(),
      IUniswapV2Pair(losingLpToken).token1(),
      share,
      0,
      0,
      msg.sender,
      deadline
    );
    claimedMapping[msg.sender][_betId] = true;

  }

  /**
   * @notice start the match
   * @param _betId the id of the lock bet
   */
  function startMatch(uint256 _betId) external nonReentrant onlyOwner{
    BetLock storage lock = betLocks[_betId];
    lock.status = ON_GOING;

    IERC20u(lock.teamA.token).pause();
    IERC20u(lock.teamB.token).pause();
  }

  /**
   * @notice announce result
   * @param _betId the id of the lock bet
   * @param result the match results
   */
  function announceResult(uint256 _betId, uint256 result,bool removeInitial) external nonReentrant onlyOwner {
    BetLock storage lock = betLocks[_betId];

    _takeSnapshot(_betId);

    lock.result = result;
    betLocks[_betId] = lock;

    address winningToken;
    address losingLPtoken;
    address losingToken;
    uint256 initial;
    if(lock.result == 1){
      winningToken = lock.teamA.token;
      losingLPtoken = lock.teamB.lpToken;
      losingToken = lock.teamB.token;
      initial = lock.teamB.initialStableAmount;
    }else if(lock.result == 2){
      winningToken = lock.teamB.token;
      losingLPtoken = lock.teamA.lpToken;
      losingToken = lock.teamA.token;
      initial = lock.teamA.initialStableAmount;
    }

    IERC20u(winningToken).unpause();
    IERC20u(losingToken).unpauseExceptSelling();

    //remove intial liquidity.
    address stableToken = IUniswapV2Pair(losingLPtoken).token1();
    if(stableToken == losingToken){
      stableToken =  IUniswapV2Pair(losingLPtoken).token0();
    }

    uint256 totalInPool = IERC20u(stableToken).balanceOf(losingLPtoken);
    uint256 losingLPtokenAmount = IERC20u(losingLPtoken).balanceOf(address(this));

    uint256 initialAmountToRemove = initial.mul(100000).div(totalInPool).mul(losingLPtokenAmount).div(100000);
    uint256 feeToAmountToClaim = 0;

    if(feePercent > 0){
      if(losingLPtokenAmount > initialAmountToRemove){
        feeToAmountToClaim = losingLPtokenAmount.sub(initialAmountToRemove).mul(feePercent).div(10000);
      }
    }


    uint256 amountToRemove = initialAmountToRemove.add(feeToAmountToClaim);

    if(amountToRemove > losingLPtokenAmount){
      amountToRemove = losingLPtokenAmount;
    }
    if(removeInitial){
      IERC20u(losingLPtoken).approve(address(uniswapV2Router), amountToRemove);

      IUniswapV2Router01(uniswapV2Router).removeLiquidity(
        IUniswapV2Pair(losingLPtoken).token0(),
        IUniswapV2Pair(losingLPtoken).token1(),
        amountToRemove,
        0,
        0,
        owner(),
        block.timestamp + 60*10
      );
    }else{
      IERC20u(losingToken).transfer(owner(),amountToRemove);
    }

    lock.teamA.amountLp = IERC20u(lock.teamA.lpToken).balanceOf(address(this));
    lock.teamB.amountLp = IERC20u(lock.teamB.lpToken).balanceOf(address(this));
    lock.status = ENDED;

  }

  function _takeSnapshot(uint256 _betId) internal{
    BetLock memory lock = betLocks[_betId];
    betLocks[_betId].teamA.snapshotId = IERC20u(lock.teamA.token).snapshot();
    betLocks[_betId].teamB.snapshotId = IERC20u(lock.teamB.token).snapshot();
  }


  function withdrawLockedLP(uint256 _betId) external nonReentrant onlyOwner {
    BetLock memory lock = betLocks[_betId];
    require(lock.unlockDate < block.timestamp, 'NOT YET');
    IERC20u(lock.teamA.lpToken).transfer(owner(), IERC20u(lock.teamA.lpToken).balanceOf(address(this)));
    IERC20u(lock.teamB.lpToken).transfer(owner(), IERC20u(lock.teamB.lpToken).balanceOf(address(this)));
  }

  function withdrawToken(address token, uint256 amount) external nonReentrant onlyOwner {
    require(totalLockTime < block.timestamp, 'NOT YET');
    IERC20u(token).transfer(owner(), amount);
  }

  /**
   * @notice returns a bool if user already claimed a specific bet id
   * @param _betId the id of the lock bet
   */
  function isUserClaimed(uint256 _betId,address user) external view returns (bool) {
      return(claimedMapping[msg.sender][_betId]);
  }
  function getLpAmountAbleToClaim(uint256 _betId,uint8 result, uint256 winningTokenAmount) external view returns (uint256) {
    BetLock memory lock = betLocks[_betId];

    address winningToken;
    address losingLpToken;
    uint256 losingLpTokenAmount;

    if(result == 1){
      winningToken = lock.teamA.token;
      losingLpToken = lock.teamB.lpToken;
    }else if(result == 2){
      winningToken = lock.teamB.token;
      losingLpToken = lock.teamA.lpToken;
    }
    losingLpTokenAmount = IERC20u(losingLpToken).balanceOf(address(this));

    uint256 winningTokenTotalSupply = IERC20u(winningToken).totalSupply();
    uint256 share = winningTokenAmount.mul(losingLpTokenAmount).div(winningTokenTotalSupply);

    return share;
  }

  /**
     * @notice get the current total prize for each team
   * @param _betId the id of the lock bet
   */
  function getCurrentTotalPrizes(uint256 _betId) public view returns (uint256, uint256) {
    uint256 totalPrizeA;
    uint256 totalPrizeB;
    BetLock memory lock = betLocks[_betId];

    address stableCoin = IUniswapV2Pair(lock.teamA.lpToken).token1();
    if(stableCoin == lock.teamA.token){
      stableCoin =  IUniswapV2Pair(lock.teamA.lpToken).token0();
    }

    if(lock.result == 0){
      totalPrizeA = IERC20u(stableCoin).balanceOf(lock.teamB.lpToken).sub(lock.teamB.initialStableAmount);
      totalPrizeB = IERC20u(stableCoin).balanceOf(lock.teamA.lpToken).sub(lock.teamA.initialStableAmount);

    }else if(lock.result == 1){
      totalPrizeA = IERC20u(stableCoin).balanceOf(lock.teamB.lpToken);
      totalPrizeB = 0;

    }else if(lock.result == 2){
      totalPrizeA = 0;
      totalPrizeB = IERC20u(stableCoin).balanceOf(lock.teamA.lpToken);
    }

    //remove fee
    uint256 fee = 0;
    if(feePercent > 0){
      if(totalPrizeA > 0){
        fee = totalPrizeA.mul(feePercent).div(10000);
        totalPrizeA = totalPrizeA.sub(fee);
      }
      if(totalPrizeB > 0){
        fee = totalPrizeB.mul(feePercent).div(10000);
        totalPrizeB = totalPrizeB.sub(fee);
      }
    }

    return (totalPrizeA, totalPrizeB);
  }

  /**
     * @notice retruns stats of a match
   * @param _betId the id of the lock bet
   */
  function getStats(uint256 _betId) external view returns (TeamStats memory,TeamStats memory,uint256 result,string memory status) {
    BetLock memory lock = betLocks[_betId];
    require(lock.teamA.lpToken != address(0x0000000000000000000000000000000000000000),"lock id is not exist");
    (uint256 prizeA,uint256 prizeB) = getCurrentTotalPrizes(_betId);
    TeamStats memory statsA;
    address pool = lock.teamA.lpToken;
    statsA.token = lock.teamA.token;
    statsA.pool = lock.teamA.lpToken;

    (statsA.amountToken0,statsA.amountToken1,statsA.timestampLast) = IUniswapV2Pair(pool).getReserves();

    uint256 tokenDecimals = IERC20u(statsA.token).decimals();
    address stableAddress;

    if(statsA.token == IUniswapV2Pair(pool).token0()){
      stableAddress = IUniswapV2Pair(pool).token1();
    }else{
      stableAddress = IUniswapV2Pair(pool).token0();
      uint256 amountStables = statsA.amountToken0;
      statsA.amountToken1 = statsA.amountToken0;
      statsA.amountToken0 = amountStables;
    }

    uint256 decimalsDiff = tokenDecimals.sub(IERC20u(stableAddress).decimals());
    uint256 amountStable = IERC20u(stableAddress).balanceOf(statsA.pool);
    uint256 amountToken = IERC20u(statsA.token).balanceOf(statsA.pool);
    uint256 amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
    statsA.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
    statsA.marketcap = statsA.price * IERC20u(statsA.token).totalSupply().div(1000000000);
    statsA.traded = !IERC20u(statsA.token).isPaused();
    statsA.tokenName = IERC20u(statsA.token).name();
    statsA.tokenSymbol = IERC20u(statsA.token).symbol();
    statsA.circulationSupply = IERC20u(statsA.token).totalSupply().sub(IERC20u(statsA.token).balanceOf(statsA.pool));
    statsA.liquidityAmount = IERC20u(stableAddress).balanceOf(statsA.pool).mul(2);

    if(statsA.circulationSupply > 0){
      statsA.prizePerUnit = prizeA.mul(1000000000).div(statsA.circulationSupply);
    }else{
      statsA.prizePerUnit = prizeA.mul(1000000000);
    }

    TeamStats memory statsB;
    pool = lock.teamB.lpToken;
    statsB.token = lock.teamB.token;
    statsB.pool = pool;
    (statsB.amountToken0,statsB.amountToken1,statsB.timestampLast) = IUniswapV2Pair(pool).getReserves();
    tokenDecimals = IERC20u(statsB.token).decimals();

    if(statsB.token == IUniswapV2Pair(statsB.pool).token0()){
      stableAddress = IUniswapV2Pair(statsB.pool).token1();
    }else{
      stableAddress = IUniswapV2Pair(statsB.pool).token0();
      uint256 amountStables = statsB.amountToken0;
      statsB.amountToken1 = statsB.amountToken0;
      statsB.amountToken0 = amountStables;
    }
    decimalsDiff = tokenDecimals.sub(IERC20u(stableAddress).decimals());
    amountStable = IERC20u(stableAddress).balanceOf(statsB.pool);
    amountToken = IERC20u(statsB.token).balanceOf(statsB.pool);
    amountStableAfterDecimals = amountStable.mul(10 ** decimalsDiff);
    statsB.price = amountStableAfterDecimals.mul(1000000000).div(amountToken);
    statsB.marketcap = statsB.price * IERC20u(statsB.token).totalSupply().div(1000000000);
    statsB.traded = !IERC20u(statsB.token).isPaused();
    statsB.tokenName = IERC20u(statsB.token).name();
    statsB.tokenSymbol = IERC20u(statsB.token).symbol();
    statsB.circulationSupply = IERC20u(statsB.token).totalSupply().sub(IERC20u(statsB.token).balanceOf(statsB.pool));
    statsB.liquidityAmount = IERC20u(stableAddress).balanceOf(statsB.pool).mul(2);

    if(statsB.circulationSupply > 0){
      statsB.prizePerUnit = prizeB.mul(1000000000).div(statsB.circulationSupply);
    }else{
      statsB.prizePerUnit = prizeB.mul(1000000000);
    }
  return(statsA, statsB, lock.result, lock.status);
  }

}