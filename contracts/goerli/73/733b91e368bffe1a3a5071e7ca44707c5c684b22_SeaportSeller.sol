// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    OrderType,
    BasicOrderType,
    ItemType,
    Side
} from "./ConsiderationEnums.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-1155 token contract
interface IERC1155 {
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event URI(string _value, uint256 indexed _id);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory _owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function isApprovedForAll(address, address) external view returns (bool);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-721 token contract
interface IERC721 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id);

    function approve(address _spender, uint256 _id) external;

    function balanceOf(address _owner) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function name() external view returns (string memory);

    function ownerOf(uint256 _id) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _id) external view returns (string memory);

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for Minter module contract
interface IMinter {
    function getPermissions() external view returns (Permission[] memory permissions);

    function supply() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeaves() external view returns (bytes32[] memory leaves);

    function getUnhashedLeaves() external view returns (bytes[] memory leaves);

    function getPermissions() external view returns (Permission[] memory permissions);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for generic Protoform contract
interface IProtoform {
    /// @dev Event log for modules that are enabled on a vault
    /// @param _vault The vault deployed
    /// @param _modules The modules being activated on deployed vault
    event ActiveModules(address indexed _vault, address[] _modules);

    function generateMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes32[] memory tree);

    function generateUnhashedMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes[] memory tree);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface of ERC-1155 token contract for raes
interface IRae {
    /// @dev Emitted when caller is not required address
    error InvalidSender(address _required, address _provided);
    /// @dev Emitted when owner signature is invalid
    error InvalidSignature(address _signer, address _owner);
    /// @dev Emitted when deadline for signature has passed
    error SignatureExpired(uint256 _timestamp, uint256 _deadline);
    /// @dev Emitted when royalty is set to value greater than 100%
    error InvalidRoyalty(uint256 _percentage);
    /// @dev Emitted when new controller is zero address
    error ZeroAddress();

    /// @dev Event log for updating the Controller of the token contract
    /// @param _newController Address of the controller
    event ControllerTransferred(address indexed _newController);
    /// @dev Event log for updating the metadata contract for a token type
    /// @param _metadata Address of the metadata contract that URI data is stored on
    /// @param _id ID of the token type
    event SetMetadata(address indexed _metadata, uint256 _id);
    /// @dev Event log for updating the royalty of a token type
    /// @param _receiver Address of the receiver of secondary sale royalties
    /// @param _id ID of the token type
    /// @param _percentage Royalty percent on secondary sales
    event SetRoyalty(address indexed _receiver, uint256 indexed _id, uint256 _percentage);
    /// @dev Event log for approving a spender of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    event SingleApproval(
        address indexed _owner,
        address indexed _operator,
        uint256 indexed _id,
        bool _approved
    );
    /// @notice Event log for Minting Raes of ID to account _to
    /// @param _to Address to mint rae tokens to
    /// @param _id Token ID to mint
    /// @param _amount Number of tokens to mint
    event MintRaes(address indexed _to, uint256 indexed _id, uint256 _amount);

    /// @notice Event log for Burning raes of ID from account _from
    /// @param _from Address to burn rae tokens from
    /// @param _id Token ID to burn
    /// @param _amount Number of tokens to burn
    event BurnRaes(address indexed _from, uint256 indexed _id, uint256 _amount);

    function INITIAL_CONTROLLER() external pure returns (address);

    function VAULT_REGISTRY() external pure returns (address);

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;

    function contractURI() external view returns (string memory);

    function controller() external view returns (address controllerAddress);

    function isApproved(
        address,
        address,
        uint256
    ) external view returns (bool);

    function metadataDelegate() external view returns (address);

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external;

    function setMetadataDelegate(address _metadata) external;

    function setRoyalties(
        uint256 _id,
        address _receiver,
        uint256 _percentage
    ) external;

    function totalSupply(uint256) external view returns (uint256);

    function transferController(address _newController) external;

    function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Supply target contract
