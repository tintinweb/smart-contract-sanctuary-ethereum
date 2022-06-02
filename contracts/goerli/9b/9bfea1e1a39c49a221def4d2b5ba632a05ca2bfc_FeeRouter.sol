/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: UNLICENSED

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol


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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.8.10;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: contracts/interfaces/IRouter.sol

pragma solidity 0.8.10;

interface IRouter {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
        external 
        returns (uint[] memory amounts);
}

// File: contracts/interfaces/IFeeTransfer.sol

pragma solidity 0.8.10;

interface IFeeTransfer {
    function setRouter(IRouter _router) external;
    function feeReceiver() external view returns (address);
    function minimumAmountToSwapInToken() external view returns (uint);
    function getAmountInTokensWithFee(uint amountInNoFee, address[] calldata _path) external view returns (uint);
    function getAmountInTokensNoFee(uint amountInWithFee, address[] calldata _path) external view returns (uint);
    function getAmountInETHWithFee(uint amountInNoFee) external view returns (uint);
    function getAmountInETHNoFee(uint amountInWithFee) external view returns (uint);
    function convertTokenToETH(uint amount) external view returns (uint);
}

// File: contracts/FeeRouter.sol

pragma solidity 0.8.10;

contract FeeRouter is Context, Ownable {
    uint constant VALUE_FEE_MUL_FACTOR = 99000;
    uint constant VALUE_FEE_DIV_FACTOR = 100000;
    uint constant TOKEN_VALUE_FEE_MUL_FACTOR = 98000;
    uint constant private APPROVE_MAX = type(uint256).max;
    IRouter public routerContract;
    IFeeTransfer public feeTransferContract;

    event SwapTokensForETH(address indexed from, address indexed to, address tokenIn, uint256 amountInWithFee, uint256 amountOut, uint256 fee);
    event SwapETHForTokens(address indexed from, address indexed to, address tokenIn, uint256 amountInWithFee, uint256 amountOut, uint256 fee);
    event SwapTokensForTokens(address indexed from, address indexed to, address tokenIn, uint256 amountInWithFee, uint256 amountOut, uint256 fee);

    constructor(IRouter _router, IFeeTransfer _transfer) Ownable() {
        routerContract = _router;
        feeTransferContract = _transfer;
    }

    function setRouter(IRouter _router) public onlyOwner {
        routerContract = _router;
    }

    function setFeeTransfer(IFeeTransfer _transfer) public onlyOwner {
        feeTransferContract = _transfer;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts) {
        return routerContract.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts) {
        return routerContract.getAmountsIn(amountOut, path);
    }

    function getAmountInETHWithFee(uint amountInNoFee, address[] calldata path) public view returns (uint) {
        return feeTransferContract.getAmountInETHWithFee(amountInNoFee);
    }

    function getAmountInETHNoFee(uint amountInWithFee, address[] calldata path) public view returns (uint) {
        return feeTransferContract.getAmountInETHNoFee(amountInWithFee);
    }

    function getAmountInTokensWithFee(uint amountInNoFee, address[] calldata path) public view returns (uint) {
        return feeTransferContract.getAmountInTokensWithFee(amountInNoFee, path);
    }

    function getAmountInTokensNoFee(uint amountInWithFee, address[] calldata path) public view returns (uint) {
        return feeTransferContract.getAmountInTokensNoFee(amountInWithFee, path);
    }

    function getMinimumFeeInToken() public view returns (uint) {
        return feeTransferContract.minimumAmountToSwapInToken();
    }

    function getMinimumFeeInETH() public view returns (uint) {
        return feeTransferContract.convertTokenToETH(feeTransferContract.minimumAmountToSwapInToken());
    }

    function WETH() public view returns (address) {
        return routerContract.WETH();
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        require(amountOutMin > 0, "FeeRouter: INSUFFICIENT_AMOUNT_OUT");
        require(msg.value > 0, "FeeRouter: INSUFFICIENT_VALUE");
        uint amountInNoFee = getAmountInETHNoFee(msg.value, path);
        uint fee = msg.value - amountInNoFee;
        TransferHelper.safeTransferETH(feeTransferContract.feeReceiver(), fee);
        uint[] memory result = routerContract.swapExactETHForTokens{value: amountInNoFee}(amountOutMin, path, to, deadline);
        emit SwapETHForTokens(_msgSender(), to, path[0], msg.value, result[result.length - 1], fee);
        return result;
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(amountOutMin > 0, "FeeRouter: INSUFFICIENT_AMOUNT_OUT");
        require(amountIn > 0, "FeeRouter: INSUFFICIENT_AMOUNT_IN");
        uint amountInNoFee = getAmountInTokensNoFee(amountIn, path);
        uint fee = amountIn - amountInNoFee;
        IERC20 tokenContract = IERC20(address(path[0]));
        TransferHelper.safeTransferFrom(address(tokenContract), _msgSender(), address(this), amountIn);
        TransferHelper.safeTransfer(address(tokenContract), feeTransferContract.feeReceiver(), fee);
        tokenContract.approve(address(routerContract), amountInNoFee);
        uint[] memory result = routerContract.swapExactTokensForETH(amountInNoFee, amountOutMin, path, to, deadline);
        emit SwapTokensForETH(_msgSender(), to, path[0], amountIn, result[result.length - 1], fee);
        return result;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(amountOutMin > 0, "FeeRouter: INSUFFICIENT_AMOUNT_OUT");
        require(amountIn > 0, "FeeRouter: INSUFFICIENT_AMOUNT_IN");
        uint amountInNoFee = getAmountInTokensNoFee(amountIn, path);
        uint fee = amountIn - amountInNoFee;
        IERC20 tokenContract = IERC20(address(path[0]));
        TransferHelper.safeTransferFrom(address(tokenContract), _msgSender(), address(this), amountIn);
        TransferHelper.safeTransfer(address(tokenContract), feeTransferContract.feeReceiver(), fee);
        tokenContract.approve(address(routerContract), amountInNoFee);
        uint[] memory result = routerContract.swapExactTokensForTokens(amountInNoFee, amountOutMin, path, to, deadline);
        emit SwapTokensForTokens(_msgSender(), to, path[0], amountIn, result[result.length - 1], fee);
        return result;
    }
}