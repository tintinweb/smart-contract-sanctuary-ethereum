/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Lens/compoundReadAll.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


interface Compound {
    function getAllMarkets() external view returns (address[] memory);
    function getAssetsIn(address account) external view returns (address[] memory);
    function markets(address _address) external view returns (bool, uint, bool);
    function compSpeeds(address _address) external view returns (uint256);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

interface PToken {
    function underlying() external view returns (address);
    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256,uint256); 
    function totalSupply() external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function getCash() external view returns (uint256);
}

interface UERC20{
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
}


interface Oracle{
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

contract compoundReadAll {
    using SafeMath for uint256;

    struct PoolInfo {
        address pTokenAddress;
        address underlyingAddress;
        string symbol;
        uint256 supplyApy;
        uint256 borrowApy;
        uint256 underlyingAllowance;
        uint256 walletBalance;
        uint256 marketTotalSupply;
        uint256 marketTotalBorrowInTokenUnit;
        uint256 underlyingAmount;
        uint256 underlyingPrice;
        uint256 collateralFactor;
        uint256 pctSpeed;
        uint256 decimals;
        uint256 cTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 supplyAndBorrowBalance;
    }
    
    address private _owner;
    uint256 public MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    address public COMPTROLLER;
    address public ORACLE;
    address public TOKEN;
    string public NAME;


    constructor(
        address _COMPTROLLER,
        address _ORACLE,
        address _TOKEN,
        string memory _NAME
    ) public {
        _owner = msg.sender;
        COMPTROLLER = _COMPTROLLER;
        ORACLE = _ORACLE;
        TOKEN = _TOKEN;
        NAME = _NAME;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function setName(string memory _name) public onlyOwner {
        NAME = _name;
    }

    function setToken(address _token) public onlyOwner {
        TOKEN = _token;
    }

    function setCompTroller(address _address) public onlyOwner {
        COMPTROLLER = _address;
    }

    function setOracle(address _address) public onlyOwner {
        ORACLE = _address;
    }

    function getAllPTokens() public view returns(address[] memory){
        return Compound(COMPTROLLER).getAllMarkets();
    }

    function getUnderlyingTokenAddress(address _pToken) public view returns (address){
        if (_pToken == TOKEN) {
            return address(0);
        }else{
            return PToken(_pToken).underlying();
        }
    }

    function getUnderlyingPrice (address _pToken) public view returns (uint256){
        return Oracle(ORACLE).getUnderlyingPrice(_pToken);
    }

    function getCTokenBalance(address _pToken, address _account) public view returns (uint256 ){
        (,uint256 results,,) = PToken(_pToken).getAccountSnapshot(_account);
        return results;
    }

    function getBorrowBalance(address _pToken, address _account) public view returns (uint256){
        (,,uint256 results,) = PToken(_pToken).getAccountSnapshot(_account);
        return results;
    }

    function getExchangeRateMantissa(address _pToken, address _account) public view returns (uint256){
        (,,,uint256 results) = PToken(_pToken).getAccountSnapshot(_account);
        return results;
    }

    function getMarketTotalSupplyInTokenUnit(address _pToken) public view returns (uint256){
        uint256 cTokenTotalSupply = PToken(_pToken).totalSupply();
        uint256 exchangeRateStored = PToken(_pToken).exchangeRateStored();
        return cTokenTotalSupply.mul(exchangeRateStored);
    }

    function getMarketTotalBorrowInTokenUnit(address _pToken) public view returns (uint256){
        return PToken(_pToken).totalBorrows();
    }

    function getCollateralFactor(address _pToken) public view returns (uint256){
        (,uint256 _data,) = Compound(COMPTROLLER).markets(_pToken);
        return _data;
    }

    function getSupplyApy(address _pToken) public view returns (uint256){
        return PToken(_pToken).supplyRatePerBlock();
    }

    function getBorrowApy(address _pToken) public view returns (uint256) {
        return PToken(_pToken).borrowRatePerBlock();
    }

    function getUnderlyingAmount(address _pToken) public view returns (uint256) {
        return PToken(_pToken).getCash();
    }

    function getPctSpeed(address _pToken) public view returns (uint256) {
        return Compound(COMPTROLLER).compSpeeds(_pToken);
    }

    function getAllowance(address _tokenAddress, address _walletAddress, address _pToken) public view returns (uint256) {
        return _tokenAddress == address(0) ? MAX_INT : IERC20(_tokenAddress).allowance(_walletAddress, _pToken);
    }

    function getSymbol(address _tokenAddress) public view returns (string memory) {
        return _tokenAddress == address(0)? NAME : UERC20(_tokenAddress).symbol();
    }
    
    function getBalanceOf(address _tokenAddress, address _walletAddress) public view returns (uint256) {
        return _tokenAddress == address(0) ? _walletAddress.balance : IERC20(_tokenAddress).balanceOf(_walletAddress);
    }

    function getDecimals(address _tokenAddress) public view returns (uint256) {
        return _tokenAddress == address(0)? 18 : UERC20(_tokenAddress).decimals();
    }

    function getLength() public view returns (uint256){
        address[] memory _PTokens = getAllPTokens();
        return _PTokens.length;
    }

    function getMarketDetail(address _account,address[] calldata _PTokens) external view returns (PoolInfo[] memory){
        //uint256 len = _PTokens.length;
        PoolInfo[] memory results = new PoolInfo[](_PTokens.length);
        for(uint256 i = 0 ; i < _PTokens.length; i++){
            results[i] = getMarketDetailOne(_PTokens[i],_account);
        }
        
        return results;
    }

    function getMarketDetailOne(address _pToken,address _account) public view returns (PoolInfo memory){
     
        PoolInfo memory results = PoolInfo({
            pTokenAddress: _pToken,
            underlyingAddress: getUnderlyingTokenAddress(_pToken),
            symbol: getSymbol(getUnderlyingTokenAddress(_pToken)),
            supplyApy: getSupplyApy(_pToken),
            borrowApy: getBorrowApy(_pToken),
            underlyingAllowance:getAllowance(getUnderlyingTokenAddress(_pToken), _account, _pToken),
            walletBalance: getBalanceOf(getUnderlyingTokenAddress(_pToken), _account),
            marketTotalSupply: getMarketTotalSupplyInTokenUnit(_pToken),
            marketTotalBorrowInTokenUnit: getMarketTotalBorrowInTokenUnit(_pToken),
            underlyingAmount: getUnderlyingAmount(_pToken),
            underlyingPrice: getUnderlyingPrice(_pToken),
            collateralFactor: getCollateralFactor(_pToken),
            pctSpeed: getPctSpeed(_pToken),
            decimals: getDecimals(getUnderlyingTokenAddress(_pToken)),
            cTokenBalance: getCTokenBalance(_pToken,_account),
            borrowBalance: getBorrowBalance(_pToken,_account),
            exchangeRateMantissa: getExchangeRateMantissa(_pToken,_account),
            supplyAndBorrowBalance:0
        });
        return results;
    }

    function getAccountLiquidity(address[] calldata accounts) external view returns(bool[] memory) {
        bool[] memory results = new bool[](accounts.length);
        for(uint256 i = 0 ; i < accounts.length; i++){
            (,,uint shortfall) = Compound(COMPTROLLER).getAccountLiquidity(accounts[i]);
            results[i] = shortfall > 0;
        }
        return results;
    }


}