interface ISupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Transfer target contract
interface ITransfer {
    /// @dev Emitted when an ERC-20 token transfer returns a falsey value
    /// @param _token The token for which the ERC20 transfer was attempted
    /// @param _from The source of the attempted ERC20 transfer
    /// @param _to The recipient of the attempted ERC20 transfer
    /// @param _amount The amount for the attempted ERC20 transfer
    error BadReturnValueFromERC20OnTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    );
    /// @dev Emitted when the transfer of ether is unsuccessful
    error ETHTransferUnsuccessful();
    /// @dev Emitted when a batch ERC-1155 token transfer reverts
    /// @param _token The token for which the transfer was attempted
    /// @param _from The source of the attempted transfer
    /// @param _to The recipient of the attempted transfer
    /// @param _identifiers The identifiers for the attempted transfer
    /// @param _amounts The amounts for the attempted transfer
    error ERC1155BatchTransferGenericFailure(
        address _token,
        address _from,
        address _to,
        uint256[] _identifiers,
        uint256[] _amounts
    );
    /// @dev Emitted when an ERC-721 transfer with amount other than one is attempted
    error InvalidERC721TransferAmount();
    /// @dev Emitted when attempting to fulfill an order where an item has an amount of zero
    error MissingItemAmount();
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    /// @param _account The account that should contain code
    error NoContract(address _account);
    /// @dev Emitted when an ERC-20, ERC-721, or ERC-1155 token transfer fails
    /// @param _token The token for which the transfer was attempted
    /// @param _from The source of the attempted transfer
    /// @param _to The recipient of the attempted transfer
    /// @param _identifier The identifier for the attempted transfer
    /// @param _amount The amount for the attempted transfer
    error TokenTransferGenericFailure(
        address _token,
        address _from,
        address _to,
        uint256 _identifier,
        uint256 _amount
    );

    function ETHTransfer(address _to, uint256 _value) external returns (bool);

    function ERC20Transfer(
        address _token,
        address _to,
        uint256 _value
    ) external;

    function ERC721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ERC1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function ERC1155BatchTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Initialization call information
struct InitInfo {
    // Address of target contract
    address target;
    // Initialization data
    bytes data;
    // Merkle proof for call
    bytes32[] proof;
}

/// @dev Interface for Vault proxy contract
interface IVault {
    /// @dev Emitted when execution reverted with no reason
    error ExecutionReverted();
    /// @dev Emitted when the caller is not the owner
    error NotAuthorized(address _caller, address _target, bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotOwner(address _owner, address _caller);
    /// @dev Emitted when the caller is not the factory
    error NotFactory(address _factory, address _caller);
    /// @dev Emitted when passing an EOA or an undeployed contract as the target
    error TargetInvalid(address _target);

    /// @dev Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);

    function execute(
        address _target,
        bytes memory _data,
        bytes32[] memory _proof
    ) external payable returns (bool success, bytes memory response);

    function MERKLE_ROOT() external view returns (bytes32);

    function OWNER() external view returns (address);

    function FACTORY() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {InitInfo} from "./IVault.sol";

/// @dev Vault permissions
struct Permission {
    // Address of module contract
    address module;
    // Address of target contract
    address target;
    // Function selector from target contract
    bytes4 selector;
}

/// @dev Vault information
struct VaultInfo {
    // Address of Rae token contract
    address token;
    // ID of the token type
    uint256 id;
}

/// @dev Interface for VaultRegistry contract
interface IVaultRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(address indexed _vault, address indexed _token, uint256 indexed _id);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function createFor(bytes32 _merkleRoot, address _owner) external returns (address vault);

    function create(bytes32 _merkleRoot, InitInfo[] calldata _calls)
        external
        returns (address vault);

    function create(bytes32 _merkleRoot) external returns (address vault);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        InitInfo[] calldata _calls
    ) external returns (address vault, address token);

    function createCollection(bytes32 _merkleRoot, InitInfo[] calldata _calls)
        external
        returns (address vault, address token);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function factory() external view returns (address);

    function rae() external view returns (address);

    function raeImplementation() external view returns (address);

    function burn(address _from, uint256 _value) external;

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address) external view returns (address token, uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Module} from "./Module.sol";
import {IMinter} from "../interfaces/IMinter.sol";
import {ISupply} from "../interfaces/ISupply.sol";
import {IVault} from "../interfaces/IVault.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";

