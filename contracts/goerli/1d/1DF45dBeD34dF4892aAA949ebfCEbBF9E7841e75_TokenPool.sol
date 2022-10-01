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