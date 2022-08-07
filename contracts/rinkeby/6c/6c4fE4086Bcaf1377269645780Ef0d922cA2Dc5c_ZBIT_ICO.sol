//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ZBIT_ICO is Ownable{

    using SafeMath for uint256;
    mapping(address=>bool) private validTokens;
    mapping(address=>uint256) private validTokensRate;
    mapping(address=>address) private tokensAggregator;

    //Tokens per 1 USD => example rate = 1000000000000000000 wei => means 1USD = 1 Token
    //since our ICO is cross-chain, we can not use a Token/ETH rate as ETH(native token)
    //price differs on different chains
    uint256 public rate = 0;
    bool public saleIsOnGoing = false;
    IERC20 public ZBIT;
    AggregatorV3Interface public ETHPriceAggregator;

    constructor(address _ZBIT, uint256 initialRate){
        ZBIT = IERC20(_ZBIT);
        rate = initialRate;
        uint256 chainId = getChainID();
        if(chainId == 56){ // BSC mainnet
            ETHPriceAggregator = // BNB / USD
            AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        }else if(chainId ==137){ // Polygon Mainnet
            ETHPriceAggregator = // MATIC / USD
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        }else if(chainId == 1){ //ETH mainnet
            ETHPriceAggregator = //ETH / USD 
            AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        }
    }

    modifier notZero(address target){
        require(target != address(0), "can't use zero address");
        _;
    }

    modifier canTrade(){
        require(saleIsOnGoing == true, "sale is not started yet");
        _;
    }

    //Owner can change ETH pricefeed
    function setETHPriceFeed(address PriceFeed) external notZero(PriceFeed) onlyOwner{
        ETHPriceAggregator = AggregatorV3Interface(PriceFeed);
    }

    //to detect which chain we are using
    function getChainID() public view returns(uint256){
        uint256 id;
        assembly{
            id := chainid()
        }
        return id;
    }

    //ownre can change ZBIT token address
    function setZBITAddress(address _ZBIT) notZero(_ZBIT) external onlyOwner{
        require(_ZBIT != address(ZBIT), "This token is already in use");
        ZBIT = IERC20(_ZBIT);
    }

    //Owner can change ZBIT Rate (enter wei amount)
    function changeZBITRate(uint256 newRate) external onlyOwner{
        rate = newRate;
    }

    //owner must set this to true in order to start ICO
    function setSaleStatus(bool status) external onlyOwner{
        saleIsOnGoing = status;
    }

    function contributeETH() canTrade() public payable{ 
        require(msg.value > 0, "cant contribute 0 eth");
        uint256 toClaim = _ETHToZBIT(msg.value);
        if(ZBIT.balanceOf(address(this)) - toClaim < 0){
            revert("claim amount is bigger than ICO remaining tokens, try a lower value");
        }
        ZBIT.transfer(msg.sender, toClaim);
    }

    function contributeToken(address token, uint256 amount) notZero(token) canTrade() public{
        require(validTokens[token], "This token is not allowed for ICO");
        uint256 toClaim = _TokenToZBIT(token, amount);
        if(ZBIT.balanceOf(address(this)) - toClaim < 0){
            revert("claim amount is bigger than ICO remaining tokens, try a lower value");
        }
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));
        ZBIT.transfer(msg.sender, toClaim);
    }

    //Admin is able to add a costume token here, this tokens are allowed to be contibuted
    //in our ICO

    //aggregator is a contract which gives you latest price of a token
    //not all tokens support aggregators, you can find all aggregator supported tokens
    //in this link https://docs.chain.link/docs/bnb-chain-addresses/
    //Example: we set _token to BTC contract address and aggregator to BTC/USD priceFeed
    function addCostumeTokenByAggregator(address _token, address aggregator)
    notZero(_token) notZero(aggregator) public onlyOwner{
        require(_token != address(this), "ZBIT : cant add native token");
        validTokens[_token] = true;
        //amount of tokens per ETH
        tokensAggregator[_token] = aggregator;
    }

    //in this section owner must set a rate (in wei format) for _token
    //this method is not recommended
    function addCostumTokenByRate(address _token, uint256 _rate)
    notZero(_token) public onlyOwner{
        require(_token != address(this), "ZBIT : cant add native token");
        validTokens[_token] = true;
        validTokensRate[_token] = _rate;
    }

    //give rate of a token
    function getCostumeTokenRate(address _token) public view returns(uint256){
        if(tokensAggregator[_token] == address(0)){
            return validTokensRate[_token];
        }
        address priceFeed = tokensAggregator[_token];
        (,int256 price,,,) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(price) * 10 ** 10; //return price in 18 decimals
    }

    //latest price of ETH (native chain token)
    function getLatestETHPrice() public view returns(uint256){
        (,int256 price,,,) = ETHPriceAggregator.latestRoundData();
        return uint256(price) * 10 ** 10;
    }

    //Converts ETH(in wei) to ZBIT
    function _ETHToZBIT(uint256 eth) public view returns(uint256){
        uint256 ethPrice = getLatestETHPrice();
        uint256 EthToUSD = eth.mul(ethPrice).div(10 ** 18);
        return EthToUSD.mul(rate).div(10 ** 18);
    }

    //converts Tokens(in wei) to ZBIT
    function _TokenToZBIT(address token, uint256 tokensAmount) public view returns(uint256){
        uint256 _rate = validTokensRate[token];
        if(_rate == 0){
            _rate = getCostumeTokenRate(token);
        }
        uint256 TokensAmountUSD = _rate.mul(tokensAmount);
        uint256 ZBITAmount = TokensAmountUSD.mul(10 ** 18).div(rate);
        return ZBITAmount;
    }

    function withdrawETH() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address Token) external onlyOwner{
        IERC20(Token).transfer(msg.sender, IERC20(Token).balanceOf(address(this)));
    }

    //returns balance of contract for a costume token
    function getCostumeTokenBalance(address token) external view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    function getETHBalance() external view returns(uint256){
        return address(this).balance;
    }

    function ZBITBalance() external view returns(uint256){
        return ZBIT.balanceOf(address(this));
    }

    //if wallet sent ethereum to this contract sent him back tokens
    receive() payable external{
        uint256 toClaim = _ETHToZBIT(msg.value);
        if(ZBIT.balanceOf(address(this)) - toClaim < 0){
            revert("claim amount is bigger than ICO remaining tokens, try a lower value");
        }
        ZBIT.transfer(msg.sender, toClaim);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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