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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: GPLv3
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICondition {
    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view returns (bool);
}

interface IRedPacket {
    enum BonusType {
        AVERAGE,
        RANDOM
    }
    struct RedPacketInfo {
        uint256 passcodeHash;
        uint256 amount;
        uint256 amountLeft;
        address creator;
        address token;
        address condition;
        uint32 total;
        uint32 totalLeft;
        BonusType bonusType;
    }

    function getRedPacket(uint256 id)
        external
        view
        returns (RedPacketInfo memory);

    function isOpened(uint256 id, address addr) external view returns (bool);
}

abstract contract BaseValidator is ICondition {
    IRedPacket internal redPacket;

    constructor(address redPacketAddr) {
        redPacket = IRedPacket(redPacketAddr);
    }

    modifier onlyCreator(uint256 redPacketId) {
        IRedPacket.RedPacketInfo memory rp = redPacket.getRedPacket(
            redPacketId
        );
        require(msg.sender == rp.creator, "not creator");
        _;
    }

    modifier checkContract(address addr) {
        require(addr == address(redPacket), "invalid red packet address");
        _;
    }
}

/**
 * Only address in the pool can open the red packet.
 */
contract AddressPoolValidator is BaseValidator {
    mapping(uint256 => mapping(address => bool)) pools;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function addAddresses(uint256 redPacketId, address[] memory addrs)
        public
        onlyCreator(redPacketId)
    {
        setAddresses(true, redPacketId, addrs);
    }

    function removeAddresses(uint256 redPacketId, address[] memory addrs)
        public
        onlyCreator(redPacketId)
    {
        setAddresses(false, redPacketId, addrs);
    }

    function setAddresses(
        bool add,
        uint256 redPacketId,
        address[] memory addrs
    ) internal {
        mapping(address => bool) storage pool = pools[redPacketId];
        for (uint256 i = 0; i < addrs.length; i++) {
            pool[addrs[i]] = add;
        }
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        mapping(address => bool) storage pool = pools[redPacketId];
        return pool[operator];
    }
}

/**
 * Only the NFT-721 holder can open the red packet
 */
contract Nft721HolderValidator is BaseValidator {
    mapping(uint256 => address) nftAddrs;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setERC721(uint256 redPacketId, address nftAddr)
        public
        onlyCreator(redPacketId)
    {
        nftAddrs[redPacketId] = nftAddr;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        address nftAddr = nftAddrs[redPacketId];
        if (nftAddr == address(0)) {
            return false;
        }
        return IERC721(nftAddr).balanceOf(operator) > 0;
    }
}

/**
 * Only the NFT-1155 holder can open the red packet
 */
contract Nft1155HolderValidator is BaseValidator {
    mapping(uint256 => address) nftAddrs;
    mapping(uint256 => uint256) nftIds;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setERC1155(
        uint256 redPacketId,
        address nftAddr,
        uint256 nftId
    ) public onlyCreator(redPacketId) {
        nftAddrs[redPacketId] = nftAddr;
        nftIds[redPacketId] = nftId;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        address nftAddr = nftAddrs[redPacketId];
        if (nftAddr == address(0)) {
            return false;
        }
        return IERC1155(nftAddr).balanceOf(operator, nftIds[redPacketId]) > 0;
    }
}

/**
 * Only the ERC20 holder with minimum balance can open the red packet
 */
contract ERC20HolderValidator is BaseValidator {
    mapping(uint256 => address) ercAddrs;
    mapping(uint256 => uint256) ercHolds;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setERC20(
        uint256 redPacketId,
        address ercAddr,
        uint256 ercMinHold
    ) public onlyCreator(redPacketId) {
        ercAddrs[redPacketId] = ercAddr;
        ercHolds[redPacketId] = ercMinHold;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        address erc = ercAddrs[redPacketId];
        if (erc == address(0)) {
            return false;
        }
        return IERC20(erc).balanceOf(operator) >= ercHolds[redPacketId];
    }
}

/**
 * Can open the red packet after specific timestamp.
 */
contract TimeBasedValidator is BaseValidator {
    mapping(uint256 => uint256) timestamps;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setTimestamp(uint256 redPacketId, uint256 timestamp)
        public
        onlyCreator(redPacketId)
    {
        timestamps[redPacketId] = timestamp;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        uint256 timestamp = timestamps[redPacketId];
        if (timestamp == 0) {
            return false;
        }
        return block.timestamp >= timestamp;
    }
}