// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './SellOrder.sol';
import './interfaces/IOrderBook.sol';

/// @dev A factory for creating orders. The Graph should index this contract.
contract OrderBook is IOrderBook {
    /// @dev all the sell orders available in the order book
    mapping(address => bool) public sellOrders;

    /// @dev the fee rate in parts per million
    uint256 public fee = 10000; // 1%

    /// @dev the authority over this order book, ie the DAO
    address private _owner;

    /// @dev Throws if msg.sender is not the owner.
    error NotOwner();

    /// @dev initializes a new order book
    constructor() {
        _owner = msg.sender;
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
        if (owner() != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    /// @dev changes the fee rate
    function setFee(uint256 _fee) external onlyOwner {
        emit FeeChanged(fee, _fee);
        fee = _fee;
    }

    /// @dev changes the owner of this order book
    function setOwner(address _newOwner) external onlyOwner {
        emit OwnerChanged(owner(), _newOwner);
        _owner = _newOwner;
    }

    /// @dev Creates a new sell order that can be easily indexed by something like theGraph.
    function createSellOrder(
        address seller,
        IERC20 token,
        uint256 stake,
        string memory uri,
        uint256 timeout
    ) external returns (SellOrder) {
        SellOrder sellOrder = new SellOrder(seller, token, stake, uri, timeout);
        emit SellOrderCreated(address(sellOrder));
        sellOrders[address(sellOrder)] = true;
        return sellOrder;
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
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IOrderBook.sol';

contract SellOrder {
    /// @dev Don't allow purchases from self
    error BuyerCannotBeSeller();

    /// @dev msg.sender is not the seller
    error MustBeSeller();

    /// @dev A function is run at the wrong time in the lifecycle
    error InvalidState(State expected, State received);

    /// @dev The order is not accepting new offers
    error OrderInactive();

    /// @dev Emitted when `buyer` submits and offer.
    event OfferSubmitted(
        address indexed buyer,
        uint32 indexed index,
        uint32 quantity,
        uint128 pricePerUnit,
        uint128 stakePerUnit,
        string uri
    );

    /// @dev Emitted when `buyer` withdrew and offer.
    event OfferWithdrawn(address indexed buyer, uint32 indexed index);

    /// @dev Emitted when `buyer`'s offer was commited too.
    event OfferCommitted(address indexed buyer, uint32 indexed index);

    /// @dev Emitted when `buyer` withdrew and offer.
    event OfferConfirmed(address indexed buyer, uint32 indexed index);

    /// @dev Emitted when `buyer` withdrew and offer.
    event OfferEnforced(address indexed buyer, uint32 indexed index);

    /// @dev Someone requested a cancellation of the sell order. The order is
    ///      is only "really" canceled if both sellerCanceled and buyerCanceled is
    ///      true.
    event OfferCanceled(
        address indexed buyer,
        uint32 indexed index,
        bool sellerCanceled,
        bool buyerCanceled
    );

    /// @dev The sell order's URI changed
    event OrderURIChanged(string previous, string next);

    /// @dev The token used for payment & staking, such as wETH, DAI, or USDC.
    IERC20 public token;

    /// @dev The seller
    address public seller;

    /// @dev the maximum delivery time before the order can said to have failed.
    uint256 public timeout;

    /// @dev the amount the seller is offering to stake per order.
    uint256 public orderStake;

    /// @dev order book
    address public orderBook;

    /// @dev the URI where metadata about this SellOrder can be found
    string private _uri;

    /// @dev if false, the order is not open for new offers.
    bool public active;

    /// @dev The state of an offer
    enum State {
        Closed,
        Open,
        Committed
    }

    struct Offer {
        /// @dev the state of the offer
        State state;
        /// @dev the amount the buyer is willing to pay
        uint128 pricePerUnit;
        /// @dev the amount the buyer is willing to stake
        uint128 stakePerUnit;
        /// @dev the uri of metadata that can contain shipping information (typically encrypted)
        string uri;
        /// @dev the block.timestamp in which acceptOffer() was called. 0 otherwise
        uint64 acceptedAt;
        /// @dev canceled by the seller
        bool sellerCanceled;
        /// @dev canceled by the buyer
        bool buyerCanceled;
        /// @dev Allows a buyer to purchase multiple units.
        /// The seller will need to stake quantity*stake to accept.
        uint32 quantity;
    }

    /// @dev A mapping of potential offers to the amount of tokens they are willing to stake
    ///     a "uint32" here means you can have 2^32 open offers from any given address.
    ///     uint32 was chosen over uint8 to support the use case of a program that's buying
    ///     on behalf of a large number of users.
    ///
    ///     If, for some reason, ~2 billion open offers does not support your use case, you
    ///     could just create another address for your buyer (shard), implement a queue,
    ///     or we could just release a new version.
    mapping(address => mapping(uint32 => Offer)) public offers;

    /// @dev The denominator of parts per million
    uint256 constant ONE_MILLION = 1000000;

    /// @dev Creates a new sell order.
    constructor(
        address seller_,
        IERC20 token_,
        uint256 orderStake_,
        string memory uri_,
        uint256 timeout_
    ) {
        orderBook = msg.sender;
        seller = seller_;
        token = token_;
        orderStake = orderStake_;
        _uri = uri_;
        timeout = timeout_;
        active = true;
    }

    /// @dev returns the URI of the sell order, containing it's metadata
    function orderURI() external view virtual returns (string memory) {
        return _uri;
    }

    /// @dev sets the URI of the sell order, containing it's metadata
    function setURI(string memory uri_) external virtual onlySeller {
        _uri = uri_;
        emit OrderURIChanged(_uri, uri_);
    }

    /// @dev Sets "active". If false, the order is not open for new offers.
    function setActive(bool active_) external virtual onlySeller {
        active = active_;
    }

    /// @dev reverts if the function is not at the expected state
    modifier onlyState(
        address buyer_,
        uint32 index,
        State expected
    ) {
        if (offers[buyer_][index].state != expected) {
            revert InvalidState(expected, offers[buyer_][index].state);
        }

        _;
    }

    /// @dev reverts if msg.sender is not the seller
    modifier onlySeller() {
        if (msg.sender != seller) {
            revert MustBeSeller();
        }

        _;
    }

    /// @dev reverts if not active
    modifier onlyActive() {
        if (!active) {
            revert OrderInactive();
        }

        _;
    }

    /// @dev creates an offer
    function submitOffer(
        uint32 index,
        uint32 quantity,
        uint128 pricePerUnit,
        uint128 stakePerUnit,
        string memory uri
    ) external virtual onlyState(msg.sender, index, State.Closed) onlyActive {
        if (msg.sender == seller) {
            revert BuyerCannotBeSeller();
        }

        Offer storage offer = offers[msg.sender][index];
        offer.state = State.Open;
        offer.pricePerUnit = pricePerUnit;
        offer.stakePerUnit = stakePerUnit;
        offer.uri = uri;
        offer.quantity = quantity;

        bool result = token.transferFrom(
            msg.sender,
            address(this),
            (stakePerUnit + pricePerUnit) * quantity
        );
        require(result, 'Transfer failed');

        emit OfferSubmitted(
            msg.sender,
            index,
            quantity,
            pricePerUnit,
            stakePerUnit,
            uri
        );
    }

    /// @dev allows a buyer to withdraw the offer
    function withdrawOffer(uint32 index)
        external
        virtual
        onlyState(msg.sender, index, State.Open)
    {
        Offer memory offer = offers[msg.sender][index];

        bool result = token.transfer(
            msg.sender,
            (offer.stakePerUnit + offer.pricePerUnit) * offer.quantity
        );
        assert(result);

        offers[msg.sender][index] = Offer(
            State.Closed,
            0,
            0,
            offer.uri,
            0,
            false,
            false,
            0
        );

        emit OfferWithdrawn(msg.sender, index);
    }

    /// @dev Commits a seller to an offer
    function commit(address buyer_, uint32 index)
        public
        virtual
        onlyState(buyer_, index, State.Open)
        onlySeller
    {
        // Deposit the stake required to commit to the offer
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= orderStake);

        // Update the status of the buyer's offer
        Offer storage offer = offers[buyer_][index];
        offer.acceptedAt = uint64(block.timestamp);
        offer.state = State.Committed;

        bool result = token.transferFrom(
            msg.sender,
            address(this),
            offer.quantity * orderStake
        );
        assert(result);

        emit OfferCommitted(buyer_, index);
    }

    /// @dev Marks all provided offers as confirmed
    function commitBatch(address[] calldata buyers, uint32[] calldata indices)
        external
        virtual
    {
        require(buyers.length == indices.length);
        for (uint256 i = 0; i < buyers.length; i++) {
            commit(buyers[i], indices[i]);
        }
    }

    /// @dev Marks the order as sucessfully completed, and transfers the tokens.
    function confirm(uint32 index)
        external
        virtual
        onlyState(msg.sender, index, State.Committed)
    {
        // Close the offer
        Offer memory offer = offers[msg.sender][index];
        offers[msg.sender][index] = Offer(
            State.Closed,
            0,
            0,
            '',
            uint64(block.timestamp),
            false,
            false,
            0
        );

        // Return the stake to the buyer
        bool result0 = token.transfer(
            msg.sender,
            offer.stakePerUnit * offer.quantity
        );
        assert(result0);

        uint256 total = offer.pricePerUnit * offer.quantity;
        uint256 toOrderBook = (total * IOrderBook(orderBook).fee()) /
            ONE_MILLION;
        uint256 toSeller = total - toOrderBook;

        // Transfer payment to the seller, along with their stake
        bool result1 = token.transfer(
            seller,
            toSeller + (orderStake * offer.quantity)
        );
        assert(result1);

        // Transfer payment to the order book
        bool result2 = token.transfer(
            IOrderBook(orderBook).owner(),
            toOrderBook
        );
        assert(result2);

        emit OfferConfirmed(msg.sender, index);
    }

    /// @dev Allows anyone to enforce an offer.
    function enforce(address buyer_, uint32 index)
        external
        virtual
        onlyState(buyer_, index, State.Committed)
    {
        Offer memory offer = offers[buyer_][index];
        require(block.timestamp > timeout + offer.acceptedAt);

        // Close the offer
        offers[buyer_][index] = Offer(
            State.Closed,
            0,
            0,
            '',
            uint64(block.timestamp),
            false,
            false,
            0
        );

        // Transfer the payment to the seller
        bool result0 = token.transfer(
            seller,
            (offer.pricePerUnit * offer.quantity)
        );
        assert(result0);

        // Transfer the buyer's stake to address(dead).
        bool result1 = token.transfer(
            address(0x000000000000000000000000000000000000dEaD),
            (offer.stakePerUnit * offer.quantity)
        );
        assert(result1);

        // Transfer the seller's stake to address(dead).
        bool result2 = token.transfer(
            address(0x000000000000000000000000000000000000dEaD),
            orderStake * offer.quantity
        );
        assert(result2);

        emit OfferEnforced(buyer_, index);
    }

    /// @dev Allows either the buyer or the seller to cancel the offer.
    ///      Only a committed offer can be canceled
    function cancel(address buyer_, uint32 index)
        external
        virtual
        onlyState(buyer_, index, State.Committed)
    {
        Offer storage offer = offers[buyer_][index];
        if (msg.sender == buyer_) {
            // The buyer is canceling their offer
            offer.buyerCanceled = true;
        } else {
            // The seller is canceling their offer
            if (msg.sender != seller) {
                revert MustBeSeller();
            }
            offer.sellerCanceled = true;
        }

        // If both parties canceled, then return the stakes, and the payment to the buyer
        // and set the offer to closed
        if (offer.sellerCanceled && offer.buyerCanceled) {
            // Transfer the stake to the buyer along with their payment
            bool result0 = token.transfer(
                buyer_,
                (offer.stakePerUnit + offer.pricePerUnit) * offer.quantity
            );
            assert(result0);

            // Transfer the stake to the seller
            bool result1 = token.transfer(seller, orderStake * offer.quantity);
            assert(result1);

            // Null out the offer
            offers[buyer_][index] = Offer(
                State.Closed,
                0,
                0,
                '',
                uint64(block.timestamp),
                false,
                false,
                0
            );
        }

        emit OfferCanceled(
            buyer_,
            index,
            offer.sellerCanceled,
            offer.buyerCanceled
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../SellOrder.sol';

interface IOrderBook {
    event SellOrderCreated(address indexed sellOrder);

    event OwnerChanged(address previous, address next);

    event FeeChanged(uint256 previous, uint256 next);

    function owner() external view returns (address);

    function fee() external view returns (uint256);

    function setFee(uint256 _fee) external;

    function setOwner(address _newOwner) external;

    function createSellOrder(
        address seller,
        IERC20 token,
        uint256 stake,
        string memory uri,
        uint256 timeout
    ) external returns (SellOrder);
}