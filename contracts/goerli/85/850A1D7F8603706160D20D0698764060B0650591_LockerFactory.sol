// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Locker.sol";
import "./interfaces/ILockerIndexer.sol";
import "./interfaces/ILockerFactory.sol";

contract LockerFactory is ILockerFactory {
    address public immutable comboCollFactory;
    address public immutable lockerIndexer;
    address public immutable agent;
    address public immutable tokenIdentifier;

    constructor(
        address comboCollFactory_,
        address lockerIndexer_,
        address agent_,
        address tokenIdentifier_
    ) {
        if (
            comboCollFactory_ == address(0) ||
            lockerIndexer_ == address(0) ||
            agent_ == address(0) ||
            tokenIdentifier_ == address(0)
        ) {
            revert ZeroAddress();
        }
        comboCollFactory = comboCollFactory_;
        lockerIndexer = lockerIndexer_;
        agent = agent_;
        tokenIdentifier = tokenIdentifier_;
    }

    function deploy(address combo_) external override returns (address) {
        if (msg.sender != comboCollFactory) {
            revert CallerNotAllowed();
        }

        Locker locker = new Locker(
            combo_,
            lockerIndexer,
            agent,
            tokenIdentifier
        );
        ILockerIndexer(lockerIndexer).addLocker(address(locker));
        IAgent(agent).addEntrance(address(locker));
        locker.transferOwnership(comboCollFactory);
        return address(locker);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ICollectionType.sol";

interface IComboReceipt is ICollectionType {

    struct ComboReceipt {
        uint256 comboId;
        bytes32 comboHash;

        uint256 usedTotalCount;
        address[] usedColls;
        uint256[] usedCollCounts;
        uint256[] addOnFees;

        address[] lockColls;    // ERC721 and ERC1155
        CollectionType[] lockCollTypes;
        uint256[][] lockTokenIds;
        uint256[][] lockTokenAmounts;
        uint256[][] lockUUIDs;

        address[] unlockColls; // only ERC721 (including Combo)
        uint256[][] unlockTokenIds;
        uint256[][] unlockUUIDs;

        uint64[] sets;
        address[][] collsForSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ICollectionType.sol";


interface IComboCoreStructs is ICollectionType {

    struct Factor {
        uint128 max;
        uint128 min;
        // collection = address(0) indicates this is a factor for set and
        // Factor.setId must not be 0.
        address collection;
        // setId = 0 indicates this is a factor for non-set colection and 
        // Factor.collection must not be address(0).
        uint64 setId;
        bool lock;
    }

    struct Limit {
        address collection; // Only ERC721
        uint128 maxTokenUsage; // Max usage times for each token
    }

    struct ComboRules {
        Factor[] factors;
        Limit[] limits;
    }

    struct ConstructorParams {
        string name;
        string symbol;
        string contractURIPath;
        ComboRules comboRules;
    }

    // ============================ ComboMeta ============================
    struct Item {
        uint256 uuid;
        uint128 amount;
        uint64 setId;
        uint8 typ;
        bool lock;
        bool limit;
    }

    struct ComboMeta {
        // the one who created or edited this combo
        address creator;
        Item[] items;
    }

    // ============================ ComboParams ============================
    struct ComboParams {
        Ingredients ingredients;

        // For ingredients.collections
        CollectionType[] collectionTypes;

        // For ERC1155 collection, dup does not matter.
        uint256[][] userBalancesFor1155Items;

        uint256[][] uuidForItems;
        string hash;
    }

    struct Ingredients {
        address[] collections;    // sorted in ascending order. no dup.
        uint256[][] itemsForCollections; // sorted in ascending order. dup is only allowed for ERC-1155.
        uint128[][] amountsForItems;
        uint64[][] setsForItems;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ICollectionType {
    enum CollectionType {
        UNDEFINED, // unused
        ERC721,
        ERC1155,
        COMBO
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ITokenIdentifier {
    error ZeroAddress();    // 0xd92e233d
    error TokenNotExists(); // 0x01bdc21c

    struct Token {
        address tokenAddress;
        uint256 tokenId;
    }

    function getOrGenerateUUID(
        address[] calldata collections,
        uint256[][] calldata tokenIds
    ) external returns (uint256[][] memory);

    function getUUID(
        address[] calldata collections,
        uint256[][] calldata tokenIds,
        bool mustExist
    ) external view returns (uint256[][] memory);

    /**
     * @dev no error thrown if not found
     */
    function tokensOf(uint256[][] calldata uuids)
        external
        view
        returns (Token[][] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboReceipt.sol";
import "./ITokenIdentifier.sol";
import "./base/IComboCoreStructs.sol";

interface ILockerIndexer {
    error ZeroAddress();        // 0xd92e233d
    error DuplicateLockers();   // 0x8bd0ef32
    error CallerNotAllowed();   // 0x2af07d20
    error ParentExists();       // 0xbca6ce22
    error LockerNotExists();    // 0xde129513
    error ParentDiffers(        // 0x37452d1e
        uint256 uuid,
        uint256 expect,
        uint256 actual
    );

    struct LockerInfo {
        bool registered;
        bool enabled;
    }
    
    function addLocker(address locker) external;

    function setEnabled(address locker, bool enabled) external;

    function getInfos(address[] calldata lockers)
        external
        view
        returns (LockerInfo[] memory);

    function addIndex(
        address combo,
        IComboReceipt.ComboReceipt calldata receipt
    ) external;

    function removeIndex(
        address combo,
        uint256 comboId,
        IComboCoreStructs.ComboMeta calldata meta
    ) external;

    function rootCombosOf(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds
    ) external returns (ITokenIdentifier.Token[][] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ILockerFactory {
    error ZeroAddress();        // 0xd92e233d
    error CallerNotAllowed();   // 0x2af07d20

    function deploy(address combo) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboReceipt.sol";

interface ILocker {
    error TransferForbidden(); // 0x44983244

    event Unlock1155Failed(uint256 comboId, address token, uint256 tokenId);
    event Unlock721SafeFailed(uint256 comboId, address token, uint256 tokenId);
    event Unlock721Failed(uint256 comboId, address token, uint256 tokenId);

    function lock(address from, IComboReceipt.ComboReceipt calldata receipt)
        external;

    function unlock(address to, uint256 comboId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboCoreStructs.sol";
import "./base/IComboReceipt.sol";

interface IComboCollCore is IComboCoreStructs, IComboReceipt {
    event Mint(address indexed who, uint256 indexed comboId, string metaHash, bytes32 comboHash);
    event Remint(address indexed who, uint256 indexed comboId, string metaHash, bytes32 comboHash);

    error CallerNotAllowed();       // 0x2af07d20
    error UnknownCollection(address collection);                        // 0xd053b7de
    error UnknownSet(uint256 setId);                                    // 0xe21ee9e0
    error ExceedTokenUsageLimit(address collection, uint256 tokenId);   // 0x4a9e44c8
    error NotComboOwner();                                              // 0x37021de8
    error ComboNotExists();                                             // 0x178832c0

    function mint(
        address caller,
        address to,
        ComboParams calldata params
    ) external returns (ComboReceipt memory);

    function remint(
        address caller,
        uint256 comboId,
        ComboParams calldata params
    ) external returns (ComboReceipt memory);

    function dismantle(address caller, uint256 comboId) external;

    function getComboRules() external view returns (ComboRules memory);

    /**
     * @dev Returns 0 if token is not limited
     */
    function getLimitedTokenUsages(uint256[] calldata uuids)
        external
        view
        returns (uint256[] memory);

    function comboMetasOf(uint256[] calldata comboIds)
        external
        view
        returns (ComboMeta[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IAgent {
    enum AgentItemType {
        UNDEFINED, // unused
        ERC20,
        ERC721,
        ERC1155
    }

    error ZeroAddress(); // 0xd92e233d
    error EntranceClosed(); // 0x3118dcd6
    error InvalidAgentItemType(); // 0xcc05c803
    error OnlyOneAmountAllowed(); // 0x032cb2ed
    error CallerNotAllowed(); // 0x2af07d20
    error Reenter(); // 0xa1592b02

    struct AgentTransfer {
        AgentItemType itemType;
        address token;
        address from;
        address to;
        uint256 id;
        uint256 amount;
    }

    struct AgentTransferBatch {
        AgentItemType itemType;
        address token;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
    }

    struct AgentERC1155BatchTransfer {
        address token;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
    }

    function addEntrance(address entrance) external;

    function isApproved(address user, address operator)
        external
        view
        returns (bool);

    function executeTransfer(address user, AgentTransfer[] calldata transfers)
        external
        returns (bytes4);

    function executeTransferBatch(
        address user,
        AgentTransferBatch[] calldata transfers
    ) external returns (bytes4);

    function executeERC1155BatchTransfer(
        address user,
        AgentERC1155BatchTransfer[] calldata transfers
    ) external returns (bytes4);

    function executeWithERC1155BatchTransfer(
        address user,
        AgentTransfer[] calldata transfers,
        AgentTransferBatch[] calldata transferBatches,
        AgentERC1155BatchTransfer[] calldata erc1155BatchTransfers
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/ILocker.sol";
import "./interfaces/ILockerIndexer.sol";
import "./interfaces/IAgent.sol";
import "./interfaces/ITokenIdentifier.sol";
import "./interfaces/IComboCollCore.sol";

// @title Locker helps ComboCollection manage all locked NFTs.
// @dev only ComboCollection can access its own Locker.
contract Locker is Ownable, ILocker, IERC1155Receiver, IERC721Receiver {
    address private immutable _lockerIndexer;
    address private immutable _combo;
    address private immutable _agent;
    address private immutable _tokenIdentifier;

    constructor(
        address combo_,
        address lockerIndexer_,
        address agent_,
        address tokenIdentifier_
    ) {
        _combo = combo_;
        _lockerIndexer = lockerIndexer_;
        _agent = agent_;
        _tokenIdentifier = tokenIdentifier_;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (operator == _agent) {
            return IERC1155Receiver.onERC1155Received.selector;
        } else {
            revert TransferForbidden();
        }
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view override returns (bytes4) {
        if (operator == _agent) {
            return IERC1155Receiver.onERC1155BatchReceived.selector;
        } else {
            revert TransferForbidden();
        }
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (operator == _agent) {
            return IERC721Receiver.onERC721Received.selector;
        } else {
            revert TransferForbidden();
        }
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return (interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId);
    }

    function lock(address from_, IComboReceipt.ComboReceipt calldata receipt_)
        external
        override
        onlyOwner
    {
        ILockerIndexer(_lockerIndexer).addIndex(_combo, receipt_);

        uint256 size = receipt_.lockColls.length;
        IAgent.AgentTransferBatch[]
            memory transfers = new IAgent.AgentTransferBatch[](size);
        for (uint256 i = 0; i < size; ) {
            transfers[i] = IAgent.AgentTransferBatch({
                itemType: receipt_.lockCollTypes[i] ==
                    ICollectionType.CollectionType.ERC1155
                    ? IAgent.AgentItemType.ERC1155
                    : IAgent.AgentItemType.ERC721,
                token: receipt_.lockColls[i],
                from: from_,
                to: address(this),
                ids: receipt_.lockTokenIds[i],
                amounts: receipt_.lockTokenAmounts[i]
            });
            unchecked {
                ++i;
            }
        }
        IAgent(_agent).executeTransferBatch(from_, transfers);
    }

    /**
     * @dev only combo owner can withraw NFTs
     */
    function unlock(address to_, uint256 comboId_) external override onlyOwner {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = comboId_;
        IComboCoreStructs.ComboMeta memory meta = IComboCollCore(_combo)
            .comboMetasOf(tokenIds)[0];

        uint256 size = meta.items.length;

        uint256[][] memory uuids = new uint256[][](1);
        uuids[0] = new uint256[](size);

        bool hasLock;
        for (uint256 i = 0; i < size; ) {
            if (meta.items[i].lock) {
                uuids[0][i] = meta.items[i].uuid;
                if (!hasLock) {
                    hasLock = true;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (!hasLock) {
            return;
        }

        ITokenIdentifier.Token[] memory tokens = ITokenIdentifier(
            _tokenIdentifier
        ).tokensOf(uuids)[0];

        for (uint256 i = 0; i < size; ) {
            if (meta.items[i].lock) {
                if (
                    meta.items[i].typ ==
                    uint8(ICollectionType.CollectionType.ERC1155)
                ) {
                    // ignore error, in case malicious collection
                    try
                        IERC1155(tokens[i].tokenAddress).safeTransferFrom(
                            address(this),
                            to_,
                            tokens[i].tokenId,
                            meta.items[i].amount,
                            ""
                        )
                    {
                        // do nothing
                    } catch {
                        emit Unlock1155Failed(
                            comboId_,
                            tokens[i].tokenAddress,
                            tokens[i].tokenId
                        );
                    }
                } else {
                    // ignore error, in case malicious collection
                    try
                        IERC721(tokens[i].tokenAddress).safeTransferFrom(
                            address(this),
                            to_,
                            tokens[i].tokenId
                        )
                    {
                        // do nothing
                    } catch {
                        emit Unlock721SafeFailed(
                            comboId_,
                            tokens[i].tokenAddress,
                            tokens[i].tokenId
                        );
                        try
                            IERC721(tokens[i].tokenAddress).transferFrom(
                                address(this),
                                to_,
                                tokens[i].tokenId
                            )
                        {
                            // do nothing
                        } catch {
                            emit Unlock721Failed(
                                comboId_,
                                tokens[i].tokenAddress,
                                tokens[i].tokenId
                            );
                        }
                    }
                }
            }
            unchecked {
                ++i;
            }
        }

        ILockerIndexer(_lockerIndexer).removeIndex(_combo, comboId_, meta);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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