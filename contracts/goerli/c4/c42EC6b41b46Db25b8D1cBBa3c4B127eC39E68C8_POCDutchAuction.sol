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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract DutchAuction {
    using Counters for Counters.Counter;

    event AuctionCreated(
        uint indexed id,
        address indexed seller,
        uint quantity,
        uint initialPrice
    );

    event AuctionEnded(
        uint indexed id,
        address indexed seller,
        uint quantity,
        uint initialPrice,
        address indexed buyer,
        uint price
    );

    enum Status {
        Created,
        Ended
    }

    struct AuctionInformation {
        // Auction Initialize Information
        uint id;
        Status status;
        address seller;
        uint quantity;
        uint256 createdAt;
        uint256 initialPrice;

        // Auction Result Information
        address buyer;
        uint256 price;
        uint256 updatedAt;
    }

    Counters.Counter private _id;
    IERC20 public token;
    AuctionInformation[] public _auctions;
    uint256 public duration;

    constructor(address _tokenAddress, uint _duration) {
        token = IERC20(_tokenAddress);
        duration = _duration; 
    }

    function getAuction(uint id) public virtual view returns (AuctionInformation memory) {
        return _auctions[id];
    }

    function getAuction() public virtual view returns (AuctionInformation memory) {
        // Returns current(last) auction.
        return _auctions[_id.current() - 1];
    }

    function createAuction(uint quantity, uint initialPrice) public virtual returns (AuctionInformation memory) {
        address seller = msg.sender;
        return _createAuction(seller, quantity, initialPrice);
    }

    function getPrice() public virtual view returns (uint256) {
        return _getPrice();
    }

    function takeAuction() public virtual payable returns (bool) {
        return _takeAuction(msg.sender, msg.value);
    }

    function _createAuction(address seller, uint quantity, uint initialPrice) internal virtual returns (AuctionInformation memory) {
        require(
            _id.current() == 0 || _auctions[_id.current() - 1].status == Status.Ended,
            "Auction: Auction creation is only available one at a time."
        );
        AuctionInformation memory auction = AuctionInformation(
            _id.current(),
            Status.Created,
            seller,
            quantity,
            block.number,
            initialPrice,
            address(0),
            0,
            block.number
        );
        _auctions.push(auction);

        emit AuctionCreated(
            _id.current(),
            msg.sender,
            quantity,
            initialPrice
        );

        _id.increment();

        return auction;
    }

    function _getPrice() internal virtual view returns (uint256) {
        // The pricing model may be implemented differently depending on the situation.
        // Default to "linear-decreasing" dutch auction.

        AuctionInformation memory currentAuction = getAuction();
        uint256 currentPrice = currentAuction.initialPrice * (duration - (block.number - currentAuction.createdAt))/duration;
        return currentPrice;
    }

    function _takeAuction(address buyer, uint max_eth_sold) internal virtual returns (bool) {
        AuctionInformation storage currentAuction = _auctions[_id.current() - 1];
        uint256 currentPrice = getPrice();

        require(currentAuction.status != Status.Ended);
        require(max_eth_sold >= currentPrice);

        currentAuction.price = currentPrice;
        currentAuction.status = Status.Ended;
        currentAuction.buyer = buyer;
        currentAuction.updatedAt = block.number;

        token.transferFrom(currentAuction.seller, buyer, currentAuction.quantity);

        payable(currentAuction.seller).transfer(currentPrice);
        if (max_eth_sold > currentPrice) {
            payable(msg.sender).transfer(max_eth_sold - currentPrice);
        }

        emit AuctionEnded(
            currentAuction.id,
            currentAuction.seller,
            currentAuction.quantity,
            currentAuction.initialPrice,
            buyer,
            currentPrice
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


import "./DutchAuction.sol";


contract POCDutchAuction is DutchAuction {
    constructor(address _tokenAddress) DutchAuction(_tokenAddress, 7200) {
        // Duration 7,200 means 1 Day/86,400s(average 12s/block) in average.
    }
}