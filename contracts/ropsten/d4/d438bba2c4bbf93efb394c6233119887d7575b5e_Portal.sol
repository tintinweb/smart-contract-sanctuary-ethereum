// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "btcmirror/interfaces/IBtcTxVerifier.sol";
import "openzeppelin-contracts/access/Ownable.sol";

//
//                                        #
//                                       # #
//                                      # # #
//                                     # # # #
//                                    # # # # #
//                                   # # # # # #
//                                  # # # # # # #
//                                 # # # # # # # #
//                                # # # # # # # # #
//                               # # # # # # # # # #
//                              # # # # # # # # # # #
//                                   # # # # # #
//                               +        #        +
//                                ++++         ++++
//                                  ++++++ ++++++
//                                    +++++++++
//                                      +++++
//                                        +
//

uint256 constant MAX_SATS = 21000000 * 100 * 1000000; // 21m BTC in sats
uint256 constant MAX_PRICE_WEI_PER_SAT = 1e18; // Max allowed price, 1sat = 1ETH
/**
 * @dev Each order represents a bid or ask.
 */
struct Order {
    /** @dev Liquidity maker that created this bid or ask. */
    address maker;
    /** @dev Positive if buying ether (bid), negative if selling (ask). */
    int128 amountSats;
    /** @dev INVERSE price, in weis per sat. You're buying or selling weis.*/
    uint128 priceWeiPerSat;
    /** @dev Unused for bid. Bitcoin P2SH address for asks. */
    bytes20 scriptHash;
    /** @dev Unused for ask. Staked wei for bids. */
    uint256 stakedWei;
}

/**
 * @dev During an in-progress transaction, ether is held in escrow.
 */
struct Escrow {
    /** @dev Bitcoin P2SH address to which bitcoin must be sent. */
    bytes20 destScriptHash;
    /** @dev Bitcoin due, in satoshis. */
    uint128 amountSatsDue;
    /** @dev Due date, in Unix seconds. */
    uint128 deadline;
    /** @dev Ether held in escrow. */
    uint256 escrowWei;
    /** @dev If correct amount is paid to script hash, who gets the eth? */
    address successRecipient;
    /** @dev If deadline passes without proof of payment, who gets the eth? */
    address timeoutRecipient;
}

