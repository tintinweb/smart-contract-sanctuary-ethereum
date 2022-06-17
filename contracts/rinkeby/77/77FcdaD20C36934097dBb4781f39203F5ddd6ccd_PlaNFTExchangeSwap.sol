//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ExchangeSwap.sol";

contract PlaNFTExchangeSwap is ExchangeSwap {
    string public constant name = "Project PlaNFT Exchange";

    string public constant version = "1.0";

    string public constant codename = "Lambton Worm";

    /**
     * @dev Initialize a PlaNFTExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    constructor(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        address protocolFeeAddress
    ) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ExchangeCoreSwap.sol";

/**
 * @title Exchange
 * @author Project Wyvern Developers
 */
contract ExchangeSwap is ExchangeCoreSwap {
    /**
     * @dev Call guardedArrayReplace - library function exposed for testing.
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) public pure returns (bytes memory) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    /**
     * Test copy byte array
     *
     * @param arrToCopy Array to copy
     * @return byte array
     */
    function testCopy(bytes memory arrToCopy) public pure returns (bytes memory) {
        bytes memory arr = new bytes(arrToCopy.length);
        uint256 index;
        assembly {
            index := add(arr, 0x20)
        }
        ArrayUtils.unsafeWriteBytes(index, arrToCopy);
        return arr;
    }

    /**
     * Test write address to bytes
     *
     * @param addr Address to write
     * @return byte array
     */
    function testCopyAddress(address addr) public pure returns (bytes memory) {
        bytes memory arr = new bytes(0x14);
        uint256 index;
        assembly {
            index := add(arr, 0x20)
        }
        ArrayUtils.unsafeWriteAddress(index, addr);
        return arr;
    }

    function makeOrder(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns
    ) internal pure returns (Order memory) {
        return
            Order(
                addrs[0],  // exchange
                addrs[1],  // maker
                addrs[2],  // taker
                side,
                howToCall,
                addrs[3],  // maker erc20 token
                uints[0],  // maker erc20 amount
                addrs[4],  // taker erc20 addr
                uints[1],  // taker erc20 amount
                tokens[0],  // maker erc721 tokens
                datas[0],  // maker calldatas
                replacementPatterns[0],  // maker replacementPatterns
                tokens[1],  // taker erc721 tokens
                datas[1],  // taker calldatas
                replacementPatterns[1],  // taker replacementPatterns
                uints[2],  // listingTime
                uints[3],  // expirationTime
                uints[4]   // salt
            );
    }

    /**
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns
    ) public pure returns (bytes32) {
        return hashOrder(makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns));
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns
    ) public pure returns (bytes32) {
        return hashToSign(makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns));
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns
    ) public view returns (bool) {
        return
            validateOrderParameters(
                makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns)
            );
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        Order memory order = makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns);
        return validateOrder(hashToSign(order), order, Sig(v, r, s));
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        bool orderbookInclusionDesired
    ) public {
        return
            approveOrder(
                makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns),
                orderbookInclusionDesired
            );
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[5] memory addrs,
        uint256[5] memory uints,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall,
        address[][2] memory tokens,
        bytes[][2] memory datas,
        bytes[][2] memory replacementPatterns,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        return
            cancelOrder(
                makeOrder(addrs, uints, side, howToCall, tokens, datas, replacementPatterns),
                Sig(v, r, s)
            );
    }

    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address[10] memory addrs,
        uint256[10] memory uints,
        uint8[6] memory sidesKindsHowToCalls,
        address[][4] memory tokens,
        bytes[][4] memory datas,
        bytes[][4] memory replacementPatterns
    ) public view returns (bool) {
        Order memory buy = Order(
            addrs[0],  // exchange
            addrs[1],  // maker
            addrs[2],  // taker
            SaleKindInterface.Side(sidesKindsHowToCalls[0]),  // side
            AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[2]),  // how to call
            addrs[3],  // maker erc20 token
            uints[0],  // maker erc20 amount
            addrs[4],  // taker erc20 addr
            uints[1],  // taker erc20 amount
            tokens[0],  // maker erc721 tokens
            datas[0],  // maker calldatas
            replacementPatterns[0], // maker replacementPatterns
            tokens[1],  // taker erc721 tokens
            datas[1],  // taker calldatas
            replacementPatterns[1],  // taker replacementPatterns
            uints[2],  // listingTime
            uints[3],  // expirationTime
            uints[4]   // salt
        );
        Order memory sell = Order(
            addrs[5],  // exchange
            addrs[6],  // maker
            addrs[7],  // taker
            SaleKindInterface.Side(sidesKindsHowToCalls[3]),  // side
            AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[5]),  // how to call
            addrs[8],  // maker erc20 token
            uints[5],  // maker erc20 amount
            addrs[9],  // taker erc20 addr
            uints[6],  // taker erc20 amount
            tokens[2],  // maker erc721 tokens
            datas[2],  // maker calldatas
            replacementPatterns[2], // maker replacementPatterns
            tokens[3],  // taker erc721 tokens
            datas[3],  // taker calldatas
            replacementPatterns[3],  // taker replacementPatterns
            uints[7],  // listingTime
            uints[8],  // expirationTime
            uints[9]   // salt
        );
        return ordersCanMatch(buy, sell);
    }

    /**
     * @dev Return whether or not two orders' calldata specifications can match
     * @param buyCalldata Buy-side order calldata
     * @param buyReplacementPattern Buy-side order calldata replacement mask
     * @param sellCalldata Sell-side order calldata
     * @param sellReplacementPattern Sell-side order calldata replacement mask
     * @return Whether the orders' calldata can be matched
     */
    function orderCalldataCanMatch(
        bytes memory buyCalldata,
        bytes memory buyReplacementPattern,
        bytes memory sellCalldata,
        bytes memory sellReplacementPattern
    ) public pure returns (bool) {
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[10] memory addrs,
        uint256[10] memory uints,
        uint8[4] memory sidesHowToCalls,
        address[][4] memory tokens,
        bytes[][4] memory datas,
        bytes[][4] memory replacementPatterns,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) public payable {
        return
            atomicMatch(
                Order(
                    addrs[0],  // exchange
                    addrs[1],  // maker
                    addrs[2],  // taker
                    SaleKindInterface.Side(sidesHowToCalls[0]),  // side
                    AuthenticatedProxy.HowToCall(sidesHowToCalls[1]),  // how to call
                    addrs[3],  // maker erc20 token
                    uints[0],  // maker erc20 amount
                    addrs[4],  // taker erc20 addr
                    uints[1],  // taker erc20 amount
                    tokens[0],  // maker erc721 tokens
                    datas[0],  // maker calldatas
                    replacementPatterns[0],  // maker replacementPatterns
                    tokens[1],  // taker erc721 tokens
                    datas[1],  // taker calldatas
                    replacementPatterns[1],  // taker replacementPatterns
                    uints[2],  // listingTime
                    uints[3],  // expirationTime
                    uints[4]   // salt
                ),
                Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                Order(
                    addrs[5],  // exchange
                    addrs[6],  // maker
                    addrs[7],  // taker
                    SaleKindInterface.Side(sidesHowToCalls[2]),  // side
                    AuthenticatedProxy.HowToCall(sidesHowToCalls[3]),  // how to call
                    addrs[8],  // maker erc20 token
                    uints[5],  // maker erc20 amount
                    addrs[9],  // taker erc20 addr
                    uints[6],  // taker erc20 amount
                    tokens[2],  // maker erc721 tokens
                    datas[2],  // maker calldatas
                    replacementPatterns[2],  // maker replacementPatterns
                    tokens[3],  // taker erc721 tokens
                    datas[3],  // taker calldatas
                    replacementPatterns[3],  // taker replacementPatterns
                    uints[7],  // listingTime
                    uints[8],  // expirationTime
                    uints[9]   // salt
                ),
                Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }
}

// SPDX-License-Identifier: MIT

/*

  Decentralized digital asset exchange. Supports any digital asset that can be represented on the Ethereum blockchain (i.e. - transferred in an Ethereum transaction or sequence of transactions).

  Let us suppose two agents interacting with a distributed ledger have utility functions preferencing certain states of that ledger over others.
  Aiming to maximize their utility, these agents may construct with their utility functions along with the present ledger state a mapping of state transitions (transactions) to marginal utilities.
  Any composite state transition with positive marginal utility for and enactable by the combined permissions of both agents thus is a mutually desirable trade, and the trustless
  code execution provided by a distributed ledger renders the requisite atomicity trivial.

  Relative to this model, this instantiation makes two concessions to practicality:
  - State transition preferences are not matched directly but instead intermediated by a standard of tokenized value.
  - A small fee can be charged in WYV for order settlement in an amount configurable by the frontend hosting the orderbook.

  Solidity presently possesses neither a first-class functional typesystem nor runtime reflection (ABI encoding in Solidity), so we must be a bit clever in implementation and work at a lower level of abstraction than would be ideal.

  We elect to utilize the following structure for the initial version of the protocol:
  - Buy-side and sell-side orders each provide calldata (bytes) - for a sell-side order, the state transition for sale, for a buy-side order, the state transition to be bought.
    Along with the calldata, orders provide `replacementPattern`: a bytemask indicating which bytes of the calldata can be changed (e.g. NFT destination address).
    When a buy-side and sell-side order are matched, the desired calldatas are unified, masked with the bytemasks, and checked for agreement.
    This alone is enough to implement common simple state transitions, such as "transfer my CryptoKitty to any address" or "buy any of this kind of nonfungible token".
  - Orders (of either side) can optionally specify a static (no state modification) callback function, which receives configurable data along with the actual calldata as a parameter.
    Although it requires some encoding acrobatics, this allows for arbitrary transaction validation functions.
    For example, a buy-sider order could express the intent to buy any CryptoKitty with a particular set of characteristics (checked in the static call),
    or a sell-side order could express the intent to sell any of three ENS names, but not two others.
    Use of the EVM's STATICCALL opcode, added in Ethereum Metropolis, allows the static calldata to be safely specified separately and thus this kind of matching to happen correctly
    - that is to say, wherever the two (transaction => bool) functions intersect.

  Future protocol versions may improve upon this structure in capability or usability according to protocol user feedback demand, with upgrades enacted by the Wyvern DAO.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../registry/ProxyRegistry.sol";
import "../registry/TokenTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "../common/ArrayUtils.sol";
import "../common/ReentrancyGuarded.sol";
import "./SaleKindInterface.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers
 */
contract ExchangeCoreSwap is ReentrancyGuarded, Ownable {
    using SafeMath for uint256;

    /* The token used to pay exchange fees. */
    ERC20 public exchangeToken;

    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /* User order start time. */
    mapping(address => uint256) public startTimes;

    /* Protocol maker fee, in basis points. Paid to owner (who can change it). */
    uint256 public protocolFee = 10;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Token address of maker's erc20. */
        address makerErc20Address;
        /* Amount of maker's erc20. */
        uint256 makerErc20Amount;
        /* Token address of taker's erc20. */
        address takerErc20Address;
        /* Amount of taker's erc20. */
        uint256 takerErc20Amount;
        /* Address of maker's ERC721 tokens. */
        address[] makerErc721Targets;
        /* Calldatas corresponding to maker's ERC721 tokens. */
        bytes[] makerCalldatas;
        /* Calldata replacement patterns for maker's calldatas, or an empty byte array for no replacement. */
        bytes[] makerReplacementPatterns;
        /* Address of taker's ERC721 tokens. */
        address[] takerErc721Targets;
        /* Calldatas corresponding to taker's ERC721 tokens. */
        bytes[] takerCalldatas;
        /* Calldata replacement patterns for taker's calldatas, or an empty byte array for no replacement. */
        bytes[] takerReplacementPatterns;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        SaleKindInterface.Side side,
        AuthenticatedProxy.HowToCall howToCall
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        address indexed makerErc20Address,
        uint256 makerErc20Amount,
        address indexed takerErc20Address,
        uint256 takerErc20Amount,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        bytes32 indexed metadata
    );
    event RelaySetFee(address owner, uint256 relaySetFeeTime, uint256 relayExchangeFee);
    event SetFee(address owner, uint256 exchangeFee);
    event RelaySetRecipientFee(address owner, address relayRewardFeeRecipient, uint256 relaySetFeeRecipientTime);
    event SetFeeRecipient(address owner, address rewardFeeRecipient);
    event SetStartTime(address owner, uint256 startTime);

    function setExchangeToken(address token) public onlyOwner {
      exchangeToken = ERC20(token);
    }

    function setStartTime(uint256 startTime) public {
        startTimes[msg.sender] = startTime;
        emit SetStartTime(msg.sender, startTime);
    }

    /**
     * @dev Change the minimum taker fee paid to the protocol (owner only)
     * @param newProtocolFee New fee to set in basis points
     */
    function changeProtocolFee(uint256 newProtocolFee) public onlyOwner {
        protocolFee = newProtocolFee;
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient) public onlyOwner {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return result of the call (success or failure)
     */
    function staticCall(
        address target,
        bytes memory data,
        bytes memory extradata
    ) public view returns (bool result) {
        bytes memory combined = new bytes(data.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, data);
        assembly {
            result := staticcall(gas(), target, add(combined, 0x20), mload(combined), mload(0x40), 0)
        }
        return result;
    }

    /**
     * Calculate size of an order struct when tightly packed
     *
     * @param order order to calculate size of
     * @return Size in bytes
     */
    function sizeOf(Order memory order) internal pure returns (uint256) {
        uint256 bytesLength = 0;
        for (uint256 i = 0; i < order.makerCalldatas.length; ++i) {
            bytesLength += order.makerCalldatas[i].length;
        }
        for (uint256 i = 0; i < order.makerReplacementPatterns.length; ++i) {
            bytesLength += order.makerReplacementPatterns[i].length;
        }
        for (uint256 i = 0; i < order.takerCalldatas.length; ++i) {
            bytesLength += order.takerCalldatas[i].length;
        }
        for (uint256 i = 0; i < order.takerReplacementPatterns.length; ++i) {
            bytesLength += order.takerReplacementPatterns[i].length;
        }

        return ((0x14 * (5 + order.makerErc721Targets.length + order.takerErc721Targets.length)) +
            (0x20 * 5) +
            2 +
            bytesLength);
    }

    /**
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @return hash of order
     */
    function hashOrder(Order memory order) internal pure returns (bytes32 hash) {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = sizeOf(order);
        bytes memory array = new bytes(size);

        uint256 index;
        assembly {
            index := add(array, 0x20)
        }

        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteAddress(index, order.makerErc20Address);
        index = ArrayUtils.unsafeWriteUint(index, order.makerErc20Amount);
        index = ArrayUtils.unsafeWriteAddress(index, order.takerErc20Address);
        index = ArrayUtils.unsafeWriteUint(index, order.takerErc20Amount);

        for (uint256 i = 0; i < order.makerErc721Targets.length; i++) {
            index = ArrayUtils.unsafeWriteAddress(index, order.makerErc721Targets[i]);
        }

        for (uint256 i = 0; i < order.makerCalldatas.length; i++) {
            index = ArrayUtils.unsafeWriteBytes(index, order.makerCalldatas[i]);
        }

        for (uint256 i = 0; i < order.makerReplacementPatterns.length; i++) {
            index = ArrayUtils.unsafeWriteBytes(index, order.makerReplacementPatterns[i]);
        }

        for (uint256 i = 0; i < order.takerErc721Targets.length; i++) {
            index = ArrayUtils.unsafeWriteAddress(index, order.takerErc721Targets[i]);
        }

        for (uint256 i = 0; i < order.takerCalldatas.length; i++) {
            index = ArrayUtils.unsafeWriteBytes(index, order.takerCalldatas[i]);
        }

        for (uint256 i = 0; i < order.takerReplacementPatterns.length; i++) {
            index = ArrayUtils.unsafeWriteBytes(index, order.takerReplacementPatterns[i]);
        }

        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }

        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOrder(order)));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param sig ECDSA signature
     * @return hash Hash of order require validated
     */
    function requireValidOrder(Order memory order, Sig memory sig) internal view returns (bytes32) {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
        return hash;
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order) internal view returns (bool) {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (order.listingTime < startTimes[order.maker]) {
            return false;
        }

        /* Order must contain one maker ERC721 at lease. */
        if (order.makerErc721Targets.length == 0) {
            return false;
        }

        /* Order must contain one taker ERC721 at lease. */
        if (order.takerErc721Targets.length == 0) {
            return false;
        }

        /* Count of maker's ERC721 items must be equal to calldatas. */
        if (order.makerErc721Targets.length != order.makerCalldatas.length) {
            return false;
        }

        /* Count of maker's calldatas must be equal to replacement patterns. */
        if (order.makerCalldatas.length != order.makerReplacementPatterns.length) {
            return false;
        }

        /* Count of taker's ERC721 items must be equal to calldatas. */
        if (order.takerErc721Targets.length != order.takerCalldatas.length) {
            return false;
        }

        /* Count of taker's calldatas must be equal to replacement patterns. */
        if (order.takerCalldatas.length != order.takerReplacementPatterns.length) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     * @return valid Valid for hash and order
     */
    function validateOrder(
        bytes32 hash,
        Order memory order,
        Sig memory sig
    ) internal view returns (bool) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Order authentication. Order must be either:
        /* (a) previously approved */
        if (approvedOrders[hash]) {
            return true;
        }

        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired) internal {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker, "PlaExchange: caller must be order maker");

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);

        /* Assert order has not already been approved. */
        require(!approvedOrders[hash]);

        /* EFFECTS */

        /* Mark order as approved. */
        approvedOrders[hash] = true;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.side, order.howToCall);
        }
        {
            emit OrderApprovedPartTwo(
                hash,
                order.makerErc20Address,
                order.makerErc20Amount,
                order.takerErc20Address,
                order.takerErc20Amount,
                order.listingTime,
                order.expirationTime,
                order.salt,
                orderbookInclusionDesired
            );
        }
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param sig ECDSA signature
     */
    function cancelOrder(Order memory order, Sig memory sig) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Return whether or not ERC721 items of two orders can be matched with each other (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function erc721ItemsCanMatch(Order memory buy, Order memory sell) internal pure returns (bool) {
        if (buy.makerErc721Targets.length != sell.takerErc721Targets.length) return false;

        if (buy.takerErc721Targets.length != sell.makerErc721Targets.length) return false;

        for (uint256 i = 0; i < buy.makerErc721Targets.length; ++i) {
            if (buy.makerErc721Targets[i] != sell.takerErc721Targets[i]) return false;
        }

        for (uint256 i = 0; i < buy.takerErc721Targets.length; ++i) {
            if (buy.takerErc721Targets[i] != sell.makerErc721Targets[i]) return false;
        }

        return true;
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell) internal view returns (bool) {
        return (/* Must be opposite-side. */
        (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Must match ERC20. */
            (buy.makerErc20Address == address(0) ||
                (buy.makerErc20Address == sell.takerErc20Address && buy.makerErc20Amount == sell.takerErc20Amount)) &&
            (buy.takerErc20Address == address(0) ||
                (buy.takerErc20Address == sell.makerErc20Address && buy.takerErc20Amount == sell.makerErc20Amount)) &&
            (sell.makerErc20Address == address(0) ||
                (sell.makerErc20Address == buy.takerErc20Address && sell.makerErc20Amount == buy.takerErc20Amount)) &&
            (sell.takerErc20Address == address(0) ||
                (sell.takerErc20Address == buy.makerErc20Address && sell.takerErc20Amount == buy.makerErc20Amount)) &&
            /* ERC721 items must match. */
            erc721ItemsCanMatch(buy, sell) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime));
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by
     *       a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(
        Order memory buy,
        Sig memory buySig,
        Order memory sell,
        Sig memory sellSig,
        bytes32 metadata
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy));
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell));
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxySeller = registry.proxies(sell.maker);
        OwnableDelegateProxy delegateProxyBuyer = registry.proxies(buy.maker);

        /* Proxy must exist. */
        require(delegateProxySeller != OwnableDelegateProxy(payable(0)), "Delegate proxy does not exist for seller");
        require(delegateProxyBuyer != OwnableDelegateProxy(payable(0)), "Delegate proxy does not exist for buyer");

        /* Assert implementation. */
        require(
            delegateProxySeller.implementation() == registry.delegateProxyImplementation() &&
            delegateProxyBuyer.implementation() == registry.delegateProxyImplementation(),
            "Incorrect delegate proxy implementation for maker"
        );

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* INTERACTIONS */

        /* Transfer ERC20. */
        transferTokens(sell.makerErc20Address, sell.maker, buy.maker, sell.makerErc20Amount);
        transferTokens(buy.makerErc20Address, buy.maker, sell.maker, buy.makerErc20Amount);

        uint256 fee = protocolFee.mul(10 ** 18).div(INVERSE_BASIS_POINT);
        transferTokens(address(exchangeToken), sell.maker, protocolFeeRecipient, fee);
        transferTokens(address(exchangeToken), buy.maker, protocolFeeRecipient, fee);

        /* Transfer ERC721 items. */
        for (uint256 i = 0; i < sell.makerErc721Targets.length; ++i) {
            uint256 size;
            address target = sell.makerErc721Targets[i];
            assembly {
                size := extcodesize(target)
            }

            /* Must match calldata after replacement, if specified. */
            if (sell.makerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    sell.makerCalldatas[i],
                    buy.takerCalldatas[i],
                    sell.makerReplacementPatterns[i]
                );
            }

            if (buy.takerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    buy.takerCalldatas[i],
                    sell.makerCalldatas[i],
                    buy.takerReplacementPatterns[i]
                );
            }

            require(ArrayUtils.arrayEq(sell.makerCalldatas[i], buy.takerCalldatas[i]));

            /* Execute specified call through proxy. */
            require(AuthenticatedProxy(payable(delegateProxySeller)).proxy(sell.makerErc721Targets[i], sell.howToCall, sell.makerCalldatas[i]));
        }

        for (uint256 i = 0; i < sell.takerErc721Targets.length; ++i) {
            uint256 size;
            address target = sell.takerErc721Targets[i];
            assembly {
                size := extcodesize(target)
            }

            /* Must match calldata after replacement, if specified. */
            if (sell.takerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    sell.takerCalldatas[i],
                    buy.makerCalldatas[i],
                    sell.takerReplacementPatterns[i]
                );
            }

            if (buy.makerReplacementPatterns[i].length > 0) {
                ArrayUtils.guardedArrayReplace(
                    buy.makerCalldatas[i],
                    sell.takerCalldatas[i],
                    buy.makerReplacementPatterns[i]
                );
            }

            require(ArrayUtils.arrayEq(sell.takerCalldatas[i], buy.makerCalldatas[i]));

            /* Execute specified call through proxy. */
            require(AuthenticatedProxy(payable(delegateProxyBuyer)).proxy(sell.takerErc721Targets[i], sell.howToCall, sell.takerCalldatas[i]));
        }

        /* Log match event. */
        emit OrdersMatched(buyHash, sellHash, sell.maker, buy.maker, metadata);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry is Ownable {

    /* DelegateProxy implementation contract. Must be initialized. */
    address public delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public proxies;

    /* Contracts pending access. */
    mapping(address => uint) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the Wyvern DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the Wyvern and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint public DELAY_PERIOD = 2 weeks;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to nable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < block.timestamp));
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */    
    function revokeAuthentication (address addr)
        public
        onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy()
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[msg.sender] == OwnableDelegateProxy(payable(0)), "User already has a proxy");
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }

}

// SPDX-License-Identifier: MIT

/*

  Token transfer proxy. Uses the authentication table of a ProxyRegistry contract to grant ERC20 `transferFrom` access.
  This means that users only need to authorize the proxy contract once for all future protocol versions.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ProxyRegistry.sol";

contract TokenTransferProxy {

    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
        public
        returns (bool)
    {
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT

/* 

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

pragma solidity ^0.8.13;

import "./ProxyRegistry.sol";
import "../common/TokenRecipient.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";

/**
 * @title AuthenticatedProxy
 * @author Project Wyvern Developers
 */
contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize (address addrUser, ProxyRegistry addrRegistry)
        public
    {
        require(!initialized);
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
        public
    {
        require(msg.sender == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes memory data)
        public
        returns (bool result)
    {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)), "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access");
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     * 
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param data Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes memory data)
        public
    {
        require(proxy(dest, howToCall, data));
    }

}

// SPDX-License-Identifier: MIT

/*

  Various functions for manipulating arrays in Solidity.
  This library is completely inlined and does not need to be deployed or linked.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ArrayUtils
 * @author Project Wyvern Developers
 */
library ArrayUtils {
    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint256 words = array.length / 0x20;
        uint256 index = words * 0x20;
        assert(index / 0x20 == words);
        uint256 i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint256 index, bytes memory source) internal pure returns (uint256) {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint256 index, address source) internal pure returns (uint256) {
        uint256 conv = uint160(source);
        conv = conv << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }

        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint256 index, uint256 source) internal pure returns (uint256) {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint256 index, uint8 source) internal pure returns (uint256) {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }
}

// SPDX-License-Identifier: MIT

/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

pragma solidity ^0.8.13;

/**
 * @title ReentrancyGuarded
 * @author Project Wyvern Developers
 */
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

// SPDX-License-Identifier: MIT

/*

  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.

  Separated into a library for convenience, all the functions are inlined.

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title SaleKindInterface
 * @author Project Wyvern Developers
 */
library SaleKindInterface {
    /**
     * Side: buy or sell.
     */
    enum Side {
        Buy,
        Sell
    }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind {
        FixedPrice,
        DutchAuction
    }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint256 expirationTime) internal pure returns (bool) {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint256 listingTime, uint256 expirationTime) internal view returns (bool) {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        Side side,
        SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) internal view returns (uint256 finalPrice) {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint256 diff = SafeMath.div(
                SafeMath.mul(extra, SafeMath.sub(block.timestamp, listingTime)),
                SafeMath.sub(expirationTime, listingTime)
            );
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT

/*

  WyvernOwnableDelegateProxy

*/

pragma solidity ^0.8.13;

import "./proxy/OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);

        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import './Proxy.sol';
import './OwnedUpgradeabilityStorage.sol';

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev This event will be emitted every time the implementation gets upgraded
  * @param implementation_ representing the address of the upgraded implementation
  */
  event Upgraded(address indexed implementation_);

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() override(Proxy, OwnedUpgradeabilityStorage) public view returns (address) {
    return _implementation;
  }

  /**
  * @dev Tells the proxy type (EIP 897)
  * @return proxyTypeId Proxy type, 2 for forwarding proxy
  */
  function proxyType() override(Proxy, OwnedUpgradeabilityStorage) public pure returns (uint256 proxyTypeId) {
    return 2;
  }

  /**
  * @dev Upgrades the implementation address
  * @param implementation_ representing the address of the new implementation to be set
  */
  function _upgradeTo(address implementation_) internal {
    require(_implementation != implementation_);
    _implementation = implementation_;
    emit Upgraded(_implementation);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the proxy owner
   * @return the address of the proxy owner
   */
  function proxyOwner() public view returns (address) {
    return upgradeabilityOwner();
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
   * @param implementation_ representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation_) public onlyProxyOwner {
    _upgradeTo(implementation_);
  }

  /**
   * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
   * and delegatecall the new implementation for initialization.
   * @param implementation_ representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation_, bytes memory data) payable public onlyProxyOwner {
    upgradeTo(implementation_);
    (bool success,) = address(this).delegatecall(data);
    require(success, "Call failed after proxy upgrade");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() public pure virtual returns (uint256 proxyTypeId);

    function call() internal {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    /**
     * @dev Receive function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    receive() external payable {
        call();
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        call();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract OwnedUpgradeabilityStorage {

  // Current implementation
  address internal _implementation;

  // Owner of the contract
  address private _upgradeabilityOwner;

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function upgradeabilityOwner() public view returns (address) {
    return _upgradeabilityOwner;
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
    _upgradeabilityOwner = newUpgradeabilityOwner;
  }

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() virtual public view returns (address) {
    return _implementation;
  }

  /**
  * @dev Tells the proxy type (EIP 897)
  * @return proxyTypeId Proxy type, 2 for forwarding proxy
  */
  function proxyType() virtual public pure returns (uint256 proxyTypeId) {
    return 2;
  }
}

// SPDX-License-Identifier: MIT

/*

  Token recipient. Modified very slightly from the example on http://ethereum.org/dao (just to index log parameters).

*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenRecipient
 * @author Project Wyvern Developers
 */
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}