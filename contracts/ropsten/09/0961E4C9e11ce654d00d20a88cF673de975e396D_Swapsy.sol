//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISwapsyManager.sol";

contract Swapsy is ReentrancyGuard, Ownable {
    enum STATUS {
        OPEN,
        CANCELLED,
        EXPIRED,
        SUCCESS
    }

    struct SWAPS {
        address seller;
        uint256 amountIn;
        uint256 amountOut;
        address tokenIn;
        address tokenOut;
        uint256 deadline;
        STATUS status;
    }

    uint256 public totalSwaps;
    ISwapsyManager public swapsyManager;
    mapping(uint256 => SWAPS) private _allSwaps;
    mapping(address => SWAPS[]) private _swapsByUser;
    mapping(address => uint256) private _revenue;

    event Sell(
        address indexed seller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 id,
        uint256 deadline
    );
    event Buy(
        address indexed buyer,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 id
    );
    event Cancel(
        address indexed seller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 id
    );
    event Refund(
        address indexed seller,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 id
    );

    constructor(address _swapsyManager) {
        swapsyManager = ISwapsyManager(_swapsyManager);
    }

    function sellETH(
        uint256 amountOut,
        address tokenOut,
        uint256 deadline
    ) public payable nonReentrant {
        require((msg.value > 0) && (amountOut > 0), "Swapsy: zero I/O amount");

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Swapsy: sell order failed");

        _sell(msg.sender, msg.value, amountOut, address(0), tokenOut, deadline);
    }

    function sellToken(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public nonReentrant {
        require((amountIn > 0) && (amountOut > 0), "Swapsy: zero  I/O amount");
        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "Swapsy: sell order failed"
        );

        _sell(msg.sender, amountIn, amountOut, tokenIn, tokenOut, deadline);
    }

    function _sell(
        address seller,
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal {
        require(deadline > block.timestamp, "Swapsy: old time set");

        _allSwaps[totalSwaps] = SWAPS(
            seller,
            amountIn,
            amountOut,
            tokenIn,
            tokenOut,
            deadline,
            STATUS.OPEN
        );
        _swapsByUser[seller].push(_allSwaps[totalSwaps]);

        emit Sell(
            seller,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            totalSwaps++,
            deadline
        );
    }

    function buyWithETH(uint256 id) public payable nonReentrant {
        require(
            msg.value == _allSwaps[id].amountOut,
            "Swapsy: incorrect price"
        );
        require(
            _allSwaps[id].tokenOut == address(0),
            "Swapsy: only for ether price"
        );

        _buy(id);
    }

    function buyWithToken(uint256 id) public nonReentrant {
        require(
            _allSwaps[id].tokenOut != address(0),
            "Swapsy: only for token price"
        );

        _buy(id);
    }

    function _buy(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.status == STATUS.OPEN, "Swapsy: unavailable swap");
        require(_swaps.deadline >= block.timestamp, "Swapsy: expired swap");

        /* Buyer pays and transfers amount to the seller */
        uint256 sellerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 sellerFeeAmt = (_swaps.amountOut * sellerFee) / 1000;
        uint256 sellerTransAmt = _swaps.amountOut - sellerFeeAmt;
        
        _revenue[_swaps.tokenOut] += sellerFeeAmt;
        if (_swaps.tokenOut == address(0)) {
            (bool toSeller, ) = payable(_swaps.seller).call{value: sellerTransAmt}("");
            require(toSeller, "Swapsy: payment failed");

            (bool toPlatform, ) = payable(address(this)).call{value: sellerFeeAmt}("");
            require(toPlatform, "Swapsy: platform fee failed");
        } else {
            require(
                IERC20(_swaps.tokenOut).transferFrom(msg.sender, _swaps.seller, sellerTransAmt),
                "Swapsy: payment failed"
            );
            require(
                IERC20(_swaps.tokenOut).transferFrom(msg.sender, address(this), sellerFeeAmt),
                "Swapsy: platform fee failed"
            );
        }

        /* Buyer gets the purchased item */
        uint256 buyerFee = ISwapsyManager(swapsyManager).getFeeForBuyer();
        uint256 buyerFeeAmt = (_swaps.amountIn * buyerFee) / 1000;
        uint256 buyerTransAmt = _swaps.amountIn - buyerFeeAmt;
        
        _revenue[_swaps.tokenIn] += buyerTransAmt;
        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: buyerTransAmt}("");
            require(sent, "Swapsy: tx failed");
        } else {
            require(
                IERC20(_swaps.tokenIn).transfer(msg.sender, buyerTransAmt),
                "Swapsy: tx failed"
            );
        }

        _allSwaps[id].status = STATUS.SUCCESS;
        emit Buy(
            msg.sender,
            _swaps.tokenIn,
            _swaps.tokenOut,
            _swaps.amountIn,
            _swaps.amountOut,
            id
        );
    }

    function cancel(uint256 id) external nonReentrant {
        _cancel(id);
    }

    function _cancel(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.seller == msg.sender, "Swapsy: not seller");
        require(_swaps.status == STATUS.OPEN, "Swapsy: unavailable swap");
        require(_swaps.deadline >= block.timestamp, "Swapsy: swap expired");

        /* Instead using claim(), let's do direct refund to seller for minimize gas */
        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: _swaps.amountIn}(
                ""
            );
            require(sent, "Swapsy: refund failed");
        } else {
            require(
                IERC20(_swaps.tokenIn).transfer(msg.sender, _swaps.amountIn),
                "Swapsy: refund failed"
            );
        }

        _allSwaps[id].status = STATUS.CANCELLED;
        emit Cancel(_swaps.seller, _swaps.tokenIn, _swaps.tokenOut, id);
    }

    function refund(uint256 id) external nonReentrant {
        _refund(id);
    }

    function _refund(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.seller == msg.sender, "Swapsy: not seller");
        require((_swaps.status == STATUS.OPEN) && (_swaps.deadline < block.timestamp), "Swapsy: cannot be refund");
        
        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(_swaps.seller).call{
                value: _swaps.amountIn
            }("");
            require(sent, "Swapsy: refund failed");
        } else {
            require(
                IERC20(_swaps.tokenIn).transfer(
                    _swaps.seller,
                    _swaps.amountIn
                ),
                "Swapsy: refund failed"
            );
        }

        _swaps.status = STATUS.EXPIRED;
        emit Refund(
            _swaps.seller,
            _swaps.tokenIn,
            _swaps.amountIn,
            id
        );
    }

    function getSwapById(uint256 id) public view returns (SWAPS memory) {
        return _allSwaps[id];
    }

    function getSwapsByUser(address user) public view returns (SWAPS[] memory) {
        return _swapsByUser[user];
    }

    function getRevenue(address token) external view returns (uint256 amount) {
        return _revenue[token];
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        require(
            amount > 0 && _revenue[token] >= amount,
            "Swapsy: incorrect amount to withdraw"
        );

        _revenue[token] -= amount;
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            require(
                IERC20(token).transfer(msg.sender, amount),
                "Swapsy: withdraw failed"
            );
        }
    }

    function setSwapsyManager(address _swapsyManager) external onlyOwner {
        require(
            _swapsyManager != address(0),
            "Swapsy: impossible manager address"
        );

        swapsyManager = ISwapsyManager(_swapsyManager);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

interface ISwapsyManager {
    function getFeeForSeller() external returns (uint256);

    function getFeeForBuyer() external returns (uint256);
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