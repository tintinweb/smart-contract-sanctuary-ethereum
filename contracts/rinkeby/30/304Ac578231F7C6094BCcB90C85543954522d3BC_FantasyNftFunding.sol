pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {


    function decimals() external view returns (uint8);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {//internal
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract FantasyNftFunding {
    using SafeMath for uint256;

    address public owner;
    /// @notice In basis points (default set to 3%)
    uint256 public taxRate = 300;
    /// @notice Address that collects the protocol fees
    address public taxCollector;
    /// @notice Stablecoin that is stored in the smart contract to collateralize the user balances
    address public finalCurrency = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;//Ethereum USDC////0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 - Polygon USDC
    uint public finalCurrencyDecimal=6;
    IUniswapV2Router02 public uniswapV2Router;
    /// @notice Balance available to be used
    mapping (address => uint) public spendingBalance;
    /// @notice Balance locked in existing bets
    mapping (address => uint) public bettingBalances;
    /// @notice Only betting contracts are permitted to modify balances
    mapping (address => bool) public canModifyBalances;

    constructor(address _taxCollector) {
        owner = msg.sender;
        taxCollector=_taxCollector;
        setRouterAddress(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//Uniswap Router on Ethereum
    }

    /// @notice Converts deposited crypto into stablecoins and increases the user's spending balance
    /// @param _amount Amount to deposit
    /// @param _currency Type of Deposit - ETH or ERC-20 tokens
    /// @param _currencyAddress Address of the deposited ERC-20 token
    function processDeposit(uint _amount,string calldata _currency, address _currencyAddress) external payable{
        
        uint stablecoinAmount=_amount;//by default, assumes the deposit is in the final currency
        IERC20 final_token = IERC20(finalCurrency);

        if(keccak256(abi.encodePacked(_currency)) == keccak256(abi.encodePacked("ETH"))){//convert ETH to Stablecoin
            require(msg.value>0, "Not enough ETH");
            uint256 initialBalance = final_token.balanceOf(address(this));

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = finalCurrency;

            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
                0, // accept any amount of stablecoins
                path,
                address(this),
                block.timestamp
            );

            uint256 postConversionBalance = final_token.balanceOf(address(this));
            stablecoinAmount = postConversionBalance.sub(initialBalance);
        }
        else{

            IERC20 this_token = IERC20(_currencyAddress);
            require(this_token.balanceOf(msg.sender) >= _amount, "Not enough token balance");
            this_token.transferFrom(msg.sender, address(this), _amount);
            
            if(_currencyAddress!=finalCurrency){//convert any coin into stablecoin (unless the coin itself is already the stablecoin)
                uint256 initialBalance = final_token.balanceOf(address(this));

                this_token.approve(address(uniswapV2Router), _amount);


                address[] memory path = new address[](3);
                path[0] = _currencyAddress;
                path[1] = uniswapV2Router.WETH();
                path[2] = finalCurrency;

                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amount,
                    0, // accept any amount of stablecoins
                    path,
                    address(this),
                    block.timestamp
                );

                uint256 postConversionBalance = final_token.balanceOf(address(this));
                stablecoinAmount = postConversionBalance.sub(initialBalance);
            }
        }
        spendingBalance[msg.sender] = spendingBalance[msg.sender].add(stablecoinAmount);
    }

    /// @notice Withdraw's the user's funds in the form of stablecoins
    /// @param _amount Amount to withdraw
    function withdrawFunds(uint _amount)external{
        require(spendingBalance[msg.sender]>=_amount, "Not enough to withdraw");
        spendingBalance[msg.sender]=spendingBalance[msg.sender].sub(_amount);
        IERC20(finalCurrency).transfer(msg.sender,_amount);
    }

    /// @notice Tranfers the wager to the winner after a bet has been decided
    /// @param winner The winner's address
    /// @param loser The loser's address
    /// @param _betAmount Amount to transfer
    function transferWagerFromLoserToWinner(
        address winner,
        address loser,
        uint256 _betAmount
    ) public {
        require(
            canModifyBalances[msg.sender] == true,
            "Only Betting Contracts can call"
        );

        bettingBalances[loser] = bettingBalances[loser].sub(_betAmount);
        bettingBalances[winner] = bettingBalances[winner].add(_betAmount);
    }

    /// @notice During a league's resolution, funds are transfered to an "Escrow" state prior to distribution
    /// @param user The user to transfer funds from
    /// @param _betAmount Amount to transfer
    function transferToEscrowPriorToDistribution(
        address user,
        uint256 _betAmount
    ) public {
        require(
            canModifyBalances[msg.sender] == true,
            "Only Betting Contracts can call"
        );

        bettingBalances[user] = bettingBalances[user].sub(_betAmount);
        bettingBalances[address(this)] = bettingBalances[address(this)].add(_betAmount);
    }

    /// @notice Locks or unlocks betting amounts when the user enters/leaves a bet, so that the spending balance can't be wagered more than once
    /// @param user The user address
    /// @param _amount Amount to lock/unlock
    /// @param _type 0 is to unlock after cancelling or draw, 1 is to lock, 2 is to unlock after bet result,
    function lockUnlockSpendingBalance(
        address user,
        uint256 _amount,
        uint256 _type
    ) public {
        require(
            canModifyBalances[msg.sender] == true,
            "Only Betting Contracts can call"
        );
        if (_type == 1) {
            //lock
            spendingBalance[user] = spendingBalance[user].sub(_amount);
            bettingBalances[user] = bettingBalances[user].add(_amount);
        } else if (_type == 0) {
            //cancel
            bettingBalances[user] = bettingBalances[user].sub(_amount);
            spendingBalance[user] = spendingBalance[user].add(_amount);
        } 
        else {
            //post bet  - deduct tax
            uint256 taxAmount = _amount.mul(taxRate).div(10000);
            uint256 winnerAmount = _amount.sub(taxAmount);
            bettingBalances[user] = bettingBalances[user].sub(_amount);
            spendingBalance[user] = spendingBalance[user].add(winnerAmount);
            spendingBalance[taxCollector] = spendingBalance[taxCollector].add(taxAmount);
        }
        
    }

    /// @notice Locks or unlocks league buy-in amounts when the user enters/leaves a league
    /// @param userAddresses array of user addresses; set length of 5 because solidity does not allow the creation of dynamic memory arrays
    /// @param _amount Amount to lock/unlock
    /// @param _type 0 is to unlock, 1 is to lock, 2 is to unlock after league result
    /// @param _payoutType only applicable if _type == 2. 0: Winner take all; 1: Top 3; 2: Top 5
    function lockUnlockSpendingBalanceLeague(
        address[5] memory userAddresses, 
        uint256 _amount,
        uint256 _type,
        uint256 _payoutType
    ) public {
        require(
            canModifyBalances[msg.sender] == true,
            "Only Betting Contracts can call"
        );
        if (_type == 1) {
            //lock
            address user=userAddresses[0];
            spendingBalance[user] = spendingBalance[user].sub(_amount);
            bettingBalances[user] = bettingBalances[user].add(_amount);
        } else if (_type == 0) {
            //cancel
            address user=userAddresses[0];
            bettingBalances[user] = bettingBalances[user].sub(_amount);
            spendingBalance[user] = spendingBalance[user].add(_amount);
        } 
        else {
            require(bettingBalances[address(this)]>=_amount, "Not enough to distribute");
            if(_payoutType==1 || _payoutType==2){
                uint zeroAddressCount;
                for(uint i = 0; i < userAddresses.length; i++){
                    if(userAddresses[i]==address(0)){
                        zeroAddressCount++;
                    }
                }
                if((_payoutType==1 && zeroAddressCount>2) || (_payoutType==2 && zeroAddressCount>0)){
                    _payoutType=0;//default to Winner take all if there are not enough users in the league
                }
            }

            uint256 taxAmount = _amount.mul(taxRate).div(10000);
            uint256 amountToDistribute = _amount.sub(taxAmount);

            bettingBalances[address(this)] = bettingBalances[address(this)].sub(_amount);
            spendingBalance[taxCollector] = spendingBalance[taxCollector].add(taxAmount);

            if(_payoutType==0){
                spendingBalance[userAddresses[0]] = spendingBalance[userAddresses[0]].add(amountToDistribute);
            }
            else if(_payoutType==1){
                spendingBalance[userAddresses[0]] = spendingBalance[userAddresses[0]].add((amountToDistribute.mul(50).div(100)));
                spendingBalance[userAddresses[1]] = spendingBalance[userAddresses[1]].add((amountToDistribute.mul(30).div(100)));
                spendingBalance[userAddresses[2]] = spendingBalance[userAddresses[2]].add((amountToDistribute.mul(20).div(100)));
            }
            else{
                spendingBalance[userAddresses[0]] = spendingBalance[userAddresses[0]].add((amountToDistribute.mul(40).div(100)));
                spendingBalance[userAddresses[1]] = spendingBalance[userAddresses[1]].add((amountToDistribute.mul(25).div(100)));
                spendingBalance[userAddresses[2]] = spendingBalance[userAddresses[2]].add((amountToDistribute.mul(20).div(100)));
                spendingBalance[userAddresses[3]] = spendingBalance[userAddresses[3]].add((amountToDistribute.mul(10).div(100)));
                spendingBalance[userAddresses[4]] = spendingBalance[userAddresses[4]].add((amountToDistribute.mul(5).div(100)));
            }
            
        }
        
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Utilities Functions

    /// @notice Fetches the locked betting balance of the user
    function getBettingBalance(address _user) public view returns(uint){
        return bettingBalances[_user];
    }

    /// @notice Fetches the spending balance of the user
    function getSpendingBalance(address _user) public view returns(uint){
        return spendingBalance[_user];
    }

    /// @notice Updates protocol tax rate
    function setTaxRate(uint256 newTaxRate) external {
        if (msg.sender != owner) {
            return;
        }
        taxRate = newTaxRate;
        return;
    }

    /// @notice Updates the address that collects the protocol fees
    function setTaxCollector(address _newTaxCollector) public{
        if(msg.sender!=owner){
            return;
        }
        taxCollector = _newTaxCollector;
    }

    /// @notice Updates the Router that is used to make token swaps (Uniswap V2 clone)
    /// @param _newRouter Address of new Dex router
    function setRouterAddress(address _newRouter) public{
        if(msg.sender!=owner){
            return;
        }
        IUniswapV2Router02 newRouter = IUniswapV2Router02(_newRouter);
        uniswapV2Router = newRouter;
    }

    /// @notice Sets which contracts are allowed to alter user balances
    /// @param _bettingContract Address of the betting contract
    function setCanModifyBalances(address _bettingContract, bool trueOrFalse) public{
        if(msg.sender!=owner){
            return;
        }
        canModifyBalances[_bettingContract]=trueOrFalse;
    }
}