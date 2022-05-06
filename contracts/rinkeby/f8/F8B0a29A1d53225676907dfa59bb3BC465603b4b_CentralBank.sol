// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IUSDB.sol';
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapOracle.sol";
import './interfaces/IStaking.sol';
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import './interfaces/Math.sol';

contract CentralBank is Ownable{
  uint256 private INFLAT_MULTIPLIER = 100000000;

  address public usdb;
  address public usds;
  // store staking contract address
  address public staking;

  bool initialized;

  address public oracle;
  OracleToken[] public oracleTokens;
  uint256 ORACLE_MULTIPLIER = 10000;

  uint256 public periodDuration;
  uint256 public genesisRate;
  uint256 public lastUpdateTime;
  uint256 public lastNonceUpdated;
  uint256 public halvingDuration;

  // Period[] public periods;
  uint256 public lastRewardPeriod;
  mapping(uint256 => Period) public periods;
  mapping(uint256 => Pool) public pools;

  struct Period{
    uint256 nonce;
    uint256 rate;
    uint256 startAt;
    uint256 endAt;
  }

  struct OracleToken{
    address token;
    uint256 multiplier;   // 1x = 10000
  }

  struct Pool{
    uint256 nonce;
    address token;
    uint256 total;
    uint256 rewardAmount;
    bool done;
  }

  modifier onlyStaking(){
    require(staking == msg.sender, "invalid call");
    _;
  }

  constructor() {
    
  }

  modifier sync(){
    catchUp();
    _;
  }

  /* ========== ADMIN ========== */
  function setNextRate(uint256 _rate) public sync() onlyOwner {

    uint256 currentNonce = currentPeriod();
    require(currentNonce+1>lastNonceUpdated,"Period invalid");

    Period memory lastPeriod = periods[currentNonce];
    periods[currentNonce+1] = Period(
      currentNonce+1,_rate,lastPeriod.endAt,lastPeriod.endAt+periodDuration
    );
    lastNonceUpdated = currentNonce+1;
    lastUpdateTime = block.timestamp;
  }

  function setOracle(address _oracle) external onlyOwner {
    oracle = _oracle;
  }

  function setStaking(address _staking) external onlyOwner{
    staking = _staking;
  }

  function addOracleToken(address _token, uint256 _multiplier) external onlyOwner{
    bool contains = false;
    for (uint256 i = 0; i < oracleTokens.length; i++) {
      if(oracleTokens[i].token == _token){
        contains = true;
        oracleTokens[i].multiplier = _multiplier;
        break;
      }
    }
    if(!contains){
      oracleTokens.push(OracleToken(_token, _multiplier));
    }
  }

  function removeOracleToken(address _token) external onlyOwner{
    bool contains = false;
    uint256 idx = 0;
    for (uint256 i = 0; i < oracleTokens.length; i++) {
      if(oracleTokens[i].token == _token){
        contains = true;
        idx = i;
        break;
      }
    }

    require(contains, "Not in oracles");

    delete oracleTokens[idx];
  }

  function initialize(address _usdb,address _usds, uint256 _startAt) external onlyOwner{
    require(!initialized, "initialized");
    usdb = _usdb;
    usds = _usds;
    periodDuration = 60*3; //30 minutes
    halvingDuration = 30*60*2; // 30 minutes
    lastUpdateTime = block.timestamp;
    genesisRate = 6 * INFLAT_MULTIPLIER / 100;   // 6% per 12hours
    lastNonceUpdated = 0;

    periods[0] = Period(
      0,
      genesisRate,
      _startAt,
      _startAt + periodDuration
    );

    initialized = true;
    if(block.timestamp>=_startAt){
      _inflat(0);
    }
  }

  /* ========== FUNCTION ========== */
  function catchUp() public{
    catchUpElapse(10);
  }

  function catchUpElapse(uint256 _maxElapsePeriod) public{
    _periodCatchUp(_maxElapsePeriod);
    _inflatCatchUp();
  }

  function _calculateRate(uint256 _nonce) private view returns(uint256) {
    uint256 timeElapsed = _nonce*periodDuration;
    uint256 halvingTimes = timeElapsed/halvingDuration;

    // min rate 0.75%
    return Math.max(genesisRate/(2**halvingTimes), 75*INFLAT_MULTIPLIER / 10000);
  }

  function _inflatCatchUp() internal {
    require(initialized, "initialize not ready");
    require(lastRewardPeriod <= lastNonceUpdated, "Period data error");
    for (uint256 i = lastRewardPeriod; i < lastNonceUpdated+1; i++) {
      _inflat(i);
    }
  }

  function _periodCatchUp(uint256 _maxElapsePeriod) internal{
    require(initialized, "initialize not ready");
    Period memory lastPeriod = periods[lastNonceUpdated];
    if(lastPeriod.endAt>=block.timestamp){
      return;
    }
    uint256 numPeriodsElapsed = Math.min(uint256(block.timestamp - lastPeriod.endAt) / periodDuration+1, _maxElapsePeriod);
    for (uint256 i = 0; i < numPeriodsElapsed; i++) {
      uint256 nonce = lastPeriod.nonce+i+1;
      uint256 rate = _calculateRate(nonce);
      periods[nonce] = Period(
        nonce,rate,lastPeriod.endAt+i*periodDuration,lastPeriod.endAt+(i+1)*periodDuration
      );

      lastNonceUpdated = nonce;
    }
    
    lastUpdateTime = block.timestamp;
  }

  function currentPeriod() public view returns(uint256) {
    require(block.timestamp>=periods[0].startAt, "Period not start");
    return uint256(block.timestamp - periods[0].startAt) / periodDuration;
  }

  function _inflat(uint256 _nonce) private{
    require(initialized, "initialize not ready");
    // require(lastRewardPeriod<_nonce || (lastRewardPeriod==0 && !pools[_nonce].done), "Wrong inflat period");
    // require(periods[_nonce].startAt<=block.timestamp && periods[_nonce].endAt>0, "Period not start");
    if(pools[_nonce].done){
      return;
    }
    if(periods[_nonce].startAt>block.timestamp || periods[_nonce].endAt==0){
      return;
    }

    Period memory period = periods[_nonce];
    uint256 price = _cumulatePrice();
    uint256 inflatAmount;
    uint256 rewardAmount;
    address rewardToken;
    if(price<98){
      // price of usdb < 0.98, 200W usds reward
      rewardToken = usds;
      inflatAmount = 2000000*1e18;
      rewardAmount = inflatAmount;
    }else{
      rewardToken = usdb;
      inflatAmount  = IUSDB(usdb).totalSupply() * period.rate / INFLAT_MULTIPLIER;
      rewardAmount = inflatAmount;
    }

    pools[_nonce] = Pool(
      _nonce,
      rewardToken,
      inflatAmount,
      rewardAmount,
      true
    );

    lastRewardPeriod = _nonce;

    IUSDB(rewardToken).mint(address(this), inflatAmount);
    TransferHelper.safeTransfer(rewardToken, staking, rewardAmount);

    // notify staking
    IStaking(staking).catchUp(rewardToken, rewardAmount,_nonce, period.startAt, period.endAt);

    emit Inflat(_nonce,rewardToken,inflatAmount,rewardAmount,period.startAt, period.endAt);
  }

  function inflat() public sync() onlyOwner{
    uint256 currentNonce = currentPeriod();
    _inflat(currentNonce);
  }

  function _cumulatePrice() private view returns (uint256) {
    uint256 count = 0;
    uint256 price = 0;
    for (uint256 i = 0; i < oracleTokens.length; i++) {
      if(oracleTokens[i].token != address(0)){
        IUniswapV2Pair pair = IUniswapV2Pair(oracleTokens[i].token);
        address token1;
        if(pair.token0()==usdb){
          token1 = pair.token1();
        }else{
          token1 = pair.token0();
        }
        uint256 amountOut = IUniswapOracle(oracle).consult(usdb,100e18,token1);
        price = price + amountOut * oracleTokens[i].multiplier;
        count = count+1;
      }
    }

    require(count>0, "No price oracle");

    return price/(1e18*count*ORACLE_MULTIPLIER);
  }


  /* ========== EVENTS ========== */

  event Inflat(uint256 indexed nonce,address token,uint256 total, uint256 reward, uint256 startAt, uint256 endAt);
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

interface IUniswapOracle{
  function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
  function update(address tokenA, address tokenB) external;
}

pragma solidity ^0.8.4;

interface IStaking{
  function catchUp(address _token, uint256 _amount, uint256 _nonce, uint256 _startAt, uint256 _endAt) external;
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