// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IRouter.sol";

contract DEXLimitOrder is ReentrancyGuard {
    /*
		Enums
	*/
    enum LimitOrderType {
        GoodTime,
        fillOrKill,
        immOrCancel
    }

    /*
		Structs
	*/

    struct LimitOrder {
        address inTokenAddr;
        address outTokenAddr;
        uint8 orderType;
        address owner;
        bool inBoundToken;
        bool limitOrderStatus;
        uint256 tokenAmt;
        uint256 boundToken;
        uint256 timeStamp;
    }

    /*
		Events
	*/

    event LimitOrderPlaced(
        uint256 limitOrderId,
        uint256 tokenAmt,
        address inTokenAddr,
        address outTokenAddr,
        address owner,
        bool inBoundToken,
        uint256 boundToken,
        uint256 timeStamp,
        uint8 orderType
    );

    event LimitOrderCancelled(
        uint256 limitOrderId
    );

    event LimitOrderExecuted (
        uint256 limitOrderId
    );

    event LimitOrderNotExecuted (
        uint256 limitOrderId
    );

    event LimitOrderEnded (
        uint256 limitOrderId
    );

    /*
		State Variables
	*/
    uint256 private limitOrderId = 0;
    address wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;


    /*
		Mappings
	*/

    mapping(uint256 => LimitOrder) private _limitOrders;

    IRouter public uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    /*
		External Functions
	*/

    /**
    * @dev List limit order for token
     */
    function limitOrderListing(
        bool inBoundToken,
        uint256 inAmt,
        address inTokenAddr,
        address outTokenAddr,
        uint256 outAmt,
        uint256 timeStamp,
        uint8 orderType
    ) external
    nonReentrant payable 
    {
        // uint256 boundToken = inBoundToken == true ? minOrMaxAmt : msg.value; //boundToken(minOutormaxIn)
        // uint256 tokenAmt = inBoundToken == true ? msg.value : minOrMaxAmt;
        // uint256 amt = inBoundToken == true ? tokenAmt : minOrMaxAmt;
        _safeTransferFrom(inTokenAddr, msg.sender, address(this), inAmt);
        LimitOrder memory limitOrder = LimitOrder(
            inTokenAddr,
            outTokenAddr,
            orderType,
            msg.sender,
            inBoundToken,
            false,
            inAmt,
            outAmt,
            timeStamp
        );

        limitOrderId++;

        _limitOrders[limitOrderId] = limitOrder;

        emit LimitOrderPlaced(limitOrderId, inAmt, inTokenAddr, outTokenAddr, msg.sender, inBoundToken, outAmt, timeStamp, orderType);
    }

    /**
    * @dev List limit order for eth swap
     */
    function limitOrderListingEth(
        address outTokenAddr,
        uint256 outAmt,
        uint256 timeStamp,
        uint8 orderType,
        bool inBoundToken
    ) external
    nonReentrant payable 
    {
        // uint256 amt = inBoundToken == true ? msg.value : boundToken;
        // _safeTransferFrom(wethAddress, msg.sender, address(this), amt);
        // uint256 boundToken = inBoundToken == true ? minOrMaxAmt : msg.value; //boundToken(minOutormaxIn)
        // uint256 tokenAmt = inBoundToken == true ? msg.value : minOrMaxAmt;
        LimitOrder memory limitOrder = LimitOrder(
            wethAddress,
            outTokenAddr,
            orderType,
            msg.sender,
            inBoundToken,
            false,
            msg.value,
            outAmt,
            timeStamp
        );

        limitOrderId++;

        _limitOrders[limitOrderId] = limitOrder;

        emit LimitOrderPlaced(limitOrderId, msg.value, wethAddress, outTokenAddr, msg.sender, inBoundToken, outAmt, timeStamp, orderType);
    }

    /**
    * @dev able to cancel listing if swap not settled
     */
    function cancelLimitOrderListing(uint256 orderId
    ) external
    nonReentrant payable 
	{
        LimitOrder storage limitOrder = _limitOrders[orderId];

        require(limitOrder.limitOrderStatus == true, "Already settled");
        require(msg.sender == limitOrder.owner, "ONLY_OWNER");
        delete _limitOrders[orderId];
        uint256 amt = limitOrder.inBoundToken == true ? limitOrder.tokenAmt : limitOrder.boundToken;
        if (limitOrder.inTokenAddr == wethAddress) {
            (bool sent,) = msg.sender.call{value: msg.value}("");
            require(sent, "Failed to send ether");
        }
        _safeTransferFrom(limitOrder.inTokenAddr, address(this), msg.sender, amt);

        emit LimitOrderCancelled(limitOrderId);
    }

    /**
    * @dev Execute swap for the called ids
     */
    function executeSwap(address payable _addr, uint256[] memory limitOrderIds
    ) external
    nonReentrant payable 
    {
        for (uint i = 0; i < limitOrderIds.length; i++) {
            LimitOrder storage limitOrder = _limitOrders[limitOrderIds[i]];
            uint[] memory amounts;
            bool success;
            bytes memory data;
            address[] memory path = new address[](2);
            path[0] = limitOrder.inTokenAddr == wethAddress ? wethAddress : limitOrder.inTokenAddr;
            path[1] = limitOrder.outTokenAddr;
            if(((limitOrder.orderType == 1 || limitOrder.orderType == 3) && block.timestamp >= limitOrder.timeStamp)|| limitOrder.orderType == 2) {
                if(limitOrder.inBoundToken == true) {
                    amounts = uniRouter.getAmountsOut(limitOrder.tokenAmt, path);
                    if(amounts[amounts.length - 1] >= limitOrder.boundToken) {
                        if(limitOrder.inTokenAddr == wethAddress) {
                            (success,) = _addr.call{value: limitOrder.tokenAmt,gas:10000000}(
                            abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)", 
                            limitOrder.boundToken,
                            path,
                            limitOrder.owner,
                            block.timestamp+600)
                        );
                            if(!success) emit LimitOrderNotExecuted(limitOrderIds[i]);
                            else {
                                    limitOrder.limitOrderStatus = true;
                                    emit LimitOrderExecuted(limitOrderIds[i]);
                                }
                        }
                        else if(limitOrder.outTokenAddr == wethAddress) {
                        IERC20(limitOrder.inTokenAddr).approve(_addr, limitOrder.tokenAmt);
                        (success,) = _addr.call{gas:10000000}(
                            abi.encodeWithSignature("swapExactTokensForETH(uint256,uint256,address[],address,uint256)", 
                            limitOrder.tokenAmt,
                            limitOrder.boundToken,
                            path,
                            limitOrder.owner,
                            block.timestamp+600)
                        );
                            if(!success) emit LimitOrderNotExecuted(limitOrderIds[i]);    
                            else {
                                    limitOrder.limitOrderStatus = true;
                                    emit LimitOrderExecuted(limitOrderIds[i]);
                                }
                        }
                        else {
                        IERC20(limitOrder.inTokenAddr).approve(_addr, limitOrder.tokenAmt);
                        (success,) = _addr.call{gas:10000000}(
                            abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)", 
                            limitOrder.tokenAmt,
                            limitOrder.boundToken,
                            path,
                            limitOrder.owner,
                            block.timestamp+600)
                        );
                            if(!success) emit LimitOrderNotExecuted(limitOrderIds[i]); 
                            else {
                                    limitOrder.limitOrderStatus = true;
                                    emit LimitOrderExecuted(limitOrderIds[i]);
                                }
                        }
                    }
                    else {
                        emit LimitOrderNotExecuted(limitOrderIds[i]);
                    }
                }
                else {
                    amounts = uniRouter.getAmountsIn(limitOrder.tokenAmt, path);
                    if(amounts[amounts.length - 1] <= limitOrder.boundToken) {
                        if(limitOrder.inTokenAddr == wethAddress) {
                            (success, data) = _addr.call{value: limitOrder.tokenAmt,gas:10000000}(
                            abi.encodeWithSignature("swapETHForExactTokens(uint256,address[],address,uint256)", 
                            limitOrder.tokenAmt,
                            path,
                            limitOrder.owner,
                            block.timestamp+600)
                            );
                                if(!success) emit LimitOrderNotExecuted(limitOrderIds[i]);
                                else {
                                    (uint256[] memory amountUsed) = abi.decode(data, (uint[]));
                                    uint256 amountRemaining = SafeMath.sub(limitOrder.boundToken, amountUsed[0]);
                                    if(amountRemaining > 0) _transfer(limitOrder.owner, amountRemaining);
                                    limitOrder.limitOrderStatus = true;
                                    emit LimitOrderExecuted(limitOrderIds[i]);
                                }
                        }            
                        else if(limitOrder.outTokenAddr == wethAddress) {
                            IERC20(limitOrder.inTokenAddr).approve(_addr, limitOrder.tokenAmt);
                            (success, data) = _addr.call{gas:10000000}(
                            abi.encodeWithSignature("swapTokensForExactETH(uint256,uint256,address[],address,uint256)",
                            limitOrder.tokenAmt,
                            limitOrder.boundToken,
                            path,
                            limitOrder.owner,
                            block.timestamp+600)
                            );
                                if(!success) emit LimitOrderNotExecuted(limitOrderIds[i]);
                                else {
                                    (uint256[] memory amountUsed) = abi.decode(data, (uint[]));
                                    uint256 amountRemaining = SafeMath.sub(limitOrder.boundToken, amountUsed[0]);
                                    if(amountRemaining > 0) _transfer(limitOrder.owner, amountRemaining);
                                    limitOrder.limitOrderStatus = true;
                                    emit LimitOrderExecuted(limitOrderIds[i]);
                                }
                        }
                        else {
                            IERC20(limitOrder.inTokenAddr).approve(_addr, limitOrder.tokenAmt);
                            (success,) = _addr.call{gas:10000000}(
                            abi.encodeWithSignature("swapTokensForExactTokens(uint256,uint256,address[],address,uint256)",
                            limitOrder.tokenAmt,
                            limitOrder.boundToken,
                            path,
                            limitOrder.owner,
                            block.timestamp+600)
                            );
                                if(!success) emit LimitOrderNotExecuted(limitOrderIds[i]);
                                else {
                                    (uint256[] memory amountUsed) = abi.decode(data, (uint[]));
                                    uint256 amountRemaining = SafeMath.sub(limitOrder.boundToken, amountUsed[0]);
                                    if(amountRemaining > 0) _transfer(limitOrder.owner, amountRemaining);
                                    limitOrder.limitOrderStatus = true;
                                    emit LimitOrderExecuted(limitOrderIds[i]);
                                }
                        }
                    }
                    else {
                        emit LimitOrderNotExecuted(limitOrderIds[i]);
                    }
                }
            }
            else {
                emit LimitOrderEnded(limitOrderIds[i]);
            }
        }
    }

    /*
		Internal Functions
	*/

	function _transfer(address to, uint256 amount) internal {
		(bool success, ) = payable(to).call{value: amount}("");
        require(success, "TRANSFER_FAILED");
	}

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safeTransferFrom: Transfer failed"
        );
    }

    /*
		Getters
	*/

    /**
    * @dev Get limit order detail
     */
    function getLimitOrder(uint256 orderId)
        public
        view
        returns (LimitOrder memory)
    {
        return _limitOrders[orderId];
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
pragma solidity ^0.8.7;

interface IRouter {
    function getAmountsOut(uint , address[] memory) external returns (uint[] memory);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
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
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}