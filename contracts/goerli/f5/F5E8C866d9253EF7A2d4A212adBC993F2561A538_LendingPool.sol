// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/ISwapRouter.sol';
import './Math.sol';

interface ERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
    function mint(address to, uint256 value) external ;
   
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LendingPool is Ownable {
    using SafeMath for uint256;
     AggregatorV3Interface public priceCollateral;
     AggregatorV3Interface public priceLoan;

    // AggregatorV3Interface internal constant priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    ISwapRouter public constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    
    mapping(address => uint256) public lendingPoolTokenList;
    mapping(address => uint256) public lendersList;
    mapping(address => uint256) public borrowwerList;
    uint256                     public lendingId=0;
    uint256                     public borrowerId=0;
    uint                        public borrowPercentage;

    
    //===========================================================================
    struct lendingMember {
        address lenderAddress; // address of the user that lended
        string token; //eth,Matic ,bnb
        uint256 tokenAmount; //1
        uint256 SuppliedAmount; //1
        uint256 startDay; // time when he lended
        uint256 endDay; // when lending period ends
        bool isRedeem; // if true is means he has something in pool if false it means he/she redeem
    }
    // if we have struct as above we can also map it like this
    // mapping(address => lendingMember) public mapLenderInfo;

    // mapping(address => mapping(string => lendingMember)) public mapLenderInfo;
    mapping(uint256 => lendingMember) public mapLenderInfo; // lending id goes to struct
    mapping(address => mapping(string => uint256[])) public lenderIds;
    mapping(address => mapping(string => uint256)) public lenderShares;
    //===========================================================================
    struct borrowMember {
        address borrowerAddress; 
        string collateralToken; 
        uint256 tokenAmount; 
        uint256 borrowDay; 
        uint256 endDay; 
        bool hasRepaid;
    }
    mapping(uint256 => borrowMember) public mapBorrowerInfo; 
    mapping(address => mapping(string => uint256[])) public borrowerIds;
    mapping(address => mapping(string => uint256)) public borrowerShares;


    constructor() {
    }

    function lend(
        string memory _tokenSymbol,
        uint256 _amount,
        uint256 _days,
        address _token,
        address _ftoken
    ) public payable {
        require(msg.value <= 0, 'Can not send 0 amount');

        // mapLenderInfo[msg.sender][_tokenSymbol].lenderAddress = msg.sender;
        // mapLenderInfo[msg.sender][_tokenSymbol].token = _tokenSymbol;
        // mapLenderInfo[msg.sender][_tokenSymbol].tokenAmount = _amount;
        // mapLenderInfo[msg.sender][_tokenSymbol].startDay = block.timestamp;
        // mapLenderInfo[msg.sender][_tokenSymbol].endDay = block.timestamp + _days * 1 days;
        // mapLenderInfo[msg.sender][_tokenSymbol].isRedeem = false;
        lendingId += 1;
        lenderIds[msg.sender][_tokenSymbol].push(lendingId);
        lenderShares[msg.sender][_tokenSymbol] += _amount;

        mapLenderInfo[lendingId].lenderAddress = msg.sender;
        mapLenderInfo[lendingId].token = _tokenSymbol;
        mapLenderInfo[lendingId].SuppliedAmount = _amount;
        mapLenderInfo[lendingId].tokenAmount = _amount;
        mapLenderInfo[lendingId].startDay = block.timestamp;
        mapLenderInfo[lendingId].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[lendingId].isRedeem = false;
        ERC20(_token).transferFrom(msg.sender,address(this), _amount);
        ERC20(_ftoken).mint(msg.sender,_amount);

    }

    // function isLenderExist (address _address) public view return (bool){
    //   return true   
    // }
    function getLenderId ( string memory _tokenSymbol) public view returns (uint [] memory){
        return lenderIds[msg.sender][_tokenSymbol];
    }
    function getLenderAsset (uint _id) public view returns (lendingMember memory){
        return mapLenderInfo[_id];
    }
     function getLenderShare ( string memory _tokenSymbol) public view returns (uint){
        return lenderShares[msg.sender][_tokenSymbol];
    }

    // function lendedAssetDetails(string memory _tokenSymbol) public view returns () {
    //     // return mapLenderInfo[msg.sender][_tokenSymbol][1];
    //     return mapLenderInfo[msg.sender][_tokenSymbol][50];
    // }

    

    


    function redeem(
        string memory _tokenSymbol,
        uint256 _amount,
        address _token,
        uint _lendeingId
    ) external payable {
        // require(block.timestamp >= mapLenderInfo[_lendeingId].endDay, "Can not redeem before end day");
        require(keccak256(abi.encodePacked(mapLenderInfo[_lendeingId].token)) == keccak256(abi.encodePacked(_tokenSymbol)),'Use correct token');
        mapLenderInfo[_lendeingId].isRedeem = true;
        mapLenderInfo[_lendeingId].tokenAmount -= _amount;
        lenderShares[msg.sender][_tokenSymbol] -= _amount;

        ERC20(_token).transfer(msg.sender, _amount);
    }

      function borrow( 
        string memory _collateralTokenSymbol, 
        uint256 _collateralAmount, 
        address _collateralToken, 
        address _loanToken, 
        address loanAggregator,
        address collateralAggregator
        
        ) external payable {
        // require(block.timestamp >= mapLenderInfo[_borrowerId].endDay, "Can not redeem before end day");
        // require(keccak256(abi.encodePacked(mapLenderInfo[_borrowerId].token)) == keccak256(abi.encodePacked(_tokenSymbol)),'Use correct token');
        // IERC20 tokenObj = IERC20(_token);
        uint _borrowerId = borrowerId++;
        borrowerIds[msg.sender][_collateralTokenSymbol].push(lendingId);
        uint alloweAmount =  getLoanAmount(loanAggregator,collateralAggregator,_collateralAmount);
        mapBorrowerInfo[_borrowerId].borrowerAddress = msg.sender;
        mapBorrowerInfo[_borrowerId].collateralToken = _collateralTokenSymbol;
        mapBorrowerInfo[_borrowerId].tokenAmount += _collateralAmount;
        mapBorrowerInfo[_borrowerId].borrowDay = block.timestamp;
        mapBorrowerInfo[_borrowerId].hasRepaid = false;
        borrowerShares[msg.sender][_collateralTokenSymbol] += _collateralAmount;
        ERC20(_collateralToken).transferFrom(msg.sender, address(this), _collateralAmount); 
        ERC20(_loanToken).transfer(msg.sender, alloweAmount);
    }

    function poolTokensBal(address _address) public view returns (uint256) {
        return ERC20(_address).balanceOf(address(this));
    }

    function setPercentage(uint _percentage) external {
        borrowPercentage = _percentage;
    }
    function checkPercentage(uint _amount) public view returns(uint){
        // uint per = (_amount * borrowPercentage) /10000;
       return _amount.mul(borrowPercentage).div(1e18);
    }


     function getBorrowerId ( string memory _collateralTokenSymbol) public view returns (uint [] memory){
        return borrowerIds[msg.sender][_collateralTokenSymbol];
    }
    function getBorrowerDetails (uint _id) public view returns (borrowMember memory){
        return mapBorrowerInfo[_id];
    }
    
     function getBorrowerShare ( string memory _collateralTokenSymbol) public view returns (uint){
        return borrowerShares[msg.sender][_collateralTokenSymbol];
    }

    function getLoanAmount(address loanTokenAggregator, address collateralTokenAggregator,uint collateralAmount) public returns (uint)
    {    
        // convert collateral to desired exchange
         priceCollateral = AggregatorV3Interface(collateralTokenAggregator);
         (,int price,,,)=priceCollateral.latestRoundData();
        // calculate 70% of collateral to get loan amount
       uint conversionAmount= checkPercentage(collateralAmount.mul(uint(price)));

        // convert loan to desired exchange
        priceLoan = AggregatorV3Interface(loanTokenAggregator);
        (
            /*uint80 roundID*/,
            int loanPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceLoan.latestRoundData();

        uint returnLoanPrice=uint(conversionAmount).div(uint(loanPrice));

        return returnLoanPrice;
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;
pragma abicoder v2;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Math {
    using SafeMath for uint256;

    uint256 private constant EXP_SCALE = 1e18;
    uint256 private constant HALF_EXP_SCALE = EXP_SCALE / 2;

    function getExp(uint256 num, uint256 denom) internal pure returns (uint256) {
        (bool successMul, uint256 scaledNumber) = num.tryMul(EXP_SCALE);
        if (!successMul) return 0;
        (bool successDiv, uint256 rational) = scaledNumber.tryDiv(denom);
        if (!successDiv) return 0;
        return rational;
    }

    function mulExp(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool successMul, uint256 doubleScaledProduct) = a.tryMul(b);
        if (!successMul) return 0;
        (
            bool successAdd,
            uint256 doubleScaledProductWithHalfScale
        ) = HALF_EXP_SCALE.tryAdd(doubleScaledProduct);
        if (!successAdd) return 0;
        (bool successDiv, uint256 product) = doubleScaledProductWithHalfScale
            .tryDiv(EXP_SCALE);
        assert(successDiv == true);
        return product;
    }

    function percentage(uint256 _num, uint256 _percentage) internal pure returns (uint256) {
        uint256 rational = getExp(_num, 5);
        return mulExp(rational, _percentage);
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