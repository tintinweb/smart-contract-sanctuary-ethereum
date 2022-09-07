// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "../interfaces/IHelixV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";

contract RouterProxy is Ownable {
    address public router;
    address public partner;

    uint256 public partnerPercent;
    uint256 public immutable percentDecimals;

    event SetRouter(address router);
    event SetPartner(address partner);
    event SetPartnerPercent(uint256 partnerPercent);
    event CollectFee(address token, address from, uint256 amount);

    modifier onlyPartner() {
        require(msg.sender == partner, "Caller is not partner");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    modifier onlyValidPartnerPercent(uint256 _partnerPercent) {
        require(_partnerPercent <= percentDecimals, "Invalid partner percent");
        _;
    }

    constructor (address _router, address _partner) 
        onlyValidAddress(_router)
        onlyValidAddress(_partner)
    {
        router = _router;
        partner = _partner;
        partnerPercent = 500; // 0.050%
        percentDecimals = 1e5;  // Use 3 decimals of precision for percents, i.e. 000.000%
    }

    function setRouter(address _router) external onlyOwner onlyValidAddress(_router) {
        router = _router;
        emit SetRouter(_router);
    }

    function setPartner(address _partner) external onlyPartner onlyValidAddress(_partner) {
        partner = _partner;
        emit SetPartner(_partner);
    }

    function setPartnerPercent(uint256 _partnerPercent) 
        external 
        onlyPartner 
        onlyValidPartnerPercent(_partnerPercent) 
    {
        require(_partnerPercent <= percentDecimals, "Invalid partner percent");
        partnerPercent = _partnerPercent;
        emit SetPartnerPercent(_partnerPercent);
    }

    function swapExactTokensForTokens(
        uint256 amountIn, 
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) 
        external
        returns (uint256[] memory amounts)
    {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        uint256 fee = getFee(amountIn);
        amountIn -= fee;
        TransferHelper.safeApprove(path[0], router, amountIn);
        amounts = IHelixV2Router02(router).swapExactTokensForTokens(
            amountIn, 
            amountOutMin, 
            path, 
            to, 
            deadline
        );
        _withdrawErc20(path[0], fee);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts)
    {
        amounts = IHelixV2Router02(router).getAmountsIn(amountOut, path);
        uint256 fee = getFee(amounts[0]);
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0] + fee);  
        TransferHelper.safeApprove(path[0], router, amounts[0]);
        amounts = IHelixV2Router02(router).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        _withdrawErc20(path[0], fee);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) 
        external
        payable
        returns (uint256[] memory amounts) 
    {
        uint256 fee = getFee(msg.value);
        amounts = IHelixV2Router02(router).swapExactETHForTokens{ value: msg.value - fee }(
            amountOutMin,
            path,
            to,
            deadline
        );
        _withdrawEth(fee);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts)
    {
        amounts = IHelixV2Router02(router).getAmountsIn(amountOut, path);
        uint256 fee = getFee(amounts[0]);
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0] + fee);
        TransferHelper.safeApprove(path[0], router, amounts[0]);
        amounts = IHelixV2Router02(router).swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        _withdrawErc20(path[0], fee);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) 
        external
        returns (uint256[] memory amounts)
    {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        uint256 fee = getFee(amountIn);
        amountIn -= fee;
        TransferHelper.safeApprove(path[0], router, amountIn);
        amounts = IHelixV2Router02(router).swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        _withdrawErc20(path[0], fee);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256[] memory amounts)
    {
        amounts = IHelixV2Router02(router).getAmountsIn(amountOut, path);
        uint256 fee = getFee(amounts[0]);
        amounts = IHelixV2Router02(router).swapETHForExactTokens{ value: amounts[0] }(
            amountOut,
            path,
            to,
            deadline
        );
        _withdrawEth(fee);
        if (msg.value > amounts[0] + fee) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - (amounts[0] + fee));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
    {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        uint256 fee = getFee(amountIn);
        amountIn -= fee;
        TransferHelper.safeApprove(path[0], router, amountIn);
        IHelixV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        _withdrawErc20(path[0], fee);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
    {
        uint256 fee = getFee(msg.value);
        IHelixV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value - fee }(
            amountOutMin,
            path,
            to,
            deadline
        );
        _withdrawEth(fee);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )   
        external
    {
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        uint256 fee = getFee(amountIn);
        amountIn -= fee;
        TransferHelper.safeApprove(path[0], router, amountIn);
        IHelixV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        _withdrawErc20(path[0], fee);
    }

    function getFee(uint256 _amount) public view returns(uint256) {
        return _amount * partnerPercent / percentDecimals;
    }

    function _withdrawErc20(address _token, uint256 _amount) private {
        TransferHelper.safeTransfer(_token, partner, _amount);
    }

    function _withdrawEth(uint256 _amount) private {
        TransferHelper.safeTransferETH(partner, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixV2Router01.sol";

interface IHelixV2Router02 is IHelixV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IHelixV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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