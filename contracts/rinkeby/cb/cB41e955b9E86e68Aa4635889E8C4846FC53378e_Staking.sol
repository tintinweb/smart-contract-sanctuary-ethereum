// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/ICentralBank.sol";
import "./interfaces/IUSDB.sol";
import "./interfaces/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/Math.sol";

contract Staking is Ownable{
  address public usdb;
  address public controller;
  // token tracking
  mapping(address => bool) public stakingTokens;
  address[] public historyStakingTokens;

  // staker address => (staking token => total liquidity)
  mapping(address => mapping(address => uint256)) public stakerLiquidityLocked;
  // staking token => total liquidity
  mapping(address => uint256) public tokenLiquidityLocked;

  // staker address => LockedStake[]
  mapping(address => LockedStake[]) public stakerLocked;
  // staking token => LockedStake[]
  mapping(address => LockedStake[]) public tokenLocked;

  // uint256 public yieldPerUSDBStored;
  mapping(address => uint256) private rewardsPerTokenStored;

  uint256 public currentPeriod;
  uint256 public lastUpdateTime;
  uint256 public lastUpdatePeriod;
  // staker addr => reward token => paid amount
  mapping(address => mapping(address => uint256)) public userRewardsPerTokenPaid;
  mapping(address => uint256) public lastRewardClaimTime;
  mapping(address => uint256) public lastRewardClaimPeriod;
  // staker address => weight
  // mapping(address => uint256) public pendingWeights;
  // uint256 public pendingTotalWeight;

  uint256 private _MULTIPLIER_;
  // staking token => Multiplier[]
  mapping(address => Multiplier[]) public multiplierStored;

  uint256 public MINIMUM_REWARD;
  Period[] public periodStore;
  
  // reward tracking
  address[] public rewardTokens;
  mapping(address => uint256) public rewardTokenAddrToIdx;
  mapping(address => Reward) rewardPool;

  // mapping(address => Reward[]) public rewardPool;
  // mapping(uint256 => Reward) public rewardPoolOfPeriods;

  uint256 private TOKEN_UNIT = 1e18;

  struct Multiplier {
    uint256 value;        // 6 decimals of precision. 1x = 1000000
    uint256 nonce;
  }

  struct Reward{
    address token;
    uint256 total;
    uint256 balance;
  }

  struct Period{
    uint256 nonce;
    address rewardToken;
    uint256 total;
    uint256 balance;
    uint256 startAt;
    uint256 endAt;
    uint256 startPerStored;
    uint256 yieldPerStored;
    bool    init;
  }

  struct LockedStake{
    bytes32 kekId;
    address staker;
    address token;
    uint256 liquidity;
    uint256 startAt;
    uint256 endAt;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyController(){
    require(msg.sender == controller, "Caller is not the controller");
    _;
  }

  /* ========== CONSTRUCTOR ========== */

  constructor() {
    
  }

  function initialize(address _usdb, address _controller) public onlyOwner{
    usdb = _usdb;
    controller = _controller;
    _MULTIPLIER_ = 1000000;
    MINIMUM_REWARD = 10**3;
    // __Ownable_init();
  }

  /* ========== ADMIN ========== */
  function setController(address _controller) external onlyOwner{
    controller = _controller;
  }

  function setMultiplier(address _token, uint256 _value, uint256 _nonce) external onlyOwner{
     Multiplier[] storage tokenMuls = multiplierStored[_token];
     Multiplier memory newMul = Multiplier(_value, _nonce);
     if(tokenMuls.length > 0){
       require(tokenMuls[tokenMuls.length-1].nonce < _nonce, "Invalid multiplier");
     }
     tokenMuls.push(newMul);
  }

  function addStakingToken(address _token) external onlyOwner{
    require(_token!=address(0), "Invalid staking token");

    stakingTokens[_token] = true;

    bool contains = false;
    for (uint256 i = 0; i < historyStakingTokens.length; i++) {
      if(historyStakingTokens[i] == _token){
        contains = true;
        break;
      }
    }
    if(!contains){
      historyStakingTokens.push(_token);
    }
  }

  function removeStakingToken(address _token) external onlyOwner{
    require(_token!=address(0), "Invalid staking token");
    stakingTokens[_token] = false;
  }

  function catchUp(address _token, uint256 _amount, uint256 _nonce, uint256 _startAt, uint256 _endAt) external onlyController{
    require(periodStore.length<=_nonce || !periodStore[_nonce].init , "Period already initialized");
    require(_nonce == periodStore.length, "Invalid period");

    if(_startAt<=block.timestamp && block.timestamp<_endAt){
      currentPeriod = _nonce;
    }

    bool contains = false;
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      if(rewardTokens[i] == _token){
        rewardTokenAddrToIdx[_token] = i;
        contains = true;
        break;
      }
    }
    if(!contains){
      rewardTokenAddrToIdx[_token] = rewardTokens.length;
      rewardTokens.push(_token);
      rewardsPerTokenStored[_token] = 0;
    }
    rewardPool[_token].total = rewardPool[_token].total+_amount;
    rewardPool[_token].balance = rewardPool[_token].balance+_amount;

    periodStore.push(Period(_nonce,_token,_amount,_amount,_startAt,_endAt,0,0,true));
    _updatePeriodYieldStored(_nonce);
  }

  function _calYieldStored(uint256 _rate, uint256 _timeElapse, uint256 _totalsupply) private view returns(uint256){
    if(_totalsupply>0){
      return _rate * _timeElapse / _totalsupply;
    }else{
      return 0;
    }
  }

  function _updatePeriodYieldStored(uint256 _nonce) private {
    if(periodStore.length<=_nonce || lastUpdateTime>=block.timestamp){
      return;
    }
    Period memory period = periodStore[_nonce];
    if(lastUpdateTime>=period.endAt || period.startAt>block.timestamp){
      return;
    }
    uint256 rate = period.total/(period.endAt-period.startAt);
    uint256 periodUpdateElapseTime = Math.min(block.timestamp, period.endAt)-Math.max(period.startAt,lastUpdateTime);
    uint256 lpTotalSupply = _totalLiquidityLocked(_nonce);

    uint256 yieldPerStored = _calYieldStored(rate, periodUpdateElapseTime, lpTotalSupply);
    if(periodStore[_nonce].startPerStored == 0 && lastUpdateTime<period.startAt){
      periodStore[_nonce].startPerStored = rewardsPerTokenStored[period.rewardToken];
      periodStore[_nonce].yieldPerStored = periodStore[_nonce].startPerStored + yieldPerStored;
    }else{
      periodStore[_nonce].yieldPerStored = periodStore[_nonce].yieldPerStored + yieldPerStored;
    }
    
    rewardsPerTokenStored[period.rewardToken] = rewardsPerTokenStored[period.rewardToken]+yieldPerStored;
    lastUpdateTime = Math.min(period.endAt, block.timestamp);
    lastUpdatePeriod = _nonce;
  }

  function tokenMultiplier(address _token, uint256 _nonce) public view returns(uint256){
    Multiplier[] memory multipliers = multiplierStored[_token];
    if(multipliers.length == 0){
      return _MULTIPLIER_;
    }
    uint256 m = _MULTIPLIER_;
    for (uint256 i = 0; i < multipliers.length; i++) {
      if(multipliers[i].nonce > _nonce){
        break;
      }
      m = multipliers[i].value;
    }
    return m;
  }

  function _totalLiquidityLocked(uint256 _nonce) private view returns(uint256){
    uint256 totalLiquidityLocked = 0;
    for (uint256 i = 0; i < historyStakingTokens.length; i++) {
      address token = historyStakingTokens[i];      
      if(stakingTokens[token]){
        uint256 multiplier = tokenMultiplier(token, _nonce);
        totalLiquidityLocked = totalLiquidityLocked + tokenLiquidityLocked[token] * multiplier;
      }
    }
    return totalLiquidityLocked/_MULTIPLIER_;
  }

  function needCatchUp() private view returns(bool){
    if(periodStore.length == 0 || periodStore[periodStore.length-1].endAt<=block.timestamp){
      return true;
    }
    return false;
  }

  function sync() public {
    if(needCatchUp()){
      ICentralBank(controller).catchUp();
    }
    for (uint256 i = 0; i < periodStore.length; i++) {
      Period memory period = periodStore[i];
      _updatePeriodYieldStored(period.nonce);
    }
  }

  function periodForTime(uint256 _timestamp) public view returns(uint256){
    for (uint256 i = 0; i < periodStore.length; i++) {
      if(periodStore[i].startAt<=_timestamp && _timestamp<periodStore[i].endAt){
        return periodStore[i].nonce;
      }
    }
    return 0;
  }

  function claim() public {
    _claim(msg.sender);
  }

  function _claim(address _staker) private{
    sync();
    
    uint256 nonce = lastRewardClaimPeriod[_staker];
    uint256[] memory earnedAmount = new uint256[](rewardTokens.length);
    for (uint256 i = 0; i < historyStakingTokens.length; i++) {
      address token = historyStakingTokens[i];
      uint256 lpLocked = stakerLiquidityLocked[_staker][token];
      if(lpLocked == 0){
        continue;
      }
      for (uint256 j = nonce; j < periodStore.length; j++) {
        Period memory period = periodStore[j];
        if(period.startAt>block.timestamp){
          break;
        }
        uint256 multiplier = tokenMultiplier(token, period.nonce);
        uint256 endM = period.yieldPerStored;
        uint256 startM;
        if(lastRewardClaimTime[_staker]>=period.startAt){
          startM = userRewardsPerTokenPaid[_staker][period.rewardToken];
        }else{
          startM = period.startPerStored;
        }
        uint256 rewardIdx = rewardTokenAddrToIdx[period.rewardToken];
        earnedAmount[rewardIdx] = earnedAmount[rewardIdx] + (endM-startM) * lpLocked * multiplier / _MULTIPLIER_;
      }
    }

    lastRewardClaimPeriod[_staker] = lastUpdatePeriod;
    lastRewardClaimTime[_staker] = lastUpdateTime;
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      userRewardsPerTokenPaid[_staker][rewardToken] = rewardsPerTokenStored[rewardToken];
      if(earnedAmount[i]>0){
        uint256 rewardAmount = earnedAmount[i];
        TransferHelper.safeTransfer(rewardToken, _staker, rewardAmount);
        emit Claim(_staker, rewardToken, rewardAmount);
      }
    }
      
  }


  function stake(address _token,uint256 _liquidity, uint256 _secs) public {
    require(_liquidity > 0, "Must stake more than zero");
    require(stakingTokens[_token], "Invalid staking token");

    _claim(msg.sender);

    address staker = msg.sender;
    bytes32 kekId = keccak256(abi.encodePacked(staker, block.timestamp, _liquidity, stakerLiquidityLocked[staker][_token]));
    LockedStake memory locked = LockedStake(
      kekId,
      staker,
      _token,
      _liquidity,
      block.timestamp,
      block.timestamp + _secs
    );
    stakerLocked[staker].push(locked);
    tokenLocked[_token].push(locked);

    stakerLiquidityLocked[staker][_token] = stakerLiquidityLocked[staker][_token] + _liquidity;
    tokenLiquidityLocked[_token] = tokenLiquidityLocked[_token] + _liquidity;

    TransferHelper.safeTransferFrom(address(_token), staker, address(this), _liquidity);

    emit Stake(staker, _token, _liquidity, _secs, kekId);
  }

  function _updateStakingLiquidity(address _token, bytes32 _kekId, uint256 _remain) private{
    for (uint256 i = 0; i < tokenLocked[_token].length; i++) {
      if(tokenLocked[_token][i].kekId == _kekId){
        if(_remain == 0){
          delete tokenLocked[_token][i];
        }else{
          tokenLocked[_token][i].liquidity = _remain;
        }
        break;
      }
    }
  }

  function unstake(address _token, uint256 _liquidity) public {
    require(_liquidity > 0, "Must stake more than zero");

    _claim(msg.sender);

    address staker = msg.sender;
    uint256 unstakedLiquidity = _liquidity;

    for (uint i = 0; i < stakerLocked[staker].length; i++){
      LockedStake storage locked = stakerLocked[staker][i];
      if(locked.token == _token && locked.endAt < block.timestamp && locked.liquidity>0){
        if(locked.liquidity < unstakedLiquidity){
          unstakedLiquidity = unstakedLiquidity - locked.liquidity;
          locked.liquidity = 0;

          _updateStakingLiquidity(_token, locked.kekId, 0);
        }else{
          locked.liquidity = locked.liquidity - unstakedLiquidity;
          unstakedLiquidity = 0;

          _updateStakingLiquidity(_token, locked.kekId, locked.liquidity);
          break;
        }
      }
      if(locked.liquidity == 0){
        delete stakerLocked[staker][i];
      }
    }

    require(unstakedLiquidity == 0, "insufficient liquidity");

    stakerLiquidityLocked[staker][_token] = stakerLiquidityLocked[staker][_token] - _liquidity;
    tokenLiquidityLocked[_token] = tokenLiquidityLocked[_token] - _liquidity;

    IUniswapV2Pair(_token).transfer(staker, _liquidity);

    emit Unstake(staker, _token, _liquidity);
  }

  


  /* ========== EVENTS ========== */

  event Stake(address indexed user,address token,uint256 liquidity, uint256 secs, bytes32 kekId);
  event Unstake(address indexed user,address token, uint256 liquidity);
  event Claim(address indexed user,address token, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.4;

interface ICentralBank {
  function claim(address staker, uint256 liquidityMultiplier, uint256 totalMultiplier) external returns(bool);
  function catchUp() external;
}

pragma solidity ^0.8.4;

interface IUSDB {
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

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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
pragma solidity >=0.6.11;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
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