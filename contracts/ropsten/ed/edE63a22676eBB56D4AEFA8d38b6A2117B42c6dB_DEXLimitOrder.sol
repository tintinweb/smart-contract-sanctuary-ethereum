// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
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
        bool limitOrderStatus;
        uint256 tokenAmt;
        address inTokenAddr;
        address outTokenAddr;
        address owner;
        uint256 minToken;
        uint timeStamp;
        uint orderType;
    }

    /*
		Events
	*/

    event LimitOrderPlaced(
        uint256 _limitOrderId,
        uint256 tokenAmt,
        address inTokenAddr,
        address outTokenAddr,
        address owner,
        uint256 minToken,
        uint timeStamp,
        uint orderType
    );

    event CancelOrder(
        uint256 _limitOrderId,
        address owner
    );

    event OrderExecuted (
        uint timestamp,
        uint amountIn,
        uint amountOut,
        address[] path,
        address sender
    );

    /*
		State Variables
	*/
    uint256 private _limitOrderId = 0;
    address zeroAddress = 0x0000000000000000000000000000000000000000;


    /*
		Mappings
	*/

    mapping(uint256 => LimitOrder) private _limitOrders;

    IRouter public uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    /*
		External Functions
	*/

    function limitOrderListing(
        uint256 tokenAmt,
        address inTokenAddr,
        address outTokenAddr,
        uint256 minToken,
        uint timeStamp,
        uint orderType
    ) external
    nonReentrant payable 
    {
        _safeTransferFrom(inTokenAddr, msg.sender, address(this), tokenAmt);
        LimitOrder memory limitOrder = LimitOrder(
            false,
            tokenAmt,
            inTokenAddr,
            outTokenAddr,
            msg.sender,
            minToken,
            timeStamp,
            orderType
        );

        _limitOrderId++;

        _limitOrders[_limitOrderId] = limitOrder;

        emit LimitOrderPlaced(_limitOrderId, tokenAmt, inTokenAddr, outTokenAddr, msg.sender, minToken, timeStamp, orderType);
    }

    function limitOrderListingEth(
        address outTokenAddr,
        uint256 minToken,
        uint timeStamp,
        uint orderType
    ) external
    nonReentrant payable 
    {
        _safeTransferFrom(zeroAddress, msg.sender, address(this), msg.value);
        LimitOrder memory limitOrder = LimitOrder(
            false,
            msg.value,
            zeroAddress,
            outTokenAddr,
            msg.sender,
            minToken,
            timeStamp,
            orderType
        );

        _limitOrderId++;

        _limitOrders[_limitOrderId] = limitOrder;

        emit LimitOrderPlaced(_limitOrderId, msg.value, zeroAddress, outTokenAddr, msg.sender, minToken, timeStamp, orderType);
    }

    function cancelLimitOrderListing(uint256 limitOrderId
    ) external
    nonReentrant payable 
	{
        LimitOrder storage limitOrder = _limitOrders[limitOrderId];

        require(limitOrder.limitOrderStatus == true, "Already settled");
        require(msg.sender == limitOrder.owner, "ONLY_OWNER");
        delete _limitOrders[limitOrderId];
        _safeTransferFrom(limitOrder.inTokenAddr, address(this), msg.sender, limitOrder.tokenAmt);

        emit CancelOrder(_limitOrderId, msg.sender);
    }

    function executeSwap(uint256[] memory limitOrderIds
    ) external
    nonReentrant payable 
    {
        for (uint i = 0; i < limitOrderIds.length; i++) {
            LimitOrder storage limitOrder = _limitOrders[limitOrderIds[i]];
            address weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
            address[] memory path = new address[](2);
            path[0] = limitOrder.inTokenAddr == zeroAddress ? weth : limitOrder.inTokenAddr;
            path[1] = limitOrder.outTokenAddr;
            uint[] memory amounts = uniRouter.getAmountsOut(limitOrder.tokenAmt, path);
            require(amounts[amounts.length - 1] >= limitOrder.minToken, 'Insufficient output amount');
            if(limitOrder.inTokenAddr == zeroAddress) {
                uniRouter.swapExactETHForTokens{value: limitOrder.tokenAmt}(limitOrder.minToken, path, limitOrder.owner, block.timestamp+600);
            }            
            else if(limitOrder.outTokenAddr == zeroAddress) {
                uniRouter.swapTokensForExactETH(limitOrder.minToken, limitOrder.tokenAmt, path, limitOrder.owner, block.timestamp+600);
            }
            else {
                uniRouter.swapExactTokensForTokens(limitOrder.tokenAmt, limitOrder.minToken, path, limitOrder.owner, block.timestamp+600);
            }
            limitOrder.limitOrderStatus = true;
            emit OrderExecuted(block.timestamp+90, limitOrder.tokenAmt, amounts[amounts.length - 1], path, msg.sender);
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

    function getLimitOrder(uint256 limitOrderId)
        public
        view
        returns (LimitOrder memory)
    {
        return _limitOrders[limitOrderId];
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
}