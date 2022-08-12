// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "btcmirror/interfaces/IBtcTxVerifier.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";

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

/**
 * @dev Max order size: 21m BTC. That should be enough for now ;)
 */
uint256 constant MAX_SATS = 21e6 * 1e8;
/**
 * @dev Max allowed price: 1sat = 1 token. See priceTps below for "TPS" details.
 */
uint256 constant MAX_PRICE_TPS = 1e18;

/**
 * @dev Each order represents a bid or ask.
 */
struct Order {
    /**
     * @dev Market maker that created this bid or ask.
     */
    address maker;
    /**
     * @dev Positive if selling bitcoin (ask), negative if buying (bid).
     */
    int128 amountSats;
    /**
     * @dev Price, in (10^-18 token) per sat, regardless of token.decimals().
     * Equivalently, price in tokens per bitcoin, in 10-decimal fixed point.
     */
    uint128 priceTps;
    /**
     * @dev Unused for ask. Bitcoin P2SH address for bid.
     */
    bytes20 scriptHash;
    /**
     * @dev Unused for bid. Staked token amount for asks, in token units.
     */
    uint256 stakedTok;
}

/**
 * @dev After each trade, tokens are held in escrow pendings BTC settlement.
 */
struct Escrow {
    /**
     * @dev Bitcoin P2SH address to which bitcoin must be sent.
     */
    bytes20 destScriptHash;
    /**
     * @dev Bitcoin due, in satoshis. This precise amount must be paid.
     */
    uint128 amountSatsDue;
    /**
     * @dev Due date, in Unix seconds.
     */
    uint128 deadline;
    /**
     * @dev Token units held in escrow.
     */
    uint256 escrowTok;
    /**
     * @dev If correct amount is paid to script hash, who keeps the escrow?
     */
    address successRecipient;
    /**
     * @dev If deadline passes without proof of payment, who keeps escrow?
     */
    address timeoutRecipient;
}

/**
 * @notice Implements a limit order book for trust-minimized BTC-ETH trades.
 */
