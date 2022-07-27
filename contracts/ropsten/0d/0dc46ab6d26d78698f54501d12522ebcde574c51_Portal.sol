// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "btcmirror/interfaces/IBtcTxVerifier.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";

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

// Max order size: 21m BTC
uint256 constant MAX_SATS = 21e6 * 1e8;
// Max allowed price: 1sat = 1WETH or 1e18 of another ERC20 token.
uint256 constant MAX_PRICE_TOK_PER_SAT = 1e18;

/**
 * @dev Each order represents a bid or ask.
 */
struct Order {
    /** @dev Market maker that created this bid or ask. */
    address maker;
    /** @dev Positive if buying ether (bid), negative if selling (ask). */
    int128 amountSats;
    /** @dev INVERSE price, in token units per sat. */
    uint128 priceTokPerSat;
    /** @dev Unused for bid. Bitcoin P2SH address for asks. */
    bytes20 scriptHash;
    /** @dev Unused for ask. Staked token amount for bids. */
    uint256 stakedTok;
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
    /** @dev Tokens held in escrow. */
    uint256 escrowTok;
    /** @dev If correct amount is paid to script hash, who keeps the escrow? */
    address successRecipient;
    /** @dev If deadline passes without proof of payment, who keeps escrow? */
    address timeoutRecipient;
}

