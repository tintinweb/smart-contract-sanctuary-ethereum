pragma solidity ^0.8.0;

// imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// interfaces
import "../interfaces/IStargateRouter.sol";
import "../interfaces/IStargateLpStaking.sol";
import "../interfaces/IDex.sol";

import "../libraries/stargate/Pool.sol";
import "../libraries/stargate/LPStaking.sol";
import "../libraries/stargate/Router.sol";

import "hardhat/console.sol";

contract OrderTaker is Ownable {
    using SafeMath for uint256;

    modifier onlyVault() {
        require(vault == msg.sender, "onlyVault: caller is not vault");
        _;
    }

    // data types
    enum OrderType {
        Stake,
        Unstake,
        Swap,
        SwapRemote,
        Sell
    }
    

    /// @title: Order Parameters for Each Type:
    /// - Stake (amountCoin, poolIndex)
    /// - Unstake: (amountLP, poolIndex)
    /// - Swap (amountSrc, srcPoolIndex, dstPoolIndex)
    /// - Swap Remote(amountSrc, srcPoolIndex, dstChainId, dstPoolIndex)
    /// - Sell(amountSTG, StgPoolIndex)
    /// @note: every pool index is the index in Stargate Factory
    struct Order {
        OrderType orderType;
        uint256 amount;
        uint256 arg1;
        uint256 arg2;
        uint256 arg3;
    }

    uint16 public chainId; // LayerZero defined chain ID;
    address public stargateRouter; // Stargate Router Address. Used for DEX operations.
    address public stargateLpStaking; // Stargate Farming Pool Address.
    address public stargateToken; // Stargate Token Address.
    address public vault;

    constructor(
        uint16 _chainId,
        address _stargateRouter,
        address _stargateLpStaking,
        address _stargateToken
    ) {
        chainId = _chainId;
        stargateRouter = _stargateRouter;
        stargateLpStaking = _stargateLpStaking;
        stargateToken = _stargateToken;
    }

    function getStargatePriceMil() public virtual view returns (uint256) {
        return 0;
    }
    function executeOrders(Order[] memory orders) public onlyOwner{
        for (uint i = 0; i < orders.length; i++ ) {
            {
                Order memory order = orders[i];
                if (order.orderType == OrderType.Stake) {
                    _stake(order.amount, order.arg1);
                }
                else if (order.orderType == OrderType.Unstake) {
                    _unstake(order.amount, order.arg1);
                }
                // else if (order.orderType == OrderType.Sell) {
                //     _sell(order.amount, order.arg1);
                // }
                else if (order.orderType == OrderType.Swap) {
                    _swap(order.amount, order.arg1, order.arg2);
                }
                else if (order.orderType == OrderType.SwapRemote) {
                    _swapRemote(order.amount, order.arg1, order.arg2, order.arg3);
                }
            }
        }
    }
    
    function _stake(uint256 _amountLD, uint256 _poolId ) private {
        require (_amountLD > 0, "Cannot stake zero amount");
        Pool pool = getPool(_poolId);
        // Approve coin transfer from OrderTaker to STG.Pool
        IERC20 coinContract = IERC20(pool.token());
        coinContract.approve(stargateRouter, _amountLD);
        // Stake coin from OrderTaker to STG.Pool
        uint256 balancePre = pool.balanceOf(address(this));
        Router(stargateRouter).addLiquidity(_poolId, _amountLD, address(this));
        uint256 balanceAfter = pool.balanceOf(address(this));
        uint256 amountLPToken = balanceAfter - balancePre;
        // Find the Liquidity Pool's index in the Farming Pool.
        (bool found, uint256 stkPoolIndex) = getPoolIndexInFarming(_poolId);
        require(found, "The LP token not acceptable.");
        // Approve LPToken transfer from OrderTaker to LPStaking
        pool.approve(stargateLpStaking, amountLPToken);
        // Stake LPToken from OrderTaker to LPStaking
        LPStaking(stargateLpStaking).deposit(stkPoolIndex, amountLPToken);
    }
    function _unstake(uint256 _amountLPToken, uint256 _poolId) private {
        console.log("OrderTaker._unstake started: _amountLPToken, _poolId", _amountLPToken, _poolId);
        require (_amountLPToken > 0, "Cannot unstake zero amount");
        Pool pool = getPool(_poolId);
        // Find the Liquidity Pool's index in the Farming Pool.
        (bool found, uint256 stkPoolIndex) = getPoolIndexInFarming(_poolId);
        require(found, "The LP token not acceptable.");

        // Unstake LPToken from LPStaking to OrderTaker
        console.log("   LPTokens in LPStaking before withdraw", LPStaking(stargateLpStaking).lpBalances(stkPoolIndex));
        LPStaking(stargateLpStaking).withdraw(stkPoolIndex, _amountLPToken);
        console.log("   LPTokens in LPStaking after withdraw", LPStaking(stargateLpStaking).lpBalances(stkPoolIndex));
        
        // Unstake coin from STG.Pool to OrderTaker
        Router(stargateRouter).instantRedeemLocal(uint16(_poolId), _amountLPToken, address(this));
        
        IERC20 coinContract = IERC20(pool.token());
        uint256 userToken = coinContract.balanceOf(address(this));
        console.log("   USDC in OrderTaker", userToken);
        console.log("OrderTaker._unstake ended");
    }

    // function _sell(uint256 _amount, uint256 _poolId) internal virtual {
        
    // }

    function _swap(uint256 _amount, uint256 _srcPoolId, uint256 _dstPoolId) internal virtual {
    }

    function _swapRemote(uint256 _amountLD, uint256 _srcPoolId, uint256 _dstChainId, uint256 _dstPoolId) internal virtual {
        require (_amountLD > 0, "Cannot stake zero amount");
        Pool pool = getPool(_srcPoolId);
        // Approve coin transfer from OrderTaker to STG.Pool
        IERC20 coinContract = IERC20(pool.token());
        coinContract.approve(stargateRouter, _amountLD);
        Router(stargateRouter).swap(uint16(_dstChainId), _srcPoolId, _dstPoolId, payable(msg.sender), _amountLD, 0, IStargateRouter.lzTxObj(0, 0, "0x"), abi.encodePacked(msg.sender), bytes(""));
    }
    
    function getPool(uint256 _poolId) public view returns (Pool) {
        return Router(stargateRouter).factory().getPool(_poolId);
    }

    function getPoolIndexInFarming(uint256 _poolId)public view returns (bool, uint256) {
        Pool pool = getPool(_poolId);
        
        for (uint i = 0; i < LPStaking(stargateLpStaking).poolLength(); i++ ) {
            if (address(LPStaking(stargateLpStaking).getPoolInfo(i)) == address(pool)) {
                return (true, i);
            }
        }
        // not found
        return (false, 0);
    }

    function giveStablecoin(address _user, address _token, uint256 _amountLD) public onlyVault {
        IERC20(_token).transfer(_user, _amountLD);
    }

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
    // function _swapUsingDex(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) internal {
      
    //     //first we need to transfer the amount in tokens from the msg.sender to this contract
    //     //this contract will have the amount of in tokens
    //     IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
    //     //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //     //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    //     IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

    //     //path is an array of addresses.
    //     //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //     //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    //     address[] memory path;
    //     if (_tokenIn == WETH || _tokenOut == WETH) {
    //         path = new address[](2);
    //         path[0] = _tokenIn;
    //         path[1] = _tokenOut;
    //     } else {
    //         path = new address[](3);
    //         path[0] = _tokenIn;
    //         path[1] = WETH;
    //         path[2] = _tokenOut;
    //     }
    //     //then we will call swapExactTokensForTokens
    //     //for the deadline we will pass in block.timestamp
    //     //the deadline is the latest time the trade is valid for
    //     IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    // }

    // //this function will return the minimum amount from a swap
    // //input the 3 parameters below and it will return the minimum amount out
    // //this is needed for the swap function above
    //  function _getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) internal view returns (uint256) {

    //    //path is an array of addresses.
    //    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    //     address[] memory path;
    //     if (_tokenIn == WETH || _tokenOut == WETH) {
    //         path = new address[](2);
    //         path[0] = _tokenIn;
    //         path[1] = _tokenOut;
    //     } else {
    //         path = new address[](3);
    //         path[0] = _tokenIn;
    //         path[1] = WETH;
    //         path[2] = _tokenOut;
    //     }
        
    //     uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
    //     return amountOutMins[path.length -1];  
    // }  

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStargateLpStaking {

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IDex {


    function stgToStablecoin(uint256 stgAmount) external;

    
    function getStablecoinAmount() external view returns(uint256);

    function getStgAmount() external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

// imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./LPTokenERC20.sol";
import "../../interfaces/IStargateFeeLibrary.sol";

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

/// Pool contracts on other chains and managed by the Stargate protocol.
contract Pool is LPTokenERC20, ReentrancyGuard {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // CONSTANTS
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint256 public constant BP_DENOMINATOR = 10000;

    //---------------------------------------------------------------------------
    // STRUCTS
    struct ChainPath {
        bool ready; // indicate if the counter chainPath has been created.
        uint16 dstChainId;
        uint256 dstPoolId;
        uint256 weight;
        uint256 balance;
        uint256 lkb;
        uint256 credits;
        uint256 idealBalance;
    }

    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    struct CreditObj {
        uint256 credits;
        uint256 idealBalance;
    }

    //---------------------------------------------------------------------------
    // VARIABLES

    // chainPath
    ChainPath[] public chainPaths; // list of connected chains with shared pools
    mapping(uint16 => mapping(uint256 => uint256)) public chainPathIndexLookup; // lookup for chainPath by chainId => poolId =>index

    // metadata
    uint256 public immutable poolId; // shared id between chains to represent same pool
    uint256 public sharedDecimals; // the shared decimals (lowest common decimals between chains)
    uint256 public localDecimals; // the decimals for the token
    uint256 public immutable convertRate; // the decimals for the token
    address public immutable token; // the token for the pool
    address public immutable router; // the token for the pool

    bool public stopSwap; // flag to stop swapping in extreme cases

    // Fee and Liquidity
    uint256 public totalLiquidity; // the total amount of tokens added on this side of the chain (fees + deposits - withdrawals)
    uint256 public totalWeight; // total weight for pool percentages
    uint256 public mintFeeBP; // fee basis points for the mint/deposit
    uint256 public protocolFeeBalance; // fee balance created from dao fee
    uint256 public mintFeeBalance; // fee balance created from mint fee
    uint256 public eqFeePool; // pool rewards in Shared Decimal format. indicate the total budget for reverse swap incentive
    address public feeLibrary; // address for retrieving fee params for swaps

    // Delta related
    uint256 public deltaCredit; // credits accumulated from txn
    bool public batched; // flag to indicate if we want batch processing.
    bool public defaultSwapMode; // flag for the default mode for swap
    bool public defaultLPMode; // flag for the default mode for lp
    uint256 public swapDeltaBP; // basis points of poolCredits to activate Delta in swap
    uint256 public lpDeltaBP; // basis points of poolCredits to activate Delta in liquidity events

    //---------------------------------------------------------------------------
    // EVENTS
    event Mint(address to, uint256 amountLP, uint256 amountSD, uint256 mintFeeAmountSD);
    event Burn(address from, uint256 amountLP, uint256 amountSD);
    event RedeemLocalCallback(address _to, uint256 _amountSD, uint256 _amountToMintSD);
    event Swap(
        uint16 chainId,
        uint256 dstPoolId,
        address from,
        uint256 amountSD,
        uint256 eqReward,
        uint256 eqFee,
        uint256 protocolFee,
        uint256 lpFee
    );
    event SendCredits(uint16 dstChainId, uint256 dstPoolId, uint256 credits, uint256 idealBalance);
    event RedeemRemote(uint16 chainId, uint256 dstPoolId, address from, uint256 amountLP, uint256 amountSD);
    event RedeemLocal(address from, uint256 amountLP, uint256 amountSD, uint16 chainId, uint256 dstPoolId, bytes to);
    event InstantRedeemLocal(address from, uint256 amountLP, uint256 amountSD, address to);
    event CreditChainPath(uint16 chainId, uint256 srcPoolId, uint256 amountSD, uint256 idealBalance);
    event SwapRemote(address to, uint256 amountSD, uint256 protocolFee, uint256 dstFee);
    event WithdrawRemote(uint16 srcChainId, uint256 srcPoolId, uint256 swapAmount, uint256 mintAmount);
    event ChainPathUpdate(uint16 dstChainId, uint256 dstPoolId, uint256 weight);
    event FeesUpdated(uint256 mintFeeBP);
    event FeeLibraryUpdated(address feeLibraryAddr);
    event StopSwapUpdated(bool swapStop);
    event WithdrawProtocolFeeBalance(address to, uint256 amountSD);
    event WithdrawMintFeeBalance(address to, uint256 amountSD);
    event DeltaParamUpdated(bool batched, uint256 swapDeltaBP, uint256 lpDeltaBP, bool defaultSwapMode, bool defaultLPMode);

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyRouter() {
        require(msg.sender == router, "Stargate: only the router can call this method");
        _;
    }

    constructor(
        uint256 _poolId,
        address _router,
        address _token,
        uint256 _sharedDecimals,
        uint256 _localDecimals,
        address _feeLibrary,
        string memory _name,
        string memory _symbol
    ) LPTokenERC20(_name, _symbol) {
        require(_token != address(0x0), "Stargate: _token cannot be 0x0");
        require(_router != address(0x0), "Stargate: _router cannot be 0x0");
        poolId = _poolId;
        router = _router;
        token = _token;
        sharedDecimals = _sharedDecimals;
        decimals = uint8(_sharedDecimals);
        localDecimals = _localDecimals;
        convertRate = 10**(uint256(localDecimals).sub(sharedDecimals));
        totalWeight = 0;
        feeLibrary = _feeLibrary;

        //delta algo related
        batched = false;
        defaultSwapMode = true;
        defaultLPMode = true;
    }

    function getChainPathsLength() public view returns (uint256) {
        return chainPaths.length;
    }

    //---------------------------------------------------------------------------
    // LOCAL CHAIN FUNCTIONS

    function mint(address _to, uint256 _amountLD) external nonReentrant onlyRouter returns (uint256) {
        return _mintLocal(_to, _amountLD, true, true);
    }

    // Local                                    Remote
    // -------                                  ---------
    // swap             ->                      swapRemote
    function swap(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        bool newLiquidity
    ) external nonReentrant onlyRouter returns (SwapObj memory) {
        require(!stopSwap, "Stargate: swap func stopped");
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        require(cp.ready == true, "Stargate: counter chainPath is not ready");

        uint256 amountSD = amountLDtoSD(_amountLD);
        uint256 minAmountSD = amountLDtoSD(_minAmountLD);

        // request fee params from library
        SwapObj memory s = IStargateFeeLibrary(feeLibrary).getFees(poolId, _dstPoolId, _dstChainId, _from, amountSD);

        // equilibrium fee and reward. note eqFee/eqReward are separated from swap liquidity
        eqFeePool = eqFeePool.sub(s.eqReward);
        // update the new amount the user gets minus the fees
        s.amount = amountSD.sub(s.eqFee).sub(s.protocolFee).sub(s.lpFee);
        // users will also get the eqReward
        require(s.amount.add(s.eqReward) >= minAmountSD, "Stargate: slippage too high");

        // behaviours
        //     - protocolFee: booked, stayed and withdrawn at remote.
        //     - eqFee: booked, stayed and withdrawn at remote.
        //     - lpFee: booked and stayed at remote, can be withdrawn anywhere

        s.lkbRemove = amountSD.sub(s.lpFee).add(s.eqReward);
        // check for transfer solvency.
        require(cp.balance >= s.lkbRemove, "Stargate: dst balance too low");
        cp.balance = cp.balance.sub(s.lkbRemove);

        if (newLiquidity) {
            deltaCredit = deltaCredit.add(amountSD).add(s.eqReward);
        } else if (s.eqReward > 0) {
            deltaCredit = deltaCredit.add(s.eqReward);
        }

        // distribute credits on condition.
        if (!batched || deltaCredit >= totalLiquidity.mul(swapDeltaBP).div(BP_DENOMINATOR)) {
            _delta(defaultSwapMode);
        }

        emit Swap(_dstChainId, _dstPoolId, _from, s.amount, s.eqReward, s.eqFee, s.protocolFee, s.lpFee);
        return s;
    }

    // Local                                    Remote
    // -------                                  ---------
    // sendCredits      ->                      creditChainPath
    function sendCredits(uint16 _dstChainId, uint256 _dstPoolId) external nonReentrant onlyRouter returns (CreditObj memory c) {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        require(cp.ready == true, "Stargate: counter chainPath is not ready");
        cp.lkb = cp.lkb.add(cp.credits);
        c.idealBalance = totalLiquidity.mul(cp.weight).div(totalWeight);
        c.credits = cp.credits;
        cp.credits = 0;
        emit SendCredits(_dstChainId, _dstPoolId, c.credits, c.idealBalance);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemRemote   ->                        swapRemote
    function redeemRemote(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        address _from,
        uint256 _amountLP
    ) external nonReentrant onlyRouter {
        require(_from != address(0x0), "Stargate: _from cannot be 0x0");
        uint256 amountSD = _burnLocal(_from, _amountLP);
        //run Delta
        if (!batched || deltaCredit > totalLiquidity.mul(lpDeltaBP).div(BP_DENOMINATOR)) {
            _delta(defaultLPMode);
        }
        uint256 amountLD = amountSDtoLD(amountSD);
        emit RedeemRemote(_dstChainId, _dstPoolId, _from, _amountLP, amountLD);
    }

    function instantRedeemLocal(
        address _from,
        uint256 _amountLP,
        address _to
    ) external nonReentrant onlyRouter returns (uint256 amountSD) {
        console.log("Pool.instantRedeemLocal started: _from, _amountLP, _to:", _from, _amountLP, _to);
        require(_from != address(0x0), "Stargate: _from cannot be 0x0");
        uint256 _deltaCredit = deltaCredit; // sload optimization.
        uint256 _capAmountLP = _amountSDtoLP(_deltaCredit);

        if (_amountLP > _capAmountLP) _amountLP = _capAmountLP;
        console.log("Pool.instantRedeemLocal: _deltaCredit, _amountLP, _capAmountLP:", _deltaCredit, _amountLP, _capAmountLP);
        console.log("Pool.instantRedeemLocal: totalSupply, totalLiquidity:", totalSupply, totalLiquidity);

        amountSD = _burnLocal(_from, _amountLP);
        deltaCredit = _deltaCredit.sub(amountSD);
        uint256 amountLD = amountSDtoLD(amountSD);
        _safeTransfer(token, _to, amountLD);
        emit InstantRedeemLocal(_from, _amountLP, amountSD, _to);
        console.log("Pool.instantRedeemLocal ended");
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemLocal   ->                         redeemLocalCheckOnRemote
    // redeemLocalCallback             <-
    function redeemLocal(
        address _from,
        uint256 _amountLP,
        uint16 _dstChainId,
        uint256 _dstPoolId,
        bytes calldata _to
    ) external nonReentrant onlyRouter returns (uint256 amountSD) {
        require(_from != address(0x0), "Stargate: _from cannot be 0x0");

        // safeguard.
        require(chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]].ready == true, "Stargate: counter chainPath is not ready");
        amountSD = _burnLocal(_from, _amountLP);

        // run Delta
        if (!batched || deltaCredit > totalLiquidity.mul(lpDeltaBP).div(BP_DENOMINATOR)) {
            _delta(false);
        }
        emit RedeemLocal(_from, _amountLP, amountSD, _dstChainId, _dstPoolId, _to);
    }

    //---------------------------------------------------------------------------
    // REMOTE CHAIN FUNCTIONS

    // Local                                    Remote
    // -------                                  ---------
    // sendCredits      ->                      creditChainPath
    function creditChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        CreditObj memory _c
    ) external nonReentrant onlyRouter {
        ChainPath storage cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]];
        cp.balance = cp.balance.add(_c.credits);
        if (cp.idealBalance != _c.idealBalance) {
            cp.idealBalance = _c.idealBalance;
        }
        emit CreditChainPath(_dstChainId, _dstPoolId, _c.credits, _c.idealBalance);
    }

    // Local                                    Remote
    // -------                                  ---------
    // swap             ->                      swapRemote
    function swapRemote(
        uint16 _srcChainId,
        uint256 _srcPoolId,
        address _to,
        SwapObj memory _s
    ) external nonReentrant onlyRouter returns (uint256 amountLD) {
        // booking lpFee
        totalLiquidity = totalLiquidity.add(_s.lpFee);
        // booking eqFee
        eqFeePool = eqFeePool.add(_s.eqFee);
        // booking stargateFee
        protocolFeeBalance = protocolFeeBalance.add(_s.protocolFee);

        // update LKB
        uint256 chainPathIndex = chainPathIndexLookup[_srcChainId][_srcPoolId];
        chainPaths[chainPathIndex].lkb = chainPaths[chainPathIndex].lkb.sub(_s.lkbRemove);

        // user receives the amount + the srcReward
        amountLD = amountSDtoLD(_s.amount.add(_s.eqReward));
        _safeTransfer(token, _to, amountLD);
        emit SwapRemote(_to, _s.amount.add(_s.eqReward), _s.protocolFee, _s.eqFee);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemLocal   ->                         redeemLocalCheckOnRemote
    // redeemLocalCallback             <-
    function redeemLocalCallback(
        uint16 _srcChainId,
        uint256 _srcPoolId,
        address _to,
        uint256 _amountSD,
        uint256 _amountToMintSD
    ) external nonReentrant onlyRouter {
        if (_amountToMintSD > 0) {
            _mintLocal(_to, amountSDtoLD(_amountToMintSD), false, false);
        }

        ChainPath storage cp = getAndCheckCP(_srcChainId, _srcPoolId);
        cp.lkb = cp.lkb.sub(_amountSD);

        uint256 amountLD = amountSDtoLD(_amountSD);
        _safeTransfer(token, _to, amountLD);
        emit RedeemLocalCallback(_to, _amountSD, _amountToMintSD);
    }

    // Local                                    Remote
    // -------                                  ---------
    // redeemLocal(amount)   ->               redeemLocalCheckOnRemote
    // redeemLocalCallback             <-
    function redeemLocalCheckOnRemote(
        uint16 _srcChainId,
        uint256 _srcPoolId,
        uint256 _amountSD
    ) external nonReentrant onlyRouter returns (uint256 swapAmount, uint256 mintAmount) {
        ChainPath storage cp = getAndCheckCP(_srcChainId, _srcPoolId);
        if (_amountSD > cp.balance) {
            mintAmount = _amountSD - cp.balance;
            swapAmount = cp.balance;
            cp.balance = 0;
        } else {
            cp.balance = cp.balance.sub(_amountSD);
            swapAmount = _amountSD;
            mintAmount = 0;
        }
        emit WithdrawRemote(_srcChainId, _srcPoolId, swapAmount, mintAmount);
    }

    //---------------------------------------------------------------------------
    // DAO Calls
    function createChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _weight
    ) external onlyRouter {
        for (uint256 i = 0; i < chainPaths.length; ++i) {
            ChainPath memory cp = chainPaths[i];
            bool exists = cp.dstChainId == _dstChainId && cp.dstPoolId == _dstPoolId;
            require(!exists, "Stargate: cant createChainPath of existing dstChainId and _dstPoolId");
        }
        totalWeight = totalWeight.add(_weight);
        chainPathIndexLookup[_dstChainId][_dstPoolId] = chainPaths.length;
        chainPaths.push(ChainPath(false, _dstChainId, _dstPoolId, _weight, 0, 0, 0, 0));
        emit ChainPathUpdate(_dstChainId, _dstPoolId, _weight);
    }

    function setWeightForChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint16 _weight
    ) external onlyRouter {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        totalWeight = totalWeight.sub(cp.weight).add(_weight);
        cp.weight = _weight;
        emit ChainPathUpdate(_dstChainId, _dstPoolId, _weight);
    }

    function setFee(uint256 _mintFeeBP) external onlyRouter {
        require(_mintFeeBP <= BP_DENOMINATOR, "Bridge: cum fees > 100%");
        mintFeeBP = _mintFeeBP;
        emit FeesUpdated(mintFeeBP);
    }

    function setFeeLibrary(address _feeLibraryAddr) external onlyRouter {
        require(_feeLibraryAddr != address(0x0), "Stargate: fee library cant be 0x0");
        feeLibrary = _feeLibraryAddr;
        emit FeeLibraryUpdated(_feeLibraryAddr);
    }

    function setSwapStop(bool _swapStop) external onlyRouter {
        stopSwap = _swapStop;
        emit StopSwapUpdated(_swapStop);
    }

    function setDeltaParam(
        bool _batched,
        uint256 _swapDeltaBP,
        uint256 _lpDeltaBP,
        bool _defaultSwapMode,
        bool _defaultLPMode
    ) external onlyRouter {
        require(_swapDeltaBP <= BP_DENOMINATOR && _lpDeltaBP <= BP_DENOMINATOR, "Stargate: wrong Delta param");
        batched = _batched;
        swapDeltaBP = _swapDeltaBP;
        lpDeltaBP = _lpDeltaBP;
        console.log("Pool.setDeltaParam: lpDeltaBP:", lpDeltaBP);
        defaultSwapMode = _defaultSwapMode;
        defaultLPMode = _defaultLPMode;
        emit DeltaParamUpdated(_batched, _swapDeltaBP, _lpDeltaBP, _defaultSwapMode, _defaultLPMode);
    }

    function callDelta(bool _fullMode) external onlyRouter {
        _delta(_fullMode);
    }

    function activateChainPath(uint16 _dstChainId, uint256 _dstPoolId) external onlyRouter {
        ChainPath storage cp = getAndCheckCP(_dstChainId, _dstPoolId);
        require(cp.ready == false, "Stargate: chainPath is already active");
        // this func will only be called once
        cp.ready = true;
    }

    function withdrawProtocolFeeBalance(address _to) external onlyRouter {
        if (protocolFeeBalance > 0) {
            uint256 amountOfLD = amountSDtoLD(protocolFeeBalance);
            protocolFeeBalance = 0;
            _safeTransfer(token, _to, amountOfLD);
            emit WithdrawProtocolFeeBalance(_to, amountOfLD);
        }
    }

    function withdrawMintFeeBalance(address _to) external onlyRouter {
        if (mintFeeBalance > 0) {
            uint256 amountOfLD = amountSDtoLD(mintFeeBalance);
            mintFeeBalance = 0;
            _safeTransfer(token, _to, amountOfLD);
            emit WithdrawMintFeeBalance(_to, amountOfLD);
        }
    }

    //---------------------------------------------------------------------------
    // INTERNAL
    // Conversion Helpers
    //---------------------------------------------------------------------------
    function amountLPtoLD(uint256 _amountLP) external view returns (uint256) {
        return amountSDtoLD(_amountLPtoSD(_amountLP));
    }

    function _amountLPtoSD(uint256 _amountLP) internal view returns (uint256) {
        require(totalSupply > 0, "Stargate: cant convert LPtoSD when totalSupply == 0");
        return _amountLP.mul(totalLiquidity).div(totalSupply);
    }

    function _amountSDtoLP(uint256 _amountSD) internal view returns (uint256) {
        require(totalLiquidity > 0, "Stargate: cant convert SDtoLP when totalLiq == 0");
        return _amountSD.mul(totalSupply).div(totalLiquidity);
    }

    function amountSDtoLD(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(convertRate);
    }

    function amountLDtoSD(uint256 _amount) internal view returns (uint256) {
        return _amount.div(convertRate);
    }

    function getAndCheckCP(uint16 _dstChainId, uint256 _dstPoolId) internal view returns (ChainPath storage) {
        require(chainPaths.length > 0, "Stargate: no chainpaths exist");
        ChainPath storage cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]];
        require(cp.dstChainId == _dstChainId && cp.dstPoolId == _dstPoolId, "Stargate: local chainPath does not exist");
        return cp;
    }

    function getChainPath(uint16 _dstChainId, uint256 _dstPoolId) external view returns (ChainPath memory) {
        ChainPath memory cp = chainPaths[chainPathIndexLookup[_dstChainId][_dstPoolId]];
        require(cp.dstChainId == _dstChainId && cp.dstPoolId == _dstPoolId, "Stargate: local chainPath does not exist");
        return cp;
    }

    function _burnLocal(address _from, uint256 _amountLP) internal returns (uint256) {
        require(totalSupply > 0, "Stargate: cant burn when totalSupply == 0");
        uint256 amountOfLPTokens = balanceOf[_from];
        require(amountOfLPTokens >= _amountLP, "Stargate: not enough LP tokens to burn");

        uint256 amountSD = _amountLP.mul(totalLiquidity).div(totalSupply);
        //subtract totalLiquidity accordingly
        totalLiquidity = totalLiquidity.sub(amountSD);

        _burn(_from, _amountLP);
        emit Burn(_from, _amountLP, amountSD);
        return amountSD;
    }

    function _delta(bool fullMode) internal {
        if (deltaCredit > 0 && totalWeight > 0) {
            uint256 cpLength = chainPaths.length;
            uint256[] memory deficit = new uint256[](cpLength);
            uint256 totalDeficit = 0;

            // algorithm steps 6-9: calculate the total and the amounts required to get to balance state
            for (uint256 i = 0; i < cpLength; ++i) {
                ChainPath storage cp = chainPaths[i];
                // (liquidity * (weight/totalWeight)) - (lkb+credits)
                uint256 balLiq = totalLiquidity.mul(cp.weight).div(totalWeight);
                uint256 currLiq = cp.lkb.add(cp.credits);
                console.log("Pool._delta: totalLiquidity, balLiq, currLiq:", totalLiquidity, balLiq, currLiq);
                if (balLiq > currLiq) {
                    // save gas since we know balLiq > currLiq and we know deficit[i] > 0
                    deficit[i] = balLiq - currLiq;
                    totalDeficit = totalDeficit.add(deficit[i]);
                }
            }

            // indicates how much delta credit is distributed
            uint256 spent;

            // handle credits with 2 tranches. the [ < totalDeficit] [excessCredit]
            // run full Delta, allocate all credits
            if (totalDeficit == 0) {
                // only fullMode delta will allocate excess credits
                if (fullMode && deltaCredit > 0) {
                    // credit ChainPath by weights
                    for (uint256 i = 0; i < cpLength; ++i) {
                        ChainPath storage cp = chainPaths[i];
                        // credits = credits + toBalanceChange + remaining allocation based on weight
                        uint256 amtToCredit = deltaCredit.mul(cp.weight).div(totalWeight);
                        spent = spent.add(amtToCredit);
                        console.log("Pool._delta: first added: spent, amtToCredit", spent, amtToCredit);
                        cp.credits = cp.credits.add(amtToCredit);
                    }
                } // else do nth
            } else if (totalDeficit <= deltaCredit) {
                if (fullMode) {
                    // algorithm step 13: calculate amount to disperse to bring to balance state or as close as possible
                    uint256 excessCredit = deltaCredit - totalDeficit;
                    console.log("Pool._delta: excessCredit, deltaCredit, totalDeficit:", excessCredit, deltaCredit, totalDeficit);
                    // algorithm steps 14-16: calculate credits
                    for (uint256 i = 0; i < cpLength; ++i) {
                        console.log("Pool._delta: cpLength, deficit[i]:", cpLength, deficit[i]);
                        if (deficit[i] > 0) {
                            ChainPath storage cp = chainPaths[i];
                            // credits = credits + deficit + remaining allocation based on weight
                            uint256 amtToCredit = deficit[i].add(excessCredit.mul(cp.weight).div(totalWeight));
                            spent = spent.add(amtToCredit);
                            console.log("Pool._delta: second added: spent, amtToCredit", spent, amtToCredit);
                            cp.credits = cp.credits.add(amtToCredit);
                        }
                    }
                } else {
                    // totalDeficit <= deltaCredit but not running fullMode
                    // credit chainPaths as is if any deficit, not using all deltaCredit
                    for (uint256 i = 0; i < cpLength; ++i) {
                        if (deficit[i] > 0) {
                            ChainPath storage cp = chainPaths[i];
                            uint256 amtToCredit = deficit[i];
                            spent = spent.add(amtToCredit);
                            console.log("Pool._delta: third added: spent, amtToCredit", spent, amtToCredit);
                            cp.credits = cp.credits.add(amtToCredit);
                        }
                    }
                }
            } else {
                // totalDeficit > deltaCredit, fullMode or not, normalize the deficit by deltaCredit
                for (uint256 i = 0; i < cpLength; ++i) {
                    if (deficit[i] > 0) {
                        ChainPath storage cp = chainPaths[i];
                        uint256 proportionalDeficit = deficit[i].mul(deltaCredit).div(totalDeficit);
                        spent = spent.add(proportionalDeficit);
                        console.log("Pool._delta: fourth added: spent, proportionalDeficit", spent, proportionalDeficit);
                        cp.credits = cp.credits.add(proportionalDeficit);
                    }
                }
            }

            // deduct the amount of credit sent
            deltaCredit = deltaCredit.sub(spent);
            console.log("Pool._delta ended: deltaCredit, spent:", deltaCredit, spent);
        }
    }

    function _mintLocal(
        address _to,
        uint256 _amountLD,
        bool _feesEnabled,
        bool _creditDelta
    ) internal returns (uint256 amountSD) {
        console.log("Pool._mintLocal: _to, _amountLD, _creditDelta:", _to, _amountLD, _creditDelta);
        require(totalWeight > 0, "Stargate: No ChainPaths exist");
        amountSD = amountLDtoSD(_amountLD);
        console.log("Pool._mintLocal: amountSD:", amountSD);

        uint256 mintFeeSD = 0;
        if (_feesEnabled) {
            mintFeeSD = amountSD.mul(mintFeeBP).div(BP_DENOMINATOR);
            amountSD = amountSD.sub(mintFeeSD);
            mintFeeBalance = mintFeeBalance.add(mintFeeSD);
            console.log("Pool._mintLocal: _feesEnabled, mintFeeSD, amountSD:", _feesEnabled, mintFeeSD, amountSD);
        }

        if (_creditDelta) {
            deltaCredit = deltaCredit.add(amountSD);
            console.log("Pool._mintLocal: _creditDelta, deltaCredit:", _creditDelta, deltaCredit);
        }

        uint256 amountLPTokens = amountSD;
        if (totalSupply != 0) {
            amountLPTokens = amountSD.mul(totalSupply).div(totalLiquidity);
        }
        totalLiquidity = totalLiquidity.add(amountSD);

        _mint(_to, amountLPTokens);
        emit Mint(_to, amountLPTokens, amountSD, mintFeeSD);

        // add to credits and call delta. short circuit to save gas
        if (!batched || deltaCredit > totalLiquidity.mul(lpDeltaBP).div(BP_DENOMINATOR)) {
            console.log("Pool._mintLocal: _delta() called: defaultLPMode, batched, lpDeltaBP:", defaultLPMode, batched, lpDeltaBP);
            _delta(defaultLPMode);
        }
    }

    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Stargate: TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// imports
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StargateToken.sol";

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LPStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of STGs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accStargatePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accStargatePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. STGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that STGs distribution occurs.
        uint256 accStargatePerShare; // Accumulated STGs per share, times 1e12. See below.
    }
    // The STG TOKEN!
    StargateToken public stargate;
    // Block number when bonus STG period ends.
    uint256 public bonusEndBlock;
    // STG tokens created per block.
    uint256 public stargatePerBlock;
    // Bonus multiplier for early stargate makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Track which tokens have been added.
    mapping(address => bool) private addedLPTokens;

    mapping(uint256 => uint256) public lpBalances;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when STG mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        StargateToken _stargate,
        uint256 _stargatePerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        require(_startBlock >= block.number, "LPStaking: _startBlock must be >= current block");
        require(_bonusEndBlock >= _startBlock, "LPStaking: _bonusEndBlock must be > than _startBlock");
        require(address(_stargate) != address(0x0), "Stargate: _stargate cannot be 0x0");
        stargate = _stargate;
        stargatePerBlock = _stargatePerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 _pid) external view returns (IERC20) {
        return poolInfo[_pid].lpToken;
    }

    function getAllocPoint(uint256 _pid) external view returns (uint256) {
        return poolInfo[_pid].allocPoint;
    }

    /// @notice handles adding a new LP token (Can only be called by the owner)
    /// @param _allocPoint The alloc point is used as the weight of the pool against all other alloc points added.
    /// @param _lpToken The lp token address
    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        massUpdatePools();
        require(address(_lpToken) != address(0x0), "StarGate: lpToken cant be 0x0");
        require(addedLPTokens[address(_lpToken)] == false, "StarGate: _lpToken already exists");
        addedLPTokens[address(_lpToken)] = true;
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({lpToken: _lpToken, allocPoint: _allocPoint, lastRewardBlock: lastRewardBlock, accStargatePerShare: 0}));
    }

    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
        }
    }

    function pendingStargate(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accStargatePerShare = pool.accStargatePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 stargateReward = multiplier.mul(stargatePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accStargatePerShare = accStargatePerShare.add(stargateReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accStargatePerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 stargateReward = multiplier.mul(stargatePerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accStargatePerShare = pool.accStargatePerShare.add(stargateReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accStargatePerShare).div(1e12).sub(user.rewardDebt);
            safeStargateTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accStargatePerShare).div(1e12);
        lpBalances[_pid] = lpBalances[_pid].add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: _amount is too large");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accStargatePerShare).div(1e12).sub(user.rewardDebt);
        safeStargateTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accStargatePerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        lpBalances[_pid] = lpBalances[_pid].sub(_amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw without caring about rewards.
    /// @param _pid The pid specifies the pool
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 userAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), userAmount);
        lpBalances[_pid] = lpBalances[_pid].sub(userAmount);
        emit EmergencyWithdraw(msg.sender, _pid, userAmount);
    }

    /// @notice Safe transfer function, just in case if rounding error causes pool to not have enough STGs.
    /// @param _to The address to transfer tokens to
    /// @param _amount The quantity to transfer
    function safeStargateTransfer(address _to, uint256 _amount) internal {
        uint256 stargateBal = stargate.balanceOf(address(this));
        if (_amount > stargateBal) {
            IERC20(stargate).safeTransfer(_to, stargateBal);
        } else {
            IERC20(stargate).safeTransfer(_to, _amount);
        }
    }

    function setStargatePerBlock(uint256 _stargatePerBlock) external onlyOwner {
        massUpdatePools();
        stargatePerBlock = _stargatePerBlock;
    }

    // Override the renounce ownership inherited by zeppelin ownable
    function renounceOwnership() public override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

// imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Factory.sol";
import "./Pool.sol";
import "./Bridge.sol";

// interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IStargateRouter.sol";
import "../../interfaces/IStargateReceiver.sol";

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract Router is IStargateRouter, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // CONSTANTS
    uint8 internal constant TYPE_REDEEM_LOCAL_RESPONSE = 1;
    uint8 internal constant TYPE_REDEEM_LOCAL_CALLBACK_RETRY = 2;
    uint8 internal constant TYPE_SWAP_REMOTE_RETRY = 3;

    //---------------------------------------------------------------------------
    // STRUCTS
    struct CachedSwap {
        address token;
        uint256 amountLD;
        address to;
        bytes payload;
    }

    //---------------------------------------------------------------------------
    // VARIABLES
    Factory public factory; // used for creating pools
    address public protocolFeeOwner; // can call methods to pull Stargate fees collected in pools
    address public mintFeeOwner; // can call methods to pull mint fees collected in pools
    Bridge public bridge;
    mapping(uint16 => mapping(bytes => mapping(uint256 => bytes))) public revertLookup; //[chainId][srcAddress][nonce]
    mapping(uint16 => mapping(bytes => mapping(uint256 => CachedSwap))) public cachedSwapLookup; //[chainId][srcAddress][nonce]

    //---------------------------------------------------------------------------
    // EVENTS
    event Revert(uint8 bridgeFunctionType, uint16 chainId, bytes srcAddress, uint256 nonce);
    event CachedSwapSaved(uint16 chainId, bytes srcAddress, uint256 nonce, address token, uint256 amountLD, address to, bytes payload, bytes reason);
    event RevertRedeemLocal(uint16 srcChainId, uint256 _srcPoolId, uint256 _dstPoolId, bytes to, uint256 redeemAmountSD, uint256 mintAmountSD, uint256 indexed nonce, bytes indexed srcAddress);
    event RedeemLocalCallback(uint16 srcChainId, bytes indexed srcAddress, uint256 indexed nonce, uint256 srcPoolId, uint256 dstPoolId, address to, uint256 amountSD, uint256 mintAmountSD);

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyBridge() {
        require(msg.sender == address(bridge), "Bridge: caller must be Bridge.");
        _;
    }

    constructor() {}

    function setBridgeAndFactory(Bridge _bridge, Factory _factory) external onlyOwner {
        require(address(bridge) == address(0x0) && address(factory) == address(0x0), "Stargate: bridge and factory already initialized"); // 1 time only
        require(address(_bridge) != address(0x0), "Stargate: bridge cant be 0x0");
        require(address(_factory) != address(0x0), "Stargate: factory cant be 0x0");

        bridge = _bridge;
        factory = _factory;
    }

    //---------------------------------------------------------------------------
    // VIEWS
    function _getPool(uint256 _poolId) internal view returns (Pool pool) {
        pool = factory.getPool(_poolId);
        require(address(pool) != address(0x0), "Stargate: Pool does not exist");
    }

    //---------------------------------------------------------------------------
    // INTERNAL
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Stargate: TRANSFER_FROM_FAILED");
    }

    //---------------------------------------------------------------------------
    // LOCAL CHAIN FUNCTIONS
    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external override nonReentrant {
        Pool pool = _getPool(_poolId);
        uint256 convertRate = pool.convertRate();
        _amountLD = _amountLD.div(convertRate).mul(convertRate);
        _safeTransferFrom(pool.token(), msg.sender, address(pool), _amountLD);
        pool.mint(_to, _amountLD);
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable override nonReentrant {
        require(_amountLD > 0, "Stargate: cannot swap 0");
        require(_refundAddress != address(0x0), "Stargate: _refundAddress cannot be 0x0");
        Pool.SwapObj memory s;
        Pool.CreditObj memory c;
        {
            Pool pool = _getPool(_srcPoolId);
            {
                uint256 convertRate = pool.convertRate();
                _amountLD = _amountLD.div(convertRate).mul(convertRate);
            }

            s = pool.swap(_dstChainId, _dstPoolId, msg.sender, _amountLD, _minAmountLD, true);
            _safeTransferFrom(pool.token(), msg.sender, address(pool), _amountLD);
            c = pool.sendCredits(_dstChainId, _dstPoolId);
        }
        bridge.swap{value: msg.value}(_dstChainId, _srcPoolId, _dstPoolId, _refundAddress, c, s, _lzTxParams, _to, _payload);
    }

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable override nonReentrant {
        require(_refundAddress != address(0x0), "Stargate: _refundAddress cannot be 0x0");
        require(_amountLP > 0, "Stargate: not enough lp to redeemRemote");
        Pool.SwapObj memory s;
        Pool.CreditObj memory c;
        {
            Pool pool = _getPool(_srcPoolId);
            uint256 amountLD = pool.amountLPtoLD(_amountLP);
            // perform a swap with no liquidity
            s = pool.swap(_dstChainId, _dstPoolId, msg.sender, amountLD, _minAmountLD, false);
            pool.redeemRemote(_dstChainId, _dstPoolId, msg.sender, _amountLP);
            c = pool.sendCredits(_dstChainId, _dstPoolId);
        }
        // equal to a swap, with no payload ("0x") no dstGasForCall 0
        bridge.swap{value: msg.value}(_dstChainId, _srcPoolId, _dstPoolId, _refundAddress, c, s, _lzTxParams, _to, "");
    }

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external override nonReentrant returns (uint256 amountSD) {
        console.log("Router.instantRedeemLocal started: _srcPoolId, _amountLP, _to:", _srcPoolId, _amountLP, _to);
        require(_amountLP > 0, "Stargate: not enough lp to redeem");
        Pool pool = _getPool(_srcPoolId);
        amountSD = pool.instantRedeemLocal(msg.sender, _amountLP, _to);
        console.log("Router.instantRedeemLocal ended");
    }

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable override nonReentrant {
        require(_refundAddress != address(0x0), "Stargate: _refundAddress cannot be 0x0");
        Pool pool = _getPool(_srcPoolId);
        require(_amountLP > 0, "Stargate: not enough lp to redeem");
        uint256 amountSD = pool.redeemLocal(msg.sender, _amountLP, _dstChainId, _dstPoolId, _to);
        require(amountSD > 0, "Stargate: not enough lp to redeem with amountSD");

        Pool.CreditObj memory c = pool.sendCredits(_dstChainId, _dstPoolId);
        bridge.redeemLocal{value: msg.value}(_dstChainId, _srcPoolId, _dstPoolId, _refundAddress, c, amountSD, _to, _lzTxParams);
    }

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable override nonReentrant {
        require(_refundAddress != address(0x0), "Stargate: _refundAddress cannot be 0x0");
        Pool pool = _getPool(_srcPoolId);
        Pool.CreditObj memory c = pool.sendCredits(_dstChainId, _dstPoolId);
        bridge.sendCredits{value: msg.value}(_dstChainId, _srcPoolId, _dstPoolId, _refundAddress, c);
    }

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        Router.lzTxObj memory _lzTxParams
    ) external view override returns (uint256, uint256) {
        return bridge.quoteLayerZeroFee(_dstChainId, _functionType, _toAddress, _transferAndCallPayload, _lzTxParams);
    }

    function revertRedeemLocal(
        uint16 _dstChainId,
        bytes calldata _srcAddress,
        uint256 _nonce,
        address payable _refundAddress,
        lzTxObj memory _lzTxParams
    ) external payable {
        require(_refundAddress != address(0x0), "Stargate: _refundAddress cannot be 0x0");
        bytes memory payload = revertLookup[_dstChainId][_srcAddress][_nonce];
        require(payload.length > 0, "Stargate: no retry revert");
        {
            uint8 functionType;
            assembly {
                functionType := mload(add(payload, 32))
            }
            require(functionType == TYPE_REDEEM_LOCAL_RESPONSE, "Stargate: invalid function type");
        }

        // empty it
        revertLookup[_dstChainId][_srcAddress][_nonce] = "";

        uint256 srcPoolId;
        uint256 dstPoolId;
        assembly {
            srcPoolId := mload(add(payload, 64))
            dstPoolId := mload(add(payload, 96))
        }

        Pool.CreditObj memory c;
        {
            Pool pool = _getPool(dstPoolId);
            c = pool.sendCredits(_dstChainId, srcPoolId);
        }

        bridge.redeemLocalCallback{value: msg.value}(_dstChainId, _refundAddress, c, _lzTxParams, payload);
    }

    function retryRevert(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint256 _nonce
    ) external payable {
        bytes memory payload = revertLookup[_srcChainId][_srcAddress][_nonce];
        require(payload.length > 0, "Stargate: no retry revert");

        // empty it
        revertLookup[_srcChainId][_srcAddress][_nonce] = "";

        uint8 functionType;
        assembly {
            functionType := mload(add(payload, 32))
        }

        if (functionType == TYPE_REDEEM_LOCAL_CALLBACK_RETRY) {
            (, uint256 srcPoolId, uint256 dstPoolId, address to, uint256 amountSD, uint256 mintAmountSD) = abi.decode(
                payload,
                (uint8, uint256, uint256, address, uint256, uint256)
            );
            _redeemLocalCallback(_srcChainId, _srcAddress, _nonce, srcPoolId, dstPoolId, to, amountSD, mintAmountSD);
        }
        // for retrying the swapRemote. if it fails again, retry
        else if (functionType == TYPE_SWAP_REMOTE_RETRY) {
            (, uint256 srcPoolId, uint256 dstPoolId, uint256 dstGasForCall, address to, Pool.SwapObj memory s, bytes memory p) = abi.decode(
                payload,
                (uint8, uint256, uint256, uint256, address, Pool.SwapObj, bytes)
            );
            _swapRemote(_srcChainId, _srcAddress, _nonce, srcPoolId, dstPoolId, dstGasForCall, to, s, p);
        } else {
            revert("Stargate: invalid function type");
        }
    }

    function clearCachedSwap(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint256 _nonce
    ) external {
        CachedSwap memory cs = cachedSwapLookup[_srcChainId][_srcAddress][_nonce];
        require(cs.to != address(0x0), "Stargate: cache already cleared");
        // clear the data
        cachedSwapLookup[_srcChainId][_srcAddress][_nonce] = CachedSwap(address(0x0), 0, address(0x0), "");
        IStargateReceiver(cs.to).sgReceive(_srcChainId, _srcAddress, _nonce, cs.token, cs.amountLD, cs.payload);
    }

    function creditChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _srcPoolId,
        Pool.CreditObj memory _c
    ) external onlyBridge {
        Pool pool = _getPool(_srcPoolId);
        pool.creditChainPath(_dstChainId, _dstPoolId, _c);
    }

    //---------------------------------------------------------------------------
    // REMOTE CHAIN FUNCTIONS
    function redeemLocalCheckOnRemote(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint256 _amountSD,
        bytes calldata _to
    ) external onlyBridge {
        Pool pool = _getPool(_dstPoolId);
        try pool.redeemLocalCheckOnRemote(_srcChainId, _srcPoolId, _amountSD) returns (uint256 redeemAmountSD, uint256 mintAmountSD) {
            revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(
                TYPE_REDEEM_LOCAL_RESPONSE,
                _srcPoolId,
                _dstPoolId,
                redeemAmountSD,
                mintAmountSD,
                _to
            );
            emit RevertRedeemLocal(_srcChainId, _srcPoolId, _dstPoolId, _to, redeemAmountSD, mintAmountSD, _nonce, _srcAddress);
        } catch {
            // if the func fail, return [swapAmount: 0, mintAMount: _amountSD]
            // swapAmount represents the amount of chainPath balance deducted on the remote side, which because the above tx failed, should be 0
            // mintAmount is the full amount of tokens the user attempted to redeem on the src side, which gets converted back into the lp amount
            revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(TYPE_REDEEM_LOCAL_RESPONSE, _srcPoolId, _dstPoolId, 0, _amountSD, _to);
            emit Revert(TYPE_REDEEM_LOCAL_RESPONSE, _srcChainId, _srcAddress, _nonce);
        }
    }

    function redeemLocalCallback(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _to,
        uint256 _amountSD,
        uint256 _mintAmountSD
    ) external onlyBridge {
        _redeemLocalCallback(_srcChainId, _srcAddress, _nonce, _srcPoolId, _dstPoolId, _to, _amountSD, _mintAmountSD);
    }

    function _redeemLocalCallback(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _to,
        uint256 _amountSD,
        uint256 _mintAmountSD
    ) internal {
        Pool pool = _getPool(_dstPoolId);
        try pool.redeemLocalCallback(_srcChainId, _srcPoolId, _to, _amountSD, _mintAmountSD) {} catch {
            revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(
                TYPE_REDEEM_LOCAL_CALLBACK_RETRY,
                _srcPoolId,
                _dstPoolId,
                _to,
                _amountSD,
                _mintAmountSD
            );
            emit Revert(TYPE_REDEEM_LOCAL_CALLBACK_RETRY, _srcChainId, _srcAddress, _nonce);
        }
        emit RedeemLocalCallback(_srcChainId, _srcAddress, _nonce, _srcPoolId, _dstPoolId, _to, _amountSD, _mintAmountSD);
    }

    function swapRemote(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint256 _dstGasForCall,
        address _to,
        Pool.SwapObj memory _s,
        bytes memory _payload
    ) external onlyBridge {
        _swapRemote(_srcChainId, _srcAddress, _nonce, _srcPoolId, _dstPoolId, _dstGasForCall, _to, _s, _payload);
    }

    function _swapRemote(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint256 _dstGasForCall,
        address _to,
        Pool.SwapObj memory _s,
        bytes memory _payload
    ) internal {
        Pool pool = _getPool(_dstPoolId);
        // first try catch the swap remote
        try pool.swapRemote(_srcChainId, _srcPoolId, _to, _s) returns (uint256 amountLD) {
            if (_payload.length > 0) {
                // then try catch the external contract call
                try IStargateReceiver(_to).sgReceive{gas: _dstGasForCall}(_srcChainId, _srcAddress, _nonce, pool.token(), amountLD, _payload) {
                    // do nothing
                } catch (bytes memory reason) {
                    cachedSwapLookup[_srcChainId][_srcAddress][_nonce] = CachedSwap(pool.token(), amountLD, _to, _payload);
                    emit CachedSwapSaved(_srcChainId, _srcAddress, _nonce, pool.token(), amountLD, _to, _payload, reason);
                }
            }
        } catch {
            revertLookup[_srcChainId][_srcAddress][_nonce] = abi.encode(
                TYPE_SWAP_REMOTE_RETRY,
                _srcPoolId,
                _dstPoolId,
                _dstGasForCall,
                _to,
                _s,
                _payload
            );
            emit Revert(TYPE_SWAP_REMOTE_RETRY, _srcChainId, _srcAddress, _nonce);
        }
    }

    //---------------------------------------------------------------------------
    // DAO Calls
    function createPool(
        uint256 _poolId,
        address _token,
        uint8 _sharedDecimals,
        uint8 _localDecimals,
        string memory _name,
        string memory _symbol
    ) external onlyOwner returns (address) {
        require(_token != address(0x0), "Stargate: _token cannot be 0x0");
        return factory.createPool(_poolId, _token, _sharedDecimals, _localDecimals, _name, _symbol);
    }

    function createChainPath(
        uint256 _poolId,
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _weight
    ) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.createChainPath(_dstChainId, _dstPoolId, _weight);
    }

    function activateChainPath(
        uint256 _poolId,
        uint16 _dstChainId,
        uint256 _dstPoolId
    ) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.activateChainPath(_dstChainId, _dstPoolId);
    }

    function setWeightForChainPath(
        uint256 _poolId,
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint16 _weight
    ) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.setWeightForChainPath(_dstChainId, _dstPoolId, _weight);
    }

    function setProtocolFeeOwner(address _owner) external onlyOwner {
        require(_owner != address(0x0), "Stargate: _owner cannot be 0x0");
        protocolFeeOwner = _owner;
    }

    function setMintFeeOwner(address _owner) external onlyOwner {
        require(_owner != address(0x0), "Stargate: _owner cannot be 0x0");
        mintFeeOwner = _owner;
    }

    function setFees(uint256 _poolId, uint256 _mintFeeBP) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.setFee(_mintFeeBP);
    }

    function setFeeLibrary(uint256 _poolId, address _feeLibraryAddr) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.setFeeLibrary(_feeLibraryAddr);
    }

    function setSwapStop(uint256 _poolId, bool _swapStop) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.setSwapStop(_swapStop);
    }

    function setDeltaParam(
        uint256 _poolId,
        bool _batched,
        uint256 _swapDeltaBP,
        uint256 _lpDeltaBP,
        bool _defaultSwapMode,
        bool _defaultLPMode
    ) external onlyOwner {
        Pool pool = _getPool(_poolId);
        pool.setDeltaParam(_batched, _swapDeltaBP, _lpDeltaBP, _defaultSwapMode, _defaultLPMode);
    }

    function callDelta(uint256 _poolId, bool _fullMode) external {
        Pool pool = _getPool(_poolId);
        pool.callDelta(_fullMode);
    }

    function withdrawMintFee(uint256 _poolId, address _to) external {
        require(mintFeeOwner == msg.sender, "Stargate: only mintFeeOwner");
        Pool pool = _getPool(_poolId);
        pool.withdrawMintFeeBalance(_to);
    }

    function withdrawProtocolFee(uint256 _poolId, address _to) external {
        require(protocolFeeOwner == msg.sender, "Stargate: only protocolFeeOwner");
        Pool pool = _getPool(_poolId);
        pool.withdrawProtocolFeeBalance(_to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LPTokenERC20 {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // CONSTANTS
    string public name;
    string public symbol;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // set in constructor
    bytes32 public DOMAIN_SEPARATOR;

    //---------------------------------------------------------------------------
    // VARIABLES
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    //---------------------------------------------------------------------------
    // EVENTS
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Bridge: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Bridge: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;
import "../libraries/stargate/Pool.sol";

interface IStargateFeeLibrary {
    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external returns (Pool.SwapObj memory s);

    function getVersion() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./OmnichainFungibleToken.sol";

contract StargateToken is OmnichainFungibleToken {
    constructor(
        string memory _name,
        string memory _symbol,
        address _endpoint,
        uint16 _mainEndpointId,
        uint256 _initialSupplyOnMainEndpoint
    ) OmnichainFungibleToken(_name, _symbol, _endpoint, _mainEndpointId, _initialSupplyOnMainEndpoint) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/ILayerZeroReceiver.sol";
import "../../interfaces/ILayerZeroEndpoint.sol";
import "../../interfaces/ILayerZeroUserApplicationConfig.sol";

//---------------------------------------------------------------------------
// THIS CONTRACT IS OF BUSINESS LICENSE. CONTACT US BEFORE YOU USE IT.
//
// LayerZero is pushing now a new cross-chain token standard with permissive license soon
//
// Stay tuned for maximum cross-chain compatability of your token
//---------------------------------------------------------------------------
contract OmnichainFungibleToken is ERC20, Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint immutable public endpoint;
    mapping(uint16 => bytes) public dstContractLookup; // a map of the connected contracts
    bool public paused; // indicates cross chain transfers are paused
    bool public isMain; // indicates this contract is on the main chain

    event Paused(bool isPaused);
    event SendToChain(uint16 srcChainId, bytes toAddress, uint256 qty, uint64 nonce);
    event ReceiveFromChain(uint16 srcChainId, address toAddress, uint256 qty, uint64 nonce);

    constructor(
        string memory _name,
        string memory _symbol,
        address _endpoint,
        uint16 _mainChainId,
        uint256 _initialSupplyOnMainEndpoint
    ) ERC20(_name, _symbol) {
        // only mint the total supply on the main chain
        if (ILayerZeroEndpoint(_endpoint).getChainId() == _mainChainId) {
            isMain = true;
        }
        _mint(msg.sender, _initialSupplyOnMainEndpoint);
        // set the LayerZero endpoint
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    function pauseSendTokens(bool _pause) external onlyOwner {
        paused = _pause;
        emit Paused(_pause);
    }

    function setDestination(uint16 _dstChainId, bytes calldata _destinationContractAddress) public onlyOwner {
        dstContractLookup[_dstChainId] = _destinationContractAddress;
    }

    function chainId() external view returns (uint16){
        return endpoint.getChainId();
    }

    function sendTokens(
        uint16 _dstChainId, // send tokens to this chainId
        bytes calldata _to, // where to deliver the tokens on the destination chain
        uint256 _qty, // how many tokens to send
        address _zroPaymentAddress, // ZRO payment address
        bytes calldata _adapterParam // txParameters
    ) public payable {
        require(!paused, "OFT: sendTokens() is currently paused");

        // lock by transferring to this contract if leaving the main chain, otherwise burn
        if (isMain) {
            _transfer(msg.sender, address(this), _qty);
        } else {
            _burn(msg.sender, _qty);
        }

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(_to, _qty);

        // send LayerZero message
        endpoint.send{value: msg.value}(
            _dstChainId, // destination chainId
            dstContractLookup[_dstChainId], // destination UA address
            payload, // abi.encode()'ed bytes
            payable(msg.sender), // refund address (LayerZero will refund any extra gas back to msg.sender
            _zroPaymentAddress, // 'zroPaymentAddress'
            _adapterParam // 'adapterParameters'
        );
        uint64 nonce = endpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(_dstChainId, _to, _qty, nonce);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint)); // lzReceive must only be called by the endpoint
        require(
            _fromAddress.length == dstContractLookup[_srcChainId].length && keccak256(_fromAddress) == keccak256(dstContractLookup[_srcChainId]),
            "OFT: invalid source sending contract"
        );

        // decode and load the toAddress
        (bytes memory _to, uint256 _qty) = abi.decode(_payload, (bytes, uint256));
        address toAddress;
        assembly { toAddress := mload(add(_to, 20)) }

        // if the toAddress is 0x0, burn it
        if (toAddress == address(0x0)) toAddress == address(0xdEaD);

        // on the main chain unlock via transfer, otherwise _mint
        if (isMain) {
            _transfer(address(this), toAddress, _qty);
        } else {
            _mint(toAddress, _qty);
        }

        emit ReceiveFromChain(_srcChainId, toAddress, _qty, _nonce);
    }

    function estimateSendTokensFee(uint16 _dstChainId, bytes calldata _toAddress, bool _useZro, bytes calldata _txParameters) external view returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for sendTokens()
        bytes memory payload = abi.encode(_toAddress, 1);
        return endpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _txParameters);
    }

    //---------------------------DAO CALL----------------------------------------
    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function renounceOwnership() public override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

import "hardhat/console.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        console.log("ERC20._transfer started: from, to, amount:", from, to, amount);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
        console.log("ERC20._transfer ended:");
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pool.sol";

contract Factory is Ownable {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // VARIABLES
    mapping(uint256 => Pool) public getPool; // poolId -> PoolInfo
    address[] public allPools;
    address public immutable router;
    address public defaultFeeLibrary; // address for retrieving fee params for swaps

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyRouter() {
        require(msg.sender == router, "Stargate: caller must be Router.");
        _;
    }

    constructor(address _router) {
        require(_router != address(0x0), "Stargate: _router cant be 0x0"); // 1 time only
        router = _router;
    }

    function setDefaultFeeLibrary(address _defaultFeeLibrary) external onlyOwner {
        require(_defaultFeeLibrary != address(0x0), "Stargate: fee library cant be 0x0");
        defaultFeeLibrary = _defaultFeeLibrary;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(
        uint256 _poolId,
        address _token,
        uint8 _sharedDecimals,
        uint8 _localDecimals,
        string memory _name,
        string memory _symbol
    ) public onlyRouter returns (address poolAddress) {
        require(address(getPool[_poolId]) == address(0x0), "Stargate: Pool already created");

        Pool pool = new Pool(_poolId, router, _token, _sharedDecimals, _localDecimals, defaultFeeLibrary, _name, _symbol);
        getPool[_poolId] = pool;
        poolAddress = address(pool);
        allPools.push(poolAddress);
    }

    function renounceOwnership() public override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

// imports
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Pool.sol";
import "./Router.sol";

// libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../interfaces/ILayerZeroReceiver.sol";
import "../../interfaces/ILayerZeroEndpoint.sol";
import "../../interfaces/ILayerZeroUserApplicationConfig.sol";

contract Bridge is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // CONSTANTS
    uint8 internal constant TYPE_SWAP_REMOTE = 1;
    uint8 internal constant TYPE_ADD_LIQUIDITY = 2;
    uint8 internal constant TYPE_REDEEM_LOCAL_CALL_BACK = 3;
    uint8 internal constant TYPE_WITHDRAW_REMOTE = 4;

    //---------------------------------------------------------------------------
    // VARIABLES
    ILayerZeroEndpoint public immutable layerZeroEndpoint;
    mapping(uint16 => bytes) public bridgeLookup;
    mapping(uint16 => mapping(uint8 => uint256)) public gasLookup;
    Router public immutable router;
    bool public useLayerZeroToken;

    //---------------------------------------------------------------------------
    // EVENTS
    event SendMsg(uint8 msgType, uint64 nonce);

    //---------------------------------------------------------------------------
    // MODIFIERS
    modifier onlyRouter() {
        require(msg.sender == address(router), "Stargate: caller must be Router.");
        _;
    }

    constructor(address _layerZeroEndpoint, address _router) {
        require(_layerZeroEndpoint != address(0x0), "Stargate: _layerZeroEndpoint cannot be 0x0");
        require(_router != address(0x0), "Stargate: _router cannot be 0x0");
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        router = Router(_router);
    }

    //---------------------------------------------------------------------------
    // EXTERNAL functions

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(layerZeroEndpoint), "Stargate: only LayerZero endpoint can call lzReceive");
        require(
            _srcAddress.length == bridgeLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(bridgeLookup[_srcChainId]),
            "Stargate: bridge does not match"
        );

        uint8 functionType;
        assembly {
            functionType := mload(add(_payload, 32))
        }

        if (functionType == TYPE_SWAP_REMOTE) {
            (
                ,
                uint256 srcPoolId,
                uint256 dstPoolId,
                uint256 dstGasForCall,
                Pool.CreditObj memory c,
                Pool.SwapObj memory s,
                bytes memory to,
                bytes memory payload
            ) = abi.decode(_payload, (uint8, uint256, uint256, uint256, Pool.CreditObj, Pool.SwapObj, bytes, bytes));
            address toAddress;
            assembly {
                toAddress := mload(add(to, 20))
            }
            router.creditChainPath(_srcChainId, srcPoolId, dstPoolId, c);
            router.swapRemote(_srcChainId, _srcAddress, _nonce, srcPoolId, dstPoolId, dstGasForCall, toAddress, s, payload);
        } else if (functionType == TYPE_ADD_LIQUIDITY) {
            (, uint256 srcPoolId, uint256 dstPoolId, Pool.CreditObj memory c) = abi.decode(_payload, (uint8, uint256, uint256, Pool.CreditObj));
            router.creditChainPath(_srcChainId, srcPoolId, dstPoolId, c);
        } else if (functionType == TYPE_REDEEM_LOCAL_CALL_BACK) {
            (, uint256 srcPoolId, uint256 dstPoolId, Pool.CreditObj memory c, uint256 amountSD, uint256 mintAmountSD, bytes memory to) = abi
                .decode(_payload, (uint8, uint256, uint256, Pool.CreditObj, uint256, uint256, bytes));
            address toAddress;
            assembly {
                toAddress := mload(add(to, 20))
            }
            router.creditChainPath(_srcChainId, srcPoolId, dstPoolId, c);
            router.redeemLocalCallback(_srcChainId, _srcAddress, _nonce, srcPoolId, dstPoolId, toAddress, amountSD, mintAmountSD);
        } else if (functionType == TYPE_WITHDRAW_REMOTE) {
            (, uint256 srcPoolId, uint256 dstPoolId, Pool.CreditObj memory c, uint256 amountSD, bytes memory to) = abi.decode(
                _payload,
                (uint8, uint256, uint256, Pool.CreditObj, uint256, bytes)
            );
            router.creditChainPath(_srcChainId, srcPoolId, dstPoolId, c);
            router.redeemLocalCheckOnRemote(_srcChainId, _srcAddress, _nonce, srcPoolId, dstPoolId, amountSD, to);
        }
    }

    //---------------------------------------------------------------------------
    // LOCAL CHAIN FUNCTIONS
    function swap(
        uint16 _chainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        Pool.CreditObj memory _c,
        Pool.SwapObj memory _s,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable onlyRouter {
        bytes memory payload = abi.encode(TYPE_SWAP_REMOTE, _srcPoolId, _dstPoolId, _lzTxParams.dstGasForCall, _c, _s, _to, _payload);
        _call(_chainId, TYPE_SWAP_REMOTE, _refundAddress, _lzTxParams, payload);
    }

    function redeemLocalCallback(
        uint16 _chainId,
        address payable _refundAddress,
        Pool.CreditObj memory _c,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes memory _payload
    ) external payable onlyRouter {
        bytes memory payload;

        {
            (, uint256 srcPoolId, uint256 dstPoolId, uint256 amountSD, uint256 mintAmountSD, bytes memory to) = abi.decode(
                _payload,
                (uint8, uint256, uint256, uint256, uint256, bytes)
            );

            // swap dst and src because we are headed back
            payload = abi.encode(TYPE_REDEEM_LOCAL_CALL_BACK, dstPoolId, srcPoolId, _c, amountSD, mintAmountSD, to);
        }

        _call(_chainId, TYPE_REDEEM_LOCAL_CALL_BACK, _refundAddress, _lzTxParams, payload);
    }

    function redeemLocal(
        uint16 _chainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        Pool.CreditObj memory _c,
        uint256 _amountSD,
        bytes calldata _to,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) external payable onlyRouter {
        bytes memory payload = abi.encode(TYPE_WITHDRAW_REMOTE, _srcPoolId, _dstPoolId, _c, _amountSD, _to);
        _call(_chainId, TYPE_WITHDRAW_REMOTE, _refundAddress, _lzTxParams, payload);
    }

    function sendCredits(
        uint16 _chainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        Pool.CreditObj memory _c
    ) external payable onlyRouter {
        bytes memory payload = abi.encode(TYPE_ADD_LIQUIDITY, _srcPoolId, _dstPoolId, _c);
        IStargateRouter.lzTxObj memory lzTxObj = IStargateRouter.lzTxObj(0, 0, "0x");
        _call(_chainId, TYPE_ADD_LIQUIDITY, _refundAddress, lzTxObj, payload);
    }

    function quoteLayerZeroFee(
        uint16 _chainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256) {
        bytes memory payload = "";
        Pool.CreditObj memory c = Pool.CreditObj(1, 1);
        if (_functionType == TYPE_SWAP_REMOTE) {
            Pool.SwapObj memory s = Pool.SwapObj(1, 1, 1, 1, 1, 1);
            payload = abi.encode(TYPE_SWAP_REMOTE, 0, 0, 0, c, s, _toAddress, _transferAndCallPayload);
        } else if (_functionType == TYPE_ADD_LIQUIDITY) {
            payload = abi.encode(TYPE_ADD_LIQUIDITY, 0, 0, c);
        } else if (_functionType == TYPE_REDEEM_LOCAL_CALL_BACK) {
            payload = abi.encode(TYPE_REDEEM_LOCAL_CALL_BACK, 0, 0, c, 0, 0, _toAddress);
        } else if (_functionType == TYPE_WITHDRAW_REMOTE) {
            payload = abi.encode(TYPE_WITHDRAW_REMOTE, 0, 0, c, 0, _toAddress);
        } else {
            revert("Stargate: unsupported function type");
        }

        bytes memory lzTxParamBuilt = _txParamBuilder(_chainId, _functionType, _lzTxParams);
        return layerZeroEndpoint.estimateFees(_chainId, address(this), payload, useLayerZeroToken, lzTxParamBuilt);
    }

    //---------------------------------------------------------------------------
    // dao functions
    function setBridge(uint16 _chainId, bytes calldata _bridgeAddress) external onlyOwner {
        require(bridgeLookup[_chainId].length == 0, "Stargate: Bridge already set!");
        bridgeLookup[_chainId] = _bridgeAddress;
    }

    function setGasAmount(
        uint16 _chainId,
        uint8 _functionType,
        uint256 _gasAmount
    ) external onlyOwner {
        require(_functionType >= 1 && _functionType <= 4, "Stargate: invalid _functionType");
        gasLookup[_chainId][_functionType] = _gasAmount;
    }

    function approveTokenSpender(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).approve(spender, amount);
    }

    function setUseLayerZeroToken(bool enable) external onlyOwner {
        useLayerZeroToken = enable;
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        layerZeroEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    //---------------------------------------------------------------------------
    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        layerZeroEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setReceiveVersion(version);
    }

    //---------------------------------------------------------------------------
    // INTERNAL functions
    function txParamBuilderType1(uint256 _gasAmount) internal pure returns (bytes memory) {
        uint16 txType = 1;
        return abi.encodePacked(txType, _gasAmount);
    }

    function txParamBuilderType2(
        uint256 _gasAmount,
        uint256 _dstNativeAmount,
        bytes memory _dstNativeAddr
    ) internal pure returns (bytes memory) {
        uint16 txType = 2;
        return abi.encodePacked(txType, _gasAmount, _dstNativeAmount, _dstNativeAddr);
    }

    function _txParamBuilder(
        uint16 _chainId,
        uint8 _type,
        IStargateRouter.lzTxObj memory _lzTxParams
    ) internal view returns (bytes memory) {
        bytes memory lzTxParam;
        address dstNativeAddr;
        {
            bytes memory dstNativeAddrBytes = _lzTxParams.dstNativeAddr;
            assembly {
                dstNativeAddr := mload(add(dstNativeAddrBytes, 20))
            }
        }

        uint256 totalGas = gasLookup[_chainId][_type].add(_lzTxParams.dstGasForCall);
        if (_lzTxParams.dstNativeAmount > 0 && dstNativeAddr != address(0x0)) {
            lzTxParam = txParamBuilderType2(totalGas, _lzTxParams.dstNativeAmount, _lzTxParams.dstNativeAddr);
        } else {
            lzTxParam = txParamBuilderType1(totalGas);
        }

        return lzTxParam;
    }

    function _call(
        uint16 _chainId,
        uint8 _type,
        address payable _refundAddress,
        IStargateRouter.lzTxObj memory _lzTxParams,
        bytes memory _payload
    ) internal {
        bytes memory lzTxParamBuilt = _txParamBuilder(_chainId, _type, _lzTxParams);
        uint64 nextNonce = layerZeroEndpoint.getOutboundNonce(_chainId, address(this)) + 1;
        layerZeroEndpoint.send{value: msg.value}(_chainId, bridgeLookup[_chainId], _payload, _refundAddress, address(this), lzTxParamBuilt);
        emit SendMsg(_type, nextNonce);
    }

    function renounceOwnership() public override onlyOwner {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}