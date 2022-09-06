/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: DexOrderTypes.sol


pragma solidity ^0.8.7;


contract DEXOrderTypes is ReentrancyGuard {
    enum OrderType {
        LIMIT_ORDER_SELL,
        LIMIT_ORDER_BUY,
        TAKE_PROFIT_LIMIT,
        TAKE_PROFIT_MARKET,
        STOP_LIMIT_BUY,
        STOP_LIMIT_SELL,
        STOP_MARKET_BUY,
        STOP_MARKET_SELL
    }

    enum OrderStatus {
        PENDING,
        REJECTED,
        PARTIALLY_FILLED,
        COMPLETE,
        EXPIRED
    }

    struct Order {
        OrderType orderType;
        uint256 tokenAmount;
        address inTokenAddress;
        address outTokenAddress;
        address owner;
        uint256 limit;
        uint256 stop;
        uint timestamp;
        OrderStatus orderStatus;
    }

    event OrderPlaced(      
        uint256 orderId, 
        OrderType orderType,
        uint256 tokenAmount,
        address inTokenAddress,
        address outTokenAddress,
        address owner,
        uint256 limit,
        uint256 stop,
        uint timestamp,
        OrderStatus orderStatus
    );

    /*
		State Variables
	*/
    uint256 private totalOrdersPlaced = 0;
    address zeroAddress = 0x0000000000000000000000000000000000000000;


    /*
		Mappings
	*/

    mapping(uint256 => Order) public orders;

    function limitOrderListing(
        OrderType orderType,
        uint256 tokenAmount,
        address inTokenAddress,
        address outTokenAddress,
        uint256 limit,
        uint256 stop
    ) external
    nonReentrant payable 
    {
        _safeTransferFrom(inTokenAddress, msg.sender, address(this), tokenAmount);
        uint256 timestamp = block.timestamp;
        Order memory order = Order(
            orderType,
            tokenAmount,
            inTokenAddress,
            outTokenAddress,
            msg.sender,
            limit,
            stop,
            timestamp,
            OrderStatus.PENDING
        );

        totalOrdersPlaced++;

        orders[totalOrdersPlaced] = order;

        emit OrderPlaced(
            totalOrdersPlaced,
            orderType,
            tokenAmount,
            inTokenAddress,
            outTokenAddress,
            msg.sender,
            limit,
            stop,
            timestamp,
            OrderStatus.PENDING
        );
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
}