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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IPaymentController {
    
    event PaymentReceived(
        string paymentId,
        address indexed sender,
        uint spendingTokenAmount,
        uint baseTokenAmount
    );
    
    function getPathForToken(address token_) external view returns (address[] memory);
    function getEstimate(
        address[] memory path, 
        uint baseTokenPrice
    ) external view returns (uint[] memory estimatedPrice);
    function processPayment(
        string memory paymentId,
        address offeredToken, 
        uint amountInMax, 
        uint amountOut, 
        address[] memory path_
    ) external returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IPaymentController.sol";

//TODO: remove before deployment
// import "hardhat/console.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (
        uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast
    );
}

interface IUniswapV2Router02 {
    function getAmountsIn(
        uint amountOut, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract PaymentController is IPaymentController {
    
    bool private _initialised = false;
    address private _defaultAdminAddress;

    address private _uniswapFactoryAddress;
    IUniswapV2Router02 private _uniswapRouter;
    address private _baseToken;

    constructor () {
        _defaultAdminAddress = msg.sender;
    }

    function init(
        address uniswapRouterAddress_,
        address uniswapFactoryAddress_,
        address baseToken_
    ) public {
        require(msg.sender == _defaultAdminAddress, "Caller is not an admin");
        require(!_initialised, "Already initialised");
        
        _uniswapFactoryAddress = uniswapFactoryAddress_;
        _uniswapRouter = IUniswapV2Router02(uniswapRouterAddress_);
        _baseToken = baseToken_;

        _initialised = true;
    }

    function getPathForToken(address token_) public view override returns (address[] memory) {
        //TODO check if path possible
        
        address[] memory path = new address[](2);
        path[0] = token_;
        // path[0] = _uniswapRouter.WETH();
        path[1] = _baseToken;
        return path;
    }

    function getEstimate(address[] memory path_, uint baseTokenPrice_) public view override returns (uint[] memory estimatedPrice) {
        return _uniswapRouter.getAmountsIn(baseTokenPrice_, path_);
    }

    function processPayment(
        string memory paymentId,
        address offeredToken_,
        uint amountInMax_,
        uint amountOut_,
        address[] memory path_
    ) public override returns (bool){
        
        IERC20 token = IERC20(offeredToken_);
        token.transferFrom(msg.sender, address(this), amountInMax_);
        token.approve(address(_uniswapRouter), amountInMax_);

        uint[] memory amounts = _uniswapRouter.swapTokensForExactTokens(
            amountOut_,
            amountInMax_,
            path_,
            address(this),
            block.timestamp + 300
        );

        //TODO: distribute payment to founder, stakeholder, merchant
        emit PaymentReceived(
            paymentId, 
            msg.sender, 
            amounts[0], 
            amounts[1]
        );
        return true;
    }

}