contract Portal is Owned {
    event OrderPlaced(
        uint256 orderID,
        int128 amountSats,
        uint128 priceTps,
        uint256 makerStakedTok,
        address maker
    );

    event OrderCancelled(uint256 orderID);

    event OrderMatched(
        uint256 escrowID,
        uint256 orderID,
        int128 amountSats,
        int128 amountSatsFilled,
        uint128 priceTps,
        uint256 takerStakedTok,
        uint128 deadline,
        address maker,
        address taker,
        bytes20 destScriptHash
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
     * @dev The token we are trading for BTC, or address(0) for ETH.
     */
    ERC20 public immutable token;

    /**
     * @dev How many (10^-18 tokens) in one unit. 1 for ETH/WETH, 1e10 for WBTC.
     */
    uint256 public immutable tokDiv;

    /**
     * @dev Required stake for buy transactions. If you promise to send X BTC to
     * buy Y ETH, you have post some percentage of Y ETH, which you lose if
     * you don't follow thru sending the Bitcoin. Same for bids.
     */
    uint256 public stakePercent;

    /**
     * @dev Number of bitcoin confirmations required to settle a trade.
     */
    uint256 public minConfirmations;

    /**
     * @dev Bitcoin light client. Reports block hashes, allowing tx proofs.
     */
    IBtcTxVerifier public btcVerifier;

    /**
     * @dev Minimum order size, in satoshis.
     */
    uint256 public minOrderSats;

    /**
     * @dev Price tick, in (10^-18 tokens) per satoshi = (10^-10 tokens / BTC).
     * All order prices must be a multiple of tickTps.
     */
    uint256 public tickTps;

    /**
     * @dev Tracks all available liquidity (bids and asks), by order ID.
     */
    mapping(uint256 => Order) public orderbook;

    /**
     * @dev Tracks all pending BTC settlement transactions, by escrow ID.
     */
    mapping(uint256 => Escrow) public escrows;

    /**
     * @dev Next order ID = number of orders so far + 1.
     */
    uint256 public nextOrderID;

    /**
     * @dev Next escrow ID = number of fills so far + 1.
     */
    uint256 public nextEscrowID;

    /**
     * @dev Tracks in-flight escrows, and where we expect payments to come from.
     * Prevents using a single btc payment proof to close multiple escrows.
     *
     * Key is keccak(destScriptHash, amountSats), and the value is the minimum
     * BtcMirror block height at which this escrow may be settled.
     *
     * This means that no two open escrows can have an identical destination and
     * amount. If an older (closed) escrow exists, the block height prevents
     * proof re-use.
     */
    mapping(bytes32 => uint256) public openEscrows;

    constructor(
        ERC20 _token,
        uint256 _stakePercent,
        IBtcTxVerifier _btcVerifier
    ) Owned(msg.sender) {
        // Immutable
        token = _token;
        uint256 dec = 18;
        if (address(_token) != address(0)) {
            dec = _token.decimals();
        }
        require(dec <= 18, "Tokens over 18 decimals unsupported");
        tokDiv = 10**(18 - dec);

        // Mutable
        minOrderSats = 100_000; // 0.001 BTC
        tickTps = 1e6; // 0.0001 tokens per bitcoin

        stakePercent = _stakePercent;
        btcVerifier = _btcVerifier;
        minConfirmations = 1;

        nextOrderID = 1;
        nextEscrowID = 1;
    }

    /**
     * @notice Owner-settable parameter.
     */
    function setStakePercent(uint256 _stakePercent) public onlyOwner {
        uint256 old = stakePercent;
        stakePercent = _stakePercent;
        emit ParamUpdated(old, stakePercent, "stakePercent");
    }

    /**
     * @notice Owner-settable parameter.
     */
    function setMinConfirmations(uint256 _minConfirmations) public onlyOwner {
        uint256 old = minConfirmations;
        minConfirmations = _minConfirmations;
        emit ParamUpdated(old, minConfirmations, "minConfirmations");
    }

    /**
     * @notice Owner-settable parameter.
     */
    function setBtcVerifier(IBtcTxVerifier _btcVerifier) public onlyOwner {
        uint160 old = uint160(address(btcVerifier));
        btcVerifier = _btcVerifier;
        emit ParamUpdated(old, uint160(address(btcVerifier)), "btcVerifier");
    }

    /**
     * @notice Owner-settable parameter.
     */
    function setMinOrderSats(uint256 _minOrderSats) public onlyOwner {
        uint256 old = minOrderSats;
        minOrderSats = _minOrderSats;
        emit ParamUpdated(old, minOrderSats, "minOrderSats");
    }

    /**
     * @notice Owner-settable parameter.
     */
    function setTickTps(uint256 _tickTps) public onlyOwner {
        uint256 old = tickTps;
        tickTps = _tickTps;
        emit ParamUpdated(old, tickTps, "tickTps");
    }

    modifier validAmount(uint256 amountSats) {
        require(amountSats <= MAX_SATS, "Amount overflow");
        require(amountSats > 0, "Amount underflow");
        require(amountSats % minOrderSats == 0, "Non-round amount");
        _;
    }

    modifier validPrice(uint256 priceTps) {
        require(priceTps <= MAX_PRICE_TPS, "Price overflow");
        require(priceTps > 0, "Price underflow");
        require(priceTps % tickTps == 0, "Price must be divisible by tickTps");
        _;
    }

    /**
     * @notice Posts an ask, offering to sell bitcoin for tokens.
     */
    function postAsk(uint256 amountSats, uint256 priceTps)
        public
        payable
        validAmount(amountSats)
        validPrice(priceTps)
        returns (uint256 orderID)
    {
        uint256 totalValueTok = (amountSats * priceTps) / tokDiv;
        uint256 requiredStakeTok = (totalValueTok * stakePercent) / 100;
        require(requiredStakeTok < 2**128, "Stake must be < 2**128");

        // Receive stake amount
        _transferFromSender(requiredStakeTok);

        // Record order.
        orderID = nextOrderID++;
        Order storage o = orderbook[orderID];
        o.maker = msg.sender;
        o.amountSats = int128(uint128(amountSats));
        o.priceTps = uint128(priceTps);
        o.stakedTok = requiredStakeTok;

        emit OrderPlaced(
            orderID,
            o.amountSats,
            o.priceTps,
            o.stakedTok,
            msg.sender
        );
    }

    /**
     * @notice Posts a bid. You send ether, which is now for sale at the stated
     * price. To buy, a buyer sends bitcoin to the state P2SH address.
     */
    function postBid(
        uint256 amountSats,
        uint256 priceTps,
        bytes20 scriptHash
    )
        public
        payable
        validAmount(amountSats)
        validPrice(priceTps)
        returns (uint256 orderID)
    {
        // Receive payment
        uint256 totalValueTok = (amountSats * priceTps) / tokDiv;
        _transferFromSender(totalValueTok);

        // Record order.
        orderID = nextOrderID++;
        Order storage o = orderbook[orderID];
        o.maker = msg.sender;
        o.amountSats = -int128(uint128(amountSats));
        o.priceTps = uint128(priceTps);
        o.scriptHash = scriptHash;

        emit OrderPlaced(orderID, o.amountSats, o.priceTps, 0, msg.sender);
    }

    function cancelOrder(uint256 orderID) public {
        Order storage o = orderbook[orderID];

        require(o.amountSats != 0, "Order not found");
        require(msg.sender == o.maker, "Order not yours");

        uint256 tokToSend;
        if (o.amountSats > 0) {
            // Ask, return stake
            tokToSend = o.stakedTok;
        } else {
            // Bid, return liquidity
            tokToSend = uint256(uint128(-o.amountSats) * o.priceTps) / tokDiv;
        }

        emit OrderCancelled(orderID);

        // Delete order now. Prevent reentrancy issues.
        delete orderbook[orderID];

        _transferToSender(tokToSend);
    }

    /**
     * @notice Sell BTC receive ERC-20.
     */
    function initiateSell(uint256 orderID, uint128 amountSats)
        public
        payable
        returns (uint256 escrowID)
    {
        escrowID = nextEscrowID++;

        Order storage o = orderbook[orderID];
        require(o.amountSats < 0, "Order already filled");
        require(amountSats <= uint128(-o.amountSats), "Amount incorrect");
        require(amountSats % minOrderSats == 0, "Odd-sized amount");

        // Verify correct stake amount.
        uint256 totalTok = (uint256(amountSats) * uint256(o.priceTps)) / tokDiv;
        uint256 expectedStakeTok = (totalTok * stakePercent) / 100;

        // Receive stake. Validates that msg.value == expectedStateTok (for ether based payments)
        _transferFromSender(expectedStakeTok);

        // Put the COMBINED eth (buyer's stake + the order amount) into escrow.
        Escrow storage e = escrows[escrowID];
        e.destScriptHash = o.scriptHash;
        e.amountSatsDue = amountSats;
        e.deadline = uint128(block.timestamp + 24 hours);
        e.escrowTok = totalTok + expectedStakeTok;
        e.successRecipient = msg.sender;
        e.timeoutRecipient = o.maker;

        // Order matched.
        emit OrderMatched(
            escrowID,
            orderID,
            o.amountSats,
            int128(amountSats),
            o.priceTps,
            expectedStakeTok,
            e.deadline,
            o.maker,
            msg.sender,
            o.scriptHash
        );

        // Update the amount of liquidity in this order
        o.amountSats += int128(amountSats);

        // Delete the order if there is no more liquidity left
        if (o.amountSats == 0) {
            delete orderbook[orderID];
        }

        addOpenEscrow(e.destScriptHash, amountSats);
    }

    /**
     * @notice Buy bitcoin, paying via ERC-20
     */
    function initiateBuy(
        uint256 orderID,
        uint128 amountSats,
        bytes20 destScriptHash
    ) public payable returns (uint256 escrowID) {
        escrowID = nextEscrowID++;
        Order storage o = orderbook[orderID];
        require(o.amountSats > 0, "Order already filled"); // Must be a bid
        require(o.amountSats >= int128(amountSats), "Amount incorrect");
        require(amountSats % minOrderSats == 0, "Odd-sized amount");

        uint256 totalValue = (amountSats * o.priceTps) / tokDiv;
        uint256 portionOfStake = (o.stakedTok * uint256(amountSats)) /
            uint256(uint128(o.amountSats));

        // Receive sale payment
        _transferFromSender(totalValue);

        // Put the COMBINED eth--the value being sold, plus the liquidity
        // maker's stake--into escrow. If the maker sends bitcoin as
        // expected and provides proof, they get both (stake back + proceeds).
        // If maker fails to deliver, they're slashed and seller gets both.
        Escrow storage e = escrows[escrowID];
        e.destScriptHash = destScriptHash;
        e.amountSatsDue = amountSats;
        e.deadline = uint128(block.timestamp + 24 hours);
        e.escrowTok = portionOfStake + totalValue;
        e.successRecipient = o.maker;
        e.timeoutRecipient = msg.sender;

        // Order matched.
        emit OrderMatched(
            escrowID,
            orderID,
            o.amountSats,
            int128(amountSats),
            o.priceTps,
            0,
            e.deadline,
            o.maker,
            msg.sender,
            destScriptHash
        );

        o.amountSats -= int128(amountSats);
        o.stakedTok -= portionOfStake;

        // Delete the order if its been filled.
        if (o.amountSats == 0) {
            delete orderbook[orderID];
        }

        addOpenEscrow(destScriptHash, amountSats);
    }

    /**
     * @notice Seller proves they've sent bitcoin, completing the sale.
     */
    function proveSettlement(
        uint256 escrowID,
        uint256 bitcoinBlockNum,
        BtcTxProof calldata bitcoinTransactionProof,
        uint256 txOutIx
    ) public {
        Escrow storage e = escrows[escrowID];
        require(e.successRecipient != address(0), "Escrow not found");
        require(msg.sender == e.successRecipient, "Wrong caller");

        // The blockheight of the proof must be > this value.
        bytes32 recKey = openEscrowKey(e.destScriptHash, e.amountSatsDue);
        uint256 minBlockHeightExclusive = openEscrows[recKey];
        require(
            bitcoinBlockNum > minBlockHeightExclusive,
            "Can't use old proof of payment"
        );

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

        // Delete the openEscrow key after the _transfer, since it blocks new actions from happening
        // in case of a re-entrancy attack. We'd rather fail closed, than open.
        delete openEscrows[recKey];
    }

    function slash(uint256 escrowID) public {
        Escrow storage e = escrows[escrowID];

        require(msg.sender == e.timeoutRecipient, "Wrong caller");
        require(e.deadline < block.timestamp, "Too early");

        uint256 tokToSend = e.escrowTok;
        emit EscrowSlashed(escrowID, e.deadline, msg.sender, tokToSend);

        delete escrows[escrowID];

        _transferToSender(tokToSend);

        // Delete the openEscrow key after the _transfer, since it blocks new actions from happening
        // in case of a re-entrancy attack. We'd rather fail closed, than open.
        delete openEscrows[openEscrowKey(e.destScriptHash, e.amountSatsDue)];
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

    function openEscrowKey(bytes20 scriptHash, uint256 amountSats)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(scriptHash, amountSats));
    }

    function addOpenEscrow(bytes20 scriptHash, uint256 amountSats) private {
        bytes32 recKey = openEscrowKey(scriptHash, amountSats);
        uint256 existingOpenEscrow = openEscrows[recKey];
        require(existingOpenEscrow == 0, "Escrow collision, please retry");
        // Say Alice opens an escrow at block height 1000. She submits a Bitcoin transaction.
        // A normal two-block reorg occurs, and her transaction ends up confirmed at block height 999.
        openEscrows[recKey] =
            btcVerifier.mirror().getLatestBlockHeight() -
            minConfirmations;
    }

    // Returns true if there is an escrow inflight for this
    // scriptHash/amountSats pair, otherwise false.
    function openEscrowInflight(bytes20 scriptHash, uint256 amountSats)
        public
        view
        returns (bool)
    {
        uint256 n = openEscrows[openEscrowKey(scriptHash, amountSats)];
        return n != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BtcTxProof.sol";
import "./IBtcMirror.sol";

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

    // Returns the underlying IBtcMirror instance associated with this verifier.
    function mirror() external view returns (IBtcMirror);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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
pragma solidity >=0.8.0;

/** @notice Provides Bitcoin block hashes. */
interface IBtcMirror {
    /** @notice Returns the Bitcoin block hash at a specific height. */
    function getBlockHash(uint256 number) external view returns (bytes32);

    /** @notice Returns the height of the latest block (tip of the chain). */
    function getLatestBlockHeight() external view returns (uint256);

    /** @notice Returns the timestamp of the lastest block, as Unix seconds. */
    function getLatestBlockTime() external view returns (uint256);

    /** @notice Submits a new Bitcoin chain segment. */
    function submit(uint256 blockHeight, bytes calldata blockHeaders) external;
}