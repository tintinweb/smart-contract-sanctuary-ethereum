//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "IERC20.sol";
import "ITokenPool.sol";
import "TokenPool.sol";

contract Registry {
//Variables
address public owner;
address[] public tokenPools;
address public factory; 
mapping (address => address) public tokenToPool;
mapping (address => address) public PoolToToken;
mapping (address => uint256) public PoolToConcentration;
uint256 constant PRECISION = 1e6;


//Structs
struct Rebalancing {
    address pool;
    uint256 amt;
}

//Errors
error Error_Unauthorized();

//Events
event ReservePoolDeployed(
        address indexed poolAddress,
        address tokenAddress
    );

//Modifier
modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Error_Unauthorized();
        }
        _;
    }
//Constructor
    constructor(){
       owner = msg.sender;
    }

/**
@dev function to set the factory address
@param _factory (address of the factory)
 */
    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

/**
@dev function to add TokenPool to tokenPool array and various mappings
@param _tokenPool - address of tokenPool
@param _token - address of token
@param concentration - value of target concentration 
 */
    function addTokenPool(address _tokenPool, address _token, uint256 concentration) public {
        require(msg.sender == owner, "Only the factory can add token pools");
        tokenPools.push(_tokenPool);
        tokenToPool[_token] = _tokenPool;
        PoolToToken[_tokenPool] = _token;
        PoolToConcentration[_tokenPool] = concentration;
    }

/** 
@dev function to update the target concentration of a specific pool 
@param _pool - address of tokenPool
@param _target - value of target concentration
 */
    function setTargetConcentration(address _pool, uint256 _target)
        external
        onlyOwner
    {
        PoolToConcentration[_pool] = _target;
    }

/**
@dev function to get the total USD value of all assets in the protocol
iterates through all the pools to get their usd value and adds all the values together
 */

    function getTotalAUMinUSD() public view returns (uint256) {
        uint256 total = 0;
        uint256 len = tokenPools.length;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];  
            uint256 poolBalance = ITokenPool(pool).getPoolValue();
            total += poolBalance;
            unchecked{++i;}
        }
        return total;
    }

/** 
@dev function to get the pools to withdraw from and the amount to withdraw from each pool
@param _amount - amount in usd to be withdrawn
 */
    function tokensToWithdraw(uint256 _amount) public view returns (address[] memory, uint256[] memory){
        (address[] memory pools, uint256[] memory tokenAmt) = checkWithdraw(_amount);
        return (pools, tokenAmt);
    }


/**
@dev function that finds which pools need to be rebalanced through a withdraw
@param _amount - how much usd is to be withdrawn
Calculates new aum and how much money has to be added/removed from pool to reach the target concentration
Checks which pool have to have money removed (and how much) and adds them to the array 
 */
    function liquidityCheck(uint256 _amount) public view returns(Rebalancing[] memory)  {
        uint len = tokenPools.length;
        Rebalancing[] memory withdraw = new Rebalancing[](len);
        uint aum = getTotalAUMinUSD();
        uint newAUM = aum - _amount;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];
            uint256 poolBalance = ITokenPool(pool).getPoolValue();
            uint256 target = PoolToConcentration[pool];
            uint256 poolTarget = newAUM*target/PRECISION;
            if(poolBalance > poolTarget){
                uint256 amt = poolBalance - poolTarget;
                withdraw[i]=(Rebalancing({pool: pool, amt: amt}));
            }
            else{
                withdraw[i]=(Rebalancing({pool: pool, amt: 0}));
            }
            unchecked{++i;}
        }
        return withdraw;
        }
    
/**
@dev function that takes the rebalancing array from liquidityCheck and returns the pools to withdraw from
and how much to withdraw from each pool
Checks total amount to be withdraw, finds pools with greatest concentration disparity and takes from those first
@param _amount - amount to be withdrawn
 */
    function checkWithdraw(uint _amount)public view returns (address[] memory, uint256[] memory){
        Rebalancing[] memory withdraw = liquidityCheck(_amount);
        uint256 len = withdraw.length;
        address[] memory pool = new address[](len);
        uint[] memory tokenamt = new uint[](len);
        uint total = 0;
        for (uint i; i<len;){
            (Rebalancing memory max, uint index) = findMax(withdraw);
            if ((total<_amount)&&(total + max.amt > _amount)){
                tokenamt[i]= (_amount - total);
                pool[i] = (max.pool);
                total += tokenamt[i];
            }
            else if ((total<_amount)&&(total + max.amt <= _amount)){
                tokenamt[i] = (max.amt);
                pool[i] = (max.pool);
                total += max.amt;
                 withdraw[index].amt = 0;
            }
            unchecked{++i;}
           }
        return (pool, tokenamt);
    }
