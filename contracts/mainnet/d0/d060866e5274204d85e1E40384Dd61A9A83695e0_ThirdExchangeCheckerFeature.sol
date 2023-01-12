/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ITransferSelectorNFT.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IX2y2.sol";
import "./IThirdExchangeCheckerFeature.sol";


contract ThirdExchangeCheckerFeature is IThirdExchangeCheckerFeature {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable LOOKS_RARE;
    address public immutable X2Y2;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(address looksRare, address x2y2) {
        LOOKS_RARE = looksRare;
        X2Y2 = x2y2;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoV2(
        address account,
        uint8 itemType,
        address nft,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    )
        external
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(SEAPORT).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        public
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        uint8 itemType = 255;
        if (supportsERC721(nft)) {
            itemType = 0;
        } else if (supportsERC1155(nft)) {
            itemType = 1;
        }
        return getSeaportCheckInfoEx(account, itemType, nft, tokenId, conduitKey, orderHash);
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getLooksRareCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, uint256 accountNonce)
        public
        override
        view
        returns (LooksRareCheckInfo memory info)
    {
        try ILooksRare(LOOKS_RARE).transferSelectorNFT() returns (ITransferSelectorNFT transferSelector) {
            try transferSelector.checkTransferManagerForToken(nft) returns (address transferManager) {
                info.transferManager = transferManager;
            } catch {}
        } catch {}

        try ILooksRare(LOOKS_RARE).isUserOrderNonceExecutedOrCancelled(account, accountNonce) returns (bool isExecutedOrCancelled) {
            info.isExecutedOrCancelled = isExecutedOrCancelled;
        } catch {}

        try ILooksRare(LOOKS_RARE).userMinOrderNonce(account) returns (uint256 minNonce) {
            if (accountNonce < minNonce) {
                info.isExecutedOrCancelled = true;
            }
        } catch {}

        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        }
        return info;
    }

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        override
        view
        returns (LooksRareCheckInfo memory info)
    {
        uint8 itemType = 255;
        if (supportsERC721(nft)) {
            itemType = 0;
        } else if (supportsERC721(nft)) {
            itemType = 1;
        }
        return getLooksRareCheckInfoEx(account, itemType, nft, tokenId, accountNonce);
    }

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        override
        view
        returns (X2y2CheckInfo memory info)
    {
        if (X2Y2 == address(0)) {
            return info;
        }

        try IX2y2(X2Y2).inventoryStatus(orderHash) returns (IX2y2.InvStatus status) {
            info.status = status;
        } catch {}

        info.erc721Owner = ownerOf(nft, tokenId);
        info.erc721ApprovedAccount = getApproved(nft, tokenId);
        info.isApprovedForAll = isApprovedForAll(nft, account, executionDelegate);
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        try ISeaport(SEAPORT).information() returns (string memory, bytes32, address conduitController) {
            try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                conduit = _conduit;
                exists = _exists;
            } catch {
            }
        } catch {
        }
        return (conduit, exists);
    }

    function supportsERC721(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC721) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function supportsERC1155(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC1155) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try IERC721(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try IERC721(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity >=0.8.7;

interface IConduitController {
    /**
     * @dev Track the conduit key, current owner, new potential owner, and open
     *      channels for each deployed conduit.
     */
    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    /**
     * @dev Emit an event whenever a new conduit is created.
     *
     * @param conduit    The newly created conduit.
     * @param conduitKey The conduit key used to create the new conduit.
     */
    event NewConduit(address conduit, bytes32 conduitKey);

    /**
     * @dev Emit an event whenever conduit ownership is transferred.
     *
     * @param conduit       The conduit for which ownership has been
     *                      transferred.
     * @param previousOwner The previous owner of the conduit.
     * @param newOwner      The new owner of the conduit.
     */
    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit an event whenever a conduit owner registers a new potential
     *      owner for that conduit.
     *
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to create a new conduit using a
     *      conduit key where the first twenty bytes of the key do not match the
     *      address of the caller.
     */
    error InvalidCreator();

    /**
     * @dev Revert with an error when attempting to create a new conduit when no
     *      initial owner address is supplied.
     */
    error InvalidInitialOwner();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentialOwner
    );

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet(address conduit);

    /**
     * @dev Revert with an error when attempting to interact with a conduit that
     *      does not yet exist.
     */
    error NoConduit();

    /**
     * @dev Revert with an error when attempting to create a conduit that
     *      already exists.
     */
    error ConduitAlreadyExists(address conduit);

    /**
     * @dev Revert with an error when attempting to update channels or transfer
     *      ownership of a conduit when the caller is not the owner of the
     *      conduit in question.
     */
    error CallerIsNotOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsZeroAddress(address conduit);

    /**
     * @dev Revert with an error when attempting to claim ownership of a conduit
     *      with a caller that is not the current potential owner for the
     *      conduit in question.
     */
    error CallerIsNotNewPotentialOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to retrieve a channel using an
     *      index that is out of range.
     */
    error ChannelOutOfRange(address conduit);

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        returns (address conduit);

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external;

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view returns (address owner);

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        returns (address conduit, bool exists);

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        returns (address potentialOwner);

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        returns (bool isOpen);

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        returns (uint256 totalChannels);

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        returns (address channel);

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        returns (address[] memory channels);

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface ISeaport {
    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer) external view returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface ITransferSelectorNFT {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ITransferSelectorNFT.sol";

interface ILooksRare {
    /**
    * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool);

    function transferSelectorNFT() external view returns (ITransferSelectorNFT);

    function userMinOrderNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface IX2y2 {

    enum InvStatus {
        NEW,
        AUCTION,
        COMPLETE,
        CANCELLED,
        REFUNDED
    }

    function inventoryStatus(bytes32) external view returns (InvStatus status);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ITransferSelectorNFT.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IX2y2.sol";


interface IThirdExchangeCheckerFeature {

    struct SeaportCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct LooksRareCheckInfo {
        address transferManager;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isExecutedOrCancelled;
    }

    struct X2y2CheckInfo {
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        IX2y2.InvStatus status;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoV2(
        address account,
        uint8 itemType,
        address nft,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (SeaportCheckInfo memory info);

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info);

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info);

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getLooksRareCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info);

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info);

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        view
        returns (X2y2CheckInfo memory info);
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