/** @notice Implements a limit order book for trust-minimized BTC-ETH trades. */
contract Portal is Owned {
    event OrderPlaced(
        uint256 orderID,
        int128 amountSats,
        uint128 priceTokPerSat,
        uint256 makerStakedTok,
        address maker
    );

    event OrderCancelled(uint256 orderID);

    event OrderMatched(
        uint256 escrowID,
        uint256 orderID,
        int128 amountSats,
        uint128 priceTokPerSat,
        uint256 takerStakedTok,
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

    /** The token we are trading for BTC. */
    IERC20 public immutable token;

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

    constructor(
        IERC20 _token,
        uint256 _stakePercent,
        IBtcTxVerifier _btcVerifier
    ) Owned(msg.sender) {
        token = _token;
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
    function postBid(uint256 amountSats, uint256 priceTokPerSat)
        public
        payable
        returns (uint256 orderID)
    {
        // Validate order and stake amount.
        require(amountSats <= MAX_SATS, "Amount overflow");
        require(amountSats > 0, "Amount underflow");
        require(priceTokPerSat <= MAX_PRICE_TOK_PER_SAT, "Price overflow");
        require(priceTokPerSat > 0, "Price underflow");
        uint256 totalValueTok = amountSats * priceTokPerSat;
        uint256 requiredStakeTok = (totalValueTok * stakePercent) / 100;

        // Receive stake amount
        _transferFromSender(requiredStakeTok);

        // Record order.
        orderID = nextOrderID++;
        Order storage o = orderbook[orderID];
        o.maker = msg.sender;
        o.amountSats = int128(uint128(amountSats));
        o.priceTokPerSat = uint128(priceTokPerSat);
        o.stakedTok = requiredStakeTok;

        emit OrderPlaced(
            orderID,
            o.amountSats,
            o.priceTokPerSat,
            o.stakedTok,
            msg.sender
        );
    }

    /**
     * @notice Posts an ask. You send ether, which is now for sale at the stated
     *         price. To buy, a buyer sends bitcoin to the state P2SH address.
     */
    function postAsk(
        uint256 amountSats,
        uint256 priceTokPerSat,
        bytes20 scriptHash
    ) public payable returns (uint256 orderID) {
        require(priceTokPerSat <= MAX_PRICE_TOK_PER_SAT, "Price overflow");
        require(priceTokPerSat > 0, "Price underflow");
        require(amountSats <= MAX_SATS, "Amount overflow");
        require(amountSats > 0, "Amount underflow");

        // Receive payment
        _transferFromSender(amountSats * priceTokPerSat);

        // Record order.
        orderID = nextOrderID++;
        Order storage o = orderbook[orderID];
        o.maker = msg.sender;
        o.amountSats = -int128(uint128(amountSats));
        o.priceTokPerSat = uint128(priceTokPerSat);
        o.scriptHash = scriptHash;

        emit OrderPlaced(
            orderID,
            o.amountSats,
            o.priceTokPerSat,
            0,
            msg.sender
        );
    }

    function cancelOrder(uint256 orderID) public {
        Order storage o = orderbook[orderID];

        require(o.amountSats != 0, "Order not found");
        require(msg.sender == o.maker, "Order not yours");

        uint256 tokToSend;
        if (o.amountSats > 0) {
            // Bid, return stake
            tokToSend = o.stakedTok;
        } else {
            // Ask, return liquidity
            tokToSend = uint256(uint128(-o.amountSats) * o.priceTokPerSat);
        }

        emit OrderCancelled(orderID);

        // Delete order now. Prevent reentrancy issues.
        delete orderbook[orderID];

        _transferToSender(tokToSend);
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
        uint256 totalTok = uint256(amountSats) * uint256(o.priceTokPerSat);
        uint256 expectedStakeTok = (totalTok * stakePercent) / 100;

        // Receive stake
        _transferFromSender(expectedStakeTok);

        // Put the COMBINED eth (buyer's stake + the order amount) into escrow.
        Escrow storage e = escrows[escrowID];
        e.destScriptHash = o.scriptHash;
        e.amountSatsDue = amountSats;
        e.deadline = uint128(block.timestamp + 24 hours);
        e.escrowTok = totalTok + msg.value;
        e.successRecipient = msg.sender;
        e.timeoutRecipient = o.maker;

        // Order matched and filled.
        emit OrderMatched(
            escrowID,
            orderID,
            o.amountSats,
            o.priceTokPerSat,
            expectedStakeTok,
            o.maker,
            msg.sender
        );

        delete orderbook[orderID];
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

        // Receive sale payment
        _transferFromSender(amountSats * o.priceTokPerSat);

        // Put the COMBINED eth--the value being sold, plus the liquidity
        // maker's stake--into escrow. If the maker sends bitcoin as
        // expected and provides proof, they get both (stake back + proceeds).
        // If maker fails to deliver, they're slashed and seller gets both.
        Escrow storage e = escrows[escrowID];
        e.destScriptHash = destScriptHash;
        e.amountSatsDue = amountSats;
        e.deadline = uint128(block.timestamp + 24 hours);
        e.escrowTok = o.stakedTok + msg.value;
        e.successRecipient = o.maker;
        e.timeoutRecipient = msg.sender;

        // Order matched and filled.
        emit OrderMatched(
            escrowID,
            orderID,
            o.amountSats,
            o.priceTokPerSat,
            0,
            o.maker,
            msg.sender
        );

        delete orderbook[orderID];
    }

    /** @notice The bidder proves they've sent bitcoin, completing the sale. */
    function proveSettlement(
        uint256 escrowID,
        uint256 bitcoinBlockNum,
        BtcTxProof calldata bitcoinTransactionProof,
        uint256 txOutIx
    ) public {
        Escrow storage e = escrows[escrowID];
        require(e.successRecipient != address(0), "Escrow not found");
        require(msg.sender == e.successRecipient, "Wrong caller");

        bool valid = btcVerifier.verifyPayment(
            minConfirmations,
            bitcoinBlockNum,
            bitcoinTransactionProof,
            txOutIx,
            e.destScriptHash,
            uint256(e.amountSatsDue)
        );
        require(valid, "Bad bitcoin transaction");

        uint256 tokToSend = e.escrowTok;

        emit EscrowSettled(escrowID, e.amountSatsDue, msg.sender, tokToSend);

        delete escrows[escrowID];

        _transferToSender(tokToSend);
    }

    function slash(uint256 escrowID) public {
        Escrow storage e = escrows[escrowID];

        require(msg.sender == e.timeoutRecipient, "Wrong caller");
        require(e.deadline < block.timestamp, "Too early");

        uint256 tokToSend = e.escrowTok;
        emit EscrowSlashed(escrowID, e.deadline, msg.sender, tokToSend);

        delete escrows[escrowID];

        _transferToSender(tokToSend);
    }

    function _transferFromSender(uint256 tok) private {
        if (address(token) == address(0)) {
            // Receive wei
            require(msg.value == tok, "Wrong payment");
            return;
        }

        bool success = token.transferFrom(msg.sender, address(this), tok);
        require(success, "transferFrom failed");
    }

    function _transferToSender(uint256 tok) private {
        if (address(token) == address(0)) {
            // Send wei
            (bool suc, ) = msg.sender.call{value: tok}(hex"");
            require(suc, "Send failed");
            return;
        }

        bool success = token.transfer(msg.sender, tok);
        require(success, "transfer failed");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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