/**
@dev helper function that finds which pool has to have the most money withdrawn
@param _rebalance - rebalancing array 
 */
        function findMax (Rebalancing[] memory _rebalance) public pure returns (Rebalancing memory, uint256){ 
        uint256 len = _rebalance.length;
        uint max = 0;
        uint index = 0;
        for (uint i = 0; i<len;){
            if (max < _rebalance[i].amt){
                max = _rebalance[i].amt;
                index = i;
            }
            unchecked{++i;}
        }
        return (_rebalance[index],index);
    }
/**
@dev function to get the current concentration of a specific pool
@param pool - pool to fnd concentration of 
 */

    function getConcentration(address pool) view public returns(uint){
            uint256 total = getTotalAUMinUSD();
            uint256 poolBalance = ITokenPool(pool).getPoolValue();       
            return total == 0 ? 0 :poolBalance*PRECISION/total;
        }
/**
@dev function to get the concentration of certain pool when a certain amount is added to the pool
@param pool - pool to find concentration of
@param amount - amount to be added to pool
 */
    function getNewConcentration (address pool, uint amount) view public returns (uint){    
            uint256 total = getTotalAUMinUSD() + amount;
            uint256 poolBalance = ITokenPool(pool).getPoolValue() + amount;       
            return total == 0 ? 0 : poolBalance*PRECISION/total;
            
        }
/**
@dev checks if any pool has a concentration more than "percent" % above/below target concentration
@param percent - percent above/below target concentration 
 */
    function checkDeposit(uint percent) public view returns (bool){
        uint len = tokenPools.length;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];
            uint currentConcentration = getConcentration(pool);
            int diff = int(currentConcentration) - int(PoolToConcentration[pool]);
            uint absdiff = abs(diff);
            if (absdiff>percent) {
                return (true);
            }
            unchecked{++i;}
        }
        return (false);
    }
    function abs (int256 x) public pure returns (uint){
        if (x<0){
            x = 0 - x;
            return uint(x);
        }
        else{
            return uint(x);
        }
    }
    
    function calcDeposit() public view returns (uint){
        uint total = 0;
        uint len = tokenPools.length;
        for (uint i = 0; i < len;) {
            address pool = tokenPools[i];
            uint currentConcentration = getConcentration(pool);
            int diff = int(currentConcentration) - int(PoolToConcentration[pool]);
            uint absdiff = abs(diff);
            total += absdiff;
            unchecked {++i;}
    } return total;}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface ITokenPool {
    
    
    function getPoolValue() external view returns (uint256);

    function getDepositValue(uint256) external view returns (uint256);
    
    function withdrawToken(address , uint256) external ;
    
    function getPrice() external returns (uint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

//import "AggregatorV3Interface.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenPool{
//variables
IERC20 public immutable token;
address public chainlinkfeed;
uint256 public targetconcentration;
AggregatorV3Interface public oracle;
uint256 public decimal;

//constructor
constructor (address _tokenAddress, address _chainlinkfeed, uint256 _targetconcentration, uint256 _decimal)  {
    token = IERC20(_tokenAddress);
    chainlinkfeed = _chainlinkfeed;
    oracle = AggregatorV3Interface(_chainlinkfeed);
    targetconcentration = _targetconcentration;
    decimal = _decimal;

}
/** 
@dev function to get current price of the token from the oracle 
returns the price of the token in USD with 18 decimals 
(token has 18 decimals, oracle has 8 decimals, so we multiply by 10^10 to make oracle price same decimals as token) )
 */
function getPrice() public  view returns (uint256){
    (,int256 price, , , ) = oracle.latestRoundData();
    uint256 decimals = oracle.decimals();
    return (uint256(price) * (10**(18-decimals)));
}

/**
@dev function to get the current pool value in USD
Multiplies the price of the token by number of tokens in the pool and divides by amount of token decimals 
 */
function getPoolValue() public view returns(uint256){
    uint256 price = getPrice();
    return ((token.balanceOf(address(this)) * price)/10**decimal);
}

/**
@dev function to get the usd value of the number of tokens someone wants to deposit
@param _amount (number of tokens to be deposited)
 */
 
function getDepositValue(uint256 _amount) external view returns(uint256){
    uint256 price = getPrice();
    return ((_amount * price) / (10 ** decimal));
}

/**
@dev function to send user tokens upon withdrawal
@param receiver - who to send the tokens to
@param amount - how much to send 
 */
function withdrawToken(address receiver, uint256 amount) external  {
    bool success = token.transfer(receiver, amount);
    require(success);
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}