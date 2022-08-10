pragma solidity ^0.8.0;

import "../interfaces/ISwapRouter01.sol";
import "../interfaces/ISwapRouter02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TradeIn is Ownable {
    address public sbx;
    address public feeReceiver;
    uint256 public feePercent;
    uint256 public tolerance;
    bool public isTradeInEnabled;
    bool public isAssetControlled;
    bool public isRouterControlled;

    mapping(address => bool) public allowedAssets;
    mapping(address => bool) public allowedRouters;

    event Swap(
        address owner,
        address assetToSwap,
        address router,
        uint256 amountIn,
        uint256 fee,
        uint256 amountOut
    );

    constructor(
        address sbx_,
        address feeReceiver_,
        uint256 feePercent_
    ) {
        sbx = sbx_;
        feeReceiver = feeReceiver_;
        feePercent = feePercent_;
        tolerance = 7500;
    }

    function changeAssetControl() external onlyOwner {
        isAssetControlled = !isAssetControlled;
    }

    function changeRouterControl() external onlyOwner {
        isRouterControlled = !isRouterControlled;
    }

    function changeTradeInEnabled() external onlyOwner {
        isTradeInEnabled = !isTradeInEnabled;
    }

    function changeFeePercent(uint256 newFeePercent_) external onlyOwner {
        require(
            newFeePercent_ <= 10000,
            "TradeIn: Value cannot be more than 100% (10000)"
        );
        feePercent = newFeePercent_;
    }

    function changeFeeReceiver(address newFeeReceiver_) external onlyOwner {
        require(
            newFeeReceiver_ != feeReceiver,
            "TradeIn: This address has been already fee receiver"
        );
        require(
            newFeeReceiver_ != address(0),
            "TradeIn: Zero address is not allowed"
        );
        feeReceiver = newFeeReceiver_;
    }

    function changeAllowedAsset(address assetAddress, bool isAllowed)
        external
        onlyOwner
    {
        require(
            assetAddress != address(0),
            "TradeIn: Zero address is not allowed"
        );
        allowedAssets[assetAddress] = isAllowed;
    }

    function changeAllowedRouter(address router, bool isAllowed)
        external
        onlyOwner
    {
        require(router != address(0), "TradeIn: Zero address is not allowed");
        allowedRouters[router] = isAllowed;
    }

    function changeTolerance(uint256 tolerance_) external onlyOwner {
        require(
            tolerance_ <= 10000,
            "TradeIn: Value cannot be more than 100% (10000)"
        );
        tolerance = tolerance_;
    }

    function swap(
        address assetToSwap,
        address router,
        uint256 amount
    ) external {
        // require(isTradeInEnabled, "TradeIn: TradeIn is not enabled");
        require(
            IERC20(sbx).totalSupply() > 0 &&
                IERC20(sbx).totalSupply() >= amount,
            "TradeIn: Not enough tokens in the smart contract"
        );
        if (isAssetControlled) {
            require(
                allowedAssets[assetToSwap],
                "TradeIn: Asset is not allowed"
            );
        }
        if (isRouterControlled) {
            require(allowedRouters[router], "TradeIn: Router is not allowed");
        }
        require(amount > 0, "TradeIn: Zero amount is not allowed");
        require(
            IERC20(assetToSwap).allowance(msg.sender, address(this)) >= amount,
            "TradeIn: Not enough allowance"
        );
        require(
            IERC20(assetToSwap).balanceOf(msg.sender) >= amount,
            "TradeIn: Not enough balance"
        );

        IERC20(assetToSwap).transferFrom(msg.sender, address(this), amount);

        uint256 prevBalance = IERC20(sbx).balanceOf(address(this));
        _swap(assetToSwap, router, amount);
        uint256 currBalance = IERC20(sbx).balanceOf(address(this));
        uint256 balance = currBalance - prevBalance;
        uint256 fee = (balance * feePercent) / 10000;
        IERC20(sbx).transfer(msg.sender, balance - fee);
        IERC20(sbx).transfer(feeReceiver, fee);
        emit Swap(msg.sender, assetToSwap, router, amount, fee, balance - fee);
    }

    function estimate(
        address assetToSwap,
        address router_,
        uint256 amount
    ) external view returns (uint256 returnAmount) {
        ISwapRouter02 router = ISwapRouter02(router_);
        address[] memory path = new address[](2);
        path[0] = assetToSwap;
        path[1] = sbx;
        uint256[] memory amountsOut = router.getAmountsOut(amount, path);
        uint256 fee = amountsOut[1] * feePercent / 10000;
        returnAmount = amountsOut[1] - fee;
    }

    function _swap(
        address assetToSwap,
        address routerAddress,
        uint256 amount
    ) internal {
        IERC20(assetToSwap).approve(routerAddress, amount);
        ISwapRouter02 router = ISwapRouter02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = assetToSwap;
        path[1] = sbx;
        // uint256[] memory amountsOut = router.getAmountsOut(amount, path);
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}

pragma solidity ^0.8.0;

interface ISwapRouter01 {
    function WETH9() external pure returns (address);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint256[] memory amounts);
}

pragma solidity ^0.8.0;

interface ISwapRouter02 {
  function WETH() external pure returns (address);
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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