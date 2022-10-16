// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "./Interfaces/BAPOrchestratorInterfaceV3.sol";
import "./IERC1155Receiver.sol";
import "./IERC721A.sol";
import "./IERC721Enumerable.sol";
import "./IERC1155.sol";
import "./IERC165.sol";
import "./IERC20.sol";

contract BAPInfoReader {
    uint256 public constant startTime = 1665291600;
    // uint256 public constant timeCounter = 7200;
    uint256 public constant timeCounter = 1 days;

    BAPOrchestratorInterfaceV3 public V3Interface;
    IERC721A public bapGenesis;
    IERC721A public bapTeenBulls;
    IERC1155 public bapUtilities;
    IERC20 public bapMeth;

    mapping(uint256 => bool) public isGod;

    struct BullData {
        uint256 tokenId;
        uint256 claimableMeth;
        uint256 breedings;
        uint256 lastChestOpen;
        bool isGod;
        bool availableForRefund;
    }

    struct TeenData {
        uint256 tokenId;
        uint256 claimableMeth;
        address owner;
        bool isResurrected;
    }

    constructor(
        address _orchestratorV3,
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls
    ) {
        V3Interface = BAPOrchestratorInterfaceV3(_orchestratorV3);
        bapGenesis = IERC721A(_bapGenesis);
        bapMeth = IERC20(_bapMethane);
        bapUtilities = IERC1155(_bapUtilities);
        bapTeenBulls = IERC721A(_bapTeenBulls);
        isGod[2016] = true;
        isGod[3622] = true;
        isGod[3714] = true;
        isGod[4473] = true;
        isGod[4741] = true;
        isGod[5843] = true;
        isGod[6109] = true;
        isGod[7977] = true;
        isGod[8190] = true;
        isGod[9690] = true;
    }

    function getBullInfo(uint256 tokenId)
        public
        view
        returns (BullData memory bullInfo)
    {
        bool isGod = godBulls(tokenId);
        uint256 claimableMeth = getClaimableMeth(tokenId, isGod);
        uint256 breedings = V3Interface.breedings(tokenId);
        uint256 lastChestOpen = isGod ? V3Interface.lastChestOpen(tokenId) : 0;
        bool availableForRefund = !isGod
            ? V3Interface.availableForRefund(tokenId)
            : false;

        bullInfo = BullData({
            tokenId: tokenId,
            claimableMeth: claimableMeth,
            breedings: breedings,
            lastChestOpen: lastChestOpen,
            isGod: isGod,
            availableForRefund: availableForRefund
        });
    }

    function getTeenInfo(uint256 tokenId)
        public
        view
        returns (TeenData memory teenInfo)
    {
        uint256 claimed = V3Interface.claimedTeenMeth(tokenId);

        teenInfo = TeenData({
            tokenId: tokenId,
            claimableMeth: getTeenClaimableMeth(tokenId, claimed),
            owner: bapTeenBulls.ownerOf(tokenId),
            isResurrected: claimed > 0
        });
    }

    function getBullsInfoBatch(uint256[] memory tokensIds)
        external
        view
        returns (BullData[] memory data)
    {
        uint256 tokensCount = tokensIds.length;
        data = new BullData[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            data[i] = getBullInfo(tokensIds[i]);
        }
    }

    function getTeensInfoBatch(uint256[] memory tokensIds)
        external
        view
        returns (TeenData[] memory data)
    {
        uint256 tokensCount = tokensIds.length;
        data = new TeenData[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            data[i] = getTeenInfo(tokensIds[i]);
        }
    }

    function bullsBatchMeth(uint256[] memory tokensIds)
        external
        view
        returns (uint256[] memory amounts)
    {
        uint256 tokensCount = tokensIds.length;
        amounts = new uint256[](tokensCount);

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        for (uint256 i = 0; i < tokensCount; i++) {
            uint256 tokenId = tokensIds[i];
            bool isGod = godBulls(tokenId);

            uint256 claimed = V3Interface.claimedMeth(tokenId);
            uint256 dailyRewards = isGod ? 20 : 10;
            uint256 claimableMeth = (timeFromCreation * dailyRewards) - claimed;

            if (!isGod && V3Interface.breedings(tokenId) == 0) {
                claimableMeth += claimableMeth / 2;
            }

            bool prevClaimed = V3Interface.prevClaimed(tokenId);

            if (!prevClaimed) {
                claimableMeth += V3Interface.getOldClaimableMeth(
                    tokenId,
                    isGod
                );
            }
            amounts[i] = claimableMeth;
        }
    }

    function teensBatchMeth(uint256[] memory tokensIds)
        external
        view
        returns (uint256[] memory amounts)
    {
        uint256 tokensCount = tokensIds.length;
        amounts = new uint256[](tokensCount);

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        uint256 dailyRewards = 5;

        for (uint256 i = 0; i < tokensCount; i++) {
            uint256 tokenId = tokensIds[i];

            uint256 claimed = V3Interface.claimedTeenMeth(tokenId);

            bool isResurrected = V3Interface.isResurrected(tokenId);

            uint256 claimableMeth = isResurrected
                ? (timeFromCreation * dailyRewards) - claimed
                : 0;

            amounts[i] = claimableMeth;
        }
    }

    function walletBalances(address user)
        external
        view
        returns (
            uint256 bulls,
            uint256 teens,
            uint256 meth,
            uint256[] memory utilities
        )
    {
        bulls = bapGenesis.balanceOf(user);
        teens = bapTeenBulls.balanceOf(user);
        meth = bapMeth.balanceOf(user);
        address[] memory addresses = new address[](14);
        addresses[0] = user;
        addresses[1] = user;
        addresses[2] = user;
        addresses[3] = user;
        addresses[4] = user;
        addresses[5] = user;
        addresses[6] = user;
        addresses[7] = user;
        addresses[8] = user;
        addresses[9] = user;
        addresses[10] = user;
        addresses[11] = user;
        addresses[12] = user;
        addresses[13] = user;
        uint256[] memory ids = new uint256[](14);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 20;
        ids[3] = 21;
        ids[4] = 22;
        ids[5] = 23;
        ids[6] = 30;
        ids[7] = 31;
        ids[8] = 32;
        ids[9] = 33;
        ids[10] = 40;
        ids[11] = 41;
        ids[12] = 42;
        ids[13] = 43;
        utilities = bapUtilities.balanceOfBatch(addresses, ids);
    }

    function enumerableUserWallet(address user, address nftContract)
        external
        view
        returns (uint256[] memory ids)
    {
        IERC721Enumerable contractInstace = IERC721Enumerable(nftContract);
        uint256 tokenCount = contractInstace.balanceOf(user);

        ids = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            ids[i] = contractInstace.tokenOfOwnerByIndex(user, i);
        }
    }

    function batchOwnerData(uint256[] memory ids, address nftContract)
        external
        view
        returns (address[] memory owners)
    {
        IERC721A contractInstace = IERC721A(nftContract);
        uint256 tokenCount = ids.length;

        owners = new address[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            try contractInstace.ownerOf(ids[i]) returns (address owner) {
                owners[i] = owner;
            } catch {
                owners[i] = address(0);
            }
        }
    }

    function multisender(
        address nftContract,
        uint256[] memory ids,
        address recipient
    ) external {
        IERC721A contractInstace = IERC721A(nftContract);
        for (uint256 i = 0; i < ids.length; i++) {
            contractInstace.safeTransferFrom(msg.sender, recipient, ids[i]);
        }
    }

    function sendTokensToEveryone(
        address[] memory users,
        uint256[] memory amounts
    ) external {
        address sender = msg.sender;
        for (uint256 i = 0; i < users.length; i++) {
            bapMeth.transferFrom(sender, users[i], amounts[i]);
        }
    }

    function godBulls(uint256 tokenId) internal view returns (bool) {
        return tokenId > 10010 || isGod[tokenId];
    }

    function getClaimableMeth(uint256 tokenId, bool isGod)
        internal
        view
        returns (uint256 claimableMeth)
    {
        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);
        uint256 claimed = V3Interface.claimedMeth(tokenId);
        uint256 dailyRewards = isGod ? 20 : 10;
        claimableMeth = (timeFromCreation * dailyRewards) - claimed;

        if (!isGod && V3Interface.breedings(tokenId) == 0) {
            claimableMeth += claimableMeth / 2;
        }

        bool prevClaimed = V3Interface.prevClaimed(tokenId);

        if (!prevClaimed) {
            claimableMeth += V3Interface.getOldClaimableMeth(tokenId, isGod);
        }
    }

    function getTeenClaimableMeth(uint256 tokenId, uint256 claimed)
        internal
        view
        returns (uint256 claimableMeth)
    {
        if (claimed == 0) return 0;

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        uint256 dailyRewards = 5;

        uint256 rewards = (timeFromCreation * dailyRewards);

        if (claimed > rewards) return 0;

        claimableMeth = rewards - claimed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterfaceV3 {
    function getClaimableMeth(uint256 tokenId, uint256 _type)
        external
        view
        returns (uint256);

    function getOldClaimableMeth(uint256 tokenId, bool isGod)
        external
        view
        returns (uint256);

    function breedings(uint256) external view returns (uint256);

    function claimedTeenMeth(uint256) external view returns (uint256);

    function claimedMeth(uint256) external view returns (uint256);

    function lastChestOpen(uint256) external view returns (uint256);

    function godBulls(uint256) external view returns (bool);

    function isResurrected(uint256) external view returns (bool);

    function prevClaimed(uint256) external view returns (bool);

    function availableForRefund(uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721A.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721A {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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