contract Portal is Ownable {
    event OrderPlaced(
        uint256 orderID,
        int128 amountSats,
        uint128 priceWeiPerSat,
        uint256 makerStakedWei,
        address maker
    );

    event OrderCancelled(uint256 orderID);

    event OrderMatched(
        uint256 escrowID,
        uint256 orderID,
        int128 amountSats,
        uint128 priceWeiPerSat,
        uint256 takerStakedWei,
        address maker,
        address taker
    );

    event EscrowSettled(
        uint256 escrowID,
        uint256 amountSats,
        address ethDest,
        uint256 ethAmount
    );

    event EscrowSlashed(
        uint256 escrowID,
        uint256 escrowDeadline,
        address ethDest,
        uint256 ethAmount
    );

    event ParamUpdated(uint256 oldVal, uint256 newVal, string name);

    /**
     * @dev Required stake for buy transactions. If you promise to send X BTC to
     *      buy Y ETH, you have post some percentage of Y ETH, which you lose if
     *      you don't follow thru sending the Bitcoin. Same for bids.
     */
    uint256 public stakePercent;

    /** @dev Number of bitcoin confirmations required to settle a trade. */
    uint256 public minConfirmations;

    /** @dev Bitcoin light client. Reports block hashes, allowing tx proofs. */
    IBtcTxVerifier public btcVerifier;

    /** @dev Tracks all available liquidity (bids and asks). */
    mapping(uint256 => Order) public orderbook;

    /** @dev Tracks all pending transactions, by order ID. */
    mapping(uint256 => Escrow) public escrows;

    /** @dev Next order ID = number of orders so far + 1. */
    uint256 public nextOrderID;

    constructor(uint256 _stakePercent, IBtcTxVerifier _btcVerifier) {
        stakePercent = _stakePercent;
        btcVerifier = _btcVerifier;
        nextOrderID = 1;
        minConfirmations = 1;
    }

    /** @notice Owner-settable parameter. */
    function setStakePercent(uint256 _stakePercent) public onlyOwner {
        uint256 old = stakePercent;
        stakePercent = _stakePercent;
        emit ParamUpdated(old, stakePercent, "stakePercent");
    }

    /** @notice Owner-settable parameter. */
    function setMinConfirmations(uint256 _minConfirmations) public onlyOwner {
        uint256 old = minConfirmations;
        minConfirmations = _minConfirmations;
        emit ParamUpdated(old, minConfirmations, "minConfirmations");
    }

    /** @notice Owner-settable parameter. */
    function setBtcVerifier(IBtcTxVerifier _btcVerifier) public onlyOwner {
        uint160 old = uint160(address(btcVerifier));
        btcVerifier = _btcVerifier;
        emit ParamUpdated(old, uint160(address(btcVerifier)), "btcVerifier");
    }

    /**
     * @notice Posts a bid. By calling this function, you represent that you
     *         have a stated amount of bitcoin, and are willing to buy ether
     *         at the stated price. You must stake a percentage of the total
     *         eth value, which is returned after a successful transaction.
     */
    function postBid(uint256 amountSats, uint256 priceWeiPerSat)
        public
        payable
        returns (uint256 orderID)
    {
        // Validate order and stake amount.
        require(amountSats <= MAX_SATS, "Amount overflow");
        require(amountSats > 0, "Amount underflow");
        require(priceWeiPerSat <= MAX_PRICE_WEI_PER_SAT, "Price overflow");
        require(priceWeiPerSat > 0, "Price underflow");
        uint256 totalValueWei = amountSats * priceWeiPerSat;
        uint256 requiredStakeWei = (totalValueWei * stakePercent) / 100;
        require(msg.value == requiredStakeWei, "Incorrect stake");

        // Record order.
        orderID = nextOrderID++;
        Order storage o = orderbook[orderID];
        o.maker = msg.sender;
        o.amountSats = int128(uint128(amountSats));
        o.priceWeiPerSat = uint128(priceWeiPerSat);
        o.stakedWei = requiredStakeWei;

        emit OrderPlaced(
            orderID,
            o.amountSats,
            o.priceWeiPerSat,
            o.stakedWei,
            msg.sender
        );
    }

    /**
     * @notice Posts an ask. You send ether, which is now for sale at the stated
     *         price. To buy, a buyer sends bitcoin to the state P2SH address.
     */
    function postAsk(uint256 priceWeiPerSat, bytes20 scriptHash)
        public
        payable
        returns (uint256 orderID)
    {
        require(priceWeiPerSat <= MAX_PRICE_WEI_PER_SAT, "Price overflow");
        require(priceWeiPerSat > 0, "Price underflow");
        uint256 amountSats = msg.value / priceWeiPerSat;
        require(amountSats <= MAX_SATS, "Amount overflow");
        require(amountSats > 0, "Amount underflow");
        require(amountSats * priceWeiPerSat == msg.value, "Wrong payment");

        // Record order.
        orderID = nextOrderID++;
        Order storage o = orderbook[orderID];
        o.maker = msg.sender;
        o.amountSats = -int128(uint128(amountSats));
        o.priceWeiPerSat = uint128(priceWeiPerSat);
        o.scriptHash = scriptHash;

        emit OrderPlaced(
            orderID,
            o.amountSats,
            o.priceWeiPerSat,
            0,
            msg.sender
        );
    }

    function cancelOrder(uint256 orderID) public {
        Order storage o = orderbook[orderID];

        require(msg.sender == o.maker, "Not your order");
        require(o.amountSats != 0, "Order already filled");

        uint256 weiToSend;
        if (o.amountSats > 0) {
            // Bid, return stake
            weiToSend = o.stakedWei;
        } else {
            // Ask, return liquidity
            weiToSend = uint256(uint128(-o.amountSats) * o.priceWeiPerSat);
        }

        // Delete order now. Prevent reentrancy issues.
        delete orderbook[orderID];

        (bool success, ) = msg.sender.call{value: weiToSend}("");
        require(success, "Transfer failed");
    }

    /** @notice Buy ether, posting stake and promising to send bitcoin. */
    function initiateBuy(uint256 orderID, uint128 amountSats)
        public
        payable
        returns (uint256 escrowID)
    {
        // Orders can only be filled in their entirety, for now.
        // This means escrows are 1:1 with orders.
        // TODO: allow partial fills?
        escrowID = orderID * 1e9;

        Order storage o = orderbook[orderID];
        require(o.amountSats < 0, "Order already filled");
        require(-o.amountSats == int128(amountSats), "Amount incorrect");

        // Verify correct stake amount.
        uint256 totalWei = uint256(amountSats) * uint256(o.priceWeiPerSat);
        uint256 expectedStakeWei = (totalWei * stakePercent) / 100;
        require(msg.value != expectedStakeWei, "Wrong payment");

        // Put the COMBINED eth (buyer's stake + the order amount) into escrow.
        Escrow storage e = escrows[escrowID];
        e.destScriptHash = o.scriptHash;
        e.amountSatsDue = amountSats;
        e.deadline = uint128(block.timestamp + 24 hours);
        e.escrowWei = totalWei + msg.value;
        e.successRecipient = msg.sender;
        e.timeoutRecipient = o.maker;

        // Order matched and filled.
        delete orderbook[orderID];

        emit OrderMatched(
            escrowID,
            orderID,
            o.amountSats,
            o.priceWeiPerSat,
            0,
            o.maker,
            msg.sender
        );
    }

    /** @notice Sell ether, receive bitcoin. */
    function initiateSell(
        uint256 orderID,
        uint128 amountSats,
        bytes20 destScriptHash
    ) public payable returns (uint256 escrowID) {
        escrowID = orderID * 1e9;
        Order storage o = orderbook[orderID];
        require(o.amountSats > 0, "Order already filled"); // Must be a bid
        require(o.amountSats == int128(amountSats), "Amount incorrect");
        require(msg.value == amountSats * o.priceWeiPerSat, "Wrong payment");

        // Put the COMBINED eth--the value being sold, plus the liquidity
        // maker's stake--into escrow. If the maker sends bitcoin as
        // expected and provides proof, they get both (stake back + proceeds).
        // If maker fails to deliver, they're slashed and seller gets both.
        Escrow storage e = escrows[escrowID];
        e.destScriptHash = destScriptHash;
        e.amountSatsDue = amountSats;
        e.deadline = uint128(block.timestamp + 24 hours);
        e.escrowWei = o.stakedWei + msg.value;
        e.successRecipient = o.maker;
        e.timeoutRecipient = msg.sender;

        // Order matched and filled.
        delete orderbook[orderID];

        emit OrderMatched(
            escrowID,
            orderID,
            o.amountSats,
            o.priceWeiPerSat,
            msg.value,
            o.maker,
            msg.sender
        );
    }

    /** @notice The bidder proves they've sent bitcoin, completing the sale. */
    function proveSettlement(
        uint256 escrowID,
        uint256 bitcoinBlockNum,
        BtcTxProof calldata bitcoinTransactionProof,
        uint256 txOutIx
    ) public {
        Escrow storage e = escrows[escrowID];
        require(msg.sender == e.successRecipient, "Wrong caller");

        require(
            btcVerifier.verifyPayment(
                minConfirmations,
                bitcoinBlockNum,
                bitcoinTransactionProof,
                txOutIx,
                e.destScriptHash,
                uint256(e.amountSatsDue)
            ),
            "Bad bitcoin transaction"
        );

        uint256 weiToSend = e.escrowWei;
        delete escrows[escrowID];

        (bool success, ) = msg.sender.call{value: weiToSend}("");
        require(success, "Transfer failed");

        emit EscrowSettled(escrowID, e.amountSatsDue, msg.sender, weiToSend);
    }

    function slash(uint256 escrowID) public {
        Escrow storage e = escrows[escrowID];

        require(msg.sender == e.timeoutRecipient, "Wrong caller");
        require(e.deadline < block.timestamp, "Too early");

        uint256 weiToSend = e.escrowWei;
        delete escrows[escrowID];

        (bool success, ) = msg.sender.call{value: weiToSend}("");
        require(success, "Transfer failed");

        emit EscrowSlashed(escrowID, e.deadline, msg.sender, weiToSend);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BtcTxProof.sol";

/** @notice Verifies Bitcoin transaction proofs. */
interface IBtcTxVerifier {
    /**
     * @notice Verifies that the a transaction cleared, paying a given amount to
     *         a given address. Specifically, verifies a proof that the tx was
     *         in block N, and that block N has at least M confirmations.
     */
    function verifyPayment(
        uint256 minConfirmations,
        uint256 blockNum,
        BtcTxProof calldata inclusionProof,
        uint256 txOutIx,
        bytes20 destScriptHash,
        uint256 amountSats
    ) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/** @notice Proof that a transaction (rawTx) is in a given block. */
struct BtcTxProof {
    /** 80-byte block header. */
    bytes blockHeader;
    /** Bitcoin transaction ID, equal to SHA256(SHA256(rawTx)) */
    bytes32 txId;
    /** Index of transaction within the block. */
    uint256 txIndex;
    /** Merkle proof. Concatenated sibling hashes, 32*n bytes. */
    bytes txMerkleProof;
    /** Raw transaction, HASH-SERIALIZED, no witnesses. */
    bytes rawTx;
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