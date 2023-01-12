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

//SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.15;

/**
 * IToadRouter01
 * 
 * Interface for a trusted toad router
 * 
 * 
 */
abstract contract IToadRouter01  {
    string public versionRecipient = "3.0.0";
    address public immutable factory;
    address public immutable WETH;

    constructor(address fac, address weth) {
        factory = fac;
        WETH = weth;
    }

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns(uint256 outputAmount);
    function swapExactTokensForWETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns (uint[] memory amounts);

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns(uint256 outputAmount);
    function swapExactWETHforTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns (uint[] memory amounts);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn, address[] calldata gasPath) external virtual returns(uint256 outputAmount);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn, address[] calldata gasPath) external virtual returns (uint[] memory amounts);

    function unwrapWETH(address to, uint256 amount, uint256 gasReturn) external virtual;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view virtual returns (uint[] memory amounts);
}

pragma solidity ^0.8.15;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
import "./IToadRouter01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * ToadRouter01
 * A re-implementation of the Uniswap v2 router with bot-driven meta-transactions.
 * Bot private keys are all stored on a hardware wallet. 
 */
contract ToadRouter01 is IToadRouter01, Ownable {
    mapping(address => bool) allowedBots;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ToadRouter: EXPIRED');
        _;
    }


    modifier onlyBot() {
        require(allowedBots[msg.sender], "ToadRouter: UNTRUSTED");
        _;
    }

    constructor(address fac, address weth) IToadRouter01(fac, weth) {
        // Do any other stuff necessary
        // Add sender to allowedBots
        allowedBots[msg.sender] = true;
    }

    function addTrustedBot(address newBot) external onlyOwner {
        allowedBots[newBot] = true;
    }
    function removeTrustedBot(address bot) external onlyOwner {
        allowedBots[bot] = false;
    }

    receive() external payable {
        if(msg.sender != WETH) {
            revert("ToadRouter: No ETH not from WETH.");
        }
    }

    
    // We assume we can swap without fee on transfer here
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 gasReturn,
        address[] calldata gasPath
    ) external virtual override ensure(deadline) onlyBot() returns (uint[] memory amounts) {
        if(gasReturn > 0) {
        // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
            uint[] memory gasAmounts = UniswapV2Library.getAmountsOut(factory, gasReturn, gasPath);
            TransferHelper.safeTransferFrom(gasPath[0], to, UniswapV2Library.pairFor(factory, gasPath[0], gasPath[1]), gasReturn);
            _swap(gasAmounts, gasPath, address(this));
            IWETH(WETH).withdraw(gasAmounts[gasAmounts.length-1]);
            TransferHelper.safeTransferETH(tx.origin, gasAmounts[gasAmounts.length-1]);
        }
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn-gasReturn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);

    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 gasReturn,
        address[] calldata gasPath
    ) external virtual override ensure(deadline) onlyBot() returns(uint256 outputAmount) {
        if(gasReturn > 0) {
            // Swap the gasReturn tokens from their wallet to us as WETH, unwrap and send to tx origin
        uint balanceBef = IERC20(WETH).balanceOf(address(this));
        TransferHelper.safeTransferFrom(gasPath[0], to, UniswapV2Library.pairFor(factory, gasPath[0], gasPath[1]), gasReturn);
        _swapSupportingFeeOnTransferTokens(gasPath, address(this));
        outputAmount = IERC20(WETH).balanceOf(address(this)) - balanceBef;
        IWETH(WETH).withdraw(outputAmount);
        TransferHelper.safeTransferETH(tx.origin, outputAmount);
        }
        
        // Swap remaining tokens to the path provided
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn-gasReturn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - (balanceBefore) >= amountOutMin,
            'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        
    }


    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual override ensure(deadline) onlyBot() returns(uint256 outputAmount) {
        require(path[0] == WETH, 'ToadRouter: INVALID_PATH');
        // Send us gas first
        if(gasReturn > 0) {
            TransferHelper.safeTransferFrom(WETH, to, address(this), gasReturn);
            // Pay the relayer
            IWETH(WETH).withdraw(gasReturn);
            TransferHelper.safeTransferETH(tx.origin, gasReturn);
        }
        // Send to first pool
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn-gasReturn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        outputAmount = IERC20(path[path.length - 1]).balanceOf(to) - (balanceBefore);
        require(
            outputAmount >= amountOutMin,
            'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );

    }
    function swapExactWETHforTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual override ensure(deadline) onlyBot() returns (uint[] memory amounts) {
        require(path[0] == WETH, 'ToadRouter: INVALID_PATH');
        // Send us gas first
        TransferHelper.safeTransferFrom(WETH, to, address(this), gasReturn);
        // Do the amount calcs
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn-gasReturn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
        // Pay gas out
        if(gasReturn > 0) {
            IWETH(WETH).withdraw(gasReturn);
            TransferHelper.safeTransferETH(tx.origin, gasReturn);
        }
    }

    function swapExactTokensForWETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn)
        external
        virtual
        override
        ensure(deadline) 
        onlyBot()
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'ToadRouter: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        TransferHelper.safeTransfer(WETH, to, amounts[amounts.length - 1]-gasReturn);
        // Pay gas
        if(gasReturn > 0) {
            IWETH(WETH).withdraw(gasReturn);
            TransferHelper.safeTransferETH(tx.origin, gasReturn);
        }
        
    }
    
    function swapExactTokensForWETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint256 gasReturn
    )
        external
        virtual
        override
        ensure(deadline) onlyBot() returns(uint256 outputAmount)
    {
        require(path[path.length - 1] == WETH, 'ToadRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], to, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        // Adjust output amount to be exclusive of the payout of gas
        outputAmount = amountOut - gasReturn;
        require(outputAmount >= amountOutMin, 'ToadRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        // Give the WETH to the holder
        TransferHelper.safeTransfer(WETH, to, outputAmount);
        // Pay the relayer
        IWETH(WETH).withdraw(gasReturn);
        TransferHelper.safeTransferETH(tx.origin, gasReturn);
    }

    // Gasloan WETH unwrapper
    function unwrapWETH(address to, uint256 amount, uint256 gasReturn) onlyBot() external virtual override {
        IERC20(WETH).transferFrom(to, address(this), amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(tx.origin, gasReturn);
        TransferHelper.safeTransferETH(to, amount-gasReturn);
    }



    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        
        }
    }

    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    
}

//SPDX-License-Identifier: GPL-3.0
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
pragma solidity ^0.8.15;
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

/**
 * Modified version of the UniswapV2Library to use inbuilt SafeMath
 */
//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {


    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }



    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * (reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}