/// @title Minter
/// @author Tessera
/// @notice Module contract for minting a fixed supply of Raes
contract Minter is IMinter, Module {
    /// @notice Address of Supply target contract
    address public immutable supply;

    /// @notice Initializes supply target contract
    constructor(address _supply) {
        supply = _supply;
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions()
        public
        view
        virtual
        override(IMinter, Module)
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](1);
        permissions[0] = Permission(address(this), supply, ISupply.mint.selector);
    }

    /// @notice Mints a Rae supply
    /// @param _vault Address of the Vault
    /// @param _to Address of the receiver of Raes
    /// @param _raeSupply Number of NFT Raes minted to control the vault
    /// @param _mintProof List of proofs to execute a mint function
    function _mintRaes(
        address _vault,
        address _to,
        uint256 _raeSupply,
        bytes32[] memory _mintProof
    ) internal {
        bytes memory data = abi.encodeCall(ISupply.mint, (_to, _raeSupply));
        IVault(payable(_vault)).execute(supply, data, _mintProof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "../interfaces/IModule.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";

/// @title Module
/// @author Tessera
/// @notice Base module contract for converting vault permissions into leaf nodes
contract Module is IModule {
    /// @notice Gets the list of hashed leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return leaves Hashed leaf nodes
    function getLeaves() external view returns (bytes32[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes32[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = keccak256(abi.encode(permissions[i]));
            }
        }
    }

    /// @notice Gets the list of unhashed leaf nodes used to generate a merkle tree
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @return leaves Unhashed leaf nodes
    function getUnhashedLeaves() external view returns (bytes[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = abi.encode(permissions[i]);
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Intentionally left empty to be overridden by the module inheriting from this contract
    /// @return permissions List of vault permissions
    function getPermissions() public view virtual returns (Permission[] memory permissions) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "../interfaces/IModule.sol";
import {IProtoform} from "../interfaces/IProtoform.sol";
import "../utils/MerkleBase.sol";

/// @title Protoform
/// @author Tessera
/// @notice Base protoform contract for generating merkle trees
contract Protoform is IProtoform, MerkleBase {
    /// @notice Generates a merkle tree from the hashed permissions of the given modules
    /// @param _modules List of module contracts
    /// @return tree Merkle tree of hashed leaf nodes
    function generateMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes32[] memory tree)
    {
        uint256 counter;
        uint256 modulesLength = _modules.length;
        uint256 treeSize = _getTreeSize(_modules, modulesLength);
        tree = new bytes32[](treeSize);
        unchecked {
            /* _sortList(_modules, modulesLength); */
            for (uint256 i; i < modulesLength; ++i) {
                bytes32[] memory leaves = IModule(_modules[i]).getLeaves();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    tree[counter++] = leaves[j];
                }
            }
        }
    }

    /// @notice Generates a merkle tree from the unhashed permissions of the given modules
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @param _modules List of module contracts
    /// @return tree Merkle tree of unhashed leaf nodes
    function generateUnhashedMerkleTree(address[] memory _modules)
        public
        view
        returns (bytes[] memory tree)
    {
        uint256 counter;
        uint256 modulesLength = _modules.length;
        uint256 treeSize = _getTreeSize(_modules, modulesLength);
        tree = new bytes[](treeSize);
        unchecked {
            /* _sortList(_modules, modulesLength); */
            for (uint256 i; i < modulesLength; ++i) {
                bytes[] memory leaves = IModule(_modules[i]).getUnhashedLeaves();
                uint256 leavesLength = leaves.length;
                for (uint256 j; j < leavesLength; ++j) {
                    tree[counter++] = leaves[j];
                }
            }
        }
    }

    /// @dev Gets the size of a merkle tree based on the total permissions across all modules
    /// @param _modules List of module contracts
    /// @param _length Size of modules array
    /// @return size Total size of the merkle tree
    function _getTreeSize(address[] memory _modules, uint256 _length)
        internal
        view
        returns (uint256 size)
    {
        unchecked {
            for (uint256 i; i < _length; ++i) {
                size += IModule(_modules[i]).getLeaves().length;
            }
        }
    }

    /// @dev Sorts the list of modules in ascending order
    function _sortList(address[] memory _modules, uint256 _length) internal pure {
        for (uint256 i; i < _length; ++i) {
            for (uint256 j = i + 1; j < _length; ++j) {
                if (_modules[i] > _modules[j]) {
                    (_modules[i], _modules[j]) = (_modules[j], _modules[i]);
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Protoform} from "src/protoforms/Protoform.sol";
import {Multicall} from "src/utils/Multicall.sol";
import {Minter} from "src/modules/Minter.sol";
import {NFTReceiver} from "src/utils/NFTReceiver.sol";
import {ConsiderationItem, ItemType, OfferItem, Order, OrderParameters, OrderComponents, OrderType} from "seaport/lib/ConsiderationStructs.sol";
import {IERC1155} from "src/interfaces/IERC1155.sol";
import {IRae} from "src/interfaces/IRae.sol";
import {IERC721} from "src/interfaces/IERC721.sol";
import {ISeaportSeller, OrderInfo} from "src/seaport/interfaces/ISeaportSeller.sol";
import {ISeaportLister} from "src/seaport/interfaces/ISeaportLister.sol";
import {ITransfer} from "src/interfaces/ITransfer.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IVaultRegistry, Permission} from "src/interfaces/IVaultRegistry.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

/// @title SeaportSeller
/// @author Tessera
/// @notice Protoform contract for vaults to list items on Seaport
contract SeaportSeller is ISeaportSeller, Multicall, Protoform, Minter, NFTReceiver {
    using SafeCastLib for uint256;
    /// @notice constant duration of order required
    uint256 public constant EXPIRY = 365 days;
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of the Seaport  contract
    address public seaport;
    /// @notice Conduit key - we need to use a conduit key because the target contract uses a conduit
    bytes32 public immutable conduitKey;
    /// @notice Address of the fee receiver
    address payable public feeReceiver;
    /// @notice basis point fee collected by of the fee receiver
    uint256 public fee;
    /// @notice Address of Supply target contract
    address public immutable transfer;
    /// @notice Address of the seaport lister target contract
    address public immutable seaportLister;
    /// @notice Mapping of vault to OrderInfo associated with the vault
    mapping(address => OrderInfo) public vaultOrderInfo;

    /// @dev Initializes registry, seaport, zone, conduitKey, supply, seaportLister, etc.
    constructor(
        address _registry,
        address _seaport,
        bytes32 _conduitKey,
        address _supply,
        address _transfer,
        address _seaportLister,
        address payable _feeReceiver
    ) Minter(_supply) {
        registry = _registry;
        seaport = _seaport;
        conduitKey = _conduitKey;
        transfer = _transfer;
        seaportLister = _seaportLister;
        feeReceiver = _feeReceiver;
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    modifier authorized() {
        if (msg.sender != feeReceiver) revert NotAuthorized();
        _;
    }

    function updateSeaport(address _seaport) external authorized {
        seaport = _seaport;
    }

    /// @notice Sets the feeReceiver address
    /// @param _new The new fee receiver address
    function updateFeeReceiver(address payable _new) external authorized {
        feeReceiver = _new;
    }

    /// @notice Sets the fee received by the fee receiver
    /// @param _new The new fee
    function updateFee(uint256 _new) external authorized {
        if (_new >= 10000) revert InvalidFee();
        fee = _new;
    }

    /// @notice Deploys a vault with module permissions, mints Raes to Seller contract,
    /// lists Raes for sale at set price on Seaport for the initial distribution
    /// @param _nft Address of the nft contract being deposited into the vault
    /// @param _tokenIds The tokenIds of the NFT being deposited into the vault
    /// @param _raeSupply The number of Raes to create and list on Seaport
    /// @param _modules The modules to enable on the Vault
    /// @param _mintProof Merkle proof for initially minting Raes
    function deployVault(
        address _nft,
        uint256[] calldata _tokenIds,
        uint256 _raeSupply,
        address[] calldata _modules,
        bytes32[] calldata _mintProof
    ) external returns (address vault) {
        vault = _createVault(_modules);
        vaultOrderInfo[vault] = OrderInfo(
            msg.sender,
            uint96(block.timestamp + EXPIRY),
            type(uint128).max,
            uint128(fee)
        );
        unchecked {
            for (uint256 i; i < _tokenIds.length; ++i)
                IERC721(_nft).transferFrom(msg.sender, vault, _tokenIds[i]);
        }
        _mintRaes(vault, vault, _raeSupply, _mintProof);
    }

    /// @notice Updates an active listing for Raes on Seaport with a lower than current price
    /// @param _vault Address of the vault
    /// @param _newPrice The new lower price for Raes
    /// @param _listProof Merkle proof for listing an order on seaport
    function updateRaePrice(
        address _vault,
        uint256 _newPrice,
        bytes32[] calldata _delistProof,
        bytes32[] calldata _listProof
    ) external {
        // Reverts if vault is not registered
        (address token, uint256 id) = _verifyVault(_vault);

        OrderInfo storage info = vaultOrderInfo[_vault];
        if (msg.sender != info.payee) revert NotPayee();
        Order[] memory orders = currentOrder(_vault);

        /// validator price change
        uint256 oldPrice = orders[0].parameters.consideration[0].endAmount;
        if (oldPrice <= _newPrice) revert NotLower();
        orders[0].parameters.consideration[0].startAmount = _newPrice;
        orders[0].parameters.consideration[0].endAmount = _newPrice;
        if (info.fee > 0) {
            orders[0].parameters.consideration[1].startAmount = _calculateFee(_newPrice, info.fee);
            orders[0].parameters.consideration[1].endAmount = _calculateFee(_newPrice, info.fee);
        }

        if (oldPrice < type(uint128).max) _delist(_vault, _delistProof);
        /// update price and on seaport
        info.price = _newPrice.safeCastTo128();
        bytes memory data = abi.encodeCall(ISeaportLister.validateListing, (seaport, orders));
        IVault(payable(_vault)).execute(seaportLister, data, _listProof);

        emit SeaportListing(_vault, msg.sender, oldPrice, _newPrice);
    }

    /// @notice Cancels an active listing on seaport
    /// @param _vault Address of the vault
    /// @param _delistProof Merkle proof for cancelling the current order on Seaport
    /// @param _redeemProof Merkle proof for withdrawing the remaining Raes
    function cancel(
        address _vault,
        bytes32[] calldata _delistProof,
        bytes32[] calldata _redeemProof
    ) external {
        // Reverts if vault is not registered
        (address token, uint256 id) = _verifyVault(_vault);

        OrderInfo storage info = vaultOrderInfo[_vault];
        // Reverts if caller is not proposer of active listing
        if (msg.sender != info.payee) revert NotPayee();

        if (block.timestamp < info.expiration)
            revert TimeNotElapsed(block.timestamp, info.expiration);

        // Cancels the Seaport Order
        _delist(_vault, _delistProof);

        uint256 amount = IERC1155(token).balanceOf(_vault, id);
        bytes memory data = abi.encodeCall(
            ITransfer.ERC1155TransferFrom,
            (token, _vault, msg.sender, id, amount)
        );
        IVault(payable(_vault)).execute(transfer, data, _redeemProof);

        emit RedeemRaes(_vault, token, id, amount);
    }

    /// @notice Build a valid seaport order for the Raes with the current price in storage associated with a vault
    /// @param _vault Address of the vault
    function currentOrder(address _vault) public view returns (Order[] memory) {
        return _constructOrder(_vault, vaultOrderInfo[_vault].price);
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions() public view override returns (Permission[] memory permissions) {
        permissions = new Permission[](4);
        permissions[0] = super.getPermissions()[0];
        permissions[1] = Permission(
            address(this),
            transfer,
            ITransfer.ERC1155TransferFrom.selector
        );
        permissions[2] = Permission(
            address(this),
            seaportLister,
            ISeaportLister.validateListing.selector
        );
        permissions[3] = Permission(
            address(this),
            seaportLister,
            ISeaportLister.cancelListing.selector
        );
    }

    function _calculateFee(uint256 _salePrice, uint256 _fee) internal view returns (uint256) {
        return (_salePrice * _fee) / 10000;
    }

    function _createVault(address[] memory _modules) internal returns (address vault) {
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        bytes32 merkleRoot = getRoot(leafNodes);
        vault = IVaultRegistry(registry).create(merkleRoot);
    }

    /// @dev Executes the delisting of a listing on Seaport
    function _delist(address _vault, bytes32[] calldata _delistProof) internal {
        OrderParameters memory orderParams = currentOrder(_vault)[0].parameters;
        orderParams.totalOriginalConsiderationItems = 0;
        OrderComponents memory orderComps;
        assembly {
            orderComps := orderParams
        }
        OrderComponents[] memory components = new OrderComponents[](1);
        components[0] = orderComps;
        // Cancel the Seaport listing
        bytes memory data = abi.encodeCall(ISeaportLister.cancelListing, (seaport, components));
        IVault(payable(_vault)).execute(seaportLister, data, _delistProof);
    }

    function _createOffer(address _vault) internal view returns (OfferItem[] memory offers) {
        (address rae, uint256 id) = IVaultRegistry(registry).vaultToToken(_vault);
        uint256 supply = IRae(rae).totalSupply(id);
        offers = new OfferItem[](1);
        offers[0] = OfferItem(ItemType.ERC1155, rae, id, supply, supply);
    }

    function _createConsiderations(address _vault, uint256 _price)
        internal
        view
        returns (ConsiderationItem[] memory considerations)
    {
        OrderInfo storage info = vaultOrderInfo[_vault];
        considerations = (info.fee == 0) ? new ConsiderationItem[](1) : new ConsiderationItem[](2);
        considerations[0] = ConsiderationItem(
            ItemType.NATIVE,
            address(0),
            0,
            _price,
            _price,
            payable(info.payee)
        );

        if (info.fee > 0) {
            considerations[1] = ConsiderationItem(
                ItemType.NATIVE,
                address(0),
                0,
                _calculateFee(_price, fee),
                _calculateFee(_price, fee),
                feeReceiver
            );
        }
    }

    function _constructOrder(address _vault, uint256 _price)
        internal
        view
        returns (Order[] memory orders)
    {
        OrderInfo storage info = vaultOrderInfo[_vault];
        orders = new Order[](1);
        orders[0].parameters = OrderParameters(
            _vault,
            address(0),
            _createOffer(_vault),
            _createConsiderations(_vault, _price),
            OrderType.PARTIAL_OPEN,
            0,
            type(uint256).max,
            bytes32(0),
            0,
            conduitKey,
            (info.fee == 0) ? 1 : 2
        );
    }

    /// @dev Reverts if vault is not registered
    function _verifyVault(address _vault) internal view returns (address token, uint256 id) {
        (token, id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Order, OrderComponents} from "seaport/lib/ConsiderationStructs.sol";

/// @dev Interface for Seaport Lister target contract
interface ISeaportLister {
    function validateListing(address _consideration, Order[] memory _orders) external;

    function cancelListing(address _consideration, OrderComponents[] memory _orders) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Order} from "seaport/lib/ConsiderationStructs.sol";

struct OrderInfo {
    address payee;
    uint96 expiration;
    uint128 price;
    uint128 fee;
}

/// @dev Interface for ISeaportSeller
interface ISeaportSeller {
    error NotAuthorized();
    error NotPayee();
    error NotLower();
    error InvalidFee();
    error NotVault(address _vault);
    error TimeNotElapsed(uint256 _currentTimestamp, uint256 _requiredTimestamp);

    event SeaportListing(
        address indexed vault,
        address indexed offerer,
        uint256 old,
        uint256 latest
    );
    event RedeemRaes(address indexed vault, address indexed raes, uint256 id, uint256 amount);
    event DeployVault(
        address indexed vault,
        address indexed nft,
        address indexed rae,
        uint256[] ids,
        uint256 raeId,
        uint256 raeSupply
    );

    function updateSeaport(address _seaport) external;

    function updateFeeReceiver(address payable _new) external;

    function deployVault(
        address _nft,
        uint256[] calldata _tokenId,
        uint256 _raeSupply,
        address[] calldata _modules,
        bytes32[] calldata _mintProof
    ) external returns (address vault);

    function updateRaePrice(
        address _vault,
        uint256 _newPrice,
        bytes32[] calldata _delistProof,
        bytes32[] calldata _listProof
    ) external;

    function cancel(
        address _vault,
        bytes32[] calldata _delistProof,
        bytes32[] calldata _redeemProof
    ) external;

    function currentOrder(address _vault) external view returns (Order[] memory);

    function EXPIRY() external view returns (uint256);

    function conduitKey() external view returns (bytes32);

    function feeReceiver() external view returns (address payable);

    function registry() external view returns (address);

    function seaport() external view returns (address);

    function seaportLister() external view returns (address);

    function transfer() external view returns (address);

    function vaultOrderInfo(address)
        external
        view
        returns (
            address payee,
            uint96 expiration,
            uint128 price,
            uint128 fee
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Merkle Base
/// @author Modified from Murky (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    constructor() {}

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right) public pure returns (bytes32 data) {
        // Return opposite node if checked node is of bytes zero value
        if (_left == bytes32(0)) return _right;
        if (_right == bytes32(0)) return _left;

        assembly {
            // TODO: This can be aesthetically simplified with a switch. Not sure it will
            // save much gas but there are other optimizations to be had in here.
            if or(lt(_left, _right), eq(_left, _right)) {
                mstore(0x0, _left)
                mstore(0x20, _right)
            }
            if gt(_left, _right) {
                mstore(0x0, _right)
                mstore(0x20, _left)
            }
            data := keccak256(0x0, 0x40)
        }
    }

    /// @notice Verifies the merkle proof of a given value
    /// @param _root Hash of merkle root
    /// @param _proof Merkle proof
    /// @param _valueToProve Leaf node being proven
    /// @return Status of proof verification
    function verifyProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _valueToProve
    ) public pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = _valueToProve;
        unchecked {
            for (uint256 i = 0; i < _proof.length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, _proof[i]);
            }
        }
        return _root == rollingHash;
    }

    /// @notice Generates the merkle root of a tree
    /// @param _data Leaf nodes of the merkle tree
    /// @return Hash of merkle root
    function getRoot(bytes32[] memory _data) public pure returns (bytes32) {
        require(_data.length > 1, "wont generate root for single leaf");
        while (_data.length > 1) {
            _data = hashLevel(_data);
        }
        return _data[0];
    }

    /// @notice Generates the merkle proof for a leaf node in a given tree
    /// @param _data Leaf nodes of the merkle tree
    /// @param _node Index of the node in the tree
    /// @return proof Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory proof)
    {
        require(_data.length > 1, "wont generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        uint256 size = log2ceil_naive(_data.length);
        bytes32[] memory result = new bytes32[](size);
        uint256 pos;
        uint256 counter;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (_data.length > 1) {
            unchecked {
                if (_node % 2 == 1) {
                    result[pos] = _data[_node - 1];
                } else if (_node + 1 == _data.length) {
                    result[pos] = bytes32(0);
                    ++counter;
                } else {
                    result[pos] = _data[_node + 1];
                }
                ++pos;
                _node = _node / 2;
            }
            _data = hashLevel(_data);
        }

        // Dynamic array to filter out address(0) since proof size is rounded up
        // This is done to return the actual proof size of the indexed node
        uint256 offset;
        proof = new bytes32[](size - counter);
        unchecked {
            for (uint256 i; i < size; ++i) {
                if (result[i] != bytes32(0)) {
                    proof[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }
    }

    /// @dev Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data) private pure returns (bytes32[] memory result) {
        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always.
        unchecked {
            uint256 length = _data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[]((length >> 1) + 1);
                result[result.length - 1] = hashLeafPairs(_data[length - 1], bytes32(0));
            } else {
                result = new bytes32[](length >> 1);
            }

            // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos;
            for (uint256 i; i < length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so.
        assembly {
            // we check by seeing if x == (~x + 1) & x. This applies a mask
            // to find the lowest set bit of x and then checks it for equality
            // with x. If they are equal, then x is a power of 2.

            /* Example
                x has single bit set
                x := 0000_1000
                (~x + 1) = (1111_0111) + 1 = 1111_1000
                (1111_1000 & 0000_1000) = 0000_1000 == x
                x has multiple bits set
                x := 1001_0010
                (~x + 1) = (0110_1101 + 1) = 0110_1110
                (0110_1110 & x) = 0000_0010 != x
            */

            // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            ceil -= pOf2;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Multicall
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
/// @notice Utility contract that enables calling multiple local methods in a single call
abstract contract Multicall {
    /// @notice Allows multiple function calls within a contract that inherits from it
    /// @param _data List of encoded function calls to make in this contract
    /// @return results List of return responses for each encoded call passed
    function multicall(bytes[] calldata _data) external returns (bytes[] memory results) {
        uint256 length = _data.length;
        results = new bytes[](length);

        bool success;
        for (uint256 i; i < length; ) {
            bytes memory result;
            (success, result) = address(this).delegatecall(_data[i]);
            if (!success) {
                if (result.length == 0) revert();
                // If there is return data and the call wasn't successful, the call reverted with a reason or a custom error.
                _revertedWithReason(result);
            }

            results[i] = result;

            // cannot realistically overflow on human timescales
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Handles function for revert responses
    /// @param _response Reverted return response from a delegate call
    function _revertedWithReason(bytes memory _response) internal pure {
        assembly {
            let returndata_size := mload(_response)
            revert(add(32, _response), returndata_size)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {ERC1155TokenReceiver} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

/// @title NFT Receiver
/// @author Tessera
/// @notice Plugin contract for handling receipts of non-fungible tokens
contract NFTReceiver is ERC721TokenReceiver, ERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC721 token
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /// @notice Handles the receipt of a single ERC1155 token type
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles the receipt of multiple ERC1155